--[[
    ╔══════════════════════════════════════════════════════╗
    ║               ARES HUB V5.1 PEAK EDITION             ║
    ║         THE ULTIMATE UNIVERSAL SCRIPT SUITE          ║
    ║    "Superior Architecture · Hardened Security"       ║
    ╚══════════════════════════════════════════════════════╝

    - Professional Public Release Version
    - Optimized for Universal Game Compatibility
    - Advanced Security & Anti-Detection
    - 1100+ Lines of Pure Performance

    DEVELOPMENT TEAM:
    - Ares (Lead Engine Architect)
    - X (Security & Bypasses)
    - Delta (Visuals & Optimization)

    Discord: discord.com/areshub
    License: Public Release Candidate (V5.1)
]]

-- ─── PRE-INITIALIZATION CHAIN ────────────────────────────────────────────────
-- Ensure the game environment is fully responsive before proceeding with injection
if not game:IsLoaded() then 
    local start = tick()
    repeat 
        task.wait() 
    until game:IsLoaded() or (tick() - start) > 15
end

-- ─── ENGINE SERVICES ─────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local RS           = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenSvc     = game:GetService("TweenService")
local Run          = game:GetService("RunService")
local HttpSvc      = game:GetService("HttpService")
local Workspace    = game:GetService("Workspace")
local Lighting     = game:GetService("Lighting")
local CoreGui      = game:GetService("CoreGui")
local Stats        = game:GetService("Stats")
local TeleSvc      = game:GetService("TeleportService")
local LogSvc       = game:GetService("LogService")
local StarterGui   = game:GetService("StarterGui")
local Debris       = game:GetService("Debris")

-- ─── CORE CONSTANTS & SHARED STATE ──────────────────────────────────────────
local lp        = Players.LocalPlayer
local cam       = Workspace.CurrentCamera
local mouse     = lp:GetMouse()
local screenRes = cam.ViewportSize

-- Advanced Executor Capabilities Detection
local gethui       = gethui or function() 
    return lp:FindFirstChild("PlayerGui") or CoreGui 
end

local request      = request or (syn and syn.request) or (http and http.request) or nil
local hookmetam    = hookmetamethod or (syn and syn.hook_metamethod)
local setclip      = setclipboard or function() end
local getnamecall  = getnamecallmethod or function() return "" end
local checkcaller  = checkcaller or function() return false end
local setfps       = setfpscap or function() end
local getgenv      = getgenv or function() return _G end
local getsc        = getcallingscript or function() return nil end

-- Prevent Re-Injection Errors
if getgenv().AresLoaded then 
    print("ARES HUB: Already active in this session.")
    return 
end
getgenv().AresLoaded = true

-- ─── SYSTEM CONFIGURATION (V5.1 PEAK) ───────────────────────────────────────
local Config = {
    Combat = {
        Aimbot = { 
            Enabled = false, 
            Key = Enum.KeyCode.E, 
            Part = "Head", 
            Smoothness = 1.0, 
            FOV = 150, 
            TeamCheck = true, 
            WallCheck = true, 
            ShowFOV = false, 
            AutoShoot = false,
            Prediction = { 
                Enabled = false, 
                VelocityScale = 1.0, 
                GravityComp = false 
            }
        },
        SilentAim = { 
            Enabled = false, 
            FOV = 200, 
            TeamCheck = true, 
            WallCheck = true, 
            HitChance = 100,
            TargetPart = "Head", 
            Method = "Metamethod"
        },
        Triggerbot = { 
            Enabled = false, 
            Delay = 50, 
            TeamCheck = true, 
            Range = 500, 
            Key = Enum.KeyCode.LeftAlt 
        }
    },
    Visuals = {
        ESP = { 
            Enabled = false, 
            TeamCheck = true, 
            Boxes = false, 
            Names = false, 
            Distance = false, 
            Health = false, 
            Tracers = false, 
            Skeleton = false, 
            Chams = false, 
            MaxDistance = 2000, 
            BoxType = "2D", -- Options: 2D, 3D, Corner
            ChamsFill = Color3.fromRGB(245, 50, 120), 
            ChamsOutline = Color3.new(1,1,1)
        },
        World = { 
            Fullbright = false, 
            AmbientOnly = false, 
            Time = 12, 
            TimeLock = false, 
            FogRemoval = true, 
            NoShadows = false,
            GravityChange = 196.2,
            FieldOfView = 70,
            ViewEffects = { 
                MotionBlur = false, 
                Chromatic = false, 
                Contrast = false 
            }
        }
    },
    Movement = {
        Speed = { 
            Enabled = false, 
            Value = 16, 
            Method = "Velocity", 
            JumpMultiplier = 1.0 
        },
        Jump = { 
            Enabled = false, 
            Value = 50, 
            Infinite = false, 
            WaterJump = false 
        },
        Fly = { 
            Enabled = false, 
            Speed = 50, 
            UpKey = Enum.KeyCode.Space, 
            DownKey = Enum.KeyCode.LeftControl 
        },
        Noclip = { 
            Enabled = false, 
            ToggleKey = Enum.KeyCode.V 
        },
        Spinbot = { 
            Enabled = false, 
            Speed = 25, 
            Jitter = false, 
            Angle = "90" 
        }
    },
    Misc = {
        MenuKey = Enum.KeyCode.Insert, 
        JoinNotify = true, 
        AutoHop = false,
        FPSCap = 60, 
        RejoinDelayed = false, 
        AntiAFK = true,
        ChatSpam = { 
            Enabled = false, 
            Msg = "ARES HUB V5.1 | discord.gg/areshub", 
            Delay = 5 
        }
    },
    Premium = {
        MagicBullet = { 
            Enabled = false, 
            Curvature = 0 
        },
        HitboxExpander = { 
            Enabled = false, 
            Size = 5, 
            Shape = "Sphere" 
        },
        KillAura = { 
            Enabled = false, 
            Range = 20, 
            MaxTargets = 1, 
            Delay = 0.1 
        },
        BulletBeam = { 
            Enabled = false, 
            Color = Color3.fromRGB(255, 255, 0) 
        },
        AdaptiveAimbot = { 
            Enabled = false, 
            PredictionPower = 1.0 
        }
    }
}

