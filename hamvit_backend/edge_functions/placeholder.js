export default async function handler(req, res) {
  res.status(501).json({ message: 'Use Supabase Edge Functions para endpoints críticos.' });
}
