import makeWASocket, {
  DisconnectReason,
  useMultiFileAuthState,
  downloadMediaMessage,
} from "@whiskeysockets/baileys";
import pino from "pino";
import QRCode from "qrcode";
import qrcodeTerminal from "qrcode-terminal";
import fs from "fs";
import http from "http";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

dotenv.config();

// Global crash handlers
process.on("unhandledRejection", (reason, promise) => {
  console.error("⚠️ Unhandled Rejection at:", promise, "reason:", reason);
});
process.on("uncaughtException", (err) => {
  console.error("⚠️ Uncaught Exception:", err);
});

// 1. Initialize Supabase & Gemini Key Pool
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY,
  { auth: { persistSession: false } }
);

// Support comma-separated GEMINI_API_KEYS or single GEMINI_API_KEY
const rawKeys = process.env.GEMINI_API_KEYS || process.env.GEMINI_API_KEY || "";
const geminiApiKeys = rawKeys
  .split(",")
  .map((k) => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

console.log("=========================================");
console.log("🤖 Starting Receipto WhatsApp AI Bot (Baileys Engine)...");
console.log(`🔑 Loaded ${geminiApiKeys.length} Gemini API key(s) for rotation & auto-fallback`);
console.log("⚡ Zero Chromium Overhead: Ultra-lightweight WebSocket connection (~40MB RAM)");
console.log("=========================================");

let latestQrBase64 = null;
let isBotReady = false;
let sock = null;

// 2. Built-in HTTP Health & QR Web Server for Render
const PORT = process.env.PORT || 10000;
const server = http.createServer((req, res) => {
  if (req.url === "/health" || req.url === "/") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        status: "ok",
        ready: isBotReady,
        service: "Receipto WhatsApp AI Bot (Baileys)",
        message: isBotReady
          ? "Bot is live and receiving messages."
          : "Bot is waiting for WhatsApp QR scan. Open /qr to scan.",
      })
    );
  } else if (req.url === "/qr") {
    res.writeHead(200, { "Content-Type": "text/html" });
    if (isBotReady) {
      res.end(`
        <!DOCTYPE html>
        <html>
        <head><title>Receipto Bot - Connected</title><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <body style="font-family:system-ui,-apple-system,sans-serif;text-align:center;padding:50px 20px;background:#0d1117;color:white;">
          <div style="max-width:400px;margin:auto;background:#161b22;padding:30px;border-radius:16px;border:1px solid #30363d;">
            <h1 style="color:#25D366;font-size:42px;margin:0 0 10px 0;">✅</h1>
            <h2 style="color:#25D366;margin:0 0 12px 0;">Bot is Live & Connected!</h2>
            <p style="color:#8b949e;line-height:1.5;">Your WhatsApp account is authenticated. Send or forward any receipt photo to your bot on WhatsApp.</p>
          </div>
        </body>
        </html>
      `);
    } else if (latestQrBase64) {
      res.end(`
        <!DOCTYPE html>
        <html>
        <head><title>Receipto Bot - Scan QR</title><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <body style="font-family:system-ui,-apple-system,sans-serif;text-align:center;padding:40px 20px;background:#0d1117;color:white;">
          <div style="max-width:420px;margin:auto;background:#161b22;padding:30px;border-radius:16px;border:1px solid #30363d;">
            <h2 style="margin:0 0 8px 0;">Connect WhatsApp Bot</h2>
            <p style="color:#8b949e;font-size:14px;margin-bottom:20px;">Open WhatsApp &gt; Settings &gt; Linked Devices &gt; Link a Device</p>
            <img src="${latestQrBase64}" style="width:280px;height:280px;border-radius:12px;background:white;padding:8px;" />
            <p style="color:#8b949e;font-size:12px;margin-top:20px;">Page auto-refreshes every 8 seconds...</p>
          </div>
          <script>setTimeout(() => location.reload(), 8000);</script>
        </body>
        </html>
      `);
    } else {
      res.end(`
        <!DOCTYPE html>
        <html>
        <head><title>Receipto Bot - Starting</title><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <body style="font-family:system-ui,-apple-system,sans-serif;text-align:center;padding:50px 20px;background:#0d1117;color:white;">
          <div style="max-width:400px;margin:auto;background:#161b22;padding:30px;border-radius:16px;border:1px solid #30363d;">
            <h2 style="margin:0 0 12px 0;">Initializing Bot...</h2>
            <p style="color:#8b949e;">Connecting to WhatsApp servers, please wait a moment.</p>
          </div>
          <script>setTimeout(() => location.reload(), 5000);</script>
        </body>
        </html>
      `);
    }
  } else {
    res.writeHead(404);
    res.end();
  }
});

