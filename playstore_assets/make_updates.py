import sys, re
sys.stdout.reconfigure(encoding='utf-8')

with open('playstore_assets/build_feedback_portal.py', 'r', encoding='utf-8') as f:
    code = f.read()

lines = code.split('\n')
for j in range(2515, 2585):
    print(f"{j+1}: {lines[j]}")
