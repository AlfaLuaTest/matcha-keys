-- ╔═══════════════════════════════════════════════════════════╗
-- ║            MATCHA KEY SYSTEM - Professional GUI           ║
-- ║                 github.com/USERNAME/matcha-keys           ║
-- ╚═══════════════════════════════════════════════════════════╝

print("🔑 MATCHA KEY SYSTEM LOADING...")

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════
local CONFIG = {
    GITHUB_USER = "AlfaLuaTest",
    GITHUB_REPO = "matcha-keys",
    GITHUB_BRANCH = "main",
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/orbiacc/Pandi-s-Aim-Trainer/refs/heads/main/PAND%C4%B0SA%C4%B0MTRA%C4%B0NEROBF.lua"
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
    local base = tostring(getbase())
    local gameId = tostring(game.GameId)
    local placeId = tostring(game.PlaceId)
    local jobId = game.JobId or "unknown"
    
    local unique = base .. "-" .. gameId .. "-" .. placeId .. "-" .. jobId
    return base64encode(unique)
end

local function fetchKeys()
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/keys.json",
        CONFIG.GITHUB_USER,
        CONFIG.GITHUB_REPO,
        CONFIG.GITHUB_BRANCH
    )
    
    print("🌐 Fetching keys from: " .. url)
    
    local success, result = pcall(function()
        local response = game:HttpGet(url)
        print("📥 Raw Response Length: " .. #response .. " bytes")
        print("📄 First 200 chars: " .. string.sub(response, 1, 200))
        
        local HttpService = game:GetService("HttpService")
        local decoded = HttpService:JSONDecode(response)
        print("✅ JSON decoded successfully!")
        return decoded
    end)
    
    if not success then
        print("❌ ERROR in fetchKeys: " .. tostring(result))
        notify("Failed to connect to server", "Key System", 3)
        return nil
    end
    
    return result
end

local function validateKey(userKey)
    GUI.Loading = true
    GUI.StatusMessage = "Verifying key..."
    GUI.StatusColor = Colors.Warning
    
    -- DEBUG: Key kontrolü
    print("═══════════════════════════════════════")
    print("🔍 DEBUG: Key Validation Started")
    print("═══════════════════════════════════════")
    print("📝 Input Key: '" .. tostring(userKey) .. "'")
    print("📏 Key Length: " .. #userKey)
    
    task.wait(0.5)
    
    local hwid = generateHWID()
    print("🔐 Generated HWID: " .. hwid)
    
    local keysData = fetchKeys()
    
    if not keysData then
        print("❌ ERROR: Failed to fetch keys from GitHub")
        GUI.StatusMessage = "❌ Failed to connect to server"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Failed to connect to server", "Key System", 3)
        return false
    end
    
    print("✅ Keys fetched successfully!")
    
    if not keysData.keys then
        print("❌ ERROR: 'keys' field not found in JSON")
        GUI.StatusMessage = "❌ Invalid server response"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        return false
    end
    
    -- DEBUG: Tüm keyleri listele
    print("📋 Available keys in database:")
    for key, info in pairs(keysData.keys) do
        print("  • Key: '" .. key .. "' | Tier: " .. info.tier .. " | Expires: " .. info.expires)
    end
    
    local keyInfo = keysData.keys[userKey]
    
    if not keyInfo then
        print("❌ ERROR: Key '" .. userKey .. "' not found in database")
        print("💡 TIP: Check if key matches exactly (case-sensitive)")
        GUI.StatusMessage = "❌ Invalid key"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Invalid key!", "Key System", 3)
        return false
    end
    
    print("✅ Key found in database!")
    print("📊 Key Info:")
    print("  • Tier: " .. keyInfo.tier)
    print("  • Expires: " .. keyInfo.expires)
    print("  • Current HWID: " .. tostring(keyInfo.hwid))
    print("  • Activated: " .. tostring(keyInfo.activated))
    
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
        return false
    end
    
    -- Check HWID
    if keyInfo.hwid == nil then
        GUI.StatusMessage = "✅ Key activated! HWID copied to clipboard"
        GUI.StatusColor = Colors.Success
        notify("Key activated successfully!", "Key System", 3)
        notify("HWID copied to clipboard", "Admin", 3)
        setclipboard(hwid)
        
    elseif keyInfo.hwid == hwid then
        GUI.StatusMessage = "✅ Welcome back!"
        GUI.StatusColor = Colors.Success
        notify("Authentication successful!", "Key System", 2)
        
    else
        GUI.StatusMessage = "❌ Key already bound to another device"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Key already bound to another device!", "Key System", 5)
        return false
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
    while GUI.Visible do
        wait(0.01)
        
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
                print("🔘 Button clicked! Starting validation...")
                spawn(function()
                    validateKey(GUI.InputText)
                end)
            else
                print("⚠️ Key too short: '" .. GUI.InputText .. "' (length: " .. #GUI.InputText .. ")")
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
                if GUI.InputText ~= "" and #GUI.InputText >= 10 then
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
