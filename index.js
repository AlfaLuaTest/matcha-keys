// ╔════════════════════════════════════════════════════╗
// ║    MATCHA WEBHOOK RELAY v3.2 - Enhanced Features  ║
// ║    Dynamic Webhook + Multi-Script Support         ║
// ╚════════════════════════════════════════════════════╝

import express from "express";
import fetch from "node-fetch";

const app = express();
const PORT = process.env.PORT || 3000;
const WEBHOOK_URL = process.env.DISCORD_WEBHOOK;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const GITHUB_USER = process.env.GITHUB_USER || "AlfaLuaTest";
const GITHUB_REPO = process.env.GITHUB_REPO || "matcha-keys";
const GITHUB_BRANCH = process.env.GITHUB_BRANCH || "main";

// ═══════════════════════════════════════════════════
// WEBHOOK CONFIGURATION - PlaceId Based
// ═══════════════════════════════════════════════════

const WEBHOOK_PROFILE = {
    username: "Matcha Security",
    avatar_url: "https://i.imgur.com/RjafEmC.gif"
};

// ═══════════════════════════════════════════════════
// KEEP-ALIVE + RATE LIMITING (Önceki kodunuzdaki gibi)
// ═══════════════════════════════════════════════════

let lastActivity = Date.now();
let totalRequests = 0;
let successfulWebhooks = 0;
let failedWebhooks = 0;

setInterval(() => {
    fetch(`http://localhost:${PORT}/health`)
        .then(() => console.log("🔄 Self-ping: Stay awake"))
        .catch((err) => console.error("Self-ping failed:", err));
}, 14 * 60 * 1000);

const rateLimit = new Map();
const RATE_LIMIT_WINDOW = 60000;
const MAX_REQUESTS = 15;

function checkRateLimit(ip) {
    const now = Date.now();
    if (!rateLimit.has(ip)) {
        rateLimit.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
        return true;
    }
    
    const userData = rateLimit.get(ip);
    if (now > userData.resetTime) {
        rateLimit.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
        return true;
    }
    
    if (userData.count >= MAX_REQUESTS) {
        return false;
    }
    
    userData.count++;
    return true;
}

setInterval(() => {
    const now = Date.now();
    for (const [ip, data] of rateLimit.entries()) {
        if (now > data.resetTime) {
            rateLimit.delete(ip);
        }
    }
}, 5 * 60 * 1000);

// ═══════════════════════════════════════════════════
// GITHUB INTEGRATION
// ═══════════════════════════════════════════════════

async function updateKeyHWIDInGitHub(keyName, newHWID) {
    if (!GITHUB_TOKEN) {
        console.error("❌ GITHUB_TOKEN not configured");
        return false;
    }

    try {
        const filePath = "keys.json";
        const apiUrl = `https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/contents/${filePath}`;
        
        console.log(`📡 Fetching keys.json from GitHub...`);
        const getResponse = await fetch(apiUrl, {
            method: "GET",
            headers: {
                "Authorization": `Bearer ${GITHUB_TOKEN}`,
                "Accept": "application/vnd.github+json",
                "User-Agent": "Matcha-Webhook-Relay"
            }
        });

        if (!getResponse.ok) {
            throw new Error(`GitHub GET failed: ${getResponse.status}`);
        }

        const fileData = await getResponse.json();
        const currentContent = Buffer.from(fileData.content, 'base64').toString('utf8');
        const currentSHA = fileData.sha;
        
        const keysData = JSON.parse(currentContent);
        
        if (!keysData.keys[keyName]) {
            console.error(`❌ Key "${keyName}" not found`);
            return false;
        }

        keysData.keys[keyName].hwid = newHWID;
        keysData.last_update = new Date().toISOString();
        
        const newContent = JSON.stringify(keysData, null, 2);
        const newContentBase64 = Buffer.from(newContent).toString('base64');
        
        console.log(`📝 Updating key "${keyName}" with new HWID...`);
        const updateResponse = await fetch(apiUrl, {
            method: "PUT",
            headers: {
                "Authorization": `Bearer ${GITHUB_TOKEN}`,
                "Accept": "application/vnd.github+json",
                "Content-Type": "application/json",
                "User-Agent": "Matcha-Webhook-Relay"
            },
            body: JSON.stringify({
                message: `[AUTO] Update HWID for key ${keyName}`,
                content: newContentBase64,
                sha: currentSHA,
                branch: GITHUB_BRANCH
            })
        });

        if (!updateResponse.ok) {
            throw new Error(`GitHub PUT failed: ${updateResponse.status}`);
        }

        console.log(`✅ HWID updated for key "${keyName}"`);
        return true;

    } catch (error) {
        console.error("❌ GitHub update error:", error.message);
        return false;
    }
}

// ═══════════════════════════════════════════════════
// MIDDLEWARE
// ═══════════════════════════════════════════════════

app.use(express.json());

