import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

export async function createPremiumPayment({ userId, amountBrl, couponCode }) {
  const payload = {
    user_id: userId,
    provider: 'mercado_pago',
    amount_brl: amountBrl,
    status: 'pending',
  };

  const { data: payment, error } = await supabase.from('payments').insert(payload).select('*').single();
  if (error) throw error;

  if (couponCode) {
    await supabase.from('audit_logs').insert({
      actor_user_id: userId,
      action: 'payment_coupon_applied',
      target_table: 'payments',
      target_id: payment.id,
      payload: { couponCode },
    });
  }

  return {
    paymentId: payment.id,
    checkout: {
      method_priority: ['pix', 'card'],
      provider: 'mercado_pago',
    },
  };
}

export async function handleMercadoPagoWebhook({ providerEventId, status, userId, paymentId, rawPayload }) {
  await supabase.from('payment_webhooks').insert({
    provider: 'mercado_pago',
    payload: rawPayload,
    processed_at: new Date().toISOString(),
  });

  if (status !== 'approved') return { approved: false };

  await supabase.from('payments').update({ status: 'approved' }).eq('id', paymentId);

  await supabase.from('user_entitlements').upsert({
    user_id: userId,
    plan: 'premium_lifetime',
    active: true,
    granted_at: new Date().toISOString(),
  });

  await supabase.from('profiles').update({ plan: 'premium_lifetime' }).eq('id', userId);

  await supabase.from('audit_logs').insert({
    actor_user_id: userId,
    action: 'premium_activated_webhook',
    target_table: 'payments',
    target_id: paymentId,
    payload: { providerEventId },
  });

  return { approved: true };
}
