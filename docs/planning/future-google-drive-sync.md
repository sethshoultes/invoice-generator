# Future Feature: Google Drive Sync

**Status:** Planning (Future)
**Priority:** Medium
**Prerequisite:** Invoice History + Export/Import complete

---

## Problem

localStorage has inherent risks:
- Lost when clearing browser data
- Not synced across devices/browsers
- No automatic backup
- User must remember to export manually

Users want peace of mind that their invoice data is safe.

---

## Solution: Google Drive Sync

Automatically sync app data to user's Google Drive as a JSON file. This provides:
- Cloud backup (survives browser data loss)
- Cross-device access (same data on laptop + desktop)
- Version history (Google Drive keeps file versions)
- User owns their data (in their own Drive)

---

## How It Works

### Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   Browser App   │ ◄─────► │  Google Drive   │
│                 │  Sync   │                 │
│  localStorage   │         │  invoices.json  │
└─────────────────┘         └─────────────────┘
```

### Sync Flow

**Initial Setup:**
1. User clicks "Connect Google Drive"
2. Google OAuth consent screen appears
3. User grants permission to app folder only
4. App creates `InvoiceGenerator/` folder in Drive
5. Initial sync: upload current localStorage to Drive

**Ongoing Sync:**
1. On any data change (new invoice, edit, etc.)
2. App updates localStorage (immediate)
3. App syncs to Google Drive (debounced, every 30 seconds or on save)
4. Conflict resolution: most recent timestamp wins

**Recovery:**
1. User clears browser data (localStorage lost)
2. User opens app, connects Google Drive
3. App detects no local data but Drive has data
4. Prompts: "Restore from Google Drive backup?"
5. User confirms, data restored

---

## Technical Implementation

### Google API Setup

**Required APIs:**
- Google Drive API v3
- Google Identity Services (OAuth 2.0)

**Scopes needed:**
```
https://www.googleapis.com/auth/drive.file
```
This scope only allows access to files created by our app, not user's entire Drive.

**App Folder vs User Folder:**
- Option A: Use Drive App Folder (hidden from user, auto-managed)
- Option B: Use visible folder (user can see/manage files)
- **Recommendation:** Visible folder (`InvoiceGenerator/`) so users can see their backups

### OAuth Flow (Browser-Only)

```javascript
// Load Google Identity Services
<script src="https://accounts.google.com/gsi/client"></script>

// Initialize
const client = google.accounts.oauth2.initTokenClient({
  client_id: 'YOUR_CLIENT_ID',
  scope: 'https://www.googleapis.com/auth/drive.file',
  callback: (response) => {
    if (response.access_token) {
      // Save token, start sync
      localStorage.setItem('google_access_token', response.access_token);
      syncToDrive();
    }
  },
});

// Trigger login
client.requestAccessToken();
```

### Drive File Operations

**Create/Update File:**
```javascript
async function syncToDrive(data) {
  const accessToken = localStorage.getItem('google_access_token');
  const fileId = localStorage.getItem('google_drive_file_id');

  const metadata = {
    name: 'invoice-generator-backup.json',
    mimeType: 'application/json',
  };

  const fileContent = JSON.stringify({
    syncVersion: 1,
    lastSync: new Date().toISOString(),
    data: data
  });

  if (fileId) {
    // Update existing file
    await fetch(`https://www.googleapis.com/upload/drive/v3/files/${fileId}?uploadType=media`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: fileContent
    });
  } else {
    // Create new file
    // First create metadata, then upload content
    // ... (multipart upload)
  }
}
```

**Read File:**
```javascript
async function readFromDrive() {
  const accessToken = localStorage.getItem('google_access_token');
  const fileId = localStorage.getItem('google_drive_file_id');

  const response = await fetch(
    `https://www.googleapis.com/drive/v3/files/${fileId}?alt=media`,
    {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    }
  );

  return response.json();
}
```

### Sync Strategy

**Debounced Sync:**
```javascript
let syncTimeout = null;

function scheduleSync() {
  if (syncTimeout) clearTimeout(syncTimeout);
  syncTimeout = setTimeout(() => {
    syncToDrive(getAllLocalData());
  }, 30000); // Sync 30 seconds after last change
}

// Call on every data change
function saveInvoice(invoice) {
  saveToLocalStorage(invoice);
  scheduleSync();
}
```

**Conflict Resolution:**
```javascript
async function resolveConflict(localData, driveData) {
  const localTime = new Date(localData.lastModified);
  const driveTime = new Date(driveData.lastSync);

  if (driveTime > localTime) {
    // Drive is newer, restore from Drive
    return { action: 'restore', data: driveData };
  } else {
    // Local is newer, push to Drive
    return { action: 'push', data: localData };
  }
}
```

---

## UI Design

### Settings Section

```
┌─────────────────────────────────────────────────────┐
│  Cloud Backup                                       │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  Google Drive: [🔗 Connect Google Drive]           │
│                                                     │
│  ── OR (when connected) ──                         │
│                                                     │
│  Google Drive: ✅ Connected                        │
│  Account: seth@example.com                         │
│  Last sync: 2 minutes ago                          │
│  File: InvoiceGenerator/backup.json                │
│                                                     │
│  [🔄 Sync Now]  [🔌 Disconnect]                    │
│                                                     │
│  ☑️ Auto-sync when data changes                    │
│  ☑️ Warn before overwriting newer cloud data       │
└─────────────────────────────────────────────────────┘
```

### Sync Status Indicator

In header/footer:
```
┌─────────────────────────────────────────────────────┐
│  Invoice Generator          ☁️ Synced 2 min ago    │
└─────────────────────────────────────────────────────┘

