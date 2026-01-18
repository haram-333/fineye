const { GoogleGenerativeAI } = require("@google/generative-ai");

/**
 * Uses Gemini Multimodal (Vision) to extract structured invoice data directly from the image.
 * This is the most accurate method as Gemini can see the layout, fonts, and positioning.
 */
async function extractWithGemini(imageBuffer, mimeType) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("❌ Gemini API Key missing (GEMINI_API_KEY)");
    return null;
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    
    // Using gemini-2.0-flash (Multimodal)
    const model = genAI.getGenerativeModel({ 
      model: "gemini-2.0-flash",
      generationConfig: {
        responseMimeType: "application/json",
      }
    });

    const prompt = `
      You are a world-class Invoice Parser. Look at this invoice image and extract the following data.
      
      JSON schema required:
      {
        "supplier_name": string | null (translate Arabic names to English smoothly),
        "trn": string | null (the 15-digit UAE TRN if applicable),
        "invoice_number": string | null (look for Bill No, Inv No, Receipt No),
        "invoice_date": string | null (YYYY-MM-DD),
        "total_amount": number | null (the final grand total paid),
        "net_amount": number | null (amount before tax),
        "tax_amount": number | null (VAT amount),
        "currency": string | null (e.g. AED, SAR, USD),
        "invoice_type": string | null
      }

      STRICT RULES:
      1. DO NOT include field labels in the values. For example, if you see "Bill No: 42800", the invoice_number is "42800", NOT "Bill No: 42800".
      2. If you see "Bill No" or "Inv No", use the number next to it as the 'invoice_number', NOT the 'supplier_name'.
      3. MATH CHECK: Ensure total_amount ≈ net_amount + tax_amount. If a total looks like a TRN or a random code (e.g. 100121.00 when net is 870), ignore it and look for a more reasonable total near the bottom.
      4. Avoid picking up phone numbers or long numeric codes as the total.
      5. Return ONLY the JSON object. No Markdown.
    `;

    console.log("🤖 Gemini Vision: Sending image to gemini-2.0-flash...");
    
    const result = await model.generateContent([
      prompt,
      {
        inlineData: {
          data: Buffer.from(imageBuffer).toString("base64"),
          mimeType: mimeType,
        },
      },
    ]);

    const text = result.response.text();
    console.log("📝 Gemini Vision Raw Response:", text);
    
    try {
      const jsonData = JSON.parse(text);
      console.log("✅ Gemini Vision: Successfully extracted data:", JSON.stringify(jsonData, null, 2));
      return jsonData;
    } catch (parseError) {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) return JSON.parse(jsonMatch[0]);
      throw parseError;
    }
  } catch (error) {
    console.error("❌ Gemini Vision Extraction Error:", error);
    return null;
  }
}

module.exports = {
  extractWithGemini,
};
