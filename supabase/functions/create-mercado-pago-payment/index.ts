import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { admin, json } from "../_shared/supabase.ts";

type PaymentMethod = "pix" | "credit_card";

type AppUser = {
  id: string;
  email?: string;
};

function readJson(req: Request) {
  return req.json().catch(() => ({}));
}

function parseMethod(value: unknown): PaymentMethod {
  return value === "credit_card" ? "credit_card" : "pix";
}

function normalizeCouponCode(raw: unknown): string | null {
  const code = String(raw ?? "").trim().toUpperCase();
  return code.length > 0 ? code : null;
}

function getEnv(name: string, required = true): string {
  const value = (Deno.env.get(name) ?? "").trim();
  if (!value && required) {
    throw new Error(`missing_env_${name}`);
  }
  return value;
}

async function getAuthenticatedUser(req: Request): Promise<AppUser> {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    throw new Error("missing_bearer_token");
  }

  const supabaseUrl = getEnv("SUPABASE_URL");
  const anonKey = getEnv("SUPABASE_ANON_KEY");
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    throw new Error("invalid_auth_token");
  }

  return { id: data.user.id, email: data.user.email ?? undefined };
}

function statusToInternal(status: string | null | undefined): string {
  const s = String(status ?? "pending").toLowerCase();
  if (["approved", "rejected", "cancelled", "refunded", "chargeback"].includes(s)) return s;
  return "pending";
}

