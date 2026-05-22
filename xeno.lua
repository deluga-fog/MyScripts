-- =====================================================================
-- XENO v17.5 [OFFICIAL FULL MONOLITH]
-- Engine: v10.1 (Drawing API, batching, reusable objects = NO FPS DROPS)
-- UI:     v16.1 (7 tabs, RGB picker, PERF tab, smoothness fixed)
-- Parser: works on Lua 5.1 (No compound ops, no continue, no task.wait)
-- =====================================================================

-- ---- Cleanup previous load ----
if _G.XenoLoaded and _G.XenoCleanup then 
    pcall(_G.XenoCleanup)
    wait(0.3)
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

-- ---- Executor probe ----
local Exec = {name = "Unknown", canSilent = false, canCoreGui = false}
pcall(function()
    if identifyexecutor then Exec.name = identifyexecutor() end
end)
pcall(function()
    local t = Instance.new("Folder")
    t.Parent = CoreGui
    t:Destroy()
    Exec.canCoreGui = true
end)
Exec.canSilent = (typeof(hookmetamethod) == "function") and (typeof(getnamecallmethod) == "function")

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
    if Exec.canCoreGui then return CoreGui end
    if typeof(gethui) == "function" then
        local o, r = pcall(gethui)
        if o and r then return r end
    end
    return Plr:WaitForChild("PlayerGui")
end

local function Protect(g)
    if typeof(syn) == "table" and syn.protect_gui then pcall(syn.protect_gui, g) end
    if typeof(protect_gui) == "function" then pcall(protect_gui, g) end
end

local function ND(t)
    if not drawOK then return nil end
    local s, d = pcall(Drawing.new, t)
    if not s or not d then return nil end
    pcall(function() d.Visible = false end)
    return d
end

local function Kill(d)
    if not d then return end
    pcall(function() d.Visible = false end)
    pcall(function() d:Remove() end)
    pcall(function() d:Destroy() end)
end

