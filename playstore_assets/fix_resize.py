# -*- coding: utf-8 -*-
with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    html = f.read()

old_resize = """    function resizeCanvas() {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }"""

new_resize = """    let lastCanvasWidth = window.innerWidth;
    function resizeCanvas() {
      if (Math.abs(window.innerWidth - lastCanvasWidth) < 50 && width > 0) return;
      lastCanvasWidth = window.innerWidth;
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }"""

html = html.replace(old_resize, new_resize)

with open('docs/feedback.html', 'w', encoding='utf-8') as f:
    f.write(html)

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Guarded resizeCanvas against vertical address bar scrolling!")
