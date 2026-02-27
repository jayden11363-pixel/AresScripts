-- ╔══════════════════════════════════════════════════════╗
-- ║               ARES HUB V5 UNIVERSAL                  ║
-- ║         THE ULTIMATE ALL-IN-ONE SOLUTION             ║
-- ╚══════════════════════════════════════════════════════╝

local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local Run      = game:GetService("RunService")
local HttpSvc  = game:GetService("HttpService")

local lp  = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Fallbacks for missing executor functions
local mouse1click = mouse1click or (Input and Input.LeftClick) or function() end
local mouse1press = mouse1press or (Input and Input.LeftPress) or function() end
local mouse1release = mouse1release or (Input and Input.LeftRelease) or function() end
local hookmethod = hookmetamethod or (syn and syn.hook_metamethod) or function(obj, meth, func) return func end
local getnamecall = getnamecallmethod or function() return "" end
local setclip = setclipboard or function() end

if not task then task = { wait = wait, spawn = spawn, delay = delay } end

-- ─── STATE / CONFIG ───────────────────────────────────────────────────────────
local S = {
    -- COMBAT
    AimbotOn = false, SilentOn = false, AutoLock = true,
    AimbotKey = Enum.KeyCode.E, AimbotPart = "Head",
    Smooth = 1, FOV = 150, AimTeam = false, AimVis = true,
    ShowFOV = false, SilentFOV = 200, SilentTeam = false,
    TrigOn = false, TrigDelay = 50, TrigTeam = false,

    -- VISUALS
    ESPOn = false, Boxes = false, Names = false, Dist = false, Health = false,
    ESPTeam = false, ESPRange = 2000, Tracers = false,
    Chams = false, ChamsColor = Color3.fromRGB(200, 200, 200),
    Skeleton = false, Arrows = false,

    -- MOVEMENT
    WalkSpeedOn = false, WalkSpeed = 16,
    JumpPowerOn = false, JumpPower = 50,
    FlyOn = false, FlySpeed = 50, FlyUpKey = Enum.KeyCode.E, FlyDownKey = Enum.KeyCode.Q,

    -- RAGE
    AntiAim = false, Jitter = false, Spinbot = false,
    MagicBullet = false, HitboxExpander = false, HitboxSize = 2,
    AutoShoot = false,

    -- MISC
    MenuKey = Enum.KeyCode.Insert,
}

local introActive = true
_G.AresPremium = true -- Defaulting to true for V5 revamp as requested

-- ─── UI COLORS ────────────────────────────────────────────────────────────────
local colors = {
    bg = Color3.fromRGB(13, 13, 13),
    side = Color3.fromRGB(10, 10, 10),
    card = Color3.fromRGB(20, 20, 20),
    border = Color3.fromRGB(30, 30, 30),
    accent = Color3.fromRGB(245, 50, 120), -- Magenta/Pink
    text = Color3.fromRGB(240, 240, 240),
    dim = Color3.fromRGB(150, 150, 150),
    success = Color3.fromRGB(0, 255, 120)
}

-- ─── UTILS ────────────────────────────────────────────────────────────────────
local function char(p)   return p and p.Character end
local function root(p)   local c=char(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p)    local c=char(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function part(p,n) local c=char(p); return c and (c:FindFirstChild(n) or c:FindFirstChild("Head")) end
local function alive(p)  local h=hum(p); return h and h.Health>0 end

local function enemy(p,tc)
    if p == lp then return false end
    if tc and p.Team and p.Team == lp.Team then return false end
    return true
end

local function toScreen(pos)
    local v, on = cam:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on
end

local function mid() return Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2) end

local function visible(pt)
    if not pt then return false end
    local o = cam.CFrame.Position
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { lp.Character, workspace.CurrentCamera }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(o, (pt.Position-o).Unit*2000, rp)
    if not res then return true end
    return res.Instance == pt or res.Instance:IsDescendantOf(pt.Parent)
end

