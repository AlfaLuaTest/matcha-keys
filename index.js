// ╔════════════════════════════════════════════════════╗
// ║    MATCHA WEBHOOK RELAY v3.1 - GitHub Integration  ║
// ║    Sleep Mode Prevention + Auto HWID Update        ║
// ╚════════════════════════════════════════════════════╝

import express from "express";
import fetch from "node-fetch";

const app = express();
const PORT = process.env.PORT || 3000;
const WEBHOOK_URL = process.env.DISCORD_WEBHOOK;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN; // Personal Access Token
const GITHUB_USER = process.env.GITHUB_USER || "AlfaLuaTest";
const GITHUB_REPO = process.env.GITHUB_REPO || "matcha-keys";
const GITHUB_BRANCH = process.env.GITHUB_BRANCH || "main";

// ═══════════════════════════════════════════════════
// KEEP-ALIVE SYSTEM (Anti-Sleep)
// ═══════════════════════════════════════════════════

let lastActivity = Date.now();
let totalRequests = 0;
let successfulWebhooks = 0;
let failedWebhooks = 0;

// Her 14 dakikada bir kendi kendine ping at
setInterval(() => {
    fetch(`http://localhost:${PORT}/health`)
        .then(() => console.log("🔄 Self-ping: Stay awake"))
        .catch((err) => console.error("Self-ping failed:", err));
}, 14 * 60 * 1000); // 14 dakika

// ═══════════════════════════════════════════════════
// RATE LIMITING
// ═══════════════════════════════════════════════════

const rateLimit = new Map();
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const MAX_REQUESTS = 15; // Max 15 req/min per IP

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

// Cleanup old rate limit entries every 5 minutes
setInterval(() => {
    const now = Date.now();
    for (const [ip, data] of rateLimit.entries()) {
        if (now > data.resetTime) {
            rateLimit.delete(ip);
        }
    }
}, 5 * 60 * 1000);

// ═══════════════════════════════════════════════════
// GITHUB INTEGRATION - UPDATE HWID IN KEYS.JSON
// ═══════════════════════════════════════════════════

async function updateKeyHWIDInGitHub(keyName, newHWID) {
    if (!GITHUB_TOKEN) {
        console.error("❌ GITHUB_TOKEN not configured");
        return false;
    }

    try {
        const filePath = "keys.json";
        const apiUrl = `https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/contents/${filePath}`;
        
        // 1. Get current file content and SHA
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
            throw new Error(`GitHub GET failed: ${getResponse.status} ${getResponse.statusText}`);
        }

        const fileData = await getResponse.json();
        const currentContent = Buffer.from(fileData.content, 'base64').toString('utf8');
        const currentSHA = fileData.sha;
        
        // 2. Parse and update JSON
        const keysData = JSON.parse(currentContent);
        
        if (!keysData.keys[keyName]) {
            console.error(`❌ Key "${keyName}" not found in keys.json`);
            return false;
        }

        keysData.keys[keyName].hwid = newHWID;
        keysData.last_update = new Date().toISOString();
        
        const newContent = JSON.stringify(keysData, null, 2);
        const newContentBase64 = Buffer.from(newContent).toString('base64');
        
        // 3. Commit updated file
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
            const errorText = await updateResponse.text();
            throw new Error(`GitHub PUT failed: ${updateResponse.status} - ${errorText}`);
        }

        console.log(`✅ Successfully updated HWID for key "${keyName}" in GitHub`);
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
// ROUTES
// ═══════════════════════════════════════════════════

// Health check (for monitoring services)
app.get("/", (req, res) => {
    const uptime = Math.floor(process.uptime());
    const hours = Math.floor(uptime / 3600);
    const minutes = Math.floor((uptime % 3600) / 60);
    
    res.json({
        status: "✅ online",
        service: "Matcha Webhook Relay",
        version: "3.1.0",
        uptime: `${hours}h ${minutes}m`,
        stats: {
            totalRequests,
            successfulWebhooks,
            failedWebhooks,
            lastActivity: new Date(lastActivity).toISOString()
        },
        webhook: WEBHOOK_URL ? "✅ configured" : "❌ not configured",
        github: GITHUB_TOKEN ? "✅ configured" : "❌ not configured",
        rateLimitEntries: rateLimit.size
    });
});

