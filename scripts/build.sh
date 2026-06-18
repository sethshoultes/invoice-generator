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
  // Replace the full API key input block with a minimal indicator
  const apiKeyBlock = '{/* API Key Input */}\\n            <div className=\"mb-6 bg-amber-50 border border-amber-200 rounded-xl p-4\">\\n              <div className=\"flex items-center justify-between mb-2\">\\n                <label className=\"text-sm font-medium text-amber-800\">Anthropic API Key</label>\\n                {apiKey && localStorage.getItem(\\'anthropic_api_key\\') && (\\n                  <span className=\"flex items-center gap-1 text-xs text-green-600\">\\n                    <Icon name=\"check\" className=\"w-3 h-3\" /> Saved\\n                  </span>\\n                )}\\n              </div>\\n              <div className=\"flex gap-2\">\\n                <input\\n                  type=\"password\"\\n                  value={apiKey}\\n                  onChange={(e) => handleApiKeyChange(e.target.value)}\\n                  placeholder=\"sk-ant-...\"\\n                  className=\"flex-1 px-3 py-2 border border-amber-300 rounded-lg focus:border-amber-500 focus:ring-1 focus:ring-amber-500 outline-none bg-white\"\\n                />\\n                {apiKey && (\\n                  <button\\n                    onClick={clearApiKey}\\n                    className=\"px-3 py-2 text-amber-700 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors\"\\n                    title=\"Clear saved key\"\\n                  >\\n                    <Icon name=\"trash\" className=\"w-4 h-4\" />\\n                  </button>\\n                )}\\n              </div>\\n              <p className=\"text-xs text-amber-600 mt-2\">\\n                {localStorage.getItem(\\'anthropic_api_key\\')\\n                  ? \\'Your key is saved locally (obfuscated) and will be remembered.\\'\\n                  : \\'Your key is only used in-browser. Enter a valid key to save it.\\'}\\n              </p>\\n            </div>';
  const minimalIndicator = '{/* API Key - Pre-configured */}\\n            {apiKey && <div className=\"mb-6 bg-green-50 border border-green-200 rounded-xl px-4 py-3 flex items-center gap-2\">\\n              <Icon name=\"check\" className=\"w-4 h-4 text-green-600\" />\\n              <span className=\"text-sm text-green-800\">API key configured</span>\\n            </div>}';
  html = html.replace(apiKeyBlock, minimalIndicator);
}
fs.writeFileSync('dist/index.html', html);
console.log('Build complete. Supabase URL: ' + process.env.SUPABASE_URL.trim());
if (anthropicKey) console.log('Anthropic API key injected.');
"
