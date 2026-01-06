-- ╔════════════════════════════════════════════════════╗
-- ║      MATCHA KEY SYSTEM v2.3 - Multi-Script System  ║
-- ║      PlaceId Detection + Closeable GUI + Enhanced  ║
-- ╚════════════════════════════════════════════════════╝

-- ===========================================================
-- CONFIGURATION
-- ===========================================================
local CONFIG = {
    KEY_GITHUB_USER = "AlfaLuaTest",
    KEY_GITHUB_REPO = "matcha-keys",
    KEY_GITHUB_BRANCH = "main",
    
    RENDER_API_URL = "https://matcha-discord-relay.onrender.com",
    WEBHOOK_ENABLED = true,
    
    DEBUG_MODE = false
}

-- ===========================================================
-- GUI STATE
-- ===========================================================
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
    Loading = false,
    Authenticated = false
}

local RainbowHue = 0

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
    Warning = Color3.fromRGB(255, 200, 0),
    CloseButton = Color3.fromRGB(255, 50, 50),
    CloseHover = Color3.fromRGB(255, 100, 100)
}

local Drawings = {}

-- ===========================================================
-- UTILITY FUNCTIONS
-- ===========================================================
local function DebugPrint(...)
    if CONFIG.DEBUG_MODE then
        print("[DEBUG]", ...)
    end
end

local function UserPrint(...)
    print("[MATCHA]", ...)
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

-- ===========================================================
-- GAME DETECTION
-- ===========================================================
local function getGameInfo()
    local placeId = tostring(game.PlaceId)
    
    local gameNames = {
        ["606849621"] = "Jailbreak",
        ["2788229376"] = "Da Hood",
        ["3233893879"] = "Bad Business",
        ["292439477"] = "Phantom Forces",
        ["286090429"] = "Arsenal"
    }
    
    return placeId, gameNames[placeId] or "Unknown Game"
end

-- ===========================================================
-- DRAWING FUNCTIONS
-- ===========================================================
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

-- ===========================================================
-- CREATE GUI ELEMENTS
-- ===========================================================
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

local titleText = CreateText("[*] MATCHA KEY SYSTEM v2.3", 20)
local subtitleText = CreateText("Enter your license key to continue", 13)

-- CLOSE BUTTON (X)
local closeBtnBg = CreateSquare()
closeBtnBg.Color = Colors.CloseButton
closeBtnBg.Transparency = 0.9
closeBtnBg.Size = Vector2.new(30, 30)

local closeBtnX = CreateText("X", 18)
closeBtnX.Color = Colors.Text

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

local buttonBg = CreateSquare()
buttonBg.Color = Colors.Button

local buttonBorder = CreateSquare()
buttonBorder.Filled = false
buttonBorder.Color = Colors.Accent
buttonBorder.Thickness = 2

local buttonText = CreateText("Verify Key", 16)

local statusText = CreateText("", 12)

local gameInfoText = CreateText("", 11)
gameInfoText.Color = Colors.TextDim

local infoText1 = CreateText("[+] Key will be bound to your device", 11)
infoText1.Color = Colors.TextDim
local infoText2 = CreateText("[+] HWID copied to clipboard", 11)
infoText2.Color = Colors.TextDim

local loadingDots = CreateText("", 14)

-- ===========================================================
-- HWID GENERATION
-- ===========================================================
local function generateHWID()
    local base = tostring(getbase())
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local userId = LocalPlayer and tostring(LocalPlayer.UserId) or "unknown"
    local combined = base .. "-" .. userId
    local hwid = base64encode(combined)
    
    DebugPrint("HWID Generated:", hwid)
    return hwid, base, userId
end

local function validateHWID(storedHWID, currentHWID, currentBase, currentUserId)
    if storedHWID == currentHWID then
        return true, "exact"
    end
    
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
        return false, "decode_error"
    end
    
    local baseMatches = (storedBase == currentBase)
    local userIdMatches = (storedUserId == currentUserId)
    
    if baseMatches and userIdMatches then
        return true, "both"
    elseif baseMatches then
        return true, "base_only"
    elseif userIdMatches then
        return true, "userid_only"
    else
        return false, "no_match"
    end