-- ---- Config ----
local Cfg = {
    Aim = {
        On = false,
        Mode = "Silent", -- Minimal, Normal, Silent
        Part = "Head",
        FOV = 120,
        FOVOn = true,
        Smooth = 30,
        Speed = 1.0,
        Prediction = true,
        PredFactor = 0.12,
        VelSmooth = 0.3,
        Sticky = true,
        Aim360 = false,
    },
    ESP = {
        On = false,
        MaxDist = 1500,
        ShowTeam = false,
    },
    Box = {On = true, Style = "Corner", Thickness = 1, Outline = true, Color = Color3.fromRGB(255, 50, 50), TeamColor = Color3.fromRGB(50, 255, 50), CL = 0.25},
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
    TP = {On = false, RotSpeed = 0.3, MaxAngle = 45, Dist = 30},
    Spin = {On = false, Spd = 10},
    Speed = {On = false, Mult = 1.5},
    Checks = {Team = true, Wall = true},
    Limits = {MaxDist = 800, MaxAngle = 90, MinDist = 5},
    MagicBullet = {On = false, Range = 300, Keybind = "E"},
    Tick = {ESP = 1, WH = 5, HUD = 2, Aim = 1},
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
    tgt = {part = nil, plr = nil, dist = 0, hp = 0, mhp = 0, name = "", vis = false, lastT = 0, lastPos = nil, vel = Vector3.new(0,0,0)},
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
    fpsLast = tick(),
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
    if not sp or not on then return 9999 end
    return (sp - ScrC()).Magnitude
end

local function HPCol(pct)
    if pct > 1 then pct = 1 end
    if pct < 0 then pct = 0 end
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
        local tp = part.Position
        local dir = tp - origin
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
    if Plr.Character then onChar(Plr.Character) end
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
    local hp, mhp = GetHP(ch)
    if hp <= 0 then return false end
    if tp and Cfg.Checks.Team and TeamEq(Plr, tp) then return false end
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

-- ---- PredPos Logic ----
local function PredPos(p)
    if not p then return Vector3.new(0,0,0) end
    if not Cfg.Aim.Prediction then return p.Position end
    local cur = p.Position
    if S.tgt.lastPos then
        local delta = (cur - S.tgt.lastPos) * 60
        S.tgt.vel = S.tgt.vel + (delta - S.tgt.vel) * Cfg.Aim.VelSmooth
    end
    S.tgt.lastPos = cur
    return cur + S.tgt.vel * Cfg.Aim.PredFactor
end

-- ---- Find Target ----
local function FindTarget()
    if not S.me.alive or not Cam then return nil, nil end
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
                if is360 then on = true; inF = true end
                
                if on and inF and vis then
                    S.tgt.part = p
                    S.tgt.lastT = tick()
                    S.tgt.vis = true
                    return p, S.tgt.plr
                end
                if tick() - S.tgt.lastT > 3 then
                    S.tgt.part = nil
                    S.tgt.plr = nil
                end
            end
        else
            S.tgt.part = nil
            S.tgt.plr = nil
        end
    end
    
    local bestP, bestPl, bestScore = nil, nil, -9999
    local players = S.plList
    for i = 1, #players do
        repeat
            local tp = players[i]
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
            
            local sc = 10000 - sd
            if sc > bestScore then
                bestScore = sc
                bestP = p
                bestPl = tp
            end
        until true
    end
    if bestP then S.tgt.vis = true end
    return bestP, bestPl
end

-- ---- Aim Methods ----
local function ApplyAim(p)
    if not p or not Cam then return end
    local t = PredPos(p)
    local c = Cam.CFrame.Position
    local d = t - c
    if d.Magnitude < 0.001 then return end
    local tcf = CFrame.new(c, c + d.Unit)
    
    if Cfg.Aim.Mode == "Snap" then
        Cam.CFrame = tcf
    elseif Cfg.Aim.Mode == "Normal" then
        local sm = math.clamp(Cfg.Aim.Smooth, 0, 100)
        local sp = math.clamp(Cfg.Aim.Speed, 0.01, 5)
        local amt = (1 / (1 + sm * 0.3)) * sp
        if amt > 1 then amt = 1 end
        Cam.CFrame = Cam.CFrame:Lerp(tcf, amt)
    end
end

-- ---- Silent Aim (__namecall only) ----
local function InstallSilent()
    if S.aim.hooked or not Exec.canSilent then return end
    local wrap = (newcclosure or function(f) return f end)
    
    pcall(function()
        local oldNc; oldNc = hookmetamethod(game, "__namecall", wrap(function(self, ...)
            if DEAD then return oldNc(self, ...) end
            local m = getnamecallmethod()
            
            if Cfg.Aim.On and Cfg.Silent.On and Cfg.Aim.Mode == "Silent" and S.tgt.part then
                local tp = PredPos(S.tgt.part)
                if tp then
                    if m == "Raycast" and self == WS then
                        local args = {...}
                        if #args >= 2 and typeof(args[1]) == "Vector3" then
                            local origin = args[1]
                            local dir = (tp - origin)
                            return oldNc(self, origin, dir.Unit * 1000, select(3, ...))
                        end
                    end
                    if (m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist") and self == WS then
                        local args = {...}
                        if typeof(args[1]) == "Ray" then
                            local origin = args[1].Origin
                            local dir = (tp - origin)
                            return oldNc(self, Ray.new(origin, dir.Unit * 1000), select(2, ...))
                        end
                    end
                end
            end
            return oldNc(self, ...)
        end))
        S.aim.hooked = true
    end)
end

-- ---- ESP Engine ----
local E = {}
function E.New(uid)
    if DEAD or S.esp[uid] or not drawOK then return end
    local o = {}
    o.box = ND("Square"); if o.box then o.box.Filled = false end
    o.boxO = ND("Square"); if o.boxO then o.boxO.Filled = false; o.boxO.Color = Color3.new(0,0,0) end
    o.cL = {}; o.cO = {}
    for i = 1, 8 do o.cL[i] = ND("Line"); o.cO[i] = ND("Line") end
    o.name = ND("Text"); if o.name then o.name.Center = true; o.name.Outline = true; o.name.Size = Cfg.Name.Size end
    o.hpBg = ND("Square"); if o.hpBg then o.hpBg.Filled = true end
    o.hpFill = ND("Square"); if o.hpFill then o.hpFill.Filled = true end
    o.tracer = ND("Line")
    o.hdot = ND("Circle"); if o.hdot then o.hdot.Filled = true; o.hdot.NumSides = 10 end
    S.esp[uid] = o
end

function E.Hide(o)
    if not o then return end
    local k = {"box", "boxO", "name", "hpBg", "hpFill", "tracer", "hdot"}
    for i = 1, #k do if o[k[i]] then o[k[i]].Visible = false end end
    for i = 1, 8 do
        if o.cL[i] then o.cL[i].Visible = false end
        if o.cO[i] then o.cO[i].Visible = false end
    end
end

function E.Del(uid)
    local o = S.esp[uid]; if not o then return end
    E.Hide(o)
    local k = {"box", "boxO", "name", "hpBg", "hpFill", "tracer", "hdot"}
    for i = 1, #k do Kill(o[k[i]]) end
    for i = 1, 8 do Kill(o.cL[i]); Kill(o.cO[i]) end
    S.esp[uid] = nil
end

function E.DelAll()
    for uid, _ in pairs(S.esp) do E.Del(uid) end
end

function E.Render(uid, ch, dname, isTeam)
    local o = S.esp[uid]; if not o then return end
    if not ch or not ch.Parent then E.Hide(o); return end
    local rp = GetRoot(ch); if not rp then E.Hide(o); return end
    local hp, mhp = GetHP(ch); if hp <= 0 then E.Hide(o); return end
    if isTeam and not Cfg.ESP.ShowTeam then E.Hide(o); return end
    
    local dist = 0
    if S.me.root then dist = (rp.Position - S.me.root.Position).Magnitude end
    if dist > Cfg.ESP.MaxDist then E.Hide(o); return end
    
    local head = ch:FindFirstChild("Head")
    local topY = (head and head.Position.Y + 1.2 or rp.Position.Y + 3)
    local botY = rp.Position.Y - 3
    local topSP, topOn = W2S(Vector3.new(rp.Position.X, topY, rp.Position.Z))
    local botSP, botOn = W2S(Vector3.new(rp.Position.X, botY, rp.Position.Z))
    
    if not topOn or not botOn then E.Hide(o); return end
    
    local h = math.abs(botSP.Y - topSP.Y)
    if h < 3 then E.Hide(o); return end
    local w = h * 0.6
    local bx = topSP.X - w / 2
    local by = topSP.Y
    
    local boxClr = (isTeam and Cfg.Box.TeamColor or Cfg.Box.Color)
    local nameClr = (isTeam and Cfg.Name.TeamColor or Cfg.Name.Color)
    
    if Cfg.Box.On then
        if Cfg.Box.Style == "Full" then
            for i = 1, 8 do o.cL[i].Visible = false; o.cO[i].Visible = false end
            o.box.Size = Vector2.new(w, h); o.box.Position = Vector2.new(bx, by); o.box.Color = boxClr; o.box.Thickness = Cfg.Box.Thickness; o.box.Visible = true
            if Cfg.Box.Outline then
                o.boxO.Size = Vector2.new(w + 4, h + 4); o.boxO.Position = Vector2.new(bx - 2, by - 2); o.boxO.Thickness = Cfg.Box.Thickness + 2; o.boxO.Visible = true
            else o.boxO.Visible = false end
        else
            o.box.Visible = false; o.boxO.Visible = false
            local cl = math.max(w, h) * Cfg.Box.CL
            local pts = {{bx,by,bx+cl,by},{bx,by,bx,by+cl},{bx+w,by,bx+w-cl,by},{bx+w,by,bx+w,by+cl},{bx,by+h,bx+cl,by+h},{bx,by+h,bx,by+h-cl},{bx+w,by+h,bx+w-cl,by+h},{bx+w,by+h,bx+w,by+h-cl}}
            for i = 1, 8 do
                o.cL[i].From = Vector2.new(pts[i][1], pts[i][2]); o.cL[i].To = Vector2.new(pts[i][3], pts[i][4]); o.cL[i].Color = boxClr; o.cL[i].Thickness = Cfg.Box.Thickness; o.cL[i].Visible = true
                if Cfg.Box.Outline then
                    o.cO[i].From = o.cL[i].From; o.cO[i].To = o.cL[i].To; o.cO[i].Color = Color3.new(0,0,0); o.cO[i].Thickness = Cfg.Box.Thickness + 2; o.cO[i].Visible = true
                else o.cO[i].Visible = false end
            end
        end
    end
    
    if Cfg.Name.On then
        local txt = (Cfg.Name.Format == "Name+Dist" and (dname .. " [" .. math.floor(dist) .. "m]") or dname)
        o.name.Text = txt; o.name.Color = nameClr; o.name.Size = Cfg.Name.Size; o.name.Position = Vector2.new(bx + w / 2, by - Cfg.Name.Size - 2); o.name.Visible = true
    else o.name.Visible = false end
    
    if Cfg.HP.On then
        local pct = math.clamp(hp / mhp, 0, 1)
        local bgX = bx - Cfg.HP.Offset - Cfg.HP.Width - 1
        o.hpBg.Position = Vector2.new(bgX, by - 1); o.hpBg.Size = Vector2.new(Cfg.HP.Width + 2, h + 2); o.hpBg.Color = Cfg.HP.BgColor; o.hpBg.Visible = true
        o.hpFill.Position = Vector2.new(bgX + 1, by + h - (h * pct)); o.hpFill.Size = Vector2.new(Cfg.HP.Width, h * pct); o.hpFill.Color = HPCol(pct); o.hpFill.Visible = true
    else o.hpBg.Visible = false; o.hpFill.Visible = false end
    
    if Cfg.Tracer.On then
        o.tracer.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y); o.tracer.To = botSP; o.tracer.Color = Cfg.Tracer.Color; o.tracer.Thickness = Cfg.Tracer.Thickness; o.tracer.Visible = true
    else o.tracer.Visible = false end
    
    if Cfg.HeadDot.On and head then
        local sp, on = W2S(head.Position)
        if sp and on then o.hdot.Position = sp; o.hdot.Radius = Cfg.HeadDot.Radius; o.hdot.Color = Cfg.HeadDot.Color; o.hdot.Visible = true
        else o.hdot.Visible = false end
    else o.hdot.Visible = false end
end

-- ---- WH Chams ----
local WH = {}
function WH.Update()
    if DEAD or not Cfg.WH.On then for uid, h in pairs(S.wh) do pcall(function() h:Destroy() end) end; S.wh = {}; return end
    local act = {}
    local players = S.plList
    for i = 1, #players do
        repeat
            local tp = players[i]
            if tp == Plr then break end
            local uid = tp.UserId; local ch = tp.Character; local isT = TeamEq(Plr, tp)
            local show = ch and ch.Parent and GetHP(ch) > 0
            if show and isT and not Cfg.WH.ShowTeam then show = false end
            if show then
                act[uid] = true
                if not S.wh[uid] then
                    local h = Instance.new("Highlight")
                    h.Adornee = ch; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillColor = (isT and Cfg.WH.TeamFill or Cfg.WH.EnemyFill)
                    h.OutlineColor = (isT and Cfg.WH.TeamLine or Cfg.WH.EnemyLine)
                    h.FillTransparency = Cfg.WH.FT; pcall(function() h.Parent = ch end); S.wh[uid] = h
                end
            else
                if S.wh[uid] then pcall(function() S.wh[uid]:Destroy() end); S.wh[uid] = nil end
            end
        until true
    end
end

-- ---- UI Building (FULL v16.1 Restore) ----
local function BuildGUI()
    if S.gui then pcall(function() S.gui:Destroy() end) end
    S.theme = {accent = {}, bg = {}, panel = {}, text = {}, textDim = {}, btnBad = {}}
    local MC, BG, PNL, TXT, TXTD, TOFF = Cfg.UI.Accent, Cfg.UI.Background, Cfg.UI.Panel, Cfg.UI.Text, Cfg.UI.TextDim, Cfg.UI.Toggle
    
    local gui = Instance.new("ScreenGui"); gui.Name = "XENO_" .. math.random(1e5, 9e5); gui.ResetOnSpawn = false; Protect(gui); gui.Parent = SafeP(); S.gui = gui
    
    local mW, mH = SC(460, 380), SC(380, 340)
    local main = Instance.new("Frame", gui); main.Name = "MainFrame"; main.Size = UDim2.new(0, mW, 0, mH); main.Position = UDim2.new(0.5, -mW / 2, 0.5, -mH / 2); main.BackgroundColor3 = BG; main.BorderSizePixel = 0; main.Visible = false; main.Active = true; main.ClipsDescendants = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8); table.insert(S.theme.bg, main)
    
    local tl = Instance.new("TextLabel", main); tl.Text = "XENO v17.5"; tl.Size = UDim2.new(1, -100, 0, 28); tl.Position = UDim2.new(0, 10, 0, 4); tl.BackgroundTransparency = 1; tl.TextColor3 = MC; tl.Font = Enum.Font.GothamBold; tl.TextSize = SC(15, 13); tl.TextXAlignment = Enum.TextXAlignment.Left; table.insert(S.theme.accent, {obj = tl, prop = "TextColor3"})
    
    local xb = Instance.new("TextButton", main); xb.Text = "X"; xb.Size = UDim2.new(0, 24, 0, 24); xb.Position = UDim2.new(1, -30, 0, 4); xb.BackgroundColor3 = Cfg.UI.ButtonBad; xb.TextColor3 = Color3.new(1, 1, 1); xb.TextSize = SC(14, 12); xb.Font = Enum.Font.GothamBold; xb.MouseButton1Click:Connect(function() main.Visible = false end); table.insert(S.theme.btnBad, xb)
    
    local function makeDraggable(target, handle)
        local dragS, startP; handle.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragS = i.Position; startP = target.Position end end)
        table.insert(S.conns, UIS.InputChanged:Connect(function(i) if dragS and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - dragS; target.Position = UDim2.new(startP.X.Scale, startP.X.Offset + d.X, startP.Y.Scale, startP.Y.Offset + d.Y) end end))
        table.insert(S.conns, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragS = nil end end))
    end
    makeDraggable(main, tl)
    
    local tabBar = Instance.new("Frame", main); tabBar.Size = UDim2.new(1, 0, 0, 26); tabBar.Position = UDim2.new(0, 0, 0, 32); tabBar.BackgroundTransparency = 1
    local body = Instance.new("Frame", main); body.Size = UDim2.new(1, -12, 1, -65); body.Position = UDim2.new(0, 6, 0, 62); body.BackgroundTransparency = 1; body.ClipsDescendants = true
    
    local curTab, tabBtns = nil, {}
    local function mkTab(name, idx, tot)
        local btn = Instance.new("TextButton", tabBar); btn.Text = name; btn.Size = UDim2.new(1/tot, 0, 1, 0); btn.Position = UDim2.new((idx-1)/tot, 0, 0, 0); btn.BackgroundTransparency = 1; btn.TextColor3 = TXTD; btn.Font = Enum.Font.GothamBold; btn.TextSize = SC(11, 10)
        local sf = Instance.new("ScrollingFrame", body); sf.Size = UDim2.new(1, 0, 1, 0); sf.BackgroundTransparency = 1; sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = MC; sf.BorderSizePixel = 0; sf.Visible = false; sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        local lay = Instance.new("UIListLayout", sf); lay.Padding = UDim.new(0, 4); lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8) end)
        btn.MouseButton1Click:Connect(function() if curTab then curTab.Visible = false end; sf.Visible = true; curTab = sf; for _, b in pairs(tabBtns) do b.TextColor3 = TXTD end; btn.TextColor3 = MC end)
        tabBtns[name] = btn; return sf
    end
    
    local ord = 0
    local function mkTog(p, txt, t, k, cb)
        ord = ord + 1; local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, SC(28, 34)); f.BackgroundColor3 = PNL; f.BorderSizePixel = 0; f.LayoutOrder = ord; table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f); l.Text = txt; l.Size = UDim2.new(0.75, 0, 1, 0); l.Position = UDim2.new(0, 8, 0, 0); l.BackgroundTransparency = 1; l.TextColor3 = TXT; l.Font = Enum.Font.Gotham; l.TextSize = SC(10, 11); l.TextXAlignment = Enum.TextXAlignment.Left; table.insert(S.theme.text, l)
        local sw = SC(18, 22); local dot = Instance.new("Frame", f); dot.Size = UDim2.new(0, sw, 0, sw); dot.Position = UDim2.new(1, -sw-6, 0.5, -sw/2); dot.BackgroundColor3 = (t[k] and MC or TOFF); Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
        local btn = Instance.new("TextButton", f); btn.Text = ""; btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
        btn.MouseButton1Click:Connect(function() t[k] = not t[k]; dot.BackgroundColor3 = (t[k] and Cfg.UI.Accent or Cfg.UI.Toggle); if cb then cb(t[k]) end end)
        table.insert(S.theme.accent, {obj = dot, prop = "BackgroundColor3", getCond = function() return t[k] end})
    end
    
    local function mkSld(p, txt, mn, mx, t, k, fmt, cb)
        ord = ord + 1; if not fmt then fmt = "%.1f" end
        local isInt = (fmt:find("%%d") or fmt:find("%%%.0f"))
        local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, SC(38, 44)); f.BackgroundColor3 = PNL; f.BorderSizePixel = 0; f.LayoutOrder = ord; table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f); l.Text = string.format("%s: " .. fmt, txt, t[k]); l.Size = UDim2.new(1, -10, 0, 14); l.Position = UDim2.new(0, 6, 0, 2); l.BackgroundTransparency = 1; l.TextColor3 = TXT; l.TextSize = SC(9, 10); l.Font = Enum.Font.Gotham; table.insert(S.theme.text, l)
        local tr = Instance.new("Frame", f); tr.Size = UDim2.new(1, -12, 0, SC(5, 7)); tr.Position = UDim2.new(0, 6, 0, SC(22, 24)); tr.BackgroundColor3 = Color3.fromRGB(40, 40, 50); tr.BorderSizePixel = 0
        local fl = Instance.new("Frame", tr); fl.Size = UDim2.new(math.clamp((t[k]-mn)/(mx-mn), 0, 1), 0, 1, 0); fl.BackgroundColor3 = MC; table.insert(S.theme.accent, {obj = fl, prop = "BackgroundColor3"})
        local drag = false; local hb = Instance.new("TextButton", f); hb.Text = ""; hb.Size = UDim2.new(1, 0, 1, 0); hb.BackgroundTransparency = 1
        local function upd(ix) local r = math.clamp((ix - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1); local v = mn + r*(mx-mn); if isInt then v = math.floor(v+0.5) end; t[k] = v; fl.Size = UDim2.new(r, 0, 1, 0); l.Text = string.format("%s: " .. fmt, txt, v); if cb then cb(v) end end
        hb.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; upd(i.Position.X) end end)
        table.insert(S.conns, UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end end))
        table.insert(S.conns, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end))
    end
    
    local function mkDD(p, txt, opts, t, k, cb)
        ord = ord + 1; local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, SC(28, 34)); f.BackgroundColor3 = PNL; f.BorderSizePixel = 0; f.LayoutOrder = ord; table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f); l.Text = txt; l.Size = UDim2.new(0.45, 0, 1, 0); l.Position = UDim2.new(0, 8, 0, 0); l.BackgroundTransparency = 1; l.TextColor3 = TXT; l.Font = Enum.Font.Gotham; table.insert(S.theme.text, l)
        local btn = Instance.new("TextButton", f); btn.Text = tostring(t[k]); btn.Size = UDim2.new(0.5, -6, 0.75, 0); btn.Position = UDim2.new(0.48, 0, 0.125, 0); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); btn.TextColor3 = MC; btn.Font = Enum.Font.GothamBold; table.insert(S.theme.accent, {obj = btn, prop = "TextColor3"})
        btn.MouseButton1Click:Connect(function() local idx = table.find(opts, t[k]) or 0; idx = (idx % #opts) + 1; t[k] = opts[idx]; btn.Text = tostring(opts[idx]); if cb then cb(opts[idx]) end end)
    end
    
    local function mkSep(p, txt)
        ord = ord + 1; local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, 18); f.BackgroundTransparency = 1; f.LayoutOrder = ord
        local l = Instance.new("TextLabel", f); l.Text = "-- " .. txt .. " --"; l.Size = UDim2.new(1, 0, 1, 0); l.TextColor3 = MC; l.Font = Enum.Font.GothamBold; table.insert(S.theme.accent, {obj = l, prop = "TextColor3"})
    end

    local function mkRGB(p, lab, t, k)
        ord = ord + 1; local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, 32); f.BackgroundColor3 = PNL; f.BorderSizePixel = 0; f.LayoutOrder = ord; f.ClipsDescendants = true; table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f); l.Text = lab; l.Size = UDim2.new(0.55, -8, 0, 32); l.Position = UDim2.new(0, 8, 0, 0); l.BackgroundTransparency = 1; l.TextColor3 = TXT; table.insert(S.theme.text, l)
        local sw = Instance.new("TextButton", f); sw.Text = ""; sw.Size = UDim2.new(0, 32, 0, 22); sw.Position = UDim2.new(1, -38, 0, 5); sw.BackgroundColor3 = t[k]; sw.AutoButtonColor = false; Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 4)
        local exp = false
        sw.MouseButton1Click:Connect(function() exp = not exp; f.Size = UDim2.new(1, 0, 0, (exp and 110 or 32)) end)
        local function cSld(y, ck, ccol)
            local row = Instance.new("Frame", f); row.Size = UDim2.new(1, -16, 0, 20); row.Position = UDim2.new(0, 8, 0, y); row.BackgroundTransparency = 1
            local b = Instance.new("TextButton", row); b.Size = UDim2.new(1, 0, 1, 0); b.BackgroundTransparency = 1; b.Text = ""
            local fl = Instance.new("Frame", row); fl.Size = UDim2.new(t[k][ck], 0, 1, 0); fl.BackgroundColor3 = ccol; fl.BorderSizePixel = 0; Instance.new("UICorner", fl).CornerRadius = UDim.new(0, 3)
            b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then local r = math.clamp((i.Position.X - b.AbsolutePosition.X)/b.AbsoluteSize.X, 0, 1); local old = t[k]; if ck=="R" then t[k] = Color3.new(r, old.G, old.B) elseif ck=="G" then t[k] = Color3.new(old.R, r, old.B) else t[k] = Color3.new(old.R, old.G, r) end; fl.Size = UDim2.new(r,0,1,0); sw.BackgroundColor3 = t[k] end end)
        end
        cSld(36, "R", Color3.new(1,0,0)); cSld(60, "G", Color3.new(0,1,0)); cSld(84, "B", Color3.new(0,0,1))
    end

    local tA = mkTab("AIM", 1, 7); local tE = mkTab("ESP", 2, 7); local tW = mkTab("WH", 3, 7); local tM = mkTab("MISC", 4, 7); local tMB = mkTab("MAGIC", 5, 7); local tC = mkTab("COLORS", 6, 7); local tT = mkTab("PERF", 7, 7)
    tabBtns["AIM"].TextColor3 = MC; tA.Visible = true; curTab = tA

    -- AIM TAB
    ord = 0; mkSep(tA, "AIMBOT"); mkTog(tA, "Enabled", Cfg, "On"); mkDD(tA, "Mode", {"Normal", "Snap", "Silent"}, Cfg.Aim, "Mode", function(v) if v=="Silent" then InstallSilent() end end)
    mkDD(tA, "Bone", {"Head", "UpperTorso", "HumanoidRootPart"}, Cfg.Aim, "Part"); mkTog(tA, "Sticky Target", Cfg.Aim, "Sticky"); mkTog(tA, "FOV Circle", Cfg.Aim, "FOVOn"); mkSld(tA, "FOV Radius", 10, 500, Cfg.Aim, "FOV", "%.0f")
    mkSep(tA, "SPEED / SMOOTH"); mkSld(tA, "Aim Speed", 0.1, 5.0, Cfg.Aim, "Speed"); mkSld(tA, "Smoothness", 0, 100, Cfg.Aim, "Smooth", "%.0f")
    mkSep(tA, "PREDICTION"); mkTog(tA, "Prediction", Cfg.Aim, "Prediction"); mkSld(tA, "Pred Factor", 0.05, 0.5, Cfg.Aim, "PredFactor")
    mkSep(tA, "CHECKS"); mkTog(tA, "Team Check", Cfg.Checks, "Team"); mkTog(tA, "Wall Check", Cfg.Checks, "Wall")

    -- ESP TAB
    ord = 0; mkSep(tE, "ESP"); mkTog(tE, "Enabled", Cfg.ESP, "On"); mkTog(tE, "Show Team", Cfg.ESP, "ShowTeam"); mkSld(tE, "Max Distance", 50, 3000, Cfg.ESP, "MaxDist", "%.0f")
    mkSep(tE, "BOX"); mkTog(tE, "Box", Cfg.Box, "On"); mkDD(tE, "Style", {"Corner", "Full"}, Cfg.Box, "Style"); mkSld(tE, "Thickness", 0.5, 5, Cfg.Box, "Thickness")
    mkSep(tE, "NAME"); mkTog(tE, "Name Tag", Cfg.Name, "On"); mkDD(tE, "Format", {"Name+Dist", "Name"}, Cfg.Name, "Format")
    mkSep(tE, "HEALTH BAR"); mkTog(tE, "Health Bar", Cfg.HP, "On"); mkSld(tE, "Bar Width", 1, 10, Cfg.HP, "Width", "%.0f")
    mkSep(tE, "TRACER"); mkTog(tE, "Tracer", Cfg.Tracer, "On")

    -- WH TAB
    ord = 0; mkSep(tW, "WALLHACK"); mkTog(tW, "Enabled", Cfg.WH, "On"); mkTog(tW, "Show Team", Cfg.WH, "ShowTeam"); mkSld(tW, "Fill Trans", 0, 1, Cfg.WH, "FT")

    -- MISC TAB
    ord = 0; mkSep(tM, "CAMERA"); mkTog(tM, "3rd Person Fix", Cfg.TP, "On"); mkSld(tM, "Distance", 10, 100, Cfg.TP, "Dist", "%.0f")
    mkSep(tM, "MOVEMENT"); mkTog(tM, "SpinBot", Cfg.Spin, "On"); mkSld(tM, "Spin Speed", 1, 50, Cfg.Spin, "Spd", "%.0f")
    mkTog(tM, "Speed Boost", Cfg.Speed, "On"); mkSld(tM, "Speed Mult", 1, 3, Cfg.Speed, "Mult")

    -- MAGIC BULLET
    ord = 0; mkSep(tMB, "MAGIC BULLET"); mkTog(tMB, "Enabled", Cfg.MagicBullet, "On"); mkSld(tMB, "Max Range", 50, 500, Cfg.MagicBullet, "Range", "%.0f")

    -- COLORS
    ord = 0; mkSep(tC, "THEME"); mkRGB(tC, "Accent", Cfg.UI, "Accent"); mkRGB(tC, "Background", Cfg.UI, "Background"); mkRGB(tC, "Panel", Cfg.UI, "Panel")
    mkSep(tC, "ESP COLORS"); mkRGB(tC, "Enemy Box", Cfg.Box, "Color"); mkRGB(tC, "Team Box", Cfg.Box, "TeamColor")

    -- PERF
    ord = 0; mkSep(tT, "TICK RATES"); mkSld(tT, "WH Update", 1, 60, Cfg.Tick, "WH", "%.0f"); mkSld(tT, "HUD Update", 1, 10, Cfg.Tick, "HUD", "%.0f")

    local obs = SC(36, 44); local ob = Instance.new("TextButton", gui); ob.Text = "X"; ob.Size = UDim2.new(0, obs, 0, obs); ob.Position = UDim2.new(0, 12, 0, 90); ob.BackgroundColor3 = MC; ob.TextColor3 = Color3.new(1,1,1); ob.Font = Enum.Font.GothamBlack; Instance.new("UICorner", ob).CornerRadius = UDim.new(1, 0)
    ob.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
