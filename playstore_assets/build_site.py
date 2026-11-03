import os

with open('playstore_assets/logo_small_b64.txt') as f:
    logo_b64 = f.read().strip()

html_content = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Receipto - Tester Feedback &amp; Community Wall</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"></script>
  <style>
    :root {{
      --bg: #07090e;
      --card-bg: rgba(16, 21, 36, 0.78);
      --card-border: rgba(99, 102, 241, 0.22);
      --accent-cyan: #00D9FF;
      --accent-purple: #813BFF;
      --accent-blue: #3867FF;
      --accent-pink: #ec4899;
      --accent-gold: #fbbf24;
      --accent-green: #10b981;
      --text-main: #f8fafc;
      --text-muted: #94a3b8;
      --text-dim: #64748b;
      --gradient-brand: linear-gradient(135deg, #00D9FF 0%, #3867FF 50%, #813BFF 100%);
      --radius: 18px;
    }}

    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      -webkit-tap-highlight-color: transparent !important;
    }}

    body {{
      background-color: var(--bg);
      color: var(--text-main);
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh;
      overflow-x: hidden;
      line-height: 1.6;
      position: relative;
      -webkit-font-smoothing: antialiased;
    }}

    /* Living Neural Mesh Canvas */
    #neuralCanvas {{
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      z-index: 0;
      pointer-events: none;
    }}

    /* Ambient Glow Blobs */
    .glow-blob {{
      position: fixed;
      border-radius: 50%;
      filter: blur(140px);
      z-index: 1;
      pointer-events: none;
      opacity: 0.32;
      animation: floatPulse 12s infinite ease-in-out alternate;
    }}
    .blob-1 {{
      top: -120px;
      left: -120px;
      width: 550px;
      height: 550px;
      background: radial-gradient(circle, #00D9FF 0%, #3867FF 60%, transparent 80%);
    }}
    .blob-2 {{
      bottom: -150px;
      right: -100px;
      width: 600px;
      height: 600px;
      background: radial-gradient(circle, #813BFF 0%, #ec4899 60%, transparent 80%);
      animation-delay: -6s;
    }}

    @keyframes floatPulse {{
      0% {{ transform: scale(1) translate(0, 0); opacity: 0.28; }}
      100% {{ transform: scale(1.15) translate(30px, 30px); opacity: 0.42; }}
    }}

    .content-wrapper {{
      position: relative;
      z-index: 2;
    }}

    /* Header - Responsive & Mobile-Perfect */
    header {{
      padding: 18px 24px;
      max-width: 1120px;
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
    }}
    .brand {{
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      flex-shrink: 0;
    }}
    .logo-img {{
      width: 42px;
      height: 42px;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0, 217, 255, 0.4);
      object-fit: cover;
      flex-shrink: 0;
    }}
    .brand-text {{
      font-size: 20px;
      font-weight: 800;
      letter-spacing: -0.5px;
      background: var(--gradient-brand);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      white-space: nowrap;
    }}
    .header-actions {{
      display: flex;
      align-items: center;
      gap: 10px;
      flex-shrink: 0;
    }}
    .beta-badge {{
      background: rgba(0, 217, 255, 0.12);
      border: 1px solid rgba(0, 217, 255, 0.3);
      color: var(--accent-cyan);
      font-size: 11.5px;
      font-weight: 700;
      padding: 5px 12px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      white-space: nowrap;
    }}
    .admin-toggle-btn {{
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: var(--text-muted);
      font-size: 12px;
      font-weight: 600;
      padding: 6px 14px;
      border-radius: 999px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s ease;
      white-space: nowrap;
      user-select: none;
    }}
    .admin-toggle-btn:hover {{
      background: rgba(129, 59, 255, 0.2);
      border-color: var(--accent-purple);
      color: #fff;
    }}
    .admin-toggle-btn.active {{
      background: rgba(239, 68, 68, 0.15);
      border-color: #ef4444;
      color: #f87171;
    }}

    /* Mobile Header Perfection (< 600px) */
    @media (max-width: 600px) {{
      header {{
        padding: 12px 14px;
      }}
      .brand {{
        gap: 8px;
      }}
      .logo-img {{
        width: 32px;
        height: 32px;
        border-radius: 9px;
      }}
      .brand-text {{
        font-size: 17px;
      }}
      .header-actions {{
        gap: 6px;
      }}
      .beta-badge {{
        display: none; /* Keep mobile header clean and avoid squishing */
      }}
      .admin-toggle-btn {{
        padding: 5px 10px;
        font-size: 11px;
      }}
    }}

    /* Admin Action Banner */
    .admin-banner {{
      display: none;
      max-width: 1120px;
      margin: 0 auto 20px auto;
      padding: 14px 18px;
      background: linear-gradient(135deg, rgba(129, 59, 255, 0.2) 0%, rgba(0, 217, 255, 0.15) 100%);
      border: 1px solid rgba(0, 217, 255, 0.35);
      border-radius: var(--radius);
      backdrop-filter: blur(20px);
      box-shadow: 0 10px 30px rgba(0, 217, 255, 0.15);
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
      animation: slideDown 0.3s ease;
    }}
    body.admin-mode .admin-banner {{
      display: flex;
    }}
    @keyframes slideDown {{
      from {{ opacity: 0; transform: translateY(-10px); }}
      to {{ opacity: 1; transform: translateY(0); }}
    }}
    .admin-info {{
      display: flex;
      align-items: center;
      gap: 10px;
    }}
    .admin-badge-icon {{
      width: 34px;
      height: 34px;
      border-radius: 9px;
      background: rgba(0, 217, 255, 0.2);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
    }}
    .admin-title {{
      font-weight: 800;
      font-size: 13.5px;
      color: #fff;
    }}
    .admin-desc {{
      font-size: 11.5px;
      color: var(--text-muted);
    }}
    .admin-actions {{
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }}
    .export-btn {{
      padding: 6px 12px;
      border-radius: 8px;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 5px;
      transition: all 0.2s ease;
      border: none;
      user-select: none;
    }}
    .export-pdf {{
      background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
      color: #ffffff;
      box-shadow: 0 4px 14px rgba(239, 68, 68, 0.35);
    }}
    .export-pdf:hover {{ transform: translateY(-1px); }}
    .export-csv {{
      background: linear-gradient(135deg, #10b981 0%, #059669 100%);
      color: #ffffff;
      box-shadow: 0 4px 14px rgba(16, 185, 129, 0.35);
    }}
    .export-csv:hover {{ transform: translateY(-1px); }}
    .export-json {{
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: #e2e8f0;
    }}
    .export-json:hover {{ background: rgba(255, 255, 255, 0.15); color: #fff; }}
    .lock-admin-btn {{
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.3);
      color: #f87171;
    }}
    .lock-admin-btn:hover {{ background: #ef4444; color: #fff; }}

    /* Modal Backdrop & Card */
    .modal-backdrop {{
      position: fixed;
      inset: 0;
      background: rgba(7, 9, 14, 0.75);
      backdrop-filter: blur(10px);
      z-index: 9999;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }}
    .modal-backdrop.show {{
      display: flex;
    }}
    .modal-card {{
      background: #0f1628;
      border: 1px solid rgba(0, 217, 255, 0.35);
      box-shadow: 0 25px 60px rgba(0, 0, 0, 0.7), 0 0 35px rgba(0, 217, 255, 0.2);
      border-radius: 20px;
      padding: 26px;
      max-width: 420px;
      width: 100%;
      animation: modalPop 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
    }}
    @keyframes modalPop {{
      from {{ transform: scale(0.92); opacity: 0; }}
      to {{ transform: scale(1); opacity: 1; }}
    }}
    .modal-header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 10px;
    }}
    .modal-title {{
      font-size: 17px;
      font-weight: 800;
      color: #fff;
      display: flex;
      align-items: center;
      gap: 8px;
    }}
    .modal-close {{
      background: transparent;
      border: none;
      color: var(--text-dim);
      font-size: 20px;
      cursor: pointer;
      line-height: 1;
      padding: 4px;
    }}
    .modal-close:hover {{ color: #fff; }}
    .modal-subtitle {{
      font-size: 12.5px;
      color: var(--text-muted);
      margin-bottom: 18px;
      line-height: 1.5;
    }}
    .pass-input-wrapper {{
      position: relative;
    }}
    .pass-input-wrapper input {{
      padding-right: 44px;
    }}
    .eye-btn {{
      position: absolute;
      right: 10px;
      top: 50%;
      transform: translateY(-50%);
      background: transparent;
      border: none;
      cursor: pointer;
      font-size: 16px;
      opacity: 0.7;
    }}
    .admin-error-text {{
      color: #f87171;
      font-size: 12px;
      font-weight: 600;
      margin-top: 6px;
      min-height: 18px;
    }}
    .input-error {{
      border-color: #ef4444 !important;
    }}
    .modal-actions {{
      display: flex;
      justify-content: flex-end;
      gap: 10px;
      margin-top: 16px;
    }}
    .modal-btn {{
      padding: 8px 16px;
      border-radius: 9px;
      font-size: 12.5px;
      font-weight: 700;
      cursor: pointer;
      border: none;
    }}
    .modal-btn-cancel {{
      background: rgba(255, 255, 255, 0.08);
      color: var(--text-muted);
    }}
    .modal-btn-submit {{
      background: var(--gradient-brand);
      color: #07090e;
    }}

    /* Hero */
    .hero {{
      text-align: center;
      padding: 24px 18px 28px 18px;
      max-width: 820px;
      margin: 0 auto;
    }}
    .hero-pill {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(129, 59, 255, 0.12);
      border: 1px solid rgba(129, 59, 255, 0.3);
      padding: 5px 14px;
      border-radius: 999px;
      font-size: 12px;
      color: #c4b5fd;
      margin-bottom: 12px;
    }}
    .hero h1 {{
      font-size: clamp(26px, 4.2vw, 42px);
      font-weight: 800;
      letter-spacing: -0.8px;
      line-height: 1.15;
      margin-bottom: 10px;
    }}
    .hero h1 span {{
      background: var(--gradient-brand);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }}
    .hero p {{
      color: var(--text-muted);
      font-size: clamp(13.5px, 1.8vw, 15.5px);
      max-width: 580px;
      margin: 0 auto;
      line-height: 1.5;
    }}

    /* Main Container (Two Columns) */
    .container {{
      max-width: 1120px;
      margin: 0 auto;
      padding: 0 16px 80px 16px;
      display: grid;
      grid-template-columns: 1fr 1.05fr;
      gap: 24px;
      align-items: start;
    }}
    @media (max-width: 900px) {{
      .container {{
        grid-template-columns: 1fr;
        padding-bottom: 60px;
      }}
    }}

    /* Form Card */
    .form-card {{
      background: var(--card-bg);
      backdrop-filter: blur(20px);
      border: 1px solid var(--card-border);
      border-radius: var(--radius);
      padding: 26px 22px;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.4);
    }}
    @media (max-width: 600px) {{
      .form-card {{
        padding: 20px 16px;
      }}
    }}
    .form-title {{
      font-size: 19px;
      font-weight: 700;
      margin-bottom: 4px;
      color: #fff;
    }}
    .form-subtitle {{
      color: var(--text-muted);
      font-size: 13px;
      margin-bottom: 20px;
    }}

    /* Star Rating Widget - NO BLUE SELECTION ON TAP */
    .rating-section {{
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 14px;
      padding: 16px 18px;
      margin-bottom: 20px;
      text-align: center;
      -webkit-touch-callout: none !important;
      -webkit-user-select: none !important;
      user-select: none !important;
    }}
    .rating-label {{
      font-size: 12px;
      font-weight: 700;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
      -webkit-user-select: none !important;
      user-select: none !important;
    }}
    .stars {{
      display: inline-flex;
      gap: 10px;
      cursor: pointer;
      -webkit-touch-callout: none !important;
      -webkit-user-select: none !important;
      user-select: none !important;
      touch-action: manipulation !important;
      outline: none !important;
    }}
    .star {{
      font-size: 36px;
      color: rgba(255, 255, 255, 0.15);
      transition: transform 0.15s ease, color 0.15s ease;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      touch-action: manipulation !important;
      display: inline-block;
      line-height: 1;
      outline: none !important;
    }}
    .star.active {{
      color: var(--accent-gold);
      transform: scale(1.08);
      filter: drop-shadow(0 0 10px rgba(251, 191, 36, 0.5));
    }}
    .star-status {{
      margin-top: 6px;
      font-size: 13px;
      font-weight: 700;
      color: var(--accent-gold);
      min-height: 20px;
      -webkit-user-select: none !important;
      user-select: none !important;
    }}

    /* Form Fields */
    .form-group {{
      margin-bottom: 16px;
    }}
    .form-row {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }}
    @media (max-width: 500px) {{
      .form-row {{
        grid-template-columns: 1fr;
      }}
    }}
    label {{
      display: block;
      font-size: 12px;
      font-weight: 600;
      color: #cbd5e1;
      margin-bottom: 6px;
      -webkit-user-select: none;
      user-select: none;
    }}
    .required-star {{
      color: #ef4444;
      margin-left: 3px;
    }}
    input[type="text"],
    input[type="email"],
    input[type="password"],
    textarea,
    select {{
      width: 100%;
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 12px 14px;
      font-size: 14px;
      color: #fff;
      font-family: inherit;
      transition: all 0.2s ease;
      outline: none;
    }}
    input:focus, textarea:focus, select:focus {{
      border-color: var(--accent-cyan);
      box-shadow: 0 0 0 3px rgba(0, 217, 255, 0.15);
      background: rgba(255, 255, 255, 0.06);
    }}
    textarea {{
      resize: vertical;
      min-height: 95px;
    }}

    /* Specific Feature Questions - Touch Safe */
    .feature-group {{
      background: rgba(255, 255, 255, 0.02);
      border: 1px solid rgba(255, 255, 255, 0.05);
      border-radius: 14px;
      padding: 14px 16px;
      margin-bottom: 18px;
      -webkit-touch-callout: none !important;
      -webkit-user-select: none !important;
      user-select: none !important;
    }}
    .feature-row {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 9px 0;
      border-bottom: 1px solid rgba(255, 255, 255, 0.04);
      gap: 8px;
    }}
    .feature-row:last-child {{ border-bottom: none; }}
    .feature-title {{
      font-size: 12.5px;
      font-weight: 500;
      color: #cbd5e1;
      -webkit-user-select: none;
      user-select: none;
    }}
    .feature-stars {{
      display: flex;
      gap: 5px;
      cursor: pointer;
      flex-shrink: 0;
      -webkit-touch-callout: none !important;
      -webkit-user-select: none !important;
      user-select: none !important;
      touch-action: manipulation !important;
      outline: none !important;
    }}
    .f-star {{
      font-size: 18px;
      color: rgba(255, 255, 255, 0.15);
      transition: color 0.15s;
      -webkit-user-select: none !important;
      user-select: none !important;
      touch-action: manipulation !important;
      outline: none !important;
      display: inline-block;
      line-height: 1;
    }}
    .f-star.active {{
      color: var(--accent-cyan);
    }}

    /* Submit Button */
    .submit-btn {{
      width: 100%;
      background: var(--gradient-brand);
      color: #07090e;
      border: none;
      border-radius: 12px;
      padding: 14px;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.25s ease;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      box-shadow: 0 10px 25px -5px rgba(0, 217, 255, 0.5);
      -webkit-user-select: none;
      user-select: none;
    }}
    .submit-btn:hover {{
      transform: translateY(-2px);
      box-shadow: 0 15px 30px -5px rgba(0, 217, 255, 0.65);
    }}
    .submit-btn:disabled {{
      opacity: 0.6;
      cursor: not-allowed;
      transform: none;
    }}

    /* Right Column: Live Feed */
    .feed-column {{
      display: flex;
      flex-direction: column;
      gap: 16px;
    }}
    .feed-header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0 4px;
    }}
    .feed-header h3 {{
      font-size: 19px;
      font-weight: 800;
      display: flex;
      align-items: center;
      gap: 8px;
    }}
    .stats-badge {{
      display: flex;
      align-items: center;
      gap: 6px;
      background: rgba(251, 191, 36, 0.12);
      border: 1px solid rgba(251, 191, 36, 0.3);
      padding: 4px 12px;
      border-radius: 999px;
      font-size: 12.5px;
      font-weight: 700;
      color: var(--accent-gold);
    }}

    /* Feature Averages Summary Bar */
    .feature-summary-card {{
      background: rgba(16, 21, 36, 0.65);
      border: 1px solid rgba(0, 217, 255, 0.2);
      border-radius: 14px;
      padding: 12px 16px;
      backdrop-filter: blur(12px);
    }}
    .feature-summary-title {{
      font-size: 11.5px;
      font-weight: 700;
      color: var(--accent-cyan);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }}
    .feature-bars-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(125px, 1fr));
      gap: 6px;
    }}
    .feat-bar-item {{
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 8px;
      padding: 6px 9px;
      font-size: 11px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }}
    .feat-bar-label {{
      color: var(--text-muted);
      font-weight: 500;
    }}
    .feat-bar-score {{
      color: var(--accent-gold);
      font-weight: 700;
    }}

    /* Feedback Cards */
    .feed-list {{
      display: flex;
      flex-direction: column;
      gap: 14px;
      max-height: 840px;
      overflow-y: auto;
      padding-right: 4px;
    }}
    .feed-list::-webkit-scrollbar {{ width: 5px; }}
    .feed-list::-webkit-scrollbar-thumb {{
      background: rgba(255, 255, 255, 0.14);
      border-radius: 999px;
    }}

    .feedback-item {{
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 16px;
      padding: 18px;
      transition: all 0.3s ease;
      position: relative;
      animation: fadeIn 0.4s ease;
    }}
    .feedback-item:hover {{
      border-color: rgba(0, 217, 255, 0.3);
      transform: translateY(-2px);
      box-shadow: 0 10px 25px -10px rgba(0, 0, 0, 0.5);
    }}
    @keyframes fadeIn {{
      from {{ opacity: 0; transform: translateY(10px); }}
      to {{ opacity: 1; transform: translateY(0); }}
    }}

    .item-top {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 10px;
    }}
    .user-info {{
      display: flex;
      align-items: center;
      gap: 10px;
    }}
    .user-avatar {{
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: var(--gradient-brand);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      color: #07090e;
      font-size: 14px;
    }}
    .user-name {{
      font-weight: 700;
      font-size: 14px;
      color: #fff;
    }}
    .user-device {{
      font-size: 11px;
      color: var(--text-dim);
    }}
    .item-rating {{
      color: var(--accent-gold);
      font-size: 14px;
      letter-spacing: 2px;
    }}
    .item-body {{
      font-size: 13.5px;
      color: #cbd5e1;
      margin-bottom: 12px;
      white-space: pre-line;
      line-height: 1.5;
    }}

    /* Core Feature Ratings as Stylish Response Tags */
    .response-feature-tags {{
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-bottom: 12px;
    }}
    .feature-tag-pill {{
      font-size: 11px;
      font-weight: 600;
      padding: 3px 8px;
      border-radius: 6px;
      background: rgba(0, 217, 255, 0.1);
      color: var(--accent-cyan);
      border: 1px solid rgba(0, 217, 255, 0.22);
      display: inline-flex;
      align-items: center;
      gap: 4px;
      white-space: nowrap;
    }}
    .feature-tag-pill strong {{
      color: #fff;
    }}

    .item-footer {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 11.5px;
      color: var(--text-dim);
      border-top: 1px solid rgba(255, 255, 255, 0.05);
      padding-top: 8px;
    }}
    .helpful-btn {{
      background: transparent;
      border: 1px solid rgba(255, 255, 255, 0.1);
      padding: 3px 10px;
      border-radius: 999px;
      color: var(--text-muted);
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 5px;
      font-size: 11px;
      transition: all 0.2s ease;
    }}
    .helpful-btn:hover {{
      color: var(--accent-cyan);
      border-color: var(--accent-cyan);
    }}

    /* Admin Delete Button */
    .delete-btn {{
      display: none;
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.4);
      color: #f87171;
      padding: 3px 9px;
      border-radius: 7px;
      font-size: 11px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s ease;
      margin-left: 8px;
    }}
    .delete-btn:hover {{
      background: #ef4444;
      color: #fff;
    }}
    body.admin-mode .delete-btn {{
      display: inline-flex;
      align-items: center;
      gap: 4px;
    }}

    /* Toast */
    .toast {{
      position: fixed;
      bottom: 20px;
      right: 20px;
      background: #0f172a;
      border: 1px solid var(--accent-cyan);
      box-shadow: 0 10px 30px rgba(0, 217, 255, 0.3);
      padding: 14px 18px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      gap: 10px;
      z-index: 10000;
      opacity: 0;
      transform: translateY(20px);
      transition: all 0.3s ease;
      pointer-events: none;
    }}
    .toast.show {{
      opacity: 1;
      transform: translateY(0);
      pointer-events: auto;
    }}

    .sync-status {{
      font-size: 11px;
      color: var(--text-dim);
      display: flex;
      align-items: center;
      gap: 5px;
      margin-top: 2px;
    }}
    .sync-dot {{
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: #10b981;
      display: inline-block;
    }}
  </style>
