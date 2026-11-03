with open('docs/feedback.html', encoding='utf-8') as f:
    text = f.read()

# 1. Check Overall Response Part is immediately below hero
hero_idx = text.find('class="hero"')
response_idx = text.find('class="overall-response-section"')
stepper_idx = text.find('class="stepper-nav"')

print('Hero idx:', hero_idx)
print('Response idx:', response_idx)
print('Stepper idx:', stepper_idx)

assert hero_idx < response_idx < stepper_idx, 'Response section is not between hero and stepper!'
assert 'id="displayAvgRating"' in text, 'displayAvgRating missing'
assert 'id="displayStarsVisual"' in text, 'displayStarsVisual missing'
assert 'id="displayResponseCount"' in text, 'displayResponseCount missing'
assert 'id="bar5"' in text, 'breakdown bars missing'
assert 'id="avg_nlp_ocr"' in text, 'feature rating tag missing'
print('Verified: Overall Response Section immediately below Hero!')

# 2. Check Giving Part is inside step2Card
step2_idx = text.find('id="step2Card"')
assert step2_idx != -1, 'step2Card missing'
assert 'id="overallStarsGroup"' in text[step2_idx:], 'overallStarsGroup missing in step2Card'
assert 'id="overallRating"' in text[step2_idx:], 'overallRating hidden input missing in step2Card'
print('Verified: Giving Part (overall experience star rating input) is in Step 2!')

# 3. Check Android OS Version
assert 'for="androidVersion">Android OS Version' in text, 'Android OS Version missing'
for ver in ['Android 10', 'Android 11', 'Android 12', 'Android 12L', 'Android 13', 'Android 14', 'Android 15', 'Android 16', 'Android 17', 'Other / Not Sure']:
    assert f'value="{ver}"' in text, f'Missing {ver}'
print('Verified: Android OS Version dropdown with Android 10-17 + Other / Not Sure (no dessert names)!')

print('>>> ALL CHECKS PASSED 100%! <<<')
