import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.split('\n')
for i, l in enumerate(lines):
    if 'function renderCommunityFeed' in l:
        for j in range(i, min(len(lines), i+80)):
            print(f"{j+1}: {lines[j]}")
        break
