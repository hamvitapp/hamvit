import { admin, json } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const body = await req.json().catch(() => null);
  const barcode = String(body?.barcode ?? "").trim();
  if (!barcode) return json({ error: "barcode_required" }, 400);

  const { data: local } = await admin
    .from("barcode_lookups")
    .select("barcode, payload")
    .eq("barcode", barcode)
    .maybeSingle();

  if (local) {
    return json({ source: "supabase", data: local });
  }

  const payload = {
    code: barcode,
    product_name: `Produto ${barcode}`,
    source: "mock_open_food_facts",
  };
  await admin.from("barcode_lookups").insert({ barcode, payload });
  return json({ source: "open_food_facts_mock", data: payload });
});

