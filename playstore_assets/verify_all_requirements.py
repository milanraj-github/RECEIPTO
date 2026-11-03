# -*- coding: utf-8 -*-
import sys, re

sys.stdout.reconfigure(encoding='utf-8')

with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    fb_html = f.read()

with open('docs/admin.html', 'r', encoding='utf-8') as f:
    adm_html = f.read()

print("=== VERIFYING RECEIPTO SUITE ===")

# 1. Check Full Name placeholder
m_name = re.search(r'id="fullName"[^>]*placeholder="([^"]*)"', fb_html)
if m_name:
    print(f"[✓] Full Name placeholder: '{m_name.group(1)}'")
    assert m_name.group(1) == "Milanraj", f"Expected Milanraj, got {m_name.group(1)}"

# 2. Check stars are SVG buttons with no raw ★ text in interactive buttons
star_spans = re.findall(r'<span class="star-btn[^"]*"[^>]*>★</span>', fb_html)
feat_spans = re.findall(r'<span class="feat-star[^"]*"[^>]*>★</span>', fb_html)
print(f"[✓] Star spans remaining: {len(star_spans)} (expected 0)")
print(f"[✓] Feat star spans remaining: {len(feat_spans)} (expected 0)")
assert len(star_spans) == 0
assert len(feat_spans) == 0

svg_star_btns = re.findall(r'<button type="button" class="star-btn[^"]*"', fb_html)
svg_feat_btns = re.findall(r'<button type="button" class="feat-star[^"]*"', fb_html)
print(f"[✓] SVG Star buttons in feedback form: {len(svg_star_btns)}")
print(f"[✓] SVG Feat star buttons in feedback form: {len(svg_feat_btns)}")
assert len(svg_star_btns) == 10
assert len(svg_feat_btns) == 55

# 3. Check Header on mobile & admin link
assert '<a href="admin.html" class="admin-toggle-btn">' in fb_html
assert 'beta-badge desktop-only' in fb_html
assert '@media (max-width: 640px)' in fb_html
assert '.desktop-only' in fb_html
print("[✓] Header has link to admin.html and desktop-only beta badge with mobile media query")

# 4. Check removed optional comments in Steps 2-4
for cid in ['comment_nlp_ocr', 'comment_receipts', 'comment_warranty', 'comment_reminders', 'comment_ai_assistant', 'comment_analytics', 'comment_pdf', 'comment_whatsapp']:
    assert cid not in fb_html, f"Found {cid} in fb_html!"
print("[✓] Optional comments in Steps 2-4 successfully removed")

# 5. Check Step 5 comments kept
for fid in ['favFeature', 'impressedFeature', 'improvements', 'futureWishes', 'devMessage']:
    assert fid in fb_html, f"Missing {fid} in fb_html!"
print("[✓] Step 5 inputs (favFeature, impressedFeature, improvements, futureWishes, devMessage) intact")

# 6. Check Core App Feature Ratings as Tags in feedback feed
assert 'core-feature-tags-grid' in fb_html
assert 'core-feed-tag' in fb_html
assert '<span class="feed-badge-pill">' not in fb_html
print("[✓] Core App Features Ratings displayed as tags in response feed, old metadata pills removed")

# 7. Check Admin Portal
assert 'xlsx.full.min.js' in adm_html
assert 'exportToExcel()' in adm_html
assert 'Milanrajjj@#12345' in adm_html
assert 'core-tags-grid' in adm_html
assert 'core-tag' in adm_html
print("[✓] Dedicated Admin Portal has SheetJS Excel export, passcode gate, and core feature tags")

# 8. Check Mobile Scroll & Canvas smoothness
assert 'lastCanvasWidth' in fb_html
assert 'lastW' in adm_html
print("[✓] Canvas resize guarded against mobile scroll bar collapse/expand")

print("\nALL VERIFICATIONS PASSED SUCCESSFULLY!")