server.listen(PORT, () => {
  console.log(`🌐 Health check & QR web server listening on port ${PORT}`);
});

function parseAndNormalizeDate(rawDate) {
  if (!rawDate || typeof rawDate !== "string") return null;
  const clean = rawDate.trim();

  // YYYY-MM-DD or YYYY/MM/DD
  const ymdMatch = clean.match(/^(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})$/);
  if (ymdMatch) {
    return `${ymdMatch[1]}-${ymdMatch[2].padStart(2, "0")}-${ymdMatch[3].padStart(2, "0")}`;
  }

  // DD-MM-YYYY or DD/MM/YYYY
  const dmyMatch = clean.match(/^(\d{1,2})[-\/](\d{1,2})[-\/](\d{4})$/);
  if (dmyMatch) {
    return `${dmyMatch[3]}-${dmyMatch[2].padStart(2, "0")}-${dmyMatch[1].padStart(2, "0")}`;
  }

  // DD-MM-YY or DD/MM/YY
  const dmyyMatch = clean.match(/^(\d{1,2})[-\/](\d{1,2})[-\/](\d{2})$/);
  if (dmyyMatch) {
    return `20${dmyyMatch[3]}-${dmyyMatch[2].padStart(2, "0")}-${dmyyMatch[1].padStart(2, "0")}`;
  }

  // Month text dictionary (e.g. "15 May 2028", "May 15, 2028", "15-May-2028")
  const months = { jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12 };
  const parts = clean.toLowerCase().replace(/[,-]/g, " ").split(/\s+/);
  let year = null, month = null, day = null;
  for (const p of parts) {
    for (const m in months) {
      if (p.startsWith(m)) { month = months[m]; break; }
    }
    if (/^\d{4}$/.test(p)) year = parseInt(p);
    else if (/^\d{1,2}$/.test(p)) {
      if (!day) day = parseInt(p);
      else if (!year) year = 2000 + parseInt(p);
    }
  }
  if (year && month && day) {
    return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
  }
  return null;
}

function calculateExpiryDate(purchaseDateStr, period, unit) {
  let d;
  try {
    const norm = parseAndNormalizeDate(purchaseDateStr);
    d = norm ? new Date(`${norm}T00:00:00Z`) : new Date();
    if (isNaN(d.getTime())) d = new Date();
  } catch (_) {
    d = new Date();
  }

  const u = (unit || "months").toLowerCase();
  const rawP = Number(period);
  // Default to 12 months if duration is missing or an invalid fractional return window (< 1)
  const p = (rawP && rawP >= 1) ? Math.round(rawP) : 12;

  if (u.startsWith("y")) {
    d.setUTCFullYear(d.getUTCFullYear() + p);
  } else if (u.startsWith("d")) {
    d.setUTCDate(d.getUTCDate() + p);
  } else {
    d.setUTCMonth(d.getUTCMonth() + p);
  }
  return d.toISOString().split("T")[0];
}

