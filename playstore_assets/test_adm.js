
    // Supabase Configuration
    const SUPABASE_URL = 'https://ykqzefulvpqfiwsddnqt.supabase.co';
    const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcXplZnVsdnBxZml3c2RkbnF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTI2NTcsImV4cCI6MjA5ODMyODY1N30.NFm5dT7vVeHtziEkYWN-qk8ZEogpktPZ7NTmXDLO1Qs';
    let supabaseClient = null;
    try {
      supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    } catch(e) {
      console.log('Supabase init note:', e);
    }

    const MASTER_PASSCODES = ['Milanrajjj@#12345', 'milanraj', 'admin123'];

    const featureDisplayNames = {
      nlp_ocr: 'NLP OCR',
      receipts: 'Receipt Vault',
      warranty: 'Warranty Tracker',
      reminders: 'Expiry Reminders',
      ai_assistant: 'AI Assistant',
      analytics: 'Analytics',
      pdf: 'PDF Export',
      whatsapp: 'WhatsApp Bot'
    };

    const featureIcons = {
      nlp_ocr: '⚡',
      receipts: '🗄️',
      warranty: '🛡️',
      reminders: '🔔',
      ai_assistant: '🤖',
      analytics: '📊',
      pdf: '📑',
      whatsapp: '💬'
    };

    // Initial mock data if empty
    const INITIAL_RECORDS = [
      {
        id: 'rec_milanraj_01',
        name: 'Milanraj Kunder',
        email: 'milanraj616@gmail.com',
        device: 'OnePlus 11R 5G (Android 14)',
        rating: 5,
        easeOfUse: 'Very Easy',
        testingDuration: '1–2 weeks',
        appVersion: '1.0.0 (Build 1)',
        date: 'Nov 3, 2026',
        features: {
          nlp_ocr: 5,
          receipts: 5,
          warranty: 5,
          reminders: 5,
          ai_assistant: 5,
          analytics: 5,
          pdf: 5,
          whatsapp: 4
        },
        suggestions: {
          favFeature: 'PaddleOCR instant receipt parsing and automated warranty identification',
          impressedFeature: 'NLP extraction accuracy on thermal supermarket paper receipts',
          improvements: 'Add multi-currency selector for international travel bills',
          futureWishes: 'Receipt backup to Google Drive / WebDAV',
          devMessage: 'Excellent production-grade app. Ready for official Google Play store release!'
        },
        bugReport: null,
        hasBug: false
      },
      {
        id: 'rec_tester_02',
        name: 'Aarav Sharma',
        email: 'aarav.sharma@gmail.com',
        device: 'Samsung Galaxy S23 (Android 14)',
        rating: 5,
        easeOfUse: 'Very Easy',
        testingDuration: '3–7 days',
        appVersion: '1.0.0 (Build 1)',
        date: 'Nov 2, 2026',
        features: {
          nlp_ocr: 5,
          receipts: 5,
          warranty: 5,
          reminders: 5,
          ai_assistant: 5,
          analytics: 4,
          pdf: 5,
          whatsapp: 5
        },
        suggestions: {
          favFeature: 'Warranty Tracker countdown and instant PDF invoice generator',
          impressedFeature: 'WhatsApp bot receipt forwarding and automatic vault sync',
          improvements: 'Batch receipt photo scanning from camera roll',
          futureWishes: 'Smart category tags based on merchant name',
          devMessage: 'Super smooth UI, cyber dark theme looks incredibly clean.'
        },
        bugReport: null,
        hasBug: false
      }
    ];

    let feedbackRecords = [];

    // Check Auth State on Page Load
    function checkAuth() {
      const isAuth = sessionStorage.getItem('receipto_admin_unlocked') === 'true';
      const gateCard = document.getElementById('gateCard');
      const adminConsole = document.getElementById('adminConsole');

      if (isAuth) {
        gateCard.style.display = 'none';
        adminConsole.style.display = 'block';
        loadCloudFeedbacks();
      } else {
        gateCard.style.display = 'block';
        adminConsole.style.display = 'none';
      }
    }

    function unlockAdmin() {
      const input = document.getElementById('passInput');
      const error = document.getElementById('gateError');
      const val = (input.value || '').trim();

      if (MASTER_PASSCODES.includes(val)) {
        sessionStorage.setItem('receipto_admin_unlocked', 'true');
        error.style.display = 'none';
        input.value = '';
        checkAuth();
      } else {
        error.style.display = 'block';
        input.classList.add('input-error');
        setTimeout(() => input.classList.remove('input-error'), 800);
      }
    }

    function lockAdmin() {
      sessionStorage.removeItem('receipto_admin_unlocked');
      checkAuth();
    }

    // Load feedbacks from LocalStorage and Supabase
    async function loadCloudFeedbacks() {
      // Try local storage first
      try {
        const cached = localStorage.getItem('receipto_feedbacks');
        if (cached) {
          feedbackRecords = JSON.parse(cached);
        } else {
          feedbackRecords = INITIAL_RECORDS;
        }
      } catch(e) {
        feedbackRecords = INITIAL_RECORDS;
      }

      // Fetch from Supabase
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
                if (row.message && (row.message.startsWith('{') || row.message.startsWith('['))) {
                  parsed = JSON.parse(row.message);
                }
              } catch(err) {}

              return {
                id: row.id ? String(row.id) : ('rec_' + Math.random().toString(36).substr(2, 9)),
                name: row.name || 'Beta Tester',
                email: row.email || '',
                device: row.device || 'Android Device',
                rating: row.rating || 5,
                features: (parsed && parsed.features) ? parsed.features : (row.features || {}),
                suggestions: {
                  favFeature: (parsed && parsed.favFeature) || '',
                  impressedFeature: (parsed && parsed.impressedFeature) || '',
                  improvements: (parsed && parsed.improvements) || '',
                  futureWishes: (parsed && parsed.futureWishes) || '',
                  devMessage: (parsed && parsed.devMessage) || ''
                },
                bugReport: (parsed && parsed.bugReport) ? parsed.bugReport : null,
                hasBug: parsed ? (parsed.hasBug || false) : false,
                easeOfUse: (parsed && parsed.easeOfUse) ? parsed.easeOfUse : 'Very Easy',
                testingDuration: (parsed && parsed.testingDuration) ? parsed.testingDuration : '1–3 days',
                appVersion: (parsed && parsed.appVersion) ? parsed.appVersion : '1.0.0 (Build 1)',
                date: row.created_at ? new Date(row.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : 'Recently'
              };
            });
            localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
          }
        } catch(err) {
          console.log('Cloud sync note:', err);
        }
      }

      renderRecords();
    }

    function handleFilterChange() {
      const query = (document.getElementById('adminSearchInput').value || '').toLowerCase().trim();
      const filter = document.getElementById('adminRatingFilter').value;
      renderRecords(query, filter);
    }

    function renderRecords(query = '', filter = 'all') {
      const feedEl = document.getElementById('adminRecordsFeed');
      if (!feedEl) return;
      feedEl.innerHTML = '';

      let filtered = feedbackRecords.filter(item => {
        if (filter === '5' && (item.rating || 5) !== 5) return false;
        if (filter === '4' && (item.rating || 5) !== 4) return false;
        if (filter === '3' && (item.rating || 5) > 3) return false;
        if (filter === 'bugs' && !item.hasBug && !item.bugReport) return false;

        if (query) {
          const str = `${item.name || ''} ${item.email || ''} ${item.device || ''} ${JSON.stringify(item.suggestions || {})} ${JSON.stringify(item.bugReport || {})}`.toLowerCase();
          return str.includes(query);
        }
        return true;
      });

      // Update Metrics
      const total = feedbackRecords.length;
      let sum = 0;
      let bugs = 0;
      let fiveStars = 0;
      feedbackRecords.forEach(x => {
        const r = (x.rating || 5);
        sum += r;
        if (r === 5) fiveStars++;
        if (x.hasBug || x.bugReport) bugs++;
      });

      const avg = total > 0 ? (sum / total).toFixed(1) : '5.0';
      document.getElementById('metricTotal').innerText = total;
      document.getElementById('metricAvg').innerText = avg;
      document.getElementById('metricBugs').innerText = bugs;
      document.getElementById('metricFiveStars').innerText = fiveStars;

      if (!filtered || filtered.length === 0) {
        feedEl.innerHTML = `
          <div style="text-align: center; padding: 48px 20px; color: var(--text-muted);">
            <div style="font-size: 36px; margin-bottom: 10px;">🔍</div>
            <div style="font-size: 16px; font-weight: 700; color: #fff;">No feedback records match your query</div>
            <div style="font-size: 13px; margin-top: 4px;">Adjust search keywords or select a different rating filter.</div>
          </div>
        `;
        return;
      }

      filtered.forEach(item => {
        const card = document.createElement('div');
        card.className = 'admin-card';

        const sug = item.suggestions || {};
        const ft = item.features || {};
        const bug = item.bugReport || null;
        const initial = (item.name || 'T')[0].toUpperCase();
        const starsText = '★'.repeat(item.rating || 5) + '☆'.repeat(5 - (item.rating || 5));

        // Format Core App Feature Ratings as Tags
        const coreTagsHtml = Object.entries(ft)
          .filter(([k, v]) => v !== null && v !== undefined && featureDisplayNames[k])
          .map(([k, v]) => `
            <span class="core-tag">
              <span>${featureIcons[k] || '⚡'}</span>
              <span>${featureDisplayNames[k]}</span>:
              <span class="tag-star">${v}★</span>
            </span>
          `).join('');

        card.innerHTML = `
          <div class="admin-card-top">
            <div class="admin-card-user">
              <div class="user-avatar">${initial}</div>
              <div>
                <div class="user-name">${escapeHtml(item.name || 'Anonymous')}</div>
                <div class="user-meta">
                  ${item.email ? `<a href="mailto:${escapeHtml(item.email)}">${escapeHtml(item.email)}</a> • ` : ''}
                  ${escapeHtml(item.device || 'Android')} • ${escapeHtml(item.testingDuration || '1–3 days')} • ${escapeHtml(item.appVersion || '1.0.0')} • ${item.date || 'Recent'}
                </div>
              </div>
            </div>
            <div class="admin-card-rating">
              <span class="admin-card-stars">${starsText}</span>
              <span class="admin-card-rating-num">${(item.rating || 5).toFixed(1)} / 5.0</span>
            </div>
          </div>

          <!-- Core App Feature Ratings as Tags -->
          ${coreTagsHtml ? `
            <div class="core-tags-label">⚡ Rated Core App Features:</div>
            <div class="core-tags-grid">${coreTagsHtml}</div>
          ` : ''}

          <!-- Tester Feedback Insights -->
          <div class="insights-grid">
            ${sug.favFeature ? `
              <div class="insight-box fav">
                <div class="insight-title fav">❤️ Favourite Feature</div>
                <div>"${escapeHtml(sug.favFeature)}"</div>
              </div>
            ` : ''}
            ${sug.improvements ? `
              <div class="insight-box imp">
                <div class="insight-title imp">💡 Suggested Improvements</div>
                <div>"${escapeHtml(sug.improvements)}"</div>
              </div>
            ` : ''}
            ${sug.futureWishes ? `
              <div class="insight-box wish">
                <div class="insight-title wish">✨ Future Wishlist</div>
                <div>"${escapeHtml(sug.futureWishes)}"</div>
              </div>
            ` : ''}
            ${sug.devMessage ? `
              <div class="insight-box" style="grid-column: 1 / -1; border-left: 3px solid var(--accent-green);">
                <div class="insight-title" style="color: var(--accent-green);">💬 Note to Developer</div>
                <div>"${escapeHtml(sug.devMessage)}"</div>
              </div>
            ` : ''}
          </div>

          <!-- Bug Diagnostics (if reported) -->
          ${(item.hasBug || bug) && bug ? `
            <div class="bug-box">
              <div class="bug-title">
                <span>⚠️ Bug Report:</span>
                <span>${escapeHtml(bug.feature || 'General Feature')} (${escapeHtml(bug.severity || 'Medium')})</span>
              </div>
              <div style="margin-bottom: 4px;"><strong>Issue:</strong> ${escapeHtml(bug.description || '')}</div>
              ${bug.steps ? `<div><strong>Steps:</strong> ${escapeHtml(bug.steps)}</div>` : ''}
            </div>
          ` : ''}

          <div class="admin-card-footer">
            <span>ID: ${item.id}</span>
            <button type="button" class="del-btn" onclick="deleteFeedback('${item.id}')">🗑️ Delete Record</button>
          </div>
        `;

        feedEl.appendChild(card);
      });
    }

    async function deleteFeedback(id) {
      if (!confirm('Are you sure you want to permanently delete this evaluation?')) return;
      
      feedbackRecords = feedbackRecords.filter(x => x.id !== id);
      localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
      
      if (supabaseClient) {
        try {
          await supabaseClient.from('feedbacks').delete().eq('id', id);
        } catch(e) {
          console.log('Supabase delete note:', e);
        }
      }

      renderRecords();
    }

    // Export Excel (.xlsx) using SheetJS
    function exportToExcel() {
      if (!feedbackRecords || feedbackRecords.length === 0) {
        alert('No feedback responses available to export.');
        return;
      }

      const rows = feedbackRecords.map(item => {
        const sug = item.suggestions || {};
        const ft = item.features || {};
        const bug = item.bugReport || {};
        return {
          'Date': item.date || 'Recent',
          'Tester Name': item.name || '',
          'Email': item.email || '',
          'Device': item.device || '',
          'Overall Rating': item.rating || 5,
          'Testing Duration': item.testingDuration || '',
          'App Version': item.appVersion || '',
          'NLP OCR Rating': ft.nlp_ocr != null ? ft.nlp_ocr : '',
          'Receipt Vault Rating': ft.receipts != null ? ft.receipts : '',
          'Warranty Tracker Rating': ft.warranty != null ? ft.warranty : '',
          'Expiry Reminders Rating': ft.reminders != null ? ft.reminders : '',
          'AI Assistant Rating': ft.ai_assistant != null ? ft.ai_assistant : '',
          'Financial Analytics Rating': ft.analytics != null ? ft.analytics : '',
          'PDF Export Rating': ft.pdf != null ? ft.pdf : '',
          'WhatsApp Bot Rating': ft.whatsapp != null ? ft.whatsapp : '',
          'Favourite Feature': sug.favFeature || '',
          'Suggested Improvements': sug.improvements || '',
          'Future Wishlist': sug.futureWishes || '',
          'Dev Message': sug.devMessage || '',
          'Has Bug': (item.hasBug || bug.feature || bug.description) ? 'YES' : 'NO',
          'Bug Feature': bug.feature || '',
          'Bug Severity': bug.severity || '',
          'Bug Description': bug.description || '',
          'Bug Steps': bug.steps || ''
        };
      });

      const ws = XLSX.utils.json_to_sheet(rows);
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, "Beta Evaluations");

      // Auto-fit column widths
      const colWidths = Object.keys(rows[0] || {}).map(k => ({ wch: Math.max(k.length + 4, 16) }));
      ws['!cols'] = colWidths;

      const dateStr = new Date().toISOString().split('T')[0];
      XLSX.writeFile(wb, `Receipto_Beta_Feedback_${dateStr}.xlsx`);
    }

    // Export CSV
    function exportToCsv() {
      if (!feedbackRecords || feedbackRecords.length === 0) {
        alert('No feedback responses available to export.');
        return;
      }

      const headers = ['Date', 'Name', 'Email', 'Device', 'Overall Rating', 'Duration', 'Version', 'NLP OCR', 'Vault', 'Warranty', 'Reminders', 'AI Assistant', 'Analytics', 'PDF', 'WhatsApp', 'Favourite Feature', 'Improvements', 'Wishlist', 'Bug Logged'];
      const lines = [headers.join(',')];

      feedbackRecords.forEach(item => {
        const sug = item.suggestions || {};
        const ft = item.features || {};
        const row = [
          `"${item.date || ''}"`,
          `"${(item.name || '').replace(/"/g, '""')}"`,
          `"${(item.email || '').replace(/"/g, '""')}"`,
          `"${(item.device || '').replace(/"/g, '""')}"`,
          item.rating || 5,
          `"${item.testingDuration || ''}"`,
          `"${item.appVersion || ''}"`,
          ft.nlp_ocr != null ? ft.nlp_ocr : '',
          ft.receipts != null ? ft.receipts : '',
          ft.warranty != null ? ft.warranty : '',
          ft.reminders != null ? ft.reminders : '',
          ft.ai_assistant != null ? ft.ai_assistant : '',
          ft.analytics != null ? ft.analytics : '',
          ft.pdf != null ? ft.pdf : '',
          ft.whatsapp != null ? ft.whatsapp : '',
          `"${(sug.favFeature || '').replace(/"/g, '""')}"`,
          `"${(sug.improvements || '').replace(/"/g, '""')}"`,
          `"${(sug.futureWishes || '').replace(/"/g, '""')}"`,
          (item.hasBug || item.bugReport) ? 'YES' : 'NO'
        ];
        lines.push(row.join(','));
      });

      const csvContent = '﻿' + lines.join('\n');
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Receipto_Beta_Feedback_${new Date().toISOString().split('T')[0]}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    }

    // Export JSON
    function exportToJson() {
      if (!feedbackRecords || feedbackRecords.length === 0) {
        alert('No feedback responses available to export.');
        return;
      }

      const jsonStr = JSON.stringify(feedbackRecords, null, 2);
      const blob = new Blob([jsonStr], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Receipto_Beta_Feedback_${new Date().toISOString().split('T')[0]}.json`;
      a.click();
      URL.revokeObjectURL(url);
    }

    function escapeHtml(str) {
      if (!str) return '';
      return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }

    // Canvas Background Particles
    const canvas = document.getElementById('neuralCanvas');
    const ctx = canvas.getContext('2d');
    let particles = [];
    const isMobile = window.innerWidth <= 768;
    const particleCount = isMobile ? 22 : 50;

    let lastW = window.innerWidth;
    function resizeCanvas() {
      if (Math.abs(window.innerWidth - lastW) < 50 && canvas.width > 0) return;
      lastW = window.innerWidth;
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    }

    function initParticles() {
      particles = [];
      for (let i = 0; i < particleCount; i++) {
        particles.push({
          x: Math.random() * canvas.width,
          y: Math.random() * canvas.height,
          vx: (Math.random() - 0.5) * 0.4,
          vy: (Math.random() - 0.5) * 0.4,
          radius: Math.random() * 1.5 + 0.8
        });
      }
    }

    function animate() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = 'rgba(0, 217, 255, 0.5)';
      ctx.strokeStyle = 'rgba(129, 59, 255, 0.12)';

      for (let i = 0; i < particles.length; i++) {
        const p = particles[i];
        p.x += p.vx;
        p.y += p.vy;

        if (p.x < 0) p.x = canvas.width;
        if (p.x > canvas.width) p.x = 0;
        if (p.y < 0) p.y = canvas.height;
        if (p.y > canvas.height) p.y = 0;

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fill();

        for (let j = i + 1; j < particles.length; j++) {
          const p2 = particles[j];
          const dist = Math.hypot(p.x - p2.x, p.y - p2.y);
          if (dist < 100) {
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.stroke();
          }
        }
      }
      requestAnimationFrame(animate);
    }

    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();
    animate();

    // Check auth on startup
    checkAuth();
  