end

-- ===========================================================
-- RENDER.COM WEBHOOK INTEGRATION
-- ===========================================================
local function sendToRender(endpoint, data)
    if not CONFIG.WEBHOOK_ENABLED then
        DebugPrint("Webhook disabled")
        return false
    end
    
    local HttpService = game:GetService("HttpService")
    
    local success, result = pcall(function()
        local jsonData = HttpService:JSONEncode(data)
        local base64Data = base64encode(jsonData)
        
        local url = CONFIG.RENDER_API_URL .. "/" .. endpoint .. "?data=" .. base64Data
        
        DebugPrint("Sending to Render:", url:sub(1, 100))
        
        local response = game:HttpGet(url)
        DebugPrint("Render response:", response)
        
        return response
    end)
    
    if success then
        DebugPrint("[+] Webhook sent successfully")
        return true
    else
        DebugPrint("[!] Webhook failed:", result)
        return false
    end
end

local function logActivation(key, hwid, keyInfo, status)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local placeId, gameName = getGameInfo()
    
    local data = {
        key = key,
        hwid = hwid,
        status = status,
        player = LocalPlayer.Name,
        placeId = placeId,
        gameName = gameName,
        tier = keyInfo and keyInfo.tier or "N/A",
        expires = keyInfo and keyInfo.expires or "N/A"
    }
    
    sendToRender("activation", data)
end

local function logUnauthorized(key, attemptedHWID, boundHWID)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local placeId, gameName = getGameInfo()
    
    local data = {
        key = key,
        attemptedHWID = attemptedHWID,
        boundHWID = boundHWID,
        player = LocalPlayer.Name,
        placeId = placeId,
        gameName = gameName
    }
    
    sendToRender("unauthorized", data)
end

local function updateKeyHWID(key, hwid)
    if not CONFIG.WEBHOOK_ENABLED then
        DebugPrint("Webhook disabled, cannot update HWID")
        return false
    end
    
    local data = {
        key = key,
        hwid = hwid
    }
    
    return sendToRender("update-hwid", data)
end

-- ===========================================================
-- KEY VALIDATION + SCRIPT LOADING
-- ===========================================================
local function fetchKeys()
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/keys.json",
        CONFIG.KEY_GITHUB_USER,
        CONFIG.KEY_GITHUB_REPO,
        CONFIG.KEY_GITHUB_BRANCH
    )
    
    DebugPrint("Fetching keys from:", url)
    
    local success, result = pcall(function()
        local response = game:HttpGet(url)
        local HttpService = game:GetService("HttpService")
        return HttpService:JSONDecode(response)
    end)
    
    if not success then
        DebugPrint("[!] Failed to fetch keys")
        return nil
    end
    
    return result
end

local function getScriptForPlace(keysData, userKey, currentPlaceId)
    -- Check if key is allowed for this place
    local keyInfo = keysData.keys[userKey]
    if not keyInfo or not keyInfo.allowed_scripts then
        return nil, "Key configuration error"
    end
    
    -- Check if current place is in allowed scripts
    local isAllowed = false
    for _, allowedPlace in ipairs(keyInfo.allowed_scripts) do
        if allowedPlace == currentPlaceId or allowedPlace == "default" then
            isAllowed = true
            break
        end
    end
    
    if not isAllowed then
        return nil, "Key not valid for this game"
    end
    
    -- Get script URL
    local scriptConfig = keysData.scripts[currentPlaceId]
    if not scriptConfig then
        scriptConfig = keysData.scripts["default"]
    end
    
    if not scriptConfig or not scriptConfig.enabled then
        return nil, "No script available for this game"
    end
    
    return scriptConfig.url, scriptConfig.name
end

