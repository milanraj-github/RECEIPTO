# -*- coding: utf-8 -*-
"""
Receipto Complete Beta Suite Builder
Generates:
  1. docs/feedback.html (and docs/index.html)
  2. docs/admin.html
"""

import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Read base64 logo
logo_b64 = ""
if os.path.exists("playstore_assets/logo_small_b64.txt"):
    with open("playstore_assets/logo_small_b64.txt", "r", encoding="utf-8") as f:
        logo_b64 = f.read().strip()
elif os.path.exists("playstore_assets/logo_b64.txt"):
    with open("playstore_assets/logo_b64.txt", "r", encoding="utf-8") as f:
        logo_b64 = f.read().strip()

print(f"Loaded logo b64 (length: {len(logo_b64)})")
