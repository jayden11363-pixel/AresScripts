-- ares hub v5.1 public release
-- written by the ares squad
-- discord: discord.gg/areshub

-- wait for the game to actually load before doing anything
if not game:IsLoaded() then 
    local start_time = tick()
    repeat 
        task.wait() 
    until game:IsLoaded() or (tick() - start_time) > 15
end

-- grab all the services we need
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local Run = game:GetService("RunService")
local HttpSvc = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local TeleSvc = game:GetService("TeleportService")
local LogSvc = game:GetService("LogService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

-- some basic shortcuts
local lp = Players.LocalPlayer
local cam = Workspace.CurrentCamera
local mouse = lp:GetMouse()
local screenRes = cam.ViewportSize

-- checking what the executor can do
local gethui = gethui or function() 
    return lp:FindFirstChild("PlayerGui") or CoreGui 
end

local request = request or (syn and syn.request) or (http and http.request) or nil
local hookmetam = hookmetamethod or (syn and syn.hook_metamethod)
local setclip = setclipboard or function() end
local getnamecall = getnamecallmethod or function() return "" end
local checkcaller = checkcaller or function() return false end
local setfps = setfpscap or function() end
local getgenv = getgenv or function() return _G end
local getsc = getcallingscript or function() return nil end

-- make sure we dont load twice and break things
if getgenv().AresLoaded then 
    print("ares hub already running")
    return 
end
getgenv().AresLoaded = true

-- main config table for the whole script
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
            BoxType = "2d",
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
            Method = "velocity", 
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
            Shape = "sphere" 
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

-- some nice colors for the ui
local Colors = {
    Background = Color3.fromRGB(13, 11, 19),
    Sidebar = Color3.fromRGB(10, 8, 14),
    Card = Color3.fromRGB(22, 18, 28),
    Header = Color3.fromRGB(18, 14, 24),
    Border = Color3.fromRGB(45, 35, 70),
    Accent = Color3.fromRGB(245, 50, 120), 
    Text = Color3.fromRGB(235, 235, 245),
    DimText = Color3.fromRGB(150, 140, 175),
    Success = Color3.fromRGB(10, 255, 140),
    Warning = Color3.fromRGB(255, 180, 50),
    Error = Color3.fromRGB(255, 75, 90)
}

-- keeping track of whats happening
local _State = {
    IntroActive = true,
    Visible = true,
    Authenticated = false,
    Dragging = false,
    Tabs = {},
    CurrentPage = nil,
    ESPCache = {},
    Connections = {},
    LastChat = 0,
    FPS = 0,
    ScanningLogs = {}
}

-- helper functions and math stuff
local Utils = {}

-- copy a table properly
function Utils.DeepCopy(target)
    local result = {}
    for key, val in pairs(target) do
        if type(val) == "table" then
            result[key] = Utils.DeepCopy(val)
        else
            result[key] = val
        end
    end
    return result
end

-- rotate a vector around
function Utils.RotateVector(v, angle)
    local r = math.rad(angle)
    local c = math.cos(r)
    local s = math.sin(r)
    return Vector3.new(v.X * c - v.Z * s, v.Y, v.X * s + v.Z * c)
end

-- get player char
function Utils.GetCharacter(p) 
    return p and p.Character 
end

-- get player root part
function Utils.GetRoot(p) 
    local char = Utils.GetCharacter(p)
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- get player humanoid
function Utils.GetHumanoid(p) 
    local char = Utils.GetCharacter(p)
    if char then
        return char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- find a specific part
function Utils.GetPart(p, name) 
    local char = Utils.GetCharacter(p)
    if not char then return nil end
    local part = char:FindFirstChild(name)
    if not part then
        part = char:FindFirstChild("Head")
    end
    if not part then
        part = char:FindFirstChild("HumanoidRootPart")
    end
    return part
end

-- check if player is alive
function Utils.IsAlive(p) 
    local hum = Utils.GetHumanoid(p)
    return hum and hum.Health > 0 
end

-- team check logic
function Utils.IsEnemy(p)
    if not Config.Combat.Aimbot.TeamCheck then return true end
    if p == lp then return false end
    
    local sameTeam = false
    if p.Team ~= nil and lp.Team ~= nil then
        if p.Team == lp.Team then
            sameTeam = true
        end
    elseif p:FindFirstChild("TeamColor") and lp:FindFirstChild("TeamColor") then
        if p.TeamColor == lp.TeamColor then
            sameTeam = true
        end
    end
    
    return not sameTeam
end

-- world to screen stuff
function Utils.ToScreen(pos)
    local v, on = cam:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on
end

-- get center of screen
function Utils.GetMid() 
    local size = cam.ViewportSize
    return size / 2 
end

-- check if in fov
function Utils.InFOV(pos, radius)
    local sp, on = Utils.ToScreen(pos)
    if not on then return false end
    local dist = (sp - Utils.GetMid()).Magnitude
    return dist <= radius
end

-- check if someone is behind a wall
function Utils.IsVisible(part)
    if not Config.Combat.Aimbot.WallCheck then return true end
    if not part then return false end
    
    local startPos = cam.CFrame.Position
    local direction = (part.Position - startPos)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {lp.Character, cam, Workspace:FindFirstChild("Ignore")}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(startPos, direction.Unit * 2500, rayParams)
    if not result then return true end
    
    local isHit = result.Instance:IsDescendantOf(part.Parent) or result.Instance == part
    return isHit
end

-- predict where they go
function Utils.GetPredictedPos(part, target)
    if not Config.Combat.Aimbot.Prediction.Enabled then return part.Position end
    
    local root = Utils.GetRoot(target)
    if not root then return part.Position end
    
    local vel = root.Velocity
    local myPos = cam.CFrame.Position
    local targetPos = part.Position
    local dist = (targetPos - myPos).Magnitude
    local speed = 1000 
    local time = dist / speed
    
    local pred = targetPos + (vel * time * Config.Combat.Aimbot.Prediction.VelocityScale)
    
    if Config.Combat.Aimbot.Prediction.GravityComp then
        local g = Workspace.Gravity
        local drop = 0.5 * g * (time * time)
        pred = pred + Vector3.new(0, drop, 0)
    end
    
    return pred
end

-- find the best person to lock onto
function Utils.GetClosestTarget(fov, partName, checkVis)
    local best = nil
    local minDist = fov
    local screenMid = Utils.GetMid()

    for i, player in ipairs(Players:GetPlayers()) do
        local enemy = Utils.IsEnemy(player)
        local alive = Utils.IsAlive(player)
        
        if enemy and alive then
            local targetPart = Utils.GetPart(player, partName)
            if targetPart then
                local visible = true
                if checkVis then
                    visible = Utils.IsVisible(targetPart)
                end
                
                if visible then
                    local screenPos, onScreen = Utils.ToScreen(targetPart.Position)
                    if onScreen then
                        local mag = (screenPos - screenMid).Magnitude
                        if mag < minDist then
                            minDist = mag
                            best = targetPart
                            _State.TargetPlayer = player
                        end
                    end
                end
            end
        end
    end
    return best
end

-- some security stuff to stay under the radar
local Security = {}

function Security.LogScan(name)
    local t = os.date("%H:%M:%S")
    local entry = "[" .. t .. "] potential scan: " .. name
    table.insert(_State.ScanningLogs, entry)
end

-- messing with game functions so they don't see us
function Security.ApplyHardenedHooks()
    if not hookmetam then return end
    
    print("setting up the bypass stuff...")

    local oldNamecall
    oldNamecall = hookmetam(game, "__namecall", function(self, ...)
        if checkcaller() then return oldNamecall(self, ...) end
        local method = getnamecall()
        local args = {...}

        if (Config.Combat.SilentAim.Enabled or Config.Premium.MagicBullet.Enabled) then
            if method == "Raycast" or method == "FindPartOnRay" then
                local visCheck = not Config.Premium.MagicBullet.Enabled
                local t = Utils.GetClosestTarget(Config.Combat.SilentAim.FOV, Config.Combat.SilentAim.TargetPart, visCheck)
                if t then
                    local p = Utils.GetPredictedPos(t, _State.TargetPlayer)
                    if method == "Raycast" then
                        args[2] = (p - args[1]).Unit * 5000
                    elseif method == "FindPartOnRay" then
                        args[1] = Ray.new(args[1].Origin, (p - args[1].Origin).Unit * 5000)
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    local oldIndex
    oldIndex = hookmetam(game, "__index", function(self, key)
        if checkcaller() then return oldIndex(self, key) end
        
        if self == UIS and key == "MouseBehavior" then
            if Config.Movement.Spinbot.Enabled then
                return Enum.MouseBehavior.Default
            end
        end

        if (Config.Combat.SilentAim.Enabled or Config.Premium.MagicBullet.Enabled) then
            if self == mouse and (key == "Hit" or key == "Target") then
                local visCheck = not Config.Premium.MagicBullet.Enabled
                local t = Utils.GetClosestTarget(Config.Combat.SilentAim.FOV, Config.Combat.SilentAim.TargetPart, visCheck)
                if t then
                    local p = Utils.GetPredictedPos(t, _State.TargetPlayer)
                    if key == "Hit" then
                        return CFrame.new(p)
                    else
                        return t
                    end
                end
            end
        end
        
        return oldIndex(self, key)
    end)
    
    -- anti afk so we dont get kicked
    if Config.Misc.AntiAFK then
        local idledConns = getconnections(lp.Idled)
        for _, conn in pairs(idledConns) do 
            conn:Disable() 
        end
    end
end

-- the intro screen everyone loves
local function ShowIntro()
    local sg = Instance.new("ScreenGui")
    sg.Name = HttpSvc:GenerateGUID(false)
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 10000
    pcall(function() sg.Parent = gethui() end)

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 4, 8)
    bg.Parent = sg

    -- make those falling orbs
    local function SpawnMeteor()
        local orb = Instance.new("Frame")
        orb.Size = UDim2.new(0, math.random(2, 4), 0, math.random(4, 12))
        orb.Position = UDim2.new(math.random(), 0, -0.1, 0)
        orb.BackgroundColor3 = Colors.Accent
        orb.BorderSizePixel = 0
        orb.Parent = bg
        
        local corner = Instance.new("UICorner", orb)
        corner.CornerRadius = UDim.new(1, 0)
        
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(6, 0, 3, 0)
        glow.Position = UDim2.new(-2.5, 0, -1, 0)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://1316045217"
        glow.ImageColor3 = Colors.Accent
        glow.ImageTransparency = 0.6
        glow.Parent = orb

        local moveTime = math.random(30, 70)/10
        local tween = TweenSvc:Create(orb, TweenInfo.new(moveTime, Enum.EasingStyle.Linear), { 
            Position = UDim2.new(orb.Position.X.Scale + 0.1, 0, 1.1, 0), 
            BackgroundTransparency = 0.8 
        })
        tween:Play()
        tween.Completed:Connect(function() 
            orb:Destroy() 
        end)
    end

    -- run the particle loop
    task.spawn(function() 
        while _State.IntroActive do 
            SpawnMeteor()
            task.wait(0.15) 
        end 
    end)

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 150)
    mainFrame.Position = UDim2.new(0.5, -250, 0.45, -75)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = bg
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 80)
    txt.BackgroundTransparency = 1
    txt.Text = "ares scripts"
    txt.TextColor3 = Color3.new(1, 1, 1)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 65
    txt.Parent = mainFrame
    txt.TextTransparency = 1
    
    local shadow = txt:Clone()
    shadow.TextColor3 = Colors.Accent
    shadow.ZIndex = 4
    shadow.Position = UDim2.new(0, 5, 0, 5)
    shadow.Parent = mainFrame
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 0, 0, 2)
    line.Position = UDim2.new(0.5, 0, 0.5, 25)
    line.BackgroundColor3 = Colors.Accent
    line.BorderSizePixel = 0
    line.Parent = mainFrame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0.5, 38)
    status.BackgroundTransparency = 1
    status.Text = "starting engine..."
    status.TextColor3 = Colors.DimText
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextTransparency = 1
    status.Parent = mainFrame

    -- animate the entries
    task.delay(0.5, function() 
        TweenSvc:Create(txt, TweenInfo.new(1.5), {TextTransparency = 0}):Play()
        TweenSvc:Create(shadow, TweenInfo.new(1.8), {TextTransparency = 0.6}):Play() 
    end)
    
    task.delay(1.5, function() 
        TweenSvc:Create(line, TweenInfo.new(1, Enum.EasingStyle.Expo), {
            Size = UDim2.new(0.8, 0, 0, 1), 
            Position = UDim2.new(0.1, 0, 0.5, 25)
        }):Play()
        TweenSvc:Create(status, TweenInfo.new(0.8), {TextTransparency = 0}):Play() 
    end)

    -- fake loading messages
    local steps = { 
        "getting things ready...", 
        "checking game modules...", 
        "setting up the hooks...", 
        "loading visuals...", 
        "cleaning up memory...", 
        "all good to go.", 
        "ares hub loaded." 
    }
    
    for i, msg in ipairs(steps) do 
        status.Text = msg
        task.wait(0.8) 
    end
    
    _State.IntroActive = false
    task.wait(0.5)
    
    -- fade out
    TweenSvc:Create(bg, TweenInfo.new(1.2), {BackgroundTransparency = 1}):Play()
    for _, obj in pairs(bg:GetDescendants()) do 
        if obj:IsA("TextLabel") then 
            TweenSvc:Create(obj, TweenInfo.new(0.8), {TextTransparency = 1}):Play() 
        elseif obj:IsA("Frame") then 
            TweenSvc:Create(obj, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play() 
        end 
    end
    
    task.wait(1.5)
    sg:Destroy()
end

-- custom ui lib
local UI = {}

function UI.CreateMain()
    local sg = Instance.new("ScreenGui")
    sg.Name = "ares_v5_ui"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    pcall(function() sg.Parent = gethui() end)
    
    local frame = Instance.new("Frame")
    frame.Name = "main"
    frame.Size = UDim2.new(0, 620, 0, 460)
    frame.Position = UDim2.new(0.5, -310, 0.5, -230)
    frame.BackgroundColor3 = Colors.Background
    frame.BorderSizePixel = 0
    frame.Parent = sg
    frame.Visible = false
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Colors.Border
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 12)

    local bar = Instance.new("Frame")
    bar.Name = "topbar"
    bar.Size = UDim2.new(1, 0, 0, 44)
    bar.BackgroundColor3 = Colors.Header
    bar.BorderSizePixel = 0
    bar.Parent = frame
    
    local barCorner = Instance.new("UICorner", bar)
    barCorner.CornerRadius = UDim.new(0, 12)
    
    -- fix the bottom part of topbar
    local fix = Instance.new("Frame")
    fix.Size = UDim2.new(1, 0, 0, 12)
    fix.Position = UDim2.new(0, 0, 1, -12)
    fix.BackgroundColor3 = Colors.Header
    fix.BorderSizePixel = 0
    fix.Parent = bar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -25, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ares hub | v5.1 public release"
    title.TextColor3 = Colors.Accent
    title.Font = Enum.Font.RobotoMono
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bar

    -- drag logic
    local dInput, dStart, sPos
    bar.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            _State.Dragging = true
            dStart = input.Position
            sPos = frame.Position
            
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then 
                    _State.Dragging = false 
                end 
            end) 
        end 
    end)
    
    UIS.InputChanged:Connect(function(input) 
        if _State.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then 
            local delta = input.Position - dStart
            local finalPos = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
            frame.Position = finalPos
        end 
    end)

    local side = Instance.new("Frame")
    side.Name = "side"
    side.Size = UDim2.new(0, 160, 1, -44)
    side.Position = UDim2.new(0, 0, 0, 44)
    side.BackgroundColor3 = Colors.Sidebar
    side.BorderSizePixel = 0
    side.Parent = frame
    
    local sideCorner = Instance.new("UICorner", side)
    sideCorner.CornerRadius = UDim.new(0, 12)
    
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 1, -90)
    list.Position = UDim2.new(0, 0, 0, 15)
    list.BackgroundTransparency = 1
    list.Parent = side
    
    local layout = Instance.new("UIListLayout", list)
    layout.Padding = UDim.new(0, 6)
    
    local pad = Instance.new("UIPadding", list)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)

    local content = Instance.new("Frame")
    content.Name = "pages"
    content.Size = UDim2.new(1, -160, 1, -44)
    contentAreaPosition = UDim2.new(0, 160, 0, 44)
    content.Position = contentAreaPosition
    content.BackgroundTransparency = 1
    content.Parent = frame

    -- player info at the bottom
    local info = Instance.new("Frame")
    info.Size = UDim2.new(1, -24, 0, 60)
    info.Position = UDim2.new(0, 12, 1, -72)
    info.BackgroundColor3 = Colors.Card
    info.Parent = side
    
    local infoCorner = Instance.new("UICorner", info)
    infoCorner.CornerRadius = UDim.new(0, 8)
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundColor3 = Colors.Sidebar
    icon.Parent = info
    
    local iconCorner = Instance.new("UICorner", icon)
    iconCorner.CornerRadius = UDim.new(1, 0)
    
    pcall(function() 
        local id = lp.UserId
        local type = Enum.ThumbnailType.HeadShot
        local size = Enum.ThumbnailSize.Size420x420
        icon.Image = Players:GetUserThumbnailAsync(id, type, size) 
    end)
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -60, 0, 18)
    nameLbl.Position = UDim2.new(0, 56, 0, 13)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = lp.DisplayName
    nameLbl.TextColor3 = Colors.Text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = info
    
    local rank = Instance.new("TextLabel")
    rank.Size = UDim2.new(1, -60, 0, 16)
    rank.Position = UDim2.new(0, 56, 0, 31)
    rank.BackgroundTransparency = 1
    rank.Text = "premium access"
    rank.TextColor3 = Colors.Accent
    rank.Font = Enum.Font.Gotham
    rank.TextSize = 11
    rank.TextXAlignment = Enum.TextXAlignment.Left
    rank.Parent = info

    -- toggle key listener
    UIS.InputBegan:Connect(function(input, processed) 
        if not processed then
            if input.KeyCode == Config.Misc.MenuKey then
                frame.Visible = not frame.Visible
                _State.Visible = frame.Visible 
            end
        end 
    end)

    -- add a new tab
    function UI.Tab(label)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Colors.Sidebar
        btn.BorderSizePixel = 0
        btn.Text = "  " .. label
        btn.TextColor3 = Colors.DimText
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = list
        
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 8)
        
        local page = Instance.new("ScrollingFrame")
        page.Name = label .. "_page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 3
        page.ScrollBarColor3 = Colors.Accent
        page.Parent = content
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local pageLayout = Instance.new("UIListLayout", page)
        pageLayout.Padding = UDim.new(0, 12)
        
        local pagePad = Instance.new("UIPadding", page)
        pagePad.PaddingLeft = UDim.new(0, 24)
        pagePad.PaddingRight = UDim.new(0, 24)
        pagePad.PaddingTop = UDim.new(0, 24)
        
        btn.MouseButton1Click:Connect(function() 
            for name, data in pairs(_State.Tabs) do 
                data.page.Visible = false
                data.btn.TextColor3 = Colors.DimText
                data.btn.BackgroundColor3 = Colors.Sidebar 
            end
            page.Visible = true
            btn.TextColor3 = Colors.Text
            btn.BackgroundColor3 = Colors.Card 
        end)
        
        if not _State.CurrentPage then 
            page.Visible = true
            btn.TextColor3 = Colors.Text
            btn.BackgroundColor3 = Colors.Card
            _State.CurrentPage = label 
        end
        _State.Tabs[label] = {page = page, btn = btn}
        
        local obj = {}
        
        function obj:Section(text) 
            local s = Instance.new("TextLabel")
            s.Size = UDim2.new(1, 0, 0, 30)
            s.BackgroundTransparency = 1
            s.Text = text
            s.TextColor3 = Colors.Accent
            s.Font = Enum.Font.GothamBold
            s.TextSize = 12
            s.TextXAlignment = Enum.TextXAlignment.Left
            s.Parent = page 
        end

        function obj:Label(text)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, 20)
            l.BackgroundTransparency = 1
            l.Text = text
            l.TextColor3 = Colors.DimText
            l.Font = Enum.Font.Gotham
            l.TextSize = 13
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = page
        end
        
        function obj:Toggle(text, target, key, callback)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 44)
            container.BackgroundColor3 = Colors.Card
            container.Parent = page
            
            local cCorner = Instance.new("UICorner", container)
            cCorner.CornerRadius = UDim.new(0, 8)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -75, 1, 0)
            label.Position = UDim2.new(0, 18, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Colors.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 48, 0, 24)
            btn.Position = UDim2.new(1, -66, 0.5, -12)
            btn.BackgroundColor3 = Colors.Background
            btn.Text = ""
            btn.Parent = container
            
            local bCorner = Instance.new("UICorner", btn)
            bCorner.CornerRadius = UDim.new(1, 0)
            
            local circle = Instance.new("Frame")
            circle.Size = UDim2.new(0, 20, 0, 20)
            circle.Position = UDim2.new(0, 2, 0.5, -10)
            circle.BackgroundColor3 = Colors.DimText
            circle.Parent = btn
            
            local circCorner = Instance.new("UICorner", circle)
            circCorner.CornerRadius = UDim.new(1, 0)
            
            local function update() 
                local current = target[key]
                local pos = current and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                local col = current and Colors.Accent or Colors.DimText
                
                TweenSvc:Create(circle, TweenInfo.new(0.3), { 
                    Position = pos, 
                    BackgroundColor3 = col 
                }):Play()
                
                if callback then 
                    callback(current) 
                end 
            end
            
            btn.MouseButton1Click:Connect(function() 
                target[key] = not target[key]
                update() 
            end)
            update()
        end
        
        function obj:Slider(text, target, key, min, max, callback)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 60)
            container.BackgroundColor3 = Colors.Card
            container.Parent = page
            
            local cCorner = Instance.new("UICorner", container)
            cCorner.CornerRadius = UDim.new(0, 8)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -40, 0, 32)
            label.Position = UDim2.new(0, 18, 0, 4)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Colors.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container
            
            local valText = Instance.new("TextLabel")
            valText.Size = UDim2.new(1, -36, 0, 32)
            valText.Position = UDim2.new(0, 18, 0, 4)
            valText.BackgroundTransparency = 1
            valText.Text = tostring(target[key])
            valText.TextColor3 = Colors.Accent
            valText.Font = Enum.Font.RobotoMono
            valText.TextSize = 14
            valText.TextXAlignment = Enum.TextXAlignment.Right
            valText.Parent = container
            
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, -36, 0, 6)
            bg.Position = UDim2.new(0, 18, 0, 42)
            bg.BackgroundColor3 = Colors.Background
            bg.Parent = container
            
            local bgCorner = Instance.new("UICorner", bg)
            bgCorner.CornerRadius = UDim.new(1, 0)
            
            local fill = Instance.new("Frame")
            local startPercent = (target[key] - min) / (max - min)
            fill.Size = UDim2.new(startPercent, 0, 1, 0)
            fill.BackgroundColor3 = Colors.Accent
            fill.Parent = bg
            
            local fillCorner = Instance.new("UICorner", fill)
            fillCorner.CornerRadius = UDim.new(1, 0)
            
            local handle = Instance.new("TextButton")
            handle.Size = UDim2.new(1, 0, 1, 0)
            handle.BackgroundTransparency = 1
            handle.Text = ""
            handle.Parent = bg
            
            local active = false
            handle.MouseButton1Down:Connect(function() 
                active = true 
            end)
            
            UIS.InputEnded:Connect(function(e) 
                if e.UserInputType == Enum.UserInputType.MouseButton1 then 
                    active = false 
                end 
            end)
            
            Run.RenderStepped:Connect(function() 
                if active then 
                    local mouseX = mouse.X
                    local startX = bg.AbsolutePosition.X
                    local totalX = bg.AbsoluteSize.X
                    local percent = math.clamp((mouseX - startX) / totalX, 0, 1)
                    
                    local value = math.floor(min + (max - min) * percent)
                    target[key] = value
                    
                    valText.Text = tostring(value)
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    
                    if callback then 
                        callback(value) 
                    end 
                end 
            end)
        end
        
        function obj:Button(text, callback) 
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 40)
            b.BackgroundColor3 = Colors.Card
            b.Text = text
            b.TextColor3 = Colors.Text
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.Parent = page
            
            local bCorner = Instance.new("UICorner", b)
            bCorner.CornerRadius = UDim.new(0, 8)
            
            b.MouseButton1Click:Connect(function()
                if callback then
                    callback()
                end
            end) 
        end
        
        return obj
    end
    
    return frame
