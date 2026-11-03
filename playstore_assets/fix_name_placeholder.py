# -*- coding: utf-8 -*-
with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    html = f.read()

html = html.replace('id="testerName" placeholder="e.g. Milanraj Kunder"', 'id="testerName" placeholder="Milanraj"')

with open('docs/feedback.html', 'w', encoding='utf-8') as f:
    f.write(html)

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Updated testerName placeholder to strictly Milanraj!")