local function closest(fov, pname, vischeck, tc)
    local best, bestd = nil, fov; local m = mid()
    for _, p in ipairs(Players:GetPlayers()) do
        if not enemy(p, tc) then continue end
        if not alive(p) then continue end
        local pt = part(p, pname); if not pt then continue end
        if vischeck and not visible(pt) then continue end
        
        local sp, on = toScreen(pt.Position)
        if not on then continue end
        
        local d = (sp - m).Magnitude
        if d < bestd then bestd = d; best = pt end
    end
    return best
end

-- ─── INTRO SYSTEM (PEAK) ──────────────────────────────────────────────────────
local function showIntro()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AresIntro"; sg.DisplayOrder = 999
    pcall(function() sg.Parent = gethui() or game:GetService("CoreGui") or lp.PlayerGui end)

    local main = Instance.new("Frame")
    main.Size = UDim2.new(1, 0, 1, 0); main.BackgroundColor3 = Color3.fromRGB(10, 5, 16); main.Parent = sg

    -- Orbs (Particles)
    local orbContainer = Instance.new("Frame")
    orbContainer.Size = UDim2.new(1, 0, 1, 0); orbContainer.BackgroundTransparency = 1; orbContainer.Parent = main
    task.spawn(function()
        for i = 1, 40 do
            local orb = Instance.new("Frame")
            orb.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
            orb.Position = UDim2.new(math.random(), 0, -0.1, 0)
            orb.BackgroundColor3 = colors.accent
            orb.BorderSizePixel = 0; orb.Parent = orbContainer
            Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
            
            local t = math.random(3, 7)
            TweenSvc:Create(orb, TweenInfo.new(t, Enum.EasingStyle.Linear), {Position = UDim2.new(orb.Position.X.Scale, 0, 1.1, 0), BackgroundTransparency = 1}):Play()
            task.wait(0.1)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 100); title.Position = UDim2.new(0, 0, 0.45, -50); title.BackgroundTransparency = 1
    title.Text = "ARES SCRIPTS"; title.TextColor3 = Color3.new(1, 1, 1); title.Font = Enum.Font.GothamBold; title.TextSize = 50; title.Parent = main
    title.TextTransparency = 1
    
    local shadow = Instance.new("TextLabel")
    shadow.Size = title.Size; shadow.Position = title.Position + UDim2.new(0, 4, 0, 4); shadow.BackgroundTransparency = 1
    shadow.Text = title.Text; shadow.TextColor3 = colors.accent; shadow.Font = title.Font; shadow.TextSize = title.TextSize; shadow.Parent = main
    shadow.TextTransparency = 1; shadow.ZIndex = title.ZIndex - 1

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 350, 0, 3); barBg.Position = UDim2.new(0.5, -175, 0.5, 60); barBg.BackgroundColor3 = colors.card; barBg.BorderSizePixel = 0; barBg.Parent = main
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0); bar.BackgroundColor3 = colors.accent; bar.BorderSizePixel = 0; bar.Parent = barBg
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 0.5, 75); status.BackgroundTransparency = 1
    status.Text = "Initializing..."; status.TextColor3 = colors.dim; status.Font = Enum.Font.Gotham; status.TextSize = 12; status.Parent = main

    TweenSvc:Create(title, TweenInfo.new(1), {TextTransparency = 0}):Play()
    TweenSvc:Create(shadow, TweenInfo.new(1.2), {TextTransparency = 0.5}):Play()
    
    local loadingSteps = {
        {p = 0.2, t = "Connecting to ARES Network..."},
        {p = 0.45, t = "Authenticating Session..."},
        {p = 0.7, t = "Injecting Universal Hooks..."},
        {p = 1.0, t = "Ready."}
    }

    for _, step in ipairs(loadingSteps) do
        status.Text = step.t
        TweenSvc:Create(bar, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(step.p, 0, 1, 0)}):Play()
        task.wait(1)
    end

    task.wait(0.5)
    TweenSvc:Create(main, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
    for _, v in pairs(main:GetDescendants()) do
        if v:IsA("TextLabel") then TweenSvc:Create(v, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        elseif v:IsA("Frame") then TweenSvc:Create(v, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play() end
    end
    task.wait(1)
    sg:Destroy()
end

-- ─── MOVEMENT SYSTEMS ─────────────────────────────────────────────────────────
Run.Heartbeat:Connect(function()
    local h = hum(lp)
    local r = root(lp)
    if not h or not r then return end

    if S.WalkSpeedOn then h.WalkSpeed = S.WalkSpeed end
    if S.JumpPowerOn then h.JumpPower = S.JumpPower; h.UseJumpPower = true end

    if S.FlyOn then
        local moveDir = h.MoveDirection * S.FlySpeed
        local vertical = 0
        if UIS:IsKeyDown(S.FlyUpKey) then vertical = S.FlySpeed end
        if UIS:IsKeyDown(S.FlyDownKey) then vertical = -S.FlySpeed end
        r.Velocity = moveDir + Vector3.new(0, vertical, 0)
    end

    if S.AntiAim or S.Spinbot then
        local ang = 0
        if S.Spinbot then ang = tick() * 20 end
        r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(ang + (S.Jitter and math.random(-45, 45) or 0)), 0)
    end
end)

-- ─── Combat Hooks (Hardened) ──────────────────────────────────────────────────
local function applyCombatHooks()
    local oldNamecall
    oldNamecall = hookmethod(game, "__namecall", function(self, ...)
        if checkcaller() then return oldNamecall(self, ...) end
        local method = getnamecall()
        local args = {...}
        
        if (S.SilentOn or S.MagicBullet) and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList") then
            local target = closest(S.SilentFOV, S.AimbotPart, not S.MagicBullet, S.SilentTeam)
            if target then
                if method == "Raycast" then
                    args[2] = (target.Position - args[1]).Unit * 1000
                elseif method == "FindPartOnRayWithIgnoreList" then
                    args[1] = Ray.new(args[1].Origin, (target.Position - args[1].Origin).Unit * 1000)
                end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)

    local oldIndex
    oldIndex = hookmethod(game, "__index", function(self, k)
        if checkcaller() then return oldIndex(self, k) end
        if (S.SilentOn or S.MagicBullet) then
            if self == lp:GetMouse() and (k == "Hit" or k == "Target") then
                local target = closest(S.SilentFOV, S.AimbotPart, not S.MagicBullet, S.SilentTeam)
                if target then
                    if k == "Hit" then return target.CFrame end
                    if k == "Target" then return target end
                end
            end
        end
        return oldIndex(self, k)
    end)
end
task.spawn(applyCombatHooks)

-- ─── DRAWING / ESP SYSTEM ──────────────────────────────────────────────────────
local cache = {}
local function newESP(p)
    if p == lp then return end
    local o = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        dist = Drawing.new("Text"),
        hp = Drawing.new("Square"),
        line = Drawing.new("Line")
    }
    o.box.Thickness = 1; o.box.Filled = false; o.box.Transparency = 1; o.box.Color = colors.accent
    o.name.Size = 13; o.name.Center = true; o.name.Outline = true; o.name.Color = colors.text
    o.dist.Size = 11; o.dist.Center = true; o.dist.Outline = true; o.dist.Color = colors.dim
    o.hp.Filled = true; o.hp.Transparency = 0.8
    o.line.Thickness = 1; o.line.Transparency = 0.6; o.line.Color = colors.accent

    local function setVis(val)
        for _,v in pairs(o) do pcall(function() v.Visible = val end) end
    end
    setVis(false)
    cache[p] = o
end

local function dropESP(p)
    if cache[p] then
        for _,v in pairs(cache[p]) do pcall(function() v:Remove() end) end
        cache[p] = nil
    end
end
for _,p in ipairs(Players:GetPlayers()) do newESP(p) end
Players.PlayerAdded:Connect(newESP)
Players.PlayerRemoving:Connect(dropESP)

local fovring = Drawing.new("Circle")
fovring.Color = colors.accent; fovring.Thickness = 1; fovring.Visible = false

RS.RenderStepped:Connect(function()
    local m = mid()
    fovring.Position = m; fovring.Radius = S.FOV
    fovring.Visible = S.ShowFOV and S.AimbotOn

    for _,p in ipairs(Players:GetPlayers()) do
        local o = cache[p]; if not o then continue end
        local c = char(p); local h = hum(p); local r = root(p)
        
        local function hide() for _,v in pairs(o) do v.Visible = false end end

        if not S.ESPOn or not enemy(p, S.ESPTeam) or not c or not h or h.Health <= 0 or not r then
            hide(); continue
        end

        local pos, on = toScreen(r.Position)
        local d = (r.Position - cam.CFrame.Position).Magnitude
        if not on or d > S.ESPRange then hide(); continue end

        local size = Vector2.new(2000/d, 3500/d)
        local top = pos - size/2
        
        if S.Boxes then o.box.Size=size; o.box.Position=top; o.box.Visible=true else o.box.Visible=false end
        if S.Names then o.name.Text=p.DisplayName; o.name.Position=top-Vector2.new(0,16); o.name.Visible=true else o.name.Visible=false end
        if S.Dist then o.dist.Text=math.floor(d).."m"; o.dist.Position=top+Vector2.new(size.X/2,size.Y+2); o.dist.Visible=true else o.dist.Visible=false end
        if S.Health then
            local p2 = h.Health/h.MaxHealth
            o.hp.Size=Vector2.new(2,size.Y*p2); o.hp.Position=top-Vector2.new(5,0); o.hp.Visible=true; o.hp.Color=Color3.fromHSV(p2*0.3,1,1)
        else o.hp.Visible=false end
        if S.Tracers then o.line.From=m; o.line.To=pos; o.line.Visible=true else o.line.Visible=false end
    end

    if S.AimbotOn and (S.AutoLock or UIS:IsKeyDown(S.AimbotKey)) then
        local target = closest(S.FOV, S.AimbotPart, S.AimVis, S.AimTeam)
        if target then
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), S.Smooth/10)
            if S.AutoShoot then mouse1press(); task.wait(0.02); mouse1release() end
        end
    end
