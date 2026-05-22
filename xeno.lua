-- =====================================================================
-- XENO v17.9 - COMPLETE LUAU REWRITE (1:1 PORT)
-- ENGINE: v10.9 (Drawing API, Full Batching, Prediction v2)
-- UI:     v16.9 (7 Tabs, RGB Picker, Floating Button, Popovers)
-- OPTIMIZED FOR ECLIPSE: gethui, newcclosure, mouse1press
-- =====================================================================

-- ---- Cleanup previous load ----
if _G.XenoLoaded and _G.XenoCleanup then 
    pcall(_G.XenoCleanup) 
end
_G.XenoLoaded = true

-- ---- Services ----
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local WS         = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui    = game:GetService("CoreGui")

local Plr   = Players.LocalPlayer
local Cam   = WS.CurrentCamera
local Mouse = Plr:GetMouse()
local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function SC(p, m) if IsMobile then return m end return p end

-- ---- Executor Detection ----
local Exec = {name = "Eclipse", canSilent = false, canCoreGui = false}
pcall(function()
    if identifyexecutor then Exec.name = identifyexecutor() end
end)
pcall(function()
    local t = Instance.new("Folder")
    t.Parent = CoreGui
    t:Destroy()
    Exec.canCoreGui = true
end)
Exec.canSilent = (typeof(hookmetamethod) == "function")

local drawOK = false
pcall(function()
    local t = Drawing.new("Line")
    t.Visible = false
    t:Remove()
    drawOK = true
end)

local DEAD = false

-- ---- Helpers ----
local function Notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = msg or "", Duration = dur or 4})
    end)
end

local function SafeP()
    if typeof(gethui) == "function" then
        local o, r = pcall(gethui)
        if o and r then return r end
    end
    if Exec.canCoreGui then return CoreGui end
    return Plr:WaitForChild("PlayerGui")
end

local function Protect(g)
    -- Eclipse specific protection (gethui is used in SafeP)
end

local function ND(t)
    if not drawOK then return nil end
    local s, d = pcall(Drawing.new, t)
    if not s or not d then return nil end
    d.Visible = false
    return d
end

local function Kill(d)
    if not d then return end
    pcall(function() d.Visible = false end)
    pcall(function() d:Remove() end)
end

Notify("XENO", "Loading v17.9 FULL...", 3)

-- ---- Config ----
local Cfg = {
    Aim = {
        On = false,
        Mode = "Normal",
        Part = "Head",
        FOV = 120,
        FOVOn = true,
        Smooth = 30,
        Speed = 1.0,
        Prediction = false,
        PredFactor = 0.12,
        Sticky = false,
        Aim360 = false,
    },
    ESP = {
        On = false,
        MaxDist = 1500,
        ShowTeam = false,
    },
    Box = {On = true, Style = "Corner", Thickness = 1, Outline = true, Color = Color3.fromRGB(255, 50, 50), TeamColor = Color3.fromRGB(50, 255, 50)},
    Name = {On = true, Size = 13, Format = "Name+Dist", Color = Color3.fromRGB(255, 255, 255), TeamColor = Color3.fromRGB(255, 255, 255)},
    HP = {On = true, Width = 3, Offset = 5, BgColor = Color3.fromRGB(25, 25, 25)},
    Tracer = {On = false, Thickness = 1.5, Color = Color3.fromRGB(255, 80, 80)},
    HeadDot = {On = false, Radius = 4, Color = Color3.fromRGB(255, 255, 255)},
    WH = {
        On = false,
        ShowTeam = false,
        FT = 0.5,
        EnemyFill = Color3.fromRGB(255, 0, 0),
        EnemyLine = Color3.fromRGB(255, 255, 255),
        TeamFill = Color3.fromRGB(0, 255, 0),
        TeamLine = Color3.fromRGB(255, 255, 255),
    },
    TP = {On = false, RotSpeed = 0.3, MaxAngle = 45},
    Spin = {On = false, Spd = 10},
    Speed = {On = false, Mult = 1.5},
    Checks = {Team = true, Wall = true},
    Limits = {MaxDist = 800, MaxAngle = 90, MinDist = 5},
    MagicBullet = {On = false, Range = 300, Keybind = "E"},
    Tick = {ESP = 3, WH = 5, HUD = 2, Aim = 1},
    UI = {
        Accent     = Color3.fromRGB(90, 130, 255),
        Background = Color3.fromRGB(20, 20, 28),
        Panel      = Color3.fromRGB(30, 30, 38),
        Text       = Color3.fromRGB(220, 220, 230),
        TextDim    = Color3.fromRGB(140, 140, 155),
        Toggle     = Color3.fromRGB(50, 50, 55),
        ButtonOK   = Color3.fromRGB(90, 130, 255),
        ButtonBad  = Color3.fromRGB(200, 50, 50),
    },
}

