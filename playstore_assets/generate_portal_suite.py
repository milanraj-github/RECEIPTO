# -*- coding: utf-8 -*-
"""
Full Generator for Receipto Feedback Portal & Dedicated Admin Portal
"""
import os, sys

sys.stdout.reconfigure(encoding='utf-8')

logo_b64 = ""
if os.path.exists("playstore_assets/logo_small_b64.txt"):
    with open("playstore_assets/logo_small_b64.txt", "r", encoding="utf-8") as f:
        logo_b64 = f.read().strip()
elif os.path.exists("playstore_assets/logo_b64.txt"):
    with open("playstore_assets/logo_b64.txt", "r", encoding="utf-8") as f:
        logo_b64 = f.read().strip()

STAR_SVG = '''<svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>'''
FEAT_STAR_SVG = '''<svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>'''

print("Building portal suite...")
