-- ╔══════════════════════════════════════════════════════╗
-- ║         ARES HUB v4 · RIVALS EDITION                ║
-- ║  aimbot · silent · esp · triggerbot · unlock · spoof ║
-- ║  xeno · wave · volt · synapse · krnl · fluxus        ║
-- ╚══════════════════════════════════════════════════════╝

local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local Run      = game:GetService("RunService")

local lp  = Players.LocalPlayer
local cam = workspace.CurrentCamera

if not task then task = { wait = wait, spawn = spawn } end

-- ─── STATE ────────────────────────────────────────────────────────────────────
local S = {
    AimbotOn  = false, AutoLock  = true,
    AimbotKey = Enum.KeyCode.E, AimbotPart = "Head",
    Smooth    = 0.12, FOV = 150, AimTeam = false,
    AimVis    = true, ShowFOV  = true,

    SilentOn  = false, SilentFOV = 200, SilentTeam = false,

    TrigOn    = false, TrigDelay = 80,  TrigTeam   = false,

    ESPOn     = true,  Boxes  = true, Names  = true,
    Dist      = true,  Health = true, ESPTeam = false,
    ESPRange  = 1000,  Tracers = false,

    SpeedOn   = false, SpeedVal = 80,
    FlyOn     = false, NoclipOn = false, InfJump = false,

    UnlockAll  = false,
    SpooferOn  = false,
    AntiReport = false,
}

-- UTILS
local function char(p)   return p and p.Character end
local function root(p)   local c=char(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p)    local c=char(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function part(p,n) local c=char(p); return c and c:FindFirstChild(n) end
local function alive(p)  local h=hum(p); return h and h.Health>0 end

local function enemy(p,tc)
    if p==lp then return false end
    if tc and p.Team and p.Team==lp.Team then return false end
    return true
end

local function toScreen(pos)
    local v,on = cam:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y), on
end

local function mid() return Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2) end

local function visible(pt)
    local o  = cam.CFrame.Position
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { lp.Character }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(o, (pt.Position-o).Unit*2000, rp)
    if not res then return true end
    return res.Instance==pt or res.Instance:IsDescendantOf(pt.Parent)
end

local function bbox(c)
    local r = c:FindFirstChild("HumanoidRootPart"); if not r then return false end
    local p = r.Position
    local pts = {
        Vector3.new(p.X-1.5,p.Y-3,  p.Z), Vector3.new(p.X+1.5,p.Y-3,  p.Z),
        Vector3.new(p.X-1.5,p.Y+2.6,p.Z), Vector3.new(p.X+1.5,p.Y+2.6,p.Z),
    }
    local mnX,mnY,mxX,mxY = math.huge,math.huge,-math.huge,-math.huge
    local vis = false
    for _,pt in ipairs(pts) do
        local sp,on = toScreen(pt)
        if on then vis=true end
        if sp.X<mnX then mnX=sp.X end; if sp.Y<mnY then mnY=sp.Y end
        if sp.X>mxX then mxX=sp.X end; if sp.Y>mxY then mxY=sp.Y end
    end
    return vis,mnX,mnY,mxX-mnX,mxY-mnY
end

local function closest(fov,pname,vischeck,tc)
    local best,bestd = nil,fov; local m = mid()
    for _,p in ipairs(Players:GetPlayers()) do
        if not enemy(p,tc) then continue end
        if not alive(p) then continue end
        local pt = part(p,pname); if not pt then continue end
        if vischeck and not visible(pt) then continue end
        local sp,on = toScreen(pt.Position); if not on then continue end
        local d = (sp-m).Magnitude
        if d<bestd then bestd=d; best=pt end
    end
    return best
end

-- ─── DRAWING ──────────────────────────────────────────────────────────────────
local DOK = type(Drawing)=="table" and Drawing.new~=nil
if not DOK then
    local mt={}
    mt.__index    = function() return function() end end
    mt.__newindex = function() end
    Drawing = { new = function() return setmetatable({Visible=false},mt) end }
end

local cache = {}
local function newESP(p)
    local o = {}
    o.glow   = Drawing.new("Square"); o.glow.Filled=false;  o.glow.Thickness=3;   o.glow.Transparency=0.18
    o.box    = Drawing.new("Square"); o.box.Filled=false;   o.box.Thickness=1.2;  o.box.Transparency=1
    o.hpbg   = Drawing.new("Square"); o.hpbg.Filled=true;   o.hpbg.Color=Color3.fromRGB(12,12,12); o.hpbg.Transparency=0.55
    o.hpfill = Drawing.new("Square"); o.hpfill.Filled=true; o.hpfill.Transparency=1
    o.name   = Drawing.new("Text");   o.name.Size=13;  o.name.Center=true;  o.name.Outline=true
    o.name.OutlineColor=Color3.fromRGB(0,0,0); o.name.Color=Color3.fromRGB(255,255,255); o.name.Font=2
    o.dist   = Drawing.new("Text");   o.dist.Size=11;  o.dist.Center=true;  o.dist.Outline=true
    o.dist.OutlineColor=Color3.fromRGB(0,0,0); o.dist.Color=Color3.fromRGB(175,175,175); o.dist.Font=2
    o.tracer = Drawing.new("Line");   o.tracer.Thickness=1; o.tracer.Transparency=0.65
    for _,v in pairs(o) do v.Visible=false end
    cache[p]=o
end
local function dropESP(p)
    if cache[p] then for _,v in pairs(cache[p]) do pcall(function() v:Remove() end) end; cache[p]=nil end
end
for _,p in ipairs(Players:GetPlayers()) do if p~=lp then newESP(p) end end
Players.PlayerAdded:Connect(function(p)   task.wait(0.1); newESP(p)  end)
Players.PlayerRemoving:Connect(dropESP)

local fovring = Drawing.new("Circle")
fovring.Color=Color3.fromRGB(220,50,50); fovring.Thickness=1
fovring.Filled=false; fovring.Transparency=0.5; fovring.Visible=false

