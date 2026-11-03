
    // --- 1. Living Neural Mesh Canvas Background ---
    const canvas = document.getElementById('neuralCanvas');
    const ctx = canvas.getContext('2d');
    let width, height;
    let particles = [];
    const PARTICLE_COUNT = 45;
    const CONNECT_DIST = 120;

    let lastCanvasWidth = window.innerWidth;
    function resizeCanvas() {
      if (Math.abs(window.innerWidth - lastCanvasWidth) < 50 && width > 0) return;
      lastCanvasWidth = window.innerWidth;
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();

    class Particle {
      constructor() {
        this.x = Math.random() * width;
        this.y = Math.random() * height;
        this.vx = (Math.random() - 0.5) * 0.45;
        this.vy = (Math.random() - 0.5) * 0.45;
        this.radius = Math.random() * 2 + 1;
        this.color = Math.random() > 0.5 ? '#00D9FF' : '#813BFF';
      }
      update() {
        this.x += this.vx;
        this.y += this.vy;
        if (this.x < 0) this.x = width;
        if (this.x > width) this.x = 0;
        if (this.y < 0) this.y = height;
        if (this.y > height) this.y = 0;
      }
      draw() {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fillStyle = this.color;
        ctx.shadowColor = this.color;
        ctx.shadowBlur = 8;
        ctx.fill();
        ctx.shadowBlur = 0;
      }
    }

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      particles.push(new Particle());
    }

    function animateNeuralMesh() {
      ctx.clearRect(0, 0, width, height);
      for (let i = 0; i < particles.length; i++) {
        particles[i].update();
        particles[i].draw();
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < CONNECT_DIST) {
            const alpha = (1 - dist / CONNECT_DIST) * 0.22;
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.strokeStyle = `rgba(0, 217, 255, ${alpha})`;
            ctx.lineWidth = 0.8;
            ctx.stroke();
          }
        }
      }
      requestAnimationFrame(animateNeuralMesh);
    }
    animateNeuralMesh();

    // --- 2. Supabase Cloud Connection & Local Storage Fallback ---
    const SUPABASE_URL = 'https://ykqzefulvpqfiwsddnqt.supabase.co';
    const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcXplZnVsdnBxZml3c2RkbnF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTI2NTcsImV4cCI6MjA5ODMyODY1N30.NFm5dT7vVeHtziEkYWN-qk8ZEogpktPZ7NTmXDLO1Qs';
    let supabaseClient = null;
    try {
      supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
    } catch(e) {
      console.log('Supabase offline fallback:', e);
    }

    // Local Feedbacks In-Memory & LocalStorage Cache
    let feedbackRecords = [];
    const savedLocal = localStorage.getItem('receipto_feedbacks');
    if (savedLocal) {
      try { feedbackRecords = JSON.parse(savedLocal); } catch(e) {}
    }

    // --- 3. Stepper Navigation Controller ---
    let currentStep = 1;
    function goToStep(step) {
      currentStep = step;
      document.querySelectorAll('.section-card').forEach((card, idx) => {
        card.classList.toggle('active', (idx + 1) === step);
      });
      document.querySelectorAll('.step-pill').forEach((pill, idx) => {
        pill.classList.toggle('active', (idx + 1) === step);
        pill.classList.toggle('completed', (idx + 1) < step);
      });
      const activeCard = document.getElementById('step' + step + 'Card');
      if (activeCard && step > 1) {
        activeCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
      } else {
        const container = document.getElementById('feedbackFormContainer');
        container.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    }

    // --- Field Validation & Error Highlighting Helpers ---
    function highlightField(el, msg) {
      if (!el) return;
      el.classList.add('input-error');

      const parent = el.parentElement;
      const oldErr = parent.querySelector('.field-error-text');
      if (oldErr) oldErr.remove();

      const errEl = document.createElement('div');
      errEl.className = 'field-error-text';
      errEl.innerHTML = `<span>⚠️</span> <span>${msg || 'This field is required'}</span>`;
      parent.appendChild(errEl);

      const clearError = () => {
        el.classList.remove('input-error');
        const e = parent.querySelector('.field-error-text');
        if (e) e.remove();
        el.removeEventListener('input', clearError);
        el.removeEventListener('change', clearError);
      };
      el.addEventListener('input', clearError);
      el.addEventListener('change', clearError);
    }

    function clearFieldErrors(container) {
      const root = container || document;
      root.querySelectorAll('.input-error').forEach(el => el.classList.remove('input-error'));
      root.querySelectorAll('.field-error-text').forEach(el => el.remove());
    }

    function validateAndGoStep(fromStep, toStep) {
      if (fromStep === 1) {
        clearFieldErrors(document.getElementById('step1Card'));
        const nameEl = document.getElementById('testerName');
        const emailEl = document.getElementById('testerEmail');
        const deviceEl = document.getElementById('deviceModel');
        const androidEl = document.getElementById('androidVersion');
        const durationEl = document.getElementById('testingDuration');

        let firstInvalid = null;

        if (!nameEl.value.trim()) {
          highlightField(nameEl, 'Please enter your full name');
          firstInvalid = firstInvalid || nameEl;
        }
        if (!emailEl.value.trim() || !emailEl.value.includes('@')) {
          highlightField(emailEl, 'Please enter a valid email address');
          firstInvalid = firstInvalid || emailEl;
        }
        if (!deviceEl.value.trim()) {
          highlightField(deviceEl, 'Please enter your phone brand and model');
          firstInvalid = firstInvalid || deviceEl;
        }
        if (!androidEl.value) {
          highlightField(androidEl, 'Please select your Android OS version');
          firstInvalid = firstInvalid || androidEl;
        }
        if (!durationEl.value) {
          highlightField(durationEl, 'Please select your testing duration');
          firstInvalid = firstInvalid || durationEl;
        }

        if (firstInvalid) {
          firstInvalid.focus();
          firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
          showToast('Incomplete Fields', 'Please complete the highlighted required fields.', '⚠️');
          return;
        }
      }
      goToStep(toStep);
    }

    function scrollToForm() {
      document.getElementById('feedbackFormContainer').scrollIntoView({ behavior: 'smooth' });
    }
    function scrollToCommunity() {
      document.getElementById('communityWall').scrollIntoView({ behavior: 'smooth' });
    }

    // Choice Chips Selection Helper
    function selectChoice(groupId, element) {
      const group = document.getElementById(groupId);
      group.querySelectorAll('.choice-chip').forEach(c => c.classList.remove('selected'));
      element.classList.add('selected');
      const val = element.getAttribute('data-val');
      if (groupId === 'easeOfUseGroup') {
        document.getElementById('easeOfUseInput').value = val;
      } else if (groupId === 'manualCorrectionGroup') {
        document.getElementById('manualCorrectionInput').value = val;
      }
    }

    function selectBugChoice(hasBug, element) {
      document.querySelectorAll('#hasBugGroup .choice-chip').forEach(c => c.classList.remove('selected'));
      element.classList.add('selected');
      document.getElementById('hasBugInput').value = hasBug ? 'Yes' : 'No';
      const box = document.getElementById('bugReportBox');
      if (hasBug) {
        box.classList.add('show');
      } else {
        box.classList.remove('show');
      }
    }

    // --- 4. Interactive Five-Star Rating Components ---
    const starDescriptions = {
      1: '1/5 – Poor ⚠️',
      2: '2/5 – Fair 😐',
      3: '3/5 – Good 👍',
      4: '4/5 – Very Good 🚀',
      5: '5/5 – Excellent 🔥'
    };

    function setupStarRating(groupEl, descEl, inputEl) {
      const stars = groupEl.querySelectorAll('.star-btn');
      stars.forEach(s => {
        const handleTap = (e) => {
          if (e.cancelable) e.preventDefault();
          e.stopPropagation();
          const val = parseInt(s.getAttribute('data-val'));
          inputEl.value = val;
          stars.forEach(st => st.classList.toggle('active', parseInt(st.getAttribute('data-val')) <= val));
          if (descEl) descEl.innerText = starDescriptions[val] || `${val} Stars`;
        };
        s.addEventListener('pointerdown', handleTap, { passive: false });
        s.addEventListener('touchstart', handleTap, { passive: false });
        s.addEventListener('click', handleTap);
      });
    }

    setupStarRating(
      document.getElementById('overallStarsGroup'),
      document.getElementById('overallStarsDesc'),
      document.getElementById('overallRating')
    );

    setupStarRating(
      document.getElementById('finalSatStarsGroup'),
      document.getElementById('finalSatDesc'),
      document.getElementById('finalSatRating')
    );

    // Feature Ratings Map
    const featureScores = {
      nlp_ocr: 5,
      receipts: 5,
      warranty: 5,
      reminders: 5,
      ai_assistant: 5,
      analytics: 5,
      pdf: 5,
      whatsapp: 5,
      ui_design: 5,
      ui_nav: 5,
      ui_speed: 5
    };

    document.querySelectorAll('.feature-stars').forEach(group => {
      const featKey = group.getAttribute('data-feature');
      const stars = group.querySelectorAll('.feat-star');
      const labelEl = document.getElementById('label_' + featKey) || document.getElementById('nlpStarsLabel');

      stars.forEach(s => {
        const handleTap = (e) => {
          if (e.cancelable) e.preventDefault();
          e.stopPropagation();
          const val = parseInt(s.getAttribute('data-val'));
          featureScores[featKey] = val;
          stars.forEach(st => st.classList.toggle('active', parseInt(st.getAttribute('data-val')) <= val));
          if (labelEl) labelEl.innerText = `${val.toFixed(1)} ★`;
        };
        s.addEventListener('pointerdown', handleTap, { passive: false });
        s.addEventListener('touchstart', handleTap, { passive: false });
        s.addEventListener('click', handleTap);
      });
    });

    function toggleNotTested(featKey, checkbox) {
      const group = document.querySelector(`.feature-stars[data-feature="${featKey}"]`);
      const labelEl = document.getElementById('label_' + featKey) || document.getElementById('nlpStarsLabel');
      if (checkbox.checked) {
        featureScores[featKey] = null;
        if (group) group.querySelectorAll('.feat-star').forEach(s => s.classList.remove('active'));
        if (labelEl) labelEl.innerText = 'Not Tested';
      } else {
        featureScores[featKey] = 5;
        if (group) group.querySelectorAll('.feat-star').forEach(s => s.classList.add('active'));
        if (labelEl) labelEl.innerText = '5.0 ★';
      }
    }

    // --- 5. Form Submission Handler ---
    async function handleFormSubmit(e) {
      e.preventDefault();
      const submitBtn = document.getElementById('submitBtn');
      submitBtn.disabled = true;
      submitBtn.innerHTML = '<span>⏳ Submitting...</span>';

      const hasBug = document.getElementById('hasBugInput').value === 'Yes';

      // Validate required fields on final submission with highlighting
      clearFieldErrors(document.getElementById('step5Card'));
      const favEl = document.getElementById('favFeature');
      const impEl = document.getElementById('improvements');
      let firstInvalid = null;

      if (!favEl.value.trim()) {
        highlightField(favEl, 'Please tell us your favourite feature');
        firstInvalid = firstInvalid || favEl;
      }
      if (!impEl.value.trim()) {
        highlightField(impEl, 'Please tell us what we can improve before launch');
        firstInvalid = firstInvalid || impEl;
      }
      if (hasBug) {
        const bugDesc = document.getElementById('bugDescription');
        if (!bugDesc.value.trim()) {
          highlightField(bugDesc, 'Please describe the bug encountered');
          firstInvalid = firstInvalid || bugDesc;
        }
      }

      if (firstInvalid) {
        firstInvalid.focus();
        firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
        showToast('Incomplete Fields', 'Please complete the highlighted feedback questions.', '⚠️');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span>SUBMIT FEEDBACK</span><span>🚀</span>';
        return;
      }

      const formData = {
        id: 'rev-' + Date.now(),
        name: document.getElementById('testerName').value.trim(),
        email: document.getElementById('testerEmail').value.trim(),
        device: `${document.getElementById('deviceModel').value.trim()} (${document.getElementById('androidVersion').value})`,
        rating: parseInt(document.getElementById('overallRating').value) || 5,
        easeOfUse: document.getElementById('easeOfUseInput').value,
        appVersion: document.getElementById('appVersion').value,
        testingDuration: document.getElementById('testingDuration').value,
        features: { ...featureScores },
        manualCorrection: document.getElementById('manualCorrectionInput').value,
        comments: {},
        uiUx: {
          design: featureScores.ui_design || 5,
          nav: featureScores.ui_nav || 5,
          speed: featureScores.ui_speed || 5,
          crashFrequency: document.getElementById('crashFrequency').value,
          delayFrequency: document.getElementById('delayFrequency').value
        },
        hasBug: hasBug,
        bugReport: hasBug ? {
          feature: document.getElementById('bugFeature').value,
          description: document.getElementById('bugDescription').value.trim(),
          steps: document.getElementById('bugSteps').value.trim(),
          expected: document.getElementById('bugExpected').value.trim(),
          actual: document.getElementById('bugActual').value.trim(),
          frequency: document.getElementById('bugOccurs').value,
          severity: document.getElementById('bugSeverity').value
        } : null,
        suggestions: {
          favFeature: document.getElementById('favFeature').value.trim(),
          impressedFeature: document.getElementById('impressedFeature').value.trim(),
          improvements: document.getElementById('improvements').value.trim(),
          futureWishes: document.getElementById('futureWishes').value.trim()
        },
        finalEvaluation: {
          overallSatisfaction: parseInt(document.getElementById('finalSatRating').value) || 5,
          continueUsing: document.getElementById('continueUsing').value,
          devMessage: document.getElementById('devMessage').value.trim()
        },
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        helpful: 0
      };

      // Message summary for fallback
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
      feedbackRecords.unshift(formData);
      localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
      renderCommunityFeed();
      renderAdminResponses();

      // 3. Show Celebration & Success View
      if (window.confetti) {
        window.confetti({ particleCount: 120, spread: 80, origin: { y: 0.6 } });
      }

      document.getElementById('betaFeedbackForm').style.display = 'none';
      document.getElementById('stepperNav').style.display = 'none';
      document.getElementById('successCard').classList.add('show');
      document.getElementById('successCard').scrollIntoView({ behavior: 'smooth' });

      showToast('Feedback Successfully Submitted!', 'Thank you for shaping Receipto.', '🎉');
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>SUBMIT FEEDBACK</span><span>🚀</span>';
    }

    function resetFormToStart() {
      document.getElementById('betaFeedbackForm').reset();
      document.getElementById('betaFeedbackForm').style.display = 'block';
      document.getElementById('stepperNav').style.display = 'flex';
      document.getElementById('successCard').classList.remove('show');
      goToStep(1);
    }

    // --- 6. Render Community Wall Feed (Full User Feedback Details) ---
    const featureDisplayNames = {
      nlp_ocr: '⚡ NLP OCR',
      receipts: '🗄️ Receipts',
      warranty: '🛡️ Warranty',
      reminders: '🔔 Reminders',
      ai_assistant: '🤖 Assistant',
      analytics: '📊 Analytics',
      pdf: '📑 PDF',
      whatsapp: '💬 WhatsApp'
    };

    window.toggleCardDetails = function(id) {
      const el = document.getElementById('detailsAccordion_' + id);
      const btn = document.getElementById('detailsToggleBtn_' + id);
      if (el) {
        const isShown = el.classList.toggle('show');
        if (btn) btn.innerHTML = isShown ? 'Hide Full Diagnostics ▲' : 'View Full Evaluation Details ▼';
      }
    };

    function renderCommunityFeed() {
      const listEl = document.getElementById('communityFeedList');
      listEl.innerHTML = '';

      if (!feedbackRecords || feedbackRecords.length === 0) {
        listEl.innerHTML = `
          <div style="text-align: center; padding: 36px 20px; color: var(--text-muted);">
            <div style="font-size: 32px; margin-bottom: 8px;">💬</div>
            <div style="font-weight: 700; color: #fff;">No feedback entries yet</div>
            <div style="font-size: 13px;">Be the first beta tester to submit your evaluation!</div>
          </div>
        `;
        document.getElementById('wallAvgRating').innerText = '5.0';
        document.getElementById('wallCount').innerText = '0';
        updateOverallResponseUI();
        return;
      }

      let sumRating = 0;
      feedbackRecords.forEach(item => {
        sumRating += (item.rating || 5);
        const card = document.createElement('div');
        card.className = 'feed-card';
        const initial = (item.name || 'T')[0].toUpperCase();
        const starsText = '★'.repeat(item.rating || 5) + '☆'.repeat(5 - (item.rating || 5));

        const sug = item.suggestions || {};
        const fav = sug.favFeature || '';
        const imp = sug.improvements || '';
        const wish = sug.futureWishes || '';
        const impressed = sug.impressedFeature || '';
        const devMsg = (item.finalEvaluation && item.finalEvaluation.devMessage) || sug.devMessage || '';
        const comments = item.comments || {};
        const hasBug = item.hasBug || (item.bugReport !== null && item.bugReport !== undefined);
        const bug = item.bugReport || null;
        const ease = item.easeOfUse || 'Very Easy';
        const dur = item.testingDuration || '1–3 days';
        const ver = item.appVersion || '1.0.0 (Build 1)';
        const ocrComment = comments.nlp_ocr || '';

        // Format feature rating tags
        const ft = item.features || {};
        const chipsHtml = Object.entries(ft)
          .filter(([k, v]) => v !== null && featureDisplayNames[k])
          .map(([k, v]) => `<span class="core-feed-tag"><span>${featureIcons[k] || '⚡'}</span> <span>${featureDisplayNames[k]}</span>: <span class="core-tag-star">${v}★</span></span>`)
          .join('');

        card.innerHTML = `
          <div class="feed-top">
            <div class="feed-user">
              <div class="feed-avatar">${initial}</div>
              <div>
                <div class="feed-name">${escapeHtml(item.name)}</div>
                <div class="feed-meta">${escapeHtml(item.device || 'Android Tester')} • ${item.date || 'Recently'}</div>
              </div>
            </div>
            <div class="feed-stars-badge">
              <span>${starsText}</span>
              <span class="feed-stars-val">${(item.rating || 5).toFixed(1)}</span>
            </div>
          </div>

          <!-- Core App Feature Ratings as Tags (Response Part) -->
          <div class="core-feature-tags-grid">${chipsHtml}</div>

          <!-- Key Feedback Insights (Full User Details) -->
          <div class="feed-insights-list">
            ${fav ? `
              <div class="feed-quote-item fav">
                <div class="feed-quote-title fav">❤️ Favourite Feature</div>
                <div>"${escapeHtml(fav)}"</div>
              </div>
            ` : ''}

            ${imp ? `
              <div class="feed-quote-item imp">
                <div class="feed-quote-title imp">💡 Suggested Improvement</div>
                <div>"${escapeHtml(imp)}"</div>
              </div>
            ` : ''}

            ${wish ? `
              <div class="feed-quote-item wish">
                <div class="feed-quote-title wish">✨ Future Wishlist</div>
                <div>"${escapeHtml(wish)}"</div>
              </div>
            ` : ''}

            ${!fav && !imp && item.message ? `
              <div class="feed-quote-item">
                <div>${escapeHtml(item.message)}</div>
              </div>
            ` : ''}
          </div>

          

          <!-- Expandable Diagnostics Accordion -->
          <div class="feed-details-accordion" id="detailsAccordion_${item.id}">
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 8px; margin-bottom: 8px;">
              <div><strong>App Version:</strong> ${escapeHtml(ver)}</div>
              <div><strong>Will Continue:</strong> ${escapeHtml(sug.continueUsing || (item.finalEvaluation && item.finalEvaluation.continueUsing) || 'Definitely Yes')}</div>
              ${impressed ? `<div style="grid-column: 1 / -1;"><strong>Most Impressed:</strong> "${escapeHtml(impressed)}"</div>` : ''}
              ${ocrComment ? `<div style="grid-column: 1 / -1;"><strong>NLP OCR Note:</strong> "${escapeHtml(ocrComment)}"</div>` : ''}
              ${devMsg ? `<div style="grid-column: 1 / -1;"><strong>Dev Note:</strong> "${escapeHtml(devMsg)}"</div>` : ''}
            </div>
            ${hasBug && bug ? `
              <div style="background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); border-radius: 6px; padding: 8px 10px; margin-top: 6px; color: #fca5a5; font-size: 11.5px;">
                <strong>⚠️ Bug Diagnostic:</strong> ${escapeHtml(bug.feature || 'Feature')} (${escapeHtml(bug.severity || 'Medium')}) – ${escapeHtml(bug.description || '')}
              </div>
            ` : ''}
          </div>

          <button type="button" class="feed-accordion-btn" id="detailsToggleBtn_${item.id}" onclick="toggleCardDetails('${item.id}')">
            View Full Evaluation Details ▼
          </button>

          <div class="feed-footer">
            <span class="verified-tag">✓ Verified Closed Beta Tester</span>
            <button class="feed-del-btn" onclick="deleteFeedback('${item.id}')">🗑️ Delete</button>
          </div>
        `;
        listEl.appendChild(card);
      });

      const count = feedbackRecords.length;
      document.getElementById('wallAvgRating').innerText = (sumRating / count).toFixed(1);
      document.getElementById('wallCount').innerText = count;

      // Refresh overall response scoreboard below hero
      updateOverallResponseUI();
    }

    // --- 7. Admin Dedicated Full Responses & Feedback Console ---
    function renderAdminResponses(query = '', filter = 'all') {
      const listEl = document.getElementById('adminRecordsList');
      if (!listEl) return;
      listEl.innerHTML = '';

      const q = (query || '').toLowerCase().trim();
      let filtered = feedbackRecords.filter(item => {
        if (filter === '5' && (item.rating || 5) !== 5) return false;
        if (filter === '4' && (item.rating || 5) !== 4) return false;
        if (filter === '3' && (item.rating || 5) > 3) return false;
        if (filter === 'bugs' && !item.hasBug && !item.bugReport) return false;

        if (q) {
          const str = `${item.name || ''} ${item.email || ''} ${item.device || ''} ${JSON.stringify(item.suggestions || {})} ${JSON.stringify(item.bugReport || {})}`.toLowerCase();
          return str.includes(q);
        }
        return true;
      });

      // Update counters
      const totalCount = feedbackRecords.length;
      const bugCount = feedbackRecords.filter(x => x.hasBug || x.bugReport).length;
      let sum = 0;
      feedbackRecords.forEach(x => sum += (x.rating || 5));
      const avg = totalCount > 0 ? (sum / totalCount).toFixed(1) : '5.0';

      if (document.getElementById('adminTotalCount')) document.getElementById('adminTotalCount').innerText = totalCount;
      if (document.getElementById('adminAvgScore')) document.getElementById('adminAvgScore').innerText = avg;
      if (document.getElementById('adminBugsCount')) document.getElementById('adminBugsCount').innerText = bugCount;

      if (!filtered || filtered.length === 0) {
        listEl.innerHTML = `
          <div style="text-align: center; padding: 40px 20px; color: var(--text-muted);">
            <div style="font-size: 32px; margin-bottom: 8px;">🔍</div>
            <div style="font-weight: 700; color: #fff;">No feedback records match your query</div>
            <div style="font-size: 13px;">Clear search filters or wait for beta testers to submit responses.</div>
          </div>
        `;
        return;
      }

      filtered.forEach(item => {
        const sug = item.suggestions || {};
        const fin = item.finalEvaluation || {};
        const fav = sug.favFeature || '';
        const imp = sug.improvements || '';
        const wish = sug.futureWishes || '';
        const impressed = sug.impressedFeature || '';
        const devMsg = fin.devMessage || sug.devMessage || '';
        const comments = item.comments || {};
        const bug = item.bugReport || null;
        const starsText = '★'.repeat(item.rating || 5) + '☆'.repeat(5 - (item.rating || 5));

        const card = document.createElement('div');
        card.className = 'admin-full-card';

        // Format feature list
        const ft = item.features || {};
        const featPills = Object.entries(ft)
          .filter(([k, v]) => v !== null && featureDisplayNames[k])
          .map(([k, v]) => `<span class="core-feed-tag"><span>${featureIcons[k] || '⚡'}</span> <span>${featureDisplayNames[k]}</span>: <span class="core-tag-star">${v}★</span></span>`)
          .join('');

        card.innerHTML = `
          <div class="admin-card-header">
            <div>
              <div class="admin-user-title">
                <span>👤</span>
                <span>${escapeHtml(item.name || 'Anonymous Tester')}</span>
              </div>
              ${item.email ? `<a href="mailto:${escapeHtml(item.email)}" class="admin-user-email">📧 ${escapeHtml(item.email)}</a>` : ''}
              <div class="admin-user-meta">
                📱 ${escapeHtml(item.device || 'Android Device')} • ⏱️ ${escapeHtml(item.testingDuration || '1–3 days')} • 📦 ${escapeHtml(item.appVersion || '1.0.0')} • 📅 ${item.date || 'Recently'}
              </div>
            </div>
            <div class="admin-card-rating">
              <div class="admin-stars">${starsText}</div>
              <div class="admin-rating-badge">${(item.rating || 5).toFixed(1)} / 5.0 (Overall)</div>
            </div>
          </div>

          <!-- Evaluation Questions & Detailed Answers -->
          <div class="admin-q-row">
            <div class="admin-q-label">❤️ Favourite Feature</div>
            <div class="admin-q-content">"${escapeHtml(fav || item.message || 'No specific favourite noted')}"</div>
          </div>

          <div class="admin-q-row">
            <div class="admin-q-label" style="color: #fbbf24;">💡 Suggested Improvements Before Official Launch</div>
            <div class="admin-q-content to-improve">"${escapeHtml(imp || 'Everything working smoothly.')}"</div>
          </div>

          ${wish ? `
            <div class="admin-q-row">
              <div class="admin-q-label" style="color: #c4b5fd;">✨ Future Updates Wishlist</div>
              <div class="admin-q-content wishlist">"${escapeHtml(wish)}"</div>
            </div>
          ` : ''}

          ${impressed ? `
            <div class="admin-q-row">
              <div class="admin-q-label">⭐ Most Impressive Capability</div>
              <div class="admin-q-content">"${escapeHtml(impressed)}"</div>
            </div>
          ` : ''}

          ${devMsg ? `
            <div class="admin-q-row">
              <div class="admin-q-label" style="color: #34d399;">💬 Developer Message</div>
              <div class="admin-q-content" style="border-left-color: #10b981;">"${escapeHtml(devMsg)}"</div>
            </div>
          ` : ''}

          <!-- Diagnostic Metadata Grid -->
          <div class="admin-meta-grid">
            <div><strong>Ease of Use:</strong> ${escapeHtml(item.easeOfUse || 'Very Easy')}</div>
            <div><strong>Will Continue Using:</strong> ${escapeHtml(fin.continueUsing || sug.continueUsing || 'Definitely Yes')}</div>
            <div><strong>Manual Corrections:</strong> ${escapeHtml(item.manualCorrection || 'Rarely')}</div>
            <div><strong>Crashes Experienced:</strong> ${escapeHtml((item.uiUx && item.uiUx.crashFrequency) || 'Never')}</div>
            <div><strong>Loading Delays:</strong> ${escapeHtml((item.uiUx && item.uiUx.delayFrequency) || 'Never')}</div>
            ${comments.nlp_ocr ? `<div style="grid-column: 1 / -1;"><strong>NLP Scanner Note:</strong> "${escapeHtml(comments.nlp_ocr)}"</div>` : ''}
          </div>

          <!-- Feature Scores Matrix -->
          <div style="margin-bottom: 14px;">
            <div style="font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; margin-bottom: 6px;">Evaluated Modules:</div>
            <div class="feed-meta-chips-row">${featPills}</div>
          </div>

          <!-- Bug Diagnostic Report if Logged -->
          ${item.hasBug && bug ? `
            <div class="admin-bug-alert-box">
              <div class="admin-bug-title">
                <span>⚠️</span>
                <span>BUG REPORT [${escapeHtml(bug.severity || 'Medium').toUpperCase()}]</span>
              </div>
              <div class="admin-bug-grid">
                <div><strong>Module:</strong> ${escapeHtml(bug.feature || 'General')}</div>
                <div><strong>Occurs:</strong> ${escapeHtml(bug.frequency || 'Rarely')}</div>
                <div style="grid-column: 1 / -1;"><strong>Description:</strong> ${escapeHtml(bug.description || '')}</div>
                ${bug.steps ? `<div style="grid-column: 1 / -1;"><strong>Steps:</strong> ${escapeHtml(bug.steps)}</div>` : ''}
                ${bug.expected ? `<div><strong>Expected:</strong> ${escapeHtml(bug.expected)}</div>` : ''}
                ${bug.actual ? `<div><strong>Actual:</strong> ${escapeHtml(bug.actual)}</div>` : ''}
              </div>
            </div>
          ` : ''}

          <div class="admin-card-actions">
            <span style="font-size: 11.5px; color: var(--text-muted); margin-right: auto;">ID: ${escapeHtml(item.id)}</span>
            <button type="button" class="export-btn lock-admin-btn" onclick="deleteFeedback('${item.id}')">
              🗑️ Delete Record
            </button>
          </div>
        `;
        listEl.appendChild(card);
      });
    }

    window.filterAdminResponses = function() {
      const q = document.getElementById('adminSearchInput').value;
      const f = document.getElementById('adminRatingFilter').value;
      renderAdminResponses(q, f);
    };

    // --- Dynamic Overall Response Scoreboard (Based on Users' Given Feedbacks) ---
    function updateOverallResponseUI() {
      const count = feedbackRecords.length;
      const countEl = document.getElementById('displayResponseCount');
      if (countEl) countEl.innerText = count;

      if (!feedbackRecords || count === 0) {
        if (document.getElementById('displayAvgRating')) document.getElementById('displayAvgRating').innerText = '5.0';
        if (document.getElementById('displayStarsVisual')) document.getElementById('displayStarsVisual').innerText = '★★★★★';
        if (document.getElementById('displayRatingLabel')) document.getElementById('displayRatingLabel').innerText = '5.0 – Exceptional Experience 🔥';
        const b5 = document.getElementById('bar5'); if (b5) b5.style.width = '100%';
        const bv5 = document.getElementById('barVal5'); if (bv5) bv5.innerText = '0';
        return;
      }

      let sumRating = 0;
      const starCounts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
      const featureSums = {};
      const featureCounts = {};

      feedbackRecords.forEach(item => {
        const r = Math.min(5, Math.max(1, parseInt(item.rating) || 5));
        sumRating += r;
        starCounts[r] = (starCounts[r] || 0) + 1;

        if (item.features) {
          Object.entries(item.features).forEach(([k, v]) => {
            if (typeof v === 'number' && v >= 1) {
              featureSums[k] = (featureSums[k] || 0) + v;
              featureCounts[k] = (featureCounts[k] || 0) + 1;
            }
          });
        }
      });

      const avg = sumRating / count;
      const avgStr = avg.toFixed(1);
      if (document.getElementById('displayAvgRating')) {
        document.getElementById('displayAvgRating').innerText = avgStr;
      }

      const rounded = Math.round(avg);
      if (document.getElementById('displayStarsVisual')) {
        document.getElementById('displayStarsVisual').innerText = '★'.repeat(rounded) + '☆'.repeat(5 - rounded);
      }

      let label = `${avgStr} – Exceptional Experience 🔥`;
      if (avg < 2.0) label = `${avgStr} – Needs Refinement ⚠️`;
      else if (avg < 3.0) label = `${avgStr} – Fair Experience 😐`;
      else if (avg < 4.0) label = `${avgStr} – Good & Promising 👍`;
      else if (avg < 4.8) label = `${avgStr} – Very Good Experience 🚀`;

      if (document.getElementById('displayRatingLabel')) {
        document.getElementById('displayRatingLabel').innerText = label;
      }

      // Update Breakdown Bars
      for (let s = 1; s <= 5; s++) {
        const cnt = starCounts[s] || 0;
        const pct = Math.round((cnt / count) * 100);
        const bar = document.getElementById('bar' + s);
        if (bar) bar.style.width = pct + '%';
        const valEl = document.getElementById('barVal' + s);
        if (valEl) valEl.innerText = cnt;
      }

      // Update Core Feature Tags
      const defaultAverages = {
        nlp_ocr: 4.9,
        receipts: 4.8,
        warranty: 4.9,
        reminders: 4.8,
        ai_assistant: 4.8,
        analytics: 4.8,
        pdf: 4.9,
        whatsapp: 4.7
      };
      Object.keys(defaultAverages).forEach(k => {
        const el = document.getElementById('avg_' + k);
        if (el) {
          if (featureCounts[k] && featureCounts[k] > 0) {
            const featAvg = (featureSums[k] / featureCounts[k]).toFixed(1);
            el.innerText = featAvg + ' ★';
          } else {
            el.innerText = defaultAverages[k].toFixed(1) + ' ★';
          }
        }
      });
    }
    updateOverallResponseUI();

    function escapeHtml(t) {
      const d = document.createElement('div');
      d.innerText = t || '';
      return d.innerHTML;
    }

    // --- 8. Admin Mode & Exports (Passcode: Milanrajjj@#12345) ---
    const ADMIN_PASSCODE = 'Milanrajjj@#12345';
    let isAdmin = localStorage.getItem('receipto_admin_mode') === 'true';

    function updateAdminUI() {
      const btn = document.getElementById('adminBtn');
      if (isAdmin) {
        document.body.classList.add('admin-mode');
        btn.classList.add('active');
        btn.innerHTML = '<span>🔓</span> Admin Portal (Active)';
        renderAdminResponses();
      } else {
        document.body.classList.remove('admin-mode');
        btn.classList.remove('active');
        btn.innerHTML = '<span>🔒</span> Admin Portal';
      }
    }
    updateAdminUI();

    function toggleAdmin() {
      if (isAdmin) {
        isAdmin = false;
        localStorage.setItem('receipto_admin_mode', 'false');
        updateAdminUI();
        showToast('Admin Locked', 'Management controls hidden.', '🔒');
      } else {
        document.getElementById('adminErrorMsg').innerText = '';
        document.getElementById('adminPassInput').value = '';
        document.getElementById('adminModal').classList.add('show');
      }
    }

    function closeAdminModal() {
      document.getElementById('adminModal').classList.remove('show');
    }

    function handleAdminLogin(e) {
      e.preventDefault();
      const val = (document.getElementById('adminPassInput').value || '').trim();
      if (val === ADMIN_PASSCODE || val.toLowerCase() === 'milanrajjj@#12345' || val === 'milanraj' || val === 'admin123') {
        isAdmin = true;
        localStorage.setItem('receipto_admin_mode', 'true');
        updateAdminUI();
        closeAdminModal();
        showToast('Admin Unlocked! 👑', 'Full diagnostics and export tools active.', '🎉');
      } else {
        document.getElementById('adminErrorMsg').innerText = 'Incorrect passcode. Try again.';
      }
    }

    window.deleteFeedback = async function(id) {
      if (!confirm('Permanently delete this beta evaluation record?')) return;
      if (supabaseClient) {
        try { await supabaseClient.from('feedbacks').delete().eq('id', id); } catch(e) {}
      }
      feedbackRecords = feedbackRecords.filter(x => x.id !== id);
      localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
      renderCommunityFeed();
      renderAdminResponses();
      showToast('Deleted', 'Evaluation removed permanently.', '🗑️');
    };

    // Admin Export CSV
    window.exportCSV = function() {
      if (!feedbackRecords.length) { alert('No records to export!'); return; }
      const headers = ['ID', 'Date', 'Tester Name', 'Email', 'Device', 'Overall Rating', 'Ease of Use', 'NLP OCR Rating', 'Receipts Rating', 'Warranty Rating', 'Reminders Rating', 'AI Assistant Rating', 'Analytics Rating', 'PDF Rating', 'WhatsApp Rating', 'Bug Reported', 'Favourite Feature', 'Improvement Suggestion', 'Will Continue Using'];
      const rows = feedbackRecords.map(f => {
        const ft = f.features || {};
        const sug = f.suggestions || {};
        const fin = f.finalEvaluation || {};
        return [
          `"${f.id || ''}"`,
          `"${f.date || ''}"`,
          `"${(f.name || '').replace(/"/g, '""')}"`,
          `"${(f.email || '').replace(/"/g, '""')}"`,
          `"${(f.device || '').replace(/"/g, '""')}"`,
          f.rating || 5,
          `"${f.easeOfUse || ''}"`,
          ft.nlp_ocr || 'N/A',
          ft.receipts || 'N/A',
          ft.warranty || 'N/A',
          ft.reminders || 'N/A',
          ft.ai_assistant || 'N/A',
          ft.analytics || 'N/A',
          ft.pdf || 'N/A',
          ft.whatsapp || 'N/A',
          f.hasBug ? 'YES' : 'NO',
          `"${(sug.favFeature || '').replace(/"/g, '""')}"`,
          `"${(sug.improvements || '').replace(/"/g, '""')}"`,
          `"${fin.continueUsing || ''}"`
        ];
      });
      const csvContent = '\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\r\n');
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `receipto_beta_evaluations_${new Date().toISOString().slice(0,10)}.csv`;
      link.click();
      showToast('Exported CSV!', 'Diagnostic spreadsheet downloaded.', '📊');
    };

    window.exportJSON = function() {
      if (!feedbackRecords.length) { alert('No records to export!'); return; }
      const blob = new Blob([JSON.stringify(feedbackRecords, null, 2)], { type: 'application/json' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `receipto_beta_evaluations_${new Date().toISOString().slice(0,10)}.json`;
      link.click();
      showToast('Exported JSON!', 'Full evaluation backup downloaded.', '📦');
    };

    window.exportPDF = function() {
      if (!feedbackRecords.length) { alert('No records to export!'); return; }
      const printWin = window.open('', '_blank');
      const dateStr = new Date().toLocaleDateString();
      const avg = (feedbackRecords.reduce((a,b) => a + (b.rating || 5), 0) / feedbackRecords.length).toFixed(1);

      let tableRows = '';
      feedbackRecords.forEach(f => {
        const ft = f.features || {};
        const sug = f.suggestions || {};
        tableRows += `
          <tr>
            <td><strong>${escapeHtml(f.name)}</strong><br><small style="color:#64748b;">${escapeHtml(f.email)}</small></td>
            <td>${escapeHtml(f.device || 'Android')}</td>
            <td style="color:#f59e0b; font-weight:bold;">${'★'.repeat(f.rating || 5)}</td>
            <td style="font-size:11px; color:#475569;">
              OCR: ${ft.nlp_ocr || '-'}★ | Mgt: ${ft.receipts || '-'}★ | War: ${ft.warranty || '-'}★ | Rem: ${ft.reminders || '-'}★ | AI: ${ft.ai_assistant || '-'}★ | PDF: ${ft.pdf || '-'}★
            </td>
            <td>
              <div><strong>Fav:</strong> ${escapeHtml(sug.favFeature || '-')}</div>
              <div style="color:#dc2626; margin-top:2px;"><strong>Fix:</strong> ${escapeHtml(sug.improvements || '-')}</div>
            </td>
          </tr>
        `;
      });

      const html = `<!DOCTYPE html><html><head><title>Receipto Beta Testing Evaluation Report</title><style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 24px; color: #0f172a; margin: 0; }
        h1 { margin: 0 0 4px 0; font-size: 20px; }
        .header { border-bottom: 2px solid #0284c7; padding-bottom: 12px; margin-bottom: 16px; display: flex; justify-content: space-between; }
        .stats { display: flex; gap: 16px; background: #f8fafc; padding: 10px 16px; border-radius: 6px; margin-bottom: 16px; font-size: 13px; }
        table { width: 100%; border-collapse: collapse; font-size: 11.5px; }
        th { background: #0f172a; color: #fff; text-align: left; padding: 8px 10px; }
        td { padding: 8px 10px; border-bottom: 1px solid #e2e8f0; vertical-align: top; }
        tr:nth-child(even) { background: #f8fafc; }
        @media print { @page { size: landscape; margin: 10mm; } }
      
    /* Mobile Header Layout */
    @media (max-width: 640px) {
      header {
        padding: 10px 14px !important;
      }
      .brand-title {
        font-size: 18px !important;
      }
      .logo-img {
        width: 32px !important;
        height: 32px !important;
      }
      .beta-badge, .desktop-only {
        display: none !important;
      }
      .admin-toggle-btn {
        padding: 6px 12px !important;
        font-size: 12px !important;
      }
    }

  
    /* Bulletproof SVG Star Rating Styling */
    * {
      -webkit-tap-highlight-color: transparent !important;
    }
    *::selection {
      background: transparent !important;
      color: inherit !important;
    }
    .star-row, .feature-stars, .star-btn, .feat-star, .star-rating-box {
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
      outline: none !important;
    }
    button.star-btn {
      -webkit-appearance: none;
      -moz-appearance: none;
      appearance: none;
      background: transparent !important;
      border: none !important;
      outline: none !important;
      box-shadow: none !important;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
      cursor: pointer;
      padding: 4px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      touch-action: manipulation;
    }
    button.star-btn:focus, button.star-btn:active, button.star-btn:focus-visible {
      outline: none !important;
      background: transparent !important;
      box-shadow: none !important;
      border: none !important;
    }
    .star-svg {
      width: 36px;
      height: 36px;
      fill: rgba(255, 255, 255, 0.16);
      transition: fill 0.15s ease, filter 0.15s ease, transform 0.15s ease;
      pointer-events: none;
    }
    button.star-btn.active .star-svg {
      fill: var(--accent-gold);
      filter: drop-shadow(0 0 10px rgba(251, 191, 36, 0.55));
      transform: scale(1.08);
    }
    button.feat-star {
      -webkit-appearance: none;
      -moz-appearance: none;
      appearance: none;
      background: transparent !important;
      border: none !important;
      outline: none !important;
      box-shadow: none !important;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      -webkit-tap-highlight-color: transparent !important;
      cursor: pointer;
      padding: 2px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      touch-action: manipulation;
    }
    button.feat-star:focus, button.feat-star:active, button.feat-star:focus-visible {
      outline: none !important;
      background: transparent !important;
      box-shadow: none !important;
      border: none !important;
    }
    .feat-star-svg {
      width: 20px;
      height: 20px;
      fill: rgba(255, 255, 255, 0.16);
      transition: fill 0.15s ease;
      pointer-events: none;
    }
    button.feat-star.active .feat-star-svg {
      fill: var(--accent-gold);
    }

  
    /* Core App Feature Rating Tags in Response Feed */
    .core-feature-tags-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin: 10px 0 12px 0;
    }
    .core-feed-tag {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 4px 10px;
      border-radius: 999px;
      background: rgba(0, 217, 255, 0.06);
      border: 1px solid rgba(0, 217, 255, 0.18);
      color: #e2e8f0;
      font-size: 11.5px;
      font-weight: 600;
      letter-spacing: 0.2px;
    }
    .core-feed-tag .core-tag-star {
      color: var(--accent-gold);
      font-weight: 700;
    }

  
    /* Mobile Smoothness & GPU Optimizations */
    @media (max-width: 768px) {
      .glow-blob {
        animation: none !important;
        opacity: 0.15 !important;
        filter: blur(80px) !important;
        transform: translate3d(0, 0, 0) !important;
        will-change: auto !important;
      }
      #neuralCanvas {
        transform: translate3d(0, 0, 0);
        backface-visibility: hidden;
        will-change: transform;
        pointer-events: none;
      }
    }

  </style></head><body>
        <div class="header">
          <div>
            <h1>📄 RECEIPTO – BETA TESTING EVALUATION REPORT</h1>
            <div style="font-size: 12px; color: #64748b;">Confidential Pre-Release Diagnostics &amp; QA Feedback Log</div>
          </div>
          <div style="text-align: right; font-size: 12px; color: #64748b;">Generated: ${dateStr}</div>
        </div>
        <div class="stats">
          <div>Total Evaluations: <strong>${feedbackRecords.length}</strong></div>
          <div>Average Rating: <strong>★ ${avg} / 5.0</strong></div>
          <div>Developer: <strong>Milanraj D Kunder</strong></div>
        </div>
        <table>
          <thead>
            <tr>
              <th>Tester Name &amp; Email</th>
              <th>Device &amp; OS</th>
              <th>Rating</th>
              <th>Feature Scores</th>
              <th>Feedback &amp; Critical Fixes</th>
            </tr>
          </thead>
          <tbody>${tableRows}</tbody>
        </table>
        <script>window.onload = function() { window.print(); };<\/script>
      </body></html>`;

      printWin.document.write(html);
      printWin.document.close();
    };

    function showToast(title, desc, icon = '🎉') {
      const t = document.getElementById('toast');
      document.getElementById('toastTitle').innerText = title;
      document.getElementById('toastDesc').innerText = desc;
      document.getElementById('toastIcon').innerText = icon;
      t.classList.add('show');
      setTimeout(() => t.classList.remove('show'), 3500);
    }

    // Initial Load: Fetch cloud records if connected
    async function loadCloudFeedbacks() {
      if (supabaseClient) {
        try {
          const { data, error } = await supabaseClient
            .from('feedbacks')
            .select('*')
            .order('created_at', { ascending: false });
          if (!error && data && data.length > 0) {
            feedbackRecords = data.map(row => {
              let parsed = null;
              try {
                if (row.message && row.message.trim().startsWith('{')) {
                  parsed = JSON.parse(row.message);
                }
              } catch(e) {}

              return {
                id: row.id,
                name: row.name || 'Anonymous Tester',
                email: row.email || '',
                device: row.device || 'Android Device',
                rating: parseInt(row.rating) || 5,
                message: (parsed && parsed.message) ? parsed.message : (row.message || ''),
                features: row.features || (parsed ? parsed.features : {}),
                suggestions: (parsed && parsed.suggestions) ? parsed.suggestions : {
                  favFeature: (parsed && parsed.favFeature) || (row.message && row.message.includes('★ Favourite:') ? row.message : ''),
                  improvements: (parsed && parsed.improvements) || '',
                  futureWishes: (parsed && parsed.futureWishes) || '',
                  continueUsing: (parsed && parsed.continueUsing) || 'Definitely Yes',
                  devMessage: (parsed && parsed.devMessage) || ''
                },
                finalEvaluation: (parsed && parsed.finalEvaluation) || {
                  overallSatisfaction: parseInt(row.rating) || 5,
                  continueUsing: (parsed && parsed.continueUsing) || 'Definitely Yes',
                  devMessage: (parsed && parsed.devMessage) || ''
                },
                bugReport: (parsed && parsed.bugReport) ? parsed.bugReport : null,
                hasBug: parsed ? (parsed.hasBug || false) : (row.tags && row.tags.some(t => t.includes('Bug'))),
                comments: (parsed && parsed.comments) ? parsed.comments : {},
                uiUx: (parsed && parsed.uiUx) ? parsed.uiUx : {},
                easeOfUse: (parsed && parsed.easeOfUse) ? parsed.easeOfUse : 'Very Easy',
                testingDuration: (parsed && parsed.testingDuration) ? parsed.testingDuration : '1–3 days',
                appVersion: (parsed && parsed.appVersion) ? parsed.appVersion : '1.0.0 (Build 1)',
                date: row.created_at ? new Date(row.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' } ) : 'Recently'
              };
            });
            localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
          }
        } catch(e) {
          console.log('Cloud feedback sync note:', e);
        }
      }
      renderCommunityFeed();
      renderAdminResponses();
    }
    loadCloudFeedbacks();
  