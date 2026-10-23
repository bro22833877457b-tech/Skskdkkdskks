-- Подпишитесь на канал Tg: @promt114
-- Чтобы развить наш канал.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
local S = {
    ESP = {
        Enabled = false,
        ShowName = true,
        ShowDist = true,
        ShowBox = true,
        ShowHealth = true,
        MurdererColor = Color3.fromRGB(255, 50, 50),
        SheriffColor = Color3.fromRGB(50, 150, 255),
        InnocentColor = Color3.fromRGB(50, 255, 100),
    },
    Aim = {
        Enabled = false,
        Active = false,
        Smoothness = 0.2,
        FOV = 150,
        ShowFOV = true,
    },
    UI = {
        Accent = Color3.fromRGB(255, 43, 43),
        Bg = Color3.fromRGB(15, 15, 20),
        SecBg = Color3.fromRGB(22, 22, 30),
        Text = Color3.fromRGB(240, 240, 240),
    }
}

-- Utils
local function getRole(p)
    local char = p.Character
    if not char then return "Innocent" end
    if char:FindFirstChild("GunTool") or char:FindFirstChild("SheriffGun") then return "Sheriff" end
    if char:FindFirstChild("KnifeTool") or char:FindFirstChild("Knife") then return "Murderer" end
    return "Innocent"
end

local function getRoleColor(r)
    if r == "Murderer" then return S.ESP.MurdererColor end
    if r == "Sheriff" then return S.ESP.SheriffColor end
    return S.ESP.InnocentColor
end

local function worldToVP(pos)
    local ok, vp = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if ok then return Vector2.new(vp.X, vp.Y), vp.Z > 0 end
    return Vector2.new(), false
end

local function getChar(p)
    local char = p.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not root or not head then return nil, nil end
    return root, head
end

-- ESP
local ESPObjs = {}

local function makeESP(p)
    if p == LocalPlayer then return end
    local o = {}
    local box = Drawing.new("Square")
    box.Visible = false box.Filled = false box.Thickness = 1.5
    o.Box = box
    local name = Drawing.new("Text")
    name.Visible = false name.Size = 13 name.Font = 2 name.Center = true name.Outline = true
    o.Name = name
    local dist = Drawing.new("Text")
    dist.Visible = false dist.Size = 11 dist.Font = 2 dist.Center = true dist.Outline = true
    o.Dist = dist
    local hpBg = Drawing.new("Square")
    hpBg.Visible = false hpBg.Filled = true hpBg.Color = Color3.fromRGB(20,20,20)
    o.HpBg = hpBg
    local hp = Drawing.new("Square")
    hp.Visible = false hp.Filled = true
    o.Hp = hp
    ESPObjs[p] = o
end

local function removeESP(p)
    local o = ESPObjs[p]
    if not o then return end
    for _, v in pairs(o) do pcall(function() v:Remove() end) end
    ESPObjs[p] = nil
end

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not ESPObjs[p] then makeESP(p) end
        local o = ESPObjs[p]
        if not o then continue end
        local root, head = getChar(p)
        if not root or not head or not S.ESP.Enabled then
            for _, v in pairs(o) do pcall(function() v.Visible = false end) end
            continue
        end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, v in pairs(o) do pcall(function() v.Visible = false end) end
            continue
        end
        local role = getRole(p)
        local color = getRoleColor(role)
        local hp, maxHp = hum.Health, hum.MaxHealth
        local d = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
        local topVP, topVis = worldToVP(head.Position + Vector3.new(0,0.7,0))
        local botVP, botVis = worldToVP(root.Position - Vector3.new(0,3,0))
        if not topVis or not botVis then
            for _, v in pairs(o) do pcall(function() v.Visible = false end) end
            continue
        end
        local h = math.abs(topVP.Y - botVP.Y)
        local w = h * 0.55
        local x = topVP.X - w/2
        local y = topVP.Y
        if S.ESP.ShowBox then
            o.Box.Visible = true o.Box.Color = color
            o.Box.Position = Vector2.new(x,y) o.Box.Size = Vector2.new(w,h)
        else o.Box.Visible = false end
        if S.ESP.ShowName then
            o.Name.Visible = true o.Name.Color = color
            o.Name.Position = Vector2.new(topVP.X, y-16)
            o.Name.Text = p.DisplayName.." ["..role:sub(1,3):upper().."]"
        else o.Name.Visible = false end
        if S.ESP.ShowDist then
            o.Dist.Visible = true o.Dist.Color = Color3.fromRGB(200,200,200)
            o.Dist.Position = Vector2.new(topVP.X, y+h+2)
            o.Dist.Text = d.."m"
        else o.Dist.Visible = false end
        if S.ESP.ShowHealth then
            local ratio = math.clamp(hp/maxHp, 0, 1)
            local hpColor = Color3.fromRGB(math.floor(255*(1-ratio)), math.floor(255*ratio), 50)
            o.HpBg.Visible = true o.HpBg.Position = Vector2.new(x-7,y) o.HpBg.Size = Vector2.new(4,h)
            o.Hp.Visible = true o.Hp.Color = hpColor
            o.Hp.Position = Vector2.new(x-7, y+h*(1-ratio)) o.Hp.Size = Vector2.new(4, h*ratio)
        else o.HpBg.Visible = false o.Hp.Visible = false end
    end
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false FOVCircle.Filled = false FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255,43,43) FOVCircle.Transparency = 0.6 FOVCircle.NumSides = 64