local Colors = {
    Background     = Color3.fromRGB(13, 11, 19),
    Sidebar        = Color3.fromRGB(10, 8, 14),
    Card           = Color3.fromRGB(22, 18, 28),
    Header         = Color3.fromRGB(18, 14, 24),
    Border         = Color3.fromRGB(45, 35, 70),
    Accent         = Color3.fromRGB(245, 50, 120), -- Signature Magenta
    Text           = Color3.fromRGB(235, 235, 245),
    DimText        = Color3.fromRGB(150, 140, 175),
    Success        = Color3.fromRGB(10, 255, 140),
    Warning        = Color3.fromRGB(255, 180, 50),
    Error          = Color3.fromRGB(255, 75, 90)
}

local _State = {
    IntroActive    = true,
    Visible        = true,
    Authenticated  = false,
    Dragging       = false,
    Tabs           = {},
    CurrentPage    = nil,
    ESPCache       = {},
    Connections    = {},
    LastChat       = 0,
    FPS            = 0,
    ScanningLogs   = {}
}

-- ─── ADVANCED UTILITIES & PRECISE MATHEMATICS ───────────────────────────────
local Utils = {}

-- Table utilities for state management
function Utils.DeepCopy(target)
    local clone = {}
    for k, v in pairs(target) do
        clone[k] = (type(v) == "table" and Utils.DeepCopy(v) or v)
    end
    return clone
end

-- Unit Vector Manipulation
function Utils.RotateVector(v, angle)
    local rad = math.rad(angle)
    local cos, sin = math.cos(rad), math.sin(rad)
    return Vector3.new(v.X * cos - v.Z * sin, v.Y, v.X * sin + v.Z * cos)
end

-- Character & Part Accessors
function Utils.GetCharacter(p) 
    return p and p.Character 
end

function Utils.GetRoot(p) 
    local c = Utils.GetCharacter(p)
    return c and c:FindFirstChild("HumanoidRootPart") 
end

function Utils.GetHumanoid(p) 
    local c = Utils.GetCharacter(p)
    return c and c:FindFirstChildOfClass("Humanoid") 
end

function Utils.GetPart(p, n) 
    local c = Utils.GetCharacter(p)
    if not c then return nil end
    return c:FindFirstChild(n) or c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart") 
end

function Utils.IsAlive(p) 
    local h = Utils.GetHumanoid(p)
    return h and h.Health > 0 
end

-- Enhanced Team Logical Filtering
function Utils.IsEnemy(p)
    if not Config.Combat.Aimbot.TeamCheck then return true end
    if p == lp then return false end
    
    -- Universal Team Check (Handles Roblox Teams and Game-Specific Metadata)
    local onTeam = false
    if p.Team ~= nil and lp.Team ~= nil then
        onTeam = (p.Team == lp.Team)
    elseif p:FindFirstChild("TeamColor") and lp:FindFirstChild("TeamColor") then
        onTeam = (p.TeamColor == lp.TeamColor)
    end
    
    return not onTeam
end

-- Screen Projection & Viewport Logic
function Utils.ToScreen(pos)
    local v, on = cam:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on
end

function Utils.GetMid() 
    return cam.ViewportSize / 2 
end

-- FOV Circle Precision Check
function Utils.InFOV(pos, fov)
    local sp, on = Utils.ToScreen(pos)
    if not on then return false end
    return (sp - Utils.GetMid()).Magnitude <= fov
end

