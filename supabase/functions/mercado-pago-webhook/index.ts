import { admin, json } from "../_shared/supabase.ts";

function getEnv(name: string, required = true): string {
  const value = (Deno.env.get(name) ?? "").trim();
  if (!value && required) {
    throw new Error(`missing_env_${name}`);
  }
  return value;
}

function toInternalStatus(value: unknown): string {
  const status = String(value ?? "pending").toLowerCase();
  if (["approved", "rejected", "cancelled", "refunded", "chargeback"].includes(status)) return status;
  return "pending";
}

function resolveEventMeta(req: Request, body: Record<string, unknown>) {
  const url = new URL(req.url);
  const eventType =
    String(url.searchParams.get("type") ?? url.searchParams.get("topic") ?? body.type ?? body.topic ?? "unknown").toLowerCase();

  const providerEventId =
    String(
      url.searchParams.get("id") ??
        body.id ??
        body["event_id"] ??
        "",
    ).trim();

  const paymentIdHint =
    String(
      url.searchParams.get("data.id") ??
        (typeof body.data === "object" && body.data !== null ? (body.data as Record<string, unknown>).id : "") ??
        body["resource_id"] ??
        "",
    ).trim();

  return { eventType, providerEventId, paymentIdHint };
}

async function getMercadoPagoPayment(providerPaymentId: string) {
  const accessToken = getEnv("MERCADO_PAGO_ACCESS_TOKEN");
  const response = await fetch(`https://api.mercadopago.com/v1/payments/${providerPaymentId}`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });

  const payload = await response.json().catch(() => ({}));
  return { ok: response.ok, payload };
}

async function activatePremiumIfApproved(payment: Record<string, unknown>, status: string, providerPayload: Record<string, unknown>) {
  if (status !== "approved") return;

  const userId = String(payment.user_id ?? "");
  const paymentId = String(payment.id ?? "");
  if (!userId || !paymentId) return;

  await admin.from("user_entitlements").upsert(
    {
      user_id: userId,
      entitlement_key: "premium_lifetime",
      plan: "premium_lifetime",
      active: true,
      source_payment_id: paymentId,
      starts_at: new Date().toISOString(),
      expires_at: null,
    },
    { onConflict: "user_id,entitlement_key" },
  );

  await admin
    .from("profiles")
    .update({ plan: "premium_lifetime", premium_active: true, updated_at: new Date().toISOString() })
    .eq("user_id", userId);

  const couponId = payment.coupon_id ? String(payment.coupon_id) : "";
  if (!couponId) return;

  const { data: coupon } = await admin
    .from("professional_coupons")
    .select("id, professional_id, commission_percent")
    .eq("id", couponId)
    .maybeSingle();

  if (!coupon?.professional_id) return;

  const amountCents = Number(payment.amount_cents ?? 0);
  const commissionPercent = Number(coupon.commission_percent ?? 0);
  const commissionCents = Math.max(0, Math.round(amountCents * (commissionPercent / 100)));

  await admin.from("professional_commissions").upsert(
    {
      professional_id: coupon.professional_id,
      user_id: userId,
      payment_id: paymentId,
      amount_cents: commissionCents,
      amount_brl: commissionCents / 100,
      status: "approved",
      approved_at: new Date().toISOString(),
    },
    { onConflict: "payment_id" },
  );

  const { data: existingLink } = await admin
    .from("patient_professional_links")
    .select("id")
    .eq("user_id", userId)
    .eq("professional_id", coupon.professional_id)
    .eq("coupon_id", coupon.id)
    .maybeSingle();

  if (!existingLink) {
    await admin.from("patient_professional_links").insert({
      user_id: userId,
      professional_id: coupon.professional_id,
      coupon_id: coupon.id,
      active: true,
      linked_at: new Date().toISOString(),
    });
  }

  await admin.from("audit_logs").insert({
    actor_user_id: userId,
    action: "premium_activated_via_webhook",
    target_table: "payments",
    target_id: paymentId,
    payload: {
      provider_payment_id: providerPayload.id ?? null,
      external_reference: providerPayload.external_reference ?? null,
    },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: true, ignored: "method_not_post" });

  const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;

  const { eventType, providerEventId, paymentIdHint } = resolveEventMeta(req, body);

  const webhookEventKey = providerEventId || paymentIdHint || crypto.randomUUID();

  const { data: insertedWebhook, error: webhookInsertError } = await admin
    .from("payment_webhooks")
    .upsert(
      {
        provider: "mercado_pago",
        event_type: eventType,
        provider_event_id: webhookEventKey,
        payload: body,
        processed: false,
      },
      { onConflict: "provider,provider_event_id" },
    )
    .select("id, processed")
    .single();

  if (webhookInsertError) {
    return json({ error: webhookInsertError.message }, 500);
  }

  if (insertedWebhook?.processed) {
    return json({ ok: true, duplicate: true });
  }

  if (eventType !== "payment") {
    await admin
      .from("payment_webhooks")
      .update({ processed: true, processed_at: new Date().toISOString() })
      .eq("id", insertedWebhook.id);
    return json({ ok: true, ignored: true, reason: "unsupported_event_type" });
  }

  if (!paymentIdHint) {
    await admin
      .from("payment_webhooks")
      .update({ processed: true, processed_at: new Date().toISOString() })
      .eq("id", insertedWebhook.id);
    return json({ ok: true, ignored: true, reason: "missing_payment_id" });
  }

  const mpPaymentResponse = await getMercadoPagoPayment(paymentIdHint);
  if (!mpPaymentResponse.ok) {
    return json({ error: "mercado_pago_lookup_failed", detail: mpPaymentResponse.payload }, 502);
  }

  const mpPayment = mpPaymentResponse.payload as Record<string, unknown>;
  const mpStatus = toInternalStatus(mpPayment.status);
  const providerPaymentId = String(mpPayment.id ?? "");
  const externalReference = String(mpPayment.external_reference ?? "");

  let paymentRow: Record<string, unknown> | null = null;

  if (providerPaymentId) {
    const { data } = await admin
      .from("payments")
      .select("*")
      .eq("provider", "mercado_pago")
      .eq("provider_payment_id", providerPaymentId)
      .maybeSingle();
    paymentRow = data as Record<string, unknown> | null;
  }

  if (!paymentRow && externalReference) {
    const { data } = await admin
      .from("payments")
      .select("*")
      .eq("external_reference", externalReference)
      .maybeSingle();
    paymentRow = data as Record<string, unknown> | null;
  }

  if (!paymentRow && externalReference) {
    const { data } = await admin
      .from("payments")
      .select("*")
      .eq("id", externalReference)
      .maybeSingle();
    paymentRow = data as Record<string, unknown> | null;
  }

  if (!paymentRow?.id) {
    return json({ ok: true, ignored: true, reason: "internal_payment_not_found" });
  }

  const updatePayload: Record<string, unknown> = {
    status: mpStatus,
    provider_payment_id: providerPaymentId || null,
    raw_payload: mpPayment,
    updated_at: new Date().toISOString(),
  };

  if (mpStatus === "approved") {
    updatePayload.approved_at = new Date().toISOString();
  }

  await admin.from("payments").update(updatePayload).eq("id", paymentRow.id);

  await activatePremiumIfApproved(paymentRow, mpStatus, mpPayment);

  await admin
    .from("payment_webhooks")
    .update({ processed: true, processed_at: new Date().toISOString() })
    .eq("id", insertedWebhook.id);

  return json({
    ok: true,
    processed: true,
    status: mpStatus,
    payment_id: paymentRow.id,
    provider_payment_id: providerPaymentId || null,
  });
});