local function getAimTarget()
    local closest, closestD = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local vp, vis = worldToVP(head.Position)
        if not vis then continue end
        local d = (vp - center).Magnitude
        if d < S.Aim.FOV/2 and d < closestD then closestD = d closest = head end
    end
    return closest
end

-- Connections store
local Conns = {}

local function clearConn(key)
    if Conns[key] then Conns[key]:Disconnect() Conns[key] = nil end
end

-- Bhop
local bhopActive = false
local function updateBhop()
    clearConn("bhop")
    if not bhopActive then return end
    Conns["bhop"] = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum:GetState() == Enum.HumanoidStateType.Landed then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- Speed
local speedActive = false
local function updateSpeed()
    clearConn("speed")
    if not speedActive then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        return
    end
    Conns["speed"] = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 36 end
    end)
end

-- Noclip
local noclipActive = false
local function updateNoclip()
    clearConn("noclip")
    if not noclipActive then
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
        return
    end
    Conns["noclip"] = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

-- Fly
local flyActive = false
local flyBody = nil
local flyDir = Vector3.new()

local function updateFly()
    clearConn("fly")
    if flyBody then flyBody:Destroy() flyBody = nil end
    if not flyActive then
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if hum then hum.PlatformStand = true end
    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBody.Velocity = Vector3.new()
    flyBody.Parent = root
    Conns["fly"] = RunService.Heartbeat:Connect(function()
        if not flyBody or not flyBody.Parent then return end
        local cf = Camera.CFrame
        local d = flyDir
        if d.Magnitude > 0 then
            flyBody.Velocity = (cf * CFrame.new(d)).Position - cf.Position
            flyBody.Velocity = flyBody.Velocity.Unit * 50
        else
            flyBody.Velocity = Vector3.new()
        end
    end)
end

-- Invis
local invisActive = false
local function updateInvis()
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then
            p.LocalTransparencyModifier = invisActive and 1 or 0
        end
    end
end

-- Fullbright
local fbActive = false
local function updateFullbright()
    local L = game:GetService("Lighting")
    if fbActive then
        L.Brightness = 10 L.ClockTime = 14
        L.GlobalShadows = false
        L.Ambient = Color3.fromRGB(255,255,255)
        L.OutdoorAmbient = Color3.fromRGB(255,255,255)
    else
        L.Brightness = 2 L.ClockTime = 14
        L.GlobalShadows = true
        L.Ambient = Color3.fromRGB(127,127,127)
        L.OutdoorAmbient = Color3.fromRGB(127,127,127)
    end
end

-- Kill Aura
local kaActive = false
local function updateKA()
    clearConn("ka")
    if not kaActive then return end
    Conns["ka"] = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local pc = p.Character
            if not pc then continue end
            local pr = pc:FindFirstChild("HumanoidRootPart")
            local hum = pc:FindFirstChildOfClass("Humanoid")
            if not pr or not hum or hum.Health <= 0 then continue end
            if (root.Position - pr.Position).Magnitude <= 12 then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Remote")
                    if remote then pcall(function() remote:FireServer(pr.Position) end) end
                end
            end
        end
    end)
