# -*- coding: utf-8 -*-
import os, sys, re

sys.stdout.reconfigure(encoding='utf-8')

with open('playstore_assets/build_feedback_portal.py', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update Full Name placeholder to "Milanraj"
content = re.sub(
    r'id="fullName"\s+placeholder="[^"]*"',
    'id="fullName" placeholder="Milanraj"',
    content
)

# 2. Update Header: Admin link to admin.html, add desktop-only to beta-badge
content = content.replace(
    '<div class="beta-badge">Official Beta Testing Program</div>\n        <button type="button" class="admin-toggle-btn" id="adminBtn" onclick="toggleAdmin()">\n          <span>🔒</span> Admin Portal\n        </button>',
    '<div class="beta-badge desktop-only">Official Closed Beta</div>\n        <a href="admin.html" class="admin-toggle-btn">\n          <span>🔒</span> Admin Portal\n        </a>'
)
content = content.replace(
    '<button type="button" class="admin-toggle-btn" id="adminBtn" onclick="toggleAdmin()">\n          <span>🔒</span> Admin Portal\n        </button>',
    '<a href="admin.html" class="admin-toggle-btn">\n          <span>🔒</span> Admin Portal\n        </a>'
)

# 3. Header mobile CSS update
header_mobile_css = """
      @media (max-width: 640px) {
        header {
          padding: 10px 14px;
        }
        .brand-title {
          font-size: 18px;
        }
        .logo-img {
          width: 32px;
          height: 32px;
        }
        .beta-badge, .desktop-only {
          display: none !important;
        }
        .admin-toggle-btn {
          padding: 6px 12px;
          font-size: 12px;
        }
      }
"""
if '.desktop-only' not in content:
    content = content.replace('.beta-badge { display: none !important; }', '.beta-badge, .desktop-only { display: none !important; }')

# 4. Remove optional comment textareas
for cid in ['comment_nlp_ocr', 'comment_receipts', 'comment_warranty', 'comment_reminders', 'comment_ai_assistant', 'comment_analytics', 'comment_pdf', 'comment_whatsapp']:
    # Match textarea element and remove it
    content = re.sub(r'<textarea\s+class="feature-comment-input"\s+id="' + cid + r'"[^>]*></textarea>', '', content)

# 5. Replace Unicode stars with SVG buttons
STAR_SVG = '<svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>'
FEAT_STAR_SVG = '<svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>'

# Replace <span class="star-btn active" data-val="X">★</span>
content = re.sub(
    r'<span class="star-btn([^"]*)" data-val="(\d+)">★</span>',
    r'<button type="button" class="star-btn\1" data-val="\2" aria-label="\2 stars">' + STAR_SVG + r'</button>',
    content
)

# Replace <span class="feat-star([^"]*)" data-val="X">★</span>
content = re.sub(
    r'<span class="feat-star([^"]*)" data-val="(\d+)">★</span>',
    r'<button type="button" class="feat-star\1" data-val="\2" aria-label="\2 stars">' + FEAT_STAR_SVG + r'</button>',
    content
)

# 6. Star CSS Update
star_css_replacement = """
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
      width: 38px;
      height: 38px;
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
      width: 22px;
      height: 22px;
      fill: rgba(255, 255, 255, 0.16);
      transition: fill 0.15s ease;
      pointer-events: none;
    }
    button.feat-star.active .feat-star-svg {
      fill: var(--accent-gold);
    }
"""

content = re.sub(
    r'\.star-row\s*\{[^}]+\}\s*\.star-btn\s*\{[^}]+\}\s*\.star-btn:focus[^{]*\{[^}]+\}\s*\.star-btn\.active\s*\{[^}]+\}',
    star_css_replacement,
    content
)

# 7. Core Feature tags in Community Feed
tags_css = """
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
if '.core-feature-tags-grid' not in content:
    content = content.replace('/* Core App Feature Rating Tags */', tags_css + '\n    /* Core App Feature Rating Tags */')

# 8. Update renderCommunityFeed to show core feature tags and remove old metadata pill row
content = content.replace(
    """          <!-- Metadata Badges -->
          <div class="feed-meta-chips-row">
            <span class="feed-badge-pill">⏱️ Tested: ${escapeHtml(dur)}</span>
            <span class="feed-badge-pill">⚡ Ease: ${escapeHtml(ease)}</span>
            ${hasBug ? `<span class="feed-badge-pill" style="border-color: rgba(239,68,68,0.4); color: #f87171;">⚠️ Bug Logged</span>` : `<span class="feed-badge-pill" style="color: #34d399;">✅ Zero Crashes</span>`}
          </div>""",
    """          <!-- Core App Feature Ratings as Tags (Response Part) -->
          <div class="core-feature-tags-grid">${chipsHtml}</div>"""
)

# Update chipsHtml generation in renderCommunityFeed
content = content.replace(
    """.map(([k, v]) => `<span class="feed-feature-chip">${featureDisplayNames[k]}: ${v}★</span>`)""",
    """.map(([k, v]) => `<span class="core-feed-tag"><span>${featureIcons[k] || '⚡'}</span> <span>${featureDisplayNames[k]}</span>: <span class="core-tag-star">${v}★</span></span>`)"""
)

# 9. Mobile canvas scroll jitter fix
content = content.replace(
    """    function resizeCanvas() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    }""",
    """    let lastCanvasWidth = window.innerWidth;
    function resizeCanvas() {
      // Guard against mobile address bar expand/collapse vertical resizes
      if (Math.abs(window.innerWidth - lastCanvasWidth) < 50 && canvas.width > 0) return;
      lastCanvasWidth = window.innerWidth;
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    }"""
)

# 10. Mobile CSS smoothness
mobile_perf_css = """
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
if 'lastCanvasWidth' in content and '@media (max-width: 768px)' in content:
    content = content.replace('@media (max-width: 768px) {', mobile_perf_css + '\n    @media (max-width: 768px) {')

# Write back to playstore_assets/build_feedback_portal.py
with open('playstore_assets/build_feedback_portal.py', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated playstore_assets/build_feedback_portal.py!")
