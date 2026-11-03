# -*- coding: utf-8 -*-
"""
Applies all requested upgrades directly to docs/feedback.html and syncs to docs/index.html
"""

import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Update Full Name placeholder to "Milanraj"
html = re.sub(
    r'id="fullName"\s+placeholder="[^"]*"',
    'id="fullName" placeholder="Milanraj"',
    html
)

# 2. Update Header: Admin link to admin.html, add desktop-only to beta-badge
html = html.replace(
    '''<div class="beta-badge">Official Beta Testing Program</div>
        <button type="button" class="admin-toggle-btn" id="adminBtn" onclick="toggleAdmin()">
          <span>🔒</span> Admin Portal
        </button>''',
    '''<div class="beta-badge desktop-only">Official Closed Beta</div>
        <a href="admin.html" class="admin-toggle-btn">
          <span>🔒</span> Admin Portal
        </a>'''
)
html = html.replace(
    '''<button type="button" class="admin-toggle-btn" id="adminBtn" onclick="toggleAdmin()">
          <span>🔒</span> Admin Portal
        </button>''',
    '''<a href="admin.html" class="admin-toggle-btn">
          <span>🔒</span> Admin Portal
        </a>'''
)

# 3. Header responsive CSS
header_responsive_css = """
    /* Mobile Header Layout */
    @media (max-width: 640px) {
      header {
        padding: 10px 14px !important;
      }
      .brand-title {
        font-size: 18px !important;
      }
      .logo-img {
        width: 32px !important;
        height: 32px !important;
      }
      .beta-badge, .desktop-only {
        display: none !important;
      }
      .admin-toggle-btn {
        padding: 6px 12px !important;
        font-size: 12px !important;
      }
    }
"""

if '/* Mobile Header Layout */' not in html:
    html = html.replace('</style>', header_responsive_css + '\n  </style>')

# 4. Remove optional comment textareas
for cid in ['comment_nlp_ocr', 'comment_receipts', 'comment_warranty', 'comment_reminders', 'comment_ai_assistant', 'comment_analytics', 'comment_pdf', 'comment_whatsapp']:
    html = re.sub(r'<textarea\s+class="feature-comment-input"\s+id="' + cid + r'"[^>]*></textarea>', '', html)

# 5. Replace Unicode stars with SVG buttons
STAR_SVG = '<svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>'
FEAT_STAR_SVG = '<svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>'

html = re.sub(
    r'<span class="star-btn([^"]*)" data-val="(\d+)">★</span>',
    r'<button type="button" class="star-btn\1" data-val="\2" aria-label="\2 stars">' + STAR_SVG + r'</button>',
    html
)

html = re.sub(
    r'<span class="feat-star([^"]*)" data-val="(\d+)">★</span>',
    r'<button type="button" class="feat-star\1" data-val="\2" aria-label="\2 stars">' + FEAT_STAR_SVG + r'</button>',
    html
)

# 6. Star CSS Upgrade (No Tap Highlight, No Text Selection, SVG Styling)
star_css = """
    /* Bulletproof SVG Star Rating Styling */
    * {
      -webkit-tap-highlight-color: transparent !important;
    }
    *::selection {
      background: transparent !important;
      color: inherit !important;
    }
    .star-row, .feature-stars, .star-btn, .feat-star, .star-rating-box {
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
      outline: none !important;
    }
    button.star-btn {
      -webkit-appearance: none;
      -moz-appearance: none;
      appearance: none;
      background: transparent !important;
      border: none !important;
      outline: none !important;
      box-shadow: none !important;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
      cursor: pointer;
      padding: 4px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      touch-action: manipulation;
    }
    button.star-btn:focus, button.star-btn:active, button.star-btn:focus-visible {
      outline: none !important;
      background: transparent !important;
      box-shadow: none !important;
      border: none !important;
    }
    .star-svg {
      width: 36px;
      height: 36px;
      fill: rgba(255, 255, 255, 0.16);
      transition: fill 0.15s ease, filter 0.15s ease, transform 0.15s ease;
      pointer-events: none;
    }
    button.star-btn.active .star-svg {
      fill: var(--accent-gold);
      filter: drop-shadow(0 0 10px rgba(251, 191, 36, 0.55));
      transform: scale(1.08);
    }
    button.feat-star {
      -webkit-appearance: none;
      -moz-appearance: none;
      appearance: none;
      background: transparent !important;
      border: none !important;
      outline: none !important;
      box-shadow: none !important;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      -webkit-tap-highlight-color: transparent !important;
      cursor: pointer;
      padding: 2px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      touch-action: manipulation;
    }
    button.feat-star:focus, button.feat-star:active, button.feat-star:focus-visible {
      outline: none !important;
      background: transparent !important;
      box-shadow: none !important;
      border: none !important;
    }
    .feat-star-svg {
      width: 20px;
      height: 20px;
      fill: rgba(255, 255, 255, 0.16);
      transition: fill 0.15s ease;
      pointer-events: none;
    }
    button.feat-star.active .feat-star-svg {
      fill: var(--accent-gold);
    }
"""

