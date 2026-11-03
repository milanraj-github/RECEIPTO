# -*- coding: utf-8 -*-
import sys, re

sys.stdout.reconfigure(encoding='utf-8')

with open('docs/feedback.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Ensure feedbackRecords is initialized with INITIAL_RECORDS
old_init = """    let feedbackRecords = [];
    const savedLocal = localStorage.getItem('receipto_feedbacks');
    if (savedLocal) {
      try { feedbackRecords = JSON.parse(savedLocal); } catch(e) {}
    }"""

new_init = """    let feedbackRecords = [...INITIAL_RECORDS];
    try {
      const savedLocal = localStorage.getItem('receipto_feedbacks');
      if (savedLocal) {
        const parsed = JSON.parse(savedLocal);
        if (Array.isArray(parsed) && parsed.length > 0) {
          feedbackRecords = parsed;
        }
      }
    } catch(e) {}"""

html = html.replace(old_init, new_init)

# 2. In loadCloudFeedbacks, merge cloudRecords with INITIAL_RECORDS so the wall is never empty
old_load = """            feedbackRecords = data.map(row => {
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
      if (!feedbackRecords || feedbackRecords.length === 0) {
        feedbackRecords = [...INITIAL_RECORDS];
      }
      renderCommunityFeed();
      renderAdminResponses();
    }
    loadCloudFeedbacks();"""

new_load = """            const cloudRecords = data.map(row => {
              let parsed = null;
              try {
                if (row.message && typeof row.message === 'string' && row.message.trim().startsWith('{')) {
                  parsed = JSON.parse(row.message);
                }
              } catch(e) {}

              const ft = (parsed && parsed.features) ? parsed.features : (row.features || {});
              const sug = (parsed && parsed.suggestions) ? parsed.suggestions : {
                favFeature: (parsed && parsed.favFeature) || (row.message && !row.message.startsWith('{') ? row.message : ''),
                impressedFeature: (parsed && parsed.impressedFeature) || '',
                improvements: (parsed && parsed.improvements) || '',
                futureWishes: (parsed && parsed.futureWishes) || '',
                devMessage: (parsed && parsed.devMessage) || ''
              };

              return {
                id: row.id,
                name: row.name || 'Anonymous Tester',
                email: row.email || '',
                device: row.device || 'Android Device',
                rating: parseInt(row.rating) || 5,
                message: (parsed && parsed.message) ? parsed.message : (row.message || ''),
                features: ft,
                suggestions: sug,
                finalEvaluation: (parsed && parsed.finalEvaluation) || {
                  overallSatisfaction: parseInt(row.rating) || 5,
                  continueUsing: 'Definitely Yes',
                  devMessage: sug.devMessage || ''
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

            // Merge cloud records and INITIAL_RECORDS
            const seenIds = new Set(cloudRecords.map(r => r.id));
            const merged = [...cloudRecords];
            INITIAL_RECORDS.forEach(init => {
              if (!seenIds.has(init.id)) merged.push(init);
            });

            feedbackRecords = merged;
            localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
          }
        } catch(e) {
          console.log('Cloud feedback sync note:', e);
        }
      }
      if (!feedbackRecords || feedbackRecords.length === 0) {
        feedbackRecords = [...INITIAL_RECORDS];
      }
      renderCommunityFeed();
      renderAdminResponses();
    }
    // Initial immediate synchronous render so cards appear instantly!
    renderCommunityFeed();
    loadCloudFeedbacks();"""

html = html.replace(old_load, new_load)

# 3. Ensure header link is "/admin"
html = re.sub(r'href="[^"]*admin[^"]*"', 'href="/admin"', html)

with open('docs/feedback.html', 'w', encoding='utf-8') as f:
    f.write(html)

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Updated docs/feedback.html and docs/index.html with instant synchronous render & merged cloud feedbacks!")
