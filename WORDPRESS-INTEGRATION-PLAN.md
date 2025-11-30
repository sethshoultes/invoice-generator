# WordPress Integration Plan

**Last Updated:** 2025-11-30
**Status:** Planning Phase
**Target Branch:** `claude/wordpress-cloud-invoice-integration-01QPtGU199TqAm7zbmTN4Mos`

---

## Executive Summary

**Goal:** Create a WordPress plugin that allows site owners to offer invoice digitization services to their members through a seamless integration with the Firebase cloud service.

**Key Architecture Decision:** Use MemberPress for user management and membership tiers, Firebase cloud service for invoice processing and storage.

**User Flow:**
1. User logs into WordPress site (MemberPress handles auth)
2. User accesses invoice generator via WordPress dashboard/frontend page
3. WordPress plugin communicates with Firebase backend via REST API
4. Firebase handles Claude API calls, storage, and invoice history
5. Results displayed in WordPress, files stored in Firebase Storage

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         WordPress Site                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  MemberPress (Authentication & Membership Tiers)           │ │
│  │  - Free Tier: 10 invoices/month                            │ │
│  │  - Pro Tier: Unlimited invoices                            │ │
│  │  - Custom Tiers: Configurable                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  WordPress Plugin: Invoice Generator                       │ │
│  │  - Shortcode: [invoice_generator]                          │ │
│  │  - Admin Dashboard: Settings & Analytics                   │ │
│  │  - User Dashboard: Upload & History                        │ │
│  │  - REST API Client: Calls Firebase                         │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↓ HTTPS
                    (Firebase REST API)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Firebase Cloud Service                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Cloud Functions (Node.js/TypeScript)                      │ │
│  │  - POST /api/extract-invoice                               │ │
│  │  - GET  /api/invoices                                      │ │
│  │  - POST /api/invoices                                      │ │
│  │  - GET  /api/clients                                       │ │
│  │  - POST /api/clients                                       │ │
│  │  - GET  /api/usage                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Firebase Services                                         │ │
│  │  - Firestore: Invoice & client data                        │ │
│  │  - Storage: Bank statement files, generated PDFs           │ │
│  │  - Secret Manager: Anthropic API key                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Claude API (Anthropic)                                    │ │
│  │  - Vision + Tool Use for extraction                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. WordPress Plugin Structure

```
wp-invoice-generator/
├── invoice-generator.php          # Main plugin file
├── readme.txt                      # WordPress.org readme
├── includes/
│   ├── class-invoice-generator.php         # Core plugin class
│   ├── class-firebase-api-client.php       # Firebase REST API client
│   ├── class-memberpress-integration.php   # MemberPress hooks
│   ├── class-usage-tracker.php             # Track user usage
│   └── class-invoice-renderer.php          # PDF generation (client-side)
├── admin/
│   ├── class-admin-settings.php            # Plugin settings page
│   ├── class-admin-analytics.php           # Usage analytics dashboard
│   └── views/
│       ├── settings.php                    # Settings template
│       └── analytics.php                   # Analytics template
├── public/
│   ├── class-public-interface.php          # Frontend shortcode handler
│   ├── css/
│   │   └── invoice-generator.css           # Styles
│   └── js/
│       ├── invoice-generator.js            # Main JS (React embedded)
│       └── pdf-generator.js                # html2pdf.js wrapper
├── templates/
│   ├── invoice-form.php                    # Invoice upload/edit form
│   ├── invoice-history.php                 # User's invoice history
│   └── usage-display.php                   # Usage meter display
└── assets/
    ├── icon.svg                            # Plugin icon
    └── banner.png                          # WordPress.org banner
```

### 2. MemberPress Integration

**Membership Tiers (Configured in MemberPress):**

| Tier | Price | Invoice Limit | Features |
|------|-------|---------------|----------|
| Free | $0/month | 10/month | Basic extraction, 30-day history |
| Pro | $19/month | Unlimited | Unlimited extraction, saved clients, unlimited history |
| Business | $49/month | Unlimited | Pro + API access, priority support |

**Plugin Integration Points:**