local function validateKey(userKey)
    GUI.Loading = true
    GUI.StatusMessage = "Verifying key..."
    GUI.StatusColor = Colors.Warning
    
    DebugPrint("[*] Validating key...")
    task.wait(0.5)
    
    local hwid, baseValue, userId = generateHWID()
    local placeId, gameName = getGameInfo()
    DebugPrint("[*] PlaceId:", placeId, "Game:", gameName)
    
    local keysData = fetchKeys()
    
    if not keysData or not keysData.keys then
        GUI.StatusMessage = "[!] Server connection failed"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        logActivation(userKey, hwid, nil, "error")
        return false
    end
    
    local keyInfo = keysData.keys[userKey]
    
    if not keyInfo then
        GUI.StatusMessage = "[!] Invalid key"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Invalid key!", "Key System", 3)
        logActivation(userKey, hwid, nil, "error")
        return false
    end
    
    DebugPrint("[+] Key found - Tier:", keyInfo.tier)
    
    -- Expiration check
    local now = os.time()
    local year, month, day = keyInfo.expires:match("(%d+)-(%d+)-(%d+)")
    local expireTime = os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = 23, min = 59, sec = 59
    })
    
    if now > expireTime then
        GUI.StatusMessage = "[!] Key expired"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Key expired!", "Key System", 3)
        logActivation(userKey, hwid, keyInfo, "error")
        return false
    end
    
    -- Activation check
    local isActivated = keyInfo.activated == true or keyInfo.activated == "true"
    
    if not isActivated then
        GUI.StatusMessage = "[!] Key not activated"
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Key not activated by admin!", "Key System", 5)
        logActivation(userKey, hwid, keyInfo, "error")
        return false
    end
    
    -- Check if key is allowed for this game
    local scriptURL, scriptName = getScriptForPlace(keysData, userKey, placeId)
    
    if not scriptURL then
        GUI.StatusMessage = "[!] " .. (scriptName or "Key not valid for this game")
        GUI.StatusColor = Colors.Error
        GUI.Loading = false
        notify("Key not valid for this game!", "Key System", 5)
        logActivation(userKey, hwid, keyInfo, "error")
        return false
    end
    
    DebugPrint("[+] Script found:", scriptName)
    
    -- HWID binding
    if not keyInfo.hwid or keyInfo.hwid == "null" or keyInfo.hwid == "" then
        GUI.StatusMessage = "[+] Key activated! Binding HWID..."
        GUI.StatusColor = Colors.Success
        notify("✅ Key activated!", "Key System", 3)
        
        DebugPrint("[*] Updating HWID in keys.json...")
        updateKeyHWID(userKey, hwid)
        
        setclipboard(hwid)
        
        logActivation(userKey, hwid, keyInfo, "success")
        
        GUI.Authenticated = true
        GUI.Visible = false
    else
        local isValid, matchType = validateHWID(keyInfo.hwid, hwid, baseValue, userId)
        
        if isValid then
            GUI.StatusMessage = "[+] Welcome back!"
            GUI.StatusColor = Colors.Success
            notify("✅ Authentication successful!", "Key System", 2)
            
            if matchType == "userid_only" or matchType == "base_only" then
                DebugPrint("[*] Partial HWID match:", matchType)
            end
            
            logActivation(userKey, hwid, keyInfo, "returning")
            
            GUI.Authenticated = true
            GUI.Visible = false
        else
            GUI.StatusMessage = "[!] Key bound to different device"
            GUI.StatusColor = Colors.Error
            GUI.Loading = false
            notify("❌ Key bound to another device!", "Key System", 5)
            
            logUnauthorized(userKey, hwid, keyInfo.hwid)
            
            return false
        end
    end
    
    -- Load script
    task.wait(1)
    GUI.StatusMessage = "[...] Loading " .. scriptName .. "..."
    
    for _, draw in ipairs(Drawings) do
        draw.Visible = false
    end
    
    notify("Loading " .. scriptName .. "...", "Matcha", 2)
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(scriptURL))()
    end)
    
    if success then
        notify("✅ " .. scriptName .. " loaded!", "Matcha", 3)
        DebugPrint("[+] Script loaded successfully")
    else
        notify("❌ Failed to load script", "Matcha", 3)
        DebugPrint("[!] Script load error:", err)
    end
    
    return true
