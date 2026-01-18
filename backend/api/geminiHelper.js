const { GoogleGenerativeAI } = require("@google/generative-ai");

/**
 * Uses Gemini to extract structured invoice data from raw OCR text.
 * This handles variability in invoice layouts much better than regex.
 */
async function extractWithGemini(fullText) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("❌ Gemini API Key missing (GEMINI_API_KEY)");
    return null;
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    
    // Using gemini-2.0-flash as it's the stable/required version in 2026
    const model = genAI.getGenerativeModel({ 
      model: "gemini-2.0-flash",
      generationConfig: {
        responseMimeType: "application/json",
      }
    });

    const prompt = `
      You are an expert UAE Invoice Parser. 
      Analyze the following raw OCR text from an invoice and extract the key information.
      
      JSON schema required:
      {
        "supplier_name": string | null,
        "trn": string | null (15-digit UAE TRN),
        "invoice_number": string | null,
        "invoice_date": string | null (YYYY-MM-DD),
        "total_amount": number | null,
        "net_amount": number | null,
        "tax_amount": number | null,
        "currency": string | null (usually AED),
        "invoice_type": string | null
      }

      RULES:
      1. Return JSON ONLY.
      2. If values are missing, use null.
      3. Remove commas from amounts.
      4. If Arabic text is present, translate the supplier name nicely.

      INVOICE TEXT:
      ${fullText}
    `;

    console.log("🤖 Gemini: Sending request to gemini-2.0-flash...");
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    
    try {
      const jsonData = JSON.parse(text);
      console.log("✅ Gemini: Successfully extracted structured data using 2.0 Flash");
      return jsonData;
    } catch (parseError) {
      // Fallback for older library versions or unexpected formatting
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      throw parseError;
    }
  } catch (error) {
    console.error("❌ Gemini Extraction Error:", error);
    return null;
  }
}

module.exports = {
  extractWithGemini,
};