1. **Usage Tracking:**
   - Hook into MemberPress membership data
   - Check user's current plan before allowing extraction
   - Display usage meter based on plan limits

2. **Access Control:**
   - Use `memberpress_is_user_active()` to verify membership
   - Check plan level with `$mepr_user->active_product_subscriptions()`
   - Block extraction if over limit (free tier)

3. **Upgrade Prompts:**
   - Display upgrade CTA when user hits limit
   - Use MemberPress checkout URLs for seamless upgrade

**Code Example:**
```php
// Check if user can extract invoice
function can_user_extract_invoice($user_id) {
    // Check if MemberPress is active
    if (!class_exists('MeprUser')) {
        return false;
    }

    $mepr_user = new MeprUser($user_id);

    // Get user's active subscriptions
    $subscriptions = $mepr_user->active_product_subscriptions();

    if (empty($subscriptions)) {
        // Free tier
        $usage_this_month = get_user_usage_count($user_id);
        return $usage_this_month < 10;
    }

    // Check plan level
    foreach ($subscriptions as $subscription) {
        $membership = new MeprProduct($subscription->product_id);

        // Pro or Business tier = unlimited
        if (in_array($membership->post_name, ['pro', 'business'])) {
            return true;
        }
    }

    return false;
}
```

### 3. Firebase API Client

**Authentication Strategy:**

Option A: **Service Account (Recommended)**
- WordPress plugin uses Firebase Admin SDK service account
- All requests authenticated as service account
- WordPress user ID passed as custom claim/parameter
- Simpler architecture, no OAuth flow needed

Option B: **Custom Token per User**
- WordPress generates Firebase custom tokens per user
- More complex, but better security isolation
- Each user gets their own Firebase auth session

**Recommendation:** Use Option A for MVP, migrate to Option B if security requirements demand it.

**API Client Class:**
```php
class Firebase_API_Client {
    private $base_url;
    private $api_key;

    public function __construct() {
        $this->base_url = get_option('invoice_gen_firebase_url');
        $this->api_key = get_option('invoice_gen_firebase_api_key');
    }

    /**
     * Extract invoice from uploaded file
     */
    public function extract_invoice($file_path, $user_id) {
        $file_data = base64_encode(file_get_contents($file_path));
        $mime_type = mime_content_type($file_path);

        $response = wp_remote_post($this->base_url . '/api/extract-invoice', [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->api_key,
                'Content-Type' => 'application/json',
            ],
            'body' => json_encode([
                'user_id' => $user_id,
                'file_data' => $file_data,
                'file_type' => $mime_type,
            ]),
            'timeout' => 60, // Claude API can take time
        ]);

        if (is_wp_error($response)) {
            return ['error' => $response->get_error_message()];
        }

        return json_decode(wp_remote_retrieve_body($response), true);
    }

    /**
     * Get user's invoice history
     */
    public function get_invoices($user_id, $limit = 10, $offset = 0) {
        $response = wp_remote_get($this->base_url . '/api/invoices', [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->api_key,
            ],
            'body' => [
                'user_id' => $user_id,
                'limit' => $limit,
                'offset' => $offset,
            ],
        ]);

        if (is_wp_error($response)) {
            return ['error' => $response->get_error_message()];
        }

        return json_decode(wp_remote_retrieve_body($response), true);
    }

    /**
     * Get user's monthly usage
     */
    public function get_usage($user_id) {
        $response = wp_remote_get($this->base_url . '/api/usage', [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->api_key,
            ],
            'body' => [
                'user_id' => $user_id,
                'period' => 'month',
            ],
        ]);

        if (is_wp_error($response)) {
            return ['error' => $response->get_error_message()];
        }

        return json_decode(wp_remote_retrieve_body($response), true);
    }

    // Additional methods: save_client(), get_clients(), save_invoice()...
}
```

### 4. Frontend Interface

**Shortcode: `[invoice_generator]`**

Renders the invoice generator interface on any WordPress page/post.

**Features:**
- File upload (drag-and-drop, multi-file support)
- Real-time extraction progress
- Editable line items table
- Invoice preview
- PDF download
- Save to history
- Usage meter display

