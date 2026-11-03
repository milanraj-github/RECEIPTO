import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('playstore_assets/build_feedback_portal.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's inspect CSS variables
import re
vars_match = re.search(r':root\s*\{([^}]+)\}', text)
if vars_match:
    print("CSS Variables:")
    print(vars_match.group(1).strip()[:400])
