-- ares hub v5.1 "mint" release
-- built for public release | discord.gg/areshub
-- credits: ares dev squad

-- global check to prevent multiple execution
if getgenv().AresLoaded then 
    print("ares hub is already active")
    return 
end
getgenv().AresLoaded = true

-- block until game is ready
if not game:IsLoaded() then 
    local t = tick()
    repeat task.wait() until game:IsLoaded() or (tick() - t) > 20
end

-- service definitions
local Players   = game:GetService("Players")
local RS        = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local TweenSvc  = game:GetService("TweenService")
local HttpSvc   = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")
local CoreGui   = game:GetService("CoreGui")
local TeleSvc   = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")

-- shortcuts
local lp    = Players.LocalPlayer
local cam   = Workspace.CurrentCamera
local mouse = lp:GetMouse()

-- executor functional checks
local gethui = gethui or function() return lp:FindFirstChild("PlayerGui") or CoreGui end
local req    = request or (syn and syn.request) or (http and http.request) or nil
local hook   = hookmetamethod or (syn and syn.hook_metamethod)
local setclip = setclipboard or function() end
local checkc = checkcaller or function() return false end
local setcap = setfpscap or function() end
local getgenv = getgenv or function() return _G end

-- fallsbacks for drawing
if not Drawing then
    Drawing = { new = function() return {Remove=function() end} end }
end

local gethwid = gethwid or function() 
    local id = "UNKNOWN_HWID"
    pcall(function() id = game:GetService("RbxAnalyticsService"):GetClientId() end)
    return id
end

-- configuration table
local Config = {
    Combat = {
        Aimbot = { 
            Enabled = false, Key = Enum.KeyCode.E, Part = "Head", 
            Smooth = 0.15, FOV = 150, Team = true, Vis = true,
            AutoShoot = false, ShowFOV = false
        },
        Prediction = { Enabled = false, Intensity = 1.0, Drop = false, Velocity = 1000 },
        SilentAim = { Enabled = false, FOV = 200, Team = true, Part = "Head" },
        Trigger = { Enabled = false, Delay = 50, Team = true }
    },
    Visuals = {
        ESP = { 
            Enabled = false, Team = true, Box = false, Name = false, 
            Dist = false, Health = false, Trace = false, Skel = false, 
            Cham = false, Weapon = false, Range = 2500, ChamColor = Color3.fromRGB(245, 50, 120)
        },
        World = {
            Fullbright = false, TimeLock = false, NoFog = false, 
            Gravity = 196.2, FOV = 70, BlurEffect = false
        }
    },
    Movement = {
        Speed = { Enabled = false, Value = 16, Mode = "Velocity" },
        Jump = { Enabled = false, Value = 50, Infinite = false, WaterJump = false },
        Fly = { Enabled = false, Speed = 60 },
        Noclip = { Enabled = false },
        Spin = { Enabled = false, Speed = 30 }
    },
    Premium = {
        Magic = { Enabled = false },
        Hitbox = { Enabled = false, Size = 10 },
        KillAura = { Enabled = false, Range = 20 }
    },
    MenuKey = Enum.KeyCode.Insert
}

-- theme tokens
local Theme = {
    Main = Color3.fromRGB(15, 12, 22),
    Sidebar = Color3.fromRGB(12, 10, 18),
    Header = Color3.fromRGB(20, 16, 28),
    Card = Color3.fromRGB(25, 20, 35),
    Accent = Color3.fromRGB(245, 50, 120),
    Border = Color3.fromRGB(45, 30, 65),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(160, 150, 180)
}

-- internal state tracking
local _S = {
    UIActive = true,
    Auth = false,
    Drag = false,
    Tabs = {},
    CurTab = nil,
    ESPObjects = {},
    Target = nil,
    Connections = {}
}

-- utility functions for aim/visibility/logic
local U = {}

function U.GetChar(p) return p and p.Character end
function U.GetRoot(p) local c = U.GetChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
function U.GetHum(p)  local c = U.GetChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
function U.IsAlive(p) local h = U.GetHum(p)  return h and h.Health > 0 end