**Implementation:**
- Reuse React components from V1 (browser-only version)
- Bundle with Webpack/Vite
- Enqueue as WordPress script
- Pass WordPress user data via localized script

**Template Hierarchy:**
1. Plugin template: `templates/invoice-form.php`
2. Theme override: `{theme}/invoice-generator/form.php`

---

## API Endpoints (Firebase Cloud Functions)

### Required for WordPress Integration

#### 1. **POST /api/extract-invoice**
Extract line items from uploaded bank statement.

**Request:**
```json
{
  "user_id": "wp_123",
  "file_data": "base64_encoded_file",
  "file_type": "image/png" | "application/pdf"
}
```

**Response:**
```json
{
  "success": true,
  "line_items": [
    {
      "date": "2025-11-15",
      "description": "Web hosting - HostGator",
      "amount": 29.99
    }
  ],
  "extraction_id": "extract_abc123",
  "usage_count": 3,
  "usage_limit": 10
}
```

#### 2. **GET /api/usage**
Get user's current usage for the billing period.

**Request:**
```
GET /api/usage?user_id=wp_123&period=month
```

**Response:**
```json
{
  "success": true,
  "user_id": "wp_123",
  "period": "2025-11",
  "usage_count": 3,
  "usage_limit": 10,
  "reset_date": "2025-12-01T00:00:00Z"
}
```

#### 3. **POST /api/invoices**
Save generated invoice.

**Request:**
```json
{
  "user_id": "wp_123",
  "invoice_data": {
    "invoice_number": "11302025-1",
    "client": {...},
    "line_items": [...],
    "total": 1234.56,
    "date": "2025-11-30"
  },
  "pdf_url": "https://storage.firebase.com/..."
}
```

**Response:**
```json
{
  "success": true,
  "invoice_id": "inv_xyz789",
  "created_at": "2025-11-30T12:00:00Z"
}
```

#### 4. **GET /api/invoices**
Get user's invoice history.

**Request:**
```
GET /api/invoices?user_id=wp_123&limit=10&offset=0
```

**Response:**
```json
{
  "success": true,
  "invoices": [
    {
      "invoice_id": "inv_xyz789",
      "invoice_number": "11302025-1",
      "client_name": "Acme Corp",
      "total": 1234.56,
      "date": "2025-11-30",
      "pdf_url": "https://storage.firebase.com/..."
    }
  ],
  "total_count": 47,
  "has_more": true
}
```

#### 5. **POST /api/clients**
Save client profile.

**Request:**
```json
{
  "user_id": "wp_123",
  "client": {
    "name": "Acme Corp",
    "email": "billing@acme.com",
    "address": "123 Main St...",
    "phone": "555-1234"
  }
}
```

**Response:**
```json
{
  "success": true,
  "client_id": "client_abc123"
}
```

#### 6. **GET /api/clients**
Get user's saved clients.

**Request:**
```
GET /api/clients?user_id=wp_123
```

**Response:**
```json
{
  "success": true,
  "clients": [
    {
      "client_id": "client_abc123",
      "name": "Acme Corp",
      "email": "billing@acme.com",
      "last_invoice_date": "2025-11-30"
    }
  ]
}
```

---

## Authentication & Security

### WordPress → Firebase Authentication

**Approach: Service Account with User ID Mapping**

1. **WordPress Plugin Configuration:**
   - Admin enters Firebase project URL
   - Admin enters service account API key (stored encrypted in wp_options)
   - API key has restricted permissions (only call specific Cloud Functions)

2. **Request Flow:**
   ```
   WordPress User (authenticated via MemberPress)
        ↓
   WordPress Plugin (captures user ID)
        ↓
   Firebase Cloud Functions (receives user_id as parameter)
        ↓
   Firestore (stores data namespaced by user_id)
   ```

3. **Security Measures:**
   - API key stored encrypted in WordPress database
   - All requests include WordPress user ID
   - Firebase validates user_id format (prevent injection)
   - Firestore security rules enforce user_id isolation
   - Rate limiting on Cloud Functions (prevent abuse)

**Firestore Security Rules:**
```javascript
// Only allow access to user's own data
match /users/{userId}/invoices/{invoiceId} {
  // WordPress service account can read/write with user_id parameter
  allow read, write: if request.auth != null;
}
```