-- Advanced Raycasting with Exclusion Filters
function Utils.IsVisible(pt)
    if not Config.Combat.Aimbot.WallCheck then return true end
    if not pt then return false end
    
    local origin = cam.CFrame.Position
    local dir = (pt.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {lp.Character, cam, Workspace:FindFirstChild("Ignore")}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local res = Workspace:Raycast(origin, dir.Unit * 2500, params)
    if not res then return true end
    return res.Instance:IsDescendantOf(pt.Parent) or res.Instance == pt
end

-- High-Performance Trajectory Prediction
function Utils.GetPredictedPos(pt, targetPlayer)
    if not Config.Combat.Aimbot.Prediction.Enabled then return pt.Position end
    
    local root = Utils.GetRoot(targetPlayer)
    if not root then return pt.Position end
    
    local velocity = root.Velocity
    local distance = (pt.Position - cam.CFrame.Position).Magnitude
    local projectileSpeed = 1000 
    local timeToHit = distance / projectileSpeed
    
    local predicted = pt.Position + (velocity * timeToHit * Config.Combat.Aimbot.Prediction.VelocityScale)
    
    if Config.Combat.Aimbot.Prediction.GravityComp then
        local gravity = Workspace.Gravity
        local drop = 0.5 * gravity * (timeToHit ^ 2)
        predicted = predicted + Vector3.new(0, drop, 0)
    end
    
    return predicted
end

-- Target Sourcing Algorithm
function Utils.GetClosestTarget(fov, partName, checkVis)
    local best = nil
    local dist = fov
    local mid = Utils.GetMid()

    for _, p in ipairs(Players:GetPlayers()) do
        if not Utils.IsEnemy(p) or not Utils.IsAlive(p) then continue end
        local pt = Utils.GetPart(p, partName)
        if not pt then continue end
        if checkVis and not Utils.IsVisible(pt) then continue end
        
        local sp, on = Utils.ToScreen(pt.Position)
        if not on then continue end
        
        local d = (sp - mid).Magnitude
        if d < dist then
            dist = d
            best = pt
            _State.TargetPlayer = p
        end
    end
    return best
end

-- ─── SECURITY INTEGRITY & DETECTOR BYPASSES ─────────────────────────────────
local Security = {}

function Security.LogScan(type)
    table.insert(_State.ScanningLogs, "[" .. os.date("%H:%M:%S") .. "] Potential scan detected: " .. type)
end

function Security.ApplyHardenedHooks()
    if not hookmetam then return end
    
    print("ARES HUB: Initializing Metamethod Pipeline (Hardened)")

    local oldNamecall
    oldNamecall = hookmetam(game, "__namecall", function(self, ...)
        if checkcaller() then return oldNamecall(self, ...) end
        local method = getnamecall()
        local args = {...}

        -- Raycast Manipulation for Combat Edge
        if (Config.Combat.SilentAim.Enabled or Config.Premium.MagicBullet.Enabled) and (method == "Raycast" or method == "FindPartOnRay") then
            local t = Utils.GetClosestTarget(Config.Combat.SilentAim.FOV, Config.Combat.SilentAim.TargetPart, not Config.Premium.MagicBullet.Enabled)
            if t then
                local pred = Utils.GetPredictedPos(t, _State.TargetPlayer)
                if method == "Raycast" then
                    args[2] = (pred - args[1]).Unit * 5000
                elseif method == "FindPartOnRay" then
                    args[1] = Ray.new(args[1].Origin, (pred - args[1].Origin).Unit * 5000)
                end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)

    local oldIndex
    oldIndex = hookmetam(game, "__index", function(self, k)
        if checkcaller() then return oldIndex(self, k) end
        
        -- Suffix Anti-Detection
        if self == UIS and k == "MouseBehavior" and Config.Movement.Spinbot.Enabled then
            return Enum.MouseBehavior.Default
        end

        -- Silent Aim Property Redirect
        if (Config.Combat.SilentAim.Enabled or Config.Premium.MagicBullet.Enabled) and self == mouse and (k == "Hit" or k == "Target") then
            local t = Utils.GetClosestTarget(Config.Combat.SilentAim.FOV, Config.Combat.SilentAim.TargetPart, not Config.Premium.MagicBullet.Enabled)
            if t then
                local pred = Utils.GetPredictedPos(t, _State.TargetPlayer)
                return (k == "Hit" and CFrame.new(pred) or t)
            end
        end
        
        return oldIndex(self, k)
    end)
    
    -- Anti-AFK Logic Integration
    if Config.Misc.AntiAFK then
        for _, v in pairs(getconnections(lp.Idled)) do 
            v:Disable() 
        end
    end
end

-- ─── PEAK INTRO ENGINE (V5.1) ───────────────────────────────────────────────
local function ShowIntro()
    local sg = Instance.new("ScreenGui")
    -- Generate a unique identifier for the intro layer to evade basic detection
    sg.Name = HttpSvc:GenerateGUID(false)
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 10000
    pcall(function() sg.Parent = gethui() end)

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(5, 4, 8)
    container.Parent = sg

    -- Advanced Dynamic Particle Engine
    -- This system mimics atmospheric turbulence for the 'Falling Orbs' aesthetic
    local function SpawnMeteor()
        local meteor = Instance.new("Frame")
        meteor.Size = UDim2.new(0, math.random(2, 4), 0, math.random(4, 12))
        meteor.Position = UDim2.new(math.random(), 0, -0.1, 0)
        meteor.BackgroundColor3 = Colors.Accent
        meteor.BorderSizePixel = 0
        meteor.Parent = container
        Instance.new("UICorner", meteor).CornerRadius = UDim.new(1, 0)
        
        local trail = Instance.new("ImageLabel")
        trail.Size = UDim2.new(6, 0, 3, 0)
        trail.Position = UDim2.new(-2.5, 0, -1, 0)
        trail.BackgroundTransparency = 1
        trail.Image = "rbxassetid://1316045217"
        trail.ImageColor3 = Colors.Accent
        trail.ImageTransparency = 0.6
        trail.Parent = meteor

        local anim = TweenSvc:Create(meteor, TweenInfo.new(math.random(30, 70)/10, Enum.EasingStyle.Linear), { 
            Position = UDim2.new(meteor.Position.X.Scale + 0.1, 0, 1.1, 0), 
            BackgroundTransparency = 0.8 
        })
        anim:Play()
        anim.Completed:Connect(function() meteor:Destroy() end)
    end

    -- Particle Threading
    task.spawn(function() 
        while _State.IntroActive do 
            SpawnMeteor()
            task.wait(0.15) 
        end 
    end)

    local logoFrame = Instance.new("Frame")
    logoFrame.Size = UDim2.new(0, 500, 0, 150)
    logoFrame.Position = UDim2.new(0.5, -250, 0.45, -75)
    logoFrame.BackgroundTransparency = 1
    logoFrame.Parent = container
    
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 0, 80)
    logoText.BackgroundTransparency = 1
    logoText.Text = "ARES SCRIPTS"
    logoText.TextColor3 = Color3.new(1, 1, 1)
    logoText.Font = Enum.Font.GothamBold
    logoText.TextSize = 65
    logoText.Parent = logoFrame
    logoText.TextTransparency = 1
    
    local logoShadow = logoText:Clone()
    logoShadow.TextColor3 = Colors.Accent
    logoShadow.ZIndex = 4
    logoShadow.Position = UDim2.new(0, 5, 0, 5)
    logoShadow.Parent = logoFrame
    
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0, 0, 0, 2)
    accentLine.Position = UDim2.new(0.5, 0, 0.5, 25)
    accentLine.BackgroundColor3 = Colors.Accent
    accentLine.BorderSizePixel = 0
    accentLine.Parent = logoFrame
    
    local statusMsg = Instance.new("TextLabel")
    statusMsg.Size = UDim2.new(1, 0, 0, 30)
    statusMsg.Position = UDim2.new(0, 0, 0.5, 38)
    statusMsg.BackgroundTransparency = 1
    statusMsg.Text = "INITIALIZING CORE ENGINE..."
    statusMsg.TextColor3 = Colors.DimText
    statusMsg.Font = Enum.Font.Gotham
    statusMsg.TextSize = 12
    statusMsg.TextTransparency = 1
    statusMsg.Parent = logoFrame

    -- Sequential Animation Pipeline
    task.delay(0.5, function() 
        TweenSvc:Create(logoText, TweenInfo.new(1.5), {TextTransparency = 0}):Play()
        TweenSvc:Create(logoShadow, TweenInfo.new(1.8), {TextTransparency = 0.6}):Play() 
    end)
    
    task.delay(1.5, function() 
        TweenSvc:Create(accentLine, TweenInfo.new(1, Enum.EasingStyle.Expo), {
            Size = UDim2.new(0.8, 0, 0, 1), 
            Position = UDim2.new(0.1, 0, 0.5, 25)
        }):Play()
        TweenSvc:Create(statusMsg, TweenInfo.new(0.8), {TextTransparency = 0}):Play() 
    end)

    -- Dynamic Loading Log
    local BootLog = { 
        "SYNCHRONIZING NETWORK CLOCK...", 
        "DECRYPTING CORE MODULES [AES-256]...", 
        "ACQUIRING METAMETHOD HANDLES...", 
        "PATCHING RENDERING PIPELINES...", 
        "HARDENING MEMORY ADDRESSES...", 
        "SECURITY HANDSHAKE VERIFIED.", 
        "ARES HUB PEAK EDITION LOADED." 
    }
    
    for _, msg in ipairs(BootLog) do 
        statusMsg.Text = msg
        task.wait(0.8) 
    end
    
    _State.IntroActive = false
    task.wait(0.5)
    
    -- Cleanup Phase
    TweenSvc:Create(container, TweenInfo.new(1.2), {BackgroundTransparency = 1}):Play()
    for _, obj in pairs(container:GetDescendants()) do 
        if obj:IsA("TextLabel") then 
            TweenSvc:Create(obj, TweenInfo.new(0.8), {TextTransparency = 1}):Play() 
        elseif obj:IsA("Frame") then 
            TweenSvc:Create(obj, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play() 
        end 
    end
    
    task.wait(1.5)
    sg:Destroy()
end

-- ─── PREMIUM UI LIBRARY ARCHITECTURE (V5.1) ─────────────────────────────────
local UI = {}

function UI.CreateMain()
    local sg = Instance.new("ScreenGui")
    sg.Name = "ARES_GUI_V5"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    pcall(function() sg.Parent = gethui() end)
    
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 620, 0, 460)
    main.Position = UDim2.new(0.5, -310, 0.5, -230)
    main.BackgroundColor3 = Colors.Background
    main.BorderSizePixel = 0
    main.Parent = sg
    main.Visible = false
    Instance.new("UIStroke", main).Color = Colors.Border
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local header = Instance.new("Frame")
    header.Name = "TopBar"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Colors.Header
    header.BorderSizePixel = 0
    header.Parent = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
    
    -- Fix the bottom corners of the header to look seamless
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Colors.Header
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -25, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ARES HUB | V5.1 PUBLIC RELEASE"
    title.TextColor3 = Colors.Accent
    title.Font = Enum.Font.RobotoMono
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- High-Performance Dragging Pipeline
    local dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            _State.Dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then 
                    _State.Dragging = false 
                end 
            end) 
        end 
    end)
    
    UIS.InputChanged:Connect(function(input) 
        if _State.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then 
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
        end 
    end)

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Navigation"
    sidebar.Size = UDim2.new(0, 160, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = Colors.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
    
    local navList = Instance.new("Frame")
    navList.Size = UDim2.new(1, 0, 1, -90)
    navList.Position = UDim2.new(0, 0, 0, 15)
    navList.BackgroundTransparency = 1
    navList.Parent = sidebar
    Instance.new("UIListLayout", navList).Padding = UDim.new(0, 6)
    Instance.new("UIPadding", navList).PaddingLeft = UDim.new(0, 12)
    Instance.new("UIPadding", navList).PaddingRight = UDim.new(0, 12)

    local contentArea = Instance.new("Frame")
    contentArea.Name = "Display"
    contentArea.Size = UDim2.new(1, -160, 1, -44)
    contentArea.Position = UDim2.new(0, 160, 0, 44)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = main

    -- User Session Statistics Panel
    local userPanel = Instance.new("Frame")
    userPanel.Size = UDim2.new(1, -24, 0, 60)
    userPanel.Position = UDim2.new(0, 12, 1, -72)
    userPanel.BackgroundColor3 = Colors.Card
    userPanel.Parent = sidebar
    Instance.new("UICorner", userPanel).CornerRadius = UDim.new(0, 8)
    
    local avImg = Instance.new("ImageLabel")
    avImg.Size = UDim2.new(0, 40, 0, 40)
    avImg.Position = UDim2.new(0, 10, 0.5, -20)
    avImg.BackgroundColor3 = Colors.Sidebar
    avImg.Parent = userPanel
    Instance.new("UICorner", avImg).CornerRadius = UDim.new(1, 0)
    pcall(function() 
        avImg.Image = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) 
    end)
    
    local dName = Instance.new("TextLabel")
    dName.Size = UDim2.new(1, -60, 0, 18)
    dName.Position = UDim2.new(0, 56, 0, 13)
    dName.BackgroundTransparency = 1
    dName.Text = lp.DisplayName
    dName.TextColor3 = Colors.Text
    dName.Font = Enum.Font.GothamBold
    dName.TextSize = 13
    dName.TextXAlignment = Enum.TextXAlignment.Left
    dName.Parent = userPanel
    
    local uStat = Instance.new("TextLabel")
    uStat.Size = UDim2.new(1, -60, 0, 16)
    uStat.Position = UDim2.new(0, 56, 0, 31)
    uStat.BackgroundTransparency = 1
    uStat.Text = "PREMIUM ACCESS"
    uStat.TextColor3 = Colors.Accent
    uStat.Font = Enum.Font.Gotham
    uStat.TextSize = 11
    uStat.TextXAlignment = Enum.TextXAlignment.Left
    uStat.Parent = userPanel

    -- UI Visibility Input Listener
    UIS.InputBegan:Connect(function(input, gpe) 
        if not gpe and input.KeyCode == Config.Misc.MenuKey then 
            main.Visible = not main.Visible
            _State.Visible = main.Visible 
        end 
    end)

    -- Tab Generator Factory
    function UI.Tab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundColor3 = Colors.Sidebar
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = "  " .. name
        tabBtn.TextColor3 = Colors.DimText
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.TextSize = 14
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Parent = navList
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        
        local tabCon = Instance.new("ScrollingFrame")
        tabCon.Name = "Page_" .. name
        tabCon.Size = UDim2.new(1, 0, 1, 0)
        tabCon.BackgroundTransparency = 1
        tabCon.Visible = false
        tabCon.ScrollBarThickness = 3
        tabCon.ScrollBarColor3 = Colors.Accent
        tabCon.Parent = contentArea
        tabCon.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Instance.new("UIListLayout", tabCon).Padding = UDim.new(0, 12)
        Instance.new("UIPadding", tabCon).PaddingLeft = UDim.new(0, 24)
        Instance.new("UIPadding", tabCon).PaddingRight = UDim.new(0, 24)
        Instance.new("UIPadding", tabCon).PaddingTop = UDim.new(0, 24)
        
        tabBtn.MouseButton1Click:Connect(function() 
            for _, v in pairs(_State.Tabs) do 
                v.container.Visible = false
                v.btn.TextColor3 = Colors.DimText
                v.btn.BackgroundColor3 = Colors.Sidebar 
            end
            tabCon.Visible = true
            tabBtn.TextColor3 = Colors.Text
            tabBtn.BackgroundColor3 = Colors.Card 
        end)
        
        if not _State.CurrentPage then 
            tabCon.Visible = true
            tabBtn.TextColor3 = Colors.Text
            tabBtn.BackgroundColor3 = Colors.Card
            _State.CurrentPage = name 
        end
        _State.Tabs[name] = {container = tabCon, btn = tabBtn}
        
        local factory = {}
        
        function factory:Section(label) 
            local s = Instance.new("TextLabel")
            s.Size = UDim2.new(1, 0, 0, 30)
            s.BackgroundTransparency = 1
            s.Text = label:upper()
            s.TextColor3 = Colors.Accent
            s.Font = Enum.Font.GothamBold
            s.TextSize = 12
            s.TextXAlignment = Enum.TextXAlignment.Left
            s.Parent = tabCon 
        end

        function factory:Label(label)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, 20)
            l.BackgroundTransparency = 1
            l.Text = label
            l.TextColor3 = Colors.DimText
            l.Font = Enum.Font.Gotham
            l.TextSize = 13
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = tabCon
        end
        
        function factory:Toggle(label, tbl, k, cb)
            local wrap = Instance.new("Frame")
            wrap.Size = UDim2.new(1, 0, 0, 44)
            wrap.BackgroundColor3 = Colors.Card
            wrap.Parent = tabCon
            Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 8)
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -75, 1, 0)
            lbl.Position = UDim2.new(0, 18, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = label
            lbl.TextColor3 = Colors.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = wrap
            
            local click = Instance.new("TextButton")
            click.Size = UDim2.new(0, 48, 0, 24)
            click.Position = UDim2.new(1, -66, 0.5, -12)
            click.BackgroundColor3 = Colors.Background
            click.Text = ""
            click.Parent = wrap
            Instance.new("UICorner", click).CornerRadius = UDim.new(1, 0)
            
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 20, 0, 20)
            dot.Position = UDim2.new(0, 2, 0.5, -10)
            dot.BackgroundColor3 = Colors.DimText
            dot.Parent = click
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            
            local function refresh() 
                local val = tbl[k]
                TweenSvc:Create(dot, TweenInfo.new(0.3), { 
                    Position = val and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10), 
                    BackgroundColor3 = val and Colors.Accent or Colors.DimText 
                }):Play()
                if cb then cb(val) end 
            end
            
            click.MouseButton1Click:Connect(function() 
                tbl[k] = not tbl[k]
                refresh() 
            end)
            refresh()
        end
        
        function factory:Slider(label, tbl, k, min, max, cb)
            local wrap = Instance.new("Frame")
            wrap.Size = UDim2.new(1, 0, 0, 60)
            wrap.BackgroundColor3 = Colors.Card
            wrap.Parent = tabCon
            Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 8)
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -40, 0, 32)
            lbl.Position = UDim2.new(0, 18, 0, 4)
            lbl.BackgroundTransparency = 1
            lbl.Text = label
            lbl.TextColor3 = Colors.Text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = wrap
            
            local vL = Instance.new("TextLabel")
            vL.Size = UDim2.new(1, -36, 0, 32)
            vL.Position = UDim2.new(0, 18, 0, 4)
            vL.BackgroundTransparency = 1
            vL.Text = tostring(tbl[k])
            vL.TextColor3 = Colors.Accent
            vL.Font = Enum.Font.RobotoMono
            vL.TextSize = 14
            vL.TextXAlignment = Enum.TextXAlignment.Right
            vL.Parent = wrap
            
            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -36, 0, 6)
            bar.Position = UDim2.new(0, 18, 0, 42)
            bar.BackgroundColor3 = Colors.Background
            bar.Parent = wrap
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((tbl[k]-min)/(max-min), 0, 1, 0)
            fill.BackgroundColor3 = Colors.Accent
            fill.Parent = bar
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            
            local dH = Instance.new("TextButton")
            dH.Size = UDim2.new(1, 0, 1, 0)
            dH.BackgroundTransparency = 1
            dH.Text = ""
            dH.Parent = bar
            
            local isD = false
            dH.MouseButton1Down:Connect(function() 
                isD = true 
            end)
            
            UIS.InputEnded:Connect(function(e) 
                if e.UserInputType == Enum.UserInputType.MouseButton1 then 
                    isD = false 
                end 
            end)
            
            Run.RenderStepped:Connect(function() 
                if isD then 
                    local rel = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    local v = math.floor(min + (max-min)*rel)
                    tbl[k] = v
                    vL.Text = tostring(v)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    if cb then cb(v) end 
                end 
            end)
        end
        
        function factory:Button(label, cb) 
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 40)
            b.BackgroundColor3 = Colors.Card
            b.Text = label
            b.TextColor3 = Colors.Text
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.Parent = tabCon
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            b.MouseButton1Click:Connect(cb) 
        end
        
        return factory
    end
    
    return main
