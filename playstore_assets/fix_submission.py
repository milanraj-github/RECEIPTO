# -*- coding: utf-8 -*-
import sys, re

sys.stdout.reconfigure(encoding='utf-8')

with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Add featureIcons definition right next to featureDisplayNames
if 'const featureIcons' not in html:
    html = html.replace(
        'const featureDisplayNames = {',
        '''const featureIcons = {
      nlp_ocr: '⚡',
      receipts: '🗄️',
      warranty: '🛡️',
      reminders: '🔔',
      ai_assistant: '🤖',
      analytics: '📊',
      pdf: '📑',
      whatsapp: '💬'
    };

    const featureDisplayNames = {'''
    )

# 2. Add novalidate to form
html = html.replace('<form id="betaFeedbackForm" onsubmit="handleFormSubmit(event)">', '<form id="betaFeedbackForm" novalidate onsubmit="handleFormSubmit(event)">')

# 3. Change submit button to type="button" with onclick="handleFormSubmit(event)"
html = re.sub(
    r'<button\s+type="submit"\s+class="btn-next\s+btn-submit"\s+id="submitBtn">',
    r'<button type="button" class="btn-next btn-submit" id="submitBtn" onclick="handleFormSubmit(event)">',
    html
)

# 4. Remove all native HTML5 required attributes inside betaFeedbackForm so browser never silently blocks hidden fields
# We have full JS validation for all required fields
def remove_required_in_form(match):
    form_content = match.group(0)
    # Remove required attribute
    cleaned = re.sub(r'\s+required\b', '', form_content)
    return cleaned

html = re.sub(r'<form id="betaFeedbackForm"[\s\S]*?</form>', remove_required_in_form, html)

# 5. Add safety try/catch and fallback to handleFormSubmit
submit_pattern = r'async function handleFormSubmit\(e\) \{[\s\S]*?showToast\(\'Feedback Successfully Submitted!\', \'Thank you for shaping Receipto\.\', \'🎉\'\);\s*submitBtn\.disabled = false;\s*submitBtn\.innerHTML = \'<span>SUBMIT FEEDBACK</span><span>🚀</span>\';\s*\}'