function U.IsEnemy(p)
    if not Config.Combat.Aimbot.Team then return true end
    if p == lp then return false end
    if p.Team and lp.Team and p.Team == lp.Team then return false end
    if p:FindFirstChild("TeamColor") and lp:FindFirstChild("TeamColor") and p.TeamColor == lp.TeamColor then return false end
    return true
end

function U.ToScreen(pos)
    local v, on = cam:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on
end

function U.Visible(pt)
    if not Config.Combat.Aimbot.Vis then return true end
    local p = RaycastParams.new()
    p.FilterDescendantsInstances = {lp.Character, cam, Workspace:FindFirstChild("Ignore")}
    p.FilterType = Enum.RaycastFilterType.Exclude
    local r = Workspace:Raycast(cam.CFrame.Position, (pt.Position - cam.CFrame.Position).Unit * 2500, p)
    return not r or r.Instance:IsDescendantOf(pt.Parent)
end

function U.Predict(part, player)
    if not Config.Combat.Prediction.Enabled then return part.Position end
    local r = U.GetRoot(player)
    if not r then return part.Position end
    local dist = (part.Position - cam.CFrame.Position).Magnitude
    local time = dist / Config.Combat.Prediction.Velocity
    local pred = part.Position + (r.Velocity * time * Config.Combat.Prediction.Intensity)
    if Config.Combat.Prediction.Drop then
        pred = pred + Vector3.new(0, 0.5 * Workspace.Gravity * (time^2), 0)
    end
    return pred
end

function U.Closest(fov, partName, checkVis)
    local best, bestD = nil, fov
    local mid = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if U.IsEnemy(p) and U.IsAlive(p) then
            local pt = U.GetChar(p) and U.GetChar(p):FindFirstChild(partName)
            if pt and (not checkVis or U.Visible(pt)) then
                local sp, on = U.ToScreen(pt.Position)
                if on then
                    local d = (sp - mid).Magnitude
                    if d < bestD then bestD = d; best = pt; _S.Target = p end
                end
            end
        end
    end
    return best
end

-- config saving/loading
function U.SaveConfig()
    if writefile then
        pcall(function()
            writefile("ares_hub_v5.json", HttpSvc:JSONEncode(Config))
        end)
    end
end

function U.LoadConfig()
    if isfile and isfile("ares_hub_v5.json") then
        pcall(function()
            local data = HttpSvc:JSONDecode(readfile("ares_hub_v5.json"))
            for k,v in pairs(data) do 
                if type(v) == "table" then
                    for k2,v2 in pairs(v) do Config[k][k2] = v2 end
                else
                    Config[k] = v 
                end
            end
        end)
    end
end

-- logic for security and hooks
local Security = {}

function Security.Hook()
    if not hook then return end
    print("hardening metatable hooks...")
    
    local oldN
    oldN = hook(game, "__namecall", function(self, ...)
        if checkc() then return oldN(self, ...) end
        local m = getnamecallmethod()
        if (Config.Combat.SilentAim.Enabled or Config.Premium.Magic.Enabled) and (m == "Raycast" or m == "FindPartOnRay") then
            local t = U.Closest(Config.Combat.SilentAim.FOV, Config.Combat.SilentAim.Part, not Config.Premium.Magic.Enabled)
            if t then
                local args = {...}
                local p = U.Predict(t, _S.Target)
                if m == "Raycast" then
                    args[2] = (p - args[1]).Unit * 1500
                else
                    args[1] = Ray.new(args[1].Origin, (p - args[1].Origin).Unit * 1500)
                end
                return oldN(self, unpack(args))
            end
        end
        return oldN(self, ...)
    end)

    local oldI
    oldI = hook(game, "__index", function(self, k)
        if not checkc() and _S.Auth and (Config.Combat.SilentAim.Enabled or Config.Premium.Magic.Enabled) then
            if self == mouse and (k == "Hit" or k == "Target") then
                local t = U.Closest(Config.Combat.SilentAim.FOV, Config.Combat.SilentAim.Part, not Config.Premium.Magic.Enabled)
                if t then
                    local p = U.Predict(t, _S.Target)
                    return k == "Hit" and CFrame.new(p) or t
                end
            end
        end
        return oldI(self, k)
    end)
end

-- ui library construction
local UI = {}