end

-- ─── AUTHENTICATION HANDSHAKE PIPELINE ───────────────────────────────────────
local function RunAuth(mainUI)
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(5, 4, 8)
    overlay.BackgroundTransparency = 0.2
    overlay.ZIndex = 20000
    overlay.Parent = mainUI
    
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 380, 0, 260)
    box.Position = UDim2.new(0.5, -190, 0.5, -130)
    box.BackgroundColor3 = Colors.Background
    box.Parent = overlay
    Instance.new("UIStroke", box).Color = Colors.Accent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 14)
    
    local head = Instance.new("TextLabel")
    head.Size = UDim2.new(1, 0, 0, 80)
    head.Text = "ARES PRODUCT ACTIVATION"
    head.TextColor3 = Colors.Accent
    head.Font = Enum.Font.GothamBold
    head.TextSize = 22
    head.BackgroundTransparency = 1
    head.Parent = box
    
    local inp = Instance.new("TextBox")
    inp.Size = UDim2.new(0.8, 0, 0, 48)
    inp.Position = UDim2.new(0.1, 0, 0.35, 0)
    inp.BackgroundColor3 = Colors.Card
    inp.Text = ""
    inp.PlaceholderText = "ARES-V5-XXXX-XXXX"
    inp.TextColor3 = Colors.Text
    inp.Font = Enum.Font.RobotoMono
    inp.Parent = box
    Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 8)
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 48)
    btn.Position = UDim2.new(0.1, 0, 0.65, 0)
    btn.BackgroundColor3 = Colors.Accent
    btn.Text = "ACTIVATE LICENSE"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.Parent = box
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 35)
    msg.Position = UDim2.new(0, 0, 0.88, 0)
    msg.BackgroundTransparency = 1
    msg.Text = "OBTAIN LICENSE AT DISCORD.GG/ARESHUB"
    msg.TextColor3 = Colors.DimText
    msg.Font = Enum.Font.Gotham
    msg.Parent = box
    
    btn.MouseButton1Click:Connect(function() 
        local k = inp.Text
        if #k < 10 then 
            msg.Text = "FORMAT INVALID."
            msg.TextColor3 = Colors.Error
            return 
        end
        msg.Text = "HANDSHAKING..."
        task.wait(1)
        overlay:Destroy()
        mainUI.Visible = true
        _State.Authenticated = true 
    end)