end

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Teleport
local function tpTo(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(name:lower()) then
            local char = LocalPlayer.Character
            local pc = p.Character
            if not char or not pc then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            local pr = pc:FindFirstChild("HumanoidRootPart")
            if root and pr then root.CFrame = pr.CFrame + Vector3.new(0,3,0) end
            return
        end
    end
end

-- =========================================================================
-- UI
-- =========================================================================
local SG = Instance.new("ScreenGui")
SG.Name = "PulseMobile"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = LocalPlayer.PlayerGui

-- Main window
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 60)
Main.Position = UDim2.new(0.5, -150, 0, 10)
Main.BackgroundColor3 = S.UI.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = S.UI.Accent
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local HFix = Instance.new("Frame")
HFix.Size = UDim2.new(1, 0, 0.5, 0)
HFix.Position = UDim2.new(0, 0, 0.5, 0)
HFix.BackgroundColor3 = S.UI.Accent
HFix.BorderSizePixel = 0
HFix.Parent = Header

local TitleL = Instance.new("TextLabel")
TitleL.Size = UDim2.new(0.7, 0, 1, 0)
TitleL.Position = UDim2.new(0, 12, 0, 0)
TitleL.BackgroundTransparency = 1
TitleL.Text = "⚡ PULSE MM2"
TitleL.TextColor3 = Color3.fromRGB(255,255,255)
TitleL.Font = Enum.Font.GothamBold
TitleL.TextSize = 14
TitleL.TextXAlignment = Enum.TextXAlignment.Left
TitleL.Parent = Header

-- Toggle open/close btn
local isOpen = false
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 60, 0, 28)
OpenBtn.Position = UDim2.new(1, -68, 0.5, -14)
OpenBtn.BackgroundColor3 = Color3.fromRGB(30,30,40)
OpenBtn.BorderSizePixel = 0
OpenBtn.Text = "OPEN"
OpenBtn.TextColor3 = Color3.fromRGB(255,255,255)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 11
OpenBtn.Parent = Header
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 6)

-- Scroll content
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -46)
Scroll.Position = UDim2.new(0, 0, 0, 46)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = S.UI.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = Scroll

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 8)
Padding.PaddingRight = UDim.new(0, 8)
Padding.PaddingTop = UDim.new(0, 8)
Padding.PaddingBottom = UDim.new(0, 8)
Padding.Parent = Scroll

-- Auto resize canvas
ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
end)

-- Open/close animation
local closedH = 60
local openH = 480
OpenBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    OpenBtn.Text = isOpen and "CLOSE" or "OPEN"
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 300, 0, isOpen and openH or closedH)
    }):Play()
end)

-- Section label
local function section(text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.Parent = Scroll
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = S.UI.Accent
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = S.UI.Accent
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Parent = f
end

-- Toggle
local function toggle(text, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.BackgroundColor3 = S.UI.SecBg
    f.BorderSizePixel = 0
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = S.UI.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local togBg = Instance.new("Frame")
    togBg.Size = UDim2.new(0, 40, 0, 22)
    togBg.Position = UDim2.new(1, -48, 0.5, -11)
    togBg.BackgroundColor3 = Color3.fromRGB(50,50,65)
    togBg.BorderSizePixel = 0
    togBg.Parent = f
    Instance.new("UICorner", togBg).CornerRadius = UDim.new(1, 0)

    local circ = Instance.new("Frame")
    circ.Size = UDim2.new(0, 16, 0, 16)
    circ.Position = UDim2.new(0, 3, 0.5, -8)
    circ.BackgroundColor3 = Color3.fromRGB(180,180,180)
    circ.BorderSizePixel = 0
    circ.Parent = togBg
    Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)

    local state = def or false
    local function set(v)
        state = v
        TweenService:Create(circ, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
        }):Play()
        TweenService:Create(togBg, TweenInfo.new(0.15), {
            BackgroundColor3 = v and S.UI.Accent or Color3.fromRGB(50,50,65)
        }):Play()
        cb(v)
    end
    set(state)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f
    btn.MouseButton1Click:Connect(function() set(not state) end)
end