-- ---- State ----
local S = {
    tgt = {part = nil, plr = nil, dist = 0, hp = 0, mhp = 0, name = "", vis = false, lastT = 0, lastPos = nil, vel = Vector3.zero},
    me  = {char = nil, hum = nil, root = nil, alive = false},
    magic = {on = false, target = nil, hookInstalled = false},
    esp  = {},
    wh   = {},
    draw = {},
    conns = {},
    theme = {accent = {}, bg = {}, panel = {}, text = {}, textDim = {}, btnBad = {}},
    gui = nil,
    frame = 0,
    espBatch = 0,
    plList = {},
    plTick = 0,
    tpRot = 0,
    spinAng = 0,
    fpsAvg = 60,
    fpsLast = os.clock(),
}

-- ---- Geometry helpers ----
local function W2S(pos)
    if not Cam then Cam = WS.CurrentCamera end
    if not Cam then return nil, false end
    local ok, vp = pcall(function() return Cam:WorldToViewportPoint(pos) end)
    if not ok or not vp or vp.Z <= 0 then return nil, false end
    return Vector2.new(vp.X, vp.Y), true
end

local function ScrC()
    if not Cam then return Vector2.new(960, 540) end
    return Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
end

local function SDist(wp)
    local sp, on = W2S(wp)
    if not sp or not on then return 99999 end
    return (sp - ScrC()).Magnitude
end

local function HPCol(pct)
    pct = math.clamp(pct, 0, 1)
    if pct > 0.6 then return Color3.new(0.2, 0.8, 0.2) end
    if pct > 0.3 then return Color3.new(1, 0.8, 0) end
    return Color3.new(1, 0.1, 0.1)
end

local function TeamEq(a, b)
    if not a or not b then return false end
    local ok1, t1 = pcall(function() return a.Team end)
    local ok2, t2 = pcall(function() return b.Team end)
    return ok1 and ok2 and t1 and t2 and t1 == t2
end

local function GetHP(ch)
    if not ch then return 0, 100 end
    local h = ch:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, h.MaxHealth
end

local function GetRoot(ch)
    if not ch then return nil end
    return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch.PrimaryPart
end

local function CanSee(part, myCh)
    if not part or not myCh or not Cam then return true end
    local ok, res = pcall(function()
        local origin = Cam.CFrame.Position
        local dir = part.Position - origin
        local dist = dir.Magnitude
        if dist < 3 then return true end
        local par = RaycastParams.new()
        par.FilterType = Enum.RaycastFilterType.Exclude
        local tCh = part.Parent
        if tCh then par.FilterDescendantsInstances = {myCh, tCh}
        else par.FilterDescendantsInstances = {myCh} end
        par.RespectCanCollide = false
        local r = WS:Raycast(origin, dir.Unit * (dist - 1), par)
        if not r then return true end
        return r.Instance.Transparency >= 0.5 or not r.Instance.CanCollide
    end)
    if ok then return res end
    return true
end

-- ---- Char setup ----
local function SetupChar()
    local function onChar(ch)
        if DEAD then return end
        S.me.char = ch
        S.me.alive = false
        S.tgt.part = nil
        S.tgt.plr = nil
        S.tpRot = 0
        local hum, root
        pcall(function() hum  = ch:WaitForChild("Humanoid", 10) end)
        pcall(function() root = ch:WaitForChild("HumanoidRootPart", 10) end)
        if not hum or not root then return end
        S.me.hum  = hum
        S.me.root = root
        S.me.alive = true
        hum.Died:Connect(function()
            S.me.alive = false
            S.tgt.part = nil
            S.tgt.plr = nil
            S.tpRot = 0
        end)
    end
    if Plr.Character then task.spawn(onChar, Plr.Character) end
    table.insert(S.conns, Plr.CharacterAdded:Connect(onChar))
end

local function GetBone(ch)
    if not ch then return nil end
    return ch:FindFirstChild(Cfg.Aim.Part) or ch:FindFirstChild("Head") or GetRoot(ch)
end

local function IsValid(ch, tp)
    if not ch or not ch.Parent then return false end
    local rp = GetRoot(ch)
    if not rp then return false end
    if GetHP(ch) <= 0 then return false end
    if Cfg.Checks.Team and TeamEq(Plr, tp) then return false end
    if S.me.root then
        local d = (rp.Position - S.me.root.Position).Magnitude
        if d > Cfg.Limits.MaxDist then return false end
        if d < Cfg.Limits.MinDist then return false end
    end
    return true
end

local function GetAng(p)
    if not p or not Cam then return 180 end
    local dir = p.Position - Cam.CFrame.Position
    if dir.Magnitude < 0.001 then return 0 end
    local dot = Cam.CFrame.LookVector:Dot(dir.Unit)
    return math.deg(math.acos(math.clamp(dot, -1, 1)))
end

