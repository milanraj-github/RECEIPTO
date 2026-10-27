import pkg from "whatsapp-web.js";
const { Client, LocalAuth } = pkg;
import QRCode from "qrcode";
import qrcodeTerminal from "qrcode-terminal";
import fs from "fs";
import http from "http";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

dotenv.config();

// Global crash handlers to catch unhandled async errors in Docker/Puppeteer
process.on("unhandledRejection", (reason, promise) => {
  console.error("⚠️ Unhandled Rejection at:", promise, "reason:", reason);
});
process.on("uncaughtException", (err) => {
  console.error("⚠️ Uncaught Exception:", err);
});

// 1. Initialize Supabase & Gemini Key Pool
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

// Support comma-separated GEMINI_API_KEYS or single GEMINI_API_KEY
const rawKeys = process.env.GEMINI_API_KEYS || process.env.GEMINI_API_KEY || "";
const geminiApiKeys = rawKeys
  .split(",")
  .map((k) => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

console.log("=========================================");
console.log("🤖 Starting Receipto WhatsApp AI Bot...");
console.log(`🔑 Loaded ${geminiApiKeys.length} Gemini API key(s) for rotation & auto-fallback`);
console.log("=========================================");

let latestQrBase64 = null;
let isBotReady = false;

// Determine platform Chrome binary
const isWindows = process.platform === "win32";
const executablePath =
  process.env.PUPPETEER_EXECUTABLE_PATH ||
  (isWindows
    ? "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
    : "/usr/bin/chromium");

// 2. Initialize WhatsApp Web Client using Chrome & persistent session
const client = new Client({
  authStrategy: new LocalAuth({
    dataPath: "./.wwebjs_auth",
  }),
  puppeteer: {
    headless: true,
    executablePath: executablePath,
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
      "--disable-accelerated-2d-canvas",
      "--no-first-run",
      "--no-zygote",
      "--disable-gpu",
      "--single-process",
      "--disable-software-rasterizer",
    ],
  },
});

// 3. Display & Save QR Code for User Scan
client.on("qr", async (qr) => {
  console.log("\n⚡ QR CODE GENERATED! Scan from WhatsApp > Linked Devices:");
  try {
    // Print ASCII QR code in terminal logs (great for Render deploy logs)
    qrcodeTerminal.generate(qr, { small: true });

    // Store base64 data URL for web browser scanning (/qr)
    latestQrBase64 = await QRCode.toDataURL(qr);

    const qrPath = "./qr.png";
    await QRCode.toFile(qrPath, qr, {
      width: 450,
      margin: 2,
      color: { dark: "#000000", light: "#ffffff" },
    });
    console.log("📸 Saved QR image to: " + qrPath);
  } catch (err) {
    console.error("Could not process QR code:", err);
  }
});

// 4. Authenticated & Ready Event
client.on("ready", () => {
  isBotReady = true;
  latestQrBase64 = null;
  console.log("\n🎉 =====================================================");
  console.log("✅ RECEIPTO WHATSAPP BOT IS LIVE & CONNECTED!");
  console.log("🚀 Forward any receipt photo to this number on WhatsApp!");
  console.log("=====================================================\n");
});