-- ─── FLY ─────────────────────────────────────────────────────────────────────
local fbv,fbg
local function startfly()
    local r=root(lp); local h=hum(lp); if not r or not h then return end
    h.PlatformStand=true
    fbv=Instance.new("BodyVelocity",r); fbv.Velocity=Vector3.zero; fbv.MaxForce=Vector3.new(1e5,1e5,1e5)
    fbg=Instance.new("BodyGyro",r);     fbg.MaxTorque=Vector3.new(1e5,1e5,1e5); fbg.P=1e4
end
local function stopfly()
    local h=hum(lp); if h then h.PlatformStand=false end
    if fbv then fbv:Destroy() end; if fbg then fbg:Destroy() end; fbv,fbg=nil,nil
end
task.spawn(function()
    local last=false
    while task.wait(0.1) do
        if S.FlyOn~=last then last=S.FlyOn; if S.FlyOn then startfly() else stopfly() end end
    end
end)
UIS.JumpRequest:Connect(function()
    if not S.InfJump then return end
    local h=hum(lp); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ─── TRIGGERBOT ───────────────────────────────────────────────────────────────
task.spawn(function()
    local firing=false
    while task.wait(0.01) do
        if not S.TrigOn then firing=false; continue end
        local m=lp:GetMouse(); local tgt=m.Target
        if not tgt then firing=false; continue end
        local c=tgt:FindFirstAncestorOfClass("Model"); if not c then firing=false; continue end
        local pl=Players:GetPlayerFromCharacter(c)
        if not pl or not enemy(pl,S.TrigTeam) or not alive(pl) then firing=false; continue end
        if not firing then
            firing=true
            task.spawn(function()
                task.wait(S.TrigDelay/1000)
                if S.TrigOn then
                    pcall(mouse1click)
                    pcall(function() mouse1press(); task.wait(0.05); mouse1release() end)
                end
                firing=false
            end)
        end
    end
end)

-- unlock all
local introActive = true

local function deepUnlock()
    -- 1. Patch RemoteFunction / BindableFunction named around inventory
    local searchRoots = {workspace, lp, game:GetService("ReplicatedStorage")}
    for _,root_ in ipairs(searchRoots) do
        pcall(function()
            for _,v in ipairs(root_:GetDescendants()) do
                if v:IsA("RemoteFunction") or v:IsA("BindableFunction") then
                    local n = v.Name:lower()
                    if n:find("skin") or n:find("wrap") or n:find("inventory") or n:find("cosmetic") or n:find("owned") or n:find("unlock") then
                        pcall(function() v.OnClientInvoke = function() return true end end)
                    end
                end
            end
        end)
    end

    -- 2. Advanced memory sweep (getgc) for Rivals data tables & functions
    pcall(function()
        if not getgc then return end
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "OwnedSkins") and type(v.OwnedSkins) == "table" then
                    for id in pairs(v.OwnedSkins) do v.OwnedSkins[id] = true end
                    setmetatable(v.OwnedSkins, {__index = function() return true end})
                end
                if rawget(v, "OwnedWraps") and type(v.OwnedWraps) == "table" then
                    for id in pairs(v.OwnedWraps) do v.OwnedWraps[id] = true end
                    setmetatable(v.OwnedWraps, {__index = function() return true end})
                end
                if rawget(v, "Inventory") and type(v.Inventory) == "table" then
                    setmetatable(v.Inventory, {__index = function() return true end})
                end
                if rawget(v, "isOwned") and type(rawget(v, "isOwned")) == "function" then
                    if hookfunction then hookfunction(v.isOwned, function() return true end) end
                end
            elseif type(v) == "function" then
                local info = debug.getinfo(v)
                if info and info.name then
                    local n = info.name:lower()
                    if n == "isowned" or n == "hasitem" or n == "getskinowned" then
                        if hookfunction then hookfunction(v, function() return true end) end
                    end
                end
            end
        end
    end)

    -- 3. LocalScript env patch fallback
    pcall(function()
        local plrgui = lp:FindFirstChild("PlayerGui")
        if not plrgui then return end
        for _,obj in ipairs(plrgui:GetDescendants()) do
            if obj:IsA("LocalScript") then
                pcall(function()
                    local env = getfenv(obj.Disabled and function() end or function() end)
                    if env then
                        env.isOwned = function() return true end
                        env.getSkinOwned = function() return true end
                    end
                end)
            end
        end
    end)
end

task.spawn(function()
    while task.wait(2.5) do
        if S.UnlockAll then pcall(deepUnlock) end
    end
end)

-- spoofer
local spoofNames = {
    "xXNoobXx","Player_"..math.random(1000,9999),"shadow_"..math.random(100,999),
    "ghost_op","voidwalker","null_ptr","s1lent","ares_user"
}
local spoofIdx = 1

local function applySpoof()
    pcall(function()
        local c=char(lp); if not c then return end
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then h.DisplayName=spoofNames[spoofIdx] end
        -- patch nametag BillboardGuis
        for _,bg in ipairs(c:GetDescendants()) do
            if bg:IsA("BillboardGui") then
                for _,tl in ipairs(bg:GetDescendants()) do
                    if tl:IsA("TextLabel") and
                       (tl.Text==lp.Name or tl.Text==lp.DisplayName or tl.Text==origName) then
                        tl.Text=spoofNames[spoofIdx]
                    end
                end
            end
        end
    end)
end
local origName = lp.DisplayName
task.spawn(function()
    while task.wait(0.8) do if S.SpooferOn then pcall(applySpoof) end end
end)