### Data Isolation

Each WordPress user's data is namespaced in Firestore:

```
/users
  /wp_123
    /invoices
      /inv_001
      /inv_002
    /clients
      /client_001
    /usage
      /2025-11
```

---

## Data Flow Examples

### Example 1: User Uploads Bank Statement

1. **WordPress:** User uploads file via `[invoice_generator]` shortcode
2. **WordPress Plugin:** Validates file type, checks usage limit
3. **WordPress Plugin → Firebase:** POST `/api/extract-invoice` with base64 file
4. **Firebase Cloud Function:**
   - Saves file to Storage
   - Calls Claude API with vision
   - Extracts line items via tool use
   - Increments usage counter in Firestore
5. **Firebase → WordPress Plugin:** Returns line items JSON
6. **WordPress Plugin → Frontend:** Displays editable line items table
7. **User:** Reviews, edits, adds invoice metadata
8. **WordPress Plugin:** Generates PDF client-side (html2pdf.js)
9. **WordPress Plugin → Firebase:** POST `/api/invoices` with invoice data + PDF
10. **Firebase:** Saves invoice to Firestore, PDF to Storage
11. **WordPress:** Displays success message + download link

### Example 2: User Views Invoice History

1. **WordPress:** User navigates to invoice history page
2. **WordPress Plugin:** Shortcode `[invoice_history]` detected
3. **WordPress Plugin → Firebase:** GET `/api/invoices?user_id=wp_123`
4. **Firebase:** Queries Firestore for user's invoices
5. **Firebase → WordPress Plugin:** Returns invoice list with PDF URLs
6. **WordPress:** Renders table with download buttons

### Example 3: Usage Limit Check

1. **WordPress:** User clicks "Extract Items" button
2. **WordPress Plugin:** Checks MemberPress membership tier
3. **If Free Tier:**
   - **WordPress Plugin → Firebase:** GET `/api/usage?user_id=wp_123`
   - **Firebase:** Returns usage count (e.g., 9/10)
   - **WordPress Plugin:** Allows extraction, displays "1 extraction remaining"
4. **If Over Limit:**
   - **WordPress Plugin:** Blocks extraction
   - Displays upgrade CTA with MemberPress checkout link

---

## Implementation Phases

### Phase 1: Firebase API Enhancements (Week 1)
**Goal:** Add WordPress-specific endpoints to Firebase Cloud Functions

**Tasks:**
- [ ] Add `/api/extract-invoice` endpoint (accept user_id parameter)
- [ ] Add `/api/usage` endpoint (track extractions per user per month)
- [ ] Add `/api/invoices` CRUD endpoints
- [ ] Add `/api/clients` CRUD endpoints
- [ ] Update Firestore security rules (namespace by user_id)
- [ ] Add request validation (user_id format, rate limiting)
- [ ] Test all endpoints with Postman

**Deliverables:**
- Firebase Cloud Functions with WordPress API
- API documentation (request/response schemas)
- Postman collection for testing

---

### Phase 2: WordPress Plugin Core (Week 2)
**Goal:** Build WordPress plugin foundation

**Tasks:**
- [ ] Create plugin structure (files, directories)
- [ ] Register plugin with WordPress
- [ ] Create admin settings page (Firebase URL, API key)
- [ ] Build Firebase API client class
- [ ] Implement error handling and logging
- [ ] Add activation/deactivation hooks
- [ ] Create database tables (if needed for caching)

**Deliverables:**
- Installable WordPress plugin (v0.1)
- Admin settings page (configure Firebase connection)
- API client class (tested with Firebase)

---

### Phase 3: MemberPress Integration (Week 2)
**Goal:** Integrate with MemberPress for membership tiers

**Tasks:**
- [ ] Create MemberPress integration class
- [ ] Hook into membership checks
- [ ] Implement usage tracking (free tier = 10/month)
- [ ] Add usage meter display (shortcode: `[invoice_usage]`)
- [ ] Create upgrade CTAs (link to MemberPress checkout)
- [ ] Test with different membership tiers
- [ ] Add fallback for non-MemberPress sites (optional)