app.use((req, res, next) => {
    lastActivity = Date.now();
    totalRequests++;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} from ${req.ip}`);
    next();
});

// ═══════════════════════════════════════════════════
// HEALTH CHECK ROUTES
// ═══════════════════════════════════════════════════

app.get("/", (req, res) => {
    const uptime = Math.floor(process.uptime());
    const hours = Math.floor(uptime / 3600);
    const minutes = Math.floor((uptime % 3600) / 60);
    
    res.json({
        status: "✅ online",
        service: "Matcha Webhook Relay",
        version: "3.2.0",
        uptime: `${hours}h ${minutes}m`,
        stats: {
            totalRequests,
            successfulWebhooks,
            failedWebhooks,
            lastActivity: new Date(lastActivity).toISOString()
        },
        webhook: WEBHOOK_URL ? "✅ configured" : "❌ not configured",
        github: GITHUB_TOKEN ? "✅ configured" : "❌ not configured"
    });
});

app.get("/health", (req, res) => {
    res.status(200).send("healthy");
});

app.get("/ping", (req, res) => {
    res.send("pong");
});

app.get("/stats", (req, res) => {
    res.json({
        totalRequests,
        successfulWebhooks,
        failedWebhooks,
        uptime: Math.floor(process.uptime()),
        lastActivity: new Date(lastActivity).toISOString()
    });
});

// ═══════════════════════════════════════════════════
// KEY ACTIVATION WEBHOOK (Enhanced)
// ═══════════════════════════════════════════════════

app.get("/activation", async (req, res) => {
    try {
        const ip = req.ip || req.connection.remoteAddress;
        
        if (!checkRateLimit(ip)) {
            return res.status(429).json({ 
                error: "rate_limit",
                message: "Too many requests. Wait 1 minute."
            });
        }
        
        const dataB64 = req.query.data;
        if (!dataB64) {
            return res.status(400).json({ 
                error: "missing_data"
            });
        }
        
        const json = Buffer.from(dataB64, "base64").toString("utf8");
        const data = JSON.parse(json);
        
        const required = ["key", "hwid", "status"];
        for (const field of required) {
            if (!data[field]) {
                return res.status(400).json({ 
                    error: "invalid_data",
                    message: `Missing field: ${field}`
                });
            }
        }
        
        // Use single webhook profile
        const profile = WEBHOOK_PROFILE;
        
        let title, color, emoji;
        
        switch(data.status) {
            case "success":
                title = "Key Activation Success";
                color = 0x00FF00;
                emoji = "✅";
                break;
            case "returning":
                title = "Returning User";
                color = 0xFFAA00;
                emoji = "🔄";
                break;
            case "error":
                title = "Activation Failed";
                color = 0xFF0000;
                emoji = "❌";
                break;
            default:
                title = "Key Activity";
                color = 0x0099FF;
                emoji = "ℹ️";
        }
        
        const embed = {
            username: profile.username,
            avatar_url: profile.avatar_url,
            embeds: [{
                title: `${emoji} ${title}`,
                color: color,
                fields: [
                    {
                        name: "🔑 Key",
                        value: `\`\`\`${data.key}\`\`\``,
                        inline: false
                    },
                    {
                        name: "💻 HWID",
                        value: `\`\`\`${data.hwid}\`\`\``,
                        inline: false
                    },
                    {
                        name: "👤 Player",
                        value: data.player || "Unknown",
                        inline: true
                    },
                    {
                        name: "🎮 Game",
                        value: data.gameName || "Unknown Game",
                        inline: true
                    },
                    {
                        name: "📊 Tier",
                        value: data.tier || "N/A",
                        inline: true
                    },
                    {
                        name: "📅 Expires",
                        value: data.expires || "N/A",
                        inline: true
                    }
                ],
                footer: {
                    text: `Matcha v3.2 | Requests: ${totalRequests}`
                },
                timestamp: new Date().toISOString()
            }]
        };
        
        const response = await fetch(WEBHOOK_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(embed)
        });
        
        if (!response.ok) {
            throw new Error(`Discord API: ${response.status}`);
        }
        
        successfulWebhooks++;
        console.log(`✅ Webhook sent: ${data.status} | Key: ${data.key}`);
        
        res.json({ 
            success: true,
            message: "Webhook delivered"
        });
        
    } catch (error) {
        failedWebhooks++;
        console.error("❌ Activation webhook error:", error.message);
        res.status(500).json({ 
            error: "internal_error",
            message: error.message
        });
    }
});

// ═══════════════════════════════════════════════════
// UPDATE HWID
// ═══════════════════════════════════════════════════

app.get("/update-hwid", async (req, res) => {
    try {
        const ip = req.ip || req.connection.remoteAddress;
        
        if (!checkRateLimit(ip)) {
            return res.status(429).json({ 
                error: "rate_limit"
            });
        }
        
        const dataB64 = req.query.data;
        if (!dataB64) {
            return res.status(400).json({ error: "missing_data" });
        }
        
        const json = Buffer.from(dataB64, "base64").toString("utf8");
        const data = JSON.parse(json);
        
        if (!data.key || !data.hwid) {
            return res.status(400).json({ 
                error: "invalid_data"
            });
        }
        
        console.log(`🔧 HWID Update: Key=${data.key}`);
        
        const success = await updateKeyHWIDInGitHub(data.key, data.hwid);
        
        if (success) {
            res.json({ 
                success: true,
                message: "HWID updated"
            });
        } else {
            res.status(500).json({ 
                success: false,
                message: "Update failed"
            });
        }
        
    } catch (error) {
        console.error("❌ Update HWID error:", error.message);
        res.status(500).json({ 
            error: "internal_error"
        });
    }
});

