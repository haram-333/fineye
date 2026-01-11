const nodemailer = require('nodemailer');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Create transporter function - creates transporter when called
function createTransporter() {
  const user = (process.env.SMTP_USER || '').trim();
  const pass = (process.env.SMTP_PASSWORD || '').trim();
  
  console.log('SMTP Config Check:', {
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    user: user ? `${user.substring(0, 3)}***` : 'MISSING',
    pass: pass ? '***SET***' : 'MISSING'
  });
  
  if (!user || !pass) {
    console.error('SMTP credentials missing! Check .env file');
    return null;
  }
  
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
      user: user,
      pass: pass,
    },
  });
}

// Verify transporter configuration on startup
const transporter = createTransporter();
if (transporter) {
  transporter.verify(function (error, success) {
    if (error) {
      console.error('SMTP configuration error:', error);
    } else {
      console.log('SMTP server is ready to send emails');
    }
  });
}

/**
 * Send OTP email to user
 * @param {string} email - Recipient email address
 * @param {string} otp - 6-digit OTP code
 * @returns {Promise<boolean>} - Returns true if email sent successfully
 */
async function sendOtpEmail(email, otp) {
  try {
    const currentTransporter = createTransporter();
    if (!currentTransporter) {
      console.error('Cannot send email: Transporter not configured');
      return false;
    }
    
    const mailOptions = {
      from: `"FinEye" <${(process.env.SMTP_USER || '').trim()}>`,
      to: email,
      subject: 'Your FinEye Verification Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #002060; padding: 20px; text-align: center;">
            <h1 style="color: white; margin: 0;">FinEye</h1>
          </div>
          <div style="padding: 30px; background-color: #f9f9f9;">
            <h2 style="color: #333;">Verification Code</h2>
            <p style="color: #666; font-size: 16px;">
              Your verification code is:
            </p>
            <div style="background-color: white; border: 2px solid #002060; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
              <h1 style="color: #002060; font-size: 36px; letter-spacing: 8px; margin: 0;">${otp}</h1>
            </div>
            <p style="color: #666; font-size: 14px;">
              This code will expire in 10 minutes. If you didn't request this code, please ignore this email.
            </p>
          </div>
          <div style="background-color: #f0f0f0; padding: 15px; text-align: center; font-size: 12px; color: #999;">
            <p>© ${new Date().getFullYear()} FinEye. All rights reserved.</p>
          </div>
        </div>
      `,
      text: `Your FinEye verification code is: ${otp}. This code will expire in 10 minutes.`,
    };

    const info = await currentTransporter.sendMail(mailOptions);
    console.log('Email sent successfully:', info.messageId);
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    return false;
  }
}

module.exports = {
  sendOtpEmail,
};