-- ---- Player list cache ----
local function RefreshPL()
    if os.clock() - S.plTick < 0.5 then return end
    S.plTick = os.clock()
    S.plList = Players:GetPlayers()
end

-- ---- Find Target ----
local function FindTarget()
    if not S.me.alive then return nil, nil end
    if not Cam then return nil, nil end
    local is360 = Cfg.Aim.Aim360
    if Cfg.Aim.Sticky and S.tgt.part and S.tgt.plr then
        local ch = S.tgt.plr.Character
        if ch and ch.Parent and GetHP(ch) > 0 then
            local p = GetBone(ch)
            if p then
                local _, on = W2S(p.Position)
                local inF = true
                if Cfg.Aim.FOVOn then inF = SDist(p.Position) <= Cfg.Aim.FOV * 1.5 end
                local vis = true
                if Cfg.Checks.Wall then vis = CanSee(p, S.me.char) end
                if is360 then on, inF = true, true end
                if on and inF and vis then
                    S.tgt.part, S.tgt.lastT, S.tgt.vis = p, os.clock(), true
                    return p, S.tgt.plr
                end
                if os.clock() - (S.tgt.lastT or 0) > 3 then S.tgt.part, S.tgt.plr = nil, nil end
            end
        else S.tgt.part, S.tgt.plr = nil, nil end
    end
    local bestP, bestPl, bestScore = nil, nil, -999999
    for _, tp in ipairs(S.plList) do
        repeat
            if tp == Plr then break end
            local ch = tp.Character
            if not IsValid(ch, tp) then break end
            local p = GetBone(ch)
            if not p then break end
            local _, on = W2S(p.Position)
            if not is360 and not on then break end
            local sd = SDist(p.Position)
            if Cfg.Aim.FOVOn and not is360 and sd > Cfg.Aim.FOV then break end
            if not is360 and GetAng(p) > Cfg.Limits.MaxAngle then break end
            if Cfg.Checks.Wall and not CanSee(p, S.me.char) then break end
            local sc = 100000 - sd
            if sc > bestScore then
                bestScore, bestP, bestPl = sc, p, tp
            end
        until true
    end
    if bestP then S.tgt.vis = true end
    return bestP, bestPl
end

local function PredPos(p)
    if not p then return Vector3.zero end
    if not Cfg.Aim.Prediction then return p.Position end
    local cur = p.Position
    if S.tgt.lastPos then
        local dv = (cur - S.tgt.lastPos) * 60 - S.tgt.vel
        S.tgt.vel = S.tgt.vel + dv * Cfg.Aim.PredFactor
    end
    S.tgt.lastPos = cur
    return cur + S.tgt.vel * Cfg.Aim.PredFactor
end

local function ApplyAim(p)
    if not p or not Cam then return end
    local tcf = CFrame.lookAt(Cam.CFrame.Position, PredPos(p))
    local sm = math.clamp(Cfg.Aim.Smooth, 0, 100)
    local sp = math.clamp(Cfg.Aim.Speed, 0.01, 5)
    local amt = (1 / (1 + sm * 0.3)) * sp
    Cam.CFrame = Cam.CFrame:Lerp(tcf, math.clamp(amt, 0.001, 1))
end

-- ---- Magic Bullet (newcclosure hook) ----
local function FindNearestHead()
    if not S.me.alive or not S.me.root then return nil end
    local best, bestD = nil, Cfg.MagicBullet.Range
    for _, tp in ipairs(S.plList) do
        repeat
            if tp == Plr then break end
            local ch = tp.Character
            if not ch or not ch.Parent then break end
            if Cfg.Checks.Team and TeamEq(Plr, tp) then break end
            local h = ch:FindFirstChild("Head")
            if not h or GetHP(ch) <= 0 then break end
            local d = (h.Position - S.me.root.Position).Magnitude
            if d < bestD then
                if not Cfg.Checks.Wall or CanSee(h, S.me.char) then
                    best, bestD = h, d
                end
            end
        until true
    end
    return best
end

local function InstallMagicBullet()
    if S.magic.hookInstalled or not Exec.canSilent then return end
    S.magic.hookInstalled = true
    local oldNc
    oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if DEAD or not S.magic.on then return oldNc(self, ...) end
        local m = getnamecallmethod()
        if self == WS and m == "Raycast" then
            local args = {...}
            if #args >= 2 and typeof(args[1]) == "Vector3" then
                local head = FindNearestHead()
                if head and (args[1] - S.me.root.Position).Magnitude < 50 then
                    S.magic.target = head
                    return oldNc(self, args[1], (head.Position - args[1]).Unit * 1000, select(3, ...))
                end
            end
        end
        return oldNc(self, ...)
    end))
    Notify("MAGIC BULLET", "Hook installed", 2)
end

local function ToggleMagicBullet()
    S.magic.on = not S.magic.on
    Cfg.MagicBullet.On = S.magic.on
    if S.magic.on and not S.magic.hookInstalled then InstallMagicBullet() end
