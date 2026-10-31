import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { GoogleGenerativeAI } from "@google/generative-ai";
import nodemailer from "nodemailer";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 10000;

// Enable CORS and generous JSON body limits for base64 receipt scans
app.use(cors());
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ extended: true, limit: "50mb" }));

// ---------------------------------------------------------------------------
// 1. GEMINI KEY POOL INITIALIZATION
// ---------------------------------------------------------------------------
const rawKeys = process.env.GEMINI_API_KEYS || process.env.GEMINI_API_KEY || "";
const geminiApiKeys = rawKeys
  .split(",")
  .map((k) => k.trim())
  .filter(Boolean);

let currentKeyIndex = 0;
console.log("=========================================");
console.log("🚀 Starting Receipto Cloud API Server...");
console.log(`🔑 Loaded ${geminiApiKeys.length} Gemini API key(s) in rotation pool`);
console.log("=========================================");

// ---------------------------------------------------------------------------
// 2. HEALTH CHECK ENDPOINT
// ---------------------------------------------------------------------------
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    service: "Receipto Cloud API",
    gemini_keys_available: geminiApiKeys.length,
    timestamp: new Date().toISOString(),
  });
});

app.get("/", (req, res) => {
  res.json({
    message: "Welcome to Receipto Cloud API. Use /health for service status.",
  });
});

// ---------------------------------------------------------------------------
// 3. RECEIPT OCR EXTRACTION PROMPT & LOGIC
// ---------------------------------------------------------------------------
const RECEIPT_OCR_PROMPT = `
You are an expert AI receipt scanner.
Analyze the provided receipt image/content and extract all details in structured JSON.

VALIDITY RULES:
- Set "is_valid_receipt": true if the image is an authentic shopping receipt, store invoice, retail bill, restaurant check, or valid purchase record.
- Set "is_valid_receipt": false if the image is NOT a receipt (e.g., photo of a person/selfie, face, pet, animal, food dish without bill, nature/landscape, screenshot of a chat/social media, blank or completely unreadable image). If false, describe the reason in "invalid_reason".

CRITICAL RULES FOR CURRENCY RESOLUTION:
- Assume all receipts are Indian by default unless another country's address, currency symbol, or tax format clearly proves otherwise.
- For all Indian receipts/merchants, the currency MUST be "₹". Never return "$" for Indian receipts.
- Only return "$", "€", "£", etc. when the receipt explicitly belongs to another country.

CRITICAL RULES FOR EXPIRY DATE & WARRANTY EXTRACTION:
- Extract ANY printed expiry, expiration, best before, use by, valid till, or warranty date for each line item!
- For grocery, dairy, food, beverages, medicines, cosmetics, skincare: receipts frequently print "Expiry : DD-MM-YYYY", "Exp:", "Use By:", or "Best Before:".
- Normalize dates to standard ISO YYYY-MM-DD. Set "warranty_available": true if expiry or warranty is detected.
- For durable electronic items, mobile devices, gadgets, home appliances, power banks, chargers:
  a) If an explicit warranty duration is printed (e.g. 1 Year, 2 Years, 24 Months), set "warranty_period" (e.g. 12, 24), "warranty_unit": "months", and "warranty_available": true.
  b) Even if NO warranty duration is explicitly printed, standard manufacturer warranty applies! Assign "warranty_period": 12, "warranty_unit": "months", "warranty_available": true.
  c) Set "has_warranty": true on the receipt level!
- Distinguish Return/Replacement Windows (e.g., 7 days return, 10 days replacement) from Warranty/Expiry Periods. Never confuse them.

Return ONLY a single valid JSON object matching this structure:
{
  "is_valid_receipt": boolean,
  "invalid_reason": string or null,
  "merchant_name": string or null,
  "invoice_number": string or null,
  "date": "YYYY-MM-DD" or null,
  "time": "HH:MM" or null,
  "gst_number": string or null,
  "currency": "₹" or other symbol,
  "subtotal": float or null,
  "tax": float or null,
  "discount": float or null,
  "total": float or null,
  "payment_method": string or null,
  "category": "One of: Electronics, Groceries, Food & Dining, Fuel, Shopping, Fashion, Furniture, Home Appliances, Healthcare, Beauty & Personal Care, Travel, Entertainment, Education, Utilities, Office Supplies, Sports, Automotive, Accessories, Books, Mobile & Gadgets, Computers, Subscription, Others",
  "merchant_address": string or null,
  "merchant_phone": string or null,
  "confidence_scores": {
    "merchant_name": 0.95,
    "invoice_number": 0.90,
    "date": 0.95,
    "payment_method": 0.90
  },
  "items": [
    {
      "name": "Item name",
      "quantity": 1,
      "unit_price": 0.00,
      "total_price": 0.00,
      "brand": string or null,
      "model": string or null,
      "serial_number": string or null,
      "category": string or null,
      "warranty_available": boolean,
      "warranty_period": int or null,
      "warranty_unit": "months" or "years",
      "warranty_expiry": "YYYY-MM-DD" or null,
      "return_window": int or null
    }
  ]
}
`;

