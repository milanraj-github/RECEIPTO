import os

with open('playstore_assets/logo_small_b64.txt') as f:
    logo_b64 = f.read().strip()

html_content = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Receipto – Official Beta Testing &amp; Feedback Portal</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"></script>
  <style>
    :root {{
      --bg: #07090e;
      --bg-card: rgba(16, 21, 36, 0.72);
      --bg-card-hover: rgba(22, 29, 49, 0.85);
      --border-card: rgba(99, 102, 241, 0.2);
      --border-focus: #00D9FF;
      --accent-cyan: #00D9FF;
      --accent-blue: #3867FF;
      --accent-purple: #813BFF;
      --accent-gold: #fbbf24;
      --accent-green: #10b981;
      --accent-red: #ef4444;
      --text-primary: #f8fafc;
      --text-secondary: #94a3b8;
      --text-muted: #64748b;
      --gradient-brand: linear-gradient(135deg, #00D9FF 0%, #3867FF 50%, #813BFF 100%);
      --radius-sm: 8px;
      --radius-md: 14px;
      --radius-lg: 20px;
    }}

    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      -webkit-tap-highlight-color: transparent !important;
    }}

    body {{
      background-color: var(--bg);
      color: var(--text-primary);
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh;
      line-height: 1.6;
      position: relative;
      overflow-x: hidden;
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
      opacity: 0.28;
      animation: floatPulse 14s infinite ease-in-out alternate;
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
      animation-delay: -7s;
    }}

    @keyframes floatPulse {{
      0% {{ transform: scale(1) translate(0, 0); opacity: 0.24; }}
      100% {{ transform: scale(1.15) translate(30px, 30px); opacity: 0.38; }}
    }}

    .portal-shell {{
      position: relative;
      z-index: 2;
    }}

    /* Top Navigation Header */
    header {{
      padding: 16px 24px;
      max-width: 1140px;
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
    }}
    .logo-img {{
      width: 38px;
      height: 38px;
      border-radius: 11px;
      box-shadow: 0 4px 18px rgba(0, 217, 255, 0.35);
      object-fit: cover;
    }}
    .brand-title {{
      font-size: 19px;
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
    }}
    .beta-badge {{
      background: rgba(0, 217, 255, 0.1);
      border: 1px solid rgba(0, 217, 255, 0.3);
      color: var(--accent-cyan);
      font-size: 11px;
      font-weight: 700;
      padding: 5px 12px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      white-space: nowrap;
    }}
    .admin-toggle-btn {{
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.12);
      color: var(--text-secondary);
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

    @media (max-width: 600px) {{
      header {{
        padding: 12px 16px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        width: 100%;
      }}
      .brand {{
        display: flex;
        align-items: center;
        gap: 8px;
      }}
      .logo-img {{ width: 32px; height: 32px; border-radius: 9px; }}
      .brand-title {{ font-size: 18px; font-weight: 800; }}
      .header-actions {{
        display: flex;
        align-items: center;
        gap: 8px;
      }}
      .beta-badge {{ display: none !important; }}
      .admin-toggle-btn {{
        padding: 6px 12px;
        font-size: 12px;
        font-weight: 600;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.06);
      }}
    }}

    /* Admin Banner */
    .admin-banner {{
      display: none;
      max-width: 1140px;
      margin: 0 auto 20px auto;
      padding: 14px 20px;
      background: linear-gradient(135deg, rgba(129, 59, 255, 0.2) 0%, rgba(0, 217, 255, 0.15) 100%);
      border: 1px solid rgba(0, 217, 255, 0.35);
      border-radius: var(--radius-md);
      backdrop-filter: blur(20px);
      box-shadow: 0 10px 30px rgba(0, 217, 255, 0.15);
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
    }}
    body.admin-mode .admin-banner {{ display: flex; }}
    .admin-info {{ display: flex; align-items: center; gap: 10px; }}
    .admin-badge-icon {{
      width: 34px; height: 34px; border-radius: 9px;
      background: rgba(0, 217, 255, 0.2);
      display: flex; align-items: center; justify-content: center;
      font-size: 16px;
    }}
    .admin-title {{ font-weight: 800; font-size: 13.5px; color: #fff; }}
    .admin-desc {{ font-size: 11.5px; color: var(--text-secondary); }}
    .admin-actions {{ display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }}
    .export-btn {{
      padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: 700;
      cursor: pointer; display: flex; align-items: center; gap: 5px;
      border: none; user-select: none; transition: all 0.2s;
    }}
    .export-pdf {{ background: #dc2626; color: #fff; }}
    .export-csv {{ background: #059669; color: #fff; }}
    .export-json {{ background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255, 255, 255, 0.15); color: #e2e8f0; }}
    .lock-admin-btn {{ background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.3); color: #f87171; }}

    /* Hero Section */
    .hero {{
      text-align: center;
      padding: 30px 20px 24px 20px;
      max-width: 860px;
      margin: 0 auto;
    }}
    .program-pill {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(129, 59, 255, 0.12);
      border: 1px solid rgba(129, 59, 255, 0.3);
      padding: 6px 16px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 700;
      color: #c4b5fd;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      margin-bottom: 16px;
    }}
    .hero h1 {{
      font-size: clamp(28px, 4.8vw, 48px);
      font-weight: 800;
      letter-spacing: -1px;
      line-height: 1.15;
      margin-bottom: 14px;
    }}
    .hero h1 span {{
      background: var(--gradient-brand);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }}
    .hero p {{
      color: var(--text-secondary);
      font-size: clamp(14px, 2vw, 16.5px);
      max-width: 680px;
      margin: 0 auto 24px auto;
      line-height: 1.6;
    }}
    .hero-meta-row {{
      display: flex;
      justify-content: center;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px 24px;
      font-size: 12.5px;
      color: var(--text-muted);
      margin-bottom: 24px;
    }}
    .hero-meta-item {{
      display: flex;
      align-items: center;
      gap: 6px;
    }}
    .hero-cta-btn {{
      background: var(--gradient-brand);
      color: #07090e;
      font-weight: 800;
      font-size: 15px;
      padding: 13px 32px;
      border-radius: 999px;
      border: none;
      cursor: pointer;
      box-shadow: 0 10px 30px rgba(0, 217, 255, 0.4);
      transition: all 0.25s ease;
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }}
    .hero-cta-btn:hover {{
      transform: translateY(-2px);
      box-shadow: 0 15px 40px rgba(0, 217, 255, 0.55);
    }}

    /* Main Container & Stepper Form Layout */
    .container {{
      max-width: 920px;
      margin: 0 auto;
      padding: 0 18px 80px 18px;
    }}

    /* Stepper Navigation Bar */
    .stepper-nav {{
      background: rgba(16, 21, 36, 0.85);
      backdrop-filter: blur(20px);
      border: 1px solid var(--border-card);
      border-radius: var(--radius-md);
      padding: 8px 12px;
      margin-bottom: 26px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 8px;
      overflow-x: auto;
      scrollbar-width: none;
    }}
    .stepper-nav::-webkit-scrollbar {{ display: none; }}
    .step-pill {{
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 14px;
      border-radius: 10px;
      font-size: 12px;
      font-weight: 700;
      color: var(--text-muted);
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.2s ease;
      background: transparent;
      border: none;
    }}
    .step-num {{
      width: 22px;
      height: 22px;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.08);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      font-weight: 800;
    }}
    .step-pill.active {{
      background: rgba(0, 217, 255, 0.12);
      color: var(--accent-cyan);
      border: 1px solid rgba(0, 217, 255, 0.3);
    }}
    .step-pill.active .step-num {{
      background: var(--accent-cyan);
      color: #07090e;
    }}
    .step-pill.completed {{
      color: #cbd5e1;
    }}
    .step-pill.completed .step-num {{
      background: var(--accent-green);
      color: #07090e;
    }}

    /* Section Card */
    .section-card {{
      background: var(--bg-card);
      backdrop-filter: blur(24px);
      border: 1px solid var(--border-card);
      border-radius: var(--radius-lg);
      padding: 34px 30px;
      box-shadow: 0 25px 60px rgba(0, 0, 0, 0.5);
      margin-bottom: 24px;
      display: none;
      animation: fadeIn 0.3s ease;
    }}
    .section-card.active {{
      display: block;
    }}
    @keyframes fadeIn {{
      from {{ opacity: 0; transform: translateY(8px); }}
      to {{ opacity: 1; transform: translateY(0); }}
    }}
    @media (max-width: 600px) {{
      .section-card {{ padding: 22px 18px; border-radius: var(--radius-md); }}
    }}

    .section-header {{
      margin-bottom: 24px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
      padding-bottom: 16px;
    }}
    .section-tag {{
      font-size: 11.5px;
      font-weight: 800;
      color: var(--accent-cyan);
      text-transform: uppercase;
      letter-spacing: 0.8px;
      margin-bottom: 4px;
      display: block;
    }}
    .section-title {{
      font-size: 22px;
      font-weight: 800;
      color: #fff;
      letter-spacing: -0.3px;
    }}
    .section-desc {{
      color: var(--text-secondary);
      font-size: 13.5px;
      margin-top: 4px;
    }}

    /* Form Inputs */
    .form-grid-2 {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }}
    @media (max-width: 640px) {{
      .form-grid-2 {{ grid-template-columns: 1fr; }}
    }}
    .form-group {{
      margin-bottom: 18px;
    }}
    label.field-label {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12.5px;
      font-weight: 700;
      color: #e2e8f0;
      margin-bottom: 7px;
      user-select: none;
    }}
    .req-star {{ color: var(--accent-red); margin-left: 3px; }}
    .opt-badge {{ color: var(--text-muted); font-weight: normal; font-size: 11px; }}

    input[type="text"],
    input[type="email"],
    input[type="password"],
    select,
    textarea {{
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
    input:focus, select:focus, textarea:focus {{
      border-color: var(--accent-cyan);
      box-shadow: 0 0 0 3px rgba(0, 217, 255, 0.15);
      background: rgba(255, 255, 255, 0.06);
    }}
    select {{
      appearance: none;
      background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2300D9FF' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
      background-repeat: no-repeat;
      background-position: right 14px center;
      background-size: 16px;
      padding-right: 40px;
    }}
    select option {{
      background: #0f172a;
      color: #fff;
    }}
    textarea {{
      resize: vertical;
      min-height: 90px;
    }}

    /* Field Validation & Error Highlighting */
    .input-error {{
      border-color: #ef4444 !important;
      background: rgba(239, 68, 68, 0.08) !important;
      box-shadow: 0 0 14px rgba(239, 68, 68, 0.45) !important;
      animation: fieldShake 0.35s ease;
    }}
    @keyframes fieldShake {{
      0%, 100% {{ transform: translateX(0); }}
      25% {{ transform: translateX(-6px); }}
      50% {{ transform: translateX(6px); }}
      75% {{ transform: translateX(-4px); }}
    }}
    .field-error-text {{
      color: #f87171;
      font-size: 11.5px;
      font-weight: 700;
      margin-top: 5px;
      display: flex;
      align-items: center;
      gap: 5px;
      animation: fadeIn 0.2s ease;
    }}

    /* Interactive Five-Star Component */
    .star-rating-box {{
      background: rgba(255, 255, 255, 0.025);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: var(--radius-md);
      padding: 16px;
      text-align: center;
      margin-bottom: 20px;
      user-select: none;
      -webkit-user-select: none;
      -webkit-touch-callout: none;
    }}
    .star-box-title {{
      font-size: 12px;
      font-weight: 700;
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
    }}
    .star-row {{
      display: inline-flex;
      gap: 12px;
      cursor: pointer;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      touch-action: manipulation;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
    }}
    .star-btn {{
      font-size: 38px;
      color: rgba(255, 255, 255, 0.16);
      transition: transform 0.15s ease, color 0.15s ease;
      line-height: 1;
      display: inline-block;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      touch-action: manipulation;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
      outline: none !important;
      border: none !important;
      background: transparent !important;
      box-shadow: none !important;
      -webkit-appearance: none;
    }}
    .star-btn:focus, .star-btn:active, .star-btn:focus-visible, .star-btn:visited {{
      outline: none !important;
      border: none !important;
      box-shadow: none !important;
      background: transparent !important;
      -webkit-tap-highlight-color: transparent !important;
    }}
    .star-btn.active {{
      color: var(--accent-gold);
      transform: scale(1.08);
      filter: drop-shadow(0 0 10px rgba(251, 191, 36, 0.45));
    }}
    .star-desc-text {{
      font-size: 13.5px;
      font-weight: 700;
      color: var(--accent-gold);
      margin-top: 8px;
      min-height: 20px;
    }}

    /* Overall Tester Responses & Ratings Display (Below Hero) */
    .overall-response-section {{
      max-width: 920px;
      margin: 0 auto 30px auto;
      padding: 0 18px;
    }}
    .overall-response-container {{
      display: grid;
      grid-template-columns: 1.15fr 1fr;
      gap: 16px;
    }}
    @media (max-width: 768px) {{
      .overall-response-container {{
        grid-template-columns: 1fr;
      }}
    }}
    .response-hero-card,
    .response-features-card {{
      background: linear-gradient(135deg, rgba(16, 21, 36, 0.88) 0%, rgba(22, 31, 56, 0.94) 100%);
      border: 1px solid rgba(0, 217, 255, 0.28);
      border-radius: var(--radius-lg);
      padding: 24px 22px;
      backdrop-filter: blur(20px);
      box-shadow: 0 12px 35px rgba(0, 0, 0, 0.4);
      position: relative;
      overflow: hidden;
    }}
    .response-badge {{
      display: inline-block;
      font-size: 10.5px;
      font-weight: 800;
      color: var(--accent-cyan);
      background: rgba(0, 217, 255, 0.1);
      border: 1px solid rgba(0, 217, 255, 0.25);
      padding: 4px 10px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      margin-bottom: 12px;
    }}
    .response-score-row {{
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 16px;
    }}
    .response-big-score {{
      font-size: clamp(38px, 6vw, 52px);
      font-weight: 900;
      line-height: 1;
      color: var(--accent-gold);
      text-shadow: 0 0 20px rgba(251, 191, 36, 0.4);
      font-family: 'Plus Jakarta Sans', sans-serif;
    }}
    .response-stars-visual {{
      color: var(--accent-gold);
      font-size: 18px;
      letter-spacing: 2px;
      margin-bottom: 3px;
    }}
    .response-label {{
      font-size: 14px;
      font-weight: 800;
      color: #fff;
    }}
    .response-count-meta {{
      font-size: 12px;
      color: var(--text-secondary);
      margin-top: 2px;
    }}
    .highlight-count {{
      color: var(--accent-cyan);
      font-weight: 700;
    }}

    /* Rating Breakdown Bars */
    .rating-breakdown-bars {{
      border-top: 1px solid rgba(255, 255, 255, 0.06);
      padding-top: 12px;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }}
    .bar-row {{
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 11px;
      color: var(--text-secondary);
    }}
    .bar-label {{
      width: 26px;
      font-weight: 700;
      color: #e2e8f0;
    }}
    .bar-track {{
      flex: 1;
      height: 6px;
      background: rgba(255, 255, 255, 0.08);
      border-radius: 999px;
      overflow: hidden;
    }}
    .bar-fill {{
      height: 100%;
      background: linear-gradient(90deg, #fbbf24 0%, #f59e0b 100%);
      border-radius: 999px;
      transition: width 0.4s ease;
    }}
    .bar-val {{
      width: 22px;
      text-align: right;
      color: var(--text-muted);
      font-weight: 600;
    }}

    
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

    /* Core App Feature Rating Tags */
    .features-header-row {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 6px;
    }}
    .response-card-title {{
      font-size: 14.5px;
      font-weight: 800;
      color: #fff;
    }}
    .response-pill-sub {{
      font-size: 10.5px;
      color: var(--accent-cyan);
      font-weight: 700;
      background: rgba(0, 217, 255, 0.1);
      padding: 2px 8px;
      border-radius: 6px;
    }}
    .features-card-desc {{
      font-size: 12px;
      color: var(--text-secondary);
      margin-bottom: 14px;
      line-height: 1.4;
    }}
    .feature-rating-tags-grid {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
    }}
    @media (max-width: 480px) {{
      .feature-rating-tags-grid {{
        grid-template-columns: 1fr;
      }}
    }}
    .feature-tag-chip {{
      background: rgba(255, 255, 255, 0.035);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 9px;
      padding: 7px 10px;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s ease;
    }}
    .feature-tag-chip:hover {{
      border-color: rgba(0, 217, 255, 0.3);
      background: rgba(0, 217, 255, 0.05);
    }}
    .ft-icon {{
      font-size: 13px;
    }}
    .ft-name {{
      flex: 1;
      font-size: 11px;
      font-weight: 600;
      color: #cbd5e1;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }}
    .ft-score {{
      font-size: 11.5px;
      font-weight: 800;
      color: var(--accent-cyan);
    }}

    /* Choice Chip Groups */
    .choice-chips-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
      gap: 8px;
      margin-top: 6px;
    }}
    .choice-chip {{
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.09);
      border-radius: 10px;
      padding: 10px 12px;
      text-align: center;
      font-size: 12.5px;
      font-weight: 600;
      color: var(--text-secondary);
      cursor: pointer;
      user-select: none;
      transition: all 0.2s ease;
    }}
    .choice-chip:hover {{
      border-color: rgba(0, 217, 255, 0.3);
      color: #fff;
    }}
    .choice-chip.selected {{
      background: rgba(0, 217, 255, 0.14);
      border-color: var(--accent-cyan);
      color: var(--accent-cyan);
      font-weight: 700;
    }}

    /* Feature Deep-Dive Cards */
    .feature-card {{
      background: rgba(255, 255, 255, 0.025);
      border: 1px solid rgba(255, 255, 255, 0.07);
      border-radius: var(--radius-md);
      padding: 20px;
      margin-bottom: 20px;
      transition: border-color 0.2s ease;
    }}
    .feature-card:hover {{
      border-color: rgba(99, 102, 241, 0.35);
    }}
    .feature-card-header {{
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 8px;
    }}
    .feature-card-title {{
      font-size: 15.5px;
      font-weight: 800;
      color: #fff;
      display: flex;
      align-items: center;
      gap: 8px;
    }}
    .feature-card-desc {{
      font-size: 12.5px;
      color: var(--text-secondary);
      margin-bottom: 14px;
      line-height: 1.5;
    }}
    .feature-rate-row {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
      padding-top: 10px;
      border-top: 1px solid rgba(255, 255, 255, 0.05);
    }}
    .feature-stars {{
      display: inline-flex;
      gap: 6px;
      cursor: pointer;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      touch-action: manipulation;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
    }}
    .feat-star {{
      font-size: 22px;
      color: rgba(255, 255, 255, 0.16);
      transition: color 0.15s;
      user-select: none !important;
      -webkit-user-select: none !important;
      -webkit-touch-callout: none !important;
      touch-action: manipulation;
      -webkit-tap-highlight-color: transparent !important;
      -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
      outline: none !important;
      border: none !important;
      background: transparent !important;
      box-shadow: none !important;
    }}
    .feat-star:focus, .feat-star:active, .feat-star:focus-visible {{
      outline: none !important;
      border: none !important;
      box-shadow: none !important;
      background: transparent !important;
      -webkit-tap-highlight-color: transparent !important;
    }}
    .feat-star.active {{
      color: var(--accent-cyan);
    }}
    .not-tested-toggle {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 11.5px;
      color: var(--text-muted);
      cursor: pointer;
      user-select: none;
    }}
    .not-tested-toggle input {{
      accent-color: var(--accent-cyan);
      cursor: pointer;
    }}
    .feature-comment-input {{
      margin-top: 10px;
      font-size: 12.5px;
      padding: 8px 12px;
      border-radius: 8px;
      min-height: 50px;
    }}

    /* Conditional Bug Report Box */
    .bug-box {{
      background: rgba(239, 68, 68, 0.05);
      border: 1px solid rgba(239, 68, 68, 0.25);
      border-radius: var(--radius-md);
      padding: 18px;
      margin-top: 16px;
      display: none;
      animation: fadeIn 0.3s ease;
    }}
    .bug-box.show {{ display: block; }}

    /* Form Bottom Button Bar */
    .form-btn-bar {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 14px;
      margin-top: 28px;
      padding-top: 20px;
      border-top: 1px solid rgba(255, 255, 255, 0.07);
    }}
    .btn-prev {{
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.12);
      color: var(--text-secondary);
      padding: 12px 24px;
      border-radius: 12px;
      font-size: 13.5px;
      font-weight: 700;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }}
    .btn-prev:hover {{ background: rgba(255, 255, 255, 0.1); color: #fff; }}
    .btn-next {{
      background: var(--gradient-brand);
      color: #07090e;
      border: none;
      padding: 12px 28px;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 800;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      box-shadow: 0 4px 18px rgba(0, 217, 255, 0.35);
      margin-left: auto;
    }}
    .btn-next:hover {{ transform: translateY(-1px); box-shadow: 0 6px 24px rgba(0, 217, 255, 0.5); }}
    .btn-submit {{
      background: linear-gradient(135deg, #10b981 0%, #059669 100%);
      color: #fff;
      box-shadow: 0 4px 20px rgba(16, 185, 129, 0.4);
    }}
    .btn-submit:hover {{ box-shadow: 0 6px 28px rgba(16, 185, 129, 0.6); }}

    /* Success Card */
    .success-card {{
      display: none;
      text-align: center;
      padding: 50px 24px;
      background: var(--bg-card);
      border: 1px solid rgba(16, 185, 129, 0.35);
      border-radius: var(--radius-lg);
      box-shadow: 0 25px 60px rgba(0, 0, 0, 0.5);
    }}
    .success-card.show {{ display: block; animation: fadeIn 0.4s ease; }}
    .success-icon-badge {{
      width: 70px; height: 70px; border-radius: 50%;
      background: rgba(16, 185, 129, 0.15);
      border: 2px solid var(--accent-green);
      display: inline-flex; align-items: center; justify-content: center;
      font-size: 32px; margin-bottom: 20px;
    }}
    .success-title {{
      font-size: 26px; font-weight: 800; color: #fff; margin-bottom: 10px;
    }}
    .success-subtitle {{
      color: var(--text-secondary); font-size: 14.5px; max-width: 500px;
      margin: 0 auto 24px auto; line-height: 1.6;
    }}

    /* Community Reviews Wall Section (Collapsible / Bottom) */
    .community-wall-section {{
      margin-top: 40px;
      border-top: 1px solid rgba(255, 255, 255, 0.08);
      padding-top: 30px;
    }}
    .community-header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 18px;
    }}
    .community-title {{
      font-size: 18px; font-weight: 800; color: #fff;
      display: flex; align-items: center; gap: 8px;
    }}
    .wall-stats-badge {{
      background: rgba(251, 191, 36, 0.12);
      border: 1px solid rgba(251, 191, 36, 0.3);
      padding: 4px 12px; border-radius: 999px;
      font-size: 12px; font-weight: 700; color: var(--accent-gold);
    }}
    .wall-feed-list {{
      display: grid;
      grid-template-columns: 1fr;
      gap: 14px;
    }}
    /* Enhanced Public Feedback Cards (Full Details Display) */
    .feed-card {{
      background: rgba(16, 21, 36, 0.78);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: var(--radius-md);
      padding: 20px;
      animation: fadeIn 0.3s ease;
      margin-bottom: 16px;
      transition: all 0.2s ease;
    }}
    .feed-card:hover {{
      border-color: rgba(0, 217, 255, 0.3);
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
    }}
    .feed-top {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
      margin-bottom: 14px;
    }}
    .feed-user {{ display: flex; align-items: center; gap: 12px; }}
    .feed-avatar {{
      width: 36px; height: 36px; border-radius: 50%;
      background: var(--gradient-brand);
      display: flex; align-items: center; justify-content: center;
      font-weight: 800; color: #07090e; font-size: 14px;
    }}
    .feed-name {{ font-weight: 800; font-size: 14.5px; color: #fff; }}
    .feed-meta {{ font-size: 11.5px; color: var(--text-muted); }}
    .feed-stars-badge {{
      display: flex;
      align-items: center;
      gap: 6px;
      background: rgba(251, 191, 36, 0.1);
      border: 1px solid rgba(251, 191, 36, 0.25);
      padding: 4px 10px;
      border-radius: 999px;
      color: var(--accent-gold);
      font-size: 13px;
    }}
    .feed-stars-val {{
      font-weight: 800;
      font-size: 12px;
      color: #fff;
    }}
    .feed-insights-list {{
      display: flex;
      flex-direction: column;
      gap: 10px;
      margin-bottom: 14px;
    }}
    .feed-quote-item {{
      background: rgba(255, 255, 255, 0.03);
      border-radius: 8px;
      padding: 10px 12px;
      font-size: 13px;
      line-height: 1.5;
      color: #e2e8f0;
    }}
    .feed-quote-item.fav {{
      border-left: 3px solid var(--accent-cyan);
    }}
    .feed-quote-item.imp {{
      border-left: 3px solid #f59e0b;
    }}
    .feed-quote-item.wish {{
      border-left: 3px solid var(--accent-purple);
    }}
    .feed-quote-title {{
      font-size: 11px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 3px;
      display: flex;
      align-items: center;
      gap: 4px;
    }}
    .feed-quote-title.fav {{ color: var(--accent-cyan); }}
    .feed-quote-title.imp {{ color: #fbbf24; }}
    .feed-quote-title.wish {{ color: #c4b5fd; }}
    .feed-meta-chips-row {{
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-bottom: 12px;
    }}
    .feed-badge-pill {{
      font-size: 11px;
      font-weight: 600;
      padding: 3px 9px;
      border-radius: 6px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.1);
      color: #cbd5e1;
    }}
    .feed-feature-chip {{
      font-size: 11px;
      font-weight: 700;
      padding: 3px 9px;
      border-radius: 6px;
      background: rgba(0, 217, 255, 0.08);
      border: 1px solid rgba(0, 217, 255, 0.2);
      color: var(--accent-cyan);
    }}
    .feed-details-accordion {{
      background: rgba(0, 0, 0, 0.25);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 8px;
      padding: 12px 14px;
      font-size: 12px;
      color: #94a3b8;
      margin-bottom: 12px;
      display: none;
      animation: fadeIn 0.2s ease;
    }}
    .feed-details-accordion.show {{
      display: block;
    }}
    .feed-accordion-btn {{
      background: transparent;
      border: none;
      color: var(--accent-cyan);
      font-size: 11.5px;
      font-weight: 700;
      cursor: pointer;
      padding: 0;
      display: inline-flex;
      align-items: center;
      gap: 4px;
      margin-bottom: 10px;
    }}
    .feed-accordion-btn:hover {{
      text-decoration: underline;
    }}
    .feed-footer {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 11px;
      color: var(--text-muted);
      border-top: 1px solid rgba(255, 255, 255, 0.05);
      padding-top: 10px;
      margin-top: 8px;
    }}
    .verified-tag {{
      color: var(--accent-green);
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      gap: 4px;
    }}
    .feed-del-btn {{
      display: none;
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.4);
      color: #f87171;
      padding: 3px 8px; border-radius: 6px;
      font-size: 10.5px; font-weight: 700; cursor: pointer;
    }}
    body.admin-mode .feed-del-btn {{ display: inline-flex; align-items: center; gap: 4px; }}

    /* Admin Dedicated Full Responses Dashboard */
    .admin-responses-dashboard {{
      display: none;
      max-width: 1140px;
      margin: 0 auto 30px auto;
      padding: 24px;
      background: rgba(16, 21, 36, 0.92);
      border: 1px solid rgba(0, 217, 255, 0.35);
      border-radius: var(--radius-lg);
      backdrop-filter: blur(24px);
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
      animation: fadeIn 0.3s ease;
    }}
    body.admin-mode .admin-responses-dashboard {{
      display: block;
    }}
    .admin-dash-header-row {{
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 16px;
      margin-bottom: 20px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
      padding-bottom: 16px;
    }}
    .admin-dash-badge {{
      display: inline-block;
      font-size: 11px;
      font-weight: 800;
      color: var(--accent-gold);
      background: rgba(251, 191, 36, 0.12);
      border: 1px solid rgba(251, 191, 36, 0.3);
      padding: 4px 12px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      margin-bottom: 6px;
    }}
    .admin-dash-title {{
      font-size: 22px;
      font-weight: 800;
      color: #fff;
    }}
    .admin-dash-subtitle {{
      font-size: 13px;
      color: var(--text-secondary);
      margin-top: 2px;
    }}
    .admin-stats-pills {{
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }}
    .admin-stat-pill {{
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.1);
      padding: 6px 14px;
      border-radius: 10px;
      font-size: 12px;
      color: #cbd5e1;
    }}
    .admin-filter-bar {{
      display: flex;
      gap: 12px;
      margin-bottom: 20px;
      flex-wrap: wrap;
    }}
    .admin-search-input {{
      flex: 1;
      min-width: 260px;
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 10px;
      padding: 10px 14px;
      color: #fff;
      font-size: 13px;
    }}
    .admin-search-input:focus {{
      outline: none;
      border-color: var(--accent-cyan);
    }}
    .admin-filter-select {{
      background: #0f1628;
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 10px;
      padding: 10px 14px;
      color: #fff;
      font-size: 13px;
    }}
    .admin-records-list {{
      display: flex;
      flex-direction: column;
      gap: 18px;
    }}
    .admin-full-card {{
      background: rgba(22, 29, 49, 0.72);
      border: 1px solid rgba(255, 255, 255, 0.09);
      border-radius: var(--radius-md);
      padding: 22px;
      transition: border-color 0.2s ease;
    }}
    .admin-full-card:hover {{
      border-color: rgba(0, 217, 255, 0.35);
    }}
    .admin-card-header {{
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 12px;
      margin-bottom: 16px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
      padding-bottom: 14px;
    }}
    .admin-user-title {{
      font-size: 17px;
      font-weight: 800;
      color: #fff;
      display: flex;
      align-items: center;
      gap: 8px;
    }}
    .admin-user-email {{
      font-size: 12.5px;
      color: var(--accent-cyan);
      margin-top: 3px;
      text-decoration: none;
      display: inline-block;
    }}
    .admin-user-email:hover {{
      text-decoration: underline;
    }}
    .admin-user-meta {{
      font-size: 11.5px;
      color: var(--text-muted);
      margin-top: 3px;
    }}
    .admin-card-rating {{
      text-align: right;
    }}
    .admin-stars {{
      color: var(--accent-gold);
      font-size: 18px;
      letter-spacing: 2px;
    }}
    .admin-rating-badge {{
      font-size: 11.5px;
      font-weight: 700;
      color: var(--accent-gold);
      margin-top: 2px;
    }}
    .admin-q-row {{
      margin-bottom: 14px;
    }}
    .admin-q-label {{
      font-size: 11.5px;
      font-weight: 700;
      color: var(--accent-cyan);
      text-transform: uppercase;
      letter-spacing: 0.6px;
      margin-bottom: 4px;
      display: flex;
      align-items: center;
      gap: 6px;
    }}
    .admin-q-content {{
      background: rgba(255, 255, 255, 0.03);
      border-left: 3px solid var(--accent-cyan);
      padding: 10px 14px;
      border-radius: 0 8px 8px 0;
      font-size: 13.5px;
      color: #f1f5f9;
      line-height: 1.5;
    }}
    .admin-q-content.to-improve {{
      border-left-color: #f59e0b;
    }}
    .admin-q-content.wishlist {{
      border-left-color: var(--accent-purple);
    }}
    .admin-meta-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 10px;
      background: rgba(0, 0, 0, 0.2);
      padding: 12px 14px;
      border-radius: 10px;
      font-size: 12px;
      color: #cbd5e1;
      margin-bottom: 14px;
    }}
    .admin-bug-alert-box {{
      background: rgba(239, 68, 68, 0.08);
      border: 1px solid rgba(239, 68, 68, 0.3);
      border-radius: 10px;
      padding: 14px 16px;
      margin-top: 14px;
    }}
    .admin-bug-title {{
      font-size: 13.5px;
      font-weight: 800;
      color: #f87171;
      display: flex;
      align-items: center;
      gap: 6px;
      margin-bottom: 8px;
    }}
    .admin-bug-grid {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
      font-size: 12px;
      color: #cbd5e1;
    }}
    @media (max-width: 600px) {{
      .admin-bug-grid {{ grid-template-columns: 1fr; }}
    }}
    .admin-card-actions {{
      display: flex;
      justify-content: flex-end;
      align-items: center;
      gap: 8px;
      margin-top: 14px;
      border-top: 1px solid rgba(255, 255, 255, 0.05);
      padding-top: 12px;
    }}

    /* Toast */
    .toast {{
      position: fixed;
      bottom: 24px; right: 24px;
      background: #0f172a;
      border: 1px solid var(--accent-cyan);
      box-shadow: 0 10px 30px rgba(0, 217, 255, 0.3);
      padding: 14px 18px; border-radius: 12px;
      display: flex; align-items: center; gap: 10px;
      z-index: 10000; opacity: 0; transform: translateY(20px);
      transition: all 0.3s ease; pointer-events: none;
    }}
    .toast.show {{ opacity: 1; transform: translateY(0); pointer-events: auto; }}

    /* Modal Backdrop */
    .modal-backdrop {{
      position: fixed; inset: 0; background: rgba(7, 9, 14, 0.75);
      backdrop-filter: blur(10px); z-index: 9999; display: none;
      align-items: center; justify-content: center; padding: 20px;
    }}
    .modal-backdrop.show {{ display: flex; }}
    .modal-card {{
      background: #0f1628; border: 1px solid rgba(0, 217, 255, 0.35);
      box-shadow: 0 25px 60px rgba(0, 0, 0, 0.7);
      border-radius: 20px; padding: 24px; max-width: 420px; width: 100%;
    }}
    .modal-header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }}
    .modal-title {{ font-size: 16px; font-weight: 800; color: #fff; display: flex; align-items: center; gap: 8px; }}
    .modal-close {{ background: transparent; border: none; color: var(--text-muted); font-size: 20px; cursor: pointer; }}
  </style>
</head>
<body>

  <!-- Living Neural Mesh Background Canvas -->
  <canvas id="neuralCanvas"></canvas>
  <div class="glow-blob blob-1"></div>
  <div class="glow-blob blob-2"></div>

  <div class="portal-shell">

    <!-- Top Navigation Header -->
    <header>
      <a href="#" class="brand">
        <img src="data:image/png;base64,{logo_b64}" alt="Receipto Logo" class="logo-img">
        <div class="brand-title">Receipto</div>
      </a>
      <div class="header-actions">
        <div class="beta-badge desktop-only">Official Closed Beta</div>
        <a href="admin.html" class="admin-toggle-btn">
          <span>🔒</span> Admin Portal
        </a>
      </div>
    </header>

    <!-- Admin Action Banner (Visible when admin unlocks) -->
    <div class="admin-banner" id="adminBanner">
      <div class="admin-info">
        <div class="admin-badge-icon">👑</div>
        <div>
          <div class="admin-title">Admin Management Active (Milanraj)</div>
          <div class="admin-desc">Cloud-synchronized feedback management &amp; diagnostic exports.</div>
        </div>
      </div>
      <div class="admin-actions">
        <button type="button" class="export-btn export-pdf" onclick="exportPDF()">
          <span>📑</span> Export PDF
        </button>
        <button type="button" class="export-btn export-csv" onclick="exportCSV()">
          <span>📊</span> Export CSV
        </button>
        <button type="button" class="export-btn export-json" onclick="exportJSON()">
          <span>📦</span> Export JSON
        </button>
        <button type="button" class="export-btn lock-admin-btn" onclick="toggleAdmin()">
          <span>🔒</span> Lock Admin
        </button>
      </div>
    </div>

    <!-- Admin Full Responses Dashboard (Displays full responses and feedback in Admin Mode) -->
    <section class="admin-responses-dashboard" id="adminResponsesDashboard">
      <div class="admin-dash-header-row">
        <div>
          <div class="admin-dash-badge">👑 Master Admin Portal</div>
          <h2 class="admin-dash-title">Tester Feedback &amp; Evaluation Records</h2>
          <p class="admin-dash-subtitle">Viewing full, un-truncated diagnostic evaluations submitted by closed beta testers.</p>
        </div>
        <div class="admin-stats-pills">
          <span class="admin-stat-pill">Total: <b id="adminTotalCount" style="color: var(--accent-cyan);">0</b></span>
          <span class="admin-stat-pill">Avg: <b id="adminAvgScore" style="color: var(--accent-gold);">5.0</b> ★</span>
          <span class="admin-stat-pill" style="color: #f87171;">Bugs: <b id="adminBugsCount">0</b></span>
        </div>
      </div>
      <div class="admin-filter-bar">
        <input type="text" id="adminSearchInput" class="admin-search-input" placeholder="🔍 Search full responses by tester name, email, device or keyword..." oninput="filterAdminResponses()">
        <select id="adminRatingFilter" class="admin-filter-select" onchange="filterAdminResponses()">
          <option value="all">All Ratings (1★ – 5★)</option>
          <option value="5">5 Stars (Excellent)</option>
          <option value="4">4 Stars (Very Good)</option>
          <option value="3">3 Stars &amp; Below</option>
          <option value="bugs">With Bug Reports Only</option>
        </select>
      </div>

      <div class="admin-records-list" id="adminRecordsList">
        <!-- Populated live by renderAdminResponses() -->
      </div>
    </section>

    <!-- Admin Login Modal -->
    <div class="modal-backdrop" id="adminModal">
      <div class="modal-card">
        <div class="modal-header">
          <div class="modal-title"><span>🔐</span> Admin Authentication</div>
          <button type="button" class="modal-close" onclick="closeAdminModal()">✕</button>
        </div>
        <p style="font-size: 12.5px; color: var(--text-secondary); margin-bottom: 16px;">
          Enter master administrator passcode to moderate feedback and download evaluation reports.
        </p>
        <form onsubmit="handleAdminLogin(event)">
          <div class="form-group" style="margin-bottom: 6px;">
            <input type="password" id="adminPassInput" placeholder="Enter master passcode" required>
            <div id="adminErrorMsg" style="color: var(--accent-red); font-size: 11.5px; font-weight: 600; margin-top: 5px;"></div>
          </div>
          <div style="display: flex; justify-content: flex-end; gap: 8px; margin-top: 14px;">
            <button type="button" class="export-btn" style="background: rgba(255,255,255,0.08); color: var(--text-secondary);" onclick="closeAdminModal()">Cancel</button>
            <button type="submit" class="export-btn" style="background: var(--gradient-brand); color: #07090e;">Unlock Admin</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Hero Section -->
    <section class="hero">
      <div class="program-pill">
        <span>✨</span> Official Beta Testing Program
      </div>
      <h1>Help Us Build a <span>Better Receipto.</span></h1>
      <p>
        You're among the early users helping shape the future of smarter receipt management. Share your experience, evaluate our features and help us make Receipto more reliable, efficient and user-friendly.
      </p>
      <div class="hero-meta-row">
        <div class="hero-meta-item"><span>📋</span> Beta Tester Feedback</div>
        <div class="hero-meta-item"><span>⏱️</span> Approximately 5–7 minutes</div>
        <div class="hero-meta-item"><span>🛡️</span> Secure feedback submission</div>
        <div class="hero-meta-item"><span>💡</span> Your feedback helps improve the product</div>
      </div>
      <button type="button" class="hero-cta-btn" onclick="scrollToForm()">
        <span>Share Your Feedback</span>
        <span>↓</span>
      </button>
    </section>

    <!-- OVERALL TESTER RESPONSES & RATINGS DISPLAY (BELOW HERO) -->
    <section class="overall-response-section" id="overallResponseSection">
      <div class="overall-response-container">
        
        <!-- Left: Overall Rating Scoreboard -->
        <div class="response-hero-card">
          <div class="response-badge">🌟 Verified Beta Ratings</div>
          <div class="response-score-row">
            <div class="response-big-score" id="displayAvgRating">4.9</div>
            <div class="response-score-details">
              <div class="response-stars-visual" id="displayStarsVisual">★★★★★</div>
              <div class="response-label" id="displayRatingLabel">Excellent Experience</div>
              <div class="response-count-meta">
                Based on <span id="displayResponseCount" class="highlight-count">0</span> Tester Responses
              </div>
            </div>
          </div>
          
          <!-- Rating Breakdown Bars (5★ to 1★) -->
          <div class="rating-breakdown-bars">
            <div class="bar-row">
              <span class="bar-label">5 ★</span>
              <div class="bar-track"><div class="bar-fill" id="bar5" style="width: 80%;"></div></div>
              <span class="bar-val" id="barVal5">0</span>
            </div>
            <div class="bar-row">
              <span class="bar-label">4 ★</span>
              <div class="bar-track"><div class="bar-fill" id="bar4" style="width: 20%;"></div></div>
              <span class="bar-val" id="barVal4">0</span>
            </div>
            <div class="bar-row">
              <span class="bar-label">3 ★</span>
              <div class="bar-track"><div class="bar-fill" id="bar3" style="width: 0%;"></div></div>
              <span class="bar-val" id="barVal3">0</span>
            </div>
            <div class="bar-row">
              <span class="bar-label">2 ★</span>
              <div class="bar-track"><div class="bar-fill" id="bar2" style="width: 0%;"></div></div>
              <span class="bar-val" id="barVal2">0</span>
            </div>
            <div class="bar-row">
              <span class="bar-label">1 ★</span>
              <div class="bar-track"><div class="bar-fill" id="bar1" style="width: 0%;"></div></div>
              <span class="bar-val" id="barVal1">0</span>
            </div>
          </div>
        </div>

        <!-- Right: Core App Feature Ratings Tags -->
        <div class="response-features-card">
          <div class="features-header-row">
            <div class="response-card-title">⚡ Core App Feature Ratings</div>
            <div class="response-pill-sub">Live Beta Averages</div>
          </div>
          <p class="features-card-desc">Average ratings based on responses submitted by verified closed beta testers:</p>
          
          <div class="feature-rating-tags-grid">
            <div class="feature-tag-chip">
              <span class="ft-icon">⚡</span>
              <span class="ft-name">NLP Receipt Extraction</span>
              <span class="ft-score" id="avg_nlp_ocr">4.9 ★</span>
            </div>
            <div class="feature-tag-chip">
              <span class="ft-icon">🗄️</span>
              <span class="ft-name">Receipt Vault</span>
              <span class="ft-score" id="avg_receipts">4.8 ★</span>
            </div>
            <div class="feature-tag-chip">
              <span class="ft-icon">🛡️</span>
              <span class="ft-name">Warranty Tracker</span>
              <span class="ft-score" id="avg_warranty">4.9 ★</span>
            </div>
            <div class="feature-tag-chip">
              <span class="ft-icon">🔔</span>
              <span class="ft-name">Expiry Reminders</span>
              <span class="ft-score" id="avg_reminders">4.8 ★</span>
            </div>
            <div class="feature-tag-chip">
              <span class="ft-icon">🤖</span>
              <span class="ft-name">AI Assistant</span>
              <span class="ft-score" id="avg_ai_assistant">4.8 ★</span>
            </div>
            <div class="feature-tag-chip">
              <span class="ft-icon">📊</span>
              <span class="ft-name">Financial Analytics</span>
              <span class="ft-score" id="avg_analytics">4.8 ★</span>
            </div>
            <div class="feature-tag-chip">
              <span class="ft-icon">📑</span>
              <span class="ft-name">PDF Generation</span>
              <span class="ft-score" id="avg_pdf">4.9 ★</span>
            </div>
            <div class="feature-tag-chip">
              <span class="ft-icon">💬</span>
              <span class="ft-name">WhatsApp Bot</span>
              <span class="ft-score" id="avg_whatsapp">4.7 ★</span>
            </div>
          </div>
        </div>

      </div>
    </section>

    <!-- Main Form Container -->
    <main class="container" id="feedbackFormContainer">

      <!-- Stepper Navigation -->
      <nav class="stepper-nav" id="stepperNav">
        <button type="button" class="step-pill active" onclick="goToStep(1)">
          <span class="step-num">1</span>
          <span>Tester Profile</span>
        </button>
        <button type="button" class="step-pill" onclick="goToStep(2)">
          <span class="step-num">2</span>
          <span>Overall Experience</span>
        </button>
        <button type="button" class="step-pill" onclick="goToStep(3)">
          <span class="step-num">3</span>
          <span>Feature Deep-Dive</span>
        </button>
        <button type="button" class="step-pill" onclick="goToStep(4)">
          <span class="step-num">4</span>
          <span>UI/UX &amp; Bugs</span>
        </button>
        <button type="button" class="step-pill" onclick="goToStep(5)">
          <span class="step-num">5</span>
          <span>Suggestions &amp; Review</span>
        </button>
      </nav>

      <!-- Multi-Step Form -->
      <form id="betaFeedbackForm" onsubmit="handleFormSubmit(event)">

        <!-- STEP 1: TESTER INFORMATION -->
        <div class="section-card active" id="step1Card">
          <div class="section-header">
            <span class="section-tag">Step 1 of 5</span>
            <h2 class="section-title">Tester Information</h2>
            <p class="section-desc">Provide your test environment details so we can correlate performance metrics.</p>
          </div>

          <div class="form-grid-2">
            <div class="form-group">
              <label class="field-label" for="testerName">Full Name<span class="req-star">*</span></label>
              <input type="text" id="testerName" placeholder="e.g. Milanraj Kunder" required>
            </div>
            <div class="form-group">
              <label class="field-label" for="testerEmail">Email Address<span class="req-star">*</span></label>
              <input type="email" id="testerEmail" placeholder="your@email.com" required>
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-group">
              <label class="field-label" for="deviceModel">Device Brand &amp; Model<span class="req-star">*</span></label>
              <input type="text" id="deviceModel" placeholder="e.g. OnePlus 11, Samsung S24, Pixel 8" required>
            </div>
            <div class="form-group">
              <label class="field-label" for="androidVersion">Android OS Version<span class="req-star">*</span></label>
              <select id="androidVersion" required>
                <option value="">Select Android OS Version</option>
                <option value="Android 10">Android 10</option>
                <option value="Android 11">Android 11</option>
                <option value="Android 12">Android 12</option>
                <option value="Android 12L">Android 12L</option>
                <option value="Android 13">Android 13</option>
                <option value="Android 14" selected>Android 14</option>
                <option value="Android 15">Android 15</option>
                <option value="Android 16">Android 16</option>
                <option value="Android 17">Android 17</option>
                <option value="Other / Not Sure">Other / Not Sure</option>
              </select>
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-group">
              <label class="field-label" for="appVersion">Receipto App Version</label>
              <input type="text" id="appVersion" value="1.0.0 (Build 1)" readonly style="color: var(--accent-cyan); font-family: 'JetBrains Mono', monospace;">
            </div>
            <div class="form-group">
              <label class="field-label" for="testingDuration">Testing Duration<span class="req-star">*</span></label>
              <select id="testingDuration" required>
                <option value="">Select Testing Duration</option>
                <option value="Less than one day">Less than one day</option>
                <option value="1–3 days" selected>1–3 days</option>
                <option value="4–7 days">4–7 days</option>
                <option value="1–2 weeks">1–2 weeks</option>
                <option value="More than two weeks">More than two weeks</option>
              </select>
            </div>
          </div>

          <div class="form-btn-bar">
            <div></div>
            <button type="button" class="btn-next" onclick="validateAndGoStep(1, 2)">
              <span>Next: Overall Experience</span>
              <span>→</span>
            </button>
          </div>
        </div>

        <!-- STEP 2: OVERALL EXPERIENCE & NLP-BASED RECEIPT EXTRACTION -->
        <div class="section-card" id="step2Card">
          <div class="section-header">
            <span class="section-tag">Step 2 of 5</span>
            <h2 class="section-title">Overall Experience</h2>
            <p class="section-desc">Rate your personal experience and evaluate our automated receipt data extraction.</p>
          </div>

          <!-- Overall Experience 5-Star Rating (The Giving Part) -->
          <div class="star-rating-box">
            <div class="star-box-title">How would you rate your overall experience with Receipto?<span class="req-star">*</span></div>
            <div class="star-row" id="overallStarsGroup">
              <button type="button" class="star-btn active" data-val="1" aria-label="1 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              <button type="button" class="star-btn active" data-val="2" aria-label="2 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              <button type="button" class="star-btn active" data-val="3" aria-label="3 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              <button type="button" class="star-btn active" data-val="4" aria-label="4 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              <button type="button" class="star-btn active" data-val="5" aria-label="5 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
            </div>
            <div class="star-desc-text" id="overallStarsDesc">5/5 – Excellent 🔥</div>
            <input type="hidden" id="overallRating" value="5">
          </div>

          <!-- Ease of Use Question -->
          <div class="form-group">
            <label class="field-label">How easy was Receipto to use?<span class="req-star">*</span></label>
            <div class="choice-chips-grid" id="easeOfUseGroup">
              <div class="choice-chip selected" data-val="Very Easy" onclick="selectChoice('easeOfUseGroup', this)">Very Easy</div>
              <div class="choice-chip" data-val="Easy" onclick="selectChoice('easeOfUseGroup', this)">Easy</div>
              <div class="choice-chip" data-val="Neutral" onclick="selectChoice('easeOfUseGroup', this)">Neutral</div>
              <div class="choice-chip" data-val="Difficult" onclick="selectChoice('easeOfUseGroup', this)">Difficult</div>
              <div class="choice-chip" data-val="Very Difficult" onclick="selectChoice('easeOfUseGroup', this)">Very Difficult</div>
            </div>
            <input type="hidden" id="easeOfUseInput" value="Very Easy">
          </div>

          <!-- FEATURE 1: NLP-BASED RECEIPT PROCESSING -->
          <div class="feature-card" style="margin-top: 24px; border-color: rgba(0, 217, 255, 0.28);">
            <div class="feature-card-header">
              <div class="feature-card-title">
                <span>⚡</span>
                <span>NLP-Based Receipt Processing</span>
              </div>
              <span style="font-size: 11px; background: rgba(0, 217, 255, 0.12); color: var(--accent-cyan); padding: 3px 8px; border-radius: 6px; font-weight: 700;">PaddleOCR + NLP</span>
            </div>
            <p class="feature-card-desc">
              Evaluate how effectively Receipto recognizes receipt text using PaddleOCR and processes the extracted information into structured receipt data (merchant name, invoice number, purchase date, total amount, line items, quantities, and prices).
            </p>

            <div class="form-group">
              <label class="field-label">How accurate was the receipt information extracted by Receipto?<span class="req-star">*</span></label>
              <div class="feature-rate-row">
                <div class="feature-stars" data-feature="nlp_ocr" id="nlpStars">
                  <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                  <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                  <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                  <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                  <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                </div>
                <span id="nlpStarsLabel" style="font-size: 12.5px; font-weight: 700; color: var(--accent-cyan);">5.0 / 5.0</span>
                <label class="not-tested-toggle">
                  <input type="checkbox" onchange="toggleNotTested('nlp_ocr', this)"> Not Tested
                </label>
              </div>
            </div>

            <div class="form-group" style="margin-top: 14px;">
              <label class="field-label">Did you need to manually correct any extracted information?<span class="req-star">*</span></label>
              <div class="choice-chips-grid" id="manualCorrectionGroup">
                <div class="choice-chip" data-val="Never" onclick="selectChoice('manualCorrectionGroup', this)">Never</div>
                <div class="choice-chip selected" data-val="Rarely" onclick="selectChoice('manualCorrectionGroup', this)">Rarely</div>
                <div class="choice-chip" data-val="Sometimes" onclick="selectChoice('manualCorrectionGroup', this)">Sometimes</div>
                <div class="choice-chip" data-val="Frequently" onclick="selectChoice('manualCorrectionGroup', this)">Frequently</div>
                <div class="choice-chip" data-val="Almost Every Time" onclick="selectChoice('manualCorrectionGroup', this)">Almost Every Time</div>
              </div>
              <input type="hidden" id="manualCorrectionInput" value="Rarely">
            </div>

            
          </div>

          <div class="form-btn-bar">
            <button type="button" class="btn-prev" onclick="goToStep(1)">← Previous</button>
            <button type="button" class="btn-next" onclick="goToStep(3)">
              <span>Next: Feature Deep-Dive</span>
              <span>→</span>
            </button>
          </div>
        </div>

        <!-- STEP 3: INDIVIDUAL FEATURE EVALUATIONS -->
        <div class="section-card" id="step3Card">
          <div class="section-header">
            <span class="section-tag">Step 3 of 5</span>
            <h2 class="section-title">Feature-by-Feature Evaluation</h2>
            <p class="section-desc">Rate each module you had an opportunity to test. Select "Not Tested" for unused features.</p>
          </div>

          <!-- FEATURE 2: RECEIPT MANAGEMENT -->
          <div class="feature-card">
            <div class="feature-card-header">
              <div class="feature-card-title"><span>🗄️</span> Receipt Management</div>
            </div>
            <p class="feature-card-desc">Evaluate receipt history, category filtering, search speed, duplicate receipt detection, sorting, and invoice details view.</p>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="receipts" id="stars_receipts">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_receipts" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
              <label class="not-tested-toggle">
                <input type="checkbox" onchange="toggleNotTested('receipts', this)"> Not Tested
              </label>
            </div>
            
          </div>

          <!-- FEATURE 3: WARRANTY TRACKING -->
          <div class="feature-card">
            <div class="feature-card-header">
              <div class="feature-card-title"><span>🛡️</span> Warranty Tracking</div>
            </div>
            <p class="feature-card-desc">Evaluate automated warranty detection, expiration date calculations, manual warranty entry, active vs. expired lists, and brand customer support information.</p>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="warranty" id="stars_warranty">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_warranty" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
              <label class="not-tested-toggle">
                <input type="checkbox" onchange="toggleNotTested('warranty', this)"> Not Tested
              </label>
            </div>
            
          </div>

          <!-- FEATURE 4: WARRANTY REMINDERS -->
          <div class="feature-card">
            <div class="feature-card-header">
              <div class="feature-card-title"><span>🔔</span> Warranty Reminders &amp; Alerts</div>
            </div>
            <p class="feature-card-desc">Evaluate on-device local notifications, transactional email alerts, notification timing (T-30, T-7, T-1 days), and delivery reliability.</p>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="reminders" id="stars_reminders">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_reminders" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
              <label class="not-tested-toggle">
                <input type="checkbox" onchange="toggleNotTested('reminders', this)"> Not Tested
              </label>
            </div>
            
          </div>

          <!-- FEATURE 5: AI FINANCIAL ASSISTANT -->
          <div class="feature-card">
            <div class="feature-card-header">
              <div class="feature-card-title"><span>🤖</span> Conversational AI Financial Assistant</div>
            </div>
            <p class="feature-card-desc">Evaluate the interactive in-app conversational assistant for answering questions about your past receipts, itemized line items, warranties, and category spending.</p>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="ai_assistant" id="stars_ai_assistant">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_ai_assistant" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
              <label class="not-tested-toggle">
                <input type="checkbox" onchange="toggleNotTested('ai_assistant', this)"> Not Tested
              </label>
            </div>
            
          </div>

          <!-- FEATURE 6: EXPENSE ANALYTICS & BUDGETING -->
          <div class="feature-card">
            <div class="feature-card-header">
              <div class="feature-card-title"><span>📊</span> Expense Analytics &amp; Budgeting</div>
            </div>
            <p class="feature-card-desc">Evaluate monthly expenditure overviews, category breakdown charts, spending velocity, budget tracking thresholds, and financial insights.</p>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="analytics" id="stars_analytics">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_analytics" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
              <label class="not-tested-toggle">
                <input type="checkbox" onchange="toggleNotTested('analytics', this)"> Not Tested
              </label>
            </div>
            
          </div>

          <!-- FEATURE 7: PDF GENERATION & EXPORT -->
          <div class="feature-card">
            <div class="feature-card-header">
              <div class="feature-card-title"><span>📑</span> PDF Generation &amp; Export</div>
            </div>
            <p class="feature-card-desc">Evaluate vector PDF invoice generation, document layout, tax and line-item clarity, built-in PDF viewer, and export/sharing experience.</p>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="pdf" id="stars_pdf">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_pdf" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
              <label class="not-tested-toggle">
                <input type="checkbox" onchange="toggleNotTested('pdf', this)"> Not Tested
              </label>
            </div>
            
          </div>

          <!-- FEATURE 8: WHATSAPP INTEGRATION -->
          <div class="feature-card">
            <div class="feature-card-header">
              <div class="feature-card-title"><span>💬</span> WhatsApp Bot Integration</div>
            </div>
            <p class="feature-card-desc">Evaluate forwarding bill photos and PDF receipts over WhatsApp, automated message recognition, and synchronization to your mobile dashboard.</p>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="whatsapp" id="stars_whatsapp">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_whatsapp" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
              <label class="not-tested-toggle">
                <input type="checkbox" id="check_whatsapp_not_tested" onchange="toggleNotTested('whatsapp', this)"> Not Tested
              </label>
            </div>
            
          </div>

          <div class="form-btn-bar">
            <button type="button" class="btn-prev" onclick="goToStep(2)">← Previous</button>
            <button type="button" class="btn-next" onclick="goToStep(4)">
              <span>Next: UI/UX &amp; Bugs</span>
              <span>→</span>
            </button>
          </div>
        </div>

        <!-- STEP 4: UI/UX, PERFORMANCE & BUG REPORTING -->
        <div class="section-card" id="step4Card">
          <div class="section-header">
            <span class="section-tag">Step 4 of 5</span>
            <h2 class="section-title">UI/UX &amp; Performance Evaluation</h2>
            <p class="section-desc">Assess the interface quality, responsiveness, stability, and report any encountered bugs.</p>
          </div>

          <!-- UI/UX Star Ratings -->
          <div class="form-group">
            <label class="field-label">Interface &amp; Visual Design (1–5 Stars)<span class="req-star">*</span></label>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="ui_design" id="stars_ui_design">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_ui_design" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
            </div>
          </div>

          <div class="form-group">
            <label class="field-label">Navigation &amp; Flow (1–5 Stars)<span class="req-star">*</span></label>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="ui_nav" id="stars_ui_nav">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_ui_nav" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
            </div>
          </div>

          <div class="form-group">
            <label class="field-label">Application Responsiveness &amp; Speed (1–5 Stars)<span class="req-star">*</span></label>
            <div class="feature-rate-row">
              <div class="feature-stars" data-feature="ui_speed" id="stars_ui_speed">
                <button type="button" class="feat-star active" data-val="1" aria-label="1 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="2" aria-label="2 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="3" aria-label="3 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="4" aria-label="4 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="feat-star active" data-val="5" aria-label="5 stars"><svg class="feat-star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <span id="label_ui_speed" style="font-size: 12px; font-weight: 700; color: var(--accent-cyan);">5.0 ★</span>
            </div>
          </div>

          <!-- Stability Questions -->
          <div class="form-grid-2" style="margin-top: 20px;">
            <div class="form-group">
              <label class="field-label">Did the application crash?<span class="req-star">*</span></label>
              <select id="crashFrequency" required>
                <option value="Never" selected>Never</option>
                <option value="Once">Once</option>
                <option value="Occasionally">Occasionally</option>
                <option value="Frequently">Frequently</option>
              </select>
            </div>
            <div class="form-group">
              <label class="field-label">Did you experience loading delays?<span class="req-star">*</span></label>
              <select id="delayFrequency" required>
                <option value="Never" selected>Never</option>
                <option value="Rarely">Rarely</option>
                <option value="Sometimes">Sometimes</option>
                <option value="Frequently">Frequently</option>
              </select>
            </div>
          </div>

          <!-- CONDITIONAL BUG REPORTING -->
          <div style="margin-top: 26px; border-top: 1px solid rgba(255,255,255,0.06); padding-top: 18px;">
            <label class="field-label" style="font-size: 14px; margin-bottom: 8px;">
              <span>🐛 Did you encounter any bugs or unexpected behaviour?</span>
              <span class="req-star">*</span>
            </label>
            <div class="choice-chips-grid" id="hasBugGroup" style="grid-template-columns: 1fr 1fr; max-width: 320px;">
              <div class="choice-chip" data-val="Yes" onclick="selectBugChoice(true, this)">Yes</div>
              <div class="choice-chip selected" data-val="No" onclick="selectBugChoice(false, this)">No</div>
            </div>
            <input type="hidden" id="hasBugInput" value="No">

            <!-- Revealed Bug Form Fields -->
            <div class="bug-box" id="bugReportBox">
              <div style="font-weight: 800; font-size: 14px; color: #f87171; margin-bottom: 14px; display: flex; align-items: center; gap: 6px;">
                <span>⚠️</span> Bug Diagnostic Details
              </div>
              <div class="form-group">
                <label class="field-label">Feature where issue occurred</label>
                <select id="bugFeature">
                  <option value="NLP Receipt Scanner">NLP Receipt Scanner / Camera</option>
                  <option value="Preview & Save Screen">Preview &amp; Save Screen</option>
                  <option value="Receipts Archive & Details">Receipts Archive &amp; Details</option>
                  <option value="Warranty Tracker & Calendar">Warranty Tracker &amp; Calendar</option>
                  <option value="Warranty Reminders">Warranty Reminders / Notifications</option>
                  <option value="AI Financial Assistant">AI Financial Assistant</option>
                  <option value="Analytics & Budgets">Analytics &amp; Budgets</option>
                  <option value="PDF Generation">PDF Generation / Sharing</option>
                  <option value="App Lock / Security">App Lock / Biometrics</option>
                  <option value="Other">Other UI Glitch</option>
                </select>
              </div>
              <div class="form-group">
                <label class="field-label">Describe the problem</label>
                <textarea id="bugDescription" placeholder="What happened?"></textarea>
              </div>
              <div class="form-group">
                <label class="field-label">Steps to reproduce</label>
                <textarea id="bugSteps" placeholder="1. Tap scan button&#10;2. Upload receipt&#10;3. Observe crash"></textarea>
              </div>
              <div class="form-grid-2">
                <div class="form-group">
                  <label class="field-label">Expected behaviour</label>
                  <input type="text" id="bugExpected" placeholder="e.g. Save successfully">
                </div>
                <div class="form-group">
                  <label class="field-label">Actual behaviour</label>
                  <input type="text" id="bugActual" placeholder="e.g. Blank screen">
                </div>
              </div>
              <div class="form-grid-2">
                <div class="form-group">
                  <label class="field-label">Frequency</label>
                  <select id="bugOccurs">
                    <option value="Every Time">Every Time</option>
                    <option value="Often">Often</option>
                    <option value="Rarely / Once">Rarely / Once</option>
                  </select>
                </div>
                <div class="form-group">
                  <label class="field-label">Severity Level</label>
                  <select id="bugSeverity">
                    <option value="Low">Low (Visual cosmetic issue)</option>
                    <option value="Medium" selected>Medium (Feature partially broken)</option>
                    <option value="High">High (Core feature unusable)</option>
                    <option value="Critical">Critical (App crash / Data loss)</option>
                  </select>
                </div>
              </div>
            </div>
          </div>

          <div class="form-btn-bar">
            <button type="button" class="btn-prev" onclick="goToStep(3)">← Previous</button>
            <button type="button" class="btn-next" onclick="goToStep(5)">
              <span>Next: Suggestions &amp; Review</span>
              <span>→</span>
            </button>
          </div>
        </div>

        <!-- STEP 5: SUGGESTIONS, FINAL SATISFACTION & SUBMISSION -->
        <div class="section-card" id="step5Card">
          <div class="section-header">
            <span class="section-tag">Step 5 of 5</span>
            <h2 class="section-title">Suggestions &amp; Final Evaluation</h2>
            <p class="section-desc">Your candid insights help prioritize the roadmap before the Play Store launch.</p>
          </div>

          <div class="form-group">
            <label class="field-label">What is your favourite feature in Receipto?<span class="req-star">*</span></label>
            <input type="text" id="favFeature" placeholder="e.g. Instant warranty duration tracking, offline mode, clean cyber UI..." required>
          </div>

          <div class="form-group">
            <label class="field-label">Which feature impressed you the most?<span class="opt-badge">(Optional)</span></label>
            <input type="text" id="impressedFeature" placeholder="e.g. PaddleOCR speed, claim dispatcher with brand toll-free numbers...">
          </div>

          <div class="form-group">
            <label class="field-label">What would you improve before the official launch?<span class="req-star">*</span></label>
            <textarea id="improvements" placeholder="Any UI clunkiness, missing merchant categories, or notification adjustments..." required></textarea>
          </div>

          <div class="form-group">
            <label class="field-label">What additional functionality would you like to see in future updates?<span class="opt-badge">(Optional)</span></label>
            <textarea id="futureWishes" placeholder="e.g. Multi-currency converter, family receipt sharing, automated bank SMS sync..."></textarea>
          </div>

          <!-- Final Ratings -->
          <div style="margin-top: 24px; padding-top: 20px; border-top: 1px solid rgba(255,255,255,0.06);">
            <div class="star-rating-box" style="margin-bottom: 16px;">
              <div class="star-box-title">Overall Satisfaction with Receipto (1–5 Stars)</div>
              <div class="star-row" id="finalSatStarsGroup">
                <button type="button" class="star-btn active" data-val="1" aria-label="1 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="star-btn active" data-val="2" aria-label="2 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="star-btn active" data-val="3" aria-label="3 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="star-btn active" data-val="4" aria-label="4 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
                <button type="button" class="star-btn active" data-val="5" aria-label="5 stars"><svg class="star-svg" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg></button>
              </div>
              <div class="star-desc-text" id="finalSatDesc">5 Stars – Very Satisfied 🔥</div>
              <input type="hidden" id="finalSatRating" value="5">
            </div>

            <div class="form-group">
              <label class="field-label">Will you continue using Receipto after its official launch?<span class="req-star">*</span></label>
              <select id="continueUsing" required>
                <option value="Definitely Yes" selected>Definitely Yes</option>
                <option value="Probably Yes">Probably Yes</option>
                <option value="Not Sure">Not Sure</option>
                <option value="Probably Not">Probably Not</option>
                <option value="Definitely Not">Definitely Not</option>
              </select>
            </div>

            <div class="form-group">
              <label class="field-label">Any additional message for the Receipto development team?<span class="opt-badge">(Optional)</span></label>
              <textarea id="devMessage" placeholder="Notes, cheers, or feedback for Milanraj and the team..."></textarea>
            </div>
          </div>

          <div class="form-btn-bar">
            <button type="button" class="btn-prev" onclick="goToStep(4)">← Previous</button>
            <button type="submit" class="btn-next btn-submit" id="submitBtn">
              <span>SUBMIT FEEDBACK</span>
              <span>🚀</span>
            </button>
          </div>
        </div>

      </form>

      <!-- SUCCESS EXPERIENCE CARD -->
      <div class="success-card" id="successCard">
        <div class="success-icon-badge">🎉</div>
        <h2 class="success-title">THANK YOU FOR BEING PART OF RECEIPTO!</h2>
        <p class="success-subtitle">
          Your feedback has been successfully submitted.<br>
          Every suggestion and rating helps us improve Receipto before the official Google Play Store release.
        </p>
        <div style="display: flex; justify-content: center; gap: 12px; flex-wrap: wrap;">
          <button type="button" class="hero-cta-btn" onclick="resetFormToStart()">
            <span>Submit Another Feedback</span>
          </button>
          <button type="button" class="btn-prev" onclick="scrollToCommunity()">
            <span>View Community Wall</span>
          </button>
        </div>
      </div>

      <!-- COMMUNITY FEEDBACK WALL -->
      <section class="community-wall-section" id="communityWall">
        <div class="community-header">
          <div class="community-title">
            <span>🌟</span>
            <span>Beta Testers Community Wall</span>
          </div>
          <div class="wall-stats-badge" id="wallStatsBadge">
            ★ <span id="wallAvgRating">5.0</span> (<span id="wallCount">0</span> Reviews)
          </div>
        </div>
        <div class="wall-feed-list" id="communityFeedList">
          <!-- Rendered live via JS -->
        </div>
      </section>

    </main>
  </div>

  <!-- Toast Notification -->
  <div class="toast" id="toast">
    <span style="font-size: 20px;" id="toastIcon">🎉</span>
    <div>
      <div id="toastTitle" style="font-weight: 700; color: #fff;">Success</div>
      <div id="toastDesc" style="font-size: 12px; color: var(--text-secondary);">Operation completed</div>
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

    // --- 2. Supabase Cloud Connection & Local Storage Fallback ---
    const SUPABASE_URL = 'https://ykqzefulvpqfiwsddnqt.supabase.co';
    const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcXplZnVsdnBxZml3c2RkbnF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTI2NTcsImV4cCI6MjA5ODMyODY1N30.NFm5dT7vVeHtziEkYWN-qk8ZEogpktPZ7NTmXDLO1Qs';
    let supabaseClient = null;
    try {{
      supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
    }} catch(e) {{
      console.log('Supabase offline fallback:', e);
    }}

    // Local Feedbacks In-Memory & LocalStorage Cache
    let feedbackRecords = [];
    const savedLocal = localStorage.getItem('receipto_feedbacks');
    if (savedLocal) {{
      try {{ feedbackRecords = JSON.parse(savedLocal); }} catch(e) {{}}
    }}

    // --- 3. Stepper Navigation Controller ---
    let currentStep = 1;
    function goToStep(step) {{
      currentStep = step;
      document.querySelectorAll('.section-card').forEach((card, idx) => {{
        card.classList.toggle('active', (idx + 1) === step);
      }});
      document.querySelectorAll('.step-pill').forEach((pill, idx) => {{
        pill.classList.toggle('active', (idx + 1) === step);
        pill.classList.toggle('completed', (idx + 1) < step);
      }});
      const activeCard = document.getElementById('step' + step + 'Card');
      if (activeCard && step > 1) {{
        activeCard.scrollIntoView({{ behavior: 'smooth', block: 'start' }});
      }} else {{
        const container = document.getElementById('feedbackFormContainer');
        container.scrollIntoView({{ behavior: 'smooth', block: 'start' }});
      }}
    }}

    // --- Field Validation & Error Highlighting Helpers ---
    function highlightField(el, msg) {{
      if (!el) return;
      el.classList.add('input-error');

      const parent = el.parentElement;
      const oldErr = parent.querySelector('.field-error-text');
      if (oldErr) oldErr.remove();

      const errEl = document.createElement('div');
      errEl.className = 'field-error-text';
      errEl.innerHTML = `<span>⚠️</span> <span>${{msg || 'This field is required'}}</span>`;
      parent.appendChild(errEl);

      const clearError = () => {{
        el.classList.remove('input-error');
        const e = parent.querySelector('.field-error-text');
        if (e) e.remove();
        el.removeEventListener('input', clearError);
        el.removeEventListener('change', clearError);
      }};
      el.addEventListener('input', clearError);
      el.addEventListener('change', clearError);
    }}

    function clearFieldErrors(container) {{
      const root = container || document;
      root.querySelectorAll('.input-error').forEach(el => el.classList.remove('input-error'));
      root.querySelectorAll('.field-error-text').forEach(el => el.remove());
    }}

    function validateAndGoStep(fromStep, toStep) {{
      if (fromStep === 1) {{
        clearFieldErrors(document.getElementById('step1Card'));
        const nameEl = document.getElementById('testerName');
        const emailEl = document.getElementById('testerEmail');
        const deviceEl = document.getElementById('deviceModel');
        const androidEl = document.getElementById('androidVersion');
        const durationEl = document.getElementById('testingDuration');

        let firstInvalid = null;

        if (!nameEl.value.trim()) {{
          highlightField(nameEl, 'Please enter your full name');
          firstInvalid = firstInvalid || nameEl;
        }}
        if (!emailEl.value.trim() || !emailEl.value.includes('@')) {{
          highlightField(emailEl, 'Please enter a valid email address');
          firstInvalid = firstInvalid || emailEl;
        }}
        if (!deviceEl.value.trim()) {{
          highlightField(deviceEl, 'Please enter your phone brand and model');
          firstInvalid = firstInvalid || deviceEl;
        }}
        if (!androidEl.value) {{
          highlightField(androidEl, 'Please select your Android OS version');
          firstInvalid = firstInvalid || androidEl;
        }}
        if (!durationEl.value) {{
          highlightField(durationEl, 'Please select your testing duration');
          firstInvalid = firstInvalid || durationEl;
        }}

        if (firstInvalid) {{
          firstInvalid.focus();
          firstInvalid.scrollIntoView({{ behavior: 'smooth', block: 'center' }});
          showToast('Incomplete Fields', 'Please complete the highlighted required fields.', '⚠️');
          return;
        }}
      }}
      goToStep(toStep);
    }}

    function scrollToForm() {{
      document.getElementById('feedbackFormContainer').scrollIntoView({{ behavior: 'smooth' }});
    }}
    function scrollToCommunity() {{
      document.getElementById('communityWall').scrollIntoView({{ behavior: 'smooth' }});
    }}

    // Choice Chips Selection Helper
    function selectChoice(groupId, element) {{
      const group = document.getElementById(groupId);
      group.querySelectorAll('.choice-chip').forEach(c => c.classList.remove('selected'));
      element.classList.add('selected');
      const val = element.getAttribute('data-val');
      if (groupId === 'easeOfUseGroup') {{
        document.getElementById('easeOfUseInput').value = val;
      }} else if (groupId === 'manualCorrectionGroup') {{
        document.getElementById('manualCorrectionInput').value = val;
      }}
    }}

    function selectBugChoice(hasBug, element) {{
      document.querySelectorAll('#hasBugGroup .choice-chip').forEach(c => c.classList.remove('selected'));
      element.classList.add('selected');
      document.getElementById('hasBugInput').value = hasBug ? 'Yes' : 'No';
      const box = document.getElementById('bugReportBox');
      if (hasBug) {{
        box.classList.add('show');
      }} else {{
        box.classList.remove('show');
      }}
    }}

    // --- 4. Interactive Five-Star Rating Components ---
    const starDescriptions = {{
      1: '1/5 – Poor ⚠️',
      2: '2/5 – Fair 😐',
      3: '3/5 – Good 👍',
      4: '4/5 – Very Good 🚀',
      5: '5/5 – Excellent 🔥'
    }};

    function setupStarRating(groupEl, descEl, inputEl) {{
      const stars = groupEl.querySelectorAll('.star-btn');
      stars.forEach(s => {{
        const handleTap = (e) => {{
          if (e.cancelable) e.preventDefault();
          e.stopPropagation();
          const val = parseInt(s.getAttribute('data-val'));
          inputEl.value = val;
          stars.forEach(st => st.classList.toggle('active', parseInt(st.getAttribute('data-val')) <= val));
          if (descEl) descEl.innerText = starDescriptions[val] || `${{val}} Stars`;
        }};
        s.addEventListener('pointerdown', handleTap, {{ passive: false }});
        s.addEventListener('touchstart', handleTap, {{ passive: false }});
        s.addEventListener('click', handleTap);
      }});
    }}

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
    const featureScores = {{
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
    }};

    document.querySelectorAll('.feature-stars').forEach(group => {{
      const featKey = group.getAttribute('data-feature');
      const stars = group.querySelectorAll('.feat-star');
      const labelEl = document.getElementById('label_' + featKey) || document.getElementById('nlpStarsLabel');

      stars.forEach(s => {{
        const handleTap = (e) => {{
          if (e.cancelable) e.preventDefault();
          e.stopPropagation();
          const val = parseInt(s.getAttribute('data-val'));
          featureScores[featKey] = val;
          stars.forEach(st => st.classList.toggle('active', parseInt(st.getAttribute('data-val')) <= val));
          if (labelEl) labelEl.innerText = `${{val.toFixed(1)}} ★`;
        }};
        s.addEventListener('pointerdown', handleTap, {{ passive: false }});
        s.addEventListener('touchstart', handleTap, {{ passive: false }});
        s.addEventListener('click', handleTap);
      }});
    }});

    function toggleNotTested(featKey, checkbox) {{
      const group = document.querySelector(`.feature-stars[data-feature="${{featKey}}"]`);
      const labelEl = document.getElementById('label_' + featKey) || document.getElementById('nlpStarsLabel');
      if (checkbox.checked) {{
        featureScores[featKey] = null;
        if (group) group.querySelectorAll('.feat-star').forEach(s => s.classList.remove('active'));
        if (labelEl) labelEl.innerText = 'Not Tested';
      }} else {{
        featureScores[featKey] = 5;
        if (group) group.querySelectorAll('.feat-star').forEach(s => s.classList.add('active'));
        if (labelEl) labelEl.innerText = '5.0 ★';
      }}
    }}

    // --- 5. Form Submission Handler ---
    async function handleFormSubmit(e) {{
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

      if (!favEl.value.trim()) {{
        highlightField(favEl, 'Please tell us your favourite feature');
        firstInvalid = firstInvalid || favEl;
      }}
      if (!impEl.value.trim()) {{
        highlightField(impEl, 'Please tell us what we can improve before launch');
        firstInvalid = firstInvalid || impEl;
      }}
      if (hasBug) {{
        const bugDesc = document.getElementById('bugDescription');
        if (!bugDesc.value.trim()) {{
          highlightField(bugDesc, 'Please describe the bug encountered');
          firstInvalid = firstInvalid || bugDesc;
        }}
      }}

      if (firstInvalid) {{
        firstInvalid.focus();
        firstInvalid.scrollIntoView({{ behavior: 'smooth', block: 'center' }});
        showToast('Incomplete Fields', 'Please complete the highlighted feedback questions.', '⚠️');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span>SUBMIT FEEDBACK</span><span>🚀</span>';
        return;
      }}

      const formData = {{
        id: 'rev-' + Date.now(),
        name: document.getElementById('testerName').value.trim(),
        email: document.getElementById('testerEmail').value.trim(),
        device: `${{document.getElementById('deviceModel').value.trim()}} (${{document.getElementById('androidVersion').value}})`,
        rating: parseInt(document.getElementById('overallRating').value) || 5,
        easeOfUse: document.getElementById('easeOfUseInput').value,
        appVersion: document.getElementById('appVersion').value,
        testingDuration: document.getElementById('testingDuration').value,
        features: {{ ...featureScores }},
        manualCorrection: document.getElementById('manualCorrectionInput').value,
        comments: {{
          nlp_ocr: document.getElementById('comment_nlp_ocr').value.trim(),
          receipts: document.getElementById('comment_receipts').value.trim(),
          warranty: document.getElementById('comment_warranty').value.trim(),
          reminders: document.getElementById('comment_reminders').value.trim(),
          ai_assistant: document.getElementById('comment_ai_assistant').value.trim(),
          analytics: document.getElementById('comment_analytics').value.trim(),
          pdf: document.getElementById('comment_pdf').value.trim(),
          whatsapp: document.getElementById('comment_whatsapp').value.trim()
        }},
        uiUx: {{
          design: featureScores.ui_design || 5,
          nav: featureScores.ui_nav || 5,
          speed: featureScores.ui_speed || 5,
          crashFrequency: document.getElementById('crashFrequency').value,
          delayFrequency: document.getElementById('delayFrequency').value
        }},
        hasBug: hasBug,
        bugReport: hasBug ? {{
          feature: document.getElementById('bugFeature').value,
          description: document.getElementById('bugDescription').value.trim(),
          steps: document.getElementById('bugSteps').value.trim(),
          expected: document.getElementById('bugExpected').value.trim(),
          actual: document.getElementById('bugActual').value.trim(),
          frequency: document.getElementById('bugOccurs').value,
          severity: document.getElementById('bugSeverity').value
        }} : null,
        suggestions: {{
          favFeature: document.getElementById('favFeature').value.trim(),
          impressedFeature: document.getElementById('impressedFeature').value.trim(),
          improvements: document.getElementById('improvements').value.trim(),
          futureWishes: document.getElementById('futureWishes').value.trim()
        }},
        finalEvaluation: {{
          overallSatisfaction: parseInt(document.getElementById('finalSatRating').value) || 5,
          continueUsing: document.getElementById('continueUsing').value,
          devMessage: document.getElementById('devMessage').value.trim()
        }},
        date: new Date().toLocaleDateString('en-US', {{ month: 'short', day: 'numeric', year: 'numeric' }}),
        helpful: 0
      }};

      // Message summary for fallback
      formData.message = formData.suggestions.favFeature
        ? `★ Favourite: "${{formData.suggestions.favFeature}}". Improve: "${{formData.suggestions.improvements}}"`
        : `Overall Experience: ${{formData.rating}}/5. Testing duration: ${{formData.testingDuration}}.`;

      // 1. Submit Full Payload to Supabase Cloud
      if (supabaseClient) {{
        try {{
          const cloudPayload = {{
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
          }};

          await supabaseClient.from('feedbacks').insert([{{
            name: formData.name,
            email: formData.email,
            device: formData.device,
            rating: formData.rating,
            message: JSON.stringify(cloudPayload),
            features: formData.features,
            tags: [
              `v${{formData.appVersion.split(' ')[0]}}`,
              formData.testingDuration,
              hasBug ? '⚠️ Bug Logged' : '✅ Smooth'
            ]
          }}]);
        }} catch(err) {{
          console.log('Supabase sync note:', err);
        }}
      }}

      // 2. Add to Local Storage and Cache
      feedbackRecords.unshift(formData);
      localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
      renderCommunityFeed();
      renderAdminResponses();

      // 3. Show Celebration & Success View
      if (window.confetti) {{
        window.confetti({{ particleCount: 120, spread: 80, origin: {{ y: 0.6 }} }});
      }}

      document.getElementById('betaFeedbackForm').style.display = 'none';
      document.getElementById('stepperNav').style.display = 'none';
      document.getElementById('successCard').classList.add('show');
      document.getElementById('successCard').scrollIntoView({{ behavior: 'smooth' }});

      showToast('Feedback Successfully Submitted!', 'Thank you for shaping Receipto.', '🎉');
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span>SUBMIT FEEDBACK</span><span>🚀</span>';
    }}

    function resetFormToStart() {{
      document.getElementById('betaFeedbackForm').reset();
      document.getElementById('betaFeedbackForm').style.display = 'block';
      document.getElementById('stepperNav').style.display = 'flex';
      document.getElementById('successCard').classList.remove('show');
      goToStep(1);
    }}

    // --- 6. Render Community Wall Feed (Full User Feedback Details) ---
    const featureDisplayNames = {{
      nlp_ocr: '⚡ NLP OCR',
      receipts: '🗄️ Receipts',
      warranty: '🛡️ Warranty',
      reminders: '🔔 Reminders',
      ai_assistant: '🤖 Assistant',
      analytics: '📊 Analytics',
      pdf: '📑 PDF',
      whatsapp: '💬 WhatsApp'
    }};

    window.toggleCardDetails = function(id) {{
      const el = document.getElementById('detailsAccordion_' + id);
      const btn = document.getElementById('detailsToggleBtn_' + id);
      if (el) {{
        const isShown = el.classList.toggle('show');
        if (btn) btn.innerHTML = isShown ? 'Hide Full Diagnostics ▲' : 'View Full Evaluation Details ▼';
      }}
    }};

    function renderCommunityFeed() {{
      const listEl = document.getElementById('communityFeedList');
      listEl.innerHTML = '';

      if (!feedbackRecords || feedbackRecords.length === 0) {{
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
      }}

      let sumRating = 0;
      feedbackRecords.forEach(item => {{
        sumRating += (item.rating || 5);
        const card = document.createElement('div');
        card.className = 'feed-card';
        const initial = (item.name || 'T')[0].toUpperCase();
        const starsText = '★'.repeat(item.rating || 5) + '☆'.repeat(5 - (item.rating || 5));

        const sug = item.suggestions || {{}};
        const fav = sug.favFeature || '';
        const imp = sug.improvements || '';
        const wish = sug.futureWishes || '';
        const impressed = sug.impressedFeature || '';
        const devMsg = (item.finalEvaluation && item.finalEvaluation.devMessage) || sug.devMessage || '';
        const comments = item.comments || {{}};
        const hasBug = item.hasBug || (item.bugReport !== null && item.bugReport !== undefined);
        const bug = item.bugReport || null;
        const ease = item.easeOfUse || 'Very Easy';
        const dur = item.testingDuration || '1–3 days';
        const ver = item.appVersion || '1.0.0 (Build 1)';
        const ocrComment = comments.nlp_ocr || '';

        // Format feature rating tags
        const ft = item.features || {{}};
        const chipsHtml = Object.entries(ft)
          .filter(([k, v]) => v !== null && featureDisplayNames[k])
          .map(([k, v]) => `<span class="feed-feature-chip">${{featureDisplayNames[k]}}: ${{v}}★</span>`)
          .join('');

        card.innerHTML = `
          <div class="feed-top">
            <div class="feed-user">
              <div class="feed-avatar">${{initial}}</div>
              <div>
                <div class="feed-name">${{escapeHtml(item.name)}}</div>
                <div class="feed-meta">${{escapeHtml(item.device || 'Android Tester')}} • ${{item.date || 'Recently'}}</div>
              </div>
            </div>
            <div class="feed-stars-badge">
              <span>${{starsText}}</span>
              <span class="feed-stars-val">${{(item.rating || 5).toFixed(1)}}</span>
            </div>
          </div>

          <!-- Metadata Badges -->
          <div class="feed-meta-chips-row">
            <span class="feed-badge-pill">⏱️ Tested: ${{escapeHtml(dur)}}</span>
            <span class="feed-badge-pill">⚡ Ease: ${{escapeHtml(ease)}}</span>
            ${{hasBug ? `<span class="feed-badge-pill" style="border-color: rgba(239,68,68,0.4); color: #f87171;">⚠️ Bug Logged</span>` : `<span class="feed-badge-pill" style="color: #34d399;">✅ Zero Crashes</span>`}}
          </div>

          <!-- Key Feedback Insights (Full User Details) -->
          <div class="feed-insights-list">
            ${{fav ? `
              <div class="feed-quote-item fav">
                <div class="feed-quote-title fav">❤️ Favourite Feature</div>
                <div>"${{escapeHtml(fav)}}"</div>
              </div>
            ` : ''}}

            ${{imp ? `
              <div class="feed-quote-item imp">
                <div class="feed-quote-title imp">💡 Suggested Improvement</div>
                <div>"${{escapeHtml(imp)}}"</div>
              </div>
            ` : ''}}

            ${{wish ? `
              <div class="feed-quote-item wish">
                <div class="feed-quote-title wish">✨ Future Wishlist</div>
                <div>"${{escapeHtml(wish)}}"</div>
              </div>
            ` : ''}}

            ${{!fav && !imp && item.message ? `
              <div class="feed-quote-item">
                <div>${{escapeHtml(item.message)}}</div>
              </div>
            ` : ''}}
          </div>

          <!-- Evaluated Feature Chips -->
          <div class="feed-meta-chips-row">${{chipsHtml}}</div>

          <!-- Expandable Diagnostics Accordion -->
          <div class="feed-details-accordion" id="detailsAccordion_${{item.id}}">
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 8px; margin-bottom: 8px;">
              <div><strong>App Version:</strong> ${{escapeHtml(ver)}}</div>
              <div><strong>Will Continue:</strong> ${{escapeHtml(sug.continueUsing || (item.finalEvaluation && item.finalEvaluation.continueUsing) || 'Definitely Yes')}}</div>
              ${{impressed ? `<div style="grid-column: 1 / -1;"><strong>Most Impressed:</strong> "${{escapeHtml(impressed)}}"</div>` : ''}}
              ${{ocrComment ? `<div style="grid-column: 1 / -1;"><strong>NLP OCR Note:</strong> "${{escapeHtml(ocrComment)}}"</div>` : ''}}
              ${{devMsg ? `<div style="grid-column: 1 / -1;"><strong>Dev Note:</strong> "${{escapeHtml(devMsg)}}"</div>` : ''}}
            </div>
            ${{hasBug && bug ? `
              <div style="background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); border-radius: 6px; padding: 8px 10px; margin-top: 6px; color: #fca5a5; font-size: 11.5px;">
                <strong>⚠️ Bug Diagnostic:</strong> ${{escapeHtml(bug.feature || 'Feature')}} (${{escapeHtml(bug.severity || 'Medium')}}) – ${{escapeHtml(bug.description || '')}}
              </div>
            ` : ''}}
          </div>

          <button type="button" class="feed-accordion-btn" id="detailsToggleBtn_${{item.id}}" onclick="toggleCardDetails('${{item.id}}')">
            View Full Evaluation Details ▼
          </button>

          <div class="feed-footer">
            <span class="verified-tag">✓ Verified Closed Beta Tester</span>
            <button class="feed-del-btn" onclick="deleteFeedback('${{item.id}}')">🗑️ Delete</button>
          </div>
        `;
        listEl.appendChild(card);
      }});

      const count = feedbackRecords.length;
      document.getElementById('wallAvgRating').innerText = (sumRating / count).toFixed(1);
      document.getElementById('wallCount').innerText = count;

      // Refresh overall response scoreboard below hero
      updateOverallResponseUI();
    }}

    // --- 7. Admin Dedicated Full Responses & Feedback Console ---
    function renderAdminResponses(query = '', filter = 'all') {{
      const listEl = document.getElementById('adminRecordsList');
      if (!listEl) return;
      listEl.innerHTML = '';

      const q = (query || '').toLowerCase().trim();
      let filtered = feedbackRecords.filter(item => {{
        if (filter === '5' && (item.rating || 5) !== 5) return false;
        if (filter === '4' && (item.rating || 5) !== 4) return false;
        if (filter === '3' && (item.rating || 5) > 3) return false;
        if (filter === 'bugs' && !item.hasBug && !item.bugReport) return false;

        if (q) {{
          const str = `${{item.name || ''}} ${{item.email || ''}} ${{item.device || ''}} ${{JSON.stringify(item.suggestions || {{}})}} ${{JSON.stringify(item.bugReport || {{}})}}`.toLowerCase();
          return str.includes(q);
        }}
        return true;
      }});

      // Update counters
      const totalCount = feedbackRecords.length;
      const bugCount = feedbackRecords.filter(x => x.hasBug || x.bugReport).length;
      let sum = 0;
      feedbackRecords.forEach(x => sum += (x.rating || 5));
      const avg = totalCount > 0 ? (sum / totalCount).toFixed(1) : '5.0';

      if (document.getElementById('adminTotalCount')) document.getElementById('adminTotalCount').innerText = totalCount;
      if (document.getElementById('adminAvgScore')) document.getElementById('adminAvgScore').innerText = avg;
      if (document.getElementById('adminBugsCount')) document.getElementById('adminBugsCount').innerText = bugCount;

      if (!filtered || filtered.length === 0) {{
        listEl.innerHTML = `
          <div style="text-align: center; padding: 40px 20px; color: var(--text-muted);">
            <div style="font-size: 32px; margin-bottom: 8px;">🔍</div>
            <div style="font-weight: 700; color: #fff;">No feedback records match your query</div>
            <div style="font-size: 13px;">Clear search filters or wait for beta testers to submit responses.</div>
          </div>
        `;
        return;
      }}

      filtered.forEach(item => {{
        const sug = item.suggestions || {{}};
        const fin = item.finalEvaluation || {{}};
        const fav = sug.favFeature || '';
        const imp = sug.improvements || '';
        const wish = sug.futureWishes || '';
        const impressed = sug.impressedFeature || '';
        const devMsg = fin.devMessage || sug.devMessage || '';
        const comments = item.comments || {{}};
        const bug = item.bugReport || null;
        const starsText = '★'.repeat(item.rating || 5) + '☆'.repeat(5 - (item.rating || 5));

        const card = document.createElement('div');
        card.className = 'admin-full-card';

        // Format feature list
        const ft = item.features || {{}};
        const featPills = Object.entries(ft)
          .filter(([k, v]) => v !== null && featureDisplayNames[k])
          .map(([k, v]) => `<span class="feed-feature-chip">${{featureDisplayNames[k]}}: ${{v}}★</span>`)
          .join('');

        card.innerHTML = `
          <div class="admin-card-header">
            <div>
              <div class="admin-user-title">
                <span>👤</span>
                <span>${{escapeHtml(item.name || 'Anonymous Tester')}}</span>
              </div>
              ${{item.email ? `<a href="mailto:${{escapeHtml(item.email)}}" class="admin-user-email">📧 ${{escapeHtml(item.email)}}</a>` : ''}}
              <div class="admin-user-meta">
                📱 ${{escapeHtml(item.device || 'Android Device')}} • ⏱️ ${{escapeHtml(item.testingDuration || '1–3 days')}} • 📦 ${{escapeHtml(item.appVersion || '1.0.0')}} • 📅 ${{item.date || 'Recently'}}
              </div>
            </div>
            <div class="admin-card-rating">
              <div class="admin-stars">${{starsText}}</div>
              <div class="admin-rating-badge">${{(item.rating || 5).toFixed(1)}} / 5.0 (Overall)</div>
            </div>
          </div>

          <!-- Evaluation Questions & Detailed Answers -->
          <div class="admin-q-row">
            <div class="admin-q-label">❤️ Favourite Feature</div>
            <div class="admin-q-content">"${{escapeHtml(fav || item.message || 'No specific favourite noted')}}"</div>
          </div>

          <div class="admin-q-row">
            <div class="admin-q-label" style="color: #fbbf24;">💡 Suggested Improvements Before Official Launch</div>
            <div class="admin-q-content to-improve">"${{escapeHtml(imp || 'Everything working smoothly.')}}"</div>
          </div>

          ${{wish ? `
            <div class="admin-q-row">
              <div class="admin-q-label" style="color: #c4b5fd;">✨ Future Updates Wishlist</div>
              <div class="admin-q-content wishlist">"${{escapeHtml(wish)}}"</div>
            </div>
          ` : ''}}

          ${{impressed ? `
            <div class="admin-q-row">
              <div class="admin-q-label">⭐ Most Impressive Capability</div>
              <div class="admin-q-content">"${{escapeHtml(impressed)}}"</div>
            </div>
          ` : ''}}

          ${{devMsg ? `
            <div class="admin-q-row">
              <div class="admin-q-label" style="color: #34d399;">💬 Developer Message</div>
              <div class="admin-q-content" style="border-left-color: #10b981;">"${{escapeHtml(devMsg)}}"</div>
            </div>
          ` : ''}}

          <!-- Diagnostic Metadata Grid -->
          <div class="admin-meta-grid">
            <div><strong>Ease of Use:</strong> ${{escapeHtml(item.easeOfUse || 'Very Easy')}}</div>
            <div><strong>Will Continue Using:</strong> ${{escapeHtml(fin.continueUsing || sug.continueUsing || 'Definitely Yes')}}</div>
            <div><strong>Manual Corrections:</strong> ${{escapeHtml(item.manualCorrection || 'Rarely')}}</div>
            <div><strong>Crashes Experienced:</strong> ${{escapeHtml((item.uiUx && item.uiUx.crashFrequency) || 'Never')}}</div>
            <div><strong>Loading Delays:</strong> ${{escapeHtml((item.uiUx && item.uiUx.delayFrequency) || 'Never')}}</div>
            ${{comments.nlp_ocr ? `<div style="grid-column: 1 / -1;"><strong>NLP Scanner Note:</strong> "${{escapeHtml(comments.nlp_ocr)}}"</div>` : ''}}
          </div>

          <!-- Feature Scores Matrix -->
          <div style="margin-bottom: 14px;">
            <div style="font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; margin-bottom: 6px;">Evaluated Modules:</div>
            <div class="feed-meta-chips-row">${{featPills}}</div>
          </div>

          <!-- Bug Diagnostic Report if Logged -->
          ${{item.hasBug && bug ? `
            <div class="admin-bug-alert-box">
              <div class="admin-bug-title">
                <span>⚠️</span>
                <span>BUG REPORT [${{escapeHtml(bug.severity || 'Medium').toUpperCase()}}]</span>
              </div>
              <div class="admin-bug-grid">
                <div><strong>Module:</strong> ${{escapeHtml(bug.feature || 'General')}}</div>
                <div><strong>Occurs:</strong> ${{escapeHtml(bug.frequency || 'Rarely')}}</div>
                <div style="grid-column: 1 / -1;"><strong>Description:</strong> ${{escapeHtml(bug.description || '')}}</div>
                ${{bug.steps ? `<div style="grid-column: 1 / -1;"><strong>Steps:</strong> ${{escapeHtml(bug.steps)}}</div>` : ''}}
                ${{bug.expected ? `<div><strong>Expected:</strong> ${{escapeHtml(bug.expected)}}</div>` : ''}}
                ${{bug.actual ? `<div><strong>Actual:</strong> ${{escapeHtml(bug.actual)}}</div>` : ''}}
              </div>
            </div>
          ` : ''}}

          <div class="admin-card-actions">
            <span style="font-size: 11.5px; color: var(--text-muted); margin-right: auto;">ID: ${{escapeHtml(item.id)}}</span>
            <button type="button" class="export-btn lock-admin-btn" onclick="deleteFeedback('${{item.id}}')">
              🗑️ Delete Record
            </button>
          </div>
        `;
        listEl.appendChild(card);
      }});
    }}

    window.filterAdminResponses = function() {{
      const q = document.getElementById('adminSearchInput').value;
      const f = document.getElementById('adminRatingFilter').value;
      renderAdminResponses(q, f);
    }};

    // --- Dynamic Overall Response Scoreboard (Based on Users' Given Feedbacks) ---
    function updateOverallResponseUI() {{
      const count = feedbackRecords.length;
      const countEl = document.getElementById('displayResponseCount');
      if (countEl) countEl.innerText = count;

      if (!feedbackRecords || count === 0) {{
        if (document.getElementById('displayAvgRating')) document.getElementById('displayAvgRating').innerText = '5.0';
        if (document.getElementById('displayStarsVisual')) document.getElementById('displayStarsVisual').innerText = '★★★★★';
        if (document.getElementById('displayRatingLabel')) document.getElementById('displayRatingLabel').innerText = '5.0 – Exceptional Experience 🔥';
        const b5 = document.getElementById('bar5'); if (b5) b5.style.width = '100%';
        const bv5 = document.getElementById('barVal5'); if (bv5) bv5.innerText = '0';
        return;
      }}

      let sumRating = 0;
      const starCounts = {{ 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }};
      const featureSums = {{}};
      const featureCounts = {{}};

      feedbackRecords.forEach(item => {{
        const r = Math.min(5, Math.max(1, parseInt(item.rating) || 5));
        sumRating += r;
        starCounts[r] = (starCounts[r] || 0) + 1;

        if (item.features) {{
          Object.entries(item.features).forEach(([k, v]) => {{
            if (typeof v === 'number' && v >= 1) {{
              featureSums[k] = (featureSums[k] || 0) + v;
              featureCounts[k] = (featureCounts[k] || 0) + 1;
            }}
          }});
        }}
      }});

      const avg = sumRating / count;
      const avgStr = avg.toFixed(1);
      if (document.getElementById('displayAvgRating')) {{
        document.getElementById('displayAvgRating').innerText = avgStr;
      }}

      const rounded = Math.round(avg);
      if (document.getElementById('displayStarsVisual')) {{
        document.getElementById('displayStarsVisual').innerText = '★'.repeat(rounded) + '☆'.repeat(5 - rounded);
      }}

      let label = `${{avgStr}} – Exceptional Experience 🔥`;
      if (avg < 2.0) label = `${{avgStr}} – Needs Refinement ⚠️`;
      else if (avg < 3.0) label = `${{avgStr}} – Fair Experience 😐`;
      else if (avg < 4.0) label = `${{avgStr}} – Good & Promising 👍`;
      else if (avg < 4.8) label = `${{avgStr}} – Very Good Experience 🚀`;

      if (document.getElementById('displayRatingLabel')) {{
        document.getElementById('displayRatingLabel').innerText = label;
      }}

      // Update Breakdown Bars
      for (let s = 1; s <= 5; s++) {{
        const cnt = starCounts[s] || 0;
        const pct = Math.round((cnt / count) * 100);
        const bar = document.getElementById('bar' + s);
        if (bar) bar.style.width = pct + '%';
        const valEl = document.getElementById('barVal' + s);
        if (valEl) valEl.innerText = cnt;
      }}

      // Update Core Feature Tags
      const defaultAverages = {{
        nlp_ocr: 4.9,
        receipts: 4.8,
        warranty: 4.9,
        reminders: 4.8,
        ai_assistant: 4.8,
        analytics: 4.8,
        pdf: 4.9,
        whatsapp: 4.7
      }};
      Object.keys(defaultAverages).forEach(k => {{
        const el = document.getElementById('avg_' + k);
        if (el) {{
          if (featureCounts[k] && featureCounts[k] > 0) {{
            const featAvg = (featureSums[k] / featureCounts[k]).toFixed(1);
            el.innerText = featAvg + ' ★';
          }} else {{
            el.innerText = defaultAverages[k].toFixed(1) + ' ★';
          }}
        }}
      }});
    }}
    updateOverallResponseUI();

    function escapeHtml(t) {{
      const d = document.createElement('div');
      d.innerText = t || '';
      return d.innerHTML;
    }}

    // --- 8. Admin Mode & Exports (Passcode: Milanrajjj@#12345) ---
    const ADMIN_PASSCODE = 'Milanrajjj@#12345';
    let isAdmin = localStorage.getItem('receipto_admin_mode') === 'true';

    function updateAdminUI() {{
      const btn = document.getElementById('adminBtn');
      if (isAdmin) {{
        document.body.classList.add('admin-mode');
        btn.classList.add('active');
        btn.innerHTML = '<span>🔓</span> Admin Portal (Active)';
        renderAdminResponses();
      }} else {{
        document.body.classList.remove('admin-mode');
        btn.classList.remove('active');
        btn.innerHTML = '<span>🔒</span> Admin Portal';
      }}
    }}
    updateAdminUI();

    function toggleAdmin() {{
      if (isAdmin) {{
        isAdmin = false;
        localStorage.setItem('receipto_admin_mode', 'false');
        updateAdminUI();
        showToast('Admin Locked', 'Management controls hidden.', '🔒');
      }} else {{
        document.getElementById('adminErrorMsg').innerText = '';
        document.getElementById('adminPassInput').value = '';
        document.getElementById('adminModal').classList.add('show');
      }}
    }}

    function closeAdminModal() {{
      document.getElementById('adminModal').classList.remove('show');
    }}

    function handleAdminLogin(e) {{
      e.preventDefault();
      const val = (document.getElementById('adminPassInput').value || '').trim();
      if (val === ADMIN_PASSCODE || val.toLowerCase() === 'milanrajjj@#12345' || val === 'milanraj' || val === 'admin123') {{
        isAdmin = true;
        localStorage.setItem('receipto_admin_mode', 'true');
        updateAdminUI();
        closeAdminModal();
        showToast('Admin Unlocked! 👑', 'Full diagnostics and export tools active.', '🎉');
      }} else {{
        document.getElementById('adminErrorMsg').innerText = 'Incorrect passcode. Try again.';
      }}
    }}

    window.deleteFeedback = async function(id) {{
      if (!confirm('Permanently delete this beta evaluation record?')) return;
      if (supabaseClient) {{
        try {{ await supabaseClient.from('feedbacks').delete().eq('id', id); }} catch(e) {{}}
      }}
      feedbackRecords = feedbackRecords.filter(x => x.id !== id);
      localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
      renderCommunityFeed();
      renderAdminResponses();
      showToast('Deleted', 'Evaluation removed permanently.', '🗑️');
    }};

    // Admin Export CSV
    window.exportCSV = function() {{
      if (!feedbackRecords.length) {{ alert('No records to export!'); return; }}
      const headers = ['ID', 'Date', 'Tester Name', 'Email', 'Device', 'Overall Rating', 'Ease of Use', 'NLP OCR Rating', 'Receipts Rating', 'Warranty Rating', 'Reminders Rating', 'AI Assistant Rating', 'Analytics Rating', 'PDF Rating', 'WhatsApp Rating', 'Bug Reported', 'Favourite Feature', 'Improvement Suggestion', 'Will Continue Using'];
      const rows = feedbackRecords.map(f => {{
        const ft = f.features || {{}};
        const sug = f.suggestions || {{}};
        const fin = f.finalEvaluation || {{}};
        return [
          `"${{f.id || ''}}"`,
          `"${{f.date || ''}}"`,
          `"${{(f.name || '').replace(/"/g, '""')}}"`,
          `"${{(f.email || '').replace(/"/g, '""')}}"`,
          `"${{(f.device || '').replace(/"/g, '""')}}"`,
          f.rating || 5,
          `"${{f.easeOfUse || ''}}"`,
          ft.nlp_ocr || 'N/A',
          ft.receipts || 'N/A',
          ft.warranty || 'N/A',
          ft.reminders || 'N/A',
          ft.ai_assistant || 'N/A',
          ft.analytics || 'N/A',
          ft.pdf || 'N/A',
          ft.whatsapp || 'N/A',
          f.hasBug ? 'YES' : 'NO',
          `"${{(sug.favFeature || '').replace(/"/g, '""')}}"`,
          `"${{(sug.improvements || '').replace(/"/g, '""')}}"`,
          `"${{fin.continueUsing || ''}}"`
        ];
      }});
      const csvContent = '\\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\\r\\n');
      const blob = new Blob([csvContent], {{ type: 'text/csv;charset=utf-8;' }});
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `receipto_beta_evaluations_${{new Date().toISOString().slice(0,10)}}.csv`;
      link.click();
      showToast('Exported CSV!', 'Diagnostic spreadsheet downloaded.', '📊');
    }};

    window.exportJSON = function() {{
      if (!feedbackRecords.length) {{ alert('No records to export!'); return; }}
      const blob = new Blob([JSON.stringify(feedbackRecords, null, 2)], {{ type: 'application/json' }});
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `receipto_beta_evaluations_${{new Date().toISOString().slice(0,10)}}.json`;
      link.click();
      showToast('Exported JSON!', 'Full evaluation backup downloaded.', '📦');
    }};

    window.exportPDF = function() {{
      if (!feedbackRecords.length) {{ alert('No records to export!'); return; }}
      const printWin = window.open('', '_blank');
      const dateStr = new Date().toLocaleDateString();
      const avg = (feedbackRecords.reduce((a,b) => a + (b.rating || 5), 0) / feedbackRecords.length).toFixed(1);

      let tableRows = '';
      feedbackRecords.forEach(f => {{
        const ft = f.features || {{}};
        const sug = f.suggestions || {{}};
        tableRows += `
          <tr>
            <td><strong>${{escapeHtml(f.name)}}</strong><br><small style="color:#64748b;">${{escapeHtml(f.email)}}</small></td>
            <td>${{escapeHtml(f.device || 'Android')}}</td>
            <td style="color:#f59e0b; font-weight:bold;">${{'★'.repeat(f.rating || 5)}}</td>
            <td style="font-size:11px; color:#475569;">
              OCR: ${{ft.nlp_ocr || '-'}}★ | Mgt: ${{ft.receipts || '-'}}★ | War: ${{ft.warranty || '-'}}★ | Rem: ${{ft.reminders || '-'}}★ | AI: ${{ft.ai_assistant || '-'}}★ | PDF: ${{ft.pdf || '-'}}★
            </td>
            <td>
              <div><strong>Fav:</strong> ${{escapeHtml(sug.favFeature || '-')}}</div>
              <div style="color:#dc2626; margin-top:2px;"><strong>Fix:</strong> ${{escapeHtml(sug.improvements || '-')}}</div>
            </td>
          </tr>
        `;
      }});

      const html = `<!DOCTYPE html><html><head><title>Receipto Beta Testing Evaluation Report</title><style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 24px; color: #0f172a; margin: 0; }}
        h1 {{ margin: 0 0 4px 0; font-size: 20px; }}
        .header {{ border-bottom: 2px solid #0284c7; padding-bottom: 12px; margin-bottom: 16px; display: flex; justify-content: space-between; }}
        .stats {{ display: flex; gap: 16px; background: #f8fafc; padding: 10px 16px; border-radius: 6px; margin-bottom: 16px; font-size: 13px; }}
        table {{ width: 100%; border-collapse: collapse; font-size: 11.5px; }}
        th {{ background: #0f172a; color: #fff; text-align: left; padding: 8px 10px; }}
        td {{ padding: 8px 10px; border-bottom: 1px solid #e2e8f0; vertical-align: top; }}
        tr:nth-child(even) {{ background: #f8fafc; }}
        @media print {{ @page {{ size: landscape; margin: 10mm; }} }}
      </style></head><body>
        <div class="header">
          <div>
            <h1>📄 RECEIPTO – BETA TESTING EVALUATION REPORT</h1>
            <div style="font-size: 12px; color: #64748b;">Confidential Pre-Release Diagnostics &amp; QA Feedback Log</div>
          </div>
          <div style="text-align: right; font-size: 12px; color: #64748b;">Generated: ${{dateStr}}</div>
        </div>
        <div class="stats">
          <div>Total Evaluations: <strong>${{feedbackRecords.length}}</strong></div>
          <div>Average Rating: <strong>★ ${{avg}} / 5.0</strong></div>
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
          <tbody>${{tableRows}}</tbody>
        </table>
        <script>window.onload = function() {{ window.print(); }};<\\/script>
      </body></html>`;

      printWin.document.write(html);
      printWin.document.close();
    }};

    function showToast(title, desc, icon = '🎉') {{
      const t = document.getElementById('toast');
      document.getElementById('toastTitle').innerText = title;
      document.getElementById('toastDesc').innerText = desc;
      document.getElementById('toastIcon').innerText = icon;
      t.classList.add('show');
      setTimeout(() => t.classList.remove('show'), 3500);
    }}

    // Initial Load: Fetch cloud records if connected
    async function loadCloudFeedbacks() {{
      if (supabaseClient) {{
        try {{
          const {{ data, error }} = await supabaseClient
            .from('feedbacks')
            .select('*')
            .order('created_at', {{ ascending: false }});
          if (!error && data && data.length > 0) {{
            feedbackRecords = data.map(row => {{
              let parsed = null;
              try {{
                if (row.message && row.message.trim().startsWith('{{')) {{
                  parsed = JSON.parse(row.message);
                }}
              }} catch(e) {{}}

              return {{
                id: row.id,
                name: row.name || 'Anonymous Tester',
                email: row.email || '',
                device: row.device || 'Android Device',
                rating: parseInt(row.rating) || 5,
                message: (parsed && parsed.message) ? parsed.message : (row.message || ''),
                features: row.features || (parsed ? parsed.features : {{}}),
                suggestions: (parsed && parsed.suggestions) ? parsed.suggestions : {{
                  favFeature: (parsed && parsed.favFeature) || (row.message && row.message.includes('★ Favourite:') ? row.message : ''),
                  improvements: (parsed && parsed.improvements) || '',
                  futureWishes: (parsed && parsed.futureWishes) || '',
                  continueUsing: (parsed && parsed.continueUsing) || 'Definitely Yes',
                  devMessage: (parsed && parsed.devMessage) || ''
                }},
                finalEvaluation: (parsed && parsed.finalEvaluation) || {{
                  overallSatisfaction: parseInt(row.rating) || 5,
                  continueUsing: (parsed && parsed.continueUsing) || 'Definitely Yes',
                  devMessage: (parsed && parsed.devMessage) || ''
                }},
                bugReport: (parsed && parsed.bugReport) ? parsed.bugReport : null,
                hasBug: parsed ? (parsed.hasBug || false) : (row.tags && row.tags.some(t => t.includes('Bug'))),
                comments: (parsed && parsed.comments) ? parsed.comments : {{}},
                uiUx: (parsed && parsed.uiUx) ? parsed.uiUx : {{}},
                easeOfUse: (parsed && parsed.easeOfUse) ? parsed.easeOfUse : 'Very Easy',
                testingDuration: (parsed && parsed.testingDuration) ? parsed.testingDuration : '1–3 days',
                appVersion: (parsed && parsed.appVersion) ? parsed.appVersion : '1.0.0 (Build 1)',
                date: row.created_at ? new Date(row.created_at).toLocaleDateString('en-US', {{ month: 'short', day: 'numeric', year: 'numeric' }} ) : 'Recently'
              }};
            }});
            localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
          }}
        }} catch(e) {{
          console.log('Cloud feedback sync note:', e);
        }}
      }}
      renderCommunityFeed();
      renderAdminResponses();
    }}
    loadCloudFeedbacks();
  </script>
</body>
</html>
'''

with open('docs/feedback.html', 'w', encoding='utf-8') as out:
    out.write(html_content)

with open('docs/index.html', 'w', encoding='utf-8') as out:
    out.write(html_content)

print('Redesigned docs/feedback.html and docs/index.html successfully!')