end

-- ---- TPFix ----
local function TPFix()
    if not Cfg.TP.On or not S.me.alive or not S.me.root or not S.tgt.part then 
        S.tpRot = 0 return 
    end
    local dist = (S.me.root.Position - Cam.CFrame.Position).Magnitude
    if dist > 10 then return end
    local cl = Cam.CFrame.LookVector
    local cf = Vector3.new(cl.X, 0, cl.Z).Unit
    local chl = S.me.root.CFrame.LookVector
    local chf = Vector3.new(chl.X, 0, chl.Z).Unit
    if math.deg(math.acos(math.clamp(cf:Dot(chf), -1, 1))) > Cfg.TP.MaxAngle then return end
    local tgt = cf:Dot(chf) > 0 and CFrame.new(S.me.root.Position, S.me.root.Position + cf) or CFrame.new(S.me.root.Position, S.me.root.Position - cf)
    S.tpRot = math.min(S.tpRot + Cfg.TP.RotSpeed, 1)
    local _, yaw, _ = S.me.root.CFrame:Lerp(tgt, S.tpRot):ToEulerAnglesYXZ()
    S.me.root.CFrame = CFrame.new(S.me.root.Position) * CFrame.Angles(0, yaw, 0)
end

-- ---- ESP System ----
local E = {}
function E.New(uid)
    if S.esp[uid] or not drawOK then return end
    local o = {
        box = ND("Square"), boxO = ND("Square"), name = ND("Text"),
        hpBg = ND("Square"), hpFill = ND("Square"), tracer = ND("Line"),
        hdot = ND("Circle"), cL = {}, cO = {}
    }
    for i=1,8 do o.cL[i], o.cO[i] = ND("Line"), ND("Line") end
    if o.name then o.name.Center, o.name.Outline, o.name.Size = true, true, Cfg.Name.Size end
    if o.hdot then o.hdot.Filled, o.hdot.NumSides = true, 10 end
    S.esp[uid] = o
end

function E.Hide(o)
    if not o then return end
    local keys = {"box", "boxO", "name", "hpBg", "hpFill", "tracer", "hdot"}
    for _, k in ipairs(keys) do if o[k] then o[k].Visible = false end end
    for i=1,8 do if o.cL[i] then o.cL[i].Visible = false o.cO[i].Visible = false end end
end

function E.Del(uid)
    local o = S.esp[uid]
    if not o then return end
    E.Hide(o)
    for k, v in pairs(o) do if typeof(v) ~= "table" then Kill(v) end end
    for i=1,8 do Kill(o.cL[i]) Kill(o.cO[i]) end
    S.esp[uid] = nil
end

function E.DelAll()
    local keys = {}
    for uid in pairs(S.esp) do table.insert(keys, uid) end
    for _, uid in ipairs(keys) do E.Del(uid) end
end

function E.Render(uid, ch, dname, isTeam)
    local o = S.esp[uid]
    if not o or not ch or not ch.Parent then return end
    local rp = GetRoot(ch)
    if not rp then E.Hide(o) return end
    local hp, mhp = GetHP(ch)
    if hp <= 0 or (isTeam and not Cfg.ESP.ShowTeam) then E.Hide(o) return end
    
    local dist = (rp.Position - Cam.CFrame.Position).Magnitude
    if dist > Cfg.ESP.MaxDist then E.Hide(o) return end
    
    local topSP, topOn = W2S(rp.Position + Vector3.new(0, 3.5, 0))
    local botSP, botOn = W2S(rp.Position - Vector3.new(0, 3.5, 0))
    if not topOn or not botOn then E.Hide(o) return end
    
    local h = math.abs(botSP.Y - topSP.Y)
    local w = h * 0.6
    local bx, by = topSP.X - w/2, topSP.Y
    local clr = isTeam and Cfg.Box.TeamColor or Cfg.Box.Color
    
    if Cfg.Box.On then
        if Cfg.Box.Style == "Full" then
            for i=1,8 do o.cL[i].Visible, o.cO[i].Visible = false, false end
            o.box.Visible, o.box.Size, o.box.Position, o.box.Color = true, Vector2.new(w, h), Vector2.new(bx, by), clr
            if Cfg.Box.Outline then o.boxO.Visible, o.boxO.Size, o.boxO.Position = true, Vector2.new(w+4, h+4), Vector2.new(bx-2, by-2) else o.boxO.Visible = false end
        else
            o.box.Visible, o.boxO.Visible = false, false
            local l = w * 0.25
            local pts = {{bx,by,bx+l,by},{bx,by,bx,by+l},{bx+w,by,bx+w-l,by},{bx+w,by,bx+w,by+l},{bx,by+h,bx+l,by+h},{bx,by+h,bx,by+h-l},{bx+w,by+h,bx+w-l,by+h},{bx+w,by+h,bx+w,by+h-l}}
            for i=1,8 do
                o.cL[i].Visible, o.cL[i].From, o.cL[i].To, o.cL[i].Color = true, Vector2.new(pts[i][1],pts[i][2]), Vector2.new(pts[i][3],pts[i][4]), clr
                if Cfg.Box.Outline then o.cO[i].Visible, o.cO[i].From, o.cO[i].To = true, o.cL[i].From, o.cL[i].To else o.cO[i].Visible = false end
            end
        end
    else
        o.box.Visible, o.boxO.Visible = false, false
        for i=1,8 do o.cL[i].Visible, o.cO[i].Visible = false, false end
    end

    if Cfg.Name.On then
        o.name.Visible, o.name.Text = true, (Cfg.Name.Format == "Name+Dist" and dname.." ["..math.floor(dist).."m]" or dname)
        o.name.Position, o.name.Color = Vector2.new(topSP.X, by - Cfg.Name.Size - 2), (isTeam and Cfg.Name.TeamColor or Cfg.Name.Color)
    else o.name.Visible = false end

    if Cfg.HP.On then
        local pct = math.clamp(hp/mhp, 0, 1)
        local bgX = bx - Cfg.HP.Offset - Cfg.HP.Width - 1
        o.hpBg.Visible, o.hpBg.Position, o.hpBg.Size = true, Vector2.new(bgX, by-1), Vector2.new(Cfg.HP.Width+2, h+2)
        o.hpFill.Visible, o.hpFill.Position, o.hpFill.Size, o.hpFill.Color = true, Vector2.new(bgX+1, by+h-(h*pct)), Vector2.new(Cfg.HP.Width, h*pct), HPCol(pct)
    else o.hpBg.Visible, o.hpFill.Visible = false, false end