end

-- ===========================================================
-- GUI UPDATE
-- ===========================================================
local function UpdateGUI()
    if GUI.Authenticated then
        for _, draw in ipairs(Drawings) do
            pcall(function() draw.Visible = false end)
        end
        return
    end
    
    if not GUI.Visible then
        for _, draw in ipairs(Drawings) do
            draw.Visible = false
        end
        return
    end
    
    RainbowHue = (RainbowHue + 0.002) % 1
    GUI.CursorBlink = (GUI.CursorBlink + 0.05) % 2
    
    local x, y = GUI.X, GUI.Y
    local w, h = GUI.Width, GUI.Height
    
    guiBg.Position = Vector2.new(x, y)
    guiBg.Size = Vector2.new(w, h)
    guiBg.Visible = true
    
    guiBorder.Position = Vector2.new(x, y)
    guiBorder.Size = Vector2.new(w, h)
    guiBorder.Color = GetRainbowColor(0)
    guiBorder.Visible = true
    
    titleBg.Position = Vector2.new(x, y)
    titleBg.Size = Vector2.new(w, 50)
    titleBg.Visible = true
    
    titleText.Position = Vector2.new(x + w/2 - 170, y + 12)
    titleText.Color = GetRainbowColor(0)
    titleText.Visible = true
    
    -- CLOSE BUTTON (sol üst köşe)
    local closeX = x + w - 40
    local closeY = y + 10
    local isCloseHovered = IsMouseOver(closeX, closeY, 30, 30)
    
    closeBtnBg.Position = Vector2.new(closeX, closeY)
    closeBtnBg.Color = isCloseHovered and Colors.CloseHover or Colors.CloseButton
    closeBtnBg.Visible = true
    
    closeBtnX.Position = Vector2.new(closeX + 9, closeY + 5)
    closeBtnX.Visible = true
    
    subtitleText.Position = Vector2.new(x + 20, y + 60)
    subtitleText.Visible = true
    
    -- Game info
    local _, gameName = getGameInfo()
    gameInfoText.Text = "[🎮] Detected: " .. gameName
    gameInfoText.Position = Vector2.new(x + 20, y + 75)
    gameInfoText.Visible = true
    
    local inputX, inputY = x + 20, y + 100
    local inputW, inputH = w - 40, 40
    
    inputBg.Position = Vector2.new(inputX, inputY)
    inputBg.Size = Vector2.new(inputW, inputH)
    inputBg.Visible = true
    
    inputBorder.Position = Vector2.new(inputX, inputY)
    inputBorder.Size = Vector2.new(inputW, inputH)
    inputBorder.Color = GUI.InputActive and GetRainbowColor(0.5) or Colors.Border
    inputBorder.Visible = true
    
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
    
    if GUI.InputActive and GUI.CursorBlink < 1 then
        local textWidth = #GUI.InputText * 8.5
        cursorLine.Position = Vector2.new(inputX + 15 + textWidth, inputY + 11)
        cursorLine.Visible = true
    else
        cursorLine.Visible = false
    end
    
    local buttonX, buttonY = x + 20, y + 155
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
        buttonText.Position = Vector2.new(buttonX + buttonW/2 - 50, buttonY + 15)
        buttonText.Visible = true
    end
    
    statusText.Text = GUI.StatusMessage
    statusText.Color = GUI.StatusColor
    statusText.Position = Vector2.new(x + 20, y + 210)
    statusText.Visible = GUI.StatusMessage ~= ""
    
    infoText1.Position = Vector2.new(x + 20, y + 235)
    infoText1.Visible = true
    infoText2.Position = Vector2.new(x + 20, y + 250)
    infoText2.Visible = true
end