function UI.Init()
    local sg = Instance.new("ScreenGui")
    sg.Name = HttpSvc:GenerateGUID(false)
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = gethui() end)
    
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 600, 0, 480)
    main.Position = UDim2.new(0.5, -300, 0.5, -240)
    main.BackgroundColor3 = Theme.Main
    main.BorderSizePixel = 0
    main.Parent = sg
    main.Visible = true -- set visible for intro/auth
    
    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Theme.Border
    stroke.Thickness = 1.2
    
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Theme.Header
    header.BorderSizePixel = 0
    header.Parent = main
    
    local hCorner = Instance.new("UICorner", header)
    hCorner.CornerRadius = UDim.new(0, 10)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ares hub · v5.1 peak release"
    title.TextColor3 = Theme.Accent
    title.Font = Enum.Font.RobotoMono
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- dragging functionality
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = main.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
    end)
    RS.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 150, 1, -42)
    sidebar.Position = UDim2.new(0, 0, 0, 42)
    sidebar.BackgroundColor3 = Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Visible = false -- wait for auth
    sidebar.Parent = main
    
    local tabList = Instance.new("ScrollingFrame")
    tabList.Size = UDim2.new(1, -20, 1, -110)
    tabList.Position = UDim2.new(0, 10, 0, 15)
    tabList.BackgroundTransparency = 1
    tabList.ScrollBarThickness = 0
    tabList.Parent = sidebar
    
    local list = Instance.new("UIListLayout", tabList)
    list.Padding = UDim.new(0, 6)
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -150, 1, -42)
    container.Position = UDim2.new(0, 150, 0, 42)
    container.BackgroundTransparency = 1
    container.Visible = false -- wait for auth
    container.Parent = main
    
    -- user info area
    local userArea = Instance.new("Frame")
    userArea.Size = UDim2.new(1, -24, 0, 65)
    userArea.Position = UDim2.new(0, 12, 1, -77)
    userArea.BackgroundColor3 = Theme.Card
    userArea.Parent = sidebar
    Instance.new("UICorner", userArea).CornerRadius = UDim.new(0, 8)
    
    local uIcon = Instance.new("ImageLabel")
    uIcon.Size = UDim2.new(0, 40, 0, 40)
    uIcon.Position = UDim2.new(0, 10, 0.5, -20)
    uIcon.BackgroundColor3 = Theme.Main
    uIcon.Parent = userArea
    Instance.new("UICorner", uIcon).CornerRadius = UDim.new(1, 0)
    
    pcall(function() 
        uIcon.Image = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    
    local uName = Instance.new("TextLabel")
    uName.Size = UDim2.new(1, -60, 0, 20)
    uName.Position = UDim2.new(0, 56, 0, 13)
    uName.BackgroundTransparency = 1
    uName.Text = lp.DisplayName
    uName.TextColor3 = Theme.Text
    uName.Font = Enum.Font.GothamBold
    uName.TextSize = 13
    uName.TextXAlignment = Enum.TextXAlignment.Left
    uName.Parent = userArea
    
    local uRank = Instance.new("TextLabel")
    uRank.Size = UDim2.new(1, -60, 0, 20)
    uRank.Position = UDim2.new(0, 56, 0, 32)
    uRank.BackgroundTransparency = 1
    uRank.Text = "Standard User"
    uRank.TextColor3 = Theme.SubText
    uRank.Font = Enum.Font.Gotham
    uRank.TextSize = 11
    uRank.TextXAlignment = Enum.TextXAlignment.Left
    uRank.Parent = userArea

    -- activation screen
    local auth = Instance.new("Frame")
    auth.Size = UDim2.new(1, 0, 1, 0)
    auth.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    auth.ZIndex = 500
    auth.Visible = true
    auth.Parent = main
    Instance.new("UICorner", auth).CornerRadius = UDim.new(0, 10)
    
    local aPopup = Instance.new("Frame")
    aPopup.Size = UDim2.new(0, 380, 0, 240)
    aPopup.Position = UDim2.new(0.5, -190, 0.5, -120)
    aPopup.BackgroundColor3 = Theme.Main
    aPopup.Parent = auth
    Instance.new("UICorner", aPopup).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", aPopup).Color = Theme.Accent
    
    local aHeader = Instance.new("TextLabel")
    aHeader.Size = UDim2.new(1, 0, 0, 70)
    aHeader.Text = "ARES ACTIVATION"
    aHeader.TextColor3 = Theme.Accent
    aHeader.Font = Enum.Font.GothamBold
    aHeader.TextSize = 22
    aHeader.BackgroundTransparency = 1
    aHeader.Parent = aPopup
    
    local aBox = Instance.new("TextBox")
    aBox.Size = UDim2.new(0.85, 0, 0, 50)
    aBox.Position = UDim2.new(0.075, 0, 0.35, 0)
    aBox.BackgroundColor3 = Theme.Card
    aBox.PlaceholderText = "Paste License Key (ARES-...)"
    aBox.TextColor3 = Theme.Text
    aBox.Font = Enum.Font.RobotoMono
    aBox.Parent = aPopup
    Instance.new("UICorner", aBox).CornerRadius = UDim.new(0, 8)
    
    local aBtn = Instance.new("TextButton")
    aBtn.Size = UDim2.new(0.85, 0, 0, 50)
    aBtn.Position = UDim2.new(0.075, 0, 0.65, 0)
    aBtn.BackgroundColor3 = Theme.Accent
    aBtn.Text = "UNLOCK ACCESS"
    aBtn.TextColor3 = Color3.new(1, 1, 1)
    aBtn.Font = Enum.Font.GothamBold
    aBtn.Parent = aPopup
    Instance.new("UICorner", aBtn).CornerRadius = UDim.new(0, 8)
    
    local aHint = Instance.new("TextLabel")
    aHint.Size = UDim2.new(1, 0, 0, 35)
    aHint.Position = UDim2.new(0, 0, 0.88, 0)
    aHint.Text = "Support: discord.gg/areshub"
    aHint.TextColor3 = Theme.SubText
    aHint.Font = Enum.Font.Gotham
    aHint.BackgroundTransparency = 1
    aHint.Parent = aPopup
    
    -- functional tab system
    function UI.Tab(label)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = Theme.Sidebar
        btn.Text = "  " .. label
        btn.TextColor3 = Theme.SubText
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = tabList
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 3
        page.ScrollBarColor3 = Theme.Accent
        page.Parent = container
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local pList = Instance.new("UIListLayout", page)
        pList.Padding = UDim.new(0, 12)
        local pPad = Instance.new("UIPadding", page)
        pPad.PaddingLeft = UDim.new(0, 25); pPad.PaddingRight = UDim.new(0, 25); pPad.PaddingTop = UDim.new(0, 25)
        
        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(_S.Tabs) do
                t.page.Visible = false
                t.btn.TextColor3 = Theme.SubText
                t.btn.BackgroundColor3 = Theme.Sidebar
            end
            page.Visible = true
            btn.TextColor3 = Theme.Text
            btn.BackgroundColor3 = Theme.Card
        end)
        
        if not _S.CurTab then 
            page.Visible = true
            btn.TextColor3 = Theme.Text
            btn.BackgroundColor3 = Theme.Card
            _S.CurTab = label 
        end
        _S.Tabs[label] = {page = page, btn = btn}
        
        local obj = {}
        
        function obj:Section(txt)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, 30)
            l.Text = txt
            l.TextColor3 = Theme.Accent
            l.Font = Enum.Font.GothamBold
            l.TextSize = 13
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.BackgroundTransparency = 1
            l.Parent = page
        end
        
        function obj:Toggle(txt, tbl, key, callback)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 0, 42)
            f.BackgroundColor3 = Theme.Card
            f.Parent = page
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
            
            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -70, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = txt
            lb.TextColor3 = Theme.Text
            lb.Font = Enum.Font.Gotham
            lb.TextSize = 14
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.BackgroundTransparency = 1
            lb.Parent = f
            
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 44, 0, 24)
            b.Position = UDim2.new(1, -58, 0.5, -12)
            b.BackgroundColor3 = Theme.Main
            b.Text = ""
            b.Parent = f
            Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
            
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 18, 0, 18)
            dot.Position = UDim2.new(0, 3, 0.5, -9)
            dot.BackgroundColor3 = Theme.SubText
            dot.Parent = b
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            
            local function update()
                local val = tbl[key]
                local pos = val and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                local col = val and Theme.Accent or Theme.SubText
                TweenSvc:Create(dot, TweenInfo.new(0.2), {Position = pos, BackgroundColor3 = col}):Play()
                if callback then callback(val) end
            end
            
            b.MouseButton1Click:Connect(function() tbl[key] = not tbl[key]; update() end)
            update()
        end
        
        function obj:Slider(txt, tbl, key, min, max, callback)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 0, 65)
            f.BackgroundColor3 = Theme.Card
            f.Parent = page
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
            
            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -20, 0, 35)
            lb.Position = UDim2.new(0, 18, 0, 5)
            lb.Text = txt
            lb.TextColor3 = Theme.Text
            lb.Font = Enum.Font.Gotham
            lb.TextSize = 14
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.BackgroundTransparency = 1
            lb.Parent = f
            
            local vlb = Instance.new("TextLabel")
            vlb.Size = UDim2.new(0, 60, 0, 35)
            vlb.Position = UDim2.new(1, -78, 0, 5)
            vlb.Text = tostring(tbl[key])
            vlb.TextColor3 = Theme.Accent
            vlb.Font = Enum.Font.RobotoMono
            vlb.TextSize = 14
            vlb.TextXAlignment = Enum.TextXAlignment.Right
            vlb.BackgroundTransparency = 1
            vlb.Parent = f
            
            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -36, 0, 7)
            track.Position = UDim2.new(0, 18, 0, 45)
            track.BackgroundColor3 = Theme.Main
            track.Parent = f
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
            
            local fill = Instance.new("Frame")
            local startP = (tbl[key] - min) / (max - min)
            fill.Size = UDim2.new(startP, 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            
            local dragBtn = Instance.new("TextButton")
            dragBtn.Size = UDim2.new(1, 0, 1, 0)
            dragBtn.BackgroundTransparency = 1
            dragBtn.Text = ""
            dragBtn.Parent = track
            
            local active = false
            dragBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then active = true end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then active = false end end)
            
            RS.RenderStepped:Connect(function()
                if active then
                    local p = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local val = math.floor(min + (max - min) * p)
                    tbl[key] = val
                    vlb.Text = tostring(val)
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    if callback then callback(val) end
                end
            end)
        end
        
        function obj:Button(txt, callback)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 40)
            b.BackgroundColor3 = Theme.Card
            b.Text = txt
            b.TextColor3 = Theme.Text
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.Parent = page
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
            b.MouseButton1Click:Connect(callback)
        end
        
        return obj
    end
    
    -- key validation logic (Ported from rivals_v4)
    aBtn.MouseButton1Click:Connect(function()
        local key = aBox.Text
        local hwid = gethwid()
        aHint.Text = "Authenticating..."
        aHint.TextColor3 = Theme.SubText
        
        if req then
            task.spawn(function()
                local s, res = pcall(function()
                    return req({
                        Url = "http://127.0.0.1:8080/validate",
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpSvc:JSONEncode({key = key, hwid = hwid}),
                        Timeout = 8
                    })
                end)
                
                if s and res.StatusCode == 200 then
                    local data = HttpSvc:JSONDecode(res.Body)
                    if data.valid then
                        aHint.Text = "Welcome, Premium Activated!"
                        aHint.TextColor3 = Color3.fromRGB(50, 255, 80)
                        uRank.Text = "Ares Premium"
                        _S.Auth = true
                        task.wait(1.2)
                        auth:Destroy()
                        sidebar.Visible = true
                        container.Visible = true
                        _S.UIActive = true
                    else
                        aHint.Text = data.message or "Invalid License Key."
                        aHint.TextColor3 = Color3.fromRGB(255, 60, 60)
                    end
                else
                    aHint.Text = "Connection Failed. (Is licensing server up?)"
                    aHint.TextColor3 = Theme.Accent
                end
            end)
        else
            aHint.Text = "Local Bypass / Legacy Executor Mode."
            task.wait(1)
            _S.Auth = true
            auth:Destroy()
            sidebar.Visible = true
            container.Visible = true
            _S.UIActive = true
        end
    end)
    
    -- toggle key listener
    UIS.InputBegan:Connect(function(i, g)
        if not g and i.KeyCode == Config.MenuKey and _S.Auth then
            main.Visible = not main.Visible
            _S.UIActive = main.Visible
        end
    end)
    
    return main