async function mercadoPagoRequest(path: string, method: string, body?: unknown) {
  const accessToken = getEnv("MERCADO_PAGO_ACCESS_TOKEN");
  const idempotencyKey = crypto.randomUUID();

  const response = await fetch(`https://api.mercadopago.com${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
      "X-Idempotency-Key": idempotencyKey,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const payload = await response.json().catch(() => ({}));
  return { ok: response.ok, status: response.status, payload };
}

async function resolveLifetimePriceCents() {
  const { data } = await admin
    .from("app_settings")
    .select("value")
    .eq("key", "premium_lifetime_price_cents")
    .maybeSingle();

  const configured = Number(data?.value?.price_cents ?? data?.value?.amount_cents ?? 0);
  return Number.isFinite(configured) && configured > 0 ? Math.round(configured) : 9700;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const user = await getAuthenticatedUser(req);
    const body = await readJson(req);

    const method = parseMethod(body.method);
    const couponCode = normalizeCouponCode(body.coupon_code);
    const cpf = String(body.cpf ?? "").replace(/\D/g, "");
    const payerEmail = String(body.payer_email ?? user.email ?? "").trim();

    if (!payerEmail) return json({ error: "payer_email_required" }, 400);

    const basePriceCents = await resolveLifetimePriceCents();

    let couponRow: Record<string, unknown> | null = null;
    let discountPercent = 0;

    if (couponCode) {
      const { data: coupon } = await admin
        .from("professional_coupons")
        .select("id, professional_id, discount_percent, commission_percent")
        .ilike("code", couponCode)
        .maybeSingle();

      if (!coupon) {
        return json({ error: "invalid_coupon_code" }, 400);
      }

      couponRow = coupon;
      discountPercent = Math.max(0, Math.min(95, Number(coupon.discount_percent ?? 0)));
    }

    const amountCents = Math.max(100, Math.round(basePriceCents * (1 - discountPercent / 100)));

    const { data: payment, error: paymentError } = await admin
      .from("payments")
      .insert({
        user_id: user.id,
        provider: "mercado_pago",
        method,
        status: "pending",
        amount_cents: amountCents,
        amount_brl: amountCents / 100,
        currency: "BRL",
        coupon_id: couponRow?.id ?? null,
        external_reference: null,
      })
      .select("*")
      .single();

    if (paymentError || !payment) {
      return json({ error: paymentError?.message ?? "payment_row_insert_failed" }, 500);
    }

    const externalReference = String(payment.id);
    await admin.from("payments").update({ external_reference: externalReference }).eq("id", payment.id);

    const notificationUrl = getEnv("MERCADO_PAGO_WEBHOOK_URL", false);
    const mpDescription = "HAMVIT Premium vitalicio";

    if (method === "pix") {
      const mpBody: Record<string, unknown> = {
        transaction_amount: Number((amountCents / 100).toFixed(2)),
        description: mpDescription,
        payment_method_id: "pix",
        external_reference: externalReference,
        payer: {
          email: payerEmail,
          ...(cpf.length === 11
            ? { identification: { type: "CPF", number: cpf } }
            : {}),
        },
      };

      if (notificationUrl) mpBody.notification_url = notificationUrl;

      const mpResponse = await mercadoPagoRequest("/v1/payments", "POST", mpBody);
      if (!mpResponse.ok) {
        await admin
          .from("payments")
          .update({
            status: "rejected",
            raw_payload: mpResponse.payload,
            updated_at: new Date().toISOString(),
          })
          .eq("id", payment.id);
        return json({ error: "mercado_pago_pix_create_failed", detail: mpResponse.payload }, 502);
      }

      const providerPaymentId = String(mpResponse.payload?.id ?? "");
      const mpStatus = statusToInternal(mpResponse.payload?.status);
      const txData = mpResponse.payload?.point_of_interaction?.transaction_data ?? {};

      const approvedAt = mpStatus === "approved" ? new Date().toISOString() : null;
      await admin
        .from("payments")
        .update({
          provider_payment_id: providerPaymentId || null,
          status: mpStatus,
          raw_payload: mpResponse.payload,
          approved_at: approvedAt,
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id);

      return json({
        ok: true,
        flow: "pix",
        payment: {
          id: payment.id,
          status: mpStatus,
          amount_cents: amountCents,
          method,
        },
        pix: {
          qr_code: txData?.qr_code ?? null,
          qr_code_base64: txData?.qr_code_base64 ?? null,
          ticket_url: txData?.ticket_url ?? null,
          provider_payment_id: providerPaymentId || null,
        },
      });
    }

    const successUrl = getEnv("MERCADO_PAGO_SUCCESS_URL", false) || getEnv("HAMVIT_APP_URL", false) || "https://example.com/success";
    const failureUrl = getEnv("MERCADO_PAGO_FAILURE_URL", false) || getEnv("HAMVIT_APP_URL", false) || "https://example.com/failure";
    const pendingUrl = getEnv("MERCADO_PAGO_PENDING_URL", false) || getEnv("HAMVIT_APP_URL", false) || "https://example.com/pending";

    const preferenceBody: Record<string, unknown> = {
      items: [
        {
          id: "hamvit_premium_lifetime",
          title: "HAMVIT Premium vitalicio",
          quantity: 1,
          unit_price: Number((amountCents / 100).toFixed(2)),
          currency_id: "BRL",
        },
      ],
      external_reference: externalReference,
      payer: { email: payerEmail },
      back_urls: {
        success: successUrl,
        failure: failureUrl,
        pending: pendingUrl,
      },
      auto_return: "approved",
    };

    if (notificationUrl) preferenceBody.notification_url = notificationUrl;

    const preferenceResponse = await mercadoPagoRequest("/checkout/preferences", "POST", preferenceBody);
    if (!preferenceResponse.ok) {
      await admin
        .from("payments")
        .update({
          status: "rejected",
          raw_payload: preferenceResponse.payload,
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id);
      return json({ error: "mercado_pago_preference_create_failed", detail: preferenceResponse.payload }, 502);
    }

    const preferenceId = String(preferenceResponse.payload?.id ?? "");
    await admin
      .from("payments")
      .update({
        provider_preference_id: preferenceId || null,
        raw_payload: preferenceResponse.payload,
        status: "pending",
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment.id);

    return json({
      ok: true,
      flow: "checkout_preference",
      payment: {
        id: payment.id,
        status: "pending",
        amount_cents: amountCents,
        method,
      },
      checkout: {
        preference_id: preferenceId || null,
        init_point: preferenceResponse.payload?.init_point ?? null,
        sandbox_init_point: preferenceResponse.payload?.sandbox_init_point ?? null,
      },
    });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "unexpected_error" }, 401);
  }
});