-- rendering
RS.RenderStepped:Connect(function()
    local m = mid()
    fovring.Position=m; fovring.Radius=S.FOV
    fovring.Visible=DOK and S.ShowFOV and S.AimbotOn

    if introActive then return end
    
    if S.AimbotOn then
        local shouldaim = S.AutoLock or UIS:IsKeyDown(S.AimbotKey)
        if shouldaim then
            local t=closest(S.FOV,S.AimbotPart,S.AimVis,S.AimTeam)
            if t then
                local cf=cam.CFrame
                cam.CFrame=cf:Lerp(CFrame.new(cf.Position,t.Position),S.Smooth)
            end
        end
    end

    if S.SilentOn then
        local t=closest(S.SilentFOV,S.AimbotPart,true,S.SilentTeam)
        if t then pcall(function() lp:GetMouse().Hit=CFrame.new(t.Position) end) end
    end

    local myhum=hum(lp)
    if myhum and S.SpeedOn then myhum.WalkSpeed=S.SpeedVal end

    if S.NoclipOn then
        local c=lp.Character
        if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
    end

    if S.FlyOn and fbv then
        local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        fbv.Velocity=dir*60; fbg.CFrame=cam.CFrame
    end

    for _,pl in ipairs(Players:GetPlayers()) do
        local o=cache[pl]; if not o then continue end
        local c2=char(pl); local h2=hum(pl); local r2=root(pl)
        local function hide() for _,v in pairs(o) do v.Visible=false end end
        if not S.ESPOn or not c2 or not h2 or h2.Health<=0 or not r2 or not enemy(pl,S.ESPTeam) then hide(); continue end
        local d3=(r2.Position-cam.CFrame.Position).Magnitude
        if d3>S.ESPRange then hide(); continue end
        local vis,bx,by,bw,bh=bbox(c2)
        if not vis or bw<=0 or bh<=0 then hide(); continue end
        local col=Color3.fromRGB(220,50,50)

        if S.Boxes then
            o.glow.Color=col; o.glow.Position=Vector2.new(bx,by); o.glow.Size=Vector2.new(bw,bh); o.glow.Visible=true
            o.box.Color=col;  o.box.Position=Vector2.new(bx,by);  o.box.Size=Vector2.new(bw,bh);  o.box.Visible=true
        else o.box.Visible=false; o.glow.Visible=false end

        if S.Health then
            local pct=math.clamp(h2.Health/h2.MaxHealth,0,1)
            local bH=bh*pct
            local r=math.floor(math.clamp((1-pct)*2,0,1)*220+35)
            local g=math.floor(math.clamp(pct*2,   0,1)*185+35)
            o.hpbg.Position=Vector2.new(bx-7,by);          o.hpbg.Size=Vector2.new(4,bh);  o.hpbg.Visible=true
            o.hpfill.Color=Color3.fromRGB(r,g,40)
            o.hpfill.Position=Vector2.new(bx-7,by+(bh-bH));o.hpfill.Size=Vector2.new(4,bH);o.hpfill.Visible=true
        else o.hpbg.Visible=false; o.hpfill.Visible=false end

        if S.Names then o.name.Text=pl.DisplayName; o.name.Position=Vector2.new(bx+bw/2,by-16); o.name.Visible=true
        else o.name.Visible=false end

        if S.Dist then o.dist.Text=math.floor(d3).."m"; o.dist.Position=Vector2.new(bx+bw/2,by+bh+3); o.dist.Visible=true
        else o.dist.Visible=false end

        if S.Tracers then
            o.tracer.Color=col; o.tracer.From=m; o.tracer.To=Vector2.new(bx+bw/2,by+bh); o.tracer.Visible=true
        else o.tracer.Visible=false end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════════════════════════════════════════

-- destroy old instances
for _,fn in ipairs({
    function() local p=game:GetService("CoreGui");  local o=p:FindFirstChild("ares_v4"); if o then o:Destroy() end end,
    function() if gethui then local p=gethui();     local o=p:FindFirstChild("ares_v4"); if o then o:Destroy() end end end,
    function() local p=lp:FindFirstChild("PlayerGui"); if p then local o=p:FindFirstChild("ares_v4"); if o then o:Destroy() end end end,
}) do pcall(fn) end

local gui = Instance.new("ScreenGui")
gui.Name="ares_v4"; gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=9999; gui.IgnoreGuiInset=true

for _,fn in ipairs({
    function() gui.Parent=gethui() end,
    function() gui.Parent=game:GetService("CoreGui") end,
    function() gui.Parent=lp:WaitForChild("PlayerGui",3) end,
}) do if not gui.Parent then pcall(fn) end end

-- ─── SILENT AIM HOOK ──────────────────────────────────────────────────────────
pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if S.SilentOn and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay") then
            -- hijack raycast direction toward nearest target
            local target = closest(S.SilentFOV, "Head", false, S.SilentTeam)
            if target and target.Parent then
                local args = {...}
                if method == "Raycast" then
                    local origin = args[1]
                    local dir = (target.Position - origin).Unit * 1000
                    args[2] = dir
                    return oldNamecall(self, unpack(args))
                elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
                    local ray = args[1]
                    if ray and typeof(ray) == "Ray" then
                        local origin = ray.Origin
                        local dir = (target.Position - origin).Unit * 1000
                        args[1] = Ray.new(origin, dir)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end)

-- ─── THEME ────────────────────────────────────────────────────────────────────
local W,H       = 316,440
local BG        = Color3.fromRGB(7,7,9)
local PANEL     = Color3.fromRGB(12,12,15)
local CARD      = Color3.fromRGB(18,18,22)
local ACC       = Color3.fromRGB(220,45,45)
local ACC2      = Color3.fromRGB(255,75,75)
local BORDER    = Color3.fromRGB(32,32,38)
local WHITE     = Color3.fromRGB(228,228,228)
local DIM       = Color3.fromRGB(78,78,86)
local SUB       = Color3.fromRGB(115,115,124)
local GREEN     = Color3.fromRGB(60,200,85)

local function cr(p,r) end -- rendering blocky ui
local function tw(obj,props,t) TweenSvc:Create(obj,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),props):Play() end
local function twback(obj,props,t) TweenSvc:Create(obj,TweenInfo.new(t or 0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out),props):Play() end

local function mklbl(parent,props)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1; l.Font=props.font or Enum.Font.Gotham
    l.TextSize=props.size or 12; l.TextColor3=props.color or WHITE
    l.Text=props.text or ""; l.TextXAlignment=props.align or Enum.TextXAlignment.Left
    l.Size=props.sz or UDim2.new(1,0,0,20); l.Position=props.pos or UDim2.new(0,0,0,0)
    l.ZIndex=props.z or 2; l.ClipsDescendants=false; l.Parent=parent
    return l
end

local function mkbtn(parent,props)
    local b=Instance.new("TextButton")
    b.BackgroundColor3=props.bg or CARD; b.BorderSizePixel=0
    b.Text=props.text or ""; b.TextColor3=props.tc or WHITE
    b.Font=props.font or Enum.Font.GothamBold; b.TextSize=props.size or 12
    b.Size=props.sz or UDim2.new(0,80,0,28); b.Position=props.pos or UDim2.new(0,0,0,0)
    b.ZIndex=props.z or 2; b.AutoButtonColor=false; b.Parent=parent
    return b