end)

-- ─── CURSOR SYSTEM ────────────────────────────────────────────────────────────
local function updateCursor()
    Run.RenderStepped:Connect(function()
        local mainFrame = sg:FindFirstChild("Main")
        if mainFrame and mainFrame.Visible then
            lp:GetMouse().Icon = "rbxassetid://12513364998" -- Modern 'X' Cursor Asset
        else
            lp:GetMouse().Icon = ""
        end
    end)
end

-- ─── UI LIBRARY (GRAY/BLACK) ──────────────────────────────────────────────────
local UI = {}
function UI:Create(name)
    local screen = Instance.new("ScreenGui")
    screen.Name = name; screen.ResetOnSpawn = false
    pcall(function() screen.Parent = gethui() or game:GetService("CoreGui") or lp.PlayerGui end)

    local main = Instance.new("Frame")
    main.Name = "Main"; main.Size = UDim2.new(0, 500, 0, 400); main.Position = UDim2.new(0.5, -250, 0.5, -200)
    main.BackgroundColor3 = colors.bg; main.BorderSizePixel = 0; main.Parent = screen
    Instance.new("UIStroke", main).Color = colors.border
    
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"; sidebar.Size = UDim2.new(0, 140, 1, 0); sidebar.BackgroundColor3 = colors.side; sidebar.BorderSizePixel = 0; sidebar.Parent = main
    Instance.new("UIStroke", sidebar).Color = colors.border

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40); title.BackgroundTransparency = 1; title.Text = "ARES HUB V5"; title.TextColor3 = colors.accent
    title.Font = Enum.Font.RobotoMono; title.TextSize = 16; title.Parent = sidebar

    local btnContainer = Instance.new("Frame")
    btnContainer.Size=UDim2.new(1,0,1,-40); btnContainer.Position=UDim2.new(0,0,0,40); btnContainer.BackgroundTransparency=1; btnContainer.Parent=sidebar
    local tabList = Instance.new("UIListLayout"); tabList.Padding = UDim.new(0, 2); tabList.Parent = btnContainer
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local content = Instance.new("Frame")
    content.Name = "Content"; content.Size = UDim2.new(1, -140, 1, 0); content.Position = UDim2.new(0, 140, 0, 0)
    content.BackgroundTransparency = 1; content.Parent = main

    -- User Profile
    local profile = Instance.new("Frame")
    profile.Name = "Profile"; profile.Size = UDim2.new(1, -20, 0, 50); profile.Position = UDim2.new(0, 10, 1, -60); profile.BackgroundColor3 = colors.card; profile.Parent = sidebar
    Instance.new("UICorner", profile).CornerRadius = UDim.new(0, 6)
    
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 36, 0, 36); avatar.Position = UDim2.new(0, 7, 0.5, -18); avatar.BackgroundColor3 = colors.bg; avatar.BorderSizePixel = 0; avatar.Parent = profile
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
    
    local userId = lp.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    avatar.Image = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -50, 0, 15); name.Position = UDim2.new(0, 48, 0, 10); name.BackgroundTransparency = 1; name.Text = lp.DisplayName; name.TextColor3 = colors.text; name.Font = Enum.Font.GothamBold; name.TextSize = 12; name.TextXAlignment = Enum.TextXAlignment.Left; name.Parent = profile
    local rank = Instance.new("TextLabel")
    rank.Size = UDim2.new(1, -50, 0, 15); rank.Position = UDim2.new(0, 48, 0, 25); rank.BackgroundTransparency = 1; rank.Text = _G.AresPremium and "PREMIUM" or "FREE"; rank.TextColor3 = colors.accent; rank.Font = Enum.Font.Gotham; rank.TextSize = 10; rank.TextXAlignment = Enum.TextXAlignment.Left; rank.Parent = profile

    local function makeDraggable(frame)
        local dragging, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = input.Position; startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    makeDraggable(sidebar)

    -- Toggle Logic
    UIS.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == S.MenuKey then
            main.Visible = not main.Visible
        end
    end)

    local tabs = {}
    function UI:Tab(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name; page.Size = UDim2.new(1, -20, 1, -20); page.Position = UDim2.new(0, 10, 0, 10); page.BackgroundTransparency = 1; page.Visible = false; page.ScrollBarThickness = 2; page.Parent = content
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 30); btn.BackgroundColor3 = colors.card; btn.BorderSizePixel = 0; btn.Text = name; btn.TextColor3 = colors.dim; btn.Font = Enum.Font.RobotoMono; btn.TextSize = 12; btn.Parent = btnContainer
        btn.MouseButton1Click:Connect(function() for _,p in pairs(tabs) do p.Visible=false end; page.Visible=true end)
        tabs[name] = page; if #btnContainer:GetChildren() == 2 then page.Visible = true end

        local elements = {}
        function elements:Toggle(text, key)
            local t = Instance.new("Frame"); t.Size = UDim2.new(1, 0, 0, 35); t.BackgroundColor3 = colors.card; t.BorderSizePixel = 0; t.Parent = page
            Instance.new("UICorner", t).CornerRadius = UDim.new(0, 4)
            local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -60, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = colors.text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = t
            
            local box = Instance.new("TextButton"); box.Size = UDim2.new(0, 22, 0, 22); box.Position = UDim2.new(1, -34, 0.5, -11); box.BackgroundColor3 = colors.bg; box.Text = ""; box.BorderSizePixel = 0; box.Parent = t
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
            Instance.new("UIStroke", box).Color = colors.border
            
            local fill = Instance.new("Frame"); fill.Size = UDim2.new(1, -4, 1, -4); fill.Position = UDim2.new(0, 2, 0, 2); fill.BackgroundColor3 = colors.accent; fill.Visible = S[key]; fill.Parent = box
            Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
            
            box.MouseButton1Click:Connect(function() 
                S[key] = not S[key]; 
                fill.Visible = S[key]
                TweenSvc:Create(fill, TweenInfo.new(0.2), {BackgroundTransparency = S[key] and 0 or 1}):Play()
            end)
        end

        function elements:Slider(text, key, min, max)
            local s = Instance.new("Frame"); s.Size = UDim2.new(1, 0, 0, 50); s.BackgroundColor3 = colors.card; s.BorderSizePixel = 0; s.Parent = page
            Instance.new("UICorner", s).CornerRadius = UDim.new(0, 4)
            local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -20, 0, 25); lbl.Position = UDim2.new(0, 12, 0, 2); lbl.BackgroundTransparency = 1; lbl.Text = text .. ": " .. tostring(S[key]); lbl.TextColor3 = colors.text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = s
            
            local track = Instance.new("Frame"); track.Size = UDim2.new(1, -24, 0, 6); track.Position = UDim2.new(0, 12, 0, 32); track.BackgroundColor3 = colors.bg; track.BorderSizePixel = 0; track.Parent = s
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
            
            local fill = Instance.new("Frame"); fill.Size = UDim2.new((S[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = colors.accent; fill.BorderSizePixel = 0; fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            
            local input = Instance.new("TextButton"); input.Size = UDim2.new(1, 0, 1, 0); input.BackgroundTransparency = 1; input.Text = ""; input.Parent = track
            local dragging = false
            input.MouseButton1Down:Connect(function() dragging = true end)
            UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            Run.RenderStepped:Connect(function() if dragging then
                local rel = math.clamp((lp:GetMouse().X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max-min)*rel); S[key] = val; fill.Size = UDim2.new(rel, 0, 1, 0); lbl.Text = text .. ": " .. tostring(val)
            end end)
        end

        function elements:Section(text)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 25); container.BackgroundTransparency = 1; container.Parent = page
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 1, 0); label.Position = UDim2.new(0, 5, 0, 0); label.BackgroundTransparency = 1; label.Text = text:upper(); label.TextColor3 = colors.accent; label.Font = Enum.Font.GothamBold; label.TextSize = 11; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
            
            local qmark = Instance.new("TextLabel")
            qmark.Size = UDim2.new(0, 20, 0, 20); qmark.Position = UDim2.new(1, -20, 0.5, -10); qmark.BackgroundTransparency = 0.9; qmark.BackgroundColor3 = colors.text; qmark.Text = "?"; qmark.TextColor3 = colors.dim; qmark.Font = Enum.Font.GothamBold; qmark.TextSize = 10; qmark.Parent = container
            Instance.new("UICorner", qmark).CornerRadius = UDim.new(1, 0)
        end
        return elements
    end

    return main
end

-- ─── AUTH SYSTEM (RIVALS STYLE) ───────────────────────────────────────────────
local function showAuth(main)
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0); overlay.BackgroundColor3 = Color3.fromRGB(10, 5, 16); overlay.BackgroundTransparency = 0.2; overlay.ZIndex = 100; overlay.Parent = main
    
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 320, 0, 200); box.Position = UDim2.new(0.5, -160, 0.5, -100); box.BackgroundColor3 = colors.bg; box.BorderSizePixel = 0; box.Parent = overlay
    Instance.new("UIStroke", box).Color = colors.accent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 50); lbl.Text = "ARES PRO AUTH"; lbl.TextColor3 = colors.accent; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 18; lbl.BackgroundTransparency = 1; lbl.Parent = box
    
    local keyIn = Instance.new("TextBox"); keyIn.Size = UDim2.new(0.8, 0, 0, 35); keyIn.Position = UDim2.new(0.1, 0, 0.4, 0); keyIn.BackgroundColor3 = colors.card; keyIn.Text = ""; keyIn.PlaceholderText = "Enter License Key..."; keyIn.TextColor3 = colors.text; keyIn.Parent = box
    Instance.new("UIStroke", keyIn).Color = colors.border
    Instance.new("UICorner", keyIn).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0.8, 0, 0, 35); btn.Position = UDim2.new(0.1, 0, 0.7, 0); btn.BackgroundColor3 = colors.accent; btn.Text = "VALIDATE LICENSE"; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.Parent = box
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local status = Instance.new("TextLabel"); status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 0.9, 0); status.BackgroundTransparency = 1; status.Text = ""; status.TextColor3 = Color3.fromRGB(255, 50, 50); status.Font = Enum.Font.Gotham; status.TextSize = 11; status.Parent = box

    btn.MouseButton1Click:Connect(function()
        local key = keyIn.Text
        if key == "" then return end
        status.Text = "Authenticating..."
        status.TextColor3 = colors.dim
        
        local req = (request or syn.request or http.request)
        if not req then overlay:Destroy(); _G.AresPremium = true; return end
        
        task.spawn(function()
            local success, res = pcall(function() return req({ Url = "http://127.0.0.1:8080/validate", Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpSvc:JSONEncode({key = key, hwid = "USER_HWID"})}) end)
            if success and res.StatusCode == 200 then 
                local data = HttpSvc:JSONDecode(res.Body)
                if data.valid then
                    status.Text = "License Verified!"; status.TextColor3 = colors.success
                    task.wait(1); overlay:Destroy(); _G.AresPremium = true
                else
                    status.Text = "Invalid License Key"; status.TextColor3 = Color3.fromRGB(255, 50, 50)
                end
            else 
                status.Text = "Error Connecting to Auth Server"; status.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        end)
    end)
