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
        "supplier_name": string | null (translate Arabic names to English nicely),
        "trn": string | null (the 15-digit UAE TRN if applicable),
        "invoice_number": string | null (look for Bill No, Inv No, etc.),
        "invoice_date": string | null (YYYY-MM-DD),
        "total_amount": number | null (the final grand total paid),
        "net_amount": number | null (amount before tax),
        "tax_amount": number | null (VAT amount),
        "currency": string | null (e.g. AED, SAR, USD),
        "invoice_type": string | null
      }

      RULES:
      - Use your vision to identify labels correctly based on their position.
      - Extract the FINAL total amount. Ignore phone numbers or other long digits.
      - Return ONLY the JSON object.
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