function calculateStatus(expiryDateStr) {
  if (!expiryDateStr) return "ACTIVE";
  const norm = parseAndNormalizeDate(expiryDateStr);
  if (!norm) return "ACTIVE";
  const exp = new Date(`${norm}T00:00:00Z`);
  if (isNaN(exp.getTime())) return "ACTIVE";

  const now = new Date();
  const today = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
  const diffDays = Math.ceil((exp.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return "EXPIRED";
  if (diffDays <= 30) return "EXPIRING SOON";
  return "ACTIVE";
}

function isDurableProduct(name, category) {
  const durableCats = [
    "electronics",
    "mobile & gadgets",
    "computers",
    "home appliances",
    "automotive",
  ];
  const cat = (category || "").toLowerCase().trim();
  if (durableCats.some((dc) => cat.includes(dc))) return true;

  const n = (name || "").toLowerCase();
  const durableKeywords = [
    "phone", "iphone", "galaxy", "pixel", "oneplus", "smartphone", "mobile",
    "laptop", "macbook", "ipad", "tablet", "pc", "computer",
    "tv", "television", "monitor", "display", "screen",
    "iron", "dryer", "hair dryer", "straightener", "trimmer", "shaver",
    "kettle", "grinder", "mixer", "blender", "cooktop", "induction", "oven", "microwave",
    "fridge", "refrigerator", "washing machine", "purifier",
    "speaker", "soundbar", "headphone", "earphone", "airpod", "earbud", "buds",
    "watch", "smartwatch",
    "camera", "charger", "adapter", "power bank", "cable",
    "fan", "ac", "air conditioner", "cooler", "heater", "geyser", "vacuum",
  ];
  return durableKeywords.some((k) => n.includes(k));
}

// 3. Start WhatsApp Bot Connection using Baileys with Cloud Session Persistence
async function startWhatsAppBot() {
  // Restore persistent session from Supabase cloud database if container was redeployed
  if (!fs.existsSync("./baileys_auth/creds.json")) {
    try {
      const { data: sessionRow } = await supabase
        .from("whatsapp_users")
        .select("user_id")
        .eq("phone_number", "baileys_session_creds")
        .maybeSingle();

      if (sessionRow?.user_id) {
        try {
          const parsed = JSON.parse(sessionRow.user_id);
          // Only restore if it contains genuine Baileys cryptographic keys
          if (parsed && parsed.noiseKey && parsed.registrationId) {
            fs.mkdirSync("./baileys_auth", { recursive: true });
            fs.writeFileSync("./baileys_auth/creds.json", sessionRow.user_id);
            console.log("🔄 Restored valid WhatsApp session from Supabase cloud!");
          }
        } catch (_) {}
      }
    } catch (e) {
      console.warn("⚠️ Could not restore cloud session:", e.message);
    }
  }

  const { state, saveCreds } = await useMultiFileAuthState("./baileys_auth");

  sock = makeWASocket({
    auth: state,
    logger: pino({ level: "silent" }),
    printQRInTerminal: false,
    syncFullHistory: false,
    browser: ["Receipto Bot", "Chrome", "1.0.0"],
  });

  sock.ev.on("creds.update", async () => {
    await saveCreds();
    // Persist session to Supabase so redeployments never lose connection
    try {
      if (fs.existsSync("./baileys_auth/creds.json")) {
        const credsContent = fs.readFileSync("./baileys_auth/creds.json", "utf8");
        await supabase.from("whatsapp_users").upsert({
          phone_number: "baileys_session_creds",
          user_id: credsContent,
        });
      }
    } catch (e) {
      console.warn("⚠️ Could not sync session to Supabase:", e.message);
    }
  });

  sock.ev.on("connection.update", async (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      console.log("\n⚡ QR CODE GENERATED! Scan from WhatsApp > Linked Devices:");
      try {
        qrcodeTerminal.generate(qr, { small: true });
        latestQrBase64 = await QRCode.toDataURL(qr);
      } catch (err) {
        console.error("Could not process QR code:", err);
      }
    }

    if (connection === "open") {
      isBotReady = true;
      latestQrBase64 = null;
      console.log("\n🎉 =====================================================");
      console.log("✅ RECEIPTO WHATSAPP BOT IS LIVE & CONNECTED!");
      console.log("🚀 Forward any receipt photo to this number on WhatsApp!");
      console.log("=====================================================\n");

      // Save creds to Supabase on first successful open
      try {
        if (fs.existsSync("./baileys_auth/creds.json")) {
          const credsContent = fs.readFileSync("./baileys_auth/creds.json", "utf8");
          await supabase.from("whatsapp_users").upsert({
            phone_number: "baileys_session_creds",
            user_id: credsContent,
          });
        }
      } catch (_) {}
    } else if (connection === "close") {
      isBotReady = false;
      const statusCode = lastDisconnect?.error?.output?.statusCode;
      const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
      console.log(
        `⚠️ Connection closed (code: ${statusCode}). Reconnecting: ${shouldReconnect}`
      );
      if (shouldReconnect) {
        setTimeout(startWhatsAppBot, 3000);
      } else {
        console.log("❌ Logged out. Clearing cloud session credentials.");
        try {
          await supabase.from("whatsapp_users").delete().eq("phone_number", "baileys_session_creds");
        } catch (_) {}
      }
    }
  });

  // 4. Message Listener with Stealth Mode & 1-Tap Verification
  sock.ev.on("messages.upsert", async (m) => {
    try {
      const msg = m.messages?.[0];
      if (!msg) return;

      const remoteJid = msg.key.remoteJid;
      if (!remoteJid || remoteJid.endsWith("@g.us")) return; // Ignore group messages

      // Extract sender phone digits
      const senderPhoneDigits = remoteJid.split("@")[0].replace(/\D/g, "");
      const cleanPhone = `+${senderPhoneDigits}`;

      // Extract message text (conversation, caption, extended text)
      const text = (
        msg.message?.conversation ||
        msg.message?.extendedTextMessage?.text ||
        msg.message?.imageMessage?.caption ||
        ""
      ).trim();

      // Don't process our own automated bot replies to prevent infinite loops!
      if (
        msg.key.fromMe &&
        (text.startsWith("🧾 *Receipt Saved") ||
          text.startsWith("🎉 *Receipto Connected") ||
          text.startsWith("🔍 Analyzing receipt") ||
          text.startsWith("⚠️") ||
          text.startsWith("❌"))
      ) {
        return;
      }

      console.log(`📩 Incoming message from ${cleanPhone} (${remoteJid}): "${text.substring(0, 30)}"`);

      // Handle 1-Tap Verification Code (e.g., "VERIFY 849201")
      const verifyMatch = text.match(/^VERIFY\s+(\d{4,6})/i);
      if (verifyMatch) {
        const inputCode = verifyMatch[1];
        console.log(`🔐 Processing verification code '${inputCode}' from: ${cleanPhone}`);

        // Search for matching pending verification in Supabase (stored as 'pending:<CODE>:<USER_ID>')
        const { data: records, error: searchErr } = await supabase
          .from("whatsapp_users")
          .select("phone_number, user_id")
          .like("user_id", `pending:${inputCode}:%`);

        if (searchErr) {
          console.error("Database error looking up verification:", searchErr);
          return;
        }

        if (records && records.length > 0) {
          const match = records[0];
          const parts = match.user_id.split(":");
          // Format: pending:<CODE>:<USER_ID>
          const realUserId = parts.slice(2).join(":");

          // Update main record to verified user_id
          await supabase
            .from("whatsapp_users")
            .update({ user_id: realUserId })
            .eq("phone_number", match.phone_number);

          // Also upsert incoming sender ID (LID / cleanPhone) so future receipts from this chat always resolve
          if (cleanPhone !== match.phone_number) {
            await supabase.from("whatsapp_users").upsert({
              phone_number: cleanPhone,
              user_id: realUserId,
            });
          }

          console.log(`✅ WhatsApp successfully linked for user: ${realUserId}`);
          await sock.sendMessage(
            remoteJid,
            {
              text:
                "🎉 *Receipto Connected Successfully!*\n\n" +
                "Your WhatsApp is now verified and linked to your Receipto account.\n\n" +
                "📸 *How to use:* Simply forward or snap any receipt photo here, and Receipto AI will instantly extract and track it for you!",
            },
            { quoted: msg }
          );
          return;
        } else {
          console.log(`⚠️ Invalid or expired verification code: ${inputCode}`);
          await sock.sendMessage(
            remoteJid,
            {
              text: "❌ Invalid or expired verification code. Please request a new code from Receipto Profile > Connect WhatsApp.",
            },
            { quoted: msg }
          );
          return;
        }
      }

      // STEALTH MODE: Check if sender is a verified Receipto user
      const { data: userRecords, error: userError } = await supabase
        .from("whatsapp_users")
        .select("user_id, phone_number")
        .or(`phone_number.eq.${cleanPhone},phone_number.eq.${senderPhoneDigits},phone_number.eq.${remoteJid}`);

      if (userError) {
        console.error("Error querying whatsapp_users:", userError);
        return;
      }

      const verifiedRecord = userRecords?.find(
        (r) => r.user_id && !r.user_id.startsWith("pending:")
      );

      // STEALTH MODE: Silently ignore all non-verified users
      if (!verifiedRecord) {
        return;
      }

      const userId = verifiedRecord.user_id;

      // Check if message is a receipt photo
      const imageMsg = msg.message?.imageMessage;

      // Friendly greeting for verified user
      if (!imageMsg && /^(hi|hy|hello|hey|help)\b/i.test(text)) {
        await sock.sendMessage(
          remoteJid,
          {
            text:
              "👋 *Hi! I am your Receipto AI Assistant.*\n\n" +
              "📸 Simply forward or snap any receipt photo here, and I will automatically extract the store, total, items, and warranty for your Receipto app!",
          },
          { quoted: msg }
        );
        return;
      }

      // Handle Receipt Image from verified user
      if (imageMsg) {
        console.log(`📸 Receipt image received from verified user (${cleanPhone}). Downloading...`);

        // Send processing status
        await sock.sendMessage(
          remoteJid,
          { text: "🔍 Analyzing receipt with Receipto AI... Please wait a moment." },
          { quoted: msg }
        );

        // Download image buffer directly from WhatsApp
        const imageBuffer = await downloadMediaMessage(msg, "buffer", {});
        const base64Image = imageBuffer.toString("base64");
        const mimeType = imageMsg.mimetype || "image/jpeg";
        const fileExt = mimeType.includes("png") ? "png" : "jpg";

        // Upload receipt image to Supabase Storage bucket 'receipts' so it displays natively in the app
        let imageUrl = null;
        try {
          const storagePath = `${userId}/receipt_wa_${Date.now()}.${fileExt}`;
          const { data: uploadData, error: uploadErr } = await supabase.storage
            .from("receipts")
            .upload(storagePath, imageBuffer, {
              contentType: mimeType,
              upsert: true,
            });

          if (!uploadErr && uploadData) {
            const { data: pubData } = supabase.storage
              .from("receipts")
              .getPublicUrl(storagePath);
            imageUrl = pubData?.publicUrl || null;
            console.log(`📸 Image successfully uploaded to Supabase Storage: ${imageUrl}`);
          } else {
            console.warn(`⚠️ Supabase Storage upload failed:`, uploadErr?.message);
          }
        } catch (uploadException) {
          console.warn(`⚠️ Supabase Storage exception:`, uploadException.message);
        }

        console.log("🤖 Extracting receipt details via Gemini AI (Multi-Key Rotation)...");
        const extracted = await extractReceiptData(base64Image, mimeType);
        console.log("📋 Extracted Data:", JSON.stringify(extracted));

        // Format data for Supabase receipts table
        const merchantName = extracted.merchant_name || "Scanned Receipt";
        const totalAmount = parseFloat(extracted.total_amount) || 0.0;
        const purchaseDate = extracted.purchase_date || new Date().toISOString().split("T")[0];
        const category = extracted.category || "General";
        const items = extracted.items || [];
        const hasWarranty = extracted.warranty?.has_warranty || false;
        const warrantyDurationMonths = extracted.warranty?.duration_months || 0;
        const warrantyExpiryDate = extracted.warranty?.expiry_date || null;

        // Insert into Supabase receipts table
        const { data: insertedReceipt, error: insertError } = await supabase
          .from("receipts")
          .insert({
            user_id: userId,
            merchant_name: merchantName,
            total: totalAmount,
            grand_total: totalAmount,
            date: purchaseDate,
            time: extracted.time || null,
            category: category,
            currency: extracted.currency || "₹",
            image_url: imageUrl,
            invoice_number: extracted.invoice_number || null,
            receipt_number: extracted.invoice_number || null,
            gst_number: extracted.gst_number || null,
            payment_method: extracted.payment_method || null,
            subtotal: parseFloat(extracted.subtotal) || null,
            tax: parseFloat(extracted.tax) || null,
            discount: parseFloat(extracted.discount) || null,
            raw_text: JSON.stringify(extracted),
            is_deleted: false,
          })
          .select("id")
          .single();

        if (insertError) {
          console.error("❌ Failed to save receipt to Supabase:", insertError);
          await sock.sendMessage(
            remoteJid,
            { text: "⚠️ Error saving receipt to your database. Please try again!" },
            { quoted: msg }
          );
          return;
        }

        console.log(`💾 Receipt #${insertedReceipt.id} saved for user ${userId}`);

        // Insert itemized list if items exist
        if (items.length > 0 && insertedReceipt?.id) {
          const itemRows = items.map((it) => {
            const price = parseFloat(it.price) || 0.0;
            const qty = parseInt(it.quantity) || 1;
            const tot = parseFloat(it.total_price) || (price * qty);
            return {
              receipt_id: insertedReceipt.id,
              name: it.name || "Item",
              price: tot,
              unit_price: price,
              total_price: tot,
              quantity: qty,
            };
          });

          const { error: itemsError } = await supabase.from("receipt_items").insert(itemRows);
          if (itemsError) {
            console.warn("⚠️ Could not save itemized rows:", itemsError);
          }
        }

        // Insert warranty records into Supabase warranties table
        const warrantiesToInsert = [];

        // 1. Process item-level warranties / product expiration dates
        for (const it of items) {
          const hasExplicitExpiry = Boolean(it.warranty_expiry && it.warranty_expiry.toString().trim() !== "");
          const rawDuration = Number(it.warranty_period);
          const hasDuration = !isNaN(rawDuration) && rawDuration >= 1;
          const isDurable = isDurableProduct(it.name, it.category || category);
          const isWarrantable = it.warranty_available === true || hasExplicitExpiry || hasDuration || isDurable;

          if (isWarrantable) {
            const unit = (it.warranty_unit || "months").toLowerCase();
            const duration = hasDuration ? Math.round(rawDuration) : (isDurable ? 12 : 12);

            let exp = null;
            if (hasExplicitExpiry) {
              exp = parseAndNormalizeDate(it.warranty_expiry.toString());
            }
            if (!exp) {
              exp = calculateExpiryDate(purchaseDate, duration, unit);
            }

            const status = calculateStatus(exp);

            warrantiesToInsert.push({
              user_id: userId,
              receipt_id: insertedReceipt.id,
              product_name: it.name || `${merchantName} Product`,
              brand: it.brand || merchantName,
              merchant_name: merchantName,
              invoice_number: extracted.invoice_number || null,
              purchase_date: purchaseDate,
              warranty_period: duration,
              warranty_unit: unit,
              expiry_date: exp,
              image_url: imageUrl,
              status: status,
            });
          }
        }

        // 2. Fallback: If no item matched but receipt-level warranty was detected
        if (warrantiesToInsert.length === 0 && (hasWarranty || (warrantyDurationMonths && Number(warrantyDurationMonths) >= 1))) {
          const rawDur = Number(warrantyDurationMonths);
          const duration = (!isNaN(rawDur) && rawDur >= 1) ? Math.round(rawDur) : 12;

          let exp = null;
          if (warrantyExpiryDate) {
            exp = parseAndNormalizeDate(warrantyExpiryDate.toString());
          }
          if (!exp) {
            exp = calculateExpiryDate(purchaseDate, duration, "months");
          }

          const status = calculateStatus(exp);
          const prodName = extracted.warranty?.product_name || items[0]?.name || `${merchantName} Product`;
          const brandName = extracted.warranty?.brand || items[0]?.brand || merchantName;

          warrantiesToInsert.push({
            user_id: userId,
            receipt_id: insertedReceipt.id,
            product_name: prodName,
            brand: brandName,
            merchant_name: merchantName,
            invoice_number: extracted.invoice_number || null,
            purchase_date: purchaseDate,
            warranty_period: duration,
            warranty_unit: "months",
            expiry_date: exp,
            image_url: imageUrl,
            status: status,
          });
        }

        if (warrantiesToInsert.length > 0) {
          const { error: wErr } = await supabase.from("warranties").insert(warrantiesToInsert);
          if (wErr) {
            console.error("⚠️ Failed to insert warranty into Supabase:", wErr);
          } else {
            console.log(`🛡️ Successfully saved ${warrantiesToInsert.length} warranty record(s) for receipt #${insertedReceipt.id}`);
          }
        }

        // Format success summary reply
        const itemsListText =
          items.length > 0
            ? `\n\n🛒 *Items (${items.length}):*\n` +
              items.slice(0, 5).map((it) => ` • ${it.name} - ₹${it.price}`).join("\n") +
              (items.length > 5 ? `\n... and ${items.length - 5} more` : "")
            : "";

        const warrantyText = warrantiesToInsert.length > 0
          ? `\n🛡️ *Warranty Protected:* ${warrantiesToInsert.length} item(s) (${warrantiesToInsert[0].warranty_period} Months, Expires: ${warrantiesToInsert[0].expiry_date})`
          : "";

        const replyMessage =
          `🧾 *Receipt Saved to Receipto!*\n\n` +
          `🏪 *Store:* ${merchantName}\n` +
          `💰 *Total:* ₹${totalAmount.toFixed(2)}\n` +
          `📅 *Date:* ${purchaseDate}\n` +
          `🏷️ *Category:* ${category}` +
          itemsListText +
          warrantyText +
          `\n\n📱 *Open Receipto app to see your updated dashboard!*`;

        await sock.sendMessage(remoteJid, { text: replyMessage }, { quoted: msg });
        console.log(`✅ Success reply delivered to ${cleanPhone}`);
      }
    } catch (err) {
      console.error("❌ Error processing message:", err);
    }
  });
}

// 5. Helper: Extract structured data using Google Gemini 3 Flash with multi-key rotation & fallback
async function extractReceiptData(base64Data, mimeType) {
  if (geminiApiKeys.length === 0) {
    console.error("❌ No Gemini API keys configured in GEMINI_API_KEYS or GEMINI_API_KEY");
    return {
      merchant_name: "Scanned Receipt",
      total_amount: 0.0,
      purchase_date: new Date().toISOString().split("T")[0],
      category: "General",
      currency: "₹",
      items: [],
      warranty: { has_warranty: false },
    };
  }

  const prompt = `Analyze this receipt image and extract structured JSON data.
Strictly return ONLY a valid raw JSON object, without markdown code fences or backticks:
{
  "merchant_name": "Store or merchant name",
  "invoice_number": "Invoice, cash memo, or bill number if available, else null",
  "purchase_date": "YYYY-MM-DD",
  "time": "HH:MM",
  "category": "One of: Electronics, Groceries, Food & Dining, Fuel, Shopping, Fashion, Furniture, Home Appliances, Healthcare, Beauty & Personal Care, Travel, Entertainment, Education, Utilities, Office Supplies, Sports, Automotive, Accessories, Books, Mobile & Gadgets, Computers, Subscription, Others",
  "currency": "₹",
  "subtotal": 0.00,
  "tax": 0.00,
  "discount": 0.00,
  "total_amount": 0.00,
  "payment_method": "Cash, UPI, Credit Card, Debit Card, etc. or null",
  "gst_number": "GSTIN or tax number if available, else null",
  "items": [
    {
      "name": "Item or product name",
      "price": 0.00,
      "quantity": 1,
      "brand": "Brand name if detectable or null",
      "category": "Matching category from above",
      "warranty_available": false,
      "warranty_period": 0,
      "warranty_unit": "months",
      "warranty_expiry": null
    }
  ],
  "warranty": {
    "has_warranty": false,
    "product_name": "Name of primary product under warranty or null",
    "brand": "Brand or null",
    "duration_months": 0,
    "expiry_date": null
  }
}

CRITICAL RULES FOR EXPIRY DATE & WARRANTY EXTRACTION:
1. EXPIRY DATES ON GROCERY / FOOD / MEDICINE / COSMETICS / BEAUTY:
   - Extract ANY printed expiry, expiration, best before, use by, valid till, or expiry date for each line item!
   - For grocery, dairy, food, beverages, medicines, cosmetics, skincare, and packaged items: receipts frequently print "Expiry: DD-MM-YYYY", "Exp:", "Use By:", or "Best Before:".
   - YOU MUST extract this printed date into "warranty_expiry" (normalized to standard ISO YYYY-MM-DD) and set "warranty_available": true!
   - Do NOT ignore food/dairy/medicine/beauty expiration dates! Treat all product expiry, validity, and warranty end dates as "warranty_expiry".

2. MANUFACTURER WARRANTY ON ELECTRONICS / APPLIANCES / GADGETS:
   - For any electronic devices, mobile phones, smartphones, computers, laptops, audio gear, TVs, home appliances, kitchen appliances, gadgets, chargers, power banks, and electric tools:
     a) If an explicit warranty duration is printed (e.g. 1 Year, 2 Years, 24 Months, 36 Months), set "warranty_period" (e.g. 12, 24), "warranty_unit": "months", and "warranty_available": true!
     b) Even if NO warranty duration is explicitly printed on the cash memo, standard manufacturer warranty applies to durable electronics! Assign "warranty_period": 12, "warranty_unit": "months", "warranty_available": true, and compute "warranty_expiry" as purchase_date + 12 months.
     c) Also set "has_warranty": true on the receipt level!

3. RETURN / REPLACEMENT POLICIES VS WARRANTY:
   - Distinguish Return/Replacement Windows (e.g., 7 days return, 10 days replacement policy) from Manufacturer Warranty or Expiry Periods.
   - NEVER set a 7-day or 10-day return policy as the warranty duration! (e.g., do NOT set duration_months: 0.37). Always preserve the true product warranty.

4. DATES:
   - All extracted dates (purchase date and expiry dates) must be normalized to standard ISO format (YYYY-MM-DD).
   - Assume currency is "₹" for Indian receipts.`;

  let lastError = null;

  for (let attempt = 0; attempt < geminiApiKeys.length; attempt++) {
    const keyIndex = (currentKeyIndex + attempt) % geminiApiKeys.length;
    const apiKey = geminiApiKeys[keyIndex];

    try {
      console.log(`🤖 Invoking Gemini AI with Key #${keyIndex + 1}...`);
      const genAI = new GoogleGenerativeAI(apiKey);
      
      let result;
      try {
        const model = genAI.getGenerativeModel({ model: "gemini-3-flash-preview" });
        result = await model.generateContent([
          prompt,
          {
            inlineData: {
              data: base64Data,
              mimeType: mimeType,
            },
          },
        ]);
      } catch (primaryErr) {
        console.warn(`⚠️ gemini-3-flash-preview failed, trying gemini-3.5-flash:`, primaryErr.message);
        const fallbackModel = genAI.getGenerativeModel({ model: "gemini-3.5-flash" });
        result = await fallbackModel.generateContent([
          prompt,
          {
            inlineData: {
              data: base64Data,
              mimeType: mimeType,
            },
          },
        ]);
      }

      const rawText = result.response.text();
      const cleaned = rawText.replace(/```json/g, "").replace(/```/g, "").trim();
      const parsed = JSON.parse(cleaned);

      // Infer merchant name if missing or placeholder
      if (
        !parsed.merchant_name ||
        parsed.merchant_name.toLowerCase().includes("store/merchant") ||
        parsed.merchant_name.toLowerCase() === "scanned receipt" ||
        parsed.merchant_name === "null"
      ) {
        if (parsed.items && parsed.items.length > 0 && parsed.items[0].name) {
          const brandWord = parsed.items[0].name.split(/[\s(]/)[0];
          parsed.merchant_name = `${brandWord} Store`;
        } else {
          parsed.merchant_name = "Retail Store";
        }
      }

      currentKeyIndex = (currentKeyIndex + 1) % geminiApiKeys.length;
      return parsed;
    } catch (e) {
      console.warn(`⚠️ Gemini Key #${keyIndex + 1} failed: ${e.message}`);
      lastError = e;
      currentKeyIndex = (currentKeyIndex + 1) % geminiApiKeys.length;
    }
  }

  console.error("❌ All Gemini API keys failed:", lastError);
  return {
    merchant_name: "Scanned Receipt",
    total_amount: 0.0,
    purchase_date: new Date().toISOString().split("T")[0],
    category: "General",
    currency: "₹",
    items: [],
    warranty: { has_warranty: false },
  };
}

// Start the bot
startWhatsAppBot();