app.get("/health", (req, res) => {
    res.status(200).send("healthy");
});

app.get("/ping", (req, res) => {
    res.send("pong");
});

// Stats endpoint
app.get("/stats", (req, res) => {
    res.json({
        totalRequests,
        successfulWebhooks,
        failedWebhooks,
        uptime: Math.floor(process.uptime()),
        lastActivity: new Date(lastActivity).toISOString(),
        rateLimitActive: rateLimit.size
    });
});

// ═══════════════════════════════════════════════════
// KEY ACTIVATION WEBHOOK
// ═══════════════════════════════════════════════════

app.get("/activation", async (req, res) => {
    try {
        const ip = req.ip || req.connection.remoteAddress;
        
        if (!checkRateLimit(ip)) {
            return res.status(429).json({ 
                error: "rate_limit",
                message: "Too many requests. Wait 1 minute.",
                retryAfter: 60
            });
        }
        
        const dataB64 = req.query.data;
        if (!dataB64) {
            return res.status(400).json({ 
                error: "missing_data",
                message: "No data parameter"
            });
        }
        
        // Decode data
        const json = Buffer.from(dataB64, "base64").toString("utf8");
        const data = JSON.parse(json);
        
        // Validate required fields
        const required = ["key", "hwid", "status"];
        for (const field of required) {
            if (!data[field]) {
                return res.status(400).json({ 
                    error: "invalid_data",
                    message: `Missing field: ${field}`
                });
            }
        }
        
        // Build Discord embed based on status
        let title, color, emoji;
        
        switch(data.status) {
            case "success":
                title = "Key Activation Success";
                color = 0x00FF00; // Green
                emoji = "✅";
                break;
            case "returning":
                title = "Returning User";
                color = 0xFFAA00; // Orange
                emoji = "🔄";
                break;
            case "error":
                title = "Activation Failed";
                color = 0xFF0000; // Red
                emoji = "❌";
                break;
            default:
                title = "Key Activity";
                color = 0x0099FF; // Blue
                emoji = "ℹ️";
        }
        
        const embed = {
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
                        value: `PlaceId: ${data.placeId || "Unknown"}`,
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
                    text: `Matcha Key System v3.1 | Total Requests: ${totalRequests}`
                },
                timestamp: new Date().toISOString()
            }]
        };
        
        // Send to Discord
        const response = await fetch(WEBHOOK_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(embed)
        });
        
        if (!response.ok) {
            throw new Error(`Discord API: ${response.status} ${response.statusText}`);
        }
        
        successfulWebhooks++;
        console.log(`✅ Webhook sent: ${data.status} | Key: ${data.key.substring(0, 10)}...`);
        
        res.json({ 
            success: true,
            message: "Webhook delivered",
            webhookId: successfulWebhooks
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
// UPDATE HWID IN GITHUB (New Endpoint)
// ═══════════════════════════════════════════════════

app.get("/update-hwid", async (req, res) => {
    try {
        const ip = req.ip || req.connection.remoteAddress;
        
        if (!checkRateLimit(ip)) {
            return res.status(429).json({ 
                error: "rate_limit",
                retryAfter: 60
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
                error: "invalid_data",
                message: "Missing key or hwid"
            });
        }
        
        console.log(`🔧 HWID Update request: Key=${data.key}, HWID=${data.hwid.substring(0, 20)}...`);
        
        // Update GitHub
        const success = await updateKeyHWIDInGitHub(data.key, data.hwid);
        
        if (success) {
            res.json({ 
                success: true,
                message: "HWID updated in GitHub"
            });
        } else {
            res.status(500).json({ 
                success: false,
                message: "Failed to update GitHub"
            });
        }
        
    } catch (error) {
        console.error("❌ Update HWID error:", error.message);
        res.status(500).json({ 
            error: "internal_error",
            message: error.message
        });
    }
});

// ═══════════════════════════════════════════════════
// UNAUTHORIZED ACCESS ALERT
// ═══════════════════════════════════════════════════

app.get("/unauthorized", async (req, res) => {
    try {
        const ip = req.ip || req.connection.remoteAddress;
        
        if (!checkRateLimit(ip)) {
            return res.status(429).json({ 
                error: "rate_limit",
                retryAfter: 60
            });
        }
        
        const dataB64 = req.query.data;
        if (!dataB64) {
            return res.status(400).json({ error: "missing_data" });
        }
        
        const json = Buffer.from(dataB64, "base64").toString("utf8");
        const data = JSON.parse(json);
        
        const embed = {
            content: "@everyone 🚨 **SECURITY ALERT**",
            embeds: [{
                title: "🚨 UNAUTHORIZED ACCESS ATTEMPT",
                description: "Someone tried to use a key bound to another device!",
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
                        value: `PlaceId: ${data.placeId || "Unknown"}`,
                        inline: true
                    }
                ],
                footer: {
                    text: "🔒 Key Theft Detection System"
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
        console.log(`🚨 Unauthorized attempt logged: ${data.key.substring(0, 10)}...`);
        
        res.json({ success: true });
        
    } catch (error) {
        failedWebhooks++;
        console.error("❌ Unauthorized webhook error:", error.message);
        res.status(500).json({ error: "internal_error" });
    }
});

// ═══════════════════════════════════════════════════
// GENERIC LOG ENDPOINT
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
        
        const message = {
            content: `📋 **Matcha Log**\n${data.message || "Generic log entry"}`,
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
// ADMIN COMMANDS (Optional)
// ═══════════════════════════════════════════════════

app.get("/admin/reset-stats", (req, res) => {
    const token = req.query.token;
    const adminToken = process.env.ADMIN_TOKEN || "changeme";
    
    if (token !== adminToken) {
        return res.status(403).json({ error: "unauthorized" });
    }
    
    totalRequests = 0;
    successfulWebhooks = 0;
    failedWebhooks = 0;
    rateLimit.clear();
    
    res.json({ success: true, message: "Stats reset" });
});

// ═══════════════════════════════════════════════════
// ERROR HANDLER
// ═══════════════════════════════════════════════════

app.use((err, req, res, next) => {
    console.error("❌ Global error:", err);
    res.status(500).json({ 
        error: "server_error",
        message: "Internal server error"
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: "not_found",
        message: "Endpoint not found",
        availableEndpoints: [
            "GET /",
            "GET /health",
            "GET /ping",
            "GET /stats",
            "GET /activation?data=<base64>",
            "GET /update-hwid?data=<base64>",
            "GET /unauthorized?data=<base64>",
            "GET /log?data=<base64>"
        ]
    });
});

// ═══════════════════════════════════════════════════
// START SERVER
// ═══════════════════════════════════════════════════

app.listen(PORT, () => {
    console.log("╔════════════════════════════════════════════════════╗");
    console.log("║     MATCHA WEBHOOK RELAY v3.1 - READY             ║");
    console.log("╚════════════════════════════════════════════════════╝");
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`📡 Discord webhook: ${WEBHOOK_URL ? "✅ Configured" : "❌ NOT CONFIGURED"}`);
    console.log(`🔧 GitHub integration: ${GITHUB_TOKEN ? "✅ Configured" : "❌ NOT CONFIGURED"}`);
    console.log(`🛡️  Rate limiting: ${MAX_REQUESTS} requests per ${RATE_LIMIT_WINDOW/1000}s`);
    console.log(`🔄 Self-ping active: Every 14 minutes`);
    console.log(`⏰ Started at: ${new Date().toISOString()}`);
    console.log("═══════════════════════════════════════════════════════");
});