end

-- ---- Main Loops ----
local function MainLoop()
    table.insert(S.conns, RunService.RenderStepped:Connect(function(dt)
        if DEAD then return end
        S.frame = S.frame + 1; Cam = WS.CurrentCamera
        
        -- Player list cache (every 0.5s)
        if tick() - S.plTick > 0.5 then S.plTick = tick(); S.plList = Players:GetPlayers() end
        
        -- Targeting Engine
        if Cfg.On and S.me.alive then
            local p, plr = FindTarget()
            if p then
                S.tgt.part = p; S.tgt.plr = plr; S.tgt.vis = true
                if Cfg.Aim.Mode ~= "Silent" then ApplyAim(p) end
            else S.tgt.vis = false end
        else S.tgt.vis = false end
        
        -- Movement Systems
        if Cfg.Spin.On and S.me.root then 
            S.spinAng = (S.spinAng + Cfg.Spin.Spd * dt * 60) % 360; 
            S.me.root.CFrame = CFrame.new(S.me.root.Position) * CFrame.Angles(0, math.rad(S.spinAng), 0) 
        end
        if Cfg.Speed.On and S.me.hum then 
            S.me.hum.WalkSpeed = 16 * Cfg.Speed.Mult 
        end
        
        -- ESP Engine
        if Cfg.ESP.On then
            local plrs = S.plList
            for i = 1, #plrs do
                local tp = plrs[i]
                if tp ~= Plr then
                    if not S.esp[tp.UserId] then E.New(tp.UserId) end
                    E.Render(tp.UserId, tp.Character, tp.Name, TeamEq(Plr, tp))
                end
            end
        end
        
        -- HUD & FOV Update
        if S.frame % Cfg.Tick.HUD == 0 then
            if S.draw.st then 
                local aimStr = (Cfg.On and Cfg.Aim.Mode:upper() or "OFF")
                S.draw.st.Text = "XENO | " .. aimStr 
                if S.tgt.part and Cfg.On then
                    S.draw.st.Text = S.draw.st.Text .. " | " .. S.tgt.name .. " " .. math.floor(GetHP(S.tgt.plr.Character)) .. "HP"
                end
                S.draw.st.Color = (Cfg.On and Color3.new(0,1,0) or Color3.new(1,0,0))
            end
            if S.draw.fov then 
                S.draw.fov.Position = ScrC(); 
                S.draw.fov.Radius = Cfg.Aim.FOV; 
                S.draw.fov.Visible = (Cfg.On and Cfg.Aim.FOVOn) 
                S.draw.fov.Color = Cfg.UI.Accent
            end
        end
        
        -- WH Heartbeat
        if S.frame % Cfg.Tick.WH == 0 then WH.Update() end
    end))
end

-- ---- Final Cleanup ----
local function Cleanup()
    DEAD = true
    for i = 1, #S.conns do pcall(function() S.conns[i]:Disconnect() end) end
    E.DelAll()
    for uid, h in pairs(S.wh) do pcall(function() h:Destroy() end) end
    if S.gui then pcall(function() S.gui:Destroy() end) end
    if S.me.hum then S.me.hum.WalkSpeed = 16 end
    _G.XenoLoaded = false; _G.XenoCleanup = nil
end
_G.XenoCleanup = Cleanup

-- ---- Initialize ----
SetupChar(); wait(0.5)
S.draw.fov = ND("Circle"); S.draw.st = ND("Text"); 
if S.draw.st then 
    S.draw.st.Position = Vector2.new(10, SC(10, 40)); 
    S.draw.st.Outline = true; 
    S.draw.st.Visible = true 
end
BuildGUI(); MainLoop()
if Cfg.Silent.On then InstallSilent() end

Notify("XENO v17.5", "Loaded successfully. Mode: Lua 5.1", 5)