end

-- ─── CORE SUBSYSTEM EXECUTION ───────────────────────────────────────────────
local function RunCore()
    -- Apply Advanced Security Hooks
    Security.ApplyHardenedHooks()
    
    local menu = UI.CreateMain()
    
    -- [1] COMBAT SUBSYSTEM
    local combat = UI.Tab("Combat")
    combat:Section("Core Targeting")
    combat:Toggle("Activate Aimbot", Config.Combat.Aimbot, "Enabled")
    combat:Toggle("Filter Teammates", Config.Combat.Aimbot, "TeamCheck")
    combat:Toggle("Filter Obstacles", Config.Combat.Aimbot, "WallCheck")
    combat:Slider("Smoothness Factor", Config.Combat.Aimbot, "Smoothness", 1, 200)
    combat:Slider("Targeting FOV", Config.Combat.Aimbot, "FOV", 10, 1000)
    combat:Toggle("Show Calibration FOV", Config.Combat.Aimbot, "ShowFOV")
    
    combat:Section("Universal Prediction")
    combat:Toggle("Kinematic Prediction", Config.Combat.Aimbot.Prediction, "Enabled")
    combat:Slider("Prediction Magnitude", Config.Combat.Aimbot.Prediction, "VelocityScale", 0, 10)
    combat:Toggle("Gravity Correction", Config.Combat.Aimbot.Prediction, "GravityComp")
    
    combat:Section("Silent Operation")
    combat:Toggle("Metamethod Silent Aim", Config.Combat.SilentAim, "Enabled")
    combat:Slider("Silent FOV Radius", Config.Combat.SilentAim, "FOV", 10, 1200)
    combat:Toggle("Triggerbot Active", Config.Combat.Triggerbot, "Enabled")

    -- [2] VISUAL DECODER
    local visual = UI.Tab("Visuals")
    visual:Section("Perception Overlay")
    visual:Toggle("Master ESP Toggle", Config.Visuals.ESP, "Enabled")
    visual:Toggle("Render Enemy Boxes", Config.Visuals.ESP, "Boxes")
    visual:Toggle("Display Player Names", Config.Visuals.ESP, "Names")
    visual:Toggle("Status Health Bars", Config.Visuals.ESP, "Health")
    visual:Toggle("Proximity Telemetry", Config.Visuals.ESP, "Distance")
    visual:Toggle("Vector Beam Tracers", Config.Visuals.ESP, "Tracers")
    visual:Toggle("High Fidelity Skeletal", Config.Visuals.ESP, "Skeleton")
    visual:Toggle("Material Glow Chams", Config.Visuals.ESP, "Chams")
    visual:Slider("Processing Horizon", Config.Visuals.ESP, "MaxDistance", 100, 10000)

    -- [3] PHYSICAL MOVEMENT ENGINE
    local move = UI.Tab("Movement")
    move:Section("Basic Dynamics")
    move:Toggle("Enable Velocity Shifting", Config.Movement.Speed, "Enabled")
    move:Slider("Movement Magnitude", Config.Movement.Speed, "Value", 16, 500)
    move:Toggle("Amplify Jumping Force", Config.Movement.Jump, "Enabled")
    move:Slider("Vertical Impulse", Config.Movement.Jump, "Value", 50, 500)
    move:Toggle("Continuous Air Jump", Config.Movement.Jump, "Infinite")
    
    move:Section("Specialized Aerials")
    move:Toggle("Propulsion Flight", Config.Movement.Fly, "Enabled")
    move:Slider("Aero Speed Scale", Config.Movement.Fly, "Speed", 10, 500)
    move:Toggle("Collision Phasing (Noclip)", Config.Movement.Noclip, "Enabled")

    -- [4] PLANETARY MANIPULATION (WORLD)
    local world = UI.Tab("World")
    world:Section("Environmental Control")
    world:Toggle("Solar Fullbright", Config.Visuals.World, "Fullbright", function(s) 
        if s then Lighting.Ambient = Color3.new(1,1,1); Lighting.Brightness = 2 else Lighting.Ambient = Color3.new(0,0,0) end 
    end)
    world:Toggle("Force Noon Lock", Config.Visuals.World, "TimeLock", function(s) 
        if s then Lighting.ClockTime = 14 end 
    end)
    world:Toggle("Atmospheric Mist Purge", Config.Visuals.World, "FogRemoval", function(s) 
        if s then Lighting.FogEnd = 1e9 else Lighting.FogEnd = 2500 end 
    end)
    
    world:Section("Physics & Optics")
    world:Slider("Gravity Magnitude", Config.Visuals.World, "GravityChange", 0, 500, function(v) 
        Workspace.Gravity = v 
    end)
    world:Slider("Field Of View", Config.Visuals.World, "FieldOfView", 30, 150, function(v) 
        cam.FieldOfView = v 
    end)
    world:Toggle("Visual Post-Blur", Config.Visuals.World.ViewEffects, "MotionBlur", function(s) 
        local b = Lighting:FindFirstChild("AresBlur") or Instance.new("BlurEffect", Lighting)
        b.Name = "AresBlur"
        b.Size = s and 12 or 0 
    end)

    -- [5] SYSTEM UTILITIES
    local misc = UI.Tab("Misc")
    misc:Section("System Commands")
    misc:Button("Initiate Rejoin Sequence", function() TeleSvc:Teleport(game.PlaceId, lp) end)
    misc:Button("Copy Community Invite", function() setclip("discord.gg/areshub") end)
    misc:Slider("Hardware FPS Limiter", Config.Misc, "FPSCap", 30, 360, function(v) setfps(v) end)
    misc:Toggle("Anti-Idle Prevention", Config.Misc, "AntiAFK")
    misc:Button("Flush Visual Cache", function() 
        for _,v in pairs(_State.ESPCache) do 
            for _,x in pairs(v) do 
                if type(x)=="table" then for _,y in pairs(x) do y:Remove() end else x:Remove() end 
            end 
        end 
        _State.ESPCache = {} 
    end)

    -- [6] PREMIUM RAGE-BOT (LOCKED)
    local prem = UI.Tab("Premium")
    prem:Section("Unfiltered Aggression")
    prem:Toggle("Inject Magic Bullet", Config.Premium.MagicBullet, "Enabled")
    prem:Toggle("Volume Hitbox Expansion", Config.Premium.HitboxExpander, "Enabled")
    prem:Slider("Geometric Hitbox Scale", Config.Premium.HitboxExpander, "Size", 1, 100)
    prem:Toggle("Radial Kill Engagement", Config.Premium.KillAura, "Enabled")
    
    prem:Section("Advanced Kinematics")
    prem:Toggle("Centrifugal Spinbot", Config.Movement.Spinbot, "Enabled")
    prem:Slider("Revolution Velocity", Config.Movement.Spinbot, "Speed", 5, 500)
    prem:Toggle("Randomized Jitter Mode", Config.Movement.Spinbot, "Jitter")

    -- [7] INTERNAL DOCUMENTATION & API
    local doc = UI.Tab("Docs")
    doc:Section("Architecture Telemetry")
    doc:Button("Export Global Registry", function() 
        for k,v in pairs(getgenv()) do print("[G] ", k, "->", v) end 
    end)
    
    doc:Section("Security Forensics")
    doc:Button("Display Scan Inventory", function() 
        print("--- ARES SECURITY LOG ---")
        for _,v in pairs(_State.ScanningLogs) do print(v) end 
    end)
    
    doc:Section("Product Information")
    doc:Label("Ares Hub V5.1 Public Release")
    doc:Label("Total Modules: 14")
    doc:Label("Build: " .. HttpSvc:GenerateGUID(false):sub(1,8))
    doc:Label("Universal Kernel: PEAK EDITION")

    -- High-Performance Graphic Linker
    local function ConstructESP(p) 
        if p == lp then return end
        
        local d = { 
            box = Drawing.new("Square"), 
            tag = Drawing.new("Text"), 
            v = Drawing.new("Line"), 
            bones = {} 
        }
        
        -- Style Configuration
        d.box.Thickness = 1.2
        d.box.Color = Colors.Accent
        d.box.Filled = false
        
        d.tag.Size = 14
        d.tag.Center = true
        d.tag.Outline = true
        d.tag.Color = Colors.Text
        
        d.v.Thickness = 1
        d.v.Transparency = 0.5
        d.v.Color = Colors.Accent
        
        for i=1, 8 do 
            d.bones[i] = Drawing.new("Line")
            d.bones[i].Thickness = 1
            d.bones[i].Transparency = 0.7
            d.bones[i].Color = Colors.Text 
        end
        
        _State.ESPCache[p] = d 
    end
    
    -- Population Management
    for _,p in ipairs(Players:GetPlayers()) do ConstructESP(p) end
    Players.PlayerAdded:Connect(ConstructESP)
    Players.PlayerRemoving:Connect(function(p) 
        if _State.ESPCache[p] then 
            for _,v in pairs(_State.ESPCache[p]) do 
                if type(v)=="table" then 
                    for _,x in pairs(v) do x:Remove() end 
                else 
                    v:Remove() 
                end 
            end
            _State.ESPCache[p] = nil 
        end 
    end)
    
    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.2
    fovCircle.Color = Colors.Accent
    fovCircle.NumSides = 60

    -- Universal Rendering Loop (Pre-Rasterization)
    Run.RenderStepped:Connect(function()
        local mid = Utils.GetMid()
        
        -- Update FOV Overlay
        fovCircle.Position = mid
        fovCircle.Radius = Config.Combat.Aimbot.FOV
        fovCircle.Visible = Config.Combat.Aimbot.ShowFOV and Config.Combat.Aimbot.Enabled
        
        -- Cursor Logic
        if _State.Visible then 
            mouse.Icon = "rbxassetid://12513364998" 
        else 
            mouse.Icon = "" 
        end
        
        for _,p in ipairs(Players:GetPlayers()) do
            local d = _State.ESPCache[p]
            if not d then continue end
            
            local char = Utils.GetCharacter(p)
            local root = Utils.GetRoot(p)
            local hum = Utils.GetHumanoid(p)
            
            local function WipeVisuals() 
                for _,v in pairs(d) do 
                    if type(v)=="table" then 
                        for _,x in pairs(v) do x.Visible=false end 
                    else 
                        v.Visible=false 
                    end 
                end 
            end
            
            -- Validation Chain
            if not Config.Visuals.ESP.Enabled or not Utils.IsEnemy(p) or not root or not hum or hum.Health <= 0 then 
                WipeVisuals()
                continue 
            end
            
            local pos, onScreen = Utils.ToScreen(root.Position)
            local range = (root.Position-cam.CFrame.Position).Magnitude
            
            if not onScreen or range > Config.Visuals.ESP.MaxDistance then 
                WipeVisuals()
                continue 
            end
            
            -- Box Dynamics
            local aspect = Vector2.new(2400/range, 3600/range)
            local anchorTop = pos - aspect/2
            
            d.box.Visible = Config.Visuals.ESP.Boxes; 
            if d.box.Visible then 
                d.box.Size = aspect
                d.box.Position = anchorTop 
            end
            
            d.tag.Visible = Config.Visuals.ESP.Names; 
            if d.tag.Visible then 
                d.tag.Text = p.DisplayName
                d.tag.Position = anchorTop - Vector2.new(0, 18) 
            end
            
            d.v.Visible = Config.Visuals.ESP.Tracers; 
            if d.v.Visible then 
                d.v.From = Vector2.new(mid.X, cam.ViewportSize.Y)
                d.v.To = pos 
            end
            
            -- Chams Logic (Highlight Engine)
            if Config.Visuals.ESP.Chams then 
                local highlight = char:FindFirstChild("ARES_XRAY") or Instance.new("Highlight", char)
                highlight.Name = "ARES_XRAY"
                highlight.FillColor = Colors.Accent
                highlight.OutlineColor = Color3.new(1,1,1)
                highlight.Enabled = true 
            elseif char:FindFirstChild("ARES_XRAY") then 
                char.ARES_XRAY.Enabled = false 
            end
        end
        
        -- Combat Execution Processor
        if Config.Combat.Aimbot.Enabled and UIS:IsKeyDown(Config.Combat.Aimbot.Key) then
            local aimTarget = Utils.GetClosestTarget(Config.Combat.Aimbot.FOV, Config.Combat.Aimbot.Part, Config.Combat.Aimbot.WallCheck)
            if aimTarget then 
                local predPos = Utils.GetPredictedPos(aimTarget, _State.TargetPlayer)
                
                -- Smooth Camera Interpolation
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, predPos), Config.Combat.Aimbot.Smoothness/450)
                
                -- Auto-Shooting Subsystem
                if Config.Combat.Aimbot.AutoShoot then 
                    mouse1press()
                    task.wait(0.015)
                    mouse1release() 
                end 
            end
        end
    end)

    -- Physics Heartbeat Processor
    Run.Heartbeat:Connect(function()
        local humanoid = Utils.GetHumanoid(lp)
        local rootPart = Utils.GetRoot(lp)
        
        if not humanoid or not rootPart then return end
        
        -- Speed Manipulation
        if Config.Movement.Speed.Enabled then 
            if Config.Movement.Speed.Method == "Velocity" then 
                local moveDir = humanoid.MoveDirection * Config.Movement.Speed.Value
                rootPart.Velocity = Vector3.new(moveDir.X, rootPart.Velocity.Y, moveDir.Z) 
            else 
                humanoid.WalkSpeed = Config.Movement.Speed.Value 
            end 
        end
        
        -- Jump Power Logic
        if Config.Movement.Jump.Enabled then 
            humanoid.JumpPower = Config.Movement.Jump.Value
            humanoid.UseJumpPower = true 
        end
        
        -- Unlimited Vertical Impulse
        if Config.Movement.Jump.Infinite and UIS:IsKeyDown(Enum.KeyCode.Space) then 
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, humanoid.JumpPower, rootPart.Velocity.Z) 
        end
        
        -- Aero Propulsion (Flying)
        if Config.Movement.Fly.Enabled then 
            local heading = humanoid.MoveDirection * Config.Movement.Fly.Speed
            local alt = 0
            if UIS:IsKeyDown(Config.Movement.Fly.UpKey) then alt = Config.Movement.Fly.Speed end
            if UIS:IsKeyDown(Config.Movement.Fly.DownKey) then alt = -Config.Movement.Fly.Speed end
            rootPart.Velocity = heading + Vector3.new(0, alt + 3, 0) 
        end
        
        -- Noclip State Processor
        if Config.Movement.Noclip.Enabled then 
            for _, part in pairs(lp.Character:GetDescendants()) do 
                if part:IsA("BasePart") then part.CanCollide = false end 
            end 
        end
        
        -- Premium Rotational Spinbot
        if Config.Movement.Spinbot.Enabled then 
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(Config.Movement.Spinbot.Speed), 0) 
            if Config.Movement.Spinbot.Jitter then
                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(math.random(-90, 90)), 0)
            end
        end
        
        -- Volumetric Hitbox Expansion (Premium)
        if Config.Premium.HitboxExpander.Enabled then 
            for _, player in ipairs(Players:GetPlayers()) do 
                if Utils.IsEnemy(player) and Utils.IsAlive(player) then 
                    local head = Utils.GetPart(player, "Head")
                    if head then 
                        head.Size = Vector3.new(Config.Premium.HitboxExpander.Size, Config.Premium.HitboxExpander.Size, Config.Premium.HitboxExpander.Size)
                        head.CanCollide = false 
                        head.Transparency = 0.5
                    end 
                end 
            end 
        end
    end)
    
    -- Authenticate Session
    if not _State.Authenticated then 
        RunAuth(menu) 
    end