// ═══════════════════════════════════════════════════
// UNAUTHORIZED ACCESS (Enhanced)
// ═══════════════════════════════════════════════════

app.get("/unauthorized", async (req, res) => {
    try {
        const ip = req.ip || req.connection.remoteAddress;
        
        if (!checkRateLimit(ip)) {
            return res.status(429).json({ error: "rate_limit" });
        }
        
        const dataB64 = req.query.data;
        if (!dataB64) {
            return res.status(400).json({ error: "missing_data" });
        }
        
        const json = Buffer.from(dataB64, "base64").toString("utf8");
        const data = JSON.parse(json);
        
        const profile = WEBHOOK_PROFILE;
        
        const embed = {
            username: profile.username,
            avatar_url: profile.avatar_url,
            content: "@everyone 🚨 **SECURITY ALERT**",
            embeds: [{
                title: "🚨 UNAUTHORIZED ACCESS ATTEMPT",
                description: "Key theft detected - Device mismatch!",
                color: 0xFF0000,
                fields: [
                    {
                        name: "🔑 Key",
                        value: `\`\`\`${data.key}\`\`\``,
                        inline: false
                    },
                    {
                        name: "❌ Attempted HWID",
                        value: `\`\`\`${data.attemptedHWID}\`\`\``,
                        inline: false
                    },
                    {
                        name: "✅ Bound HWID",
                        value: `\`\`\`${data.boundHWID}\`\`\``,
                        inline: false
                    },
                    {
                        name: "👤 Player",
                        value: data.player || "Unknown",
                        inline: true
                    },
                    {
                        name: "🎮 Game",
                        value: data.gameName || "Unknown",
                        inline: true
                    }
                ],
                footer: {
                    text: "🔒 Matcha Security System"
                },
                timestamp: new Date().toISOString()
            }]
        };
        
        await fetch(WEBHOOK_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(embed)
        });
        
        successfulWebhooks++;
        console.log(`✅ Webhook sent: ${data.status} | Key: ${data.key}`);
        
        res.json({ success: true });
        
    } catch (error) {
        failedWebhooks++;
        console.error("❌ Unauthorized webhook error:", error.message);
        res.status(500).json({ error: "internal_error" });
    }
});

// ═══════════════════════════════════════════════════
// GENERIC LOG
// ═══════════════════════════════════════════════════

app.get("/log", async (req, res) => {
    try {
        const ip = req.ip || req.connection.remoteAddress;
        
        if (!checkRateLimit(ip)) {
            return res.status(429).json({ error: "rate_limit" });
        }
        
        const dataB64 = req.query.data;
        if (!dataB64) {
            return res.status(400).json({ error: "missing_data" });
        }
        
        const json = Buffer.from(dataB64, "base64").toString("utf8");
        const data = JSON.parse(json);
        
        const profile = WEBHOOK_PROFILE;
        
        const message = {
            username: profile.username,
            avatar_url: profile.avatar_url,
            content: `📋 **Log**\n${data.message || "Generic entry"}`,
            embeds: data.embed ? [data.embed] : []
        };
        
        await fetch(WEBHOOK_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(message)
        });
        
        successfulWebhooks++;
        res.json({ success: true });
        
    } catch (error) {
        failedWebhooks++;
        console.error("❌ Log webhook error:", error.message);
        res.status(500).json({ error: "internal_error" });
    }
});

// ═══════════════════════════════════════════════════
// ERROR HANDLERS
// ═══════════════════════════════════════════════════

app.use((err, req, res, next) => {
    console.error("❌ Global error:", err);
    res.status(500).json({ 
        error: "server_error"
    });
});

app.use((req, res) => {
    res.status(404).json({
        error: "not_found",
        availableEndpoints: [
            "GET /",
            "GET /health",
            "GET /activation?data=<base64>",
            "GET /update-hwid?data=<base64>",
            "GET /unauthorized?data=<base64>"
        ]
    });
});

// ═══════════════════════════════════════════════════
// START SERVER
// ═══════════════════════════════════════════════════

app.listen(PORT, () => {
    console.log("╔════════════════════════════════════════════════════╗");
    console.log("║     MATCHA WEBHOOK RELAY v3.2 - ENHANCED          ║");
    console.log("╚════════════════════════════════════════════════════╝");
    console.log(`✅ Server: port ${PORT}`);
    console.log(`📡 Webhook: ${WEBHOOK_URL ? "✅" : "❌"}`);
    console.log(`🔧 GitHub: ${GITHUB_TOKEN ? "✅" : "❌"}`);
    console.log(`🎮 Profile: Single webhook configuration`);
    console.log(`⏰ Started: ${new Date().toISOString()}`);
    console.log("═══════════════════════════════════════════════════════");
});