end

-- ─── MAIN WINDOW (no Draggable – custom drag to avoid slider conflict) ────────
local main = Instance.new("Frame")
main.Name="main"; main.Size=UDim2.new(0,W,0,H)
main.Position=UDim2.new(0,36,0.5,-H/2); main.BackgroundColor3=BG
main.BorderSizePixel=0; main.Active=true; main.Draggable=false
main.ClipsDescendants=false; main.ZIndex=1; main.Parent=gui
main.Visible=false
cr(main,8)

local stroke=Instance.new("UIStroke"); stroke.Color=BORDER; stroke.Thickness=1; stroke.Parent=main

-- accent side stripe (left edge)
local sidestripe=Instance.new("Frame")
sidestripe.Size=UDim2.new(0,3,1,0); sidestripe.Position=UDim2.new(0,0,0,0)
sidestripe.BackgroundColor3=ACC; sidestripe.BorderSizePixel=0; sidestripe.ZIndex=4; sidestripe.Parent=main
cr(sidestripe,8)
-- fix right side of sidestripe
local ssfr=Instance.new("Frame"); ssfr.Size=UDim2.new(0.5,0,1,0); ssfr.Position=UDim2.new(0.5,0,0,0)
ssfr.BackgroundColor3=ACC; ssfr.BorderSizePixel=0; ssfr.ZIndex=4; ssfr.Parent=sidestripe

-- red glow under accent
local glow=Instance.new("Frame")
glow.Size=UDim2.new(0,3,1,0); glow.Position=UDim2.new(0,0,0,0)
glow.BackgroundColor3=ACC; glow.BorderSizePixel=0; glow.ZIndex=3
glow.BackgroundTransparency=0.6; glow.Parent=main
cr(glow,8)

-- title
local tbar=Instance.new("Frame")
tbar.Size=UDim2.new(1,0,0,46); tbar.Position=UDim2.new(0,0,0,0)
tbar.BackgroundColor3=PANEL; tbar.BorderSizePixel=0; tbar.ZIndex=2; tbar.Parent=main

-- bottom border of tbar
local tbbl=Instance.new("Frame"); tbbl.Size=UDim2.new(1,0,0,1); tbbl.Position=UDim2.new(0,0,1,-1)
tbbl.BackgroundColor3=BORDER; tbbl.BorderSizePixel=0; tbbl.ZIndex=3; tbbl.Parent=tbar

mklbl(tbar,{text="ares",font=Enum.Font.GothamBold,size=14,color=ACC,
    sz=UDim2.new(0,40,0,20),pos=UDim2.new(0,16,0,8),z=3})
mklbl(tbar,{text="  //  rivals",font=Enum.Font.GothamBold,size=14,color=WHITE,
    sz=UDim2.new(0,90,0,20),pos=UDim2.new(0,44,0,8),z=3})
mklbl(tbar,{text="aimbot · esp · silent · triggerbot · unlock · spoof",size=8,color=DIM,
    sz=UDim2.new(1,-100,0,14),pos=UDim2.new(0,16,0,30),z=3})

-- custom window drag (avoids slider conflict)
local dragging=false; local dragStart; local dragOffset
tbar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true
        dragStart=i.Position
        dragOffset=main.Position
    end
end)
tbar.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=i.Position-dragStart
        main.Position=UDim2.new(
            dragOffset.X.Scale, dragOffset.X.Offset+delta.X,
            dragOffset.Y.Scale, dragOffset.Y.Offset+delta.Y
        )
    end
end)

-- window buttons
local function winbtn(xoff,sym,accentCol)
    local b=mkbtn(tbar,{text=sym,bg=accentCol or CARD,tc=accentCol and WHITE or SUB,
        font=Enum.Font.GothamBold,size=13,
        sz=UDim2.new(0,24,0,24),pos=UDim2.new(1,xoff,0.5,-12),z=4})
    cr(b,6)
    b.MouseEnter:Connect(function() tw(b,{TextColor3=WHITE}) end)
    b.MouseLeave:Connect(function() tw(b,{TextColor3=accentCol and WHITE or SUB}) end)
    return b
end

local btnmin   = winbtn(-60,"-")
local btnclose = winbtn(-30,"×")
btnclose.BackgroundColor3=Color3.fromRGB(25,10,10)

local ismin=false

local function animOut()
    tw(main,{Size=UDim2.new(0,W,0,0),Position=UDim2.new(main.Position.X.Scale,main.Position.X.Offset+W/2,main.Position.Y.Scale,main.Position.Y.Offset+H/2),BackgroundTransparency=1},0.25)
    task.wait(0.28)
    main.Visible=false
    main.BackgroundTransparency=0
    main.Size=UDim2.new(0,W,0,H)
    main.Position=UDim2.new(0,36,0.5,-H/2)
end

local function animIn()
    local tx=main.Position.X.Offset; local ty=main.Position.Y.Offset
    main.Size=UDim2.new(0,0,0,0)
    main.BackgroundTransparency=1
    main.Visible=true
    tw(main,{Size=UDim2.new(0,W,0,H),BackgroundTransparency=0},0.3)
end

btnmin.MouseButton1Click:Connect(function()
    ismin=not ismin
    tw(main,{Size=ismin and UDim2.new(0,W,0,47) or UDim2.new(0,W,0,H)})
end)
btnclose.MouseButton1Click:Connect(function()
    task.spawn(animOut)
end)

UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.Insert then
        if main.Visible then task.spawn(animOut) else task.spawn(animIn) end
    end
end)

-- tabs
local TH=32
local tabbar=Instance.new("Frame")
tabbar.Size=UDim2.new(1,0,0,TH); tabbar.Position=UDim2.new(0,0,0,46)
tabbar.BackgroundColor3=PANEL; tabbar.BorderSizePixel=0; tabbar.ZIndex=2; tabbar.Parent=main

local tabline=Instance.new("Frame")
tabline.Size=UDim2.new(0,W/6,0,2); tabline.Position=UDim2.new(0,0,1,-2)
tabline.BackgroundColor3=ACC; tabline.BorderSizePixel=0; tabline.ZIndex=5; tabline.Parent=tabbar
cr(tabline,1)

