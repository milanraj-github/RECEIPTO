import urllib.request, json
url = 'https://ykqzefulvpqfiwsddnqt.supabase.co/rest/v1/feedbacks?select=*&order=created_at.desc'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcXplZnVsdnBxZml3c2RkbnF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTI2NTcsImV4cCI6MjA5ODMyODY1N30.NFm5dT7vVeHtziEkYWN-qk8ZEogpktPZ7NTmXDLO1Qs'
req = urllib.request.Request(url, headers={'apikey': key, 'Authorization': 'Bearer ' + key})
with urllib.request.urlopen(req) as resp:
    data = json.loads(resp.read().decode('utf-8'))
    print(f'Total Supabase Feedbacks in DB: {len(data)}')
    for r in data:
        print(f"- {r.get('name')}: rating={r.get('rating')}, id={r.get('id')}")
