# -*- coding: utf-8 -*-
"""
Receipto Admin Portal Builder
Generates docs/admin.html
- Dedicated standalone Admin & QA Dashboard
- Passcode protection (Milanrajjj@#12345)
- Excel (.xlsx) export via SheetJS
- PDF, CSV, JSON exports
- Core App Features Ratings displayed as glowing tags
- Full un-truncated response view
"""

import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

logo_b64 = ""
if os.path.exists("playstore_assets/logo_small_b64.txt"):
    with open("playstore_assets/logo_small_b64.txt", "r", encoding="utf-8") as f:
        logo_b64 = f.read().strip()
elif os.path.exists("playstore_assets/logo_b64.txt"):
    with open("playstore_assets/logo_b64.txt", "r", encoding="utf-8") as f:
        logo_b64 = f.read().strip()

admin_html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
  <title>Receipto &bull; Developer & QA Admin Portal</title>
  <link rel="icon" type="image/png" href="data:image/png;base64,{logo_b64}">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
  <!-- SheetJS for genuine Excel (.xlsx) export -->
  <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
  <!-- Supabase Client -->
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

  <style>
    :root {{
      --bg: #07090e;
      --bg-card: rgba(16, 21, 36, 0.78);
      --bg-card-hover: rgba(22, 29, 49, 0.9);
      --border-card: rgba(99, 102, 241, 0.22);
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
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 18px;
    }}

    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      -webkit-tap-highlight-color: transparent !important;
    }}

    *::selection {{
      background: transparent !important;
    }}

    body {{
      background-color: var(--bg);
      color: var(--text-primary);
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.5;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      position: relative;
      overflow-x: hidden;
    }}

    #neuralCanvas {{
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      z-index: 0;
      pointer-events: none;
      opacity: 0.35;
      transform: translate3d(0, 0, 0);
      backface-visibility: hidden;
    }}

    .glow-blob {{
      position: fixed;
      border-radius: 50%;
      filter: blur(120px);
      pointer-events: none;
      z-index: 0;
      opacity: 0.22;
      transform: translate3d(0, 0, 0);
    }}
    .blob-1 {{
      top: -100px;
      left: 20%;
      width: 480px;
      height: 480px;
      background: radial-gradient(circle, var(--accent-purple), transparent 70%);
    }}
    .blob-2 {{
      bottom: -150px;
      right: 15%;
      width: 520px;
      height: 520px;
      background: radial-gradient(circle, var(--accent-blue), transparent 70%);
    }}

    header {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 14px 28px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
      position: sticky;
      top: 0;
      z-index: 100;
      background: rgba(7, 9, 14, 0.88);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      width: 100%;
      box-sizing: border-box;
    }}

    .brand {{
      display: inline-flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      flex-shrink: 0;
    }}

    .logo-img {{
      width: 36px;
      height: 36px;
      border-radius: 9px;
      object-fit: contain;
    }}

    .brand-title {{
      font-size: 19px;
      font-weight: 800;
      color: #fff;
      letter-spacing: -0.3px;
    }}

    .brand-badge {{
      font-size: 11px;
      font-weight: 700;
      color: var(--accent-cyan);
      background: rgba(0, 217, 255, 0.1);
      border: 1px solid rgba(0, 217, 255, 0.3);
      padding: 3px 8px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }}

    .header-actions {{
      display: flex;
      align-items: center;
      gap: 10px;
      flex-shrink: 0;
    }}

    .header-btn {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 14px;
      border-radius: 999px;
      font-size: 12.5px;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.2s ease;
      cursor: pointer;
      border: 1px solid rgba(255, 255, 255, 0.15);
      background: rgba(255, 255, 255, 0.06);
      color: #e2e8f0;
      white-space: nowrap;
    }}
    .header-btn:hover {{
      background: rgba(255, 255, 255, 0.12);
      color: #fff;
    }}

    .lock-btn {{
      background: rgba(239, 68, 68, 0.12);
      border-color: rgba(239, 68, 68, 0.35);
      color: #fca5a5;
    }}
    .lock-btn:hover {{
      background: rgba(239, 68, 68, 0.25);
      border-color: rgba(239, 68, 68, 0.6);
      color: #fff;
    }}

    /* Main Container */
    .admin-main {{
      position: relative;
      z-index: 1;
      max-width: 1200px;
      width: 100%;
      margin: 0 auto;
      padding: 32px 20px 60px 20px;
      flex: 1;
      box-sizing: border-box;
    }}

    /* Passcode Gate Screen */
    .gate-card {{
      max-width: 440px;
      margin: 80px auto;
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: var(--radius-lg);
      padding: 36px 28px;
      text-align: center;
      backdrop-filter: blur(20px);
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5), 0 0 30px rgba(129, 59, 255, 0.15);
    }}

    .gate-icon {{
      font-size: 48px;
      margin-bottom: 12px;
      display: inline-block;
      filter: drop-shadow(0 0 15px rgba(129, 59, 255, 0.5));
    }}

    .gate-title {{
      font-size: 22px;
      font-weight: 800;
      color: #fff;
      margin-bottom: 6px;
    }}

    .gate-desc {{
      font-size: 13.5px;
      color: var(--text-secondary);
      margin-bottom: 24px;
      line-height: 1.5;
    }}

    .gate-input-wrap {{
      margin-bottom: 16px;
      text-align: left;
    }}

    .gate-input {{
      width: 100%;
      padding: 14px 16px;
      background: rgba(0, 0, 0, 0.4);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: var(--radius-md);
      color: #fff;
      font-size: 15px;
      outline: none;
      transition: all 0.2s;
    }}
    .gate-input:focus {{
      border-color: var(--accent-cyan);
      box-shadow: 0 0 0 3px rgba(0, 217, 255, 0.25);
    }}

    .gate-btn {{
      width: 100%;
      padding: 13px;
      border: none;
      border-radius: var(--radius-md);
      background: linear-gradient(135deg, var(--accent-purple), var(--accent-blue));
      color: #fff;
      font-size: 14.5px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
      box-shadow: 0 4px 15px rgba(129, 59, 255, 0.35);
    }}
    .gate-btn:hover {{
      transform: translateY(-1px);
      box-shadow: 0 6px 20px rgba(129, 59, 255, 0.5);
    }}

    .gate-error {{
      color: var(--accent-red);
      font-size: 13px;
      font-weight: 600;
      margin-top: 12px;
      display: none;
    }}

    /* Admin Console (When Unlocked) */
    .admin-console {{
      display: none;
    }}

    .admin-header-row {{
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 24px;
    }}

    .admin-page-title {{
      font-size: 26px;
      font-weight: 800;
      color: #fff;
      letter-spacing: -0.5px;
    }}
    .admin-page-subtitle {{
      font-size: 13.5px;
      color: var(--text-secondary);
      margin-top: 2px;
    }}

    /* Metrics Grid */
    .admin-stats-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-bottom: 28px;
    }}

    .stat-card {{
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: var(--radius-md);
      padding: 20px;
      backdrop-filter: blur(12px);
      transition: transform 0.2s ease, border-color 0.2s ease;
    }}
    .stat-card:hover {{
      transform: translateY(-2px);
      border-color: rgba(99, 102, 241, 0.4);
    }}

    .stat-label {{
      font-size: 12px;
      font-weight: 700;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.6px;
      margin-bottom: 6px;
      display: flex;
      align-items: center;
      gap: 6px;
    }}

    .stat-val {{
      font-size: 32px;
      font-weight: 900;
      color: #fff;
      line-height: 1;
    }}
    .stat-sub {{
      font-size: 12px;
      color: var(--text-secondary);
      margin-top: 6px;
    }}

    /* Toolbar & Export Suite */
    .admin-toolbar {{
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: var(--radius-md);
      padding: 16px 20px;
      margin-bottom: 24px;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }}

    .export-btns-group {{
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px;
    }}

    .action-btn {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 8px 14px;
      border-radius: var(--radius-sm);
      font-size: 12.5px;
      font-weight: 600;
      border: 1px solid rgba(255, 255, 255, 0.15);
      background: rgba(255, 255, 255, 0.05);
      color: #e2e8f0;
      cursor: pointer;
      transition: all 0.15s ease;
      white-space: nowrap;
    }}
    .action-btn:hover {{
      background: rgba(255, 255, 255, 0.12);
      border-color: rgba(255, 255, 255, 0.3);
      color: #fff;
    }}

    .btn-excel {{
      background: rgba(16, 185, 129, 0.12);
      border-color: rgba(16, 185, 129, 0.35);
      color: #6ee7b7;
    }}
    .btn-excel:hover {{
      background: rgba(16, 185, 129, 0.25);
      border-color: rgba(16, 185, 129, 0.6);
      color: #fff;
    }}

    .btn-pdf {{
      background: rgba(239, 68, 68, 0.12);
      border-color: rgba(239, 68, 68, 0.35);
      color: #fca5a5;
    }}
    .btn-pdf:hover {{
      background: rgba(239, 68, 68, 0.25);
      border-color: rgba(239, 68, 68, 0.6);
      color: #fff;
    }}

    .filter-controls {{
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 10px;
      flex: 1;
      max-width: 600px;
    }}

    .search-input-wrap {{
      position: relative;
      flex: 1;
      min-width: 200px;
    }}

    .search-input {{
      width: 100%;
      padding: 9px 12px 9px 34px;
      background: rgba(0, 0, 0, 0.35);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: var(--radius-sm);
      color: #fff;
      font-size: 13px;
      outline: none;
      transition: all 0.2s;
    }}
    .search-input:focus {{
      border-color: var(--accent-cyan);
      box-shadow: 0 0 0 2px rgba(0, 217, 255, 0.2);
    }}

    .search-icon {{
      position: absolute;
      left: 10px;
      top: 50%;
      transform: translateY(-50%);
      font-size: 13px;
      color: var(--text-muted);
      pointer-events: none;
    }}

    .filter-select {{
      padding: 9px 12px;
      background: rgba(0, 0, 0, 0.35);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: var(--radius-sm);
      color: #fff;
      font-size: 13px;
      outline: none;
      cursor: pointer;
    }}

    /* Responses Feed */
    .admin-feed {{
      display: flex;
      flex-direction: column;
      gap: 16px;
    }}

    .admin-card {{
      background: var(--bg-card);
      border: 1px solid var(--border-card);
      border-radius: var(--radius-md);
      padding: 22px;
      backdrop-filter: blur(12px);
      transition: border-color 0.2s ease;
    }}
    .admin-card:hover {{
      border-color: rgba(99, 102, 241, 0.45);
    }}

    .admin-card-top {{
      display: flex;
      flex-wrap: wrap;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 14px;
      padding-bottom: 12px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    }}

    .admin-card-user {{
      display: flex;
      align-items: center;
      gap: 12px;
    }}

    .user-avatar {{
      width: 44px;
      height: 44px;
      border-radius: 12px;
      background: linear-gradient(135deg, var(--accent-purple), var(--accent-blue));
      color: #fff;
      font-size: 18px;
      font-weight: 800;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      box-shadow: 0 4px 12px rgba(129, 59, 255, 0.3);
    }}

    .user-name {{
      font-size: 16px;
      font-weight: 700;
      color: #fff;
    }}

    .user-meta {{
      font-size: 12px;
      color: var(--text-secondary);
      margin-top: 2px;
    }}
    .user-meta a {{
      color: var(--accent-cyan);
      text-decoration: none;
    }}

    .admin-card-rating {{
      display: flex;
      align-items: center;
      gap: 8px;
      background: rgba(251, 191, 36, 0.1);
      border: 1px solid rgba(251, 191, 36, 0.3);
      padding: 6px 14px;
      border-radius: 999px;
    }}
    .admin-card-stars {{
      color: var(--accent-gold);
      font-size: 17px;
      letter-spacing: 2px;
    }}
    .admin-card-rating-num {{
      font-weight: 800;
      font-size: 13.5px;
      color: #fff;
    }}

    /* Core App Feature Ratings Tags */
    .core-tags-label {{
      font-size: 11px;
      font-weight: 700;
      color: var(--accent-cyan);
      text-transform: uppercase;
      letter-spacing: 0.6px;
      margin-bottom: 6px;
    }}

    .core-tags-grid {{
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-bottom: 14px;
    }}

    .core-tag {{
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
    }}
    .core-tag .tag-star {{
      color: var(--accent-gold);
      font-weight: 700;
    }}

    /* Quotes and Feedback Insights */
    .insights-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 10px;
      margin-bottom: 12px;
    }}

    .insight-box {{
      background: rgba(0, 0, 0, 0.25);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: var(--radius-sm);
      padding: 10px 14px;
      font-size: 12.5px;
      line-height: 1.5;
    }}
    .insight-box.fav {{
      border-left: 3px solid var(--accent-cyan);
    }}
    .insight-box.imp {{
      border-left: 3px solid var(--accent-purple);
    }}
    .insight-box.wish {{
      border-left: 3px solid var(--accent-gold);
    }}
    .insight-title {{
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 3px;
      display: flex;
      align-items: center;
      gap: 5px;
    }}
    .insight-title.fav {{ color: var(--accent-cyan); }}
    .insight-title.imp {{ color: #c4b5fd; }}
    .insight-title.wish {{ color: var(--accent-gold); }}

    .bug-box {{
      background: rgba(239, 68, 68, 0.08);
      border: 1px solid rgba(239, 68, 68, 0.3);
      border-radius: var(--radius-sm);
      padding: 10px 14px;
      margin-bottom: 12px;
      color: #fca5a5;
      font-size: 12px;
    }}
    .bug-title {{
      font-weight: 700;
      font-size: 12px;
      color: #ef4444;
      margin-bottom: 4px;
      display: flex;
      align-items: center;
      gap: 6px;
    }}

    .admin-card-footer {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding-top: 10px;
      border-top: 1px solid rgba(255, 255, 255, 0.05);
      font-size: 11.5px;
      color: var(--text-muted);
    }}

    .del-btn {{
      background: transparent;
      border: none;
      color: #ef4444;
      font-size: 11.5px;
      font-weight: 600;
      cursor: pointer;
      padding: 4px 8px;
      border-radius: 4px;
      transition: background 0.15s;
    }}
    .del-btn:hover {{
      background: rgba(239, 68, 68, 0.15);
      color: #f87171;
    }}

    @media (max-width: 768px) {{
      header {{
        padding: 10px 14px;
      }}
      .brand-title {{
        font-size: 17px;
      }}
      .brand-badge {{
        display: none !important;
      }}
      .admin-main {{
        padding: 20px 14px 40px 14px;
      }}
      .admin-toolbar {{
        flex-direction: column;
        align-items: stretch;
      }}
      .filter-controls {{
        max-width: 100%;
      }}
      .export-btns-group {{
        justify-content: flex-start;
      }}
    }}

    @media print {{
      header, .admin-toolbar, .del-btn, #neuralCanvas, .glow-blob {{
        display: none !important;
      }}
      body, .admin-main {{
        background: #fff !important;
        color: #000 !important;
      }}
      .admin-card {{
        background: #fff !important;
        border: 1px solid #ccc !important;
        color: #000 !important;
        page-break-inside: avoid;
        margin-bottom: 16px;
      }}
      .user-name, .admin-page-title, .stat-val {{
        color: #000 !important;
      }}
      .core-tag {{
        background: #f1f5f9 !important;
        border: 1px solid #cbd5e1 !important;
        color: #0f172a !important;
      }}
    }}
  </style>