// Helper: Run Gemini multimodal OCR with fallback across API keys
async function extractReceiptWithGemini(base64Image, mimeType = "image/jpeg") {
  if (geminiApiKeys.length === 0) {
    throw new Error("No Gemini API keys configured on backend server.");
  }

  let lastError = null;
  for (let attempt = 0; attempt < geminiApiKeys.length; attempt++) {
    const keyIndex = (currentKeyIndex + attempt) % geminiApiKeys.length;
    const apiKey = geminiApiKeys[keyIndex];

    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: "gemini-3-flash-preview",
        generationConfig: {
          temperature: 0.1,
          responseMimeType: "application/json",
        },
      });

      const result = await model.generateContent([
        RECEIPT_OCR_PROMPT,
        {
          inlineData: {
            data: base64Image,
            mimeType: mimeType,
          },
        },
      ]);

      const text = result.response.text();
      const cleaned = text.replace(/```json/g, "").replace(/```/g, "").trim();
      const parsed = JSON.parse(cleaned);

      currentKeyIndex = (currentKeyIndex + 1) % geminiApiKeys.length;
      return parsed;
    } catch (err) {
      console.warn(`⚠️ Gemini Key #${keyIndex + 1} failed:`, err.message);
      lastError = err;
      currentKeyIndex = (currentKeyIndex + 1) % geminiApiKeys.length;
    }
  }

  throw lastError || new Error("All Gemini API keys failed.");
}

// ---------------------------------------------------------------------------
// 4. API ENDPOINT: POST /api/scan
// Supports either:
// a) { image_bytes: "<base64>", mime_type: "image/jpeg" } (Direct bytes from camera)
// b) { image_url: "https://..." } (Download from Supabase Storage and scan)
// ---------------------------------------------------------------------------
app.post("/api/scan", async (req, res) => {
  try {
    let { image_bytes, image_url, mime_type } = req.body;

    if (!image_bytes && !image_url) {
      return res.status(400).json({
        error: "Missing image. Provide either 'image_bytes' (base64) or 'image_url'.",
      });
    }

    mime_type = mime_type || "image/jpeg";

    // If image_url is provided, download bytes
    if (!image_bytes && image_url) {
      const fetchResponse = await fetch(image_url);
      if (!fetchResponse.ok) {
        return res.status(400).json({
          error: `Failed to download image from storage: ${fetchResponse.statusText}`,
        });
      }
      const arrayBuffer = await fetchResponse.arrayBuffer();
      image_bytes = Buffer.from(arrayBuffer).toString("base64");
    }

    const receiptData = await extractReceiptWithGemini(image_bytes, mime_type);
    return res.json({
      success: true,
      data: receiptData,
    });
  } catch (err) {
    console.error("❌ /api/scan error:", err);
    return res.status(500).json({
      success: false,
      error: err.message || "Failed to analyze receipt.",
    });
  }
});

// ---------------------------------------------------------------------------
// 5. API ENDPOINT: POST /api/send-email (Brevo SMTP Proxy)
// Keeps all SMTP credentials completely off user phones!
// ---------------------------------------------------------------------------
app.post("/api/send-email", async (req, res) => {
  try {
    const { recipient_email, subject, html_content, text_content } = req.body;

    if (!recipient_email || !subject) {
      return res.status(400).json({
        error: "Missing required fields: 'recipient_email' and 'subject'.",
      });
    }

    const host = process.env.SMTP_HOST || "smtp-relay.brevo.com";
    const port = parseInt(process.env.SMTP_PORT || "587");
    const user = process.env.SMTP_USERNAME || "b2786c001@smtp-brevo.com";
    const pass = process.env.SMTP_PASSWORD;
    const sender = process.env.SMTP_SENDER || "receiptotechexplorers@gmail.com";

    if (!pass) {
      return res.status(500).json({
        error: "SMTP_PASSWORD is not configured on the backend server.",
      });
    }

    const transporter = nodemailer.createTransport({
      host: host,
      port: port,
      secure: port === 465,
      auth: {
        user: user,
        pass: pass,
      },
    });

    const info = await transporter.sendMail({
      from: `"Receipto Alerts" <${sender}>`,
      to: recipient_email,
      subject: subject,
      text: text_content || "Receipto Notification",
      html: html_content || `<p>${text_content || subject}</p>`,
    });

    console.log(`✉️ Email successfully delivered to ${recipient_email} (MsgID: ${info.messageId})`);
    return res.json({
      success: true,
      message_id: info.messageId,
    });
  } catch (err) {
    console.error("❌ /api/send-email error:", err);
    return res.status(500).json({
      success: false,
      error: err.message || "Failed to send email via SMTP.",
    });
  }
});

// ---------------------------------------------------------------------------
// 6. API ENDPOINT: POST /api/chat (AI Assistant Proxy)
// ---------------------------------------------------------------------------
app.post("/api/chat", async (req, res) => {
  try {
    const { prompt, user_context } = req.body;

    if (!prompt) {
      return res.status(400).json({ error: "Missing 'prompt' in request body." });
    }

    if (geminiApiKeys.length === 0) {
      return res.status(500).json({ error: "No Gemini API keys configured." });
    }

    let lastError = null;
    for (let attempt = 0; attempt < geminiApiKeys.length; attempt++) {
      const keyIndex = (currentKeyIndex + attempt) % geminiApiKeys.length;
      const apiKey = geminiApiKeys[keyIndex];

      try {
        const genAI = new GoogleGenerativeAI(apiKey);
        const model = genAI.getGenerativeModel({ model: "gemini-3-flash-preview" });

        const fullPrompt = user_context
          ? `User Context: ${JSON.stringify(user_context)}\n\nUser Question: ${prompt}`
          : prompt;

        const result = await model.generateContent(fullPrompt);
        const replyText = result.response.text();

        currentKeyIndex = (currentKeyIndex + 1) % geminiApiKeys.length;
        return res.json({ success: true, reply: replyText });
      } catch (err) {
        lastError = err;
        currentKeyIndex = (currentKeyIndex + 1) % geminiApiKeys.length;
      }
    }

    throw lastError || new Error("Failed to generate chat response.");
  } catch (err) {
    console.error("❌ /api/chat error:", err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Start listening
app.listen(PORT, () => {
  console.log(`🌐 Receipto API Server is live and listening on port ${PORT}`);
});
