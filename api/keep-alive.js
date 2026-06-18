import { createClient } from '@supabase/supabase-js';

export default async function handler(req, res) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    return res.status(500).json({ error: 'Missing Supabase credentials' });
  }

  const supabase = createClient(supabaseUrl, supabaseKey);

  const { data, error } = await supabase.from('clients').select('id').limit(1);

  if (error) {
    return res.status(500).json({ error: error.message, timestamp: new Date().toISOString() });
  }

  return res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
}