-- ===========================================================
-- INPUT HANDLING
-- ===========================================================
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
    while true do
        wait(0.01)
        
        if GUI.Authenticated then
            for _, draw in ipairs(Drawings) do
                pcall(function() draw.Visible = false end)
            end
            break
        end
        
        if not GUI.Visible then
            wait(0.1)
            continue
        end
        
        local mousePos = GetMousePos()
        local isMouseDown = ismouse1pressed()
        
        -- Close button check
        local closeX = GUI.X + GUI.Width - 40
        local closeY = GUI.Y + 10
        if IsMouseOver(closeX, closeY, 30, 30) and isMouseDown and not MousePressed then
            GUI.Visible = false
            notify("Key system closed", "Matcha", 2)
            UserPrint("[-] Key system closed by user")
        end
        
        -- Dragging
        if IsMouseOver(GUI.X, GUI.Y, GUI.Width, 50) and isMouseDown and not MousePressed then
            local closeX = GUI.X + GUI.Width - 40
            if not IsMouseOver(closeX, GUI.Y + 10, 30, 30) then
                GUI.Dragging = true
                GUI.DragOffset = Vector2.new(mousePos.X - GUI.X, mousePos.Y - GUI.Y)
            end
        end
        
        if GUI.Dragging then
            if isMouseDown then
                GUI.X = mousePos.X - GUI.DragOffset.X
                GUI.Y = mousePos.Y - GUI.DragOffset.Y
            else
                GUI.Dragging = false
            end
        end
        
        -- Input focus
        local inputX, inputY = GUI.X + 20, GUI.Y + 100
        local inputW, inputH = GUI.Width - 40, 40
        
        if IsMouseOver(inputX, inputY, inputW, inputH) and isMouseDown and not MousePressed then
            GUI.InputActive = true
        elseif not IsMouseOver(inputX, inputY, inputW, inputH) and isMouseDown and not MousePressed then
            GUI.InputActive = false
        end
        
        -- Button click
        local buttonX, buttonY = GUI.X + 20, GUI.Y + 155
        local buttonW, buttonH = GUI.Width - 40, 45
        
        if IsMouseOver(buttonX, buttonY, buttonW, buttonH) and isMouseDown and not MousePressed and not GUI.Loading then
            if #GUI.InputText >= 1 then
                spawn(function()
                    validateKey(GUI.InputText)
                end)
            else
                GUI.StatusMessage = "[!] Please enter a key"
                GUI.StatusColor = Colors.Error
            end
        end
        
        MousePressed = isMouseDown
        
        -- Keyboard input
        if GUI.InputActive then
            if iskeypressed(8) then
                if #GUI.InputText > 0 then
                    GUI.InputText = string.sub(GUI.InputText, 1, -2)
                    wait(0.05)
                end
            end
            
            for i = 65, 90 do
                if IsKeyPressed(i) then
                    if #GUI.InputText < 25 then
                        GUI.InputText = GUI.InputText .. string.char(i)
                    end
                end
            end
            
            for i = 48, 57 do
                if IsKeyPressed(i) then
                    if #GUI.InputText < 25 then
                        GUI.InputText = GUI.InputText .. string.char(i)
                    end
                end
            end
            
            if IsKeyPressed(189) then
                if #GUI.InputText < 25 then
                    GUI.InputText = GUI.InputText .. "-"
                end
            end
            
            if IsKeyPressed(13) and not GUI.Loading then
                if #GUI.InputText >= 1 then
                    spawn(function()
                        validateKey(GUI.InputText)
                    end)
                end
            end
        end
        
        UpdateGUI()
    end
end)

-- ===========================================================
-- INITIALIZATION
-- ===========================================================
local placeId, gameName = getGameInfo()
UserPrint("[+] MATCHA KEY SYSTEM v2.3 LOADED")
UserPrint("[+] Detected Game:", gameName, "(" .. placeId .. ")")

spawn(function()
    task.wait(0.5)
    local hwid = generateHWID()
    setclipboard(hwid)
    DebugPrint("[+] HWID copied to clipboard")
    notify("HWID copied | Game: " .. gameName, "Matcha", 3)
end)

notify("Key System Loaded", "Matcha v2.3", 2)