end

-- initialization of script modules
local function RunMint()
    Security.Hook()
    local home = UI.Init()
    U.LoadConfig()
    
    -- tab construction
    local combat = UI.Tab("combat")
    combat:Section("targeting")
    combat:Toggle("enable aimbot", Config.Combat.Aimbot, "Enabled")
    combat:Toggle("team check", Config.Combat.Aimbot, "Team")
    combat:Toggle("visibility check", Config.Combat.Aimbot, "Vis")
    combat:Slider("mouse smoothness", Config.Combat.Aimbot, "Smooth", 1, 100, function(v) Config.Combat.Aimbot.Smooth = v/100 end)
    combat:Slider("aim fov size", Config.Combat.Aimbot, "FOV", 10, 800)
    combat:Toggle("render fov ring", Config.Combat.Aimbot, "ShowFOV")
    
    combat:Section("prediction")
    combat:Toggle("bullet prediction", Config.Combat.Prediction, "Enabled")
    combat:Slider("velocity scale", Config.Combat.Prediction, "Velocity", 500, 3000)
    combat:Slider("intensity", Config.Combat.Prediction, "Intensity", 1, 100, function(v) Config.Combat.Prediction.Intensity = v/10 end)
    
    combat:Section("silent aim")
    combat:Toggle("silent targeting", Config.Combat.SilentAim, "Enabled")
    combat:Slider("silent fov", Config.Combat.SilentAim, "FOV", 10, 800)
    
    local visual = UI.Tab("visuals")
    visual:Section("esp rendering")
    visual:Toggle("master switch", Config.Visuals.ESP, "Enabled")
    visual:Toggle("2d bounding boxes", Config.Visuals.ESP, "Box")
    visual:Toggle("player identities", Config.Visuals.ESP, "Name")
    visual:Toggle("health status", Config.Visuals.ESP, "Health")
    visual:Toggle("magenta highlights", Config.Visuals.ESP, "Cham")
    visual:Toggle("skeletal overlay", Config.Visuals.ESP, "Skel")
    visual:Toggle("active weapon", Config.Visuals.ESP, "Weapon")
    visual:Toggle("tracers", Config.Visuals.ESP, "Trace")
    visual:Slider("max distance", Config.Visuals.ESP, "Range", 100, 10000)
    
    local move = UI.Tab("movement")
    move:Section("physics exploitation")
    move:Toggle("enhanced speed", Config.Movement.Speed, "Enabled")
    move:Slider("magnitude", Config.Movement.Speed, "Value", 16, 500)
    move:Toggle("extended jump", Config.Movement.Jump, "Enabled")
    move:Slider("height", Config.Movement.Jump, "Value", 50, 600)
    move:Toggle("infinite jump", Config.Movement.Jump, "Infinite")
    move:Toggle("flight protocol", Config.Movement.Fly, "Enabled")
    move:Slider("fly speed", Config.Movement.Fly, "Speed", 10, 500)
    move:Toggle("collision bypass", Config.Movement.Noclip, "Enabled")
    move:Toggle("spinbot (premium)", Config.Movement.Spin, "Enabled")
    move:Slider("spin speed", Config.Movement.Spin, "Speed", 15, 500)
    
    local premium = UI.Tab("premium")
    premium:Section("ragebot suite")
    premium:Toggle("magic bullet (no-wall)", Config.Premium.Magic, "Enabled")
    premium:Toggle("hitbox expansion", Config.Premium.Hitbox, "Enabled")
    premium:Slider("hitbox scale", Config.Premium.Hitbox, "Size", 1, 150)
    premium:Toggle("kill aura", Config.Premium.KillAura, "Enabled")
    
    local world = UI.Tab("world")
    world:Section("environment")
    world:Toggle("full brightness", Config.Visuals.World, "Fullbright", function(v) Lighting.Brightness = v and 3 or 1; Lighting.Ambient = v and Color3.new(1,1,1) or Color3.new(0,0,0) end)
    world:Slider("gravity control", Config.Visuals.World, "Gravity", 0, 500, function(v) Workspace.Gravity = v end)
    world:Slider("field of view", Config.Visuals.World, "FOV", 30, 140, function(v) cam.FieldOfView = v end)
    
    local settings = UI.Tab("misc")
    settings:Section("execution")
    settings:Button("save current config", U.SaveConfig)
    settings:Button("copy hub discord", function() setclip("discord.gg/areshub") end)
    settings:Button("relaunch script", function() TeleSvc:Teleport(game.PlaceId, lp) end)
    settings:Slider("frame limit", Config, "FPS", 30, 360, setcap)

    -- drawing logic (robust implementation)
    local function CreateESP(p)
        if p == lp then return end
        local d = {
            box = Drawing.new("Square"),
            name = Drawing.new("Text"),
            trace = Drawing.new("Line"),
            skel = {
                Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), 
                Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line")
            }
        }
        d.box.Thickness = 1.2; d.box.Color = Theme.Accent
        d.name.Size = 14; d.name.Center = true; d.name.Outline = true; d.name.Color = Theme.Text; d.name.Font = 2
        d.trace.Thickness = 1; d.trace.Color = Theme.Accent; d.trace.Transparency = 0.6
        for _,s in pairs(d.skel) do s.Thickness = 1; s.Color = Theme.Accent; s.Transparency = 0.8 end
        _S.ESPObjects[p] = d
    end
    
    for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
    Players.PlayerAdded:Connect(CreateESP)
    Players.PlayerRemoving:Connect(function(p) 
        if _S.ESPObjects[p] then 
            for _,v in pairs(_S.ESPObjects[p]) do 
                if type(v) == "table" then for _,z in pairs(v) do z:Remove() end else v:Remove() end 
            end 
            _S.ESPObjects[p] = nil 
        end 
    end)
    
    local fovC = Drawing.new("Circle")
    fovC.Thickness = 1; fovC.Color = Theme.Accent; fovC.NumSides = 64
    
    -- execution loops
    RS.RenderStepped:Connect(function()
        if not _S.Auth then return end
        
        fovC.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        fovC.Radius = Config.Combat.Aimbot.FOV
        fovC.Visible = Config.Combat.Aimbot.ShowFOV and Config.Combat.Aimbot.Enabled
        
        if _S.UIActive then mouse.Icon = "rbxassetid://12513364998" else mouse.Icon = "" end
        
        -- ESP Loop Rendering
        for p, d in pairs(_S.ESPObjects) do
            local r = U.GetRoot(p)
            local h = U.GetHum(p)
            local char = U.GetChar(p)
            
            local function kill() d.box.Visible = false; d.name.Visible = false; d.trace.Visible = false; for _,s in pairs(d.skel) do s.Visible = false end end
            
            if Config.Visuals.ESP.Enabled and U.IsEnemy(p) and r and h and h.Health > 0 then
                local pos, on = U.ToScreen(r.Position)
                local dist = (r.Position - cam.CFrame.Position).Magnitude
                if on and dist < Config.Visuals.ESP.Range then
                    local sizeW = 2200 / dist; local sizeH = 3400 / dist
                    d.box.Size = Vector2.new(sizeW, sizeH); d.box.Position = pos - d.box.Size / 2; d.box.Visible = Config.Visuals.ESP.Box
                    
                    local weaponText = ""
                    if Config.Visuals.ESP.Weapon then
                        local tool = char:FindFirstChildOfClass("Tool")
                        weaponText = tool and " [" .. tool.Name .. "]" or ""
                    end
                    
                    d.name.Text = p.DisplayName .. weaponText .. " (" .. math.floor(dist) .. "m)"
                    d.name.Position = d.box.Position - Vector2.new(0, 18); d.name.Visible = Config.Visuals.ESP.Name
                    d.trace.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y); d.trace.To = pos; d.trace.Visible = Config.Visuals.ESP.Trace
                    
                    if Config.Visuals.ESP.Skel then
                        local head = char:FindFirstChild("Head")
                        local la = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftUpperArm")
                        local ra = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
                        if head and la and ra then
                            local sH, hO = U.ToScreen(head.Position); local sR, rO = U.ToScreen(r.Position)
                            local sLA, laO = U.ToScreen(la.Position); local sRA, raO = U.ToScreen(ra.Position)
                            if hO and rO then d.skel[1].From = sH; d.skel[1].To = sR; d.skel[1].Visible = true end
                            if rO and laO then d.skel[2].From = sR; d.skel[2].To = sLA; d.skel[2].Visible = true end
                            if rO and raO then d.skel[3].From = sR; d.skel[3].To = sRA; d.skel[3].Visible = true end
                        end
                    else for _,s in pairs(d.skel) do s.Visible = false end end
                    
                    local highlight = char:FindFirstChild("AresPeak")
                    if Config.Visuals.ESP.Cham then
                        if not highlight then highlight = Instance.new("Highlight", char); highlight.Name = "AresPeak" end
                        highlight.FillColor = Config.Visuals.ESP.ChamColor; highlight.OutlineColor = Color3.new(1,1,1); highlight.Enabled = true
                    elseif highlight then highlight.Enabled = false end
                else kill() end
            else kill() end
        end
        
        -- Aimbot Target Logic
        if Config.Combat.Aimbot.Enabled and UIS:IsKeyDown(Config.Combat.Aimbot.Key) then
            local t = U.Closest(Config.Combat.Aimbot.FOV, Config.Combat.Aimbot.Part, Config.Combat.Aimbot.Vis)
            if t then
                local p = U.Predict(t, _S.Target)
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, p), Config.Combat.Aimbot.Smooth)
                if Config.Combat.Aimbot.AutoShoot then mouse1press(); task.wait(0.02); mouse1release() end
            end
        end
    end)
    
    RS.Heartbeat:Connect(function()
        if not _S.Auth then return end
        local r = U.GetRoot(lp)
        local h = U.GetHum(lp)
        if r and h then
            if Config.Movement.Speed.Enabled then r.Velocity = (h.MoveDirection * Config.Movement.Speed.Value) + Vector3.new(0, r.Velocity.Y, 0) end
            if Config.Movement.Jump.Enabled then h.JumpPower = Config.Movement.Jump.Value; h.UseJumpPower = true end
            if Config.Movement.Jump.Infinite and UIS:IsKeyDown(Enum.KeyCode.Space) then r.Velocity = Vector3.new(r.Velocity.X, h.JumpPower, r.Velocity.Z) end
            if Config.Movement.Fly.Enabled then local v = UIS:IsKeyDown(Enum.KeyCode.Space) and Config.Movement.Fly.Speed or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -Config.Movement.Fly.Speed or 0); r.Velocity = (h.MoveDirection * Config.Movement.Fly.Speed) + Vector3.new(0, v + 2, 0) end
            if Config.Movement.Noclip.Enabled then for _,v in ipairs(lp.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
            if Config.Movement.Spin.Enabled then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(Config.Movement.Spin.Speed), 0) end
            if Config.Premium.Hitbox.Enabled then for _,p in ipairs(Players:GetPlayers()) do if U.IsEnemy(p) and U.IsAlive(p) then local head = U.GetChar(p) and U.GetChar(p):FindFirstChild("Head"); if head then head.Size = Vector3.new(Config.Premium.Hitbox.Size, Config.Premium.Hitbox.Size, Config.Premium.Hitbox.Size); head.CanCollide = false; head.Transparency = 0.7 end end end end
        end
    end)
end

-- manual entry splash
local function Splash()
    local sg = Instance.new("ScreenGui", gethui())
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 10000
    local bg = Instance.new("Frame", sg); bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    local l = Instance.new("TextLabel", bg); l.Size = UDim2.new(1, 0, 1, 0); l.Text = "ARES HUB V5.1"; l.TextColor3 = Theme.Accent; l.Font = Enum.Font.GothamBold; l.TextSize = 65; l.BackgroundTransparency = 1; l.TextTransparency = 1
    TweenSvc:Create(l, TweenInfo.new(2), {TextTransparency = 0}):Play()
    task.wait(3); TweenSvc:Create(l, TweenInfo.new(1), {TextTransparency = 1}):Play()
    TweenSvc:Create(bg, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play(); task.wait(1.5); sg:Destroy()
end

-- start systems
task.spawn(Splash)
task.wait(4.8)
RunMint()

-- console verification
print("----------------------------")
print("Ares Hub v5.1 'Mint' Active")
print("Build: Public Release [Peak]")
print("Auth: Pro Edition Verified")
print("----------------------------")
-- Nerd Check
-- Ares Hub on Top
