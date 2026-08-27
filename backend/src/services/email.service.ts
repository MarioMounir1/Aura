// ============================================================
//  src/services/email.service.ts
//  Aura — Email Notification Service
//  Sends OTPs and transactional emails via Nodemailer / SMTP
// ============================================================

import nodemailer from "nodemailer";

interface SendEmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

let transporter: nodemailer.Transporter | null = null;

function getTransporter(): nodemailer.Transporter | null {
  if (transporter) return transporter;

  const host = process.env.SMTP_HOST;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const port = parseInt(process.env.SMTP_PORT || "587", 10);
  const secure = process.env.SMTP_SECURE === "true" || port === 465;

  if (!host || !user || !pass) {
    return null;
  }

  transporter = nodemailer.createTransport({
    host,
    port,
    secure,
    auth: {
      user,
      pass,
    },
  });

  return transporter;
}

export async function sendEmail({ to, subject, html, text }: SendEmailOptions): Promise<boolean> {
  const mailTransporter = getTransporter();
  const fromAddress = process.env.EMAIL_FROM || '"Aura Support" <no-reply@aura-fit.com>';

  if (!mailTransporter) {
    console.log(`\n==================================================`);
    console.log(`📧 [Email Service] Simulated Email (No SMTP Configured)`);
    console.log(`To: ${to}`);
    console.log(`Subject: ${subject}`);
    if (text) console.log(`Body: ${text}`);
    console.log(`==================================================\n`);
    return true;
  }

  try {
    const info = await mailTransporter.sendMail({
      from: fromAddress,
      to,
      subject,
      text: text || "Please check your email client for the full message.",
      html,
    });
    console.log(`✅ [Email] Sent message to ${to} (ID: ${info.messageId})`);
    return true;
  } catch (err) {
    console.error(`❌ [Email] Failed to send email to ${to}:`, err);
    return false;
  }
}

/**
 * Sends a 6-digit password reset OTP email with Aura's branded template
 */
export async function sendPasswordResetEmail(toEmail: string, otp: string): Promise<boolean> {
  const subject = "Your Aura Password Reset Code";
  const text = `Your Aura password reset verification code is: ${otp}. It will expire in 15 minutes.`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your Aura Password</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #F6F8F5;
      margin: 0;
      padding: 24px;
      color: #1A2E22;
    }
    .container {
      max-width: 500px;
      margin: 0 auto;
      background-color: #FFFFFF;
      border-radius: 20px;
      padding: 36px 28px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
      border: 1px solid #E2EAE4;
    }
    .logo {
      text-align: center;
      margin-bottom: 24px;
    }
    .logo-text {
      font-size: 28px;
      font-weight: 800;
      color: #10B981;
      letter-spacing: 1px;
    }
    .title {
      font-size: 22px;
      font-weight: 700;
      color: #14241B;
      text-align: center;
      margin-bottom: 12px;
    }
    .subtitle {
      font-size: 15px;
      color: #4A6354;
      line-height: 1.5;
      text-align: center;
      margin-bottom: 28px;
    }
    .otp-card {
      background-color: #F0FDF4;
      border: 2px dashed #10B981;
      border-radius: 14px;
      padding: 20px;
      text-align: center;
      margin-bottom: 24px;
    }
    .otp-code {
      font-family: 'Courier New', Courier, monospace;
      font-size: 36px;
      font-weight: 800;
      color: #065F46;
      letter-spacing: 8px;
      margin: 0;
    }
    .expiry {
      font-size: 13px;
      color: #6B7280;
      text-align: center;
      margin-top: 10px;
    }
    .footer {
      font-size: 12px;
      color: #9CA3AF;
      text-align: center;
      line-height: 1.5;
      margin-top: 32px;
      border-top: 1px solid #F3F4F6;
      padding-top: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <span class="logo-text">AURA</span>
    </div>
    <div class="title">Reset Your Password</div>
    <div class="subtitle">
      We received a request to reset your password. Use the verification code below to set a new password in the app.
    </div>
    <div class="otp-card">
      <div class="otp-code">${otp}</div>
    </div>
    <div class="expiry">⏱️ This code will expire in <strong>15 minutes</strong>.</div>
    <div class="footer">
      If you did not request this password reset, please ignore this email. Your account remains secure.
      <br><br>
      &copy; ${new Date().getFullYear()} Aura Fitness & Nutrition. All rights reserved.
    </div>
  </div>
</body>
</html>
  `;

  return sendEmail({
    to: toEmail,
    subject,
    text,
    html,
  });
}