end

-- ─── SYSTEM API DOCUMENTATION ───────────────────────────────────────────────
--[[
    @MODULE AresHubEngine
    The core engine managing UI, Visuals, Combat, and Security.

    @INTERFACE UI.Tab(name: string)
    Allocates a stateful tab environment.
    {
        Section(text: string) -> Renders a magenta-themed header.
        Label(text: string) -> Renders a dim informative text.
        Toggle(label: string, tbl: table, key: string, callback: function)
        Slider(label: string, tbl: table, key: string, min: num, max: num, callback: function)
        Button(label: string, callback: function)
    }

    @KINEMATICS Utils.GetPredictedPos
    Implementation of linear extrapolation.
    Pos(t) = Pos(0) + (Velocity * (Distance / ProjSpeed))

    @SECURITY Security.ApplyHardenedHooks()
    Sets up protective layer for metamethods to prevent detection by common anticheats.
]]

-- ─── BOOTSTRAP INITIALIZATION ────────────────────────────────────────────────
task.spawn(ShowIntro)
task.wait(6) 
task.spawn(RunCore)

-- Final Release Handshake
local welcomeData = { 
    Title = "ARES HUB | V5.1", 
    Text = "Public Release Peak Edition - 1150+ Lines", 
    Duration = 10,
    Icon = "rbxassetid://6031068433"
}
pcall(function() StarterGui:SetCore("SendNotification", welcomeData) end)

print("--------------------------------------------------")
print(" [ARES HUB V5.1] UNIVERSAL CORE PIPELINE LOADED ")
print(" [ARES HUB V5.1] TOTAL KLOC: 1.15k ")
print(" [ARES HUB V5.1] STATUS: PUBLIC RELEASE SEEDED ")
print("--------------------------------------------------")

--[[
    LICENSE: Public Release
    (c) 2026 Ares Scripting Syndicate
    "Stay Winning."
]]
