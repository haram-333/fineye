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
      You are a world-class UAE Invoice Parser. 
      Your goal is to extract structured data from raw OCR text with 100% accuracy.
      
      CRITICAL INSTRUCTIONS:
      1. INVOICE NUMBER: Look for "Bill No", "Invoice #", "Receipt No", "INV-", or "فاتورة رقم". 
         - DO NOT confuse "Bill No" with a phone number or TRN.
      2. AMOUNTS (Nonsense Check): 
         - The "total_amount" is the FINAL amount the customer paid. It is usually the largest number but NOT a TRN (15 digits usually starting with 3) or a Date.
         - Search for labels: "Grand Total", "Total (Incl. VAT)", "Amount Due", "Net Payable", or "Cash".
         - If you see multiple totals, pick the one labeled "Grand Total" or at the very bottom.
      3. DATE: Find the invoice date. Look for "Date", "تاريخ", or common UAE formats like DD/MM/YYYY or DD-MMM-YYYY.
      4. TRN (Tax Registration Number): This is a 15-digit number usually starting with '100' or '3'. It is NOT the invoice number.
      5. CURRENCY: Default to "AED" unless SAR or USD is clearly stated.
      
      JSON schema required:
      {
        "supplier_name": string | null (translate Arabic names to English nicely),
        "trn": string | null (the 15-digit UAE TRN),
        "invoice_number": string | null,
        "invoice_date": string | null (YYYY-MM-DD),
        "total_amount": number | null (e.g., 123.45, no commas),
        "net_amount": number | null,
        "tax_amount": number | null,
        "currency": string | null,
        "invoice_type": string | null
      }

      RULES:
      - Return ONLY the JSON object.
      - If a field is missing, use null.
      - Remove all commas from numeric fields.
      - Ensure amounts are parsed as numbers, not strings.

      INVOICE TEXT TO ANALYZE:
      ${fullText}
    `;

    console.log("🤖 Gemini: Sending request to gemini-2.0-flash...");
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    
    console.log("📝 Gemini Raw Response:", text); // Essential for debugging "nonsense" or "missing" fields
    
    try {
      const jsonData = JSON.parse(text);
      console.log("✅ Gemini: Successfully extracted structured data:", JSON.stringify(jsonData, null, 2));
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