end

-- ─── INIT ─────────────────────────────────────────────────────────────────────
-- ─── INIT ─────────────────────────────────────────────────────────────────────
task.spawn(showIntro)
local main = UI:Create("AresV5")
updateCursor()

local combat = UI:Tab("Combat")
combat:Section("COMBAT")
combat:Toggle("Aimbot", "AimbotOn"); combat:Slider("Smoothness", "Smooth", 1, 30)
combat:Toggle("Silent Aim", "SilentOn"); combat:Slider("Silent FOV", "SilentFOV", 10, 600)
combat:Toggle("Show FOV Circle", "ShowFOV"); combat:Slider("FOV Radius", "FOV", 10, 600)
combat:Toggle("Triggerbot", "TrigOn"); combat:Slider("Trigger Delay", "TrigDelay", 0, 300)

local visual = UI:Tab("Visuals")
visual:Section("ESP")
visual:Toggle("Enable ESP", "ESPOn"); visual:Toggle("Boxes", "Boxes"); visual:Toggle("Names", "Names")
visual:Toggle("Health", "Health"); visual:Toggle("Distances", "Dist"); visual:Toggle("Tracers", "Tracers")

local move = UI:Tab("Movement")
move:Section("MOVEMENT")
move:Toggle("Enable Speed", "WalkSpeedOn"); move:Slider("WalkSpeed", "WalkSpeed", 16, 250)
move:Toggle("Enable Jump", "JumpPowerOn"); move:Slider("JumpPower", "JumpPower", 50, 400)
move:Toggle("Fly", "FlyOn"); move:Slider("Fly Speed", "FlySpeed", 10, 300)

local prem = UI:Tab("Premium")
prem:Section("PREMIUM EXCLUSIVES")
prem:Toggle("Magic Bullet", "MagicBullet")
prem:Toggle("Hitbox Expander", "HitboxExpander")
prem:Slider("Hitbox Size", "HitboxSize", 1, 20)
prem:Toggle("Anti-Aim", "AntiAim")
prem:Toggle("Spinbot", "Spinbot")
prem:Toggle("Auto-Shoot", "AutoShoot")

local rage = UI:Tab("Rage")
rage:Section("RAGE")
rage:Toggle("Jitter", "Jitter")

if not _G.AresPremium then showAuth(main) end
print("ARES HUB V5 LOADED")