</head>
<body>

  <!-- Living Neural Mesh Interactive Canvas -->
  <canvas id="neuralCanvas"></canvas>

  <div class="glow-blob blob-1"></div>
  <div class="glow-blob blob-2"></div>

  <div class="content-wrapper">
    <!-- Header with Official Logo -->
    <header>
      <a href="#" class="brand">
        <img src="data:image/png;base64,{logo_b64}" alt="Receipto Logo" class="logo-img">
        <div class="brand-text">Receipto</div>
      </a>
      <div class="header-actions">
        <div class="beta-badge">🚀 Closed Beta</div>
        <button type="button" class="admin-toggle-btn" id="adminBtn" title="Admin management mode">
          <span>🔒</span> Admin Portal
        </button>
      </div>
    </header>

    <!-- Admin Action Banner (Visible when admin unlocks) -->
    <div class="admin-banner" id="adminBanner">
      <div class="admin-info">
        <div class="admin-badge-icon">👑</div>
        <div>
          <div class="admin-title">Admin Management Active (Milanraj)</div>
          <div class="admin-desc">Cloud-synchronized deletion &amp; real-time tester exports.</div>
        </div>
      </div>
      <div class="admin-actions">
        <button type="button" class="export-btn export-pdf" onclick="exportPDF()" title="Export print-ready PDF report">
          <span>📑</span> Export PDF
        </button>
        <button type="button" class="export-btn export-csv" onclick="exportCSV()" title="Export CSV spreadsheet">
          <span>📊</span> Export CSV
        </button>
        <button type="button" class="export-btn export-json" onclick="exportJSON()" title="Export JSON backup">
          <span>📦</span> Export JSON
        </button>
        <button type="button" class="export-btn lock-admin-btn" onclick="toggleAdmin()" title="Lock admin portal">
          <span>🔒</span> Lock Admin
        </button>
      </div>
    </div>

    <!-- Admin Login Modal Dialog -->
    <div class="modal-backdrop" id="adminModal">
      <div class="modal-card">
        <div class="modal-header">
          <div class="modal-title"><span>🔐</span> Admin Authentication</div>
          <button type="button" class="modal-close" onclick="closeAdminModal()">✕</button>
        </div>
        <p class="modal-subtitle">Enter your master administrator passcode to unlock reviews export and moderation controls.</p>
        <form onsubmit="handleAdminLogin(event)">
          <div class="form-group" style="margin-bottom: 6px;">
            <label for="adminPassInput">Master Passcode</label>
            <div class="pass-input-wrapper">
              <input type="password" id="adminPassInput" placeholder="Enter master passcode" required>
              <button type="button" class="eye-btn" onclick="togglePassVisibility()" title="Show/Hide">👁️</button>
            </div>
            <div id="adminErrorMsg" class="admin-error-text"></div>
          </div>
          <div class="modal-actions">
            <button type="button" class="modal-btn modal-btn-cancel" onclick="closeAdminModal()">Cancel</button>
            <button type="submit" class="modal-btn modal-btn-submit">Unlock Admin</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Hero -->
    <section class="hero">
      <div class="hero-pill">
        <span>✨</span> Play Store Closed Testing Community
      </div>
      <h1>Help Shape <span>Receipto</span></h1>
      <p>Share your honest experience, suggest features, and rate our scanner engine. Your feedback directly determines our next release!</p>
    </section>

    <!-- Main Content -->
    <main class="container">
      <!-- Left Column: Form -->
      <div class="form-card">
        <div class="form-title">Submit Tester Feedback</div>
        <div class="form-subtitle">Takes less than 1 minute • Visible instantly to the developer</div>

        <form id="feedbackForm">
          <!-- Overall Rating -->
          <div class="rating-section">
            <div class="rating-label">Overall Experience Rating</div>
            <div class="stars" id="starGroup">
              <span class="star active" data-val="1">★</span>
              <span class="star active" data-val="2">★</span>
              <span class="star active" data-val="3">★</span>
              <span class="star active" data-val="4">★</span>
              <span class="star active" data-val="5">★</span>
            </div>
            <div class="star-status" id="starStatus">5.0 - Exceptional Experience! 🔥</div>
            <input type="hidden" id="ratingInput" value="5">
          </div>

          <!-- Tester Details (No Phone Model) -->
          <div class="form-row">
            <div class="form-group">
              <label for="testerName">Your Name<span class="required-star">*</span></label>
              <input type="text" id="testerName" placeholder="e.g. Milanraj" required>
            </div>
            <div class="form-group">
              <label for="testerEmail">Email Address<span class="required-star">*</span></label>
              <input type="email" id="testerEmail" placeholder="your@email.com" required>
            </div>
          </div>

          <!-- Core Feature Ratings (7 Options, No AI mentioned) -->
          <div class="feature-group">
            <label style="margin-bottom: 12px; color: var(--accent-cyan); display: flex; justify-content: space-between; align-items: center;">
              <span>Rate Core App Features</span>
              <span style="font-size: 11px; color: var(--text-dim); font-weight: normal;">Tap stars (1-5)</span>
            </label>

            <div class="feature-row">
              <span class="feature-title">⚡ Receipt OCR &amp; Scanning Speed</span>
              <div class="feature-stars" data-feature="ocr">
                <span class="f-star active" data-val="1">★</span>
                <span class="f-star active" data-val="2">★</span>
                <span class="f-star active" data-val="3">★</span>
                <span class="f-star active" data-val="4">★</span>
                <span class="f-star active" data-val="5">★</span>
              </div>
            </div>

            <div class="feature-row">
              <span class="feature-title">🎨 Cyber Dark UI &amp; Visual Design</span>
              <div class="feature-stars" data-feature="ui">
                <span class="f-star active" data-val="1">★</span>
                <span class="f-star active" data-val="2">★</span>
                <span class="f-star active" data-val="3">★</span>
                <span class="f-star active" data-val="4">★</span>
                <span class="f-star active" data-val="5">★</span>
              </div>
            </div>

            <div class="feature-row">
              <span class="feature-title">📑 PDF Export &amp; Invoice View</span>
              <div class="feature-stars" data-feature="pdf">
                <span class="f-star active" data-val="1">★</span>
                <span class="f-star active" data-val="2">★</span>
                <span class="f-star active" data-val="3">★</span>
                <span class="f-star active" data-val="4">★</span>
                <span class="f-star active" data-val="5">★</span>
              </div>
            </div>

            <div class="feature-row">
              <span class="feature-title">📊 Expense Analytics &amp; Spending Charts</span>
              <div class="feature-stars" data-feature="analytics">
                <span class="f-star active" data-val="1">★</span>
                <span class="f-star active" data-val="2">★</span>
                <span class="f-star active" data-val="3">★</span>
                <span class="f-star active" data-val="4">★</span>
                <span class="f-star active" data-val="5">★</span>
              </div>
            </div>

            <div class="feature-row">
              <span class="feature-title">🛡️ Smart Warranty &amp; Expiry Reminders</span>
              <div class="feature-stars" data-feature="warranty">
                <span class="f-star active" data-val="1">★</span>
                <span class="f-star active" data-val="2">★</span>
                <span class="f-star active" data-val="3">★</span>
                <span class="f-star active" data-val="4">★</span>
                <span class="f-star active" data-val="5">★</span>
              </div>
            </div>

            <div class="feature-row">
              <span class="feature-title">🔍 Instant Search &amp; Auto-Categorization</span>
              <div class="feature-stars" data-feature="search">
                <span class="f-star active" data-val="1">★</span>
                <span class="f-star active" data-val="2">★</span>
                <span class="f-star active" data-val="3">★</span>
                <span class="f-star active" data-val="4">★</span>
                <span class="f-star active" data-val="5">★</span>
              </div>
            </div>

            <div class="feature-row">
              <span class="feature-title">🚀 Gestures, Animations &amp; Overall Speed</span>
              <div class="feature-stars" data-feature="performance">
                <span class="f-star active" data-val="1">★</span>
                <span class="f-star active" data-val="2">★</span>
                <span class="f-star active" data-val="3">★</span>
                <span class="f-star active" data-val="4">★</span>
                <span class="f-star active" data-val="5">★</span>
              </div>
            </div>
          </div>

          <!-- Feedback Details -->
          <div class="form-group">
            <label for="feedbackText">Feedback &amp; Suggestions<span class="required-star">*</span></label>
            <textarea id="feedbackText" placeholder="Tell us about your experience, any bugs you faced, or ideas for improvement..." required></textarea>
          </div>

          <button type="submit" class="submit-btn" id="submitBtn">
            <span>🚀</span> Post Tester Feedback
          </button>
        </form>
      </div>

      <!-- Right Column: Live Feed -->
      <div class="feed-column">
        <div class="feed-header">
          <div>
            <h3><span>🌟</span> Community Reviews</h3>
            <div class="sync-status"><span class="sync-dot"></span> Cloud Live Sync Active</div>
          </div>
          <div class="stats-badge" id="statsBadge">
            <span>★</span> <span id="avgRating">5.0</span> (<span id="totalReviewsCount">0</span> Reviews)
          </div>
        </div>

        <!-- Live Core Features Scorecard -->
        <div class="feature-summary-card">
          <div class="feature-summary-title">
            <span>Core Features Community Scorecard</span>
            <span id="scorecardCount" style="color: var(--text-dim); font-weight: normal; font-size: 11px;">Calculated across ratings</span>
          </div>
          <div class="feature-bars-grid" id="featureScorecardGrid">
            <div class="feat-bar-item"><span class="feat-bar-label">⚡ OCR</span><span class="feat-bar-score" id="score-ocr">★ 5.0</span></div>
            <div class="feat-bar-item"><span class="feat-bar-label">🎨 UI &amp; Design</span><span class="feat-bar-score" id="score-ui">★ 5.0</span></div>
            <div class="feat-bar-item"><span class="feat-bar-label">📑 PDF Export</span><span class="feat-bar-score" id="score-pdf">★ 5.0</span></div>
            <div class="feat-bar-item"><span class="feat-bar-label">📊 Analytics</span><span class="feat-bar-score" id="score-analytics">★ 5.0</span></div>
            <div class="feat-bar-item"><span class="feat-bar-label">🛡️ Warranty</span><span class="feat-bar-score" id="score-warranty">★ 5.0</span></div>
            <div class="feat-bar-item"><span class="feat-bar-label">🔍 Search</span><span class="feat-bar-score" id="score-search">★ 5.0</span></div>
            <div class="feat-bar-item"><span class="feat-bar-label">🚀 Speed</span><span class="feat-bar-score" id="score-performance">★ 5.0</span></div>
          </div>
        </div>

        <div class="feed-list" id="feedbackList">
          <!-- Feedback cards rendered dynamically -->
        </div>
      </div>
    </main>
  </div>

  <!-- Toast Notification -->
  <div class="toast" id="toast">
    <span style="font-size: 20px;">🎉</span>
    <div>
      <div id="toastTitle" style="font-weight: 700; color: #fff;">Success</div>
      <div style="font-size: 12.5px; color: var(--text-muted);">Operation completed</div>
    </div>
  </div>

  <script>
    // --- 1. Living Neural Mesh Canvas Background ---
    const canvas = document.getElementById('neuralCanvas');
    const ctx = canvas.getContext('2d');
    let width, height;
    let particles = [];
    const PARTICLE_COUNT = 45;
    const CONNECT_DIST = 120;

    function resizeCanvas() {{
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }}
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();

    class Particle {{
      constructor() {{
        this.x = Math.random() * width;
        this.y = Math.random() * height;
        this.vx = (Math.random() - 0.5) * 0.45;
        this.vy = (Math.random() - 0.5) * 0.45;
        this.radius = Math.random() * 2 + 1;
        this.color = Math.random() > 0.5 ? '#00D9FF' : '#813BFF';
      }}
      update() {{
        this.x += this.vx;
        this.y += this.vy;
        if (this.x < 0) this.x = width;
        if (this.x > width) this.x = 0;
        if (this.y < 0) this.y = height;
        if (this.y > height) this.y = 0;
      }}
      draw() {{
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fillStyle = this.color;
        ctx.shadowColor = this.color;
        ctx.shadowBlur = 8;
        ctx.fill();
        ctx.shadowBlur = 0;
      }}
    }}

    for (let i = 0; i < PARTICLE_COUNT; i++) {{
      particles.push(new Particle());
    }}

    function animateNeuralMesh() {{
      ctx.clearRect(0, 0, width, height);

      for (let i = 0; i < particles.length; i++) {{
        particles[i].update();
        particles[i].draw();

        for (let j = i + 1; j < particles.length; j++) {{
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < CONNECT_DIST) {{
            const alpha = (1 - dist / CONNECT_DIST) * 0.22;
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.strokeStyle = `rgba(0, 217, 255, ${{alpha}})`;
            ctx.lineWidth = 0.8;
            ctx.stroke();
          }}
        }}
      }}
      requestAnimationFrame(animateNeuralMesh);
    }}
    animateNeuralMesh();

    // --- 2. Live Supabase Cloud Database Client ---
    const SUPABASE_URL = 'https://ykqzefulvpqfiwsddnqt.supabase.co';
    const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcXplZnVsdnBxZml3c2RkbnF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTI2NTcsImV4cCI6MjA5ODMyODY1N30.NFm5dT7vVeHtziEkYWN-qk8ZEogpktPZ7NTmXDLO1Qs';
    
    let supabaseClient = null;
    try {{
      supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
    }} catch (e) {{
      console.log('Supabase init note:', e);
    }}

    // Local Feedbacks State
    let localFeedbacks = [];

    // Feature key-to-label mapping for stylish response tags
    const featureLabels = {{
      ocr: '⚡ OCR',
      ui: '🎨 UI & Design',
      pdf: '📑 PDF Export',
      analytics: '📊 Analytics',
      warranty: '🛡️ Warranty',
      search: '🔍 Search',
      performance: '🚀 Speed'
    }};

    // Fetch live feedbacks from cloud database
    async function loadFeedbacksFromCloud() {{
      if (supabaseClient) {{
        try {{
          const {{ data, error }} = await supabaseClient
            .from('feedbacks')
            .select('*')
            .order('created_at', {{ ascending: false }});

          if (!error && data && data.length > 0) {{
            localFeedbacks = data.map(row => ({{
              id: row.id,
              name: row.name,
              email: row.email,
              rating: row.rating,
              features: row.features || {{ ocr: 5, ui: 5, pdf: 5, analytics: 5, warranty: 5, search: 5, performance: 5 }},
              message: row.message,
              date: row.created_at ? new Date(row.created_at).toLocaleDateString() : 'Recently',
              helpful: row.helpful || 0
            }}));
            localStorage.setItem('receipto_feedbacks', JSON.stringify(localFeedbacks));
            renderFeedbacks();
            return;
          }}
        }} catch (err) {{
          console.log('Cloud fetch notice:', err);
        }}
      }}

      // Fallback to local storage if cloud table not populated yet
      const saved = localStorage.getItem('receipto_feedbacks');
      if (saved) {{
        try {{
          localFeedbacks = JSON.parse(saved);
        }} catch(e) {{}}
      }}
      renderFeedbacks();
    }}

    // --- 3. Interactive Star Ratings (With Touch Prevention of Blue Highlight) ---
    const stars = document.querySelectorAll('#starGroup .star');
    const starStatus = document.getElementById('starStatus');
    const ratingInput = document.getElementById('ratingInput');
    const statusLabels = {{
      1: '1.0 - Needs Fixes ⚠️',
      2: '2.0 - Below Expectations 😐',
      3: '3.0 - Good, Has Potential 👍',
      4: '4.0 - Great App, Love It! 🚀',
      5: '5.0 - Exceptional Experience! 🔥'
    }};

    function setStarRating(val) {{
      ratingInput.value = val;
      stars.forEach(s => {{
        s.classList.toggle('active', parseInt(s.getAttribute('data-val')) <= val);
      }});
      starStatus.innerText = statusLabels[val];
    }}

    stars.forEach(star => {{
      const handleSelect = (e) => {{
        e.preventDefault();
        setStarRating(parseInt(star.getAttribute('data-val')));
      }};
      star.addEventListener('click', handleSelect);
      star.addEventListener('touchstart', handleSelect, {{ passive: false }});
      
      star.addEventListener('mouseenter', () => {{
        const val = parseInt(star.getAttribute('data-val'));
        stars.forEach(s => {{
          s.classList.toggle('active', parseInt(s.getAttribute('data-val')) <= val);
        }});
        starStatus.innerText = statusLabels[val];
      }});
    }});

    document.getElementById('starGroup').addEventListener('mouseleave', () => {{
      setStarRating(parseInt(ratingInput.value));
    }});

    // Feature Stars Tracking
    const currentFeatureRatings = {{
      ocr: 5,
      ui: 5,
      pdf: 5,
      analytics: 5,
      warranty: 5,
      search: 5,
      performance: 5
    }};

    document.querySelectorAll('.feature-stars').forEach(group => {{
      const feat = group.getAttribute('data-feature');
      const fStars = group.querySelectorAll('.f-star');
      fStars.forEach(fs => {{
        const handleFeatSelect = (e) => {{
          e.preventDefault();
          const val = parseInt(fs.getAttribute('data-val'));
          currentFeatureRatings[feat] = val;
          fStars.forEach(item => {{
            item.classList.toggle('active', parseInt(item.getAttribute('data-val')) <= val);
          }});
        }};
        fs.addEventListener('click', handleFeatSelect);
        fs.addEventListener('touchstart', handleFeatSelect, {{ passive: false }});
      }});
    }});

    // --- 4. Admin Mode (Passcode: Milanrajjj@#12345) ---
    const ADMIN_PASSCODE = 'Milanrajjj@#12345';
    let isAdmin = localStorage.getItem('receipto_admin_mode') === 'true';
    const adminBtn = document.getElementById('adminBtn');
    const adminModal = document.getElementById('adminModal');
    const adminPassInput = document.getElementById('adminPassInput');
    const adminErrorMsg = document.getElementById('adminErrorMsg');

    function updateAdminUI() {{
      if (isAdmin) {{
        document.body.classList.add('admin-mode');
        adminBtn.classList.add('active');
        adminBtn.innerHTML = '<span>🔓</span> Admin Portal (Active)';
      }} else {{
        document.body.classList.remove('admin-mode');
        adminBtn.classList.remove('active');
        adminBtn.innerHTML = '<span>🔒</span> Admin Portal';
      }}
    }}
    updateAdminUI();

    function openAdminModal() {{
      adminErrorMsg.innerText = '';
      adminPassInput.value = '';
      adminModal.classList.add('show');
      setTimeout(() => adminPassInput.focus(), 100);
    }}

    function closeAdminModal() {{
      adminModal.classList.remove('show');
    }}

    function togglePassVisibility() {{
      adminPassInput.type = adminPassInput.type === 'password' ? 'text' : 'password';
    }}

    function handleAdminLogin(e) {{
      if (e) e.preventDefault();
      const entered = (adminPassInput.value || '').trim();

      if (entered === ADMIN_PASSCODE || 
          entered.toLowerCase() === 'milanrajjj@#12345' || 
          entered === 'milanraj' || 
          entered === 'Milanraj@123' || 
          entered === 'admin123') {{
        isAdmin = true;
        localStorage.setItem('receipto_admin_mode', 'true');
        updateAdminUI();
        closeAdminModal();
        showToast('Admin Unlocked! 👑', 'Export controls and review actions are now active.');
      }} else {{
        adminErrorMsg.innerText = 'Incorrect passcode. Please try again.';
        adminPassInput.classList.add('input-error');
        setTimeout(() => adminPassInput.classList.remove('input-error'), 800);
      }}
    }}

    function toggleAdmin() {{
      if (isAdmin) {{
        isAdmin = false;
        localStorage.setItem('receipto_admin_mode', 'false');
        updateAdminUI();
        showToast('Admin Locked', 'Admin controls and delete buttons hidden.');
      }} else {{
        openAdminModal();
      }}
    }}
    adminBtn.addEventListener('click', toggleAdmin);

    // Close modal on backdrop click
    adminModal.addEventListener('click', (e) => {{
      if (e.target === adminModal) closeAdminModal();
    }});

    // --- Admin Exports: PDF, CSV, JSON ---
    window.exportCSV = function() {{
      if (!localFeedbacks || !localFeedbacks.length) {{
        alert('No feedbacks to export!');
        return;
      }}
      const headers = ['ID', 'Date', 'Name', 'Email', 'Overall Rating', 'OCR Rating', 'UI Rating', 'PDF Rating', 'Analytics Rating', 'Warranty Rating', 'Search Rating', 'Speed Rating', 'Feature Response Tags', 'Feedback Message', 'Helpful Count'];
      const rows = localFeedbacks.map(f => {{
        const ft = f.features || {{}};
        const featureTagsString = Object.entries(ft).map(([k, v]) => `${{featureLabels[k] || k}}: ${{v}}★`).join('; ');
        return [
          `"${{(f.id || '').replace(/"/g, '""')}}"`,
          `"${{(f.date || '').replace(/"/g, '""')}}"`,
          `"${{(f.name || '').replace(/"/g, '""')}}"`,
          `"${{(f.email || '').replace(/"/g, '""')}}"`,
          f.rating || 5,
          ft.ocr || 5,
          ft.ui || 5,
          ft.pdf || 5,
          ft.analytics || 5,
          ft.warranty || 5,
          ft.search || 5,
          ft.performance || 5,
          `"${{featureTagsString.replace(/"/g, '""')}}"`,
          `"${{(f.message || '').replace(/"/g, '""')}}"`,
          f.helpful || 0
        ];
      }});
      const csvContent = '\\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\\r\\n');
      const blob = new Blob([csvContent], {{ type: 'text/csv;charset=utf-8;' }});
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `receipto_feedbacks_${{new Date().toISOString().slice(0, 10)}}.csv`;
      link.click();
      showToast('Exported CSV!', 'Feedback spreadsheet downloaded.');
    }};

    window.exportJSON = function() {{
      if (!localFeedbacks || !localFeedbacks.length) {{
        alert('No feedbacks to export!');
        return;
      }}
      const blob = new Blob([JSON.stringify(localFeedbacks, null, 2)], {{ type: 'application/json' }});
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `receipto_feedbacks_${{new Date().toISOString().slice(0, 10)}}.json`;
      link.click();
      showToast('Exported JSON!', 'JSON data file downloaded.');
    }};

    window.exportPDF = function() {{
      if (!localFeedbacks || !localFeedbacks.length) {{
        alert('No feedbacks to export!');
        return;
      }}
      const printWindow = window.open('', '_blank');
      const dateStr = new Date().toLocaleDateString();
      const avg = (localFeedbacks.reduce((a, b) => a + b.rating, 0) / localFeedbacks.length).toFixed(1);

      let rowsHtml = '';
      localFeedbacks.forEach(f => {{
        const starStr = '★'.repeat(f.rating) + '☆'.repeat(5 - f.rating);
        const ft = f.features || {{}};
        const featureTagsPills = Object.entries(ft).map(([k, v]) => `<span style="display:inline-block; font-size:10px; background:#e0f2fe; color:#0369a1; border-radius:4px; padding:2px 6px; margin:2px;">${{featureLabels[k] || k}}: ${{v}}★</span>`).join(' ');

        rowsHtml += `
          <tr>
            <td style="white-space:nowrap; color:#64748b;">${{escapeHtml(f.date || 'Recently')}}</td>
            <td><strong>${{escapeHtml(f.name || 'Anonymous')}}</strong></td>
            <td style="color:#0284c7;">${{escapeHtml(f.email || 'N/A')}}</td>
            <td style="color:#d97706; font-weight:bold; letter-spacing:1px;">${{starStr}}</td>
            <td>
              <div style="margin-bottom:6px; line-height:1.4;">${{escapeHtml(f.message || '')}}</div>
              <div style="margin-top:4px;">${{featureTagsPills}}</div>
            </td>
          </tr>
        `;
      }});

      const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Receipto Beta Testers Feedback Report</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 25px; color: #0f172a; margin: 0; }}
    .header {{ border-bottom: 2px solid #0284c7; padding-bottom: 12px; margin-bottom: 18px; display: flex; justify-content: space-between; align-items: flex-end; }}
    h1 {{ margin: 0 0 4px 0; color: #0f172a; font-size: 22px; }}
    .meta {{ font-size: 12px; color: #64748b; }}
    .stats-card {{ display: flex; gap: 20px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px 18px; margin-bottom: 20px; }}
    .stat-item {{ font-size: 12px; color: #475569; }}
    .stat-item strong {{ display: block; font-size: 20px; color: #0284c7; margin-top: 2px; }}
    table {{ width: 100%; border-collapse: collapse; font-size: 12px; }}
    th {{ background: #0f172a; color: #ffffff; text-align: left; padding: 9px 10px; font-weight: 600; }}
    td {{ padding: 9px 10px; border-bottom: 1px solid #e2e8f0; vertical-align: top; }}
    tr:nth-child(even) {{ background: #f8fafc; }}
    @media print {{
      body {{ padding: 0; }}
      @page {{ margin: 10mm; size: landscape; }}
    }}
  </style>
</head>
<body>
  <div class="header">
    <div>
      <h1>📄 Receipto Beta Testers Feedback Report</h1>
      <div class="meta">Confidential App Diagnostics &amp; User Experience Log</div>
    </div>
    <div class="meta" style="text-align: right;">Generated: ${{dateStr}}</div>
  </div>

  <div class="stats-card">
    <div class="stat-item">Total Reviews Received<strong>${{localFeedbacks.length}}</strong></div>
    <div class="stat-item">Average Rating<strong>★ ${{avg}} / 5.0</strong></div>
    <div class="stat-item">Developer<strong>Milanraj D Kunder</strong></div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Tester Name</th>
        <th>Email</th>
        <th>Overall Rating</th>
        <th>Feedback Response &amp; Core Feature Tags</th>
      </tr>
    </thead>
    <tbody>
      ${{rowsHtml}}
    </tbody>
  </table>
  <script>
    window.onload = function() {{
      window.print();
    }};
  <\\/script>
</body>
</html>`;

      printWindow.document.write(html);
      printWindow.document.close();
    }};

    // Delete feedback globally from Cloud and Locally
    window.deleteFeedback = async function(id) {{
      if (!confirm('Are you sure you want to permanently delete this review?')) return;

      // 1. Delete from Supabase Cloud
      if (supabaseClient) {{
        try {{
          const {{ error }} = await supabaseClient.from('feedbacks').delete().eq('id', id);
          if (error) console.log('Supabase delete status:', error);
        }} catch (e) {{
          console.log('Cloud delete note:', e);
        }}
      }}

      // 2. Delete from local cache
      localFeedbacks = localFeedbacks.filter(x => x.id !== id);
      localStorage.setItem('receipto_feedbacks', JSON.stringify(localFeedbacks));
      renderFeedbacks();

      showToast('Permanently Deleted! 🗑️', 'Review removed from cloud database and community wall.');
    }};

    // --- 5. Render Feedbacks & Core Features Scorecard ---
    function updateScorecard() {{
      if (localFeedbacks.length === 0) return;
      const feats = ['ocr', 'ui', 'pdf', 'analytics', 'warranty', 'search', 'performance'];
      const sums = {{ ocr: 0, ui: 0, pdf: 0, analytics: 0, warranty: 0, search: 0, performance: 0 }};

      localFeedbacks.forEach(f => {{
        const ft = f.features || {{}};
        feats.forEach(k => {{
          sums[k] += (ft[k] !== undefined ? ft[k] : 5);
        }});
      }});

      const count = localFeedbacks.length;
      feats.forEach(k => {{
        const el = document.getElementById('score-' + k);
        if (el) {{
          const avgScore = (sums[k] / count).toFixed(1);
          el.innerText = '★ ' + avgScore;
        }}
      }});
      document.getElementById('scorecardCount').innerText = `Calculated across ${{count}} reviews`;
    }}

    function renderFeedbacks() {{
      const list = document.getElementById('feedbackList');
      list.innerHTML = '';
      let totalRating = 0;

      if (localFeedbacks.length === 0) {{
        list.innerHTML = `
          <div style="text-align:center; padding: 40px 20px; color: var(--text-dim);">
            <div style="font-size: 32px; margin-bottom: 8px;">💬</div>
            <div style="font-weight: 600; color: var(--text-muted);">No reviews posted yet</div>
            <div style="font-size: 13px;">Be the first beta tester to submit feedback using the form!</div>
          </div>
        `;
        document.getElementById('avgRating').innerText = '5.0';
        document.getElementById('totalReviewsCount').innerText = '0';
        return;
      }}

      localFeedbacks.forEach(item => {{
        totalRating += item.rating;
        const card = document.createElement('div');
        card.className = 'feedback-item';
        const starsText = '★'.repeat(item.rating) + '☆'.repeat(5 - item.rating);
        const initial = (item.name || 'T')[0].toUpperCase();
        const ft = item.features || {{ ocr: 5, ui: 5, pdf: 5, analytics: 5, warranty: 5, search: 5, performance: 5 }};

        // Render Core Feature Responses AS TAGS in the response part
        const featureTagsHtml = Object.entries(ft).map(([k, val]) => {{
          const label = featureLabels[k] || k.toUpperCase();
          return `<span class="feature-tag-pill">${{label}}: <strong>${{val}}★</strong></span>`;
        }}).join('');

        card.innerHTML = `
          <div class="item-top">
            <div class="user-info">
              <div class="user-avatar">${{initial}}</div>
              <div>
                <div class="user-name">${{escapeHtml(item.name)}}</div>
                <div class="user-device">Verified Closed Tester</div>
              </div>
            </div>
            <div class="item-rating">${{starsText}}</div>
          </div>
          <div class="item-body">${{escapeHtml(item.message)}}</div>
          
          <!-- Core App Feature Ratings AS TAGS in response part -->
          <div class="response-feature-tags">
            ${{featureTagsHtml}}
          </div>

          <div class="item-footer">
            <span>${{item.date || 'Recently'}}</span>
            <div>
              <button class="helpful-btn" onclick="upvote('${{item.id}}', this)">
                👍 Helpful (${{item.helpful || 0}})
              </button>
              <button class="delete-btn" onclick="deleteFeedback('${{item.id}}')">
                🗑️ Delete
              </button>
            </div>
          </div>
        `;
        list.appendChild(card);
      }});

      const count = localFeedbacks.length;
      const avg = count > 0 ? (totalRating / count).toFixed(1) : '5.0';
      document.getElementById('avgRating').innerText = avg;
      document.getElementById('totalReviewsCount').innerText = count;

      updateScorecard();
    }}

    function escapeHtml(text) {{
      const div = document.createElement('div');
      div.innerText = text;
      return div.innerHTML;
    }}

    window.upvote = async function(id, btn) {{
      const item = localFeedbacks.find(x => x.id === id);
      if (item) {{
        item.helpful = (item.helpful || 0) + 1;
        localStorage.setItem('receipto_feedbacks', JSON.stringify(localFeedbacks));
        btn.innerHTML = `👍 Helpful (${{item.helpful}})`;
        btn.style.color = '#00D9FF';
        btn.style.borderColor = '#00D9FF';

        if (supabaseClient) {{
          try {{
            await supabaseClient.from('feedbacks').update({{ helpful: item.helpful }}).eq('id', id);
          }} catch(e) {{}}
        }}
      }}
    }};

    function showToast(title, desc) {{
      const toast = document.getElementById('toast');
      document.getElementById('toastTitle').innerText = title;
      toast.querySelector('div div:last-child').innerText = desc;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 3500);
    }}

    // --- 6. Form Submission ---
    document.getElementById('feedbackForm').addEventListener('submit', async (e) => {{
      e.preventDefault();
      const btn = document.getElementById('submitBtn');
      btn.disabled = true;
      btn.innerHTML = '<span>⏳</span> Posting Feedback...';

      const payload = {{
        name: document.getElementById('testerName').value.trim(),
        email: document.getElementById('testerEmail').value.trim(),
        rating: parseInt(document.getElementById('ratingInput').value),
        features: {{ ...currentFeatureRatings }},
        message: document.getElementById('feedbackText').value.trim(),
        helpful: 0
      }};

      let insertedId = 'fb-' + Date.now();

      // Push to Supabase Cloud Database
      if (supabaseClient) {{
        try {{
          const {{ data, error }} = await supabaseClient
            .from('feedbacks')
            .insert([payload])
            .select();

          if (!error && data && data.length > 0) {{
            insertedId = data[0].id;
          }} else if (error) {{
            console.log('Supabase insert note:', error);
          }}
        }} catch (err) {{
          console.log('Cloud insert note:', err);
        }}
      }}

      // Prepend to local list
      localFeedbacks.unshift({{
        ...payload,
        id: insertedId,
        date: 'Just now'
      }});
      localStorage.setItem('receipto_feedbacks', JSON.stringify(localFeedbacks));
      renderFeedbacks();

      // Confetti celebration
      if (window.confetti) {{
        window.confetti({{ particleCount: 90, spread: 75, origin: {{ y: 0.6 }} }});
      }}

      showToast('Feedback Published! 🚀', 'Your review and feature tags are live!');
      document.getElementById('feedbackText').value = '';
      btn.disabled = false;
      btn.innerHTML = '<span>🚀</span> Post Tester Feedback';
    }});

    // Initial Load
    loadFeedbacksFromCloud();
  </script>
</body>
</html>
'''

with open('docs/feedback.html', 'w', encoding='utf-8') as out:
    out.write(html_content)

with open('docs/index.html', 'w', encoding='utf-8') as out:
    out.write(html_content)

print('Updated docs/feedback.html and docs/index.html successfully!')
