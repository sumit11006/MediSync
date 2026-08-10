require('dotenv').config();

const { default: makeWASocket, useMultiFileAuthState, DisconnectReason } = require("@whiskeysockets/baileys");
const { Boom } = require("@hapi/boom");
const express = require('express');
const cors = require('cors');
const qrcode = require("qrcode-terminal");

const app = express();
app.use(cors());
app.use(express.json());

let sock;
const otpStore = {}; // Stores OTPs in memory: { "919129785055": "123456" }

async function connectToWhatsApp() {
    // 1. Session Management
    const { state, saveCreds } = await useMultiFileAuthState('auth_info_baileys');

    sock = makeWASocket({
        auth: state,
        printQRInTerminal: false, // Set to false to handle manually via listener
        browser: ["DrugBee Server", "Chrome", "1.0.0"]
    });

    // 2. Connection Updates
    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect, qr } = update;

        // Print QR code for terminal scanning
        if (qr) {
            console.log("-----------------------------------------");
            console.log("SCAN THIS QR CODE WITH YOUR WHATSAPP:");
            qrcode.generate(qr, { small: true });
            console.log("-----------------------------------------");
        }

        if (connection === 'close') {
            const shouldReconnect = (lastDisconnect.error instanceof Boom)
                ? lastDisconnect.error.output.statusCode !== DisconnectReason.loggedOut
                : true;
            console.log('Connection closed. Reconnecting...', shouldReconnect);
            if (shouldReconnect) connectToWhatsApp();
        } else if (connection === 'open') {
            console.log('✅ DrugBee WhatsApp Server is Connected!');
        }
    });

    sock.ev.on('creds.update', saveCreds);
}

// --- API ENDPOINTS ---

// Health Check (Visit this in your browser to see if it's working)
app.get('/', (req, res) => {
    res.send("DrugBee Backend is Running! 🐝");
});

// 1. SEND OTP
app.post('/send-otp', async (req, res) => {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ error: "Phone number is required" });

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore[phone] = otp;

    try {
        const jid = `${phone}@s.whatsapp.net`;
        await sock.sendMessage(jid, { text: `Your DrugBee verification code is: ${otp}` });
        console.log(`OTP ${otp} sent to ${phone}`);
        res.status(200).json({ success: true, message: "OTP Sent successfully" });
    } catch (err) {
        console.error("Failed to send message:", err);
        res.status(500).json({ success: false, error: "Failed to send WhatsApp message" });
    }
});


app.post('/verify-otp', (req, res) => {
    const { phone, otp } = req.body;

    if (otpStore[phone] && otpStore[phone] === otp) {
        delete otpStore[phone]; // Clear OTP after use
        res.status(200).json({ success: true, message: "Verification successful" });
    } else {
        res.status(400).json({ success: false, message: "Invalid or expired OTP" });
    }
});

// --- START SERVER ---

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server listening on port ${PORT}`);
    connectToWhatsApp();
});