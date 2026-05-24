import { NextResponse } from 'next/server';
import { getAdminSupabase } from '../../../lib/supabaseAdmin';

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const supabase = getAdminSupabase();

    const { error } = await supabase.from('audit_logs').insert({
      actor_user_id: body.actor_user_id ?? null,
      action: body.action ?? 'admin_action',
      target_table: body.target_table ?? null,
      target_id: body.target_id ?? null,
      payload: body.payload ?? {},
    });

    if (error) return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ ok: false, error: String(e) }, { status: 500 });
  }
}