local tabbline=Instance.new("Frame"); tabbline.Size=UDim2.new(1,0,0,1); tabbline.Position=UDim2.new(0,0,1,-1)
tabbline.BackgroundColor3=BORDER; tabbline.BorderSizePixel=0; tabbline.ZIndex=3; tabbline.Parent=tabbar

-- pages
local pagearea=Instance.new("Frame")
pagearea.Size=UDim2.new(1,0,1,-(46+TH)); pagearea.Position=UDim2.new(0,0,0,46+TH)
pagearea.BackgroundTransparency=1; pagearea.ClipsDescendants=true
pagearea.ZIndex=2; pagearea.Parent=main

-- components
local function makepage()
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,1,0); f.BackgroundTransparency=1
    f.Visible=false; f.BorderSizePixel=0; f.ZIndex=2; f.Parent=pagearea
    return f
end

local function makelist(page)
    local clip=Instance.new("Frame")
    clip.Size=UDim2.new(1,0,1,0); clip.BackgroundTransparency=1
    clip.ClipsDescendants=true; clip.ZIndex=2; clip.Parent=page

    local inner=Instance.new("Frame")
    inner.Size=UDim2.new(1,-24,0,0); inner.Position=UDim2.new(0,12,0,8)
    inner.BackgroundTransparency=1; inner.ZIndex=2; inner.Parent=clip

    local sb=Instance.new("Frame")
    sb.Size=UDim2.new(0,2,0,0); sb.Position=UDim2.new(1,-6,0,4)
    sb.BackgroundColor3=Color3.fromRGB(45,45,52); sb.BorderSizePixel=0; sb.ZIndex=5; sb.Parent=clip; cr(sb,1)

    clip.InputChanged:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseWheel then return end
        local maxs=math.max(0,inner.AbsoluteSize.Y-clip.AbsoluteSize.Y+16)
        local cur=-inner.Position.Y.Offset
        tw(inner,{Position=UDim2.new(0,12,0,-math.clamp(cur-i.Position.Z*36,0,maxs))})
    end)

    local list={inner=inner,y=0}

    function list:row(h)
        local r=Instance.new("Frame"); r.Size=UDim2.new(1,0,0,h); r.Position=UDim2.new(0,0,0,self.y)
        r.BackgroundTransparency=1; r.ZIndex=2; r.Parent=self.inner
        self.y=self.y+h; self.inner.Size=UDim2.new(1,-24,0,self.y)
        local ratio=math.min(1,clip.AbsoluteSize.Y/math.max(1,self.y+16))
        sb.Size=UDim2.new(0,2,ratio,0); sb.Visible=ratio<1
        return r
    end

    function list:section(text)
        local r=self:row(28)
        mklbl(r,{text=text:upper(),font=Enum.Font.GothamBold,size=8,color=ACC,
            sz=UDim2.new(1,-8,1,0),pos=UDim2.new(0,2,0,0),z=3})
        local ln=Instance.new("Frame"); ln.Size=UDim2.new(1,0,0,1); ln.Position=UDim2.new(0,0,1,-1)
        ln.BackgroundColor3=BORDER; ln.BorderSizePixel=0; ln.ZIndex=3; ln.Parent=r
    end

    function list:toggle(text,key,cb)
        local r=self:row(36)
        mklbl(r,{text=text,size=12,color=WHITE,sz=UDim2.new(1,-54,1,0),pos=UDim2.new(0,2,0,0),z=3})
        local on=S[key]
        local pill=Instance.new("Frame")
        pill.Size=UDim2.new(0,40,0,20); pill.Position=UDim2.new(1,-40,0.5,-10)
        pill.BackgroundColor3=on and ACC or Color3.fromRGB(30,30,36)
        pill.BorderSizePixel=0; pill.ZIndex=3; pill.Parent=r; cr(pill,10)
        local knob=Instance.new("Frame")
        knob.Size=UDim2.new(0,14,0,14)
        knob.Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        knob.BackgroundColor3=on and WHITE or SUB
        knob.BorderSizePixel=0; knob.ZIndex=4; knob.Parent=pill; cr(knob,7)
        local hit=mkbtn(r,{bg=Color3.new(0,0,0),sz=UDim2.new(1,0,1,0),pos=UDim2.new(0,0,0,0),z=5})
        hit.BackgroundTransparency=1
        hit.MouseButton1Click:Connect(function()
            S[key]=not S[key]; local now=S[key]
            tw(pill,{BackgroundColor3=now and ACC or Color3.fromRGB(30,30,36)})
            tw(knob,{Position=now and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
            tw(knob,{BackgroundColor3=now and WHITE or SUB})
            if cb then cb(now) end
        end)
    end

    function list:slider(text,key,minv,maxv,isfloat)
        local r=self:row(52)
        mklbl(r,{text=text,size=12,color=WHITE,sz=UDim2.new(0.62,0,0,20),pos=UDim2.new(0,2,0,0),z=3})

        local vl=mklbl(r,{text=tostring(S[key]),font=Enum.Font.GothamBold,size=11,color=SUB,
            align=Enum.TextXAlignment.Right,sz=UDim2.new(0.38,-2,0,20),pos=UDim2.new(0.62,0,0,0),z=3})

        local track=Instance.new("Frame")
        track.Size=UDim2.new(1,-4,0,5); track.Position=UDim2.new(0,2,0,30)
        track.BackgroundColor3=Color3.fromRGB(26,26,32); track.BorderSizePixel=0; track.ZIndex=3; track.Parent=r; cr(track,3)

        local pct=math.clamp((S[key]-minv)/(maxv-minv),0,1)

        local fill=Instance.new("Frame")
        fill.Size=UDim2.new(pct,0,1,0); fill.BackgroundColor3=ACC
        fill.BorderSizePixel=0; fill.ZIndex=4; fill.Parent=track; cr(fill,3)

        local handle=Instance.new("Frame")
        handle.Size=UDim2.new(0,13,0,13); handle.Position=UDim2.new(pct,-6.5,0.5,-6.5)
        handle.BackgroundColor3=WHITE; handle.BorderSizePixel=0; handle.ZIndex=6; handle.Parent=track; cr(handle,7)

        local glow2=Instance.new("Frame")
        glow2.Size=UDim2.new(0,19,0,19); glow2.Position=UDim2.new(0.5,-9.5,0.5,-9.5)
        glow2.BackgroundColor3=ACC; glow2.BackgroundTransparency=0.7
        glow2.BorderSizePixel=0; glow2.ZIndex=5; glow2.Parent=handle; cr(glow2,10)
        glow2.Visible=false

        -- Invisible full-row grab strip so mousedown anywhere on the track works
        local grabStrip=mkbtn(r,{bg=Color3.new(0,0,0),sz=UDim2.new(1,-4,0,24),pos=UDim2.new(0,2,0,22),z=7})
        grabStrip.BackgroundTransparency=1; grabStrip.Text=""

        local drag2=false

        local function setVal(mx)
            local rel=math.clamp((mx-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local val=isfloat and (math.floor((minv+(maxv-minv)*rel)*100+0.5)/100)
                                or math.floor(minv+(maxv-minv)*rel+0.5)
            S[key]=val; fill.Size=UDim2.new(rel,0,1,0)
            handle.Position=UDim2.new(rel,-6.5,0.5,-6.5); vl.Text=tostring(val)
        end

        grabStrip.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                drag2=true; dragging=false -- kill window drag
                glow2.Visible=true
                setVal(i.Position.X)
            end
        end)
        handle.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                drag2=true; dragging=false
                glow2.Visible=true
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                drag2=false; glow2.Visible=false
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if drag2 and i.UserInputType==Enum.UserInputType.MouseMovement then
                setVal(i.Position.X)
            end
        end)
    end

    function list:actionbtn(text,cb)
        local r=self:row(42)
        local b=mkbtn(r,{text=text,bg=ACC,tc=WHITE,font=Enum.Font.GothamBold,
            size=12,sz=UDim2.new(1,-4,0,30),pos=UDim2.new(0,2,0,6),z=3})
        cr(b,6)
        b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=ACC2}) end)
        b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=ACC}) end)
        b.MouseButton1Click:Connect(function()
            tw(b,{BackgroundColor3=Color3.fromRGB(255,120,120)})
            task.delay(0.12,function() tw(b,{BackgroundColor3=ACC}) end)
            if cb then cb() end
        end)
    end

    return list