if '/* Bulletproof SVG Star Rating Styling */' not in html:
    html = html.replace('</style>', star_css + '\n  </style>')

# 7. Core Feature tags in Community Feed & Removal of old metadata pill row
core_tags_css = """
    /* Core App Feature Rating Tags in Response Feed */
    .core-feature-tags-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin: 10px 0 12px 0;
    }
    .core-feed-tag {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 4px 10px;
      border-radius: 999px;
      background: rgba(0, 217, 255, 0.06);
      border: 1px solid rgba(0, 217, 255, 0.18);
      color: #e2e8f0;
      font-size: 11.5px;
      font-weight: 600;
      letter-spacing: 0.2px;
    }
    .core-feed-tag .core-tag-star {
      color: var(--accent-gold);
      font-weight: 700;
    }
"""
if '/* Core App Feature Rating Tags in Response Feed */' not in html:
    html = html.replace('</style>', core_tags_css + '\n  </style>')

# Replace the metadata badges row in renderCommunityFeed with core feature tags
old_meta_row = """          <!-- Metadata Badges -->
          <div class="feed-meta-chips-row">
            <span class="feed-badge-pill">⏱️ Tested: ${escapeHtml(dur)}</span>
            <span class="feed-badge-pill">⚡ Ease: ${escapeHtml(ease)}</span>
            ${hasBug ? `<span class="feed-badge-pill" style="border-color: rgba(239,68,68,0.4); color: #f87171;">⚠️ Bug Logged</span>` : `<span class="feed-badge-pill" style="color: #34d399;">✅ Zero Crashes</span>`}
          </div>"""

new_tags_row = """          <!-- Core App Feature Ratings as Tags (Response Part) -->
          <div class="core-feature-tags-grid">${chipsHtml}</div>"""

html = html.replace(old_meta_row, new_tags_row)

# Update chipsHtml generation in renderCommunityFeed
html = html.replace(
    """.map(([k, v]) => `<span class="feed-feature-chip">${featureDisplayNames[k]}: ${v}★</span>`)""",
    """.map(([k, v]) => `<span class="core-feed-tag"><span>${featureIcons[k] || '⚡'}</span> <span>${featureDisplayNames[k]}</span>: <span class="core-tag-star">${v}★</span></span>`)"""
)

# Also remove the duplicate chipsHtml line if present
html = html.replace('<!-- Evaluated Feature Chips -->\n          <div class="feed-meta-chips-row">${chipsHtml}</div>', '')

# 8. Mobile Canvas Scroll Jitter Fix
old_resize = """    function resizeCanvas() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    }"""

new_resize = """    let lastCanvasWidth = window.innerWidth;
    function resizeCanvas() {
      // Guard against mobile address bar expand/collapse vertical resizes
      if (Math.abs(window.innerWidth - lastCanvasWidth) < 50 && canvas.width > 0) return;
      lastCanvasWidth = window.innerWidth;
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    }"""

html = html.replace(old_resize, new_resize)

# 9. Mobile Smoothness CSS
mobile_perf_css = """
    /* Mobile Smoothness & GPU Optimizations */
    @media (max-width: 768px) {
      .glow-blob {
        animation: none !important;
        opacity: 0.15 !important;
        filter: blur(80px) !important;
        transform: translate3d(0, 0, 0) !important;
        will-change: auto !important;
      }
      #neuralCanvas {
        transform: translate3d(0, 0, 0);
        backface-visibility: hidden;
        will-change: transform;
        pointer-events: none;
      }
    }
"""
if '/* Mobile Smoothness & GPU Optimizations */' not in html:
    html = html.replace('</style>', mobile_perf_css + '\n  </style>')

# Save updated files
with open('docs/feedback.html', 'w', encoding='utf-8') as f:
    f.write(html)

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("docs/feedback.html and docs/index.html successfully updated!")
