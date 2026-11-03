import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('docs/admin.html', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(920, min(len(lines), 975)):
    print(f"{i+1}: {lines[i]}", end='')
