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

# Copy the HTML file and replace the local Supabase config with cloud values
sed \
  -e "s|const supabaseUrl = 'http://127.0.0.1:8002';|const supabaseUrl = '${SUPABASE_URL}';|" \
  -e "s|const supabaseAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';|const supabaseAnonKey = '${SUPABASE_ANON_KEY}';|" \
  invoice-generator.html > dist/invoice-generator.html

echo "Build complete. Supabase URL: ${SUPABASE_URL}"
