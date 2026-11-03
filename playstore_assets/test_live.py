# -*- coding: utf-8 -*-
import urllib.request, time

time.sleep(2)
now = str(int(time.time()))
url_main = f'https://receipto-docs.vercel.app/?t={now}'
url_admin = f'https://receipto-docs.vercel.app/admin?t={now}'

req1 = urllib.request.Request(url_main, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req1) as resp:
    html1 = resp.read().decode('utf-8')
    print('Main Portal HTTP Status:', resp.status)
    print('Contains placeholder="Milanraj":', 'placeholder="Milanraj"' in html1)
    print('Contains SVG star-svg:', 'class="star-svg"' in html1)
    print('Contains admin.html link:', 'href="admin.html"' in html1)

req2 = urllib.request.Request(url_admin, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req2) as resp:
    html2 = resp.read().decode('utf-8')
    print('Admin Portal HTTP Status:', resp.status)
    print('Contains SheetJS Excel Export:', 'exportToExcel()' in html2)
    print('Contains Master Passcode:', 'Milanrajjj@#12345' in html2)