**Deliverables:**
- MemberPress integration class
- Usage tracking system
- Usage meter shortcode

---

### Phase 4: Frontend Interface (Week 3)
**Goal:** Build user-facing invoice generator interface

**Tasks:**
- [ ] Port React components from V1 (invoice-generator.html)
- [ ] Create shortcode: `[invoice_generator]`
- [ ] Implement file upload (drag-and-drop, multi-file)
- [ ] Add real-time extraction progress indicator
- [ ] Create editable line items table
- [ ] Add invoice preview with PDF download
- [ ] Implement saved clients dropdown
- [ ] Add responsive styles (mobile-friendly)
- [ ] Bundle JS/CSS with Webpack/Vite

**Deliverables:**
- Shortcode `[invoice_generator]`
- Fully functional frontend interface
- PDF generation (client-side)

---

### Phase 5: Invoice History & Management (Week 3)
**Goal:** Allow users to view and manage past invoices

**Tasks:**
- [ ] Create shortcode: `[invoice_history]`
- [ ] Display invoice list (table with pagination)
- [ ] Add search/filter (by client, date range)
- [ ] Implement PDF download links
- [ ] Add "Re-use" button (load invoice data into generator)
- [ ] Add delete invoice functionality
- [ ] Cache invoice list in WordPress (reduce API calls)

**Deliverables:**
- Shortcode `[invoice_history]`
- Invoice management interface

---

### Phase 6: Admin Dashboard & Analytics (Week 4)
**Goal:** Provide site admin with usage analytics and monitoring

**Tasks:**
- [ ] Create admin analytics page
- [ ] Display total extractions (site-wide)
- [ ] Show top users by usage
- [ ] Display monthly trends (chart.js)
- [ ] Add Firebase connection status indicator
- [ ] Implement error log viewer
- [ ] Add manual usage reset (for testing)

**Deliverables:**
- Admin analytics dashboard
- Usage monitoring tools

---

### Phase 7: Testing & Security Hardening (Week 4)
**Goal:** Ensure plugin is secure and bug-free

**Tasks:**
- [ ] Security audit (nonce checks, input sanitization)
- [ ] Test with different WordPress versions
- [ ] Test with different themes
- [ ] Test MemberPress integration (all tiers)
- [ ] Load testing (simulate 100 concurrent users)
- [ ] Add error recovery (Firebase downtime)
- [ ] Write user documentation

**Deliverables:**
- Tested, secure plugin
- User documentation (setup guide)

---

### Phase 8: Deployment & Launch (Week 4)
**Goal:** Deploy to production

**Tasks:**
- [ ] Deploy updated Firebase Cloud Functions
- [ ] Install plugin on production WordPress site
- [ ] Configure MemberPress membership tiers
- [ ] Set up monitoring (Firebase alerts, WordPress logs)
- [ ] Create launch announcement
- [ ] Monitor usage and errors (first 48 hours)

**Deliverables:**
- Live WordPress integration
- Monitoring dashboard

---

## Configuration & Settings

### WordPress Admin Settings Page

**Plugin Settings (wp-admin → Settings → Invoice Generator):**

| Setting | Description | Default |
|---------|-------------|---------|
| Firebase URL | Base URL for Cloud Functions | `https://us-central1-project-id.cloudfunctions.net` |
| API Key | Service account key for authentication | *(encrypted)* |
| Enable MemberPress | Use MemberPress for membership tiers | `true` |
| Free Tier Limit | Extractions per month for free users | `10` |
| Default Company Info | Pre-fill company info in invoices | *(form fields)* |
| Cache Duration | How long to cache invoice list | `1 hour` |
| Debug Mode | Enable verbose logging | `false` |

### MemberPress Configuration

**Membership Tiers:**

1. Create products in MemberPress:
   - **Free** (free): 10 extractions/month
   - **Pro** ($19/month): Unlimited extractions
   - **Business** ($49/month): Unlimited + API access

2. Assign membership slugs:
   - Free: `invoice-free`
   - Pro: `invoice-pro`
   - Business: `invoice-business`

