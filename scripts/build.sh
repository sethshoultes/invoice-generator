#!/bin/bash
# Build script for Vercel deployment
# Copies invoice-generator.html to dist/ and injects Supabase Cloud credentials
# from environment variables. The original HTML file is never modified.

set -euo pipefail

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "ERROR: SUPABASE_URL and SUPABASE_ANON_KEY environment variables are required."
  echo "Set them in Vercel project settings under Environment Variables."
  exit 1
fi

mkdir -p dist

# Use Node.js for robust string replacement (avoids sed escaping issues)
node -e "
const fs = require('fs');
let html = fs.readFileSync('invoice-generator.html', 'utf8');
html = html.replace(
  \"const supabaseUrl = 'http://127.0.0.1:8002'\",
  \"const supabaseUrl = '\" + process.env.SUPABASE_URL.trim() + \"'\"
);
html = html.replace(
  \"const supabaseAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH'\",
  \"const supabaseAnonKey = '\" + process.env.SUPABASE_ANON_KEY.trim() + \"'\"
);
// If ANTHROPIC_API_KEY is set, inject a script that pre-populates localStorage
// so the app auto-loads the key without user input
const anthropicKey = (process.env.ANTHROPIC_API_KEY || '').trim();
if (anthropicKey) {
  const obfuscated = Buffer.from(anthropicKey.split('').reverse().join('')).toString('base64');
  const injection = '<script>if(!localStorage.getItem(\"anthropic_api_key\")){localStorage.setItem(\"anthropic_api_key\",\"' + obfuscated + '\");}</script>';
  html = html.replace('</head>', injection + '</head>');
}
fs.writeFileSync('dist/invoice-generator.html', html);
console.log('Build complete. Supabase URL: ' + process.env.SUPABASE_URL.trim());
if (anthropicKey) console.log('Anthropic API key injected.');
"