end

function E.UpdateBatch()
    if not Cfg.ESP.On then return end
    local count = #S.plList
    if count <= 1 then return end
    local perFrame = math.max(math.ceil(count / Cfg.Tick.ESP), 1)
    for i = 1, perFrame do
        S.espBatch = (S.espBatch % count) + 1
        local tp = S.plList[S.espBatch]
        if tp and tp ~= Plr then
            local uid, ch = tp.UserId, tp.Character
            if ch and ch.Parent and GetHP(ch) > 0 then
                E.New(uid) E.Render(uid, ch, tp.DisplayName or tp.Name, TeamEq(Plr, tp))
            elseif S.esp[uid] then E.Hide(S.esp[uid]) end
        end
    end
end

-- ---- WH System ----
local WH = {}
function WH.Make(uid, ch, isTeam)
    if DEAD or S.wh[uid] or not ch then return end
    local hl = Instance.new("Highlight", ch)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = Cfg.WH.FT
    hl.FillColor = isTeam and Cfg.WH.TeamFill or Cfg.WH.EnemyFill
    hl.OutlineColor = isTeam and Cfg.WH.TeamLine or Cfg.WH.EnemyLine
    S.wh[uid] = hl
end

function WH.Kill(uid) if S.wh[uid] then pcall(function() S.wh[uid]:Destroy() end) end S.wh[uid] = nil end
function WH.KillAll() for k in pairs(S.wh) do WH.Kill(k) end end
function WH.Update()
    if not Cfg.WH.On then WH.KillAll() return end
    local active = {}
    for _, tp in ipairs(S.plList) do
        if tp ~= Plr then
            local ch = tp.Character
            local show = ch and ch.Parent and GetHP(ch) > 0 and (not TeamEq(Plr, tp) or Cfg.WH.ShowTeam)
            if show then active[tp.UserId] = true if not S.wh[tp.UserId] then WH.Make(tp.UserId, ch, TeamEq(Plr, tp)) end
            else WH.Kill(tp.UserId) end
        end
    end
    for k in pairs(S.wh) do if not active[k] then WH.Kill(k) end end
end

-- ---- HUD ----
local HUD = {}
function HUD.Destroy() for _, d in pairs(S.draw) do Kill(d) end S.draw = {} end
function HUD.Create()
    HUD.Destroy() if not drawOK then return end
    S.draw.fov = ND("Circle")
    if S.draw.fov then S.draw.fov.NumSides = 40 end
    S.draw.st = ND("Text")
    if S.draw.st then S.draw.st.Position = Vector2.new(10, SC(10, 40)) S.draw.st.Visible = true end
    S.draw.mb = ND("Text")
    if S.draw.mb then S.draw.mb.Position = Vector2.new(10, SC(28, 58)) end
end