3. Configure product access:
   - Add page with `[invoice_generator]` shortcode
   - Set access rules in MemberPress (all tiers can access)

---

## User Experience Flows

### Flow 1: New User (Free Tier)

1. User registers on WordPress site (MemberPress registration)
2. User navigates to "Invoice Generator" page
3. Plugin detects first-time user, shows welcome message
4. User uploads bank statement
5. Plugin extracts line items (usage: 1/10)
6. User generates invoice, downloads PDF
7. Invoice saved to history
8. Usage meter shows "9 extractions remaining"

### Flow 2: Free User Hits Limit

1. User attempts 11th extraction (over limit)
2. Plugin blocks extraction
3. Display message: "You've used all 10 free extractions this month"
4. Show upgrade CTA button → MemberPress checkout (Pro tier)
5. User upgrades to Pro
6. Plugin detects new membership tier
7. User can now extract unlimited invoices

### Flow 3: Pro User Workflow

1. Pro user uploads multiple bank statements
2. Plugin processes all files (no limit check)
3. User reviews combined line items
4. User selects saved client from dropdown
5. Invoice auto-fills client info
6. User previews and downloads PDF
7. Invoice saved to history
8. User navigates to history page, downloads past invoices

---

## Technical Considerations

### 1. **File Upload Handling**

**WordPress → Firebase:**
- WordPress temporarily stores uploaded file (`wp_upload_dir()`)
- Plugin converts file to base64
- Sends to Firebase via API
- Deletes temporary file after processing
- Firebase saves original file to Storage (audit trail)

**Limitations:**
- PHP `upload_max_filesize` may need to be increased (default: 2MB)
- Recommend 10MB limit for PDF statements
- Add server-side validation (file type, size)

### 2. **PDF Generation**

**Where to generate PDFs:**

Option A: **Client-side (Recommended for MVP)**
- Reuse html2pdf.js from V1
- Generate PDF in user's browser
- Upload PDF to Firebase Storage
- Pros: No server load, faster
- Cons: User must keep browser open

Option B: **Server-side (Future enhancement)**
- Use Puppeteer in Cloud Function
- Generate high-quality PDF server-side
- Pros: Better quality, no browser dependency
- Cons: Higher cost, slower

**Recommendation:** Start with Option A, migrate to Option B if users report issues.

### 3. **Caching Strategy**

**What to cache in WordPress:**
- Invoice list (1 hour TTL)
- Saved clients (until user makes changes)
- Usage count (5 minute TTL)

**What NOT to cache:**
- Extraction results (always fresh from Firebase)
- PDF URLs (may expire if using signed URLs)

**Implementation:**
```php
// Cache invoice list
$cache_key = 'invoice_list_' . $user_id;
$cached = get_transient($cache_key);

if ($cached === false) {
    $invoices = $firebase_client->get_invoices($user_id);
    set_transient($cache_key, $invoices, HOUR_IN_SECONDS);
} else {
    $invoices = $cached;
}
```

### 4. **Error Handling**

**Graceful degradation:**
- If Firebase is down, show cached invoice history
- If Claude API is down, allow manual line item entry
- If PDF generation fails, offer CSV export alternative

**User-facing errors:**
- Network error: "Could not connect to service. Please try again."
- Limit exceeded: "You've reached your monthly limit. Upgrade to continue."
- Invalid file: "Please upload a PNG, JPEG, or PDF file."

**Admin-facing errors:**
- Log all API errors to WordPress debug log
- Send email alerts for critical errors (optional)
- Display Firebase connection status on admin dashboard

### 5. **Performance Optimization**

**Frontend:**
- Lazy load React components (code splitting)
- Compress JS/CSS bundles
- Use CDN for html2pdf.js
- Implement upload progress indicators

**Backend:**
- Cache API responses in WordPress
- Batch API requests where possible
- Use Firebase CDN for static files
- Implement pagination for invoice history

### 6. **Mobile Responsiveness**

