/**
 * UAE Invoice Extractor - Comprehensive Rule-Based System
 *
 * This module provides highly accurate extraction of UAE invoice data using
 * targeted regex patterns and business logic specific to UAE invoice formats.
 *
 * Supports all common UAE invoice types:
 * - Standard Tax Invoices (VAT 5%)
 * - Simplified Tax Invoices
 * - Commercial Invoices
 * - Credit/Debit Notes
 * - Receipts and Vouchers
 */

class UAEInvoiceExtractor {
  constructor() {
    // Initialize regex patterns for different field types
    this.patterns = this.initializePatterns();
  }

  /**
   * Initialize all regex patterns and extraction rules
   */
  initializePatterns() {
    return {
      // Tax Registration Number (TRN) - Always 15 digits, starts with 3 digits
      trn: [
        /(?:TRN|Tax\s+Registration\s+Number|TAX\s+REG\s+NO)[\s:]*([0-9]{3}[0-9]{12})/gi,
        /(?:رقم\s+التسجيل\s+الضريبي|TRN)[\s:]*([0-9]{3}[0-9]{12})/gi,
        /\b([0-9]{3}[0-9]{12})\b/g, // Standalone TRN in text
      ],

      // Invoice Numbers - Various formats
      invoiceNumber: [
        /(?:Invoice\s+(?:No|Number|#)|INV|Bill\s+No|Receipt\s+No)[\s:]*([A-Z0-9\-/]+(?:[0-9]{2,4})?)/gi,
        /(?:فاتورة\s+رقم|رقم\s+الفاتورة)[\s:]*([A-Z0-9\-/]+(?:[0-9]{2,4})?)/gi,
        /\b([A-Z]{2,3}-[0-9]{3,6})\b/gi, // INV-123, TAX-456
        /\b([0-9]{1,3}\/[0-9]{4})\b/g, // 123/2024 format
        /\b([0-9]{6,8})\b/g, // Pure numeric invoice numbers
      ],

      // Dates - Multiple UAE formats
      dates: [
        // DD-MMM-YY format (15-Apr-24)
        /\b([0-9]{1,2})-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[a-z]*-([0-9]{2})\b/gi,
        // DD/MM/YYYY format (15/04/2024)
        /\b([0-9]{1,2})[\/\-]([0-9]{1,2})[\/\-]([0-9]{4})\b/g,
        // DD MMM YYYY format (15 Apr 2024)
        /\b([0-9]{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[a-z]*\s+([0-9]{4})\b/gi,
        // Arabic date formats
        /\b([0-9]{1,2})\s*\/\s*([0-9]{1,2})\s*\/\s*([0-9]{4})\b/g,
      ],

      // Supplier Names - Company names and Arabic text
      supplierName: [
        /(?:Supplier|Vendor|Company|From|Sold\s+By|Merchant)[\s:]*([^\n\r]{3,50}?)(?:\n|$)/gi,
        /(?:المورد|البائع|الشركة|من)[\s:]*([^\n\r]{3,50}?)(?:\n|$)/gi,
        // Look for capitalized words that might be company names
        /\b([A-Z][A-Za-z\s&\-\.]{5,30}(?:L\.?L\.?C\.?|LTD|INC|CO\.?|CORP|GROUP|TRADING|GENERAL|ENTERPRISES|SOLUTIONS|SERVICES|TECHNOLOGY|CONSTRUCTION|CONTRACTING))\b/gi,
      ],

      // Amounts with currency
      amounts: [
        // AED/SAR amounts with commas and decimals
        /\b(AED|SAR|USD)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)\b/gi,
        /\b([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)\s*(AED|SAR|USD)\b/gi,
        // Arabic currency indicators
        /\bدرهم?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)\b/gi,
        /\b([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)\s*درهم?\b/gi,
        // Standalone amounts (assume AED if no currency specified)
        /\b([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2}))\b/g,
      ],

      // VAT/Tax amounts and rates
      vat: [
        /(?:VAT|Value\s+Added\s+Tax|Tax|ضريبة\s+القيمة\s+المضافة)[\s:]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)/gi,
        /(?:VAT\s+Rate|Tax\s+Rate|ضريبة)[\s:]*([0-9]{1,2}(?:\.[0-9]{1,2})?)%/gi,
        /\b5(?:\.0{1,2})?%\b/g, // Standard UAE VAT rate
      ],

      // Total amounts (grand total, net total)
      totals: [
        /(?:Total|Grand\s+Total|Net\s+Total|Amount\s+Due|Balance\s+Due)[\s:]*([A-Z]{3})?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)/gi,
        /(?:المجموع|المجموع\s+الكلي|المبلغ\s+المستحق)[\s:]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)/gi,
        /(?:TOTAL|GRAND\s+TOTAL)[\s:]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)/gi,
      ],

      // Invoice type detection
      invoiceType: [
        /\b(TAX\s+INVOICE|SIMPLIFIED\s+TAX\s+INVOICE|COMMERCIAL\s+INVOICE|CREDIT\s+NOTE|DEBIT\s+NOTE|RECEIPT|VOUCHER)\b/gi,
        /\b(فاتورة\s+ضريبية|فاتورة\s+مبسطة|فاتورة\s+تجارية|إشعار\s+ائتماني|إشعار\s+خصم|إيصال|قسيمة)\b/gi,
      ],

      // Customer information
      customer: [
        /(?:Customer|Client|Buyer|Billed\s+To|Bill\s+To)[\s:]*([^\n\r]{3,50}?)(?:\n|$)/gi,
        /(?:العميل|المشتري|الزبون)[\s:]*([^\n\r]{3,50}?)(?:\n|$)/gi,
      ],
    };
  }

  /**
   * Pre-process the OCR text to normalize it for better extraction
   */
  preprocessText(text) {
    if (!text) return '';

    return text
      // Normalize Arabic characters
      .replace(/أ|إ|آ/g, 'ا') // Normalize alef variations
      .replace(/ة/g, 'ه') // Normalize teh marbuta
      .replace(/ى/g, 'ي') // Normalize alef maksura
      // Remove extra whitespace
      .replace(/\s+/g, ' ')
      .replace(/\n\s*\n/g, '\n')
      // Normalize currency symbols
      .replace(/SR|ريال/g, 'SAR')
      .replace(/درهم?/g, 'AED')
      .trim();
  }

  /**
   * Extract TRN (Tax Registration Number)
   */
  extractTRN(text) {
    for (const pattern of this.patterns.trn) {
      const match = pattern.exec(text);
      if (match && match[1]) {
        const trn = match[1].replace(/\s/g, '');
        if (trn.length === 15 && /^\d{15}$/.test(trn)) {
          return trn;
        }
      }
      pattern.lastIndex = 0; // Reset regex state
    }
    return null;
  }

  /**
   * Extract invoice number
   */
  extractInvoiceNumber(text) {
    for (const pattern of this.patterns.invoiceNumber) {
      const match = pattern.exec(text);
      if (match && match[1]) {
        const invoiceNum = match[1].trim();
        if (invoiceNum.length >= 3 && invoiceNum.length <= 20) {
          return invoiceNum;
        }
      }
      pattern.lastIndex = 0;
    }
    return null;
  }

  /**
   * Extract and parse dates
   */
  extractDate(text) {
    for (const pattern of this.patterns.dates) {
      const match = pattern.exec(text);
      if (match) {
        try {
          let day, month, year;

          if (pattern.source.includes('MMM')) {
            // Handle MMM format (15-Apr-24)
            day = parseInt(match[1]);
            const monthStr = match[2].toLowerCase();
            const yearShort = match[3];

            // Convert month name to number
            const monthMap = {
              'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
              'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
            };
            month = monthMap[monthStr.substring(0, 3)];

            // Convert year
            year = parseInt(yearShort);
            year = year < 50 ? 2000 + year : 1900 + year;

          } else if (pattern.source.includes('/')) {
            // Handle DD/MM/YYYY format
            day = parseInt(match[1]);
            month = parseInt(match[2]);
            year = parseInt(match[3]);
          }

          if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2020 && year <= 2030) {
            return `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
          }
        } catch (e) {
          continue;
        }
      }
      pattern.lastIndex = 0;
    }
    return null;
  }

  /**
   * Extract supplier name
   */
  extractSupplierName(text) {
    // First try explicit supplier patterns
    for (const pattern of this.patterns.supplierName.slice(0, 2)) {
      const match = pattern.exec(text);
      if (match && match[1]) {
        const name = match[1].trim();
        if (name.length >= 3 && name.length <= 50) {
          return name;
        }
      }
      pattern.lastIndex = 0;
    }

    // Fallback: Look for capitalized company-like names
    const companyPattern = /\b([A-Z][A-Za-z\s&\-\.]{5,30}(?:L\.?L\.?C\.?|LTD|INC|CO\.?|CORP|GROUP|TRADING|GENERAL|ENTERPRISES|SOLUTIONS|SERVICES|TECHNOLOGY|CONSTRUCTION|CONTRACTING))\b/g;
    const matches = [...text.matchAll(companyPattern)];
    if (matches.length > 0) {
      // Return the first reasonable company name found
      for (const match of matches) {
        const name = match[1].trim();
        if (name.length >= 5 && name.length <= 40) {
          return name;
        }
      }
    }

    return null;
  }

  /**
   * Extract amounts with currency detection
   */
  extractAmounts(text) {
    const amounts = [];
    const processedText = text.replace(/,/g, ''); // Remove commas for easier parsing

    for (const pattern of this.patterns.amounts) {
      const matches = [...processedText.matchAll(pattern)];
      for (const match of matches) {
        let amount, currency = 'AED';

        if (match[1] && ['AED', 'SAR', 'USD'].includes(match[1].toUpperCase())) {
          // Currency first: AED 123.45
          currency = match[1].toUpperCase();
          amount = parseFloat(match[2]);
        } else if (match[2] && ['AED', 'SAR', 'USD'].includes(match[2].toUpperCase())) {
          // Amount first: 123.45 AED
          amount = parseFloat(match[1]);
          currency = match[2].toUpperCase();
        } else {
          // No currency specified, assume AED
          amount = parseFloat(match[1] || match[0]);
        }

        if (amount > 0 && amount < 10000000) { // Reasonable amount range
          amounts.push({
            amount: Math.round(amount * 100) / 100, // Round to 2 decimals
            currency: currency
          });
        }
      }
    }

    return amounts;
  }

  /**
   * Extract VAT information
   */
  extractVAT(text) {
    let vatAmount = null;
    let vatRate = null;

    // Extract VAT amount
    for (const pattern of this.patterns.vat.slice(0, 1)) {
      const match = pattern.exec(text);
      if (match && match[1]) {
        vatAmount = parseFloat(match[1].replace(/,/g, ''));
      }
      pattern.lastIndex = 0;
    }

    // Extract VAT rate
    for (const pattern of this.patterns.vat.slice(1, 3)) {
      const match = pattern.exec(text);
      if (match && match[1]) {
        vatRate = parseFloat(match[1]);
      }
      pattern.lastIndex = 0;
    }

    // If no explicit rate found, assume 5% for UAE
    if (vatRate === null && vatAmount !== null) {
      vatRate = 5.0;
    }

    return {
      amount: vatAmount,
      rate: vatRate
    };
  }

  /**
   * Extract total amounts
   */
  extractTotal(text) {
    const amounts = this.extractAmounts(text);

    // Look for explicit total patterns
    for (const pattern of this.patterns.totals) {
      const match = pattern.exec(text);
      if (match) {
        let currency = 'AED';
        let amount;

        if (match[1] && ['AED', 'SAR', 'USD'].includes(match[1])) {
          currency = match[1];
          amount = parseFloat((match[2] || match[1]).replace(/,/g, ''));
        } else {
          amount = parseFloat((match[1] || match[0]).replace(/,/g, ''));
        }

        if (amount > 0) {
          return {
            amount: Math.round(amount * 100) / 100,
            currency: currency
          };
        }
      }
      pattern.lastIndex = 0;
    }

    // Fallback: Return the largest amount found
    if (amounts.length > 0) {
      const sorted = amounts.sort((a, b) => b.amount - a.amount);
      return sorted[0];
    }

    return null;
  }

  /**
   * Determine invoice type
   */
  extractInvoiceType(text) {
    for (const pattern of this.patterns.invoiceType) {
      const match = pattern.exec(text);
      if (match && match[1]) {
        return match[1].trim();
      }
      pattern.lastIndex = 0;
    }
    return 'TAX INVOICE'; // Default for UAE
  }

  /**
   * Main extraction method
   */
  extract(text) {
    const cleanText = this.preprocessText(text);

    console.log('🔍 UAE Invoice Extractor: Processing text...');
    console.log(`📊 Text length: ${cleanText.length} characters`);

    // Extract all fields
    const trn = this.extractTRN(cleanText);
    const invoiceNumber = this.extractInvoiceNumber(cleanText);
    const date = this.extractDate(cleanText);
    const supplierName = this.extractSupplierName(cleanText);
    const amounts = this.extractAmounts(cleanText);
    const vat = this.extractVAT(cleanText);
    const total = this.extractTotal(cleanText);
    const invoiceType = this.extractInvoiceType(cleanText);

    // Calculate derived values
    let netAmount = null;
    let currency = 'AED';

    if (total && vat.amount && vat.amount > 0) {
      // Net = Total - VAT
      netAmount = Math.round((total.amount - vat.amount) * 100) / 100;
      currency = total.currency;
    } else if (amounts.length >= 2) {
      // Sort amounts and assume largest is total, second largest is net
      const sorted = amounts.sort((a, b) => b.amount - a.amount);
      if (sorted.length >= 2) {
        total = sorted[0];
        netAmount = sorted[1].amount;
        currency = sorted[0].currency;
      }
    } else if (total) {
      // If no VAT found, assume net = total (0% VAT or VAT included)
      netAmount = total.amount;
      currency = total.currency;
    }

    const result = {
      supplier_name: supplierName,
      invoice_number: invoiceNumber,
      invoice_date: date,
      total_amount: total ? total.amount : null,
      net_amount: netAmount,
      tax_amount: vat.amount,
      currency: currency,
      vat_rate: vat.rate,
      trn: trn,
      invoice_type: invoiceType,
    };

    console.log('✅ UAE Invoice Extractor: Extraction complete');
    console.log('📊 Extracted fields:', Object.keys(result).filter(k => result[k] !== null).length);

    return result;
  }
}

module.exports = {
  UAEInvoiceExtractor
};