// 5. Built-in HTTP Health & QR Web Server for Render
const PORT = process.env.PORT || 10000;
const server = http.createServer((req, res) => {
  if (req.url === "/health" || req.url === "/") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        status: "ok",
        ready: isBotReady,
        service: "Receipto WhatsApp AI Bot",
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
            <p style="color:#8b949e;">Generating QR code, please wait a moment.</p>
          </div>
          <script>setTimeout(() => location.reload(), 3000);</script>
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

// 5. Message Listener
client.on("message", async (message) => {
  // Fast check: Ignore group chats, status broadcasts
  if (
    !message ||
    !message.from ||
    message.from.endsWith("@g.us") ||
    message.from.includes("status@broadcast")
  ) {
    return;
  }

  // Resolve true phone number (handles LIDs seamlessly)
  let rawPhone = message.from.replace("@c.us", "").replace("@lid", "");
  try {
    const contact = await message.getContact();
    if (contact && contact.number) {
      rawPhone = contact.number;
    }
  } catch (_) {}

  const formattedPhone = `+${rawPhone}`;
  console.log(`\n📩 Incoming message from ${formattedPhone} (hasMedia: ${message.hasMedia})`);

  try {
    // A0. Handle 1-Tap Verification Code (e.g. "VERIFY 849201")
    if (!message.hasMedia) {
      const trimmedBody = (message.body || "").trim();
      const verifyMatch = trimmedBody.match(/^VERIFY\s+(\d{4,6})/i);
      if (verifyMatch) {
        const inputCode = verifyMatch[1];
        console.log(`🔐 Verification request received with code: ${inputCode} from ${formattedPhone}`);

        // Search for matching pending verification in Supabase
        const { data: records, error } = await supabase
          .from("whatsapp_users")
          .select("phone_number, user_id")
          .like("user_id", `pending:${inputCode}:%`);

        if (error) {
          console.error("Database error looking up verification:", error);
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

          // Also upsert incoming sender ID (LID / formattedPhone) so future receipts from this chat always resolve
          if (formattedPhone !== match.phone_number) {
            await supabase.from("whatsapp_users").upsert({
              phone_number: formattedPhone,
              user_id: realUserId,
            });
          }

          console.log(`✅ Successfully verified & linked ${match.phone_number} (${formattedPhone}) to user ${realUserId}`);
          await message.reply(
            "🎉 *WhatsApp Successfully Linked!* ✅\n\n" +
            "Your phone number is now verified and linked to your *Receipto* account.\n\n" +
            "📸 You can now forward any receipt photos or invoices here anytime to automatically save them to your app!"
          );
          return;
        } else {
          console.log(`⚠️ No matching pending verification found for code: ${inputCode}`);
          await message.reply(
            "⚠️ *Invalid or expired verification code.*\n\n" +
            "Please go to the Receipto app and tap *Connect WhatsApp* to start a fresh verification."
          );
          return;
        }
      }
    }

    // 🔒 STEALTH MODE & AUTHORIZATION CHECK
    // Only verified, linked users can activate the bot!
    const phoneVariants = [
      rawPhone,
      formattedPhone,
      rawPhone.replace(/^91/, ""),
      `+91${rawPhone.replace(/^91/, "")}`,
    ];

    const { data: userLinks } = await supabase
      .from("whatsapp_users")
      .select("user_id")
      .in("phone_number", phoneVariants)
      .limit(1);

    const userId = userLinks && userLinks.length > 0 ? userLinks[0].user_id : null;

    // If the sender is NOT a linked user (or pending verification), SILENTLY IGNORE!
    // Acts 100% like a normal WhatsApp account. Zero automated messages or interruptions.
    if (!userId || userId.startsWith("pending:")) {
      console.log(`🤫 Unlinked contact message from ${formattedPhone}. Silently ignored (Stealth mode).`);
      return;
    }

    // A. Handle Text Greeting (for Verified Users only)
    if (!message.hasMedia) {
      const text = (message.body || "").trim().toLowerCase();
      if (
        text.includes("hi") ||
        text.includes("hy") ||
        text.includes("hey") ||
        text.includes("hello") ||
        text.includes("start") ||
        text.includes("help")
      ) {
        await message.reply(
          "👋 *Welcome to Receipto AI Assistant!* 🧾\n\n" +
          "Simply send or forward any *receipt photo* or *invoice PDF* here.\n\n" +
          "⚡ I will automatically:\n" +
          "• Extract merchant, items & total amount\n" +
          "• Detect warranty period & expiration date\n" +
          "• Save everything directly to your Receipto mobile app!\n\n" +
          "📸 *Try sending a receipt photo right now!*"
        );
        return;
      }
    }

    // B. Handle Receipt Image or Document (for Verified Users only)
    if (message.hasMedia) {
      await message.reply(
        "🔍 *Analyzing your receipt...*\n_Please wait a few seconds!_ ⏳"
      );

      console.log("📥 Downloading media from WhatsApp...");
      await new Promise((r) => setTimeout(r, 800));

      let media = null;
      for (let attempt = 1; attempt <= 3; attempt++) {
        try {
          media = await message.downloadMedia();
          if (media && media.data) break;
        } catch (e) {
          console.log(`Download attempt ${attempt} failed: ${e.message}`);
        }
        await new Promise((r) => setTimeout(r, 1200));
      }

      if (!media || !media.data) {
        throw new Error("Could not download media file");
      }

      console.log(`🧠 Running Gemini 3 Flash Vision OCR on ${media.mimetype}...`);
      const extracted = await extractReceiptData(media.data, media.mimetype);
      console.log("📊 Extracted Receipt Data:", extracted);

      // Upload media to Supabase Storage
      const fileExt = (media.mimetype && media.mimetype.includes("pdf")) ? "pdf" : "jpg";
      const fileName = `${userId}/receipt_wa_${Date.now()}.${fileExt}`;
      const mediaBuffer = Buffer.from(media.data, "base64");

      await supabase.storage.from("receipts").upload(fileName, mediaBuffer, {
        contentType: media.mimetype || "image/jpeg",
        upsert: true,
      });

      const { data: publicUrlData } = supabase.storage.from("receipts").getPublicUrl(fileName);
      const imageUrl = publicUrlData.publicUrl;

      // Parse amounts & dates
      const totalAmount = parseFloat(extracted.total_amount) || 0.0;
      const purchaseDate = extracted.purchase_date || new Date().toISOString().split("T")[0];
      const merchantName = extracted.merchant_name || "Store Receipt";
      const category = extracted.category || "General";

      // Insert into receipts table
      const { data: insertedReceipt, error: receiptError } = await supabase
        .from("receipts")
        .insert({
          user_id: userId,
          merchant_name: merchantName,
          date: purchaseDate,
          total: totalAmount,
          grand_total: totalAmount,
          subtotal: extracted.subtotal ? parseFloat(extracted.subtotal) : totalAmount,
          tax: extracted.tax ? parseFloat(extracted.tax) : null,
          category: category,
          currency: extracted.currency || "₹",
          image_url: imageUrl,
          original_file_name: `whatsapp_${Date.now()}.${fileExt}`,
          is_deleted: false,
        })
        .select("id")
        .single();

      if (receiptError) {
        console.error("❌ Insert Receipt Error:", receiptError);
      }

      const receiptId = insertedReceipt?.id;

      // Insert line items with required 'price' column
      let itemsListText = "";
      if (receiptId && Array.isArray(extracted.items) && extracted.items.length > 0) {
        const itemsPayload = extracted.items.map((item) => {
          const unitPrice = parseFloat(item.unit_price) || 0.0;
          const totalPrice = parseFloat(item.total_price) || unitPrice || 0.0;
          return {
            receipt_id: receiptId,
            name: item.name || "Item",
            quantity: parseInt(item.quantity) || 1,
            price: totalPrice,
            unit_price: unitPrice,
            total_price: totalPrice,
          };
        });

        const { error: itemsError } = await supabase.from("receipt_items").insert(itemsPayload);
        if (itemsError) {
          console.error("❌ Insert Receipt Items Error:", itemsError);
        } else {
          console.log(`✅ Saved ${itemsPayload.length} items to database!`);
        }

        // Build item summary for WhatsApp
        itemsListText = "\n\n📦 *Items Extracted:*\n" +
          extracted.items
            .map((item) => `• ${item.name} (${item.quantity}x) - ₹${item.total_price || item.unit_price}`)
            .join("\n");
      }

      // Insert warranty if detected
      let warrantyText = "";
      if (receiptId && extracted.warranty && extracted.warranty.has_warranty) {
        const w = extracted.warranty;
        const expiryDate = w.expiry_date || null;
        await supabase.from("warranties").insert({
          user_id: userId,
          receipt_id: receiptId,
          product_name: w.product_name || merchantName,
          brand: w.brand || null,
          merchant_name: merchantName,
          purchase_date: purchaseDate,
          warranty_period: parseInt(w.warranty_period) || 1,
          warranty_unit: w.warranty_unit || "years",
          expiry_date: expiryDate,
          status: "ACTIVE",
          image_url: imageUrl,
        });

        if (expiryDate) {
          warrantyText = `\n🛡️ *Warranty Tracked:* Expires ${expiryDate}`;
        }
      }

      // Send formatted confirmation back to user
      const replyMessage =
        `✅ *Receipt Saved to Receipto!* 🧾\n\n` +
        `🏪 *Merchant:* ${merchantName}\n` +
        `💰 *Total:* ₹${totalAmount.toLocaleString("en-IN")}\n` +
        `📅 *Date:* ${purchaseDate}\n` +
        `🏷️ *Category:* ${category}` +
        itemsListText +
        warrantyText +
        `\n\n📱 *Open Receipto app to see your updated dashboard!*`;

      await message.reply(replyMessage);
      console.log(`✅ Success reply delivered to ${formattedPhone}`);
    }
  } catch (err) {
    console.error("❌ Error processing message:", err);
    if (message.hasMedia) {
      try {
        await message.reply(
          "⚠️ Sorry, I could not process this receipt. Please ensure the image is clear and try again!"
        );
      } catch (_) {}
    }
  }
});

// Initialize client with error handling
client.initialize().catch((err) => {
  console.error("❌ WhatsApp client failed to initialize:", err);
});

// Helper: Extract structured data using Google Gemini 3 Flash with multi-key rotation & fallback
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

  const prompt = `Analyze this receipt or invoice image carefully. Extract all line items and details. Return ONLY a valid JSON object without markdown or code formatting:
{
  "merchant_name": "Store / merchant name",
  "total_amount": 0.00,
  "subtotal": 0.00,
  "tax": 0.00,
  "purchase_date": "YYYY-MM-DD",
  "category": "Electronics | Groceries | Dining | Fashion | Medical | Travel | Utilities | General",
  "currency": "₹",
  "items": [
    {
      "name": "Exact item name",
      "quantity": 1,
      "unit_price": 0.00,
      "total_price": 0.00
    }
  ],
  "warranty": {
    "has_warranty": false,
    "product_name": null,
    "brand": null,
    "warranty_period": null,
    "warranty_unit": null,
    "expiry_date": null
  }
}`;

  let lastError = null;

  // Try each configured key in round-robin sequence
  for (let attempt = 0; attempt < geminiApiKeys.length; attempt++) {
    const keyIndex = currentKeyIndex;
    const activeKey = geminiApiKeys[keyIndex];
    const keyHint = activeKey.substring(0, 8) + "..." + activeKey.slice(-4);

    try {
      console.log(`🧠 Calling Gemini 3 Flash with Key #${keyIndex + 1} (${keyHint})...`);
      const genAI = new GoogleGenerativeAI(activeKey);
      const model = genAI.getGenerativeModel({ model: "gemini-3-flash-preview" });

      const result = await model.generateContent([
        prompt,
        {
          inlineData: {
            data: base64Data,
            mimeType: mimeType,
          },
        },
      ]);

      const rawText = result.response.text();
      const cleaned = rawText.replace(/```json/g, "").replace(/```/g, "").trim();
      const parsed = JSON.parse(cleaned);

      // Rotate to next key for future requests (balanced load)
      currentKeyIndex = (currentKeyIndex + 1) % geminiApiKeys.length;
      return parsed;
    } catch (e) {
      console.warn(`⚠️ Gemini Key #${keyIndex + 1} failed: ${e.message}`);
      lastError = e;
      // Rotate immediately to next key on error
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
