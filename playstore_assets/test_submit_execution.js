// Test script to mock DOM and execute handleFormSubmit
const fs = require('fs');
const html = fs.readFileSync('docs/feedback.html', 'utf-8');

// Extract script content
const scriptMatch = html.match(/<script>([\s\S]*?)<\/script>/);
if (!scriptMatch) {
  console.error("No script tag found!");
  process.exit(1);
}

// Minimal DOM mock
const domElements = {
  neuralCanvas: { getContext: () => ({ clearRect: ()=>{}, fillStyle:'', strokeStyle:'', beginPath: ()=>{}, arc: ()=>{}, fill: ()=>{}, moveTo: ()=>{}, lineTo: ()=>{}, stroke: ()=>{} }) },
  submitBtn: { disabled: false, innerHTML: '' },
  hasBugInput: { value: 'No' },
  favFeature: { value: 'PaddleOCR scanner' },
  improvements: { value: 'None, works great' },
  testerName: { value: 'Milanraj' },
  testerEmail: { value: 'milanraj616@gmail.com' },
  deviceModel: { value: 'OnePlus 11R' },
  androidVersion: { value: 'Android 14' },
  testingDuration: { value: '1–3 days' },
  overallRating: { value: '5' },
  easeOfUseInput: { value: 'Very Easy' },
  appVersion: { value: '1.0.0 (Build 1)' },
  manualCorrectionInput: { value: 'Rarely' },
  crashFrequency: { value: 'Never' },
  delayFrequency: { value: 'Never' },
  impressedFeature: { value: 'Speed' },
  futureWishes: { value: 'Cloud backup' },
  finalSatRating: { value: '5' },
  continueUsing: { value: 'Definitely Yes' },
  devMessage: { value: 'Keep it up' },
  betaFeedbackForm: { style: {} },
  stepperNav: { style: {} },
  successCard: { classList: { add: () => {} }, scrollIntoView: () => {} },
  communityFeedList: { innerHTML: '', appendChild: () => {} },
  wallAvgRating: { innerText: '' },
  wallCount: { innerText: '' },
  overallBetaAvgScore: { innerText: '' },
  overallBetaStarsDisplay: { innerText: '' },
  overallBetaTestersCount: { innerText: '' },
  avg_nlp_ocr: { innerText: '' },
  avg_receipts: { innerText: '' },
  avg_warranty: { innerText: '' },
  avg_reminders: { innerText: '' },
  avg_ai_assistant: { innerText: '' },
  avg_analytics: { innerText: '' },
  avg_pdf: { innerText: '' },
  avg_whatsapp: { innerText: '' },
  step5Card: { querySelectorAll: () => [] },
  overallStarsGroup: { querySelectorAll: () => [] },
  finalSatStarsGroup: { querySelectorAll: () => [] }
};

global.document = {
  body: { classList: { add: ()=>{}, remove: ()=>{} } },
  getElementById: (id) => domElements[id] || { value: '', innerText: '', style: {}, classList: { add: () => {}, remove: () => {} } },
  querySelectorAll: () => [],
  querySelector: () => null,
  createElement: () => ({ className: '', innerHTML: '', appendChild: () => {} })
};

global.window = {
  innerWidth: 1024,
  innerHeight: 768,
  addEventListener: () => {}
};

global.requestAnimationFrame = () => {};

global.localStorage = {
  getItem: () => null,
  setItem: () => {}
};

global.showToast = (t, m) => console.log(`[Toast] ${t}: ${m}`);
global.clearFieldErrors = () => {};

// Evaluate extracted script in node context
eval(scriptMatch[1]);

console.log("Script evaluated successfully!");

// Execute handleFormSubmit()
handleFormSubmit({ preventDefault: () => {}, stopPropagation: () => {} })
  .then(() => {
    console.log("SUCCESS! handleFormSubmit executed cleanly with ZERO errors!");
    process.exit(0);
  })
  .catch((err) => {
    console.error("FAILED with error:", err);
    process.exit(1);
  });