end

-- init tabs
local tabs   = {"aimbot","esp","combat","unlock","misc"}
local tbtns  = {}; local tpages = {}

local function switchtab(name)
    for i,td in ipairs(tabs) do
        tpages[td].Visible=(td==name)
        tw(tbtns[td],{TextColor3=td==name and WHITE or DIM})
        if td==name then
            tw(tabline,{Position=UDim2.new(0,(i-1)*(W/#tabs),1,-2),Size=UDim2.new(0,W/#tabs,0,2)})
        end
    end
end

for i,name in ipairs(tabs) do
    local pg=makepage(); tpages[name]=pg
    local b=mkbtn(tabbar,{
        text=name:sub(1,1):upper()..name:sub(2),
        bg=Color3.new(0,0,0),tc=name=="aimbot" and WHITE or DIM,
        font=Enum.Font.GothamBold,size=10,
        sz=UDim2.new(1/#tabs,0,1,0),pos=UDim2.new((i-1)/#tabs,0,0,0),z=3
    })
    b.BackgroundTransparency=1
    b.MouseEnter:Connect(function() if b.TextColor3~=WHITE then tw(b,{TextColor3=SUB}) end end)
    b.MouseLeave:Connect(function() if b.TextColor3~=WHITE then tw(b,{TextColor3=DIM}) end end)
    b.MouseButton1Click:Connect(function() switchtab(name) end)
    tbtns[name]=b
end
tpages["aimbot"].Visible=true

-- aimbot tab
do
    local L=makelist(tpages["aimbot"])
    L:section("aimbot")
    L:toggle("enable aimbot","AimbotOn")
    L:toggle("auto-lock (no key hold)","AutoLock")
    L:toggle("visibility check","AimVis")
    L:toggle("team check","AimTeam")
    L:toggle("show fov circle","ShowFOV")
    L:section("settings")
    L:slider("fov radius","FOV",20,500)
    L:slider("smoothness","Smooth",1,30,true)
end

-- esp tab
do
    local L=makelist(tpages["esp"])
    L:section("esp")
    L:toggle("enable esp","ESPOn")
    L:toggle("boxes","Boxes")
    L:toggle("names","Names")
    L:toggle("distance","Dist")
    L:toggle("health bars","Health")
    L:toggle("tracers","Tracers")
    L:toggle("team check","ESPTeam")
    L:section("range")
    L:slider("max distance","ESPRange",100,2000)
end

-- combat tab
do
    local L=makelist(tpages["combat"])
    L:section("silent aim")
    L:toggle("enable silent aim","SilentOn")
    L:toggle("team check","SilentTeam")
    L:slider("fov radius","SilentFOV",20,500)
    L:section("triggerbot")
    L:toggle("enable triggerbot","TrigOn")
    L:toggle("team check","TrigTeam")
    L:slider("delay (ms)","TrigDelay",0,300)
end

-- unlock tab
do
    local L=makelist(tpages["unlock"])
    L:section("cosmetics")
    L:toggle("auto unlock skins & wraps","UnlockAll")
    L:actionbtn("force apply now",function()
        task.spawn(deepUnlock)
    end)
    L:section("spoofer")
    L:toggle("enable spoofer","SpooferOn")
    L:actionbtn("cycle fake name",function()
        spoofIdx=spoofIdx%#spoofNames+1
        task.spawn(applySpoof)
    end)
    L:section("anti-cheat")
    L:toggle("anti-report mode","AntiReport")
end

-- misc tab
do
    local L=makelist(tpages["misc"])
    L:section("movement")
    L:toggle("speed hack","SpeedOn")
    L:toggle("fly  (wasd + space / shift)","FlyOn")
    L:toggle("noclip","NoclipOn")
    L:toggle("infinite jump","InfJump")
    L:section("settings")
    L:slider("walk speed","SpeedVal",16,300)
    L:section("window")
    L:actionbtn("reset window position",function()
        main.Position=UDim2.new(0,36,0.5,-H/2)
    end)
end

-- handle missing reference in previous edits
local pg = tpages["unlock"]

-- intro
local splash=Instance.new("Frame")
splash.Name="splash"; splash.Size=UDim2.new(1,0,1,0)
splash.BackgroundColor3=Color3.fromRGB(4,4,6); splash.BorderSizePixel=0
splash.ZIndex=100; splash.Parent=gui

local scanFrame=Instance.new("Frame")
scanFrame.Size=UDim2.new(1,0,1,0); scanFrame.BackgroundTransparency=1
scanFrame.ZIndex=108; scanFrame.ClipsDescendants=true; scanFrame.Parent=splash
do
    local lineH=4; local total=math.ceil(800/lineH)
    for i=0,total do
        local sl=Instance.new("Frame")
        sl.Size=UDim2.new(1,0,0,1); sl.Position=UDim2.new(0,0,0,i*lineH)
        sl.BackgroundColor3=Color3.fromRGB(0,0,0); sl.BackgroundTransparency=0.88
        sl.BorderSizePixel=0; sl.ZIndex=108; sl.Parent=scanFrame
    end
end

local grid=Instance.new("Frame")
grid.Size=UDim2.new(1,0,1,0); grid.BackgroundTransparency=1; grid.ZIndex=100; grid.Parent=splash
do
    local spacing=48
    local cols=math.ceil(1920/spacing); local rows=math.ceil(1080/spacing)
    for c=0,cols do
        local l=Instance.new("Frame"); l.Size=UDim2.new(0,1,1,0); l.Position=UDim2.new(0,c*spacing,0,0)
        l.BackgroundColor3=Color3.fromRGB(220,40,40); l.BackgroundTransparency=0.92
        l.BorderSizePixel=0; l.ZIndex=100; l.Parent=grid
    end
    for r=0,rows do
        local l=Instance.new("Frame"); l.Size=UDim2.new(1,0,0,1); l.Position=UDim2.new(0,0,0,r*spacing)
        l.BackgroundColor3=Color3.fromRGB(220,40,40); l.BackgroundTransparency=0.92
        l.BorderSizePixel=0; l.ZIndex=100; l.Parent=grid
    end
end

local ring1=Instance.new("Frame")
ring1.Size=UDim2.new(0,260,0,260); ring1.Position=UDim2.new(0.5,-130,0.5,-130)
ring1.BackgroundTransparency=1; ring1.BorderSizePixel=0; ring1.ZIndex=101; ring1.Parent=splash
local ringstroke1=Instance.new("UIStroke"); ringstroke1.Color=ACC; ringstroke1.Thickness=1.5
ringstroke1.Transparency=0.5; ringstroke1.Parent=ring1; cr(ring1,130)

local ring2=Instance.new("Frame")
ring2.Size=UDim2.new(0,200,0,200); ring2.Position=UDim2.new(0.5,-100,0.5,-100)
ring2.BackgroundTransparency=1; ring2.BorderSizePixel=0; ring2.ZIndex=101; ring2.Parent=splash
local ringstroke2=Instance.new("UIStroke"); ringstroke2.Color=ACC; ringstroke2.Thickness=1
ringstroke2.Transparency=0.65; ringstroke2.Parent=ring2; cr(ring2,100)

local orb=Instance.new("Frame")
orb.Size=UDim2.new(0,130,0,130); orb.Position=UDim2.new(0.5,-65,0.5,-65)
orb.BackgroundColor3=ACC; orb.BackgroundTransparency=0.45
orb.BorderSizePixel=0; orb.ZIndex=102; orb.Parent=splash; cr(orb,65)

local orbInner=Instance.new("Frame")
orbInner.Size=UDim2.new(0,80,0,80); orbInner.Position=UDim2.new(0.5,-40,0.5,-40)
orbInner.BackgroundColor3=Color3.fromRGB(255,80,80); orbInner.BackgroundTransparency=0.25
orbInner.BorderSizePixel=0; orbInner.ZIndex=103; orbInner.Parent=splash; cr(orbInner,40)

local function cornerAccent(ax,ay,rx,ry)
    local f=Instance.new("Frame"); f.Size=UDim2.new(0,40,0,2)
    f.Position=UDim2.new(ax,rx,ay,ry); f.BackgroundColor3=ACC
    f.BorderSizePixel=0; f.ZIndex=104; f.Parent=splash
    local f2=Instance.new("Frame"); f2.Size=UDim2.new(0,2,0,40)
    f2.Position=UDim2.new(ax,rx,ay,ry); f2.BackgroundColor3=ACC
    f2.BorderSizePixel=0; f2.ZIndex=104; f2.Parent=splash
end
cornerAccent(0,0, 20,20)
cornerAccent(1,0, -62,20)
cornerAccent(0,1, 20,-62)
cornerAccent(1,1, -62,-62)

local logo=Instance.new("TextLabel")
logo.BackgroundTransparency=1; logo.Font=Enum.Font.GothamBlack
logo.TextSize=52; logo.TextColor3=WHITE; logo.Text="ARES"
logo.Size=UDim2.new(1,0,0,60); logo.Position=UDim2.new(0,0,0.5,-58)
logo.TextXAlignment=Enum.TextXAlignment.Center
logo.TextTransparency=1; logo.ZIndex=105; logo.Parent=splash

local logoShadow=Instance.new("TextLabel")
logoShadow.BackgroundTransparency=1; logoShadow.Font=Enum.Font.GothamBlack
logoShadow.TextSize=52; logoShadow.TextColor3=ACC; logoShadow.Text="ARES"
logoShadow.Size=UDim2.new(1,0,0,60); logoShadow.Position=UDim2.new(0,2,0.5,-56)
logoShadow.TextXAlignment=Enum.TextXAlignment.Center
logoShadow.TextTransparency=1; logoShadow.ZIndex=104; logoShadow.Parent=splash

local tagline=Instance.new("TextLabel")
tagline.BackgroundTransparency=1; tagline.Font=Enum.Font.GothamBold
tagline.TextSize=11; tagline.TextColor3=ACC; tagline.Text="R I V A L S   E D I T I O N"
tagline.Size=UDim2.new(1,0,0,20); tagline.Position=UDim2.new(0,0,0.5,10)
tagline.TextXAlignment=Enum.TextXAlignment.Center
tagline.TextTransparency=1; tagline.ZIndex=105; tagline.Parent=splash

local pbgOuter=Instance.new("Frame")
pbgOuter.Size=UDim2.new(0,280,0,6); pbgOuter.Position=UDim2.new(0.5,-140,0.5,48)
pbgOuter.BackgroundColor3=Color3.fromRGB(18,18,22); pbgOuter.BorderSizePixel=0
pbgOuter.ZIndex=105; pbgOuter.Parent=splash; cr(pbgOuter,3)
local pgbStroke=Instance.new("UIStroke"); pgbStroke.Color=BORDER; pgbStroke.Thickness=1
pgbStroke.Parent=pbgOuter

local pbar=Instance.new("Frame")
pbar.Size=UDim2.new(0,0,1,0); pbar.BackgroundColor3=ACC
pbar.BorderSizePixel=0; pbar.ZIndex=106; pbar.Parent=pbgOuter; cr(pbar,3)

local pbarGlow=Instance.new("Frame")
pbarGlow.Size=UDim2.new(1,0,0,4); pbarGlow.Position=UDim2.new(0,0,1,0)
pbarGlow.BackgroundColor3=ACC; pbarGlow.BackgroundTransparency=0.75
pbarGlow.BorderSizePixel=0; pbarGlow.ZIndex=105; pbarGlow.Parent=pbar; cr(pbarGlow,2)

local statuslbl=Instance.new("TextLabel")
statuslbl.BackgroundTransparency=1; statuslbl.Font=Enum.Font.GothamBold
statuslbl.TextSize=9; statuslbl.TextColor3=DIM; statuslbl.Text=""
statuslbl.Size=UDim2.new(0,280,0,16); statuslbl.Position=UDim2.new(0.5,-140,0.5,60)
statuslbl.TextXAlignment=Enum.TextXAlignment.Left
statuslbl.ZIndex=105; statuslbl.Parent=splash

local verlbl=Instance.new("TextLabel")
verlbl.BackgroundTransparency=1; verlbl.Font=Enum.Font.Gotham
verlbl.TextSize=8; verlbl.TextColor3=DIM; verlbl.Text="v4.1  ·  press INSERT to toggle"
verlbl.Size=UDim2.new(1,-24,0,16); verlbl.Position=UDim2.new(0,12,1,-20)
verlbl.TextXAlignment=Enum.TextXAlignment.Left; verlbl.ZIndex=105; verlbl.Parent=splash

local glitchChars="/*@#!%^&|\\~><_"
local function randGlitch(base)
    local out=""
    for i=1,#base do
        if math.random()<0.18 then
            out=out..glitchChars:sub(math.random(1,#glitchChars),math.random(1,#glitchChars))
        else out=out..base:sub(i,i) end
    end
    return out
end

local function typeText(lbl,text,delay)
    for i=1,#text do lbl.Text=text:sub(1,i); task.wait(delay or 0.03) end
end

task.spawn(function()
    local t=0
    while splash.Visible do
        t=t+0.05
        local s=1+math.sin(t)*0.05; local s2=1+math.sin(t+1)*0.05
        orb.Size=UDim2.new(0,130*s,0,130*s); orb.Position=UDim2.new(0.5,-65*s,0.5,-65*s)
        orbInner.Size=UDim2.new(0,80*s2,0,80*s2); orbInner.Position=UDim2.new(0.5,-40*s2,0.5,-40*s2)
        ring1.Rotation=t*14; ring2.Rotation=-t*9
        task.wait(0.03)
    end
end)

local steps={
    {0.18,"  > injecting ares core..."},
    {0.36,"  > hooking render pipeline..."},
    {0.54,"  > patching ownership tables..."},
    {0.70,"  > building ui components..."},
    {0.85,"  > configuring esp renderer..."},
    {1.00,"  > all systems ready."},
}

task.spawn(function()
    task.wait(0.25)

    -- glitch-flash logo in
    for _=1,7 do
        logo.Text=randGlitch("ARES"); logoShadow.Text=randGlitch("ARES")
        logo.TextTransparency=0.25; logoShadow.TextTransparency=0.55
        task.wait(0.065)
    end
    logo.Text="ARES"; logoShadow.Text="ARES"
    tw(logo,{TextTransparency=0},0.2)
    tw(logoShadow,{TextTransparency=0.5},0.2)
    task.wait(0.18)
    tw(tagline,{TextTransparency=0},0.35)
    task.wait(0.45)

    -- step through progress
    for _,step in ipairs(steps) do
        tw(pbar,{Size=UDim2.new(step[1],0,1,0)},0.42)
        tw(pbarGlow,{Size=UDim2.new(step[1],0,0,4)},0.42)
        task.spawn(function() typeText(statuslbl,step[2],0.022) end)
        task.wait(0.52)
    end

    task.wait(0.35)

    -- final identity glitch burst
    for _=1,10 do
        logo.Text=randGlitch("ARES")
        logo.TextColor3=math.random()<0.5 and ACC or WHITE
        task.wait(0.045)
    end
    logo.Text="ARES"; logo.TextColor3=WHITE

    task.wait(0.25)

    -- fade everything out
    tw(splash,{BackgroundTransparency=1},0.55)
    tw(logo,{TextTransparency=1},0.38)
    tw(logoShadow,{TextTransparency=1},0.38)
    tw(tagline,{TextTransparency=1},0.38)
    tw(statuslbl,{TextTransparency=1},0.3)
    tw(verlbl,{TextTransparency=1},0.3)
    tw(ringstroke1,{Transparency=1},0.38)
    tw(ringstroke2,{Transparency=1},0.38)
    tw(orb,{BackgroundTransparency=1},0.38)
    tw(orbInner,{BackgroundTransparency=1},0.38)

    task.wait(0.6)
    splash.Visible=false
    introActive=false  -- ← ESP now allowed to render

    -- pop main window in
    main.Size=UDim2.new(0,W,0,0)
    main.BackgroundTransparency=1
    main.Visible=true
    tw(main,{Size=UDim2.new(0,W,0,H),BackgroundTransparency=0},0.38)
    task.wait(0.38)
    print("ares hub v4 | rivals edition — INSERT to toggle")
end)
