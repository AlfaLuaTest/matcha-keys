-- ╔═══════════════════════════════════════════════════════════╗
-- ║            MATCHA KEY SYSTEM - Professional GUI           ║
-- ║                 github.com/USERNAME/matcha-keys           ║
-- ╚═══════════════════════════════════════════════════════════╝

print("🔑 MATCHA KEY SYSTEM LOADING...")

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION - BURALARAI DEĞİŞTİR!
-- ═══════════════════════════════════════════════════════════
local CONFIG = {
    -- KEY REPO (keys.json dosyasının bulunduğu repo)
    KEY_GITHUB_USER = "AlfaLuaTest",     -- ← Key repo kullanıcı adı
    KEY_GITHUB_REPO = "matcha-keys",     -- ← Key repo adı
    KEY_GITHUB_BRANCH = "main",          -- ← Key repo branch
    
    -- MAIN SCRIPT (Ana scriptin bulunduğu yer)
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/orbiacc/Pandi-s-Aim-Trainer/refs/heads/main/PAND%C4%B0SA%C4%B0MTRA%C4%B0NEROBF.lua",
    
    -- WEBHOOK (HWID gönderimi için)
    WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL_HERE", -- ← Discord webhook URL'nizi buraya
    WEBHOOK_ENABLED = true,                        -- ← false yaparak kapatabilirsiniz
    
    -- ALTERNATIVE: Pastebin ile HWID gönderimi (Webhook çalışmazsa)
    PASTEBIN_ENABLED = false,                      -- ← true yapın webhook yerine pastebin kullanmak için
    PASTEBIN_API_KEY = "YOUR_PASTEBIN_API_KEY",    -- ← Pastebin API key
    
    -- DEBUG MODE
    DEBUG_MODE = true  -- ← false yaparak debug mesajlarını kapatın
}

-- ═══════════════════════════════════════════════════════════
-- GUI STATE
-- ═══════════════════════════════════════════════════════════
local GUI = {
    Visible = true,
    Dragging = false,
    DragOffset = Vector2.new(0, 0),
    X = 100,
    Y = 100,
    Width = 400,
    Height = 280,
    InputActive = false,
    InputText = "",
    CursorBlink = 0,
    StatusMessage = "",
    StatusColor = Color3.fromRGB(255, 255, 255),
    Loading = false
}

-- Rainbow State
local RainbowHue = 0

-- Colors
local Colors = {
    Background = Color3.fromRGB(20, 20, 25),
    Border = Color3.fromRGB(255, 50, 50),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    Accent = Color3.fromRGB(255, 50, 50),
    Button = Color3.fromRGB(40, 40, 45),
    ButtonHover = Color3.fromRGB(60, 60, 65),
    Input = Color3.fromRGB(30, 30, 35),
    Success = Color3.fromRGB(0, 255, 100),
    Error = Color3.fromRGB(255, 50, 50),
    Warning = Color3.fromRGB(255, 200, 0)
}

-- Drawing Objects
local Drawings = {}

-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function DebugPrint(...)
    if CONFIG.DEBUG_MODE then
        print(...)
    end
end

local function GetRainbowColor(offset)
    offset = offset or 0
    local hue = (RainbowHue + offset) % 1
    return Color3.fromHSV(hue, 1, 1)
end

local function GetMousePos()
    local Players = game:GetService("Players")
    local mouse = Players.LocalPlayer:GetMouse()
    return Vector2.new(mouse.X, mouse.Y)
end

local function IsMouseOver(x, y, w, h)
    local mousePos = GetMousePos()
    return mousePos.X >= x and mousePos.X <= x + w and mousePos.Y >= y and mousePos.Y <= y + h
end

-- ═══════════════════════════════════════════════════════════
-- DRAWING FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function CreateSquare()
    local sq = Drawing.new("Square")
    sq.Filled = true
    sq.Thickness = 1
    sq.Transparency = 1
    table.insert(Drawings, sq)
    return sq