**Ensure mobile-friendly:**
- Drag-and-drop upload fallback (button for mobile)
- Responsive table for line items (scrollable)
- Touch-friendly buttons (larger tap targets)
- Mobile PDF preview (use browser's native PDF viewer)

---

## Deployment Checklist

### Prerequisites
- [ ] Firebase Cloud Functions deployed with WordPress API
- [ ] Firestore security rules updated
- [ ] Firebase Storage configured with CORS
- [ ] Anthropic API key stored in Secret Manager
- [ ] MemberPress installed and configured on WordPress

### Installation Steps
1. [ ] Upload plugin to WordPress (`wp-content/plugins/`)
2. [ ] Activate plugin in WordPress admin
3. [ ] Navigate to Settings → Invoice Generator
4. [ ] Enter Firebase URL and API key
5. [ ] Test connection (should show "Connected" status)
6. [ ] Configure MemberPress membership tiers
7. [ ] Create "Invoice Generator" page with `[invoice_generator]` shortcode
8. [ ] Set MemberPress access rules for the page
9. [ ] Test with different user roles (free, pro)
10. [ ] Monitor error logs for first 24 hours

---

## Future Enhancements (Post-MVP)

**Not in initial release, but planned:**

1. **Email Delivery**
   - Send invoice PDFs via email (WP Mail SMTP)
   - Customizable email templates

2. **Multiple Invoice Templates**
   - Allow admin to upload custom templates
   - Let users choose template per invoice

3. **Team Collaboration**
   - Share invoices between team members (WordPress user roles)
   - Assign invoices to specific users

4. **Advanced Analytics**
   - Revenue tracking (if invoice amounts stored)
   - Client insights (most frequent clients)
   - Extraction accuracy feedback loop

5. **API Access (Business Tier)**
   - Provide REST API for custom integrations
   - Webhooks for invoice creation

6. **Recurring Invoices**
   - Set up monthly recurring invoices
   - Auto-populate from previous invoice

7. **Payment Integration**
   - Link to Stripe/PayPal for payment tracking
   - Mark invoices as "Paid" when payment received

---

## Cost Analysis

### Monthly Operating Costs (100 Active Users)

**Firebase:**
- Cloud Functions: ~$5 (100 users × 10 extractions × $0.40 per million)
- Firestore reads/writes: ~$2
- Storage (PDFs): ~$1 (100 users × 10 invoices × 1MB × $0.026/GB)
- **Total Firebase: ~$8/month**

**Claude API:**
- 1000 extractions/month
- Average: 1 page per statement
- Cost: ~$0.02 per extraction
- **Total Claude: ~$20/month**

**Total Operating Cost: ~$28/month**

**Revenue Potential:**
- 50 users × $19/month (Pro) = $950/month
- 10 users × $49/month (Business) = $490/month
- **Total Revenue: ~$1,440/month**

**Net Profit: ~$1,412/month**

---

## Decision Gates

**After Phase 4 (Frontend Complete):**
- [ ] Can we extract invoices successfully?
- [ ] Is the UX intuitive?
- [ ] Is MemberPress integration working?

**After Phase 8 (Launch):**
- [ ] Are users actually using this?
- [ ] What's the conversion rate (free → pro)?
- [ ] Any critical bugs or issues?

**3 Months Post-Launch:**
- [ ] Is revenue covering costs?
- [ ] What features are users requesting?
- [ ] Should we continue development?

---

## Related Documents

- [ROADMAP.md](ROADMAP.md) - Milestone 2 (Cloud Service)
- [DECISIONS.md](DECISIONS.md) - Architecture decisions
- [STATUS.md](STATUS.md) - Current project status
- [CLAUDE.md](CLAUDE.md) - AI agent instructions
- Firebase branch: `claude/invoice-digitization-service-01Sgz4omcr4jJZPAZkLoSH4E`
- WordPress branch: `claude/wordpress-cloud-invoice-integration-01QPtGU199TqAm7zbmTN4Mos`

---

## Questions to Clarify

1. **WordPress Site URL:** What's the production WordPress site URL?
2. **MemberPress Setup:** Are membership tiers already configured?
3. **Target Launch Date:** When do you want this live?
4. **Feature Priority:** Any specific features you want in v1 vs. later?
5. **Design Preferences:** Should plugin match your WordPress theme style?

---

**Next Steps:** Review this plan, provide feedback, and we'll start implementation!
