#!/bin/bash
# Build script for Vercel deployment
# Copies invoice-generator.html to dist/ and injects Supabase Cloud credentials
# from environment variables. The original HTML file is never modified.
#
# Note: the Anthropic API key is NOT injected here. Extraction runs through the
# /api/extract serverless function, which reads ANTHROPIC_API_KEY server-side so
# the key never reaches the browser.

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
fs.writeFileSync('dist/index.html', html);
console.log('Build complete. Supabase URL: ' + process.env.SUPABASE_URL.trim());
"
