with open('docs/feedback.html', encoding='utf-8') as f:
    text = f.read()

# 1. Validation error highlighting
assert '.input-error' in text, 'input-error CSS missing'
assert 'fieldShake' in text, 'fieldShake animation missing'
assert 'highlightField(' in text, 'highlightField function missing'
assert 'clearFieldErrors(' in text, 'clearFieldErrors function missing'
print('Verified: Validation error highlighting present!')

# 2. Admin Portal Full Responses Dashboard
assert 'id="adminResponsesDashboard"' in text, 'adminResponsesDashboard missing'
assert 'id="adminRecordsList"' in text, 'adminRecordsList missing'
assert 'renderAdminResponses(' in text, 'renderAdminResponses function missing'
assert 'filterAdminResponses(' in text, 'filterAdminResponses function missing'
assert 'Milanrajjj@#12345' in text, 'Passcode missing'
print('Verified: Admin dedicated full responses dashboard present!')

# 3. Public Feedback Full Details
assert 'feed-insights-list' in text, 'feed-insights-list CSS missing'
assert 'feed-quote-item' in text, 'feed-quote-item CSS missing'
assert 'feed-details-accordion' in text, 'feed-details-accordion CSS missing'
assert 'toggleCardDetails(' in text, 'toggleCardDetails function missing'
print('Verified: Full feedback details in responses present!')

# 4. Core Features & Android OS
assert 'for="androidVersion">Android OS Version' in text, 'Android OS Version label missing'
assert 'value="Android 17"' in text, 'Android 17 missing'
print('Verified: Android OS Version dropdown preserved!')

print('>>> ALL VALIDATION CHECKS PASSED 100%! <<<')
