# Firebase Setup Instructions

## Phase 1: Project Setup - Status

✅ **Completed:**
- Firebase CLI installed (v14.26.0)
- Project directory structure created
- TypeScript configured for backend and frontend
- ESLint + Prettier configured
- Firebase configuration files created
- Security rules defined (Firestore + Storage)
- Initial TypeScript types created
- Utility files and constants defined

⏳ **Next Steps:**

1. **Create Firebase Project** (User action required)
2. **Install Dependencies**
3. **Connect to Firebase**
4. **Deploy Hello World Function**

---

## 1. Create Firebase Project (Google Cloud Console)

You need to create a Firebase project in the Google Cloud Console:

### Steps:
1. Go to https://console.firebase.google.com/
2. Click "Add project" or "Create a project"
3. Enter project name: `invoice-digitization-service` (or your preferred name)
4. (Optional) Enable Google Analytics
5. Click "Create project"

### Enable Required Services:
Once the project is created, enable the following:

#### Authentication
1. Go to "Build" → "Authentication"
2. Click "Get started"
3. Enable "Email/Password" sign-in method

#### Firestore Database
1. Go to "Build" → "Firestore Database"
2. Click "Create database"
3. Start in **production mode** (we have rules defined)
4. Choose a location (e.g., us-central)

#### Cloud Storage
1. Go to "Build" → "Storage"
2. Click "Get started"
3. Start in **production mode**
4. Use the default bucket

#### Cloud Functions
1. Go to "Build" → "Functions"
2. Click "Get started" (if prompted)
3. Upgrade to Blaze plan (pay-as-you-go)
   - **Note:** Required for Cloud Functions, but has generous free tier

---

## 2. Install Dependencies

Install npm packages for both backend and frontend:

```bash
# Backend dependencies
cd service/functions
npm install

# Frontend dependencies
cd ../frontend
npm install

# Return to service directory
cd ..
```

---

## 3. Connect to Firebase

### Login to Firebase CLI:
```bash
firebase login
```

### Initialize Firebase in this directory:
```bash
cd service
firebase init
```

When prompted:
- **Select features:**
  - [x] Firestore
  - [x] Functions
  - [x] Hosting
  - [x] Storage
  - [x] Emulators

- **Use an existing project:** Select the project you created in step 1

- **Firestore rules:** Use existing file `firestore.rules` ✅
- **Firestore indexes:** Use existing file `firestore.indexes.json` ✅
- **Functions language:** TypeScript ✅
- **Use ESLint:** Yes ✅
- **Install dependencies now:** No (we already did this)
- **Hosting public directory:** `frontend/dist` ✅
- **Configure as SPA:** Yes ✅
- **Set up automatic builds:** No
- **Storage rules:** Use existing file `storage.rules` ✅
- **Emulators to set up:**
  - [x] Authentication
  - [x] Functions
  - [x] Firestore
  - [x] Hosting
  - [x] Storage

### Set Firebase project ID:
```bash
firebase use --add
```
Select your project and give it an alias (e.g., `default`)

---

## 4. Store Anthropic API Key in Secret Manager

Store your Anthropic API key securely:

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

When prompted, paste your Anthropic API key (starts with `sk-ant-...`)

---

## 5. Deploy Hello World Function

Test that everything is set up correctly:

### Build the functions:
```bash
cd functions
npm run build
```

### Deploy to Firebase:
```bash
firebase deploy --only functions
```

### Test the function:
After deployment completes, Firebase will give you a URL like:
```
https://us-central1-your-project-id.cloudfunctions.net/helloWorld
```

Visit that URL in your browser. You should see:
```json
{
  "message": "Invoice Digitization Service - Cloud Functions are running!",
  "version": "1.0.0",
  "timestamp": "2025-11-30T..."
}
```

✅ **Phase 1 Complete!**

---

## 6. Run Local Development Environment (Optional)

To develop locally with Firebase emulators:

### Start emulators:
```bash
cd service
firebase emulators:start
```

This will start:
- Functions emulator: http://localhost:5001
- Firestore emulator: http://localhost:8080
- Hosting emulator: http://localhost:5000
- Storage emulator: http://localhost:9199
- Emulator UI: http://localhost:4000

### Start frontend dev server (in another terminal):
```bash
cd service/frontend
npm run dev
```

Frontend will be available at http://localhost:3000

---

## Troubleshooting

### "Firebase CLI not found"
```bash
npm install -g firebase-tools
```

### "Billing account required"
Cloud Functions require Blaze plan (pay-as-you-go), but has generous free tier:
- 2M function invocations/month
- 400K GB-seconds compute time
- 200K GHz-seconds compute time

For our expected usage (100 users × 10 invoices), costs should be ~$5-10/month for Firebase services.

### "Permission denied"
Make sure you're logged in:
```bash
firebase logout
firebase login
```

### "Functions deploy failed"
Check that:
1. TypeScript compiled successfully (`npm run build`)
2. All dependencies installed (`npm install`)
3. You're in the `service/` directory when running firebase commands

---

## Next: Phase 2

Once Phase 1 is complete, we'll proceed to **Phase 2: Backend - Cloud Functions Setup**:
- Set up Express.js for HTTP functions
- Create authentication middleware
- Create error handling middleware
- Set up API routes structure

See `ROADMAP.md` for the full checklist.
