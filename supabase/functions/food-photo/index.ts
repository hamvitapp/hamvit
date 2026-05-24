import { admin, json } from "../_shared/supabase.ts";
import { hasPremiumLifetime } from "../_shared/entitlements.ts";

type GeminiItem = {
  name: string;
  portion: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fats_g: number;
};

async function buildGeminiEstimateFromStorage(storagePath: string) {
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiApiKey) return null;

  const bucket = Deno.env.get("FOOD_PHOTO_BUCKET") ?? "food-photos";
  const { data: signed, error: signedError } = await admin.storage
    .from(bucket)
    .createSignedUrl(storagePath, 60);
  if (signedError || !signed?.signedUrl) return null;

  const imageResp = await fetch(signed.signedUrl);
  if (!imageResp.ok) return null;
  const imageBytes = new Uint8Array(await imageResp.arrayBuffer());
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < imageBytes.length; i += chunkSize) {
    binary += String.fromCharCode(...imageBytes.subarray(i, i + chunkSize));
  }
  const imageBase64 = btoa(binary);

  const prompt =
    "Analise esta foto de comida. Responda somente JSON válido com o formato " +
    "{\"items\":[{\"name\":\"\",\"portion\":\"\",\"calories\":0,\"protein_g\":0,\"carbs_g\":0,\"fats_g\":0}]," +
    "\"notice\":\"Valores estimados e ajustáveis. Confirme antes de salvar.\"}.";

  const geminiUrl =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";
  const geminiResp = await fetch(`${geminiUrl}?key=${geminiApiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: "image/jpeg",
                data: imageBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.2,
        responseMimeType: "application/json",
      },
    }),
  });
  if (!geminiResp.ok) return null;
  const geminiJson = await geminiResp.json();
  const text = geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || typeof text !== "string") return null;

  try {
    const parsed = JSON.parse(text);
    const items = Array.isArray(parsed?.items) ? parsed.items : [];
    const normalized: GeminiItem[] = items.map((x: Record<string, unknown>) => ({
      name: String(x.name ?? "Item detectado"),
      portion: String(x.portion ?? "1 porção"),
      calories: Number(x.calories ?? 0),
      protein_g: Number(x.protein_g ?? 0),
      carbs_g: Number(x.carbs_g ?? 0),
      fats_g: Number(x.fats_g ?? 0),
    }));
    return {
      notice: "Valores estimados e ajustáveis. Confirme antes de salvar.",
      items: normalized.length > 0 ? normalized : [],
      provider: "gemini_flash_vision",
    };
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const body = await req.json().catch(() => null);
  const userId = String(body?.user_id ?? "").trim();
  const storagePath = String(body?.storage_path ?? "").trim();
  if (!userId || !storagePath) return json({ error: "user_id_and_storage_path_required" }, 400);

  const hasPremium = await hasPremiumLifetime(userId);
  if (!hasPremium) return json({ allowed: false, reason: "premium_required" }, 403);

  const usageDate = new Date().toISOString().slice(0, 10);
  const { data: usage } = await admin
    .from("ai_usage_limits")
    .select("*")
    .eq("user_id", userId)
    .eq("feature", "food_photo")
    .eq("usage_date", usageDate)
    .maybeSingle();

  const used = Number(usage?.used_count ?? 0);
  if (used >= 3) return json({ allowed: false, reason: "daily_limit_reached" }, 429);

  if (usage) {
    await admin.from("ai_usage_limits").update({ used_count: used + 1 }).eq("id", usage.id);
  } else {
    await admin.from("ai_usage_limits").insert({
      user_id: userId,
      feature: "food_photo",
      usage_date: usageDate,
      used_count: 1,
    });
  }

  const fallbackEstimate = {
    notice: "Valores estimados e ajustáveis. Confirme antes de salvar.",
    items: [{ name: "Item detectado", portion: "1 porção", calories: 250, protein_g: 12, carbs_g: 30, fats_g: 8 }],
    provider: "deterministic_fallback",
  };
  const estimated = (await buildGeminiEstimateFromStorage(storagePath)) ?? fallbackEstimate;

  const { data } = await admin
    .from("food_photo_analyses")
    .insert({ user_id: userId, storage_path: storagePath, result: estimated, status: "needs_review" })
    .select("*")
    .single();

  return json({ allowed: true, analysis: data });
});