new_submit_body = """async function handleFormSubmit(e) {
      if (e) {
        e.preventDefault();
        e.stopPropagation();
      }
      const submitBtn = document.getElementById('submitBtn');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span>⏳ Submitting...</span>';
      }

      try {
        const hasBug = document.getElementById('hasBugInput') ? (document.getElementById('hasBugInput').value === 'Yes') : false;

        // Validate required fields on final submission with highlighting
        clearFieldErrors(document.getElementById('step5Card'));
        const favEl = document.getElementById('favFeature');
        const impEl = document.getElementById('improvements');
        let firstInvalid = null;

        if (favEl && !favEl.value.trim()) {
          highlightField(favEl, 'Please tell us your favourite feature');
          firstInvalid = firstInvalid || favEl;
        }
        if (impEl && !impEl.value.trim()) {
          highlightField(impEl, 'Please tell us what we can improve before launch');
          firstInvalid = firstInvalid || impEl;
        }
        if (hasBug) {
          const bugDesc = document.getElementById('bugDescription');
          if (bugDesc && !bugDesc.value.trim()) {
            highlightField(bugDesc, 'Please describe the bug encountered');
            firstInvalid = firstInvalid || bugDesc;
          }
        }

        if (firstInvalid) {
          firstInvalid.focus();
          firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
          showToast('Incomplete Fields', 'Please complete the highlighted feedback questions.', '⚠️');
          if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<span>SUBMIT FEEDBACK</span><span>🚀</span>';
          }
          return;
        }

        // Check if tester profile was filled
        const nameVal = document.getElementById('testerName') ? document.getElementById('testerName').value.trim() : '';
        const emailVal = document.getElementById('testerEmail') ? document.getElementById('testerEmail').value.trim() : '';
        const deviceVal = document.getElementById('deviceModel') ? document.getElementById('deviceModel').value.trim() : '';
        const androidVal = document.getElementById('androidVersion') ? document.getElementById('androidVersion').value : 'Android 14';

        if (!nameVal) {
          goToStep(1);
          const nameEl = document.getElementById('testerName');
          if (nameEl) highlightField(nameEl, 'Please enter your name');
          showToast('Incomplete Profile', 'Please enter your name in Step 1.', '⚠️');
          if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<span>SUBMIT FEEDBACK</span><span>🚀</span>';
          }
          return;
        }

        const formData = {
          id: 'rev-' + Date.now(),
          name: nameVal,
          email: emailVal,
          device: `${deviceVal} (${androidVal})`,
          rating: parseInt(document.getElementById('overallRating') ? document.getElementById('overallRating').value : '5') || 5,
          easeOfUse: document.getElementById('easeOfUseInput') ? document.getElementById('easeOfUseInput').value : 'Very Easy',
          appVersion: document.getElementById('appVersion') ? document.getElementById('appVersion').value : '1.0.0 (Build 1)',
          testingDuration: document.getElementById('testingDuration') ? document.getElementById('testingDuration').value : '1–3 days',
          features: { ...featureScores },
          manualCorrection: document.getElementById('manualCorrectionInput') ? document.getElementById('manualCorrectionInput').value : 'Rarely',
          comments: {},
          uiUx: {
            design: featureScores.ui_design || 5,
            nav: featureScores.ui_nav || 5,
            speed: featureScores.ui_speed || 5,
            crashFrequency: document.getElementById('crashFrequency') ? document.getElementById('crashFrequency').value : 'Never',
            delayFrequency: document.getElementById('delayFrequency') ? document.getElementById('delayFrequency').value : 'Never'
          },
          hasBug: hasBug,
          bugReport: hasBug ? {
            feature: document.getElementById('bugFeature') ? document.getElementById('bugFeature').value : 'General',
            description: document.getElementById('bugDescription') ? document.getElementById('bugDescription').value.trim() : '',
            steps: document.getElementById('bugSteps') ? document.getElementById('bugSteps').value.trim() : '',
            expected: document.getElementById('bugExpected') ? document.getElementById('bugExpected').value.trim() : '',
            actual: document.getElementById('bugActual') ? document.getElementById('bugActual').value.trim() : '',
            frequency: document.getElementById('bugOccurs') ? document.getElementById('bugOccurs').value : 'Once',
            severity: document.getElementById('bugSeverity') ? document.getElementById('bugSeverity').value : 'Low'
          } : null,
          suggestions: {
            favFeature: favEl ? favEl.value.trim() : '',
            impressedFeature: document.getElementById('impressedFeature') ? document.getElementById('impressedFeature').value.trim() : '',
            improvements: impEl ? impEl.value.trim() : '',
            futureWishes: document.getElementById('futureWishes') ? document.getElementById('futureWishes').value.trim() : ''
          },
          finalEvaluation: {
            overallSatisfaction: parseInt(document.getElementById('finalSatRating') ? document.getElementById('finalSatRating').value : '5') || 5,
            continueUsing: document.getElementById('continueUsing') ? document.getElementById('continueUsing').value : 'Definitely Yes',
            devMessage: document.getElementById('devMessage') ? document.getElementById('devMessage').value.trim() : ''
          },
          date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
          helpful: 0
        };

        // Message summary
        formData.message = formData.suggestions.favFeature
          ? `★ Favourite: "${formData.suggestions.favFeature}". Improve: "${formData.suggestions.improvements}"`
          : `Overall Experience: ${formData.rating}/5. Testing duration: ${formData.testingDuration}.`;

        // 1. Submit Full Payload to Supabase Cloud
        if (supabaseClient) {
          try {
            const cloudPayload = {
              message: formData.message,
              suggestions: formData.suggestions,
              finalEvaluation: formData.finalEvaluation,
              bugReport: formData.bugReport,
              hasBug: formData.hasBug,
              uiUx: formData.uiUx,
              comments: formData.comments,
              easeOfUse: formData.easeOfUse,
              testingDuration: formData.testingDuration,
              appVersion: formData.appVersion
            };

            await supabaseClient.from('feedbacks').insert([{
              name: formData.name,
              email: formData.email,
              device: formData.device,
              rating: formData.rating,
              message: JSON.stringify(cloudPayload),
              features: formData.features,
              tags: [
                `v${formData.appVersion.split(' ')[0]}`,
                formData.testingDuration,
                hasBug ? '⚠️ Bug Logged' : '✅ Smooth'
              ]
            }]);
          } catch(err) {
            console.log('Supabase sync note:', err);
          }
        }

        // 2. Add to Local Storage and Cache
        try {
          feedbackRecords.unshift(formData);
          localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
          renderCommunityFeed();
          renderAdminResponses();
        } catch(storageErr) {
          console.log('Storage note:', storageErr);
        }

        // 3. Show Celebration & Success View
        if (window.confetti) {
          try {
            window.confetti({ particleCount: 120, spread: 80, origin: { y: 0.6 } });
          } catch(cErr) {}
        }

        const formEl = document.getElementById('betaFeedbackForm');
        const navEl = document.getElementById('stepperNav');
        const successEl = document.getElementById('successCard');

        if (formEl) formEl.style.display = 'none';
        if (navEl) navEl.style.display = 'none';
        if (successEl) {
          successEl.classList.add('show');
          successEl.scrollIntoView({ behavior: 'smooth' });
        }

        showToast('Feedback Successfully Submitted!', 'Thank you for shaping Receipto.', '🎉');
      } catch(fatalErr) {
        console.error('Fatal submission error:', fatalErr);
        showToast('Error Submitting', fatalErr.message || 'Please check fields and try again.', '⚠️');
      } finally {
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.innerHTML = '<span>SUBMIT FEEDBACK</span><span>🚀</span>';
        }
      }
    }"""

html = re.sub(submit_pattern, new_submit_body, html)

with open('docs/feedback.html', 'w', encoding='utf-8') as f:
    f.write(html)

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Applied fix: featureIcons defined, novalidate enabled, required attributes cleaned, button made type=button with onclick, and try/catch added!")