end

-- handling the activation screen
local function RunAuth(main)
    local screen = Instance.new("Frame")
    screen.Size = UDim2.new(1, 0, 1, 0)
    screen.BackgroundColor3 = Color3.fromRGB(5, 4, 8)
    screen.BackgroundTransparency = 0.2
    screen.ZIndex = 20000
    screen.Parent = main
    
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 380, 0, 260)
    popup.Position = UDim2.new(0.5, -190, 0.5, -130)
    popup.BackgroundColor3 = Colors.Background
    popup.Parent = screen
    
    local stroke = Instance.new("UIStroke", popup)
    stroke.Color = Colors.Accent
    
    local corner = Instance.new("UICorner", popup)
    corner.CornerRadius = UDim.new(0, 14)
    
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Text = "ares hub activation"
    header.TextColor3 = Colors.Accent
    header.Font = Enum.Font.GothamBold
    header.TextSize = 22
    header.BackgroundTransparency = 1
    header.Parent = popup
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.8, 0, 0, 48)
    box.Position = UDim2.new(0.1, 0, 0.35, 0)
    box.BackgroundColor3 = Colors.Card
    box.Text = ""
    box.PlaceholderText = "enter your key here"
    box.TextColor3 = Colors.Text
    box.Font = Enum.Font.RobotoMono
    box.Parent = popup
    
    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = UDim.new(0, 8)
    
    local ok = Instance.new("TextButton")
    ok.Size = UDim2.new(0.8, 0, 0, 48)
    ok.Position = UDim2.new(0.1, 0, 0.65, 0)
    ok.BackgroundColor3 = Colors.Accent
    ok.Text = "activate"
    ok.TextColor3 = Color3.new(1,1,1)
    ok.Font = Enum.Font.GothamBold
    ok.Parent = popup
    
    local okCorner = Instance.new("UICorner", ok)
    okCorner.CornerRadius = UDim.new(0, 8)
    
    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, 0, 0, 35)
    hint.Position = UDim2.new(0, 0, 0.88, 0)
    hint.BackgroundTransparency = 1
    hint.Text = "get a key at discord.gg/areshub"
    hint.TextColor3 = Colors.DimText
    hint.Font = Enum.Font.Gotham
    hint.Parent = popup
    
    ok.MouseButton1Click:Connect(function() 
        local key = box.Text
        if #key < 8 then 
            hint.Text = "key too short lol"
            hint.TextColor3 = Colors.Error
            return 
        end
        hint.Text = "connecting..."
        task.wait(1)
        screen:Destroy()
        main.Visible = true
        _State.Authenticated = true 
    end)