States:
- ☁️ Synced (green) - Up to date
- 🔄 Syncing... (blue) - In progress
- ⚠️ Sync needed (yellow) - Changes pending
- ❌ Sync error (red) - Failed, click for details
- ☁️ Offline (gray) - Not connected
```

### Recovery Flow

When app opens with no localStorage but has Drive connection:

```
┌─────────────────────────────────────────────────────┐
│  Restore from Google Drive?                        │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  We found a backup in your Google Drive:           │
│                                                     │
│  📄 invoice-generator-backup.json                  │
│  Last modified: Nov 26, 2025 3:45 PM              │
│  Contains: 12 invoices, 5 clients                  │
│                                                     │
│  [Restore Backup]  [Start Fresh]                   │
└─────────────────────────────────────────────────────┘
```

---

## Security Considerations

### Token Storage
- Access tokens stored in localStorage (obfuscated like API key)
- Refresh tokens: Google handles this via Identity Services
- Tokens scoped to drive.file only (can't access user's other files)

### Data Privacy
- Data stored in USER's Google Drive (not ours)
- We never see or store user data on any server
- User can delete the file anytime from their Drive

### Consent
- Clear explanation of what we're accessing
- User must explicitly click "Connect"
- Easy disconnect option

---

## Limitations

1. **Requires Google Account** - Not everyone has/wants one
2. **OAuth Complexity** - Must set up Google Cloud project
3. **Token Expiry** - Need to handle re-authentication
4. **Offline** - Can't sync when offline (but localStorage still works)
5. **Single File** - Not a real database, just JSON backup

---

## Alternatives Considered

### Dropbox
- Similar OAuth flow
- Less common than Google
- Would need separate implementation

### iCloud
- Apple only
- Complex API
- Not web-friendly

### Custom Backend
- Full control
- Requires hosting
- We'd be responsible for user data

### IndexedDB
- Larger storage than localStorage
- Still browser-only, same loss risks
- More complex API

**Decision:** Google Drive is best balance of reliability, user ownership, and browser-only architecture.

---

## Implementation Checklist

### Phase 1: Setup
- [ ] Create Google Cloud project
- [ ] Enable Google Drive API
- [ ] Configure OAuth consent screen
- [ ] Get client ID for web app
- [ ] Add Google Identity Services script

### Phase 2: Authentication
- [ ] Implement OAuth flow
- [ ] Store/retrieve access token
- [ ] Handle token expiry/refresh
- [ ] Add Connect/Disconnect UI
- [ ] Show connected account info

### Phase 3: Sync Operations
- [ ] Create file in Drive
- [ ] Update existing file
- [ ] Read file from Drive
- [ ] Find existing backup file
- [ ] Handle file not found

### Phase 4: Auto-Sync
- [ ] Debounced sync on data change
- [ ] Sync status indicator
- [ ] Manual "Sync Now" button
- [ ] Conflict detection
- [ ] Conflict resolution UI

### Phase 5: Recovery
- [ ] Detect missing localStorage
- [ ] Check for Drive backup
- [ ] Restore from backup flow
- [ ] Merge local + cloud option

### Phase 6: Polish
- [ ] Error handling for all API calls
- [ ] Offline detection
- [ ] Rate limiting (Drive API quotas)
- [ ] Testing across browsers
- [ ] Documentation

---

## Estimated Effort

| Phase | Effort | Notes |
|-------|--------|-------|
| Setup | 1-2 hours | Google Cloud console config |
| Auth | 2-3 hours | OAuth is always tricky |
| Sync | 3-4 hours | Core functionality |
| Auto-Sync | 2-3 hours | Debouncing, status |
| Recovery | 2-3 hours | Edge cases |
| Polish | 2-4 hours | Error handling, testing |
| **Total** | **12-19 hours** | |

---

## Prerequisites

Before implementing:
1. ✅ Export/Import working (fallback if Drive fails)
2. ✅ Invoice History complete (data to sync)
3. ⬜ Google Cloud account for API credentials
4. ⬜ Privacy policy page (Google requires for OAuth)

---

## Open Questions

1. **Multiple devices:** What if user has app open on two computers? Real-time sync or manual?
2. **Selective sync:** Sync everything or let user choose (invoices only, clients only)?
3. **Backup frequency:** Every change? Every 5 minutes? Only on close?
4. **Free tier limits:** Google Drive API has quotas - will we hit them?

---

## Decision Needed

This is a significant feature. Before implementing, decide:

1. **Is this worth the complexity?** Export/Import might be "good enough"
2. **When to build?** After core features stable, or sooner?
3. **Google Cloud setup:** Who creates/owns the Google Cloud project?

**Recommendation:** Implement Export/Import first, use it for a month, then evaluate if Google Drive sync is needed based on actual pain points.
