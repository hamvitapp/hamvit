import { admin, json } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const body = await req.json().catch(() => null);
  const action = String(body?.action ?? "create_payment");

  if (action === "create_payment") {
    const userId = String(body?.user_id ?? "").trim();
    const amount = Number(body?.amount_brl ?? 0);
    if (!userId || amount <= 0) return json({ error: "user_id_and_amount_required" }, 400);

    const { data: payment, error } = await admin
      .from("payments")
      .insert({ user_id: userId, provider: "mercado_pago", amount_brl: amount, status: "pending" })
      .select("*")
      .single();
    if (error) return json({ error: error.message }, 500);

    return json({ ok: true, payment });
  }

  if (action === "webhook_approved") {
    const userId = String(body?.user_id ?? "").trim();
    const paymentId = String(body?.payment_id ?? "").trim();
    if (!userId || !paymentId) return json({ error: "user_id_and_payment_id_required" }, 400);

    await admin.from("payments").update({ status: "approved" }).eq("id", paymentId);
    await admin.from("user_entitlements").upsert({ user_id: userId, plan: "premium_lifetime", active: true });
    await admin.from("profiles").update({ plan: "premium_lifetime" }).eq("id", userId);

    return json({ ok: true, premium: true });
  }

  return json({ error: "unsupported_action" }, 400);
});