-- Fly direction buttons
local function flyButtons()
    local outer = Instance.new("Frame")
    outer.Size = UDim2.new(1, 0, 0, 68)
    outer.BackgroundTransparency = 1
    outer.Parent = Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Fly Direction"
    lbl.TextColor3 = Color3.fromRGB(150,150,170)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = outer

    local btnData = {
        {text="▲", dir=Vector3.new(0,0,-1), pos=UDim2.new(0.5,-22,0,16)},
        {text="▼", dir=Vector3.new(0,0,1), pos=UDim2.new(0.5,-22,0,44)},
        {text="◄", dir=Vector3.new(-1,0,0), pos=UDim2.new(0.5,-56,0,44)},
        {text="►", dir=Vector3.new(1,0,0), pos=UDim2.new(0.5,12,0,44)},
        {text="UP", dir=Vector3.new(0,1,0), pos=UDim2.new(0,0,0,44)},
        {text="DN", dir=Vector3.new(0,-1,0), pos=UDim2.new(1,-38,0,44)},
    }

    for _, bd in pairs(btnData) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 34, 0, 22)
        b.Position = bd.pos
        b.BackgroundColor3 = S.UI.SecBg
        b.BorderSizePixel = 0
        b.Text = bd.text
        b.TextColor3 = S.UI.Text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.Parent = outer
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

        b.MouseButton1Down:Connect(function() flyDir = bd.dir end)
        b.MouseButton1Up:Connect(function() flyDir = Vector3.new() end)
        b.TouchLongPress:Connect(function() flyDir = Vector3.new() end)
    end
end

-- Aim button
local function aimButton()
    local outer = Instance.new("Frame")
    outer.Size = UDim2.new(1, 0, 0, 38)
    outer.BackgroundTransparency = 1
    outer.Parent = Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Aim Assist (Hold)"
    lbl.TextColor3 = S.UI.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = outer

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 32)
    btn.Position = UDim2.new(1, -80, 0.5, -16)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,65)
    btn.BorderSizePixel = 0
    btn.Text = "HOLD"
    btn.TextColor3 = S.UI.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = outer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Down:Connect(function()
        S.Aim.Active = true
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = S.UI.Accent}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        S.Aim.Active = false
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50,50,65)}):Play()
    end)
end

-- Teleport box
local function tpBox()
    local outer = Instance.new("Frame")
    outer.Size = UDim2.new(1, 0, 0, 36)
    outer.BackgroundColor3 = S.UI.SecBg
    outer.BorderSizePixel = 0
    outer.Parent = Scroll
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 8)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.58, -4, 1, -8)
    box.Position = UDim2.new(0, 6, 0, 4)
    box.BackgroundColor3 = Color3.fromRGB(30,30,40)
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = "Player name..."
    box.TextColor3 = S.UI.Text
    box.PlaceholderColor3 = Color3.fromRGB(100,100,120)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = outer
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.4, -4, 1, -8)
    btn.Position = UDim2.new(0.6, 2, 0, 4)
    btn.BackgroundColor3 = S.UI.Accent
    btn.BorderSizePixel = 0
    btn.Text = "TELEPORT"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = outer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(function() tpTo(box.Text) end)
end

-- Build UI
section("— ESP")
toggle("ESP Enabled", false, function(v) S.ESP.Enabled = v end)
toggle("Show Names", true, function(v) S.ESP.ShowName = v end)
toggle("Show Distance", true, function(v) S.ESP.ShowDist = v end)
toggle("Show Box", true, function(v) S.ESP.ShowBox = v end)
toggle("Show Health", true, function(v) S.ESP.ShowHealth = v end)

section("— AIM")
toggle("Aim Assist", false, function(v) S.Aim.Enabled = v end)
toggle("Show FOV", true, function(v) S.Aim.ShowFOV = v end)
aimButton()

section("— MOVEMENT")
toggle("Bhop", false, function(v) bhopActive = v updateBhop() end)
toggle("Speed Boost", false, function(v) speedActive = v updateSpeed() end)
toggle("Noclip", false, function(v) noclipActive = v updateNoclip() end)
toggle("Fly", false, function(v) flyActive = v updateFly() end)
flyButtons()

section("— MISC")
toggle("Invisibility", false, function(v) invisActive = v updateInvis() end)
toggle("Fullbright", false, function(v) fbActive = v updateFullbright() end)
toggle("Kill Aura", false, function(v) kaActive = v updateKA() end)
section("— TELEPORT")
tpBox()

-- Players
Players.PlayerAdded:Connect(function(p) task.wait(1) makeESP(p) end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then makeESP(p) end
end

-- Main loop
RunService.RenderStepped:Connect(function()
    updateESP()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    if S.Aim.ShowFOV and S.Aim.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Position = center
        FOVCircle.Radius = S.Aim.FOV/2
    else
        FOVCircle.Visible = false
    end
    if S.Aim.Enabled and S.Aim.Active then
        local target = getAimTarget()
        if target then
            local vp, vis = worldToVP(target.Position)
            if vis then
                local dx = (vp.X - center.X) * S.Aim.Smoothness
                local dy = (vp.Y - center.Y) * S.Aim.Smoothness
                mousemoverel(dx, dy)
            end
        end
    end
end)
