import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(2904, min(len(lines), 2930)):
    print(f"{i+1}: {lines[i]}", end='')