end

local function CreateText(text, size)
    local txt = Drawing.new("Text")
    txt.Text = text
    txt.Size = size or 14
    txt.Color = Colors.Text
    txt.Outline = true
    txt.Transparency = 1
    txt.Visible = false
    table.insert(Drawings, txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════
-- CREATE GUI ELEMENTS
-- ═══════════════════════════════════════════════════════════
-- Background
local guiBg = CreateSquare()
guiBg.Color = Colors.Background
guiBg.Transparency = 0.95

local guiBorder = CreateSquare()
guiBorder.Filled = false
guiBorder.Color = Colors.Border
guiBorder.Thickness = 2

local titleBg = CreateSquare()
titleBg.Color = Color3.fromRGB(15, 15, 20)
titleBg.Transparency = 0.98

-- Title
local titleText = CreateText("🔑 MATCHA KEY SYSTEM", 20)
local subtitleText = CreateText("Enter your license key to continue", 13)

-- Input Box
local inputBg = CreateSquare()
inputBg.Color = Colors.Input
inputBg.Transparency = 1

local inputBorder = CreateSquare()
inputBorder.Filled = false
inputBorder.Color = Colors.Border
inputBorder.Thickness = 2

local inputText = CreateText("", 14)
local placeholderText = CreateText("MATCHA-XXXX-XXXX-XXXX", 14)
placeholderText.Color = Colors.TextDim

local cursorLine = CreateSquare()
cursorLine.Color = Colors.Text
cursorLine.Size = Vector2.new(2, 18)

-- Button
local buttonBg = CreateSquare()
buttonBg.Color = Colors.Button

local buttonBorder = CreateSquare()
buttonBorder.Filled = false
buttonBorder.Color = Colors.Accent
buttonBorder.Thickness = 2

local buttonText = CreateText("Verify Key", 16)

-- Status
local statusText = CreateText("", 12)

-- Info
local infoText1 = CreateText("• Key will be bound to your device on first use", 11)
infoText1.Color = Colors.TextDim
local infoText2 = CreateText("• Your HWID will be copied to clipboard", 11)
infoText2.Color = Colors.TextDim

-- Loading Animation
local loadingDots = CreateText("", 14)

-- ═══════════════════════════════════════════════════════════
-- HWID & KEY FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function generateHWID()
    -- HYBRID METHOD: getbase() + UserId
    -- getbase() = Spoof-proof, PC-specific
    -- UserId = Account-specific, stable
    
    local base = tostring(getbase())
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local userId = LocalPlayer and tostring(LocalPlayer.UserId) or "unknown"
    
    -- Combine both for maximum security and flexibility
    local combined = base .. "-" .. userId
    
    -- Base64 encode for obfuscation
    local hwid = base64encode(combined)
    
    DebugPrint("🔐 HWID Generated (Hybrid method)")
    DebugPrint("  Method: getbase() + UserId")
    DebugPrint("  Security: Maximum spoof-proof + Account binding")
    
    return hwid, base, userId
end

local function validateHWID(storedHWID, currentHWID, currentBase, currentUserId)
    -- Try exact match first (best case)
    if storedHWID == currentHWID then
        DebugPrint("✅ Perfect match: Full HWID matches (getbase + UserId)")
        return true, "exact"
    end
    
    -- Decode stored HWID to get individual components
    local storedBase, storedUserId = nil, nil
    pcall(function()
        local decoded = base64decode(storedHWID)
        local parts = {}
        for part in string.gmatch(decoded, "[^-]+") do
            table.insert(parts, part)
        end
        
        if #parts >= 2 then
            storedBase = parts[1]
            storedUserId = parts[2]
        end
    end)
    
    if not storedBase or not storedUserId then
        DebugPrint("❌ Could not decode stored HWID")
        return false, "decode_error"
    end
    
    DebugPrint("🔍 Component check:")
    DebugPrint("  getbase match: " .. (storedBase == currentBase and "✅" or "❌"))
    DebugPrint("  UserId match: " .. (storedUserId == currentUserId and "✅" or "❌"))
    
    -- Check if EITHER getbase OR UserId matches
    local baseMatches = (storedBase == currentBase)
    local userIdMatches = (storedUserId == currentUserId)
    
    if baseMatches and userIdMatches then
        DebugPrint("✅ Both match (shouldn't happen if exact failed, but ok)")
        return true, "both"
    elseif baseMatches and not userIdMatches then
        DebugPrint("✅ getbase matches (UserId different - same PC, different account)")
        return true, "base_only"
    elseif not baseMatches and userIdMatches then
        DebugPrint("✅ UserId matches (getbase different - same account, different PC/restart)")
        return true, "userid_only"
    else
        DebugPrint("❌ Neither matches: Different PC AND different account")
        return false, "no_match"
    end
end

local function sendWebhook(hwid, userKey, keyInfo, status)
    if not CONFIG.WEBHOOK_ENABLED or CONFIG.WEBHOOK_URL == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        DebugPrint("⚠️ Webhook disabled or not configured")
        
        -- Try alternative method
        if CONFIG.PASTEBIN_ENABLED then
            sendToPastebin(hwid, userKey, keyInfo, status)
        end
        return
    end
    
    DebugPrint("📤 Sending webhook...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Safe string conversion
    local function safeStr(val)
        if val == nil then
            return "N/A"
        end
        return tostring(val)
    end
    
    -- Build webhook payload
    local tierInfo = keyInfo and safeStr(keyInfo.tier) or "N/A"
    local expiresInfo = keyInfo and safeStr(keyInfo.expires) or "N/A"
    local statusText = status == "success" and "Key Activated Successfully" or (status == "error" and "Activation Failed" or "Already Activated")
    local colorCode = status == "success" and 65280 or (status == "error" and 16711680 or 16776960)
    
    local embed = {
        ["embeds"] = {{
            ["title"] = "🔑 New Key Activation",
            ["color"] = colorCode,
            ["fields"] = {
                {
                    ["name"] = "👤 Player",
                    ["value"] = safeStr(LocalPlayer.Name) .. " (@" .. safeStr(LocalPlayer.UserId) .. ")",
                    ["inline"] = true
                },
                {
                    ["name"] = "🎮 Game",
                    ["value"] = "PlaceId: " .. safeStr(game.PlaceId),
                    ["inline"] = true
                },
                {
                    ["name"] = "🔑 Key",
                    ["value"] = "```" .. safeStr(userKey) .. "```",
                    ["inline"] = false
                },
                {
                    ["name"] = "🔐 HWID",
                    ["value"] = "```" .. safeStr(hwid) .. "```",
                    ["inline"] = false
                },
                {
                    ["name"] = "📊 Key Info",
                    ["value"] = "Tier: " .. tierInfo .. "\nExpires: " .. expiresInfo,
                    ["inline"] = false
                },
                {
                    ["name"] = "✅ Status",
                    ["value"] = statusText,
                    ["inline"] = false
                }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
    }
    
    local success, result = pcall(function()
        local HttpService = game:GetService("HttpService")
        local jsonData = HttpService:JSONEncode(embed)
        
        -- Try HttpPost (may not work in Matcha)
        local response = game:HttpPost(CONFIG.WEBHOOK_URL, jsonData)
        return response
    end)
    
    if success then
        DebugPrint("✅ Webhook sent successfully!")
        notify("HWID sent to admin", "Webhook", 2)
    else
        DebugPrint("❌ Webhook failed: " .. tostring(result))
        DebugPrint("⚠️ Note: HttpPost may not be supported in Matcha")
        notify("Webhook not supported - HWID copied to clipboard", "Info", 3)
        
        -- Try alternative method
        if CONFIG.PASTEBIN_ENABLED then
            sendToPastebin(hwid, userKey, keyInfo, status)
        end
    end
end

local function sendToPastebin(hwid, userKey, keyInfo, status)
    if not CONFIG.PASTEBIN_ENABLED or CONFIG.PASTEBIN_API_KEY == "YOUR_PASTEBIN_API_KEY" then
        DebugPrint("⚠️ Pastebin disabled or not configured")
        return
    end
    
    DebugPrint("📤 Sending to Pastebin...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local function safeStr(val)
        return val and tostring(val) or "N/A"
    end
    
    -- Build text content
    local content = string.format([[
========================================
    MATCHA KEY ACTIVATION LOG
========================================

Player: %s (@%s)
Game: PlaceId %s
Time: %s

Key: %s
Tier: %s
Expires: %s

HWID: %s

Status: %s
========================================
]], 
        safeStr(LocalPlayer.Name),
        safeStr(LocalPlayer.UserId),
        safeStr(game.PlaceId),
        os.date("%Y-%m-%d %H:%M:%S"),
        safeStr(userKey),
        keyInfo and safeStr(keyInfo.tier) or "N/A",
        keyInfo and safeStr(keyInfo.expires) or "N/A",
        safeStr(hwid),
        status == "success" and "Activated" or "Failed"
    )
    
    local success, result = pcall(function()
        local url = "https://pastebin.com/api/api_post.php"
        local postData = string.format(
            "api_dev_key=%s&api_option=paste&api_paste_code=%s&api_paste_name=MATCHA_HWID_%s&api_paste_expire_date=1M",
            CONFIG.PASTEBIN_API_KEY,
            game:GetService("HttpService"):UrlEncode(content),
            safeStr(LocalPlayer.Name)
        )
        
        local response = game:HttpPost(url, postData)
        return response
    end)
    
    if success and result then
        DebugPrint("✅ Pastebin created: " .. tostring(result))
        notify("HWID log created", "Pastebin", 2)
        setclipboard(tostring(result))
    else
        DebugPrint("❌ Pastebin failed: " .. tostring(result))
    end
end

local function fetchKeys()
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/keys.json",
        CONFIG.KEY_GITHUB_USER,
        CONFIG.KEY_GITHUB_REPO,
        CONFIG.KEY_GITHUB_BRANCH
    )
    
    DebugPrint("🌐 Fetching keys from server...")
    
    local success, result = pcall(function()
        local response = game:HttpGet(url)
        DebugPrint("📥 Response received: " .. #response .. " bytes")
        
        local HttpService = game:GetService("HttpService")
        local decoded = HttpService:JSONDecode(response)
        DebugPrint("✅ JSON decoded successfully!")
        return decoded
    end)
    
    if not success then
        DebugPrint("❌ ERROR: Failed to fetch keys from server")
        notify("Failed to connect to server", "Key System", 3)
        return nil
    end
    
    return result
end

local function validateKey(userKey)
    GUI.Loading = true
    GUI.StatusMessage = "Verifying key..."
    GUI.StatusColor = Colors.Warning
    
    DebugPrint("═══════════════════════════════════════")
    DebugPrint("🔍 Key Validation Started")
    DebugPrint("═══════════════════════════════════════")
    DebugPrint("📏 Key Length: " .. #userKey)
    
    task.wait(0.5)
    
    local hwid, baseValue, userId = generateHWID()
    DebugPrint("🔐 HWID Generated")
    DebugPrint("  Account: User #" .. userId)
    
    local keysData = fetchKeys()
    
    if not keysData then
        DebugPrint("❌ ERROR: Failed to fetch keys from GitHub")
        GUI.StatusMessage = "❌ Failed to connect to server"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Failed to connect to server", "Key System", 3)
        sendWebhook(hwid, userKey, nil, "error")
        return false
    end
    
    DebugPrint("✅ Keys fetched successfully!")
    
    if not keysData.keys then
        DebugPrint("❌ ERROR: Invalid server response format")
        GUI.StatusMessage = "❌ Invalid server response"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        return false
    end
    
    DebugPrint("📋 Total keys in database: " .. tostring(#keysData.keys))
    
    local keyInfo = keysData.keys[userKey]
    
    if not keyInfo then
        DebugPrint("❌ ERROR: Key not found in database")
        GUI.StatusMessage = "❌ Invalid key"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Invalid key!", "Key System", 3)
        sendWebhook(hwid, userKey, nil, "error")
        return false
    end
    
    DebugPrint("✅ Key found and validated!")
    DebugPrint("📊 Key Tier: " .. keyInfo.tier)
    DebugPrint("📅 Expires: " .. keyInfo.expires)
    
    -- Check expiration
    local now = os.time()
    local year, month, day = keyInfo.expires:match("(%d+)-(%d+)-(%d+)")
    local expireTime = os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = 23, min = 59, sec = 59
    })
    
    if now > expireTime then
        GUI.StatusMessage = "❌ Key expired on " .. keyInfo.expires
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Key expired!", "Key System", 3)
        DebugPrint("❌ Key expired!")
        sendWebhook(hwid, userKey, keyInfo, "error")
        return false
    end
    
    DebugPrint("✅ Key expiration check passed")
    
    -- Check if key is activated/enabled
    DebugPrint("🔍 Checking activation status...")
    DebugPrint("  activated field value: " .. tostring(keyInfo.activated))
    DebugPrint("  activated field type: " .. type(keyInfo.activated))
    
    -- More flexible activation check
    local isActivated = true  -- Default to true if field doesn't exist
    
    if keyInfo.activated ~= nil then
        -- If field exists, check its value
        if type(keyInfo.activated) == "boolean" then
            isActivated = keyInfo.activated
        elseif type(keyInfo.activated) == "string" then
            isActivated = (keyInfo.activated == "true" or keyInfo.activated == "1")
        else
            isActivated = (keyInfo.activated ~= false and keyInfo.activated ~= 0)
        end
    end
    
    DebugPrint("  Final activation status: " .. tostring(isActivated))
    
    if not isActivated then
        GUI.StatusMessage = "❌ Key is not activated yet"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Key not activated by admin!", "Key System", 5)
        DebugPrint("❌ Key is not activated (activated = false)")
        DebugPrint("💡 Contact admin to activate this key")
        sendWebhook(hwid, userKey, keyInfo, "error")
        return false
    end
    
    DebugPrint("✅ Key activation status check passed")
    
    -- Check HWID binding
    DebugPrint("🔍 Checking HWID binding...")
    
    if keyInfo.hwid == nil or keyInfo.hwid == "null" or keyInfo.hwid == "" then
        -- First time activation - bind HWID
        GUI.StatusMessage = "✅ Key activated! HWID copied to clipboard"
        GUI.StatusColor = Colors.Success
        notify("Key activated successfully!", "Key System", 3)
        notify("HWID copied to clipboard - Send to admin!", "Important", 5)
        setclipboard(hwid)
        DebugPrint("✅ First activation - HWID copied to clipboard")
        DebugPrint("⚠️ Send HWID to admin to complete binding")
        
        -- Send webhook for new activation
        sendWebhook(hwid, userKey, keyInfo, "success")
        
        -- Mark as authenticated
        GUI.Authenticated = true
        
        -- Immediately hide GUI
        GUI.Visible = false
        task.wait(0.1)
        
    else
        -- HWID exists, validate it
        local isValid, matchType = validateHWID(keyInfo.hwid, hwid, baseValue, userId)
        
        if isValid then
            if matchType == "exact" or matchType == "both" then
                -- Perfect match - same device, same account
                GUI.StatusMessage = "✅ Welcome back!"
                GUI.StatusColor = Colors.Success
                notify("Authentication successful!", "Key System", 2)
                DebugPrint("✅ Perfect match - Same device & account")
                
            elseif matchType == "userid_only" then
                -- UserId match but getbase different - same account, different PC or restart
                GUI.StatusMessage = "✅ Account verified!"
                GUI.StatusColor = Colors.Success
                notify("Account verified - Device signature updated", "Key System", 3)
                DebugPrint("✅ UserId match - Same account (PC changed or restart)")
                
                -- Copy new HWID to clipboard
                setclipboard(hwid)
                notify("New HWID copied to clipboard", "Info", 2)
                
            elseif matchType == "base_only" then
                -- getbase match but UserId different - same PC, different account
                GUI.StatusMessage = "✅ Device verified!"
                GUI.StatusColor = Colors.Success
                notify("Device verified - Account changed", "Key System", 3)
                DebugPrint("✅ getbase match - Same PC, different account")
                
                -- Copy new HWID to clipboard
                setclipboard(hwid)
                notify("New HWID copied to clipboard", "Info", 2)
            end
            
            -- Send webhook for returning user
            sendWebhook(hwid, userKey, keyInfo, "returning")
            
            -- Mark as authenticated
            GUI.Authenticated = true
            
            -- Immediately hide GUI
            GUI.Visible = false
            task.wait(0.1)
            
        else
            -- Neither getbase NOR UserId matches - completely different
            GUI.StatusMessage = "❌ Key bound to different account & device"
            GUI.StatusColor = Colors.Error
            GUI.Loading = false
            notify("Key bound to another user & device!", "Key System", 5)
            DebugPrint("❌ No match - Different account AND different device")
            DebugPrint("💡 Contact admin for key transfer")
            
            -- Send webhook for failed attempt
            sendWebhook(hwid, userKey, keyInfo, "error")
            return false
        end
    end
    
    -- Load main script
    task.wait(1)
    GUI.StatusMessage = "⏳ Loading script..."
    
    -- Cleanup GUI
    for _, draw in ipairs(Drawings) do
        draw.Visible = false
    end
    
    notify("Loading main script...", "Matcha", 2)
    local success, err = pcall(function()
        loadstring(game:HttpGet(CONFIG.MAIN_SCRIPT_URL))()
    end)
    
    if success then
        notify("Script loaded successfully!", "Matcha", 3)
        print("✅ Script loaded successfully!")
    else
        notify("Failed to load script", "Matcha", 3)
        warn("Error loading script:", err)
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- UPDATE GUI
-- ═══════════════════════════════════════════════════════════
local function UpdateGUI()
    -- If authenticated, force hide everything
    if GUI.Authenticated then
        for _, draw in ipairs(Drawings) do
            pcall(function()
                draw.Visible = false
            end)
        end
        return
    end
    
    if not GUI.Visible then
        for _, draw in ipairs(Drawings) do
            draw.Visible = false
        end
        return
    end
    
    -- Update Rainbow
    RainbowHue = (RainbowHue + 0.002) % 1
    GUI.CursorBlink = (GUI.CursorBlink + 0.05) % 2
    
    local x, y = GUI.X, GUI.Y
    local w, h = GUI.Width, GUI.Height
    
    -- Background
    guiBg.Position = Vector2.new(x, y)
    guiBg.Size = Vector2.new(w, h)
    guiBg.Visible = true
    
    guiBorder.Position = Vector2.new(x, y)
    guiBorder.Size = Vector2.new(w, h)
    guiBorder.Color = GetRainbowColor(0)
    guiBorder.Visible = true
    
    -- Title Background
    titleBg.Position = Vector2.new(x, y)
    titleBg.Size = Vector2.new(w, 50)
    titleBg.Visible = true
    
    -- Title
    titleText.Position = Vector2.new(x + w/2 - 130, y + 12)
    titleText.Color = GetRainbowColor(0)
    titleText.Visible = true
    
    subtitleText.Position = Vector2.new(x + 20, y + 60)
    subtitleText.Visible = true
    
    -- Input Box
    local inputX, inputY = x + 20, y + 90
    local inputW, inputH = w - 40, 40
    
    inputBg.Position = Vector2.new(inputX, inputY)
    inputBg.Size = Vector2.new(inputW, inputH)
    inputBg.Visible = true
    
    inputBorder.Position = Vector2.new(inputX, inputY)
    inputBorder.Size = Vector2.new(inputW, inputH)
    inputBorder.Color = GUI.InputActive and GetRainbowColor(0.5) or Colors.Border
    inputBorder.Visible = true
    
    -- Input Text
    if GUI.InputText == "" then
        placeholderText.Position = Vector2.new(inputX + 15, inputY + 12)
        placeholderText.Visible = true
        inputText.Visible = false
    else
        placeholderText.Visible = false
        inputText.Text = GUI.InputText
        inputText.Position = Vector2.new(inputX + 15, inputY + 12)
        inputText.Visible = true
    end
    
    -- Cursor
    if GUI.InputActive and GUI.CursorBlink < 1 then
        local textWidth = #GUI.InputText * 8.5
        cursorLine.Position = Vector2.new(inputX + 15 + textWidth, inputY + 11)
        cursorLine.Visible = true
    else
        cursorLine.Visible = false
    end
    
    -- Button
    local buttonX, buttonY = x + 20, y + 145
    local buttonW, buttonH = w - 40, 45
    local isHovered = IsMouseOver(buttonX, buttonY, buttonW, buttonH)
    
    buttonBg.Position = Vector2.new(buttonX, buttonY)
    buttonBg.Size = Vector2.new(buttonW, buttonH)
    buttonBg.Color = isHovered and Colors.ButtonHover or Colors.Button
    buttonBg.Visible = true
    
    buttonBorder.Position = Vector2.new(buttonX, buttonY)
    buttonBorder.Size = Vector2.new(buttonW, buttonH)
    buttonBorder.Color = isHovered and GetRainbowColor(0.5) or Colors.Accent
    buttonBorder.Visible = true
    
    if GUI.Loading then
        local dots = string.rep(".", math.floor((GUI.CursorBlink * 3) % 4))
        loadingDots.Text = "Verifying" .. dots
        loadingDots.Position = Vector2.new(buttonX + buttonW/2 - 40, buttonY + 15)
        loadingDots.Color = GetRainbowColor(0)
        loadingDots.Visible = true
        buttonText.Visible = false
    else
        loadingDots.Visible = false
        buttonText.Text = "Verify Key"
        buttonText.Position = Vector2.new(buttonX + buttonW/2 - 50, buttonY + 15)
        buttonText.Visible = true
    end
    
    -- Status
    statusText.Text = GUI.StatusMessage
    statusText.Color = GUI.StatusColor
    statusText.Position = Vector2.new(x + 20, y + 200)
    statusText.Visible = GUI.StatusMessage ~= ""
    
    -- Info
    infoText1.Position = Vector2.new(x + 20, y + 225)
    infoText1.Visible = true
    infoText2.Position = Vector2.new(x + 20, y + 240)
    infoText2.Visible = true
end

-- ═══════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ═══════════════════════════════════════════════════════════
local MousePressed = false
local KeyStates = {}

local function IsKeyPressed(keycode)
    local pressed = iskeypressed(keycode)
    if pressed and not KeyStates[keycode] then
        KeyStates[keycode] = true
        return true
    elseif not pressed then
        KeyStates[keycode] = false
    end
    return false
end

spawn(function()
    local loopActive = true
    
    while loopActive do
        wait(0.01)
        
        -- Stop loop if authenticated
        if GUI.Authenticated then
            DebugPrint("🛑 GUI loop stopping - authenticated")
            loopActive = false
            
            -- Force hide all drawings one more time
            task.wait(0.1)
            for _, draw in ipairs(Drawings) do
                pcall(function()
                    draw.Visible = false
                end)
            end
            break
        end
        
        -- Check if GUI should be hidden
        if not GUI.Visible then
            for _, draw in ipairs(Drawings) do
                pcall(function()
                    draw.Visible = false
                end)
            end
            wait(0.1)
            continue
        end
        
        local mousePos = GetMousePos()
        local isMouseDown = ismouse1pressed()
        
        -- Dragging
        if IsMouseOver(GUI.X, GUI.Y, GUI.Width, 50) and isMouseDown and not MousePressed then
            GUI.Dragging = true
            GUI.DragOffset = Vector2.new(mousePos.X - GUI.X, mousePos.Y - GUI.Y)
        end
        
        if GUI.Dragging then
            if isMouseDown then
                GUI.X = mousePos.X - GUI.DragOffset.X
                GUI.Y = mousePos.Y - GUI.DragOffset.Y
            else
                GUI.Dragging = false
            end
        end
        
        -- Input Box Click
        local inputX, inputY = GUI.X + 20, GUI.Y + 90
        local inputW, inputH = GUI.Width - 40, 40
        
        if IsMouseOver(inputX, inputY, inputW, inputH) and isMouseDown and not MousePressed then
            GUI.InputActive = true
        elseif not IsMouseOver(inputX, inputY, inputW, inputH) and isMouseDown and not MousePressed then
            GUI.InputActive = false
        end
        
        -- Button Click
        local buttonX, buttonY = GUI.X + 20, GUI.Y + 145
        local buttonW, buttonH = GUI.Width - 40, 45
        
        if IsMouseOver(buttonX, buttonY, buttonW, buttonH) and isMouseDown and not MousePressed and not GUI.Loading then
            if GUI.InputText ~= "" and #GUI.InputText >= 1 then
                DebugPrint("🔘 Button clicked! Starting validation...")
                spawn(function()
                    validateKey(GUI.InputText)
                end)
            else
                DebugPrint("⚠️ Key too short: '" .. GUI.InputText .. "' (length: " .. #GUI.InputText .. ")")
                GUI.StatusMessage = "❌ Please enter a valid key"
                GUI.StatusColor = Colors.Error
            end
        end
        
        MousePressed = isMouseDown
        
        -- Text Input (simplified - only handles alphanumeric and dash)
        if GUI.InputActive then
            -- Backspace (8)
            if IsKeyPressed(8) then
                if #GUI.InputText > 0 then
                    GUI.InputText = string.sub(GUI.InputText, 1, -2)
                end
            end
            
            -- Letters A-Z (65-90)
            for i = 65, 90 do
                if IsKeyPressed(i) then
                    if #GUI.InputText < 25 then
                        GUI.InputText = GUI.InputText .. string.char(i)
                    end
                end
            end
            
            -- Numbers 0-9 (48-57)
            for i = 48, 57 do
                if IsKeyPressed(i) then
                    if #GUI.InputText < 25 then
                        GUI.InputText = GUI.InputText .. string.char(i)
                    end
                end
            end
            
            -- Dash (189)
            if IsKeyPressed(189) then
                if #GUI.InputText < 25 then
                    GUI.InputText = GUI.InputText .. "-"
                end
            end
            
            -- Enter (13)
            if IsKeyPressed(13) and not GUI.Loading then
                if GUI.InputText ~= "" and #GUI.InputText >= 1 then
                    DebugPrint("⌨️ Enter pressed! Starting validation...")
                    spawn(function()
                        validateKey(GUI.InputText)
                    end)
                end
            end
        end
        
        UpdateGUI()
    end
end)

-- ═══════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════
print("✅ MATCHA KEY SYSTEM LOADED!")
print("📝 Enter your key in the GUI")
notify("Key System Loaded", "Matcha", 2)
notify("Enter your license key", "System", 3)
