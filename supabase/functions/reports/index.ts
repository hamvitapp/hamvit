import { admin, json } from "../_shared/supabase.ts";
import { hasPremiumLifetime } from "../_shared/entitlements.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const body = await req.json().catch(() => null);
  const userId = String(body?.user_id ?? "").trim();
  const periodStart = String(body?.period_start ?? "").trim();
  const periodEnd = String(body?.period_end ?? "").trim();
  if (!userId || !periodStart || !periodEnd) return json({ error: "user_id_period_start_period_end_required" }, 400);

  const hasPremium = await hasPremiumLifetime(userId);

  if (!hasPremium) {
    return json({ mode: "screen_only", message: "Usuário Free possui visualização em tela." });
  }

  const { data: report } = await admin
    .from("generated_reports")
    .insert({ user_id: userId, period_start: periodStart, period_end: periodEnd, format: "pdf" })
    .select("*")
    .single();

  await admin.from("audit_logs").insert({
    actor_user_id: userId,
    action: "report_generated",
    target_table: "generated_reports",
    target_id: report.id,
    payload: { slogan: "Evolua no seu ritmo." },
  });

  return json({ mode: "pdf", report });
});

