import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

export async function generateUserReport({ userId, periodStart, periodEnd, premium }) {
  if (!premium) {
    return { mode: 'screen_only', message: 'Usuário Free possui visualização em tela.' };
  }

  const reportMeta = {
    title: 'Relatório HAMVIT',
    slogan: 'Evolua no seu ritmo.',
    periodStart,
    periodEnd,
    sections: ['hábitos', 'hidratação', 'alimentação', 'treinos', 'evolução', 'insights'],
  };

  const { data } = await supabase
    .from('generated_reports')
    .insert({ user_id: userId, period_start: periodStart, period_end: periodEnd, format: 'pdf' })
    .select('*')
    .single();

  await supabase.from('audit_logs').insert({
    actor_user_id: userId,
    action: 'report_generated',
    target_table: 'generated_reports',
    target_id: data.id,
    payload: reportMeta,
  });

  return { mode: 'pdf', reportId: data.id, meta: reportMeta };
}