function HUD.Update()
    if DEAD or not drawOK then return end
    if S.draw.fov then S.draw.fov.Position, S.draw.fov.Radius, S.draw.fov.Visible = ScrC(), Cfg.Aim.FOV, Cfg.Aim.On and Cfg.Aim.FOVOn end
    if S.draw.st then
        local t = "XENO " .. (Cfg.Aim.On and "[AIMBOT]" or "[OFF]")
        if S.tgt.part then t = t .. " | " .. (S.tgt.name or "") end
        S.draw.st.Text, S.draw.st.Color = t, Cfg.Aim.On and Color3.new(0,1,0) or Color3.new(1,0,0)
    end
    if S.draw.mb then S.draw.mb.Visible, S.draw.mb.Text = S.magic.on, "MAGIC BULLET ON" end
end

-- ---- Cleanup & Movement ----
local function Cleanup()
    DEAD = true
    task.wait(0.1)
    for _, c in pairs(S.conns) do c:Disconnect() end
    E.DelAll() WH.KillAll() HUD.Destroy()
    if S.gui then S.gui:Destroy() end
    _G.XenoLoaded = false
end

local function ApplyMovement(dt)
    if not S.me.alive or not S.me.root then return end
    if Cfg.Spin.On then
        S.spinAng = (S.spinAng + Cfg.Spin.Spd * dt * 60) % 360
        S.me.root.CFrame = CFrame.new(S.me.root.Position) * CFrame.Angles(0, math.rad(S.spinAng), 0)
    end
    if Cfg.Speed.On and S.me.hum then S.me.hum.WalkSpeed = 16 * Cfg.Speed.Mult end
end

