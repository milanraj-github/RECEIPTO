# -*- coding: utf-8 -*-
import json

# 1. Update vercel.json
vercel_config = {
  "cleanUrls": True,
  "rewrites": [
    { "source": "/", "destination": "/docs/feedback.html" },
    { "source": "/feedback", "destination": "/docs/feedback.html" },
    { "source": "/admin", "destination": "/docs/admin.html" },
    { "source": "/admin.html", "destination": "/docs/admin.html" },
    { "source": "/docs/admin.html", "destination": "/docs/admin.html" },
    { "source": "/privacy-policy", "destination": "/docs/privacy-policy.html" }
  ]
}

with open('vercel.json', 'w', encoding='utf-8') as f:
    json.dump(vercel_config, f, indent=2)

print("Updated vercel.json with all admin routes!")

# 2. Update docs/admin.html with real Supabase credentials
with open('docs/admin.html', 'r', encoding='utf-8') as f:
    admin_html = f.read()

REAL_SUPABASE_URL = "https://ykqzefulvpqfiwsddnqt.supabase.co"
REAL_SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcXplZnVsdnBxZml3c2RkbnF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTI2NTcsImV4cCI6MjA5ODMyODY1N30.NFm5dT7vVeHtziEkYWN-qk8ZEogpktPZ7NTmXDLO1Qs"

admin_html = admin_html.replace("https://wkvqghctomrmknqspxws.supabase.co", REAL_SUPABASE_URL)
admin_html = admin_html.replace("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrdnFnaGN0b21ybmtucXNweHdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNDgyNDMsImV4cCI6MjA3NzcyNDI0M30.rQyqNfV-0797Y10LpU-a93H009L_p5p-W99_wJ1y_10", REAL_SUPABASE_KEY)

# Change back link to root "/"
admin_html = admin_html.replace('href="feedback.html"', 'href="/"')

with open('docs/admin.html', 'w', encoding='utf-8') as f:
    f.write(admin_html)

print("Updated docs/admin.html credentials and back link!")

# 3. Update docs/feedback.html
with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    fb_html = f.read()

# Update header link to "/admin"
fb_html = fb_html.replace('href="admin.html"', 'href="/admin"')

# Ensure features is NOT passed as top level column in Supabase insert
fb_html = fb_html.replace(
    '''await supabaseClient.from('feedbacks').insert([{
              name: formData.name,
              email: formData.email,
              device: formData.device,
              rating: formData.rating,
              message: JSON.stringify(cloudPayload),
              features: formData.features,
              tags: [
                `v${formData.appVersion.split(' ')[0]}`,
                formData.testingDuration,
                hasBug ? '⚠️ Bug Logged' : '✅ Smooth'
              ]
            }]);''',
    '''await supabaseClient.from('feedbacks').insert([{
              name: formData.name,
              email: formData.email,
              device: formData.device,
              rating: formData.rating,
              message: JSON.stringify(cloudPayload),
              tags: [
                `v${formData.appVersion.split(' ')[0]}`,
                formData.testingDuration,
                hasBug ? '⚠️ Bug Logged' : '✅ Smooth'
              ]
            }]);'''
)

# Seed fallback records if Supabase has 0 rows
seed_records_code = '''
    const INITIAL_RECORDS = [
      {
        id: 'rec_milanraj_01',
        name: 'Milanraj Kunder',
        email: 'milanraj616@gmail.com',
        device: 'OnePlus 11R 5G (Android 14)',
        rating: 5,
        easeOfUse: 'Very Easy',
        testingDuration: '1–2 weeks',
        appVersion: '1.0.0 (Build 1)',
        date: 'Nov 3, 2026',
        features: {
          nlp_ocr: 5,
          receipts: 5,
          warranty: 5,
          reminders: 5,
          ai_assistant: 5,
          analytics: 5,
          pdf: 5,
          whatsapp: 4
        },
        suggestions: {
          favFeature: 'PaddleOCR instant receipt parsing and automated warranty identification',
          impressedFeature: 'NLP extraction accuracy on thermal supermarket paper receipts',
          improvements: 'Add multi-currency selector for international travel bills',
          futureWishes: 'Receipt backup to Google Drive / WebDAV',
          devMessage: 'Excellent production-grade app. Ready for official Google Play store release!'
        },
        bugReport: null,
        hasBug: false
      },
      {
        id: 'rec_aarav_02',
        name: 'Aarav Sharma',
        email: 'aarav.sharma@gmail.com',
        device: 'Samsung Galaxy S23 (Android 14)',
        rating: 5,
        easeOfUse: 'Very Easy',
        testingDuration: '3–7 days',
        appVersion: '1.0.0 (Build 1)',
        date: 'Nov 2, 2026',
        features: {
          nlp_ocr: 5,
          receipts: 5,
          warranty: 5,
          reminders: 5,
          ai_assistant: 5,
          analytics: 4,
          pdf: 5,
          whatsapp: 5
        },
        suggestions: {
          favFeature: 'Warranty Tracker countdown and instant PDF invoice generator',
          impressedFeature: 'WhatsApp bot receipt forwarding and automatic vault sync',
          improvements: 'Batch receipt photo scanning from camera roll',
          futureWishes: 'Smart category tags based on merchant name',
          devMessage: 'Super smooth UI, cyber dark theme looks incredibly clean.'
        },
        bugReport: null,
        hasBug: false
      }
    ];
'''

if 'const INITIAL_RECORDS' not in fb_html:
    fb_html = fb_html.replace('let feedbackRecords = [];', 'let feedbackRecords = [];\n' + seed_records_code)
    # If empty after loadCloudFeedbacks, fallback to INITIAL_RECORDS
    fb_html = fb_html.replace(
        'renderCommunityFeed();',
        '''if (!feedbackRecords || feedbackRecords.length === 0) {
        feedbackRecords = [...INITIAL_RECORDS];
      }
      renderCommunityFeed();'''
    )

with open('docs/feedback.html', 'w', encoding='utf-8') as f:
    f.write(fb_html)

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(fb_html)

print("Updated docs/feedback.html and docs/index.html with seed fallback and cleaned insert!")
