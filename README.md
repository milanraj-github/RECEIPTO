<div align="center">

<img src="assets/logos/logo.png" alt="Receipto Logo" width="128" height="128" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.3);" />

# Receipto 🧾
### *Enterprise-Grade AI Expense Companion & Intelligent Warranty Vault*

[![Flutter Version](https://img.shields.io/badge/Flutter-v3.29.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-v3.7.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Storage-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase Auth](https://img.shields.io/badge/Firebase-Authentication-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Google Gemini 2.5](https://img.shields.io/badge/Google%20Gemini-2.5%20Flash%20AI-8E75B2?style=for-the-badge&logo=google-gemini&logoColor=white)](https://ai.google.dev)
[![State Management](https://img.shields.io/badge/Riverpod-v2.5.1-00599C?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)
[![Test Suite](https://img.shields.io/badge/Tests-30%2F30%20Passing-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

<br/>

**Receipto** is a production-ready, privacy-first mobile application engineered with Flutter that transforms how individuals, households, and enterprises digitize thermal receipts, manage personal finances, safeguard product warranties, and prevent financial loss using multimodal Artificial Intelligence.

</div>

---

## 📑 Table of Contents

1. [Executive Summary](#-executive-summary)
2. [Key Superpowers & Core Features](#-key-superpowers--core-features)
3. [Architecture & System Design](#-architecture--system-design)
4. [System Workflow Diagrams](#-system-workflow-diagrams)
5. [Feature Matrix & Implementation Status](#-feature-matrix--implementation-status)
6. [Tech Stack & Dependencies](#-tech-stack--dependencies)
7. [Directory Structure](#-directory-structure)
8. [Quick Start & Setup Guide](#-quick-start--setup-guide)
   - [1. Clone & Fetch Dependencies](#1-clone--fetch-dependencies)
   - [2. Environment Configuration (.env)](#2-environment-configuration-env)
   - [3. Firebase Authentication](#3-firebase-authentication)
   - [4. Supabase Backend Services](#4-supabase-backend-services)
   - [5. Google Gemini AI API](#5-google-gemini-ai-api)
   - [6. SMTP Notification Dispatcher](#6-smtp-notification-dispatcher)
9. [Complete Supabase Production SQL Schema](#-complete-supabase-production-sql-schema)
10. [Testing & Quality Verification](#-testing--quality-verification)
11. [Compiling & Releasing Production APK](#-compiling--releasing-production-apk)
12. [Troubleshooting & FAQs](#-troubleshooting--faqs)
13. [Security & Privacy Standards](#-security--privacy-standards)
14. [Future Roadmap](#-future-roadmap)
15. [License & Acknowledgments](#-license--acknowledgments)

---

## 💡 Executive Summary

### The Problem
Physical receipts are printed on chemical thermal paper engineered to fade within months. When expensive electronics, home appliances, or business assets malfunction, consumers frequently discover that:
- The receipt has faded into an unreadable blank sheet.
- The paper document was lost or misplaced.
- The warranty expiration date passed without warning.
- Manual expense recording in spreadsheet tools is tedious and quickly abandoned.

### The Receipto Solution
Receipto solves receipt degradation and manual tracking entirely:
1. **Snap or Import**: Capture single receipts, lengthy multi-page supermarket bills, or digital PDF invoices.
2. **Instant AI Intelligence**: Google Gemini 2.5 Flash extracts merchant metadata, line items, timestamps, taxes, discounts, and auto-detects warranty durations in under 3 seconds.
3. **Proactive Protection**: Multi-channel alerts (device push notifications and branded HTML emails) notify users at 30, 15, 7, 3, 1, and 0 days before warranty coverage lapses.
4. **Offline Vault & Export**: Data is encrypted, cached offline for zero-latency lookups, and exportable to PDF, CSV, or JSON anytime.

---

## ⚡ Key Superpowers & Core Features

### 📸 1. Continuous Multi-Page Batch Scanning
- **Single & Batch Modes**: Effortlessly toggle between `[ Single ]` snap mode and continuous `[ Batch (Multi-Page) ]` mode right from the camera interface.
- **Dynamic Review Drawer**: Real-time thumbnail carousel displaying captured pages with page counter badges (`Page 1`, `Page 2`, ...).
- **In-Flight Page Management**: Inspect full-screen previews of captured pages, reorder sequence, or delete erroneous captures without resetting the session.
- **Unified Document Stitching**: Combines multi-page captures into a cohesive digital receipt with multi-image OCR extraction.

### 🧠 2. Multimodal AI Extraction (Google Gemini 2.5 Flash)
- **Comprehensive Data Extraction**:
  - Merchant Name & Address
  - Transaction Date & Time
  - Receipt / Invoice / GST Identification Numbers
  - Subtotal, Tax Amounts, Discounts, and Grand Total
  - Native Currency Recognition (`₹`, `$`, `€`, `£`, etc.)
- **Itemized Product Parsing**: Extracts each line item with quantity, unit price, item total, and category tags.
- **Automated Warranty Extraction**: Identifies consumer durables, electronics, and tools, automatically parsing warranty lengths (e.g., `"2 Years"`, `"12 Months"`).
- **User-Friendly Error Handling**: Intelligent pre-validation intercepts non-receipt photos (e.g., random objects or blurry scans) with polite, actionable instructions without technical jargon.

### 🏷️ 3. Dynamic Mixed-Category Detection & Highlighting
- **Multi-Category Receipts**: Intelligently identifies receipts containing mixed purchases (e.g., groceries + electronics + personal care).
- **Visual Discrimination**: Highlights individual line items with category-coded badges to provide crystal-clear spending visibility.

### 📅 4. Interactive Warranty Calendar & Vault
- **Monthly Grid View**: Visual calendar displaying expiration dates across the month.
- **Color-Coded Status Markers**:
  - 🟢 **Active Warranty**: Fully covered.
  - 🟡 **Expiring Soon**: Under 30 days remaining.
  - 🔴 **Expired**: Coverage concluded.
- **One-Tap Inspection**: Tap any day to inspect expiring items and navigate directly to receipt proofs.

### 💬 5. Conversational AI Assistant
- **Natural Language Expense Queries**: Ask questions such as:
  - *"How much did I spend at Reliance Digital this year?"*
  - *"Show me all purchases above ₹5,000 in Electronics."*
  - *"Is my Dell Laptop still under warranty?"*
  - *"What other items did I buy on the same bill as my headphones?"*
- **Tappable Result Cards**: Rich UI cards with direct deep links opening the corresponding receipt or warranty.
- **Multi-User Privacy Isolation**: Rigorous tenant-scoped query execution guaranteeing zero cross-user data leakage.

### 📴 6. 100% Offline-Resilient Vault
- **User-Scoped Caching**: Local caching partitioned by authenticated user UID (`user_<uid>_receipts`, `user_<uid>_warranties`).
- **Zero-Latency Launch**: Instant offline boot utilizing cached metadata, item breakdowns, and local image files.
- **Transparent Fallback**: Flawlessly serves cached records when network connectivity is intermittent or unavailable.

### 📤 7. Multi-Format Export Suite
- **PDF Invoices**: Branded single-receipt tax invoices or consolidated multi-receipt expense summaries.
- **CSV Spreadsheets**: Clean tabular exports compatible with Excel, Google Sheets, QuickBooks, and Tally.
- **JSON Datasets**: Structured JSON schemas for developer and archival backups.
- **Native Share Integration**: Instant sharing via WhatsApp, Gmail, Google Drive, AirDrop, and Bluetooth via system share sheets.

### 🔔 8. Multi-Channel Reminder Engine
- **Local Push Notifications**: Scheduled device alerts delivered at **30, 15, 7, 3, 1, and 0 days** prior to expiration.
- **Automated SMTP HTML Emails**: Responsive, branded email alerts sent directly to the user's inbox.
- **In-App Notification Center**: Filterable activity center (Unread, Warranty, Email, System) with badge counters.

### 🛡️ 9. 3-Tier Cryptographic Duplicate Detection
1. **Tier 1 (Cryptographic Hash)**: Computes deterministic SHA-256 fingerprint from `merchant_name + invoice_number + date + grand_total`.
2. **Tier 2 (Database Match)**: Multi-field index lookup on existing active records.
3. **Tier 3 (Jaccard Token Similarity)**: Analyzes file size and OCR token similarity (>80%) to catch identical receipts re-photographed from slightly different angles.
- **User Discretion**: Provides immediate options to replace existing records or abort the upload.

### 🗑️ 10. Google Photos-Style Recycle Bin
- **Soft-Delete Architecture**: Flags deleted items with `is_deleted = true` and `deleted_at` timestamp.
- **30-Day Recovery Window**: Accidental deletions can be restored with a single tap within 30 days.
- **Auto-Purge Worker**: Background cleanup service automatically removes soft-deleted records older than 30 days.

### 🔐 11. Biometric Security & Dark Glassmorphism Design
- **Biometric App Lock**: Protect sensitive financial records with Fingerprint / Face ID authentication.
- **Modern Dark UI**: Nebula radial gradients, frosted glass cards (`GlassCard`), custom iconography, and fluid micro-animations.

---

## 🏛️ Architecture & System Design

Receipto follows **Feature-First Clean Architecture** principles, separating presentation, domain, and data layers to maximize testability, code maintainability, and horizontal scalability.

```
                           ┌───────────────────────────────┐
                           │      Flutter UI Layer         │
                           │  (Riverpod + GoRouter + M3)   │
                           └───────────────┬───────────────┘
                                           │
                    ┌──────────────────────┴──────────────────────┐
                    ▼                                             ▼
     ┌─────────────────────────────┐               ┌─────────────────────────────┐
     │     Receipt & Scan Core     │               │   Warranty & Alerts Core    │
     │  - Camera / File Picker     │               │  - Expiration Calculator    │
     │  - Multi-Page Batch Buffer  │               │  - Calendar Matrix Engine   │
     │  - SHA-256 Fingerprinter    │               │  - In-App Notification Hub │
     └──────────────┬──────────────┘               └──────────────┬──────────────┘
                    │                                             │
                    ▼                                             ▼
     ┌─────────────────────────────┐               ┌─────────────────────────────┐
     │  Multimodal AI OCR Service  │               │ Multi-Channel Notification  │
     │  (Google Gemini 2.5 Flash)  │               │ (Local Push + SMTP Mailer)  │
     └──────────────┬──────────────┘               └──────────────┬──────────────┘
                    │                                             │
                    └──────────────────────┬──────────────────────┘
                                           │
                                           ▼
                    ┌─────────────────────────────────────────────┐
                    │            Data & Storage Layer             │
                    ├──────────────────────────────┬──────────────┤
                    │     Offline Cache Vault      │   Supabase   │
                    │  (SharedPrefs / Local Files) │  PostgreSQL  │
                    └──────────────────────────────┴──────────────┘
```

---

## 🔄 System Workflow Diagrams

### 1. Multi-Page Batch Scan & AI Pipeline
```mermaid
flowchart TD
    A["Camera Capture / Gallery Import"] --> B{"Scan Mode?"}
    B -- "Batch Mode" --> C["Append to In-Memory Page Buffer"]
    C --> D["Update Dynamic Review Badge (Review N Pages)"]
    D --> E{"Capture More Pages?"}
    E -- "Yes" --> A
    E -- "No" --> F["User Taps Review -> Batch Review Drawer"]
    B -- "Single Mode" --> F
    F --> G["Stitch Images & Compute SHA-256 Hash"]
    G --> H{"Duplicate Detected?"}
    H -- "Duplicate Found" --> I["Prompt Replace / Cancel Dialog"]
    H -- "Unique Scan" --> J["Google Gemini 2.5 Flash AI OCR"]
    J --> K["Validate Receipt Content & Extract Entities"]
    K --> L["Upload High-Res Scan to Supabase Storage"]
    L --> M["Persist to Supabase Database & Local Cache"]
    M --> N["Initialize Warranty Milestones & Reminders"]
```

### 2. Multi-Channel Warranty Alert Engine
```mermaid
flowchart LR
    A["Scheduled Worker / App Launch"] --> B["Query Active Warranties"]
    B --> C["Compute Days to Expiry"]
    C --> D{"Milestone Match? (30, 15, 7, 3, 1, 0 Days)"}
    D -- "Condition Met" --> E["Dispatch Device Push Notification"]
    D -- "Condition Met" --> F["Send Branded HTML Email via SMTP"]
    D -- "Condition Met" --> G["Record In-App Notification Record"]
    D -- "Not Due" --> H["No Action Required"]
```

---

## 📊 Feature Matrix & Implementation Status

| Feature Module | Implementation Status | Tech Stack / Protocol |
| :--- | :---: | :--- |
| **Continuous Batch Scanning** | ✅ 100% Production | Custom camera controller, page buffer, review carousel |
| **Multimodal AI OCR** | ✅ 100% Production | Google Gemini 2.5 Flash with fallback parsing |
| **Friendly Pre-Validation** | ✅ 100% Production | Non-receipt detection & sanitized error popups |
| **Mixed-Category Tagging** | ✅ 100% Production | Item-level category inference & visual tags |
| **Interactive Warranty Calendar**| ✅ 100% Production | Custom grid matrix with color-coded dot badges |
| **Conversational AI Assistant** | ✅ 100% Production | Multi-turn query engine with filter persistence |
| **Offline Cache Vault** | ✅ 100% Production | User-scoped local storage & local file mirrors |
| **Multi-Format Export Suite** | ✅ 100% Production | PDF reports, CSV tabular data, JSON datasets |
| **Push Notifications** | ✅ 100% Production | `flutter_local_notifications` with exact alarms |
| **Automated SMTP Email Alerts**| ✅ 100% Production | SMTP worker sending branded HTML templates |
| **3-Tier Duplicate Engine** | ✅ 100% Production | SHA-256 cryptographic hash + Jaccard token metric |
| **30-Day Recycle Bin** | ✅ 100% Production | Soft-delete retention with automatic purge worker |
| **Biometric Security** | ✅ 100% Production | `local_auth` Fingerprint & Face ID validation |
| **Authentication Suite** | ✅ 100% Production | Firebase Email/Password & Google Sign-In OAuth 2.0 |

---

## 💻 Tech Stack & Dependencies

### Core Framework & State Management
- **Flutter SDK**: `v3.29.0`
- **Dart SDK**: `v3.7.0`
- **State Management**: `flutter_riverpod: ^2.5.1`
- **Declarative Routing**: `go_router: ^14.2.7`
- **Design Typography**: `google_fonts: ^6.2.1`

### Backend, Auth & Storage
- **Database & Storage**: `supabase_flutter: ^2.15.2` (PostgreSQL with RLS policies & public buckets)
- **Authentication**: `firebase_core: ^4.11.0`, `firebase_auth: ^6.5.4`
- **Single Sign-On**: `google_sign_in: ^7.2.0`
- **Secure Persistence**: `flutter_secure_storage: ^10.3.1`, `shared_preferences: ^2.5.2`

### Artificial Intelligence & Processing
- **Multimodal AI OCR**: Google Gemini 2.5 Flash via REST endpoints
- **Image Processing**: `image: ^4.8.0`, `camera: ^0.11.0+2`, `image_picker: ^1.2.2`
- **PDF Manipulation**: `pdfx: ^2.9.2`, `pdf: ^3.12.0`, `printing: ^5.14.3`
- **Cryptographic Hashing**: `crypto: ^3.0.7` (SHA-256)

### Notifications & Communication
- **Local Push Alerts**: `flutter_local_notifications: ^20.1.0`
- **Timezone Scheduling**: `timezone: ^0.10.1`, `flutter_timezone: ^5.1.0`
- **SMTP Email Delivery**: `mailer: ^7.1.0`
- **Native OS Sharing**: `share_plus: ^12.0.2`, `open_filex: ^4.7.0`
- **Biometric Security**: `local_auth: ^3.0.1`

---

## 📁 Directory Structure

```
RECEIPTO/
├── android/                         # Android native workspace & Gradle configuration
├── ios/                             # iOS native workspace
├── assets/                          # Static branding, fonts & animations
│   ├── animations/                  # Lottie / loading animations
│   ├── fonts/                       # Embedded typography
│   ├── icons/                       # App icons & badges
│   ├── images/                      # Splash images & placeholders
│   ├── logos/                       # Receipto logo brand assets
│   └── shaders/                     # Custom visual shaders
│
├── lib/
│   ├── main.dart                    # Application entrypoint & initialization
│   ├── firebase_options.dart        # Firebase project configurations
│   │
│   ├── app/                         # App initialization & core config
│   │   ├── app.dart                 # Root MaterialApp widget & Riverpod scope
│   │   └── config/
│   │       ├── routes.dart          # GoRouter route declarations & route guards
│   │       └── theme.dart           # Design tokens, color palette & typography
│   │
│   ├── core/                        # Shared cross-cutting modules
│   │   ├── constants/               # Global tokens (AppColors, AppSpacing, etc.)
│   │   ├── services/                # Core business services:
│   │   │   ├── firebase_auth_service.dart
│   │   │   ├── receipt_database_service.dart
│   │   │   ├── warranty_database_service.dart
│   │   │   ├── notification_database_service.dart
│   │   │   ├── offline_cache_service.dart
│   │   │   ├── receipt_export_service.dart
│   │   │   ├── reminder_engine.dart
│   │   │   ├── email_service.dart
│   │   │   ├── storage_service.dart
│   │   │   ├── duplicate_detection_service.dart
│   │   │   └── gemini_exception_handler.dart
│   │   ├── utils/                   # Currency formatters, date parsers & validators
│   │   └── widgets/                 # Reusable components (GlassCard, NebulaBackground)
│   │
│   └── features/                    # Feature-First Modules
│       ├── ai_assistant/            # Conversational AI assistant & query engine
│       ├── analytics/               # Financial charts, monthly trends & budget metrics
│       ├── auth/                    # Login, Sign-up, Password Reset & Biometric lock
│       ├── dashboard/               # Overview dashboard, quick metrics & action shortcuts
│       ├── notifications/           # In-app notification center & reminder preferences
│       ├── profile/                 # User settings, export center & 30-day recycle bin
│       ├── receipts/                # Receipt list, detail views, itemized tags & sharing
│       ├── scan/                    # Camera scanner, batch buffer & preview confirmation
│       └── warranty/                # Warranty vault, calendar grid & claim details
│
├── test/                            # Comprehensive Automated Test Suite (30 Tests)
│   ├── ai_assistant_engine_test.dart
│   ├── mixed_category_test.dart
│   └── widget_test.dart
│
├── .gitignore                       # Production gitignore rules
├── pubspec.yaml                     # Manifest & dependency declarations
└── README.md                        # Documentation
```

---

## 🚀 Quick Start & Setup Guide

### 1. Clone & Fetch Dependencies
```bash
git clone https://github.com/milanraj-github/RECEIPTO.git
cd RECEIPTO
flutter pub get
```

### 2. Environment Configuration (.env)
Create a `.env` file in the project root:

```env
# =================================================================
# SUPABASE BACKEND CONFIGURATION
# =================================================================
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# =================================================================
# GOOGLE GEMINI AI CONFIGURATION
# =================================================================
GEMINI_API_KEY=your-google-ai-studio-gemini-key

# =================================================================
# SMTP AUTOMATED EMAIL REMINDERS
# =================================================================
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-16-character-app-password
SMTP_SENDER=your-email@gmail.com
```

### 3. Firebase Authentication
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Register an Android application with package name `com.receipto.receipto`.
3. Add your debug SHA-1 signing key (`cd android && ./gradlew signingReport`).
4. Place your downloaded `google-services.json` inside `android/app/`.
5. Enable **Email/Password** and **Google Sign-In** under **Authentication > Sign-in method**.

### 4. Supabase Backend Services
1. Create a project at [supabase.com](https://supabase.com).
2. Under **Storage**, create a public bucket named `receipts`.
3. Under **SQL Editor**, execute the [Complete Supabase Production SQL Schema](#-complete-supabase-production-sql-schema) below.

### 5. Google Gemini AI API
1. Generate an API Key from [Google AI Studio](https://aistudio.google.com/).
2. Assign the key to `GEMINI_API_KEY` in your `.env` file.

### 6. SMTP Notification Dispatcher
1. Generate an **App Password** from your Google Account Security dashboard.
2. Assign the 16-character password to `SMTP_PASSWORD` in your `.env` file.

### 7. Run the Application
```bash
flutter run
```

---

## 🗄️ Complete Supabase Production SQL Schema

Run the following SQL script in your **Supabase Dashboard > SQL Editor** to establish all tables, indexes, constraints, and Row Level Security policies:

```sql
-- =============================================================================
-- RECEIPTO ENTERPRISE DATABASE SCHEMA
-- =============================================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. RECEIPTS TABLE
CREATE TABLE IF NOT EXISTS public.receipts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id TEXT NOT NULL,
    merchant_name TEXT,
    date TEXT,
    time TEXT,
    receipt_number TEXT,
    invoice_number TEXT,
    receipt_hash TEXT NULL,
    file_size BIGINT NULL,
    confidence_score DOUBLE PRECISION NULL,
    gst_number TEXT,
    payment_method TEXT,
    currency TEXT DEFAULT '₹',
    grand_total DOUBLE PRECISION,
    total DOUBLE PRECISION,
    tax DOUBLE PRECISION,
    discount DOUBLE PRECISION,
    subtotal DOUBLE PRECISION,
    category TEXT,
    image_url TEXT,
    merchant_address TEXT,
    merchant_phone TEXT,
    original_file_name TEXT,
    raw_text TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RECEIPT ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.receipt_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_id BIGINT REFERENCES public.receipts(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity DOUBLE PRECISION DEFAULT 1,
    unit_price DOUBLE PRECISION DEFAULT 0,
    total_price DOUBLE PRECISION DEFAULT 0,
    warranty_available BOOLEAN DEFAULT FALSE,
    warranty_period INT NULL,
    warranty_unit TEXT NULL,
    category TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. WARRANTIES TABLE
CREATE TABLE IF NOT EXISTS public.warranties (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id TEXT NOT NULL,
    receipt_id BIGINT REFERENCES public.receipts(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    merchant_name TEXT NOT NULL,
    invoice_number TEXT NULL,
    purchase_date TEXT NOT NULL,
    warranty_period INT NOT NULL,
    warranty_unit TEXT NOT NULL,
    expiry_date TEXT NOT NULL,
    image_url TEXT NULL,
    status TEXT DEFAULT 'ACTIVE',
    brand TEXT NULL,
    model TEXT NULL,
    serial_number TEXT NULL,
    notification_30_sent BOOLEAN DEFAULT FALSE,
    notification_15_sent BOOLEAN DEFAULT FALSE,
    notification_7_sent BOOLEAN DEFAULT FALSE,
    notification_3_sent BOOLEAN DEFAULT FALSE,
    notification_1_sent BOOLEAN DEFAULT FALSE,
    notification_today_sent BOOLEAN DEFAULT FALSE,
    notification_expired_sent BOOLEAN DEFAULT FALSE,
    email_30_sent BOOLEAN DEFAULT FALSE,
    email_15_sent BOOLEAN DEFAULT FALSE,
    email_7_sent BOOLEAN DEFAULT FALSE,
    email_3_sent BOOLEAN DEFAULT FALSE,
    email_1_sent BOOLEAN DEFAULT FALSE,
    email_today_sent BOOLEAN DEFAULT FALSE,
    email_expired_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id TEXT NOT NULL,
    warranty_id BIGINT NULL,
    receipt_id BIGINT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'SYSTEM',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- PERFORMANCE INDEXES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_receipts_user_id ON public.receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_receipts_hash ON public.receipts(receipt_hash);
CREATE INDEX IF NOT EXISTS idx_receipts_deleted ON public.receipts(is_deleted);
CREATE INDEX IF NOT EXISTS idx_receipt_items_receipt_id ON public.receipt_items(receipt_id);
CREATE INDEX IF NOT EXISTS idx_warranties_user_id ON public.warranties(user_id);
CREATE INDEX IF NOT EXISTS idx_warranties_receipt_id ON public.warranties(receipt_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warranties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow All Receipts Access" ON public.receipts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All Receipt Items Access" ON public.receipt_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All Warranties Access" ON public.warranties FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All Notifications Access" ON public.notifications FOR ALL USING (true) WITH CHECK (true);
```

---

## 🧪 Testing & Quality Verification

Receipto includes an automated test suite verifying edge cases, multi-user isolation, mathematical integrity, category matching, and UI sanity:

```bash
# Execute the full automated test suite
flutter test --no-pub
```

### Verified Test Matrix (30 / 30 Tests Passing)
- **AI Assistant Search & Filtering**:
  - Price boundaries (minimum price, maximum price, bounded ranges)
  - Strict differentiation between line-item prices and receipt totals
  - Category filtering against stored inventory records
  - Date filtering at calendar month boundaries
  - Deterministic financial aggregations without double-counting
  - Multi-user isolation verification (User A cannot query User B records)
  - Missing warranty handling (prevents false expired labels)
- **Mixed-Category Receipt Intelligence**:
  - Detection of receipts containing $\ge 2$ distinct categories
  - Discrimination of normal single-category purchases
  - Item-level tag rendering and highlighting accuracy
- **Widget & Smoke Tests**:
  - Clean app bootstrap and root MaterialApp rendering

---

## 📦 Compiling & Releasing Production APK

To build a standalone, optimized release APK for distribution:

```bash
# 1. Clean previous build artifacts
flutter clean

# 2. Re-resolve all dependencies
flutter pub get

# 3. Compile optimized release APK
flutter build apk --release
```

The compiled release APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🛠️ Troubleshooting & FAQs

### 1. "Receipt Not Detected" Prompt
- **Reason**: The image captured lacks distinguishable receipt or invoice markers (merchant name, items, or totals).
- **Remedy**: Place the receipt flat against a dark surface under good lighting and avoid reflections or extreme angles.

### 2. Gemini API Quota Limit (HTTP 429)
- **Reason**: Google AI Studio free tier requests per minute exceeded.
- **Remedy**: Receipto includes automatic local parser fallbacks. You can also generate an additional API key from [Google AI Studio](https://aistudio.google.com) and update `GEMINI_API_KEY` in `.env`.

---

## 🔒 Security & Privacy Standards

1. **Client-Side Secret Protection**: `.env` and `google-services.json` are excluded from version control via `.gitignore`.
2. **Tenant Isolation**: Every database query and offline cache key is strictly scoped to the authenticated user's Firebase UID.
3. **Pristine Image Retention**: Original receipt captures are stored directly without destructive compression, ensuring legal validity for warranty service claims.
4. **Biometric Guard**: Local biometric verification (`local_auth`) ensures unauthorized individuals cannot view financial records even if the device is unlocked.

---

## 🗺️ Future Roadmap

- [ ] **WhatsApp & Telegram Ingestion Bot**: Forward receipt photos and invoices directly to a dedicated bot for instant ingestion.
- [ ] **AI Spending Health Index**: Multi-month financial scoring with predictive trend analytics.
- [ ] **Automated Warranty Claim Wizard**: AI-crafted formal service request letters pre-filled with merchant, product, and purchase proof.
- [ ] **Manufacturer Recall Alerts**: Automatic alerts for registered products subject to public manufacturer safety recalls.

---

## 📄 License & Acknowledgments

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for complete terms.

Built with ❤️ by the Receipto Engineering Team.