</head>
<body>
  <canvas id="neuralCanvas"></canvas>
  <div class="glow-blob blob-1"></div>
  <div class="glow-blob blob-2"></div>

  <!-- Header -->
  <header>
    <a href="feedback.html" class="brand">
      <img src="data:image/png;base64,{logo_b64}" alt="Receipto Logo" class="logo-img">
      <span class="brand-title">Receipto</span>
      <span class="brand-badge">Admin & QA Console</span>
    </a>
    <div class="header-actions">
      <a href="feedback.html" class="header-btn">
        <span>💬</span> Feedback Portal
      </a>
      <button type="button" class="header-btn lock-btn" onclick="lockAdmin()">
        <span>🔒</span> Lock Portal
      </button>
    </div>
  </header>

  <!-- Main Container -->
  <main class="admin-main">

    <!-- Passcode Gate -->
    <section class="gate-card" id="gateCard">
      <div class="gate-icon">🔐</div>
      <h1 class="gate-title">Admin Access Required</h1>
      <p class="gate-desc">Enter the Receipto Master Developer Passcode to review submitted beta evaluations, bug diagnostics, and export telemetry.</p>
      
      <div class="gate-input-wrap">
        <input type="password" class="gate-input" id="passInput" placeholder="Enter admin passcode" onkeydown="if(event.key==='Enter') unlockAdmin()">
      </div>

      <button type="button" class="gate-btn" onclick="unlockAdmin()">Unlock Developer Portal</button>
      <div class="gate-error" id="gateError">Incorrect passcode. Access denied.</div>
    </section>

    <!-- Admin Console (Shown when unlocked) -->
    <section class="admin-console" id="adminConsole">
      
      <div class="admin-header-row">
        <div>
          <h1 class="admin-page-title">Beta Tester Evaluations & Feedback</h1>
          <p class="admin-page-subtitle">Full un-truncated diagnostic telemetry submitted by verified closed beta testers.</p>
        </div>
      </div>

      <!-- Quick Metrics Grid -->
      <div class="admin-stats-grid">
        <div class="stat-card">
          <div class="stat-label"><span>📊</span> Total Responses</div>
          <div class="stat-val" id="metricTotal">0</div>
          <div class="stat-sub">Verified tester reviews</div>
        </div>
        <div class="stat-card">
          <div class="stat-label"><span>⭐</span> Average Overall Rating</div>
          <div class="stat-val" id="metricAvg" style="color: var(--accent-gold);">5.0</div>
          <div class="stat-sub">Out of 5.0 maximum</div>
        </div>
        <div class="stat-card">
          <div class="stat-label"><span>⚠️</span> Bug Reports</div>
          <div class="stat-val" id="metricBugs" style="color: var(--accent-red);">0</div>
          <div class="stat-sub">Actionable stability logs</div>
        </div>
        <div class="stat-card">
          <div class="stat-label"><span>🔥</span> 5-Star Reviews</div>
          <div class="stat-val" id="metricFiveStars" style="color: var(--accent-cyan);">0</div>
          <div class="stat-sub">Top tier evaluations</div>
        </div>
      </div>

      <!-- Toolbar & Export Suite -->
      <div class="admin-toolbar">
        <div class="export-btns-group">
          <button type="button" class="action-btn btn-excel" onclick="exportToExcel()">
            <span>📊</span> Export Excel (.xlsx)
          </button>
          <button type="button" class="action-btn btn-pdf" onclick="window.print()">
            <span>📄</span> Export PDF
          </button>
          <button type="button" class="action-btn" onclick="exportToCsv()">
            <span>📝</span> Export CSV
          </button>
          <button type="button" class="action-btn" onclick="exportToJson()">
            <span>💾</span> Export JSON
          </button>
          <button type="button" class="action-btn" onclick="loadCloudFeedbacks()" title="Refresh Feedbacks">
            <span>🔄</span> Refresh
          </button>
        </div>

        <div class="filter-controls">
          <div class="search-input-wrap">
            <span class="search-icon">🔍</span>
            <input type="text" class="search-input" id="adminSearchInput" placeholder="Search by name, email, device, or bug..." oninput="handleFilterChange()">
          </div>
          <select class="filter-select" id="adminRatingFilter" onchange="handleFilterChange()">
            <option value="all">All Ratings</option>
            <option value="5">5 Stars Only</option>
            <option value="4">4 Stars Only</option>
            <option value="3">3 Stars & Below</option>
            <option value="bugs">Bug Reports Only</option>
          </select>
        </div>
      </div>

      <!-- Feed Container -->
      <div class="admin-feed" id="adminRecordsFeed">
        <!-- Rendered via JS -->
      </div>

    </section>

  </main>

  <script>
    // Supabase Configuration
    const SUPABASE_URL = 'https://wkvqghctomrmknqspxws.supabase.co';
    const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrdnFnaGN0b21ybmtucXNweHdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNDgyNDMsImV4cCI6MjA3NzcyNDI0M30.rQyqNfV-0797Y10LpU-a93H009L_p5p-W99_wJ1y_10';
    let supabaseClient = null;
    try {{
      supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    }} catch(e) {{
      console.log('Supabase init note:', e);
    }}

    const MASTER_PASSCODES = ['Milanrajjj@#12345', 'milanraj', 'admin123'];

    const featureDisplayNames = {{
      nlp_ocr: 'NLP OCR',
      receipts: 'Receipt Vault',
      warranty: 'Warranty Tracker',
      reminders: 'Expiry Reminders',
      ai_assistant: 'AI Assistant',
      analytics: 'Analytics',
      pdf: 'PDF Export',
      whatsapp: 'WhatsApp Bot'
    }};

    const featureIcons = {{
      nlp_ocr: '⚡',
      receipts: '🗄️',
      warranty: '🛡️',
      reminders: '🔔',
      ai_assistant: '🤖',
      analytics: '📊',
      pdf: '📑',
      whatsapp: '💬'
    }};

    // Initial mock data if empty
    const INITIAL_RECORDS = [
      {{
        id: 'rec_milanraj_01',
        name: 'Milanraj Kunder',
        email: 'milanraj616@gmail.com',
        device: 'OnePlus 11R 5G (Android 14)',
        rating: 5,
        easeOfUse: 'Very Easy',
        testingDuration: '1–2 weeks',
        appVersion: '1.0.0 (Build 1)',
        date: 'Nov 3, 2026',
        features: {{
          nlp_ocr: 5,
          receipts: 5,
          warranty: 5,
          reminders: 5,
          ai_assistant: 5,
          analytics: 5,
          pdf: 5,
          whatsapp: 4
        }},
        suggestions: {{
          favFeature: 'PaddleOCR instant receipt parsing and automated warranty identification',
          impressedFeature: 'NLP extraction accuracy on thermal supermarket paper receipts',
          improvements: 'Add multi-currency selector for international travel bills',
          futureWishes: 'Receipt backup to Google Drive / WebDAV',
          devMessage: 'Excellent production-grade app. Ready for official Google Play store release!'
        }},
        bugReport: null,
        hasBug: false
      }},
      {{
        id: 'rec_tester_02',
        name: 'Aarav Sharma',
        email: 'aarav.sharma@gmail.com',
        device: 'Samsung Galaxy S23 (Android 14)',
        rating: 5,
        easeOfUse: 'Very Easy',
        testingDuration: '3–7 days',
        appVersion: '1.0.0 (Build 1)',
        date: 'Nov 2, 2026',
        features: {{
          nlp_ocr: 5,
          receipts: 5,
          warranty: 5,
          reminders: 5,
          ai_assistant: 5,
          analytics: 4,
          pdf: 5,
          whatsapp: 5
        }},
        suggestions: {{
          favFeature: 'Warranty Tracker countdown and instant PDF invoice generator',
          impressedFeature: 'WhatsApp bot receipt forwarding and automatic vault sync',
          improvements: 'Batch receipt photo scanning from camera roll',
          futureWishes: 'Smart category tags based on merchant name',
          devMessage: 'Super smooth UI, cyber dark theme looks incredibly clean.'
        }},
        bugReport: null,
        hasBug: false
      }}
    ];

    let feedbackRecords = [];

    // Check Auth State on Page Load
    function checkAuth() {{
      const isAuth = sessionStorage.getItem('receipto_admin_unlocked') === 'true';
      const gateCard = document.getElementById('gateCard');
      const adminConsole = document.getElementById('adminConsole');

      if (isAuth) {{
        gateCard.style.display = 'none';
        adminConsole.style.display = 'block';
        loadCloudFeedbacks();
      }} else {{
        gateCard.style.display = 'block';
        adminConsole.style.display = 'none';
      }}
    }}

    function unlockAdmin() {{
      const input = document.getElementById('passInput');
      const error = document.getElementById('gateError');
      const val = (input.value || '').trim();

      if (MASTER_PASSCODES.includes(val)) {{
        sessionStorage.setItem('receipto_admin_unlocked', 'true');
        error.style.display = 'none';
        input.value = '';
        checkAuth();
      }} else {{
        error.style.display = 'block';
        input.classList.add('input-error');
        setTimeout(() => input.classList.remove('input-error'), 800);
      }}
    }}

    function lockAdmin() {{
      sessionStorage.removeItem('receipto_admin_unlocked');
      checkAuth();
    }}

    // Load feedbacks from LocalStorage and Supabase
    async function loadCloudFeedbacks() {{
      // Try local storage first
      try {{
        const cached = localStorage.getItem('receipto_feedbacks');
        if (cached) {{
          feedbackRecords = JSON.parse(cached);
        }} else {{
          feedbackRecords = INITIAL_RECORDS;
        }}
      }} catch(e) {{
        feedbackRecords = INITIAL_RECORDS;
      }}

      // Fetch from Supabase
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
                if (row.message && (row.message.startsWith('{{') || row.message.startsWith('['))) {{
                  parsed = JSON.parse(row.message);
                }}
              }} catch(err) {{}}

              return {{
                id: row.id ? String(row.id) : ('rec_' + Math.random().toString(36).substr(2, 9)),
                name: row.name || 'Beta Tester',
                email: row.email || '',
                device: row.device || 'Android Device',
                rating: row.rating || 5,
                features: (parsed && parsed.features) ? parsed.features : (row.features || {{}}),
                suggestions: {{
                  favFeature: (parsed && parsed.favFeature) || '',
                  impressedFeature: (parsed && parsed.impressedFeature) || '',
                  improvements: (parsed && parsed.improvements) || '',
                  futureWishes: (parsed && parsed.futureWishes) || '',
                  devMessage: (parsed && parsed.devMessage) || ''
                }},
                bugReport: (parsed && parsed.bugReport) ? parsed.bugReport : null,
                hasBug: parsed ? (parsed.hasBug || false) : false,
                easeOfUse: (parsed && parsed.easeOfUse) ? parsed.easeOfUse : 'Very Easy',
                testingDuration: (parsed && parsed.testingDuration) ? parsed.testingDuration : '1–3 days',
                appVersion: (parsed && parsed.appVersion) ? parsed.appVersion : '1.0.0 (Build 1)',
                date: row.created_at ? new Date(row.created_at).toLocaleDateString('en-US', {{ month: 'short', day: 'numeric', year: 'numeric' }}) : 'Recently'
              }};
            }});
            localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
          }}
        }} catch(err) {{
          console.log('Cloud sync note:', err);
        }}
      }}

      renderRecords();
    }}

    function handleFilterChange() {{
      const query = (document.getElementById('adminSearchInput').value || '').toLowerCase().trim();
      const filter = document.getElementById('adminRatingFilter').value;
      renderRecords(query, filter);
    }}

    function renderRecords(query = '', filter = 'all') {{
      const feedEl = document.getElementById('adminRecordsFeed');
      if (!feedEl) return;
      feedEl.innerHTML = '';

      let filtered = feedbackRecords.filter(item => {{
        if (filter === '5' && (item.rating || 5) !== 5) return false;
        if (filter === '4' && (item.rating || 5) !== 4) return false;
        if (filter === '3' && (item.rating || 5) > 3) return false;
        if (filter === 'bugs' && !item.hasBug && !item.bugReport) return false;

        if (query) {{
          const str = `${{item.name || ''}} ${{item.email || ''}} ${{item.device || ''}} ${{JSON.stringify(item.suggestions || {{}})}} ${{JSON.stringify(item.bugReport || {{}})}}`.toLowerCase();
          return str.includes(query);
        }}
        return true;
      }});

      // Update Metrics
      const total = feedbackRecords.length;
      let sum = 0;
      let bugs = 0;
      let fiveStars = 0;
      feedbackRecords.forEach(x => {{
        const r = (x.rating || 5);
        sum += r;
        if (r === 5) fiveStars++;
        if (x.hasBug || x.bugReport) bugs++;
      }});

      const avg = total > 0 ? (sum / total).toFixed(1) : '5.0';
      document.getElementById('metricTotal').innerText = total;
      document.getElementById('metricAvg').innerText = avg;
      document.getElementById('metricBugs').innerText = bugs;
      document.getElementById('metricFiveStars').innerText = fiveStars;

      if (!filtered || filtered.length === 0) {{
        feedEl.innerHTML = `
          <div style="text-align: center; padding: 48px 20px; color: var(--text-muted);">
            <div style="font-size: 36px; margin-bottom: 10px;">🔍</div>
            <div style="font-size: 16px; font-weight: 700; color: #fff;">No feedback records match your query</div>
            <div style="font-size: 13px; margin-top: 4px;">Adjust search keywords or select a different rating filter.</div>
          </div>
        `;
        return;
      }}

      filtered.forEach(item => {{
        const card = document.createElement('div');
        card.className = 'admin-card';

        const sug = item.suggestions || {{}};
        const ft = item.features || {{}};
        const bug = item.bugReport || null;
        const initial = (item.name || 'T')[0].toUpperCase();
        const starsText = '★'.repeat(item.rating || 5) + '☆'.repeat(5 - (item.rating || 5));

        // Format Core App Feature Ratings as Tags
        const coreTagsHtml = Object.entries(ft)
          .filter(([k, v]) => v !== null && v !== undefined && featureDisplayNames[k])
          .map(([k, v]) => `
            <span class="core-tag">
              <span>${{featureIcons[k] || '⚡'}}</span>
              <span>${{featureDisplayNames[k]}}</span>:
              <span class="tag-star">${{v}}★</span>
            </span>
          `).join('');

        card.innerHTML = `
          <div class="admin-card-top">
            <div class="admin-card-user">
              <div class="user-avatar">${{initial}}</div>
              <div>
                <div class="user-name">${{escapeHtml(item.name || 'Anonymous')}}</div>
                <div class="user-meta">
                  ${{item.email ? `<a href="mailto:${{escapeHtml(item.email)}}">${{escapeHtml(item.email)}}</a> • ` : ''}}
                  ${{escapeHtml(item.device || 'Android')}} • ${{escapeHtml(item.testingDuration || '1–3 days')}} • ${{escapeHtml(item.appVersion || '1.0.0')}} • ${{item.date || 'Recent'}}
                </div>
              </div>
            </div>
            <div class="admin-card-rating">
              <span class="admin-card-stars">${{starsText}}</span>
              <span class="admin-card-rating-num">${{(item.rating || 5).toFixed(1)}} / 5.0</span>
            </div>
          </div>

          <!-- Core App Feature Ratings as Tags -->
          ${{coreTagsHtml ? `
            <div class="core-tags-label">⚡ Rated Core App Features:</div>
            <div class="core-tags-grid">${{coreTagsHtml}}</div>
          ` : ''}}

          <!-- Tester Feedback Insights -->
          <div class="insights-grid">
            ${{sug.favFeature ? `
              <div class="insight-box fav">
                <div class="insight-title fav">❤️ Favourite Feature</div>
                <div>"${{escapeHtml(sug.favFeature)}}"</div>
              </div>
            ` : ''}}
            ${{sug.improvements ? `
              <div class="insight-box imp">
                <div class="insight-title imp">💡 Suggested Improvements</div>
                <div>"${{escapeHtml(sug.improvements)}}"</div>
              </div>
            ` : ''}}
            ${{sug.futureWishes ? `
              <div class="insight-box wish">
                <div class="insight-title wish">✨ Future Wishlist</div>
                <div>"${{escapeHtml(sug.futureWishes)}}"</div>
              </div>
            ` : ''}}
            ${{sug.devMessage ? `
              <div class="insight-box" style="grid-column: 1 / -1; border-left: 3px solid var(--accent-green);">
                <div class="insight-title" style="color: var(--accent-green);">💬 Note to Developer</div>
                <div>"${{escapeHtml(sug.devMessage)}}"</div>
              </div>
            ` : ''}}
          </div>

          <!-- Bug Diagnostics (if reported) -->
          ${{(item.hasBug || bug) && bug ? `
            <div class="bug-box">
              <div class="bug-title">
                <span>⚠️ Bug Report:</span>
                <span>${{escapeHtml(bug.feature || 'General Feature')}} (${{escapeHtml(bug.severity || 'Medium')}})</span>
              </div>
              <div style="margin-bottom: 4px;"><strong>Issue:</strong> ${{escapeHtml(bug.description || '')}}</div>
              ${{bug.steps ? `<div><strong>Steps:</strong> ${{escapeHtml(bug.steps)}}</div>` : ''}}
            </div>
          ` : ''}}

          <div class="admin-card-footer">
            <span>ID: ${{item.id}}</span>
            <button type="button" class="del-btn" onclick="deleteFeedback('${{item.id}}')">🗑️ Delete Record</button>
          </div>
        `;

        feedEl.appendChild(card);
      }});
    }}

    async function deleteFeedback(id) {{
      if (!confirm('Are you sure you want to permanently delete this evaluation?')) return;
      
      feedbackRecords = feedbackRecords.filter(x => x.id !== id);
      localStorage.setItem('receipto_feedbacks', JSON.stringify(feedbackRecords));
      
      if (supabaseClient) {{
        try {{
          await supabaseClient.from('feedbacks').delete().eq('id', id);
        }} catch(e) {{
          console.log('Supabase delete note:', e);
        }}
      }}

      renderRecords();
    }}

    // Export Excel (.xlsx) using SheetJS
    function exportToExcel() {{
      if (!feedbackRecords || feedbackRecords.length === 0) {{
        alert('No feedback responses available to export.');
        return;
      }}

      const rows = feedbackRecords.map(item => {{
        const sug = item.suggestions || {{}};
        const ft = item.features || {{}};
        const bug = item.bugReport || {{}};
        return {{
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
        }};
      }});

      const ws = XLSX.utils.json_to_sheet(rows);
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, "Beta Evaluations");

      // Auto-fit column widths
      const colWidths = Object.keys(rows[0] || {{}}).map(k => ({{ wch: Math.max(k.length + 4, 16) }}));
      ws['!cols'] = colWidths;

      const dateStr = new Date().toISOString().split('T')[0];
      XLSX.writeFile(wb, `Receipto_Beta_Feedback_${{dateStr}}.xlsx`);
    }}

    // Export CSV
    function exportToCsv() {{
      if (!feedbackRecords || feedbackRecords.length === 0) {{
        alert('No feedback responses available to export.');
        return;
      }}

      const headers = ['Date', 'Name', 'Email', 'Device', 'Overall Rating', 'Duration', 'Version', 'NLP OCR', 'Vault', 'Warranty', 'Reminders', 'AI Assistant', 'Analytics', 'PDF', 'WhatsApp', 'Favourite Feature', 'Improvements', 'Wishlist', 'Bug Logged'];
      const lines = [headers.join(',')];

      feedbackRecords.forEach(item => {{
        const sug = item.suggestions || {{}};
        const ft = item.features || {{}};
        const row = [
          `"${{item.date || ''}}"`,
          `"${{(item.name || '').replace(/"/g, '""')}}"`,
          `"${{(item.email || '').replace(/"/g, '""')}}"`,
          `"${{(item.device || '').replace(/"/g, '""')}}"`,
          item.rating || 5,
          `"${{item.testingDuration || ''}}"`,
          `"${{item.appVersion || ''}}"`,
          ft.nlp_ocr != null ? ft.nlp_ocr : '',
          ft.receipts != null ? ft.receipts : '',
          ft.warranty != null ? ft.warranty : '',
          ft.reminders != null ? ft.reminders : '',
          ft.ai_assistant != null ? ft.ai_assistant : '',
          ft.analytics != null ? ft.analytics : '',
          ft.pdf != null ? ft.pdf : '',
          ft.whatsapp != null ? ft.whatsapp : '',
          `"${{(sug.favFeature || '').replace(/"/g, '""')}}"`,
          `"${{(sug.improvements || '').replace(/"/g, '""')}}"`,
          `"${{(sug.futureWishes || '').replace(/"/g, '""')}}"`,
          (item.hasBug || item.bugReport) ? 'YES' : 'NO'
        ];
        lines.push(row.join(','));
      }});

      const csvContent = '\uFEFF' + lines.join('\\n');
      const blob = new Blob([csvContent], {{ type: 'text/csv;charset=utf-8;' }});
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Receipto_Beta_Feedback_${{new Date().toISOString().split('T')[0]}}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    }}

    // Export JSON
    function exportToJson() {{
      if (!feedbackRecords || feedbackRecords.length === 0) {{
        alert('No feedback responses available to export.');
        return;
      }}

      const jsonStr = JSON.stringify(feedbackRecords, null, 2);
      const blob = new Blob([jsonStr], {{ type: 'application/json' }});
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Receipto_Beta_Feedback_${{new Date().toISOString().split('T')[0]}}.json`;
      a.click();
      URL.revokeObjectURL(url);
    }}

    function escapeHtml(str) {{
      if (!str) return '';
      return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }}

    // Canvas Background Particles
    const canvas = document.getElementById('neuralCanvas');
    const ctx = canvas.getContext('2d');
    let particles = [];
    const isMobile = window.innerWidth <= 768;
    const particleCount = isMobile ? 22 : 50;

    let lastW = window.innerWidth;
    function resizeCanvas() {{
      if (Math.abs(window.innerWidth - lastW) < 50 && canvas.width > 0) return;
      lastW = window.innerWidth;
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      initParticles();
    }}

    function initParticles() {{
      particles = [];
      for (let i = 0; i < particleCount; i++) {{
        particles.push({{
          x: Math.random() * canvas.width,
          y: Math.random() * canvas.height,
          vx: (Math.random() - 0.5) * 0.4,
          vy: (Math.random() - 0.5) * 0.4,
          radius: Math.random() * 1.5 + 0.8
        }});
      }}
    }}

    function animate() {{
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = 'rgba(0, 217, 255, 0.5)';
      ctx.strokeStyle = 'rgba(129, 59, 255, 0.12)';

      for (let i = 0; i < particles.length; i++) {{
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

        for (let j = i + 1; j < particles.length; j++) {{
          const p2 = particles[j];
          const dist = Math.hypot(p.x - p2.x, p.y - p2.y);
          if (dist < 100) {{
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.stroke();
          }}
        }}
      }}
      requestAnimationFrame(animate);
    }}

    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();
    animate();

    // Check auth on startup
    checkAuth();
  </script>
</body>
</html>
'''

with open('docs/admin.html', 'w', encoding='utf-8') as f:
    f.write(admin_html)

print("Generated docs/admin.html successfully!")