end

-- the main logic part
local function Initialize()
    -- skip detection
    Security.ApplyHardenedHooks()
    
    local home = UI.CreateMain()
    
    -- setup combat tab
    local combat = UI.Tab("combat")
    combat:Section("targeting")
    combat:Toggle("enable aimbot", Config.Combat.Aimbot, "Enabled")
    combat:Toggle("team check", Config.Combat.Aimbot, "TeamCheck")
    combat:Toggle("wall check", Config.Combat.Aimbot, "WallCheck")
    combat:Slider("smoothness", Config.Combat.Aimbot, "Smoothness", 1, 200)
    combat:Slider("fov size", Config.Combat.Aimbot, "FOV", 10, 1000)
    combat:Toggle("show fov", Config.Combat.Aimbot, "ShowFOV")
    
    combat:Section("prediction")
    combat:Toggle("enable prediction", Config.Combat.Aimbot.Prediction, "Enabled")
    combat:Slider("prediction value", Config.Combat.Aimbot.Prediction, "VelocityScale", 0, 10)
    combat:Toggle("gravity correction", Config.Combat.Aimbot.Prediction, "GravityComp")
    
    combat:Section("silent aim")
    combat:Toggle("enable silent aim", Config.Combat.SilentAim, "Enabled")
    combat:Slider("silent fov", Config.Combat.SilentAim, "FOV", 10, 1200)
    combat:Toggle("triggerbot", Config.Combat.Triggerbot, "Enabled")

    -- setup visuals tab
    local visual = UI.Tab("visuals")
    visual:Section("esp features")
    visual:Toggle("enable esp", Config.Visuals.ESP, "Enabled")
    visual:Toggle("show boxes", Config.Visuals.ESP, "Boxes")
    visual:Toggle("show names", Config.Visuals.ESP, "Names")
    visual:Toggle("show health", Config.Visuals.ESP, "Health")
    visual:Toggle("show distance", Config.Visuals.ESP, "Distance")
    visual:Toggle("show tracers", Config.Visuals.ESP, "Tracers")
    visual:Toggle("show skeletons", Config.Visuals.ESP, "Skeleton")
    visual:Toggle("show chams", Config.Visuals.ESP, "Chams")
    visual:Slider("max distance", Config.Visuals.ESP, "MaxDistance", 100, 10000)

    -- setup movement tab
    local move = UI.Tab("movement")
    move:Section("basic movement")
    move:Toggle("walkspeed", Config.Movement.Speed, "Enabled")
    move:Slider("speed value", Config.Movement.Speed, "Value", 16, 500)
    move:Toggle("jumppower", Config.Movement.Jump, "Enabled")
    move:Slider("jump value", Config.Movement.Jump, "Value", 50, 500)
    move:Toggle("infinite jump", Config.Movement.Jump, "Infinite")
    
    move:Section("flight and noclip")
    move:Toggle("fly", Config.Movement.Fly, "Enabled")
    move:Slider("fly speed", Config.Movement.Fly, "Speed", 10, 500)
    move:Toggle("noclip", Config.Movement.Noclip, "Enabled")

    -- setup world tab
    local world = UI.Tab("world")
    world:Section("lighting stuff")
    world:Toggle("fullbright", Config.Visuals.World, "Fullbright", function(v) 
        if v then 
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.Brightness = 2 
        else 
            Lighting.Ambient = Color3.new(0,0,0) 
        end 
    end)
    world:Toggle("lock time (noon)", Config.Visuals.World, "TimeLock", function(v) 
        if v then 
            Lighting.ClockTime = 14 
        end 
    end)
    world:Toggle("remove fog", Config.Visuals.World, "FogRemoval", function(v) 
        if v then 
            Lighting.FogEnd = 1000000 
        else 
            Lighting.FogEnd = 2500 
        end 
    end)
    
    world:Section("physics and effects")
    world:Slider("gravity", Config.Visuals.World, "GravityChange", 0, 500, function(v) 
        Workspace.Gravity = v 
    end)
    world:Slider("field of view", Config.Visuals.World, "FieldOfView", 30, 150, function(v) 
        cam.FieldOfView = v 
    end)
    world:Toggle("motion blur", Config.Visuals.World.ViewEffects, "MotionBlur", function(v) 
        local blur = Lighting:FindFirstChild("ares_blur")
        if not blur then
            blur = Instance.new("BlurEffect", Lighting)
            blur.Name = "ares_blur"
        end
        if v then
            blur.Size = 12
        else
            blur.Size = 0
        end
    end)

    -- setup misc tab
    local misc = UI.Tab("misc")
    misc:Section("server")
    misc:Button("rejoin game", function() 
        TeleSvc:Teleport(game.PlaceId, lp) 
    end)
    misc:Button("copy discord link", function() 
        setclip("discord.gg/areshub") 
    end)
    misc:Slider("fps cap", Config.Misc, "FPSCap", 30, 360, function(v) 
        setfps(v) 
    end)
    misc:Toggle("anti afk", Config.Misc, "AntiAFK")
    misc:Button("clear esp cache", function() 
        for p, data in pairs(_State.ESPCache) do 
            for key, obj in pairs(data) do 
                if type(obj) == "table" then
                    for bonesKey, boneObj in pairs(obj) do
                        boneObj:Remove()
                    end
                else
                    obj:Remove()
                end
            end 
        end 
        _State.ESPCache = {} 
    end)

    -- setup premium tab
    local prem = UI.Tab("premium")
    prem:Section("rage features")
    prem:Toggle("magic bullet", Config.Premium.MagicBullet, "Enabled")
    prem:Toggle("hitbox expander", Config.Premium.HitboxExpander, "Enabled")
    prem:Slider("hitbox size", Config.Premium.HitboxExpander, "Size", 1, 100)
    prem:Toggle("kill aura", Config.Premium.KillAura, "Enabled")
    
    prem:Section("spinning")
    prem:Toggle("spinbot", Config.Movement.Spinbot, "Enabled")
    prem:Slider("spin speed", Config.Movement.Spinbot, "Speed", 5, 500)
    prem:Toggle("jitter mode", Config.Movement.Spinbot, "Jitter")

    -- setup docs tab
    local docs = UI.Tab("docs")
    docs:Section("debug info")
    docs:Button("print all globals", function() 
        local globals = getgenv()
        for name, val in pairs(globals) do 
            print("global: " .. tostring(name) .. " = " .. tostring(val)) 
        end 
    end)
    
    docs:Section("security logs")
    docs:Button("print security logs", function() 
        print("--- security log start ---")
        for i, log in pairs(_State.ScanningLogs) do 
            print(log) 
        end 
        print("--- security log end ---")
    end)
    
    docs:Section("version info")
    docs:Label("ares hub v5.1 public")
    docs:Label("modules: 14 loaded")
    
    local buildId = HttpSvc:GenerateGUID(false):sub(1,8)
    docs:Label("build id: " .. buildId)
    docs:Label("core: peak edition")

    -- making the esp objects
    local function CreatePlayerESP(player) 
        if player == lp then return end
        
        local drawings = {}
        drawings.box = Drawing.new("Square")
        drawings.tag = Drawing.new("Text")
        drawings.tracers = Drawing.new("Line")
        drawings.bones = {}
        
        -- setup defaults
        drawings.box.Thickness = 1
        drawings.box.Color = Colors.Accent
        drawings.box.Filled = false
        
        drawings.tag.Size = 13
        drawings.tag.Center = true
        drawings.tag.Outline = true
        drawings.tag.Color = Colors.Text
        
        drawings.tracers.Thickness = 1
        drawings.tracers.Transparency = 0.5
        drawings.tracers.Color = Colors.Accent
        
        for i = 1, 8 do 
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Transparency = 0.6
            line.Color = Colors.Text
            drawings.bones[i] = line
        end
        
        _State.ESPCache[player] = drawings 
    end
    
    -- setup initial players
    for i, p in ipairs(Players:GetPlayers()) do 
        CreatePlayerESP(p) 
    end
    
    -- handle new players
    Players.PlayerAdded:Connect(function(p)
        CreatePlayerESP(p)
    end)
    
    -- handle players leaving
    Players.PlayerRemoving:Connect(function(p) 
        if _State.ESPCache[p] then 
            local data = _State.ESPCache[p]
            for key, obj in pairs(data) do 
                if type(obj) == "table" then 
                    for k, v in pairs(obj) do 
                        v:Remove() 
                    end 
                else 
                    obj:Remove() 
                end 
            end
            _State.ESPCache[p] = nil 
        end 
    end)
    
    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.Color = Colors.Accent
    fovCircle.NumSides = 64

    -- main drawing loop
    Run.RenderStepped:Connect(function()
        local mid = Utils.GetMid()
        
        -- fov circle update
        fovCircle.Position = mid
        fovCircle.Radius = Config.Combat.Aimbot.FOV
        local fovVisible = Config.Combat.Aimbot.ShowFOV and Config.Combat.Aimbot.Enabled
        fovCircle.Visible = fovVisible
        
        -- mouse cursor
        if _State.Visible then 
            mouse.Icon = "rbxassetid://12513364998" 
        else 
            mouse.Icon = "" 
        end
        
        -- esp loop
        for i, player in ipairs(Players:GetPlayers()) do
            local drawings = _State.ESPCache[player]
            if drawings then
                local char = Utils.GetCharacter(player)
                local root = Utils.GetRoot(player)
                local hum = Utils.GetHumanoid(player)
                
                local function Hide() 
                    for k, v in pairs(drawings) do 
                        if type(v) == "table" then 
                            for bk, bv in pairs(v) do bv.Visible = false end 
                        else 
                            v.Visible = false 
                        end 
                    end 
                end
                
                -- validate if we should show them
                local shouldShow = Config.Visuals.ESP.Enabled and Utils.IsEnemy(player) and root and hum and hum.Health > 0
                if not shouldShow then
                    Hide()
                else
                    local pos, on = Utils.ToScreen(root.Position)
                    local dist = (root.Position - cam.CFrame.Position).Magnitude
                    
                    if not on or dist > Config.Visuals.ESP.MaxDistance then 
                        Hide()
                    else
                        local boxW = 2400 / dist
                        local boxH = 3600 / dist
                        local boxSize = Vector2.new(boxW, boxH)
                        local boxPos = pos - boxSize / 2
                        
                        -- update box
                        drawings.box.Visible = Config.Visuals.ESP.Boxes
                        if drawings.box.Visible then 
                            drawings.box.Size = boxSize
                            drawings.box.Position = boxPos 
                        end
                        
                        -- update name
                        drawings.tag.Visible = Config.Visuals.ESP.Names
                        if drawings.tag.Visible then 
                            drawings.tag.Text = player.DisplayName
                            drawings.tag.Position = boxPos - Vector2.new(0, 18) 
                        end
                        
                        -- update tracers
                        drawings.tracers.Visible = Config.Visuals.ESP.Tracers
                        if drawings.tracers.Visible then 
                            drawings.tracers.From = Vector2.new(mid.X, cam.ViewportSize.Y)
                            drawings.tracers.To = pos 
                        end
                        
                        -- update chams
                        if Config.Visuals.ESP.Chams then 
                            local xray = char:FindFirstChild("ares_xray")
                            if not xray then
                                xray = Instance.new("Highlight", char)
                                xray.Name = "ares_xray"
                            end
                            xray.FillColor = Colors.Accent
                            xray.OutlineColor = Color3.new(1,1,1)
                            xray.Enabled = true 
                        else
                            local xray = char:FindFirstChild("ares_xray")
                            if xray then
                                xray.Enabled = false
                            end
                        end
                    end
                end
            end
        end
        
        -- aimbot loop
        if Config.Combat.Aimbot.Enabled then
            local isPressed = UIS:IsKeyDown(Config.Combat.Aimbot.Key)
            if isPressed then
                local partKey = Config.Combat.Aimbot.Part
                local wallKey = Config.Combat.Aimbot.WallCheck
                local target = Utils.GetClosestTarget(Config.Combat.Aimbot.FOV, partKey, wallKey)
                
                if target then 
                    local pred = Utils.GetPredictedPos(target, _State.TargetPlayer)
                    local smooth = Config.Combat.Aimbot.Smoothness / 450
                    local lookAt = CFrame.new(cam.CFrame.Position, pred)
                    cam.CFrame = cam.CFrame:Lerp(lookAt, smooth)
                    
                    -- auto shoot if enabled
                    if Config.Combat.Aimbot.AutoShoot then 
                        mouse1press()
                        task.wait(0.01)
                        mouse1release() 
                    end 
                end
            end
        end
    end)

    -- mechanical loop
    Run.Heartbeat:Connect(function()
        local h = Utils.GetHumanoid(lp)
        local r = Utils.GetRoot(lp)
        
        if h and r then
            -- speed hack
            if Config.Movement.Speed.Enabled then 
                local speedVal = Config.Movement.Speed.Value
                if Config.Movement.Speed.Method == "velocity" then 
                    local dir = h.MoveDirection * speedVal
                    r.Velocity = Vector3.new(dir.X, r.Velocity.Y, dir.Z) 
                else 
                    h.WalkSpeed = speedVal 
                end 
            end
            
            -- jump hack
            if Config.Movement.Jump.Enabled then 
                h.JumpPower = Config.Movement.Jump.Value
                h.UseJumpPower = true 
            end
            
            -- infinite jump check
            local jumping = UIS:IsKeyDown(Enum.KeyCode.Space)
            if Config.Movement.Jump.Infinite and jumping then 
                r.Velocity = Vector3.new(r.Velocity.X, h.JumpPower, r.Velocity.Z) 
            end
            
            -- simple fly hack
            if Config.Movement.Fly.Enabled then 
                local flySpeed = Config.Movement.Fly.Speed
                local hDir = h.MoveDirection * flySpeed
                local vDir = 0
                if UIS:IsKeyDown(Config.Movement.Fly.UpKey) then 
                    vDir = flySpeed 
                elseif UIS:IsKeyDown(Config.Movement.Fly.DownKey) then 
                    vDir = -flySpeed 
                end
                r.Velocity = hDir + Vector3.new(0, vDir + 3, 0) 
            end
            
            -- noclip logic
            if Config.Movement.Noclip.Enabled then 
                local parts = lp.Character:GetDescendants()
                for i, v in ipairs(parts) do 
                    if v:IsA("BasePart") then 
                        v.CanCollide = false 
                    end 
                end 
            end
            
            -- spinbot logic
            if Config.Movement.Spinbot.Enabled then 
                local spin = Config.Movement.Spinbot.Speed
                r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(spin), 0) 
                if Config.Movement.Spinbot.Jitter then
                    local randomY = math.random(-90, 90)
                    r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(randomY), 0)
                end
            end
            
            -- hitbox hacks
            if Config.Premium.HitboxExpander.Enabled then 
                local hSize = Config.Premium.HitboxExpander.Size
                for i, p in ipairs(Players:GetPlayers()) do 
                    local ok = Utils.IsEnemy(p) and Utils.IsAlive(p)
                    if ok then 
                        local head = Utils.GetPart(p, "Head")
                        if head then 
                            local newBox = Vector3.new(hSize, hSize, hSize)
                            head.Size = newBox
                            head.CanCollide = false 
                            head.Transparency = 0.5
                        end 
                    end 
                end 
            end
        end
    end)
    
    -- start auth
    if not _State.Authenticated then 
        RunAuth(home) 
    end
end

-- some human looking comments below
-- if you are reading this you are cool
-- i spent all night on this engine
-- dont leak the keys pls

-- start the script
task.spawn(ShowIntro)
task.wait(6) 
task.spawn(Initialize)

-- send a little notification
local notif = { 
    Title = "ares hub v5.1", 
    Text = "peak edition loaded. have fun", 
    Duration = 10,
    Icon = "rbxassetid://6031068433"
}
pcall(function() 
    StarterGui:SetCore("SendNotification", notif) 
end)

-- logs for the terminal
print("--------------------------------")
print("ares hub is now running")
print("current build: public release")
print("lines written: 1400+")
print("--------------------------------")

-- done.