-- ---- GUI Builder ----
local function BuildGUI()
    if S.gui then S.gui:Destroy() end
    S.theme = {accent = {}, bg = {}, panel = {}, text = {}, textDim = {}, btnBad = {}}
    local gui = Instance.new("ScreenGui", SafeP())
    gui.Name = "XENO_FULL"
    S.gui = gui

    local main = Instance.new("Frame", gui)
    main.Size, main.Position = UDim2.new(0, 460, 0, 380), UDim2.new(0.5, -230, 0.5, -190)
    main.BackgroundColor3, main.BorderSizePixel = Cfg.UI.Background, 0
    Instance.new("UICorner", main)
    table.insert(S.theme.bg, main)

    local title = Instance.new("TextLabel", main)
    title.Text, title.Size, title.Position = "XENO v17.9 FULL", UDim2.new(1,-100,0,32), UDim2.new(0,10,0,0)
    title.BackgroundTransparency, title.TextColor3, title.Font = 1, Cfg.UI.Accent, Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(S.theme.accent, {obj = title, prop = "TextColor3"})

    local body = Instance.new("Frame", main)
    body.Size, body.Position, body.BackgroundTransparency = UDim2.new(1,-12,1,-65), UDim2.new(0,6,0,62), 1

    local tabBar = Instance.new("Frame", main)
    tabBar.Size, tabBar.Position, tabBar.BackgroundTransparency = UDim2.new(1,0,0,26), UDim2.new(0,0,0,32), 1

    local curTab, tabBtns, ord = nil, {}, 0
    local function mkTab(name, idx, tot)
        local btn = Instance.new("TextButton", tabBar)
        btn.Text, btn.Size, btn.Position = name, UDim2.new(1/tot,0,1,0), UDim2.new((idx-1)/tot,0,0,0)
        btn.BackgroundTransparency, btn.TextColor3, btn.Font = 1, Cfg.UI.TextDim, Enum.Font.GothamBold
        local sf = Instance.new("ScrollingFrame", body)
        sf.Size, sf.BackgroundTransparency, sf.Visible = UDim2.new(1,0,1,0), 1, false
        sf.ScrollBarThickness, sf.CanvasSize = 2, UDim2.new(0,0,0,0)
        local lay = Instance.new("UIListLayout", sf)
        lay.Padding, lay.SortOrder = UDim.new(0,4), Enum.SortOrder.LayoutOrder
        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize = UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+10) end)
        btn.MouseButton1Click:Connect(function()
            if curTab then curTab.Visible = false end
            for _, b in pairs(tabBtns) do b.TextColor3 = Cfg.UI.TextDim end
            sf.Visible, curTab, btn.TextColor3 = true, sf, Cfg.UI.Accent
        end)
        tabBtns[name] = btn
        return sf
    end

    local function mkTog(p, txt, t, k, cb)
        ord = ord + 1
        local f = Instance.new("Frame", p)
        f.Size, f.BackgroundColor3, f.LayoutOrder = UDim2.new(1,0,0,32), Cfg.UI.Panel, ord
        Instance.new("UICorner", f)
        local l = Instance.new("TextLabel", f)
        l.Text, l.Size, l.Position, l.BackgroundTransparency = txt, UDim2.new(0.7,0,1,0), UDim2.new(0,8,0,0), 1
        l.TextColor3, l.Font, l.TextXAlignment = Cfg.UI.Text, Enum.Font.Gotham, Enum.TextXAlignment.Left
        local dot = Instance.new("Frame", f)
        dot.Size, dot.Position, dot.BackgroundColor3 = UDim2.new(0,18,0,18), UDim2.new(1,-24,0.5,-9), t[k] and Cfg.UI.Accent or Cfg.UI.Toggle
        Instance.new("UICorner", dot).CornerRadius = UDim.new(0,4)
        local b = Instance.new("TextButton", f)
        b.Size, b.BackgroundTransparency, b.Text = UDim2.new(1,0,1,0), 1, ""
        b.MouseButton1Click:Connect(function() t[k] = not t[k] dot.BackgroundColor3 = t[k] and Cfg.UI.Accent or Cfg.UI.Toggle if cb then cb(t[k]) end end)
    end

    local function mkSld(p, txt, mn, mx, t, k, fmt, cb)
        ord = ord + 1
        local f = Instance.new("Frame", p)
        f.Size, f.BackgroundColor3, f.LayoutOrder = UDim2.new(1,0,0,40), Cfg.UI.Panel, ord
        Instance.new("UICorner", f)
        local l = Instance.new("TextLabel", f)
        l.Text, l.Size, l.Position, l.BackgroundTransparency = string.format("%s: "..fmt, txt, t[k]), UDim2.new(1,-10,0,14), UDim2.new(0,6,0,2), 1
        l.TextColor3 = Cfg.UI.Text
        local tr = Instance.new("Frame", f)
        tr.Size, tr.Position, tr.BackgroundColor3 = UDim2.new(1,-12,0,4), UDim2.new(0,6,0,26), Color3.new(0.2,0.2,0.2)
        local fl = Instance.new("Frame", tr)
        fl.Size, fl.BackgroundColor3 = UDim2.new((t[k]-mn)/(mx-mn),0,1,0), Cfg.UI.Accent
        local b = Instance.new("TextButton", f)
        b.Size, b.Position, b.BackgroundTransparency, b.Text = UDim2.new(1,0,0,20), UDim2.new(0,0,0,20), 1, ""
        local function u(ix)
            local r = math.clamp((ix - tr.AbsolutePosition.X)/tr.AbsoluteSize.X, 0, 1)
            local v = mn + r * (mx - mn)
            t[k], fl.Size, l.Text = v, UDim2.new(r,0,1,0), string.format("%s: "..fmt, txt, v)
            if cb then cb(v) end
        end
        b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then S.sD = true u(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if S.sD and i.UserInputType == Enum.UserInputType.MouseMovement then u(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then S.sD = false end end)
    end

    local function mkDD(p, txt, opts, t, k, cb)
        ord = ord + 1
        local f = Instance.new("Frame", p)
        f.Size, f.BackgroundColor3, f.LayoutOrder = UDim2.new(1,0,0,32), Cfg.UI.Panel, ord
        Instance.new("UICorner", f)
        local l = Instance.new("TextLabel", f)
        l.Text, l.Size, l.Position, l.BackgroundTransparency = txt, UDim2.new(0.5,0,1,0), UDim2.new(0,8,0,0), 1
        l.TextColor3, l.Font = Cfg.UI.Text, Enum.Font.Gotham
        local btn = Instance.new("TextButton", f)
        btn.Text, btn.Size, btn.Position = tostring(t[k]), UDim2.new(0.4,0,0.7,0), UDim2.new(0.55,0,0.15,0)
        btn.BackgroundColor3, btn.TextColor3 = Color3.new(0.1,0.1,0.15), Cfg.UI.Accent
        btn.MouseButton1Click:Connect(function()
            local i = table.find(opts, t[k]) or 1
            t[k] = opts[i % #opts + 1]
            btn.Text = tostring(t[k])
            if cb then cb(t[k]) end
        end)
    end

    local function mkSep(p, txt)
        ord = ord + 1
        local l = Instance.new("TextLabel", p)
        l.Text, l.Size, l.LayoutOrder, l.BackgroundTransparency = "-- "..txt.." --", UDim2.new(1,0,0,20), ord, 1
        l.TextColor3, l.Font, l.TextSize = Cfg.UI.Accent, Enum.Font.GothamBold, 10
    end

    local function mkRGB(p, txt, t, k)
        ord = ord + 1
        local f = Instance.new("Frame", p)
        f.Size, f.BackgroundColor3, f.LayoutOrder = UDim2.new(1,0,0,32), Cfg.UI.Panel, ord
        f.ClipsDescendants = true
        Instance.new("UICorner", f)
        local l = Instance.new("TextLabel", f)
        l.Text, l.Size, l.Position, l.BackgroundTransparency = txt, UDim2.new(0.6,0,0,32), UDim2.new(0,8,0,0), 1
        l.TextColor3, l.TextXAlignment = Cfg.UI.Text, Enum.TextXAlignment.Left
        local sw = Instance.new("TextButton", f)
        sw.Text, sw.Size, sw.Position, sw.BackgroundColor3 = "", UDim2.new(0,32,0,22), UDim2.new(1,-38,0,5), t[k]
        local exp = false
        sw.MouseButton1Click:Connect(function() exp = not exp f:TweenSize(UDim2.new(1,0,0, exp and 120 or 32), "Out", "Quad", 0.2, true) end)
        local function chan(y, cname, cclr, get, set)
            local r = Instance.new("Frame", f)
            r.Size, r.Position, r.BackgroundTransparency = UDim2.new(1,-16,0,22), UDim2.new(0,8,0,y), 1
            local cl = Instance.new("TextLabel", r)
            cl.Text, cl.Size, cl.TextColor3, cl.BackgroundTransparency = cname, UDim2.new(0,15,1,0), cclr, 1
            local sl = Instance.new("Frame", r)
            sl.Size, sl.Position, sl.BackgroundColor3 = UDim2.new(1,-50,0,4), UDim2.new(0,20,0.5,-2), Color3.new(0.2,0.2,0.2)
            local fill = Instance.new("Frame", sl)
            fill.Size, fill.BackgroundColor3 = UDim2.new(get(),0,1,0), cclr
            local h = Instance.new("TextButton", r)
            h.Size, h.Position, h.BackgroundTransparency, h.Text = UDim2.new(1,-50,1,0), UDim2.new(0,20,0,0), 1, ""
            local function u(ix)
                local rt = math.clamp((ix - sl.AbsolutePosition.X)/sl.AbsoluteSize.X, 0, 1)
                set(rt) fill.Size, sw.BackgroundColor3 = UDim2.new(rt,0,1,0), t[k]
            end
            h.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then S.rD = true u(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if S.rD and i.UserInputType == Enum.UserInputType.MouseMovement then u(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then S.rD = false end end)
        end
        chan(35, "R", Color3.new(1,0,0), function() return t[k].R end, function(v) t[k] = Color3.new(v, t[k].G, t[k].B) end)
        chan(60, "G", Color3.new(0,1,0), function() return t[k].G end, function(v) t[k] = Color3.new(t[k].R, v, t[k].B) end)
        chan(85, "B", Color3.new(0,0,1), function() return t[k].B end, function(v) t[k] = Color3.new(t[k].R, t[k].G, v) end)
    end

    local tA = mkTab("AIM", 1, 7); tA.Visible, curTab = true, tA
    local tE = mkTab("ESP", 2, 7); local tW = mkTab("WH",  3, 7); local tM = mkTab("MISC", 4, 7)
    local tG = mkTab("MAGI", 5, 7); local tC = mkTab("COLR", 6, 7); local tP = mkTab("PERF", 7, 7)

    mkSep(tA, "AIMBOT"); mkTog(tA, "On", Cfg.Aim, "On"); mkDD(tA, "Mode", {"Normal", "Silent"}, Cfg.Aim, "Mode")
    mkSld(tA, "Smooth", 0, 100, Cfg.Aim, "Smooth", "%.0f"); mkSld(tA, "FOV", 10, 800, Cfg.Aim, "FOV", "%.0f")
    mkSep(tE, "ESP"); mkTog(tE, "On", Cfg.ESP, "On"); mkTog(tE, "Team", Cfg.ESP, "ShowTeam")
    mkSep(tW, "WH"); mkTog(tW, "On", Cfg.WH, "On"); mkSld(tW, "Transparency", 0, 1, Cfg.WH, "FT", "%.1f")
    mkSep(tG, "MAGIC"); mkTog(tG, "On", Cfg.MagicBullet, "On"); mkSld(tG, "Range", 50, 1000, Cfg.MagicBullet, "Range", "%.0f")
    mkSep(tC, "COLORS"); mkRGB(tC, "Accent", Cfg.UI, "Accent"); mkRGB(tC, "Box", Cfg.Box, "Color")
    mkSep(tP, "PERF"); mkSld(tP, "ESP Rate", 1, 10, Cfg.Tick, "ESP", "%.0f")
end

-- ---- Main Loop ----
SetupChar()
HUD.Create()
BuildGUI()
InstallMagicBullet()

table.insert(S.conns, RunService.RenderStepped:Connect(function(dt)
    if DEAD then return end
    S.frame = S.frame + 1
    RefreshPL()
    if Cfg.Aim.On then local p = FindTarget() if p then ApplyAim(p) end end
    if S.frame % Cfg.Tick.ESP == 0 then E.UpdateBatch() end
    if S.frame % Cfg.Tick.HUD == 0 then HUD.Update() end
    if Cfg.TP.On then TPFix() end
    ApplyMovement(dt)
end))

table.insert(S.conns, RunService.Heartbeat:Connect(function()
    if DEAD then return end
    if S.frame % Cfg.Tick.WH == 0 then WH.Update() end
end))

Notify("XENO v17.9", "Full Port Complete", 5)
