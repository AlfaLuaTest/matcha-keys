-- ╔════════════════════════════════════════════════════╗
-- ║       MATCHA KEY SYSTEM - LOADER                   ║
-- ║         github.com/USERNAME/matcha-keys            ║
-- ╚════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════
-- CONFIGURATION - BURALAEI DEĞİŞTİR!
-- ═══════════════════════════════════════════════════
local CONFIG = {
    GITHUB_USER = "AlfaLuaTest",           -- ← GitHub kullanıcı adını buraya yaz
    GITHUB_REPO = "matcha-keys",        -- ← Repo adını buraya yaz
    GITHUB_BRANCH = "main",
    
    -- Ana scriptin URL'i (key doğrulandıktan sonra çalışacak)
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/orbiacc/Pandi-s-Aim-Trainer/refs/heads/main/PAND%C4%B0SA%C4%B0MTRA%C4%B0NEROBF.lua"  -- ← Buraya ana scriptin linkini yaz
}

-- ═══════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════
local function createInstance(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

-- ═══════════════════════════════════════════════════
-- HWID GENERATION
-- ═══════════════════════════════════════════════════
local function generateHWID()
    local base = tostring(getbase())
    local gameId = tostring(game.GameId)
    local placeId = tostring(game.PlaceId)
    local jobId = game.JobId or "unknown"
    
    local unique = base .. "-" .. gameId .. "-" .. placeId .. "-" .. jobId
    return base64encode(unique)
end

-- ═══════════════════════════════════════════════════
-- FETCH KEYS FROM GITHUB
-- ═══════════════════════════════════════════════════
local function fetchKeys()
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/keys.json",
        CONFIG.GITHUB_USER,
        CONFIG.GITHUB_REPO,
        CONFIG.GITHUB_BRANCH
    )
    
    local success, result = pcall(function()
        local response = game:HttpGet(url)
        local HttpService = game:GetService("HttpService")
        return HttpService:JSONDecode(response)
    end)
    
    return success and result or nil
end

-- ═══════════════════════════════════════════════════
-- CREATE UI
-- ═══════════════════════════════════════════════════
local function createUI()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local ScreenGui = createInstance("ScreenGui", {
        Name = "MatchaKeySystem",
        ResetOnSpawn = false,
        Parent = PlayerGui
    })
    
    local MainFrame = createInstance("Frame", {
        Size = UDim2.new(0, 400, 0, 250),
        Position = UDim2.new(0.5, -200, 0.5, -125),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BorderSizePixel = 0,
        Parent = ScreenGui
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = MainFrame
    })
    
    local Title = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "🔑 MATCHA KEY SYSTEM",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        Parent = MainFrame
    })
    
    local Subtitle = createInstance("TextLabel", {
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.new(0, 20, 0, 50),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Enter your license key",
        TextColor3 = Color3.fromRGB(180, 180, 190),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = MainFrame
    })
    
    local KeyInput = createInstance("TextBox", {
        Size = UDim2.new(1, -40, 0, 45),
        Position = UDim2.new(0, 20, 0, 90),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = "MATCHA-XXXX-XXXX-XXXX",
        PlaceholderColor3 = Color3.fromRGB(100, 100, 110),
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        ClearTextOnFocus = false,
        Parent = MainFrame
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = KeyInput
    })
    
    local SubmitButton = createInstance("TextButton", {
        Size = UDim2.new(1, -40, 0, 45),
        Position = UDim2.new(0, 20, 0, 150),
        BackgroundColor3 = Color3.fromRGB(88, 101, 242),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "Verify Key",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        Parent = MainFrame
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = SubmitButton
    })
    
    local StatusLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.new(0, 20, 0, 210),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 100, 100),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = MainFrame
    })
    
    return ScreenGui, KeyInput, SubmitButton, StatusLabel
end

-- ═══════════════════════════════════════════════════
-- VALIDATE KEY
-- ═══════════════════════════════════════════════════
local function validateAndLoad(userKey, statusLabel, screenGui, button, input)
    local hwid = generateHWID()
    local keysData = fetchKeys()
    
    if not keysData or not keysData.keys then
        statusLabel.Text = "❌ Failed to connect to server"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        button.Text = "Verify Key"
        button.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        input.TextEditable = true
        notify("Failed to connect to server", "Key System", 3)
        return
    end
    
    local keyInfo = keysData.keys[userKey]
    
    if not keyInfo then
        statusLabel.Text = "❌ Invalid key"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        button.Text = "Verify Key"
        button.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        input.TextEditable = true
        notify("Invalid key!", "Key System", 3)
        return
    end
    
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
        statusLabel.Text = "❌ Key expired"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        button.Text = "Verify Key"
        button.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        input.TextEditable = true
        notify("Key expired!", "Key System", 3)
        return
    end
    
    -- Check HWID
    if keyInfo.hwid == nil then
        statusLabel.Text = "✅ Key activated!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        notify("Key activated successfully!", "Key System", 3)
        notify("HWID copied to clipboard", "Admin", 3)
        setclipboard(hwid)
        
    elseif keyInfo.hwid == hwid then
        statusLabel.Text = "✅ Welcome back!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        notify("Authentication successful!", "Key System", 2)
        
    else
        statusLabel.Text = "❌ Key bound to another device"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        button.Text = "Verify Key"
        button.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        input.TextEditable = true
        notify("Key already bound to another device!", "Key System", 5)
        return
    end
    
    -- Load main script
    task.wait(1)
    statusLabel.Text = "⏳ Loading script..."
    task.wait(0.5)
    
    screenGui.Parent = nil
    
    notify("Loading main script...", "Matcha", 2)
    local success, err = pcall(function()
        loadstring(game:HttpGet(CONFIG.MAIN_SCRIPT_URL))()
    end)
    
    if success then
        notify("Script loaded successfully!", "Matcha", 3)
    else
        notify("Failed to load script", "Matcha", 3)
        warn("Error loading script:", err)
    end
end

-- ═══════════════════════════════════════════════════
-- MAIN
-- ═══════════════════════════════════════════════════
local function main()
    notify("Initializing Key System...", "Matcha", 2)
    
    local screenGui, keyInput, submitButton, statusLabel = createUI()
    
    submitButton.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        
        if key == "" or #key < 10 then
            statusLabel.Text = "❌ Please enter a valid key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        submitButton.Text = "Verifying..."
        submitButton.BackgroundColor3 = Color3.fromRGB(68, 81, 222)
        keyInput.TextEditable = false
        statusLabel.Text = "⏳ Checking key..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        task.spawn(function()
            validateAndLoad(key, statusLabel, screenGui, submitButton, keyInput)
        end)
    end)
end

main()
