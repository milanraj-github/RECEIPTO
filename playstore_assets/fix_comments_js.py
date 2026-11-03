# -*- coding: utf-8 -*-
import re

with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    html = f.read()

html = re.sub(
    r'comments:\s*\{[\s\S]*?whatsapp:[^\n]+\n\s*\},',
    'comments: {},',
    html
)

with open('docs/feedback.html', 'w', encoding='utf-8') as f:
    f.write(html)

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Updated comments block via regex!")
