-- ---- Cleanup previous load ----
if _G.XenoLoaded and _G.XenoCleanup then _G.XenoCleanup() end
_G.XenoLoaded = true

-- ---- Services ----
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local WS         = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui    = game:GetService("CoreGui")
local VIM        = game:GetService("VirtualInputManager")

local Plr   = Players.LocalPlayer
local Cam   = WS.CurrentCamera
local Mouse = Plr:GetMouse()
local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function SC(p, m) if IsMobile then return m end return p end

-- ---- Executor probe (Eclipse) ----
local Exec = {name = "Eclipse", canSilent = false, canCoreGui = false, canClick = false}
pcall(function()
    if identifyexecutor then
        Exec.name = identifyexecutor()
    elseif getexecutorname then
        Exec.name = getexecutorname()
    end
end)
pcall(function()
    local t = Instance.new("Folder")
    t.Parent = CoreGui
    t:Destroy()
    Exec.canCoreGui = true
end)
Exec.canSilent = typeof(hookmetamethod) == "function"
Exec.canClick = typeof(mouse1press) == "function" or typeof(VIM) == "Instance"

local drawOK = false
pcall(function()
    local t = Drawing.new("Line")
    t.Visible = false
    t:Remove()
    drawOK = true
end)

local DEAD = false

-- ---- Debug Log System ----
local DebugLog = {
    entries = {},
    maxEntries = 100,
    hookStats = {
        installed = false,
        totalCalls = 0,
        wsCalls = 0,
        camCalls = 0,
        redirects = 0,
        errors = {},
        lastCallTime = 0,
    },
}

local function Log(category, message)
    local entry = string.format("[%.2f][%s] %s", tick() % 1000, category, tostring(message))
    table.insert(DebugLog.entries, entry)
    if #DebugLog.entries > DebugLog.maxEntries then
        table.remove(DebugLog.entries, 1)
    end
end

local function LogError(category, err)
    local entry = string.format("[%.2f][ERROR:%s] %s", tick() % 1000, category, tostring(err))
    table.insert(DebugLog.entries, entry)
    table.insert(DebugLog.hookStats.errors, entry)
    if #DebugLog.hookStats.errors > 20 then
        table.remove(DebugLog.hookStats.errors, 1)
    end
end

local function GetDebugReport()
    local lines = {}
    table.insert(lines, "===== XENO v17.7 DEBUG REPORT =====")
    table.insert(lines, "Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "")
    
    -- Executor info
    table.insert(lines, "-- EXECUTOR --")
    table.insert(lines, "Name: " .. tostring(Exec.name))
    table.insert(lines, "canSilent (hookmetamethod): " .. tostring(Exec.canSilent))
    table.insert(lines, "canCoreGui: " .. tostring(Exec.canCoreGui))
    table.insert(lines, "canClick: " .. tostring(Exec.canClick))
    table.insert(lines, "Drawing API: " .. tostring(drawOK))
    table.insert(lines, "")
    
    -- Available functions check
    table.insert(lines, "-- FUNCTIONS CHECK --")
    table.insert(lines, "hookmetamethod: " .. tostring(typeof(hookmetamethod) == "function"))
    table.insert(lines, "getnamecallmethod: " .. tostring(typeof(getnamecallmethod) == "function"))
    table.insert(lines, "newcclosure: " .. tostring(typeof(newcclosure) == "function"))
    table.insert(lines, "setclipboard: " .. tostring(typeof(setclipboard) == "function"))
    table.insert(lines, "")
    
    -- Hook stats
    table.insert(lines, "-- HOOK STATS --")
    table.insert(lines, "Hook installed: " .. tostring(DebugLog.hookStats.installed))
    table.insert(lines, "Total calls: " .. tostring(DebugLog.hookStats.totalCalls))
    table.insert(lines, "Workspace calls: " .. tostring(DebugLog.hookStats.wsCalls))
    table.insert(lines, "Camera calls: " .. tostring(DebugLog.hookStats.camCalls))
    table.insert(lines, "Redirects done: " .. tostring(DebugLog.hookStats.redirects))
    table.insert(lines, "Last call: " .. string.format("%.2f sec ago", tick() - DebugLog.hookStats.lastCallTime))
    table.insert(lines, "")
    
    -- Config state
    table.insert(lines, "-- CONFIG STATE --")
    table.insert(lines, "Aim.On: " .. tostring(Cfg.Aim.On))
    table.insert(lines, "Aim.Mode: " .. tostring(Cfg.Aim.Mode))
    table.insert(lines, "MagicBullet.On: " .. tostring(Cfg.MagicBullet.On))
    table.insert(lines, "S.magic.on: " .. tostring(S.magic.on))
    table.insert(lines, "S.magic.hookInstalled: " .. tostring(S.magic.hookInstalled))
    table.insert(lines, "")
    
    -- Target state
    table.insert(lines, "-- TARGET STATE --")
    table.insert(lines, "S.tgt.part: " .. tostring(S.tgt.part))
    table.insert(lines, "S.tgt.plr: " .. tostring(S.tgt.plr and S.tgt.plr.Name or "nil"))
    table.insert(lines, "S.tgt.vis: " .. tostring(S.tgt.vis))
    table.insert(lines, "S.me.alive: " .. tostring(S.me.alive))
    table.insert(lines, "S.me.root: " .. tostring(S.me.root))
    table.insert(lines, "")
    
    -- Errors
    if #DebugLog.hookStats.errors > 0 then
        table.insert(lines, "-- ERRORS --")
        for _, err in ipairs(DebugLog.hookStats.errors) do
            table.insert(lines, err)
        end
        table.insert(lines, "")
    end
    
    -- Recent log entries
    table.insert(lines, "-- RECENT LOGS --")
    local startIdx = math.max(1, #DebugLog.entries - 30)
    for i = startIdx, #DebugLog.entries do
        table.insert(lines, DebugLog.entries[i])
    end
    
    table.insert(lines, "")
    table.insert(lines, "===== END REPORT =====")
    
    return table.concat(lines, "\n")
end

local function CopyDebugLog()
    local report = GetDebugReport()
    -- Always print to console as reliable fallback
    print(report)
    
    if typeof(setclipboard) == "function" then
        local s, e = pcall(function()
            setclipboard(report)
        end)
        if s then
            Notify("DEBUG", "Log copied + Printed to console!", 3)
        else
            Notify("DEBUG", "Copy failed, check console (F9)!", 5)
            warn("Clipboard error:", e)
        end
    else
        Notify("DEBUG", "Printed to console (no clipboard)", 3)
    end
end

Log("INIT", "Script starting...")

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
    -- Eclipse не имеет syn.protect_gui и protect_gui
    -- GUI защищается через gethui / CoreGui parenting
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

-- ---- Click helpers (for TriggerBot) ----
local ClickMethod = "none"
local function InitClickMethod()
    -- try mouse1press first (most common)
    if typeof(mouse1press) == "function" and typeof(mouse1release) == "function" then
        local ok = pcall(function()
            -- test if it works without crashing
            return mouse1press and mouse1release
        end)
        if ok then
            ClickMethod = "mouse1press"
            return
        end
    end
    -- try VirtualInputManager
    if VIM and typeof(VIM) == "Instance" then
        local ok = pcall(function()
            return VIM:IsA("VirtualInputManager")
        end)
        if ok then
            ClickMethod = "vim"
            return
        end
    end
    -- try getting VIM differently
    pcall(function()
        local vim2 = game:GetService("VirtualInputManager")
        if vim2 then
            VIM = vim2
            ClickMethod = "vim"
        end
    end)
    if ClickMethod ~= "none" then return end
    -- no click method available
    ClickMethod = "none"
    Exec.canClick = false
end

local function DoClick()
    if ClickMethod == "none" then return false end
    
    local success = false
    
    if ClickMethod == "mouse1press" then
        local ok1 = pcall(function()
            mouse1press()
        end)
        if ok1 then
            success = true
            task.delay(0.03, function()
                pcall(function()
                    mouse1release()
                end)
            end)
        else
            -- method failed, disable it
            ClickMethod = "none"
            Exec.canClick = false
        end
    elseif ClickMethod == "vim" then
        local ok1 = pcall(function()
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        end)
        if ok1 then
            success = true
            task.delay(0.03, function()
                pcall(function()
                    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end)
            end)
        else
            -- method failed, disable it
            ClickMethod = "none"
            Exec.canClick = false
        end
    end
    
    return success
end

-- initialize click method on load
task.spawn(function()
    task.wait(0.1)
    InitClickMethod()
end)

Notify("XENO", "Loading v17.9 [Eclipse]...", 3)

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
        VisCheck = true,  -- отдельная проверка видимости для аима
    },
    TriggerBot = {
        On = false,
        Delay = 0.05,       -- задержка между выстрелами
        BurstCount = 1,     -- количество кликов за раз
        BurstDelay = 0.02,  -- задержка между кликами в burst
        OnlyADS = false,    -- только когда зумишь (RMB)
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
    Speed = {
        On = false,
        Mult = 1.5,
        Method = "CFrame",  -- "CFrame", "Velocity", "Teleport"
    },
    Checks = {Team = true, Wall = true},
    Limits = {MaxDist = 800, MaxAngle = 90, MinDist = 5},
    MagicBullet = {On = false, Range = 300},
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
    trigger = {lastShot = 0, shooting = false},
    speed = {bodyVel = nil, originalWS = 16},
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
    moveDir = Vector3.zero,
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

local function tclear(t)
    for k in pairs(t) do t[k] = nil end
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
        -- cleanup old speed hack objects
        if S.speed.bodyVel then
            pcall(function() S.speed.bodyVel:Destroy() end)
            S.speed.bodyVel = nil
        end
        -- reset speed state
        S.speed.originalWS = 16
        local hum, root
        pcall(function() hum  = ch:WaitForChild("Humanoid", 10) end)
        pcall(function() root = ch:WaitForChild("HumanoidRootPart", 10) end)
        if not hum or not root then return end
        S.me.hum  = hum
        S.me.root = root
        S.me.alive = true
        -- wait a bit for game to set proper WalkSpeed, then save it
        task.spawn(function()
            task.wait(0.5)
            if hum and hum.Parent and not DEAD then
                local ws = hum.WalkSpeed
                -- make sure we got a valid walkspeed (not 0, not too low)
                if ws >= 1 then
                    S.speed.originalWS = ws
                else
                    S.speed.originalWS = 16
                end
            end
        end)
        hum.Died:Connect(function()
            S.me.alive = false
            S.tgt.part = nil
            S.tgt.plr = nil
            S.tpRot = 0
            -- cleanup body velocity on death
            if S.speed.bodyVel then
                pcall(function() S.speed.bodyVel:Destroy() end)
                S.speed.bodyVel = nil
            end
            -- disable speed hack on death to prevent issues
            -- (user can re-enable after respawn)
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

-- ---- Player list cache (refresh every 0.5s) ----
local function RefreshPL()
    if tick() - S.plTick < 0.5 then return end
    S.plTick = tick()
    S.plList = Players:GetPlayers()
end

-- ---- Find Target ----
local function FindTarget()
    if not S.me.alive then return nil, nil end
    if not Cam then return nil, nil end
    local is360 = Cfg.Aim.Aim360
    local doVisCheck = Cfg.Aim.VisCheck  -- используем отдельную настройку для аима
    if Cfg.Aim.Sticky and S.tgt.part and S.tgt.plr then
        local ch = S.tgt.plr.Character
        if ch and ch.Parent and GetHP(ch) > 0 then
            local p = GetBone(ch)
            if p then
                local _, on = W2S(p.Position)
                local inF = true
                if Cfg.Aim.FOVOn then inF = SDist(p.Position) <= Cfg.Aim.FOV * 1.5 end
                local vis = true
                if doVisCheck then vis = CanSee(p, S.me.char) end
                if is360 then
                    on = true
                    inF = true
                end
                if on and inF and vis then
                    S.tgt.part = p
                    S.tgt.lastT = tick()
                    S.tgt.vis = true
                    return p, S.tgt.plr
                end
                if tick() - (S.tgt.lastT or 0) > 3 then
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
            if doVisCheck and not CanSee(p, S.me.char) then break end
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

local function MakeCF(p)
    if not p or not Cam then return nil end
    local t = PredPos(p)
    local c = Cam.CFrame.Position
    local d = t - c
    if d.Magnitude < 0.001 then return nil end
    return CFrame.lookAt(c, c + d.Unit)
end

local function ApplyAim(p)
    if not p or not Cam then return end
    
    -- Silent mode: don't move camera visually, hooks handle it
    if Cfg.Aim.Mode == "Silent" then
        -- just make sure hooks are installed
        if not S.magic.hookInstalled then
            InstallSilentHooks()
        end
        return
    end
    
    -- Minimal mode: snap instantly
    if Cfg.Aim.Mode == "Minimal" then
        local tcf = MakeCF(p)
        if tcf then
            Cam.CFrame = tcf
        end
        return
    end
    
    -- Normal mode: smooth aim
    local tcf = MakeCF(p)
    if not tcf then return end
    local sm = math.clamp(Cfg.Aim.Smooth, 0, 100)
    local sp = math.clamp(Cfg.Aim.Speed, 0.01, 5)
    local amt = (1 / (1 + sm * 0.3)) * sp
    amt = math.clamp(amt, 0.001, 1)
    Cam.CFrame = Cam.CFrame:Lerp(tcf, amt)
end

-- ---- Trigger Bot ----
local function UpdateTriggerBot()
    -- safety checks
    if DEAD then return end
    if not Cfg.TriggerBot.On then return end
    if ClickMethod == "none" then return end
    if not Cfg.Aim.On then return end
    if not S.tgt.part or not S.tgt.vis then return end
    if not S.me.alive then return end
    
    -- check ADS if required
    if Cfg.TriggerBot.OnlyADS then
        local ok, rmb = pcall(function()
            return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end)
        -- if check fails (mobile server), skip ADS requirement
        if ok and not rmb then return end
    end
    
    -- check if target is actually on screen center (within small threshold)
    local sp, on = W2S(S.tgt.part.Position)
    if not sp or not on then return end
    local center = ScrC()
    local distToCenter = (sp - center).Magnitude
    
    -- trigger only if crosshair is close to target (within ~30px)
    local threshold = 30
    if distToCenter > threshold then return end
    
    -- check delay
    local now = tick()
    if now - S.trigger.lastShot < Cfg.TriggerBot.Delay then return end
    
    -- fire!
    S.trigger.lastShot = now
    local burstCount = math.clamp(Cfg.TriggerBot.BurstCount, 1, 10)
    
    if burstCount == 1 then
        local ok = DoClick()
        if not ok then
            -- click failed, disable triggerbot
            Cfg.TriggerBot.On = false
        end
    else
        task.spawn(function()
            for i = 1, burstCount do
                if DEAD then break end
                if ClickMethod == "none" then break end
                local ok = DoClick()
                if not ok then
                    Cfg.TriggerBot.On = false
                    break
                end
                if i < burstCount then
                    task.wait(Cfg.TriggerBot.BurstDelay)
                end
            end
        end)
    end
end

-- ---- Silent Aim / Magic Bullet System ----
-- Silent Aim = подменяет камеру для игры, но визуально ты смотришь в другую сторону
-- Magic Bullet = перенаправляет Raycast/FindPartOnRay на голову врага

local function FindBestTarget()
    if not S.me.alive or not S.me.root then return nil, nil end
    local best, bestD, bestPart = nil, Cfg.MagicBullet.Range, nil
    
    for _, tp in ipairs(S.plList) do
        repeat
            if tp == Plr then break end
            local ch = tp.Character
            if not ch or not ch.Parent then break end
            if Cfg.Checks.Team and TeamEq(Plr, tp) then break end
            if GetHP(ch) <= 0 then break end
            
            -- get target bone based on aim settings
            local targetPart = ch:FindFirstChild(Cfg.Aim.Part) or ch:FindFirstChild("Head")
            if not targetPart then break end
            
            local d = (targetPart.Position - S.me.root.Position).Magnitude
            if d < bestD then
                if not Cfg.Checks.Wall or CanSee(targetPart, S.me.char) then
                    best = tp
                    bestD = d
                    bestPart = targetPart
                end
            end
        until true
    end
    return bestPart, best
end

local silentCache = {part = nil, tick = 0}

local function GetSilentAimTarget()
    -- FAST: use current aim target directly (updated every frame in main loop)
    -- no heavy FindBestTarget in hook — just return what we already have
    local p = S.tgt.part
    if p and p.Parent then
        return p
    end
    
    -- fallback: cached search, max once per 0.1s
    local now = tick()
    if now - silentCache.tick < 0.1 then
        local cp = silentCache.part
        if cp and cp.Parent then return cp end
        return nil
    end
    
    silentCache.tick = now
    local part, _ = FindBestTarget()
    silentCache.part = part
    return part
end

local function InstallSilentHooks()
    if S.magic.hookInstalled then return end
    
    if not Exec.canSilent then
        Notify("SILENT/MAGIC", "Not supported", 3)
        return
    end
    
    S.magic.hookInstalled = true
    DebugLog.hookStats.installed = true
    local wrap = newcclosure or function(f) return f end
    
    local cachedWS = WS
    local cachedCam = Cam
    
    pcall(function()
        local oldNc
        oldNc = hookmetamethod(game, "__namecall", wrap(function(self, ...)
            -- THE FASTEST POSSIBLE FILTER
            if self == cachedWS then
                local magicOn = S.magic.on
                if not magicOn then return oldNc(self, ...) end
                
                local method = getnamecallmethod()
                -- Only care about raycasting
                if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local args = {...}
                    local origin, direction, mag
                    
                    if method == "Raycast" then
                        origin = args[1]
                        direction = args[2]
                        if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return oldNc(self, ...) end
                        mag = direction.Magnitude
                    else
                        local ray = args[1]
                        if typeof(ray) ~= "Ray" then return oldNc(self, ...) end
                        origin = ray.Origin
                        direction = ray.Direction
                        mag = direction.Magnitude
                    end

                    -- Optimization: Only redirect "long" rays (bullets), ignore short ones (footsteps/interact)
                    if mag < 5 then return oldNc(self, ...) end

                    -- Check if origin is from player
                    local isPlayer = (S.me.root and (origin - S.me.root.Position).Magnitude < 50)
                                  or (cachedCam and (origin - cachedCam.CFrame.Position).Magnitude < 20)
                    
                    if isPlayer then
                        local tp = GetSilentAimTarget()
                        if tp then
                            local newDir = (tp.Position - origin).Unit * mag
                            DebugLog.hookStats.redirects = DebugLog.hookStats.redirects + 1
                            if method == "Raycast" then
                                return oldNc(self, origin, newDir, select(3, ...))
                            else
                                return oldNc(self, Ray.new(origin, newDir), select(2, ...))
                            end
                        end
                    end
                end
            elseif self == cachedCam then
                local silentOn = Cfg.Aim.On and Cfg.Aim.Mode == "Silent"
                if not silentOn then return oldNc(self, ...) end
                
                local method = getnamecallmethod()
                if method == "GetRenderCFrame" or method == "GetCFrame" or method == "get_CFrame" then
                    local tp = GetSilentAimTarget()
                    if tp then
                        DebugLog.hookStats.redirects = DebugLog.hookStats.redirects + 1
                        return CFrame.lookAt(cachedCam.CFrame.Position, tp.Position)
                    end
                end
            end
            
            return oldNc(self, ...)
        end))
    end)
    
    if not hookSuccess then
        Log("HOOK", "hookmetamethod FAILED: " .. tostring(hookErr))
        LogError("HOOK", hookErr)
        DebugLog.hookStats.installed = false
        S.magic.hookInstalled = false
        Notify("HOOK ERROR", tostring(hookErr):sub(1, 50), 5)
        return
    end
    
    -- Update cached camera when it changes
    table.insert(S.conns, WS:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        cachedCam = WS.CurrentCamera
        Log("HOOK", "Camera updated: " .. tostring(cachedCam))
    end))
    
    Log("HOOK", "Installation complete!")
    Notify("SILENT/MAGIC", "Hooks installed", 2)
end

local function ToggleMagicBullet()
    Log("MAGIC", "Toggle called, current: " .. tostring(S.magic.on))
    S.magic.on = not S.magic.on
    Cfg.MagicBullet.On = S.magic.on
    Log("MAGIC", "New state: " .. tostring(S.magic.on))
    if S.magic.on and not S.magic.hookInstalled then 
        Log("MAGIC", "Installing hooks...")
        InstallSilentHooks() 
    end
    if not S.magic.on then S.magic.target = nil end
end

-- Install hooks when Silent mode is selected
local function OnAimModeChanged(mode)
    Log("AIM", "Mode changed to: " .. tostring(mode))
    if mode == "Silent" and not S.magic.hookInstalled then
        Log("AIM", "Silent mode, installing hooks...")
        InstallSilentHooks()
    end
end

-- ---- 3rd Person Fix ----
local function TPFix()
    if not Cfg.TP.On then return end
    if not S.me.alive or not S.me.root or not S.me.root.Parent then
        S.tpRot = 0
        return
    end
    if not S.tgt.part then
        S.tpRot = 0
        return
    end
    local dist = (S.me.root.Position - Cam.CFrame.Position).Magnitude
    if dist > 10 then return end
    local cl = Cam.CFrame.LookVector
    local cf = Vector3.new(cl.X, 0, cl.Z)
    if cf.Magnitude < 0.001 then return end
    cf = cf.Unit
    local chl = S.me.root.CFrame.LookVector
    local chf = Vector3.new(chl.X, 0, chl.Z)
    if chf.Magnitude < 0.001 then return end
    chf = chf.Unit
    local ang = math.deg(math.acos(math.clamp(cf:Dot(chf), -1, 1)))
    if ang > Cfg.TP.MaxAngle then return end
    local tgt
    if cf:Dot(chf) > 0 then tgt = CFrame.new(S.me.root.Position, S.me.root.Position + cf)
    else tgt = CFrame.new(S.me.root.Position, S.me.root.Position - cf) end
    S.tpRot = math.min(S.tpRot + Cfg.TP.RotSpeed, 1)
    local nc = S.me.root.CFrame:Lerp(tgt, S.tpRot)
    local _, yaw, _ = nc:ToEulerAnglesYXZ()
    pcall(function() S.me.root.CFrame = CFrame.new(S.me.root.Position) * CFrame.Angles(0, yaw, 0) end)
end

-- ---- ESP (Drawing API, reusable objects) ----
local E = {}

function E.New(uid)
    if DEAD or S.esp[uid] or not drawOK then return end
    local o = {}
    o.box = ND("Square")
    if o.box then pcall(function() o.box.Filled = false end) end
    o.boxO = ND("Square")
    if o.boxO then
        pcall(function() o.boxO.Filled = false
        o.boxO.Color = Color3.new(0,0,0) end)
    end
    o.cL = {}
    o.cO = {}
    for i = 1, 8 do
        o.cL[i] = ND("Line")
        o.cO[i] = ND("Line")
    end
    o.name = ND("Text")
    if o.name then
        pcall(function() o.name.Center = true
        o.name.Outline = true
        o.name.Size = Cfg.Name.Size end)
    end
    o.hpBg = ND("Square")
    if o.hpBg then pcall(function() o.hpBg.Filled = true end) end
    o.hpFill = ND("Square")
    if o.hpFill then pcall(function() o.hpFill.Filled = true end) end
    o.tracer = ND("Line")
    o.hdot = ND("Circle")
    if o.hdot then
        pcall(function() o.hdot.Filled = true
        o.hdot.NumSides = 10 end)
    end
    S.esp[uid] = o
end

function E.Hide(o)
    if not o then return end
    local keys = {"box", "boxO", "name", "hpBg", "hpFill", "tracer", "hdot"}
    for _, k in ipairs(keys) do
        if o[k] then pcall(function() o[k].Visible = false end) end
    end
    if o.cL then
        for i = 1, 8 do
            if o.cL[i] then pcall(function() o.cL[i].Visible = false end) end
            if o.cO[i] then pcall(function() o.cO[i].Visible = false end) end
        end
    end
end

function E.Del(uid)
    local o = S.esp[uid]
    if not o then return end
    E.Hide(o)
    local keys = {"box", "boxO", "name", "hpBg", "hpFill", "tracer", "hdot"}
    for _, k in ipairs(keys) do Kill(o[k]) end
    if o.cL then
        for i = 1, 8 do
            Kill(o.cL[i])
            Kill(o.cO[i])
        end
    end
    S.esp[uid] = nil
end

function E.DelAll()
    local keys = {}
    for uid in pairs(S.esp) do table.insert(keys, uid) end
    for _, uid in ipairs(keys) do E.Del(uid) end
end

function E.Render(uid, ch, dname, isTeam)
    local o = S.esp[uid]
    if not o then return end
    if not ch or not ch.Parent then
        E.Hide(o)
        return
    end
    local rp = GetRoot(ch)
    if not rp then
        E.Hide(o)
        return
    end
    local hp, mhp = GetHP(ch)
    if hp <= 0 then
        E.Hide(o)
        return
    end
    if isTeam and not Cfg.ESP.ShowTeam then
        E.Hide(o)
        return
    end
    local rpPos = rp.Position
    local dist = 0
    if S.me.root then dist = (rpPos - S.me.root.Position).Magnitude end
    if dist > Cfg.ESP.MaxDist then
        E.Hide(o)
        return
    end
    local head = ch:FindFirstChild("Head")
    local topY = rpPos.Y + 3
    if head then topY = head.Position.Y + 1 end
    local botY = rpPos.Y - 3
    local topSP, topOn = W2S(Vector3.new(rpPos.X, topY, rpPos.Z))
    if not topOn or not topSP then
        E.Hide(o)
        return
    end
    local botSP, botOn = W2S(Vector3.new(rpPos.X, botY, rpPos.Z))
    if not botOn or not botSP then
        E.Hide(o)
        return
    end
    local h = math.abs(botSP.Y - topSP.Y)
    if h < 3 then
        E.Hide(o)
        return
    end
    local w = h * 0.6
    local bx = topSP.X - w / 2
    local by = topSP.Y
    local vp = Cam.ViewportSize
    if bx < -200 or bx > vp.X + 200 or by < -200 or by > vp.Y + 200 then
        E.Hide(o)
        return
    end
    local boxClr = Cfg.Box.Color
    local nameClr = Cfg.Name.Color
    if isTeam then
        boxClr = Cfg.Box.TeamColor
        nameClr = Cfg.Name.TeamColor
    end
    local distI = math.floor(dist)

    if Cfg.Box.On then
        if Cfg.Box.Style == "Full" then
            for i = 1, 8 do
                pcall(function() o.cL[i].Visible = false end)
                pcall(function() o.cO[i].Visible = false end)
            end
            pcall(function()
                o.box.Size = Vector2.new(w, h)
                o.box.Position = Vector2.new(bx, by)
                o.box.Color = boxClr
                o.box.Thickness = Cfg.Box.Thickness
                o.box.Visible = true
            end)
            if Cfg.Box.Outline then
                pcall(function()
                    o.boxO.Size = Vector2.new(w + 4, h + 4)
                    o.boxO.Position = Vector2.new(bx - 2, by - 2)
                    o.boxO.Color = Color3.new(0, 0, 0)
                    o.boxO.Thickness = Cfg.Box.Thickness + 2
                    o.boxO.Visible = true
                end)
            else
                pcall(function() o.boxO.Visible = false end)
            end
        else
            pcall(function() o.box.Visible = false end)
            pcall(function() o.boxO.Visible = false end)
            local cl = math.max(w, h) * 0.25
            local pts = {
                {bx, by, bx + cl, by},
                {bx, by, bx, by + cl},
                {bx + w, by, bx + w - cl, by},
                {bx + w, by, bx + w, by + cl},
                {bx, by + h, bx + cl, by + h},
                {bx, by + h, bx, by + h - cl},
                {bx + w, by + h, bx + w - cl, by + h},
                {bx + w, by + h, bx + w, by + h - cl}
            }
            for i = 1, 8 do
                pcall(function()
                    o.cL[i].From = Vector2.new(pts[i][1], pts[i][2])
                    o.cL[i].To   = Vector2.new(pts[i][3], pts[i][4])
                    o.cL[i].Color = boxClr
                    o.cL[i].Thickness = Cfg.Box.Thickness
                    o.cL[i].Visible = true
                end)
                if Cfg.Box.Outline then
                    pcall(function()
                        o.cO[i].From = o.cL[i].From
                        o.cO[i].To   = o.cL[i].To
                        o.cO[i].Color = Color3.new(0, 0, 0)
                        o.cO[i].Thickness = Cfg.Box.Thickness + 2
                        o.cO[i].Visible = true
                    end)
                else
                    pcall(function() o.cO[i].Visible = false end)
                end
            end
        end
    else
        pcall(function() o.box.Visible = false end)
        pcall(function() o.boxO.Visible = false end)
        for i = 1, 8 do
            pcall(function() o.cL[i].Visible = false end)
            pcall(function() o.cO[i].Visible = false end)
        end
    end

    if Cfg.Name.On and o.name then
        local txt = dname
        if Cfg.Name.Format == "Name+Dist" then txt = dname .. " [" .. distI .. "m]" end
        pcall(function()
            o.name.Text = txt
            o.name.Color = nameClr
            o.name.Size = Cfg.Name.Size
            o.name.Position = Vector2.new(bx + w / 2, by - Cfg.Name.Size - 2)
            o.name.Visible = true
        end)
    elseif o.name then
        pcall(function() o.name.Visible = false end)
    end

    if Cfg.HP.On then
        local pct = math.clamp(hp / math.max(mhp, 1), 0, 1)
        local hc = HPCol(pct)
        local bW = Cfg.HP.Width
        local off = Cfg.HP.Offset
        local bgX = bx - off - bW - 1
        local fH = math.max(h * pct, 1)
        pcall(function()
            o.hpBg.Position = Vector2.new(bgX, by - 1)
            o.hpBg.Size = Vector2.new(bW + 2, h + 2)
            o.hpBg.Color = Cfg.HP.BgColor
            o.hpBg.Visible = true
        end)
        pcall(function()
            o.hpFill.Position = Vector2.new(bgX + 1, by + h - fH)
            o.hpFill.Size = Vector2.new(bW, fH)
            o.hpFill.Color = hc
            o.hpFill.Visible = true
        end)
    else
        pcall(function() o.hpBg.Visible = false end)
        pcall(function() o.hpFill.Visible = false end)
    end

    if Cfg.Tracer.On and o.tracer then
        pcall(function()
            o.tracer.From = Vector2.new(vp.X / 2, vp.Y)
            o.tracer.To = botSP
            o.tracer.Color = Cfg.Tracer.Color
            o.tracer.Thickness = Cfg.Tracer.Thickness
            o.tracer.Visible = true
        end)
    elseif o.tracer then
        pcall(function() o.tracer.Visible = false end)
    end

    if Cfg.HeadDot.On and head and o.hdot then
        local sp, on = W2S(head.Position)
        if sp and on then
            pcall(function()
                o.hdot.Position = sp
                o.hdot.Radius = Cfg.HeadDot.Radius
                o.hdot.Color = Cfg.HeadDot.Color
                o.hdot.Visible = true
            end)
        else
            pcall(function() o.hdot.Visible = false end)
        end
    elseif o.hdot then
        pcall(function() o.hdot.Visible = false end)
    end
end

function E.UpdateBatch()
    if DEAD then return end
    if not Cfg.ESP.On then return end
    local count = #S.plList
    if count <= 1 then return end
    local rate = Cfg.Tick.ESP
    if rate < 1 then rate = 1 end
    local perFrame = math.max(math.ceil((count - 1) / rate), 1)
    local start = S.espBatch
    local done = 0
    for i = 1, count do
        if done >= perFrame then break end
        local idx = ((start + i - 2) % count) + 1
        local tp = S.plList[idx]
        if tp and tp ~= Plr then
            done = done + 1
            local uid = tp.UserId
            local ch = tp.Character
            local skip = false
            if not ch or not ch.Parent then skip = true end
            if not skip and GetHP(ch) <= 0 then skip = true end
            if skip then
                if S.esp[uid] then E.Hide(S.esp[uid]) end
            else
                if not S.esp[uid] then E.New(uid) end
                E.Render(uid, ch, tp.DisplayName or tp.Name, TeamEq(Plr, tp))
            end
        end
    end
    S.espBatch = (start + done) % math.max(count - 1, 1)
    -- prune disconnected
    if S.frame % 60 == 0 then
        for uid in pairs(S.esp) do
            local found = false
            for _, tp in ipairs(S.plList) do
                if tp.UserId == uid then
                    found = true
                    break
                end
            end
            if not found then E.Del(uid) end
        end
    end
end

-- ---- WH (Highlight) ----
local WH = {}

function WH.Make(uid, ch, isTeam)
    if DEAD or S.wh[uid] or not ch then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = ch
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    if isTeam then
        hl.FillColor = Cfg.WH.TeamFill
        hl.OutlineColor = Cfg.WH.TeamLine
    else
        hl.FillColor = Cfg.WH.EnemyFill
        hl.OutlineColor = Cfg.WH.EnemyLine
    end
    hl.FillTransparency = Cfg.WH.FT
    hl.OutlineTransparency = 0
    pcall(function() hl.Parent = ch end)
    S.wh[uid] = hl
end

function WH.Kill(uid)
    if S.wh[uid] then pcall(function() S.wh[uid]:Destroy() end) end
    S.wh[uid] = nil
end

function WH.KillAll()
    for k in pairs(S.wh) do pcall(function() S.wh[k]:Destroy() end) end
    tclear(S.wh)
end

function WH.Update()
    if DEAD then return end
    if not Cfg.WH.On then
        WH.KillAll()
        return
    end
    local active = {}
    for _, tp in ipairs(S.plList) do
        repeat
            if tp == Plr then break end
            local uid = tp.UserId
            local ch = tp.Character
            local isTeam = TeamEq(Plr, tp)
            local show = ch and ch.Parent and GetHP(ch) > 0
            if show and isTeam and not Cfg.WH.ShowTeam then show = false end
            if show then
                active[uid] = true
                if not S.wh[uid] then WH.Make(uid, ch, isTeam)
                else
                    pcall(function()
                        if isTeam then
                            S.wh[uid].FillColor = Cfg.WH.TeamFill
                            S.wh[uid].OutlineColor = Cfg.WH.TeamLine
                        else
                            S.wh[uid].FillColor = Cfg.WH.EnemyFill
                            S.wh[uid].OutlineColor = Cfg.WH.EnemyLine
                        end
                        S.wh[uid].FillTransparency = Cfg.WH.FT
                    end)
                end
            else
                WH.Kill(uid)
            end
        until true
    end
    for k in pairs(S.wh) do
        if not active[k] then WH.Kill(k) end
    end
end

-- ---- HUD (Drawing API) ----
local HUD = {}

function HUD.Destroy()
    for _, d in pairs(S.draw) do Kill(d) end
    S.draw = {}
end

function HUD.Create()
    HUD.Destroy()
    if not drawOK then return end
    S.draw.fov = ND("Circle")
    if S.draw.fov then
        pcall(function() 
            S.draw.fov.Filled = false
            S.draw.fov.NumSides = 60
            S.draw.fov.Thickness = 1
        end)
    end
    S.draw.line = ND("Line")
    S.draw.dot = ND("Circle")
    if S.draw.dot then
        pcall(function() S.draw.dot.Filled = true
        S.draw.dot.NumSides = 10 end)
    end
    S.draw.st = ND("Text")
    if S.draw.st then
        pcall(function()
            S.draw.st.Center = false
            S.draw.st.Outline = true
            S.draw.st.Size = SC(14, 12)
            S.draw.st.Position = Vector2.new(10, SC(10, 40))
            S.draw.st.Visible = true
        end)
    end
    S.draw.mb = ND("Text")
    if S.draw.mb then
        pcall(function()
            S.draw.mb.Center = false
            S.draw.mb.Outline = true
            S.draw.mb.Size = SC(12, 11)
            S.draw.mb.Position = Vector2.new(10, SC(28, 58))
            S.draw.mb.Color = Color3.fromRGB(255, 80, 80)
        end)
    end
    S.draw.tb = ND("Text")
    if S.draw.tb then
        pcall(function()
            S.draw.tb.Center = false
            S.draw.tb.Outline = true
            S.draw.tb.Size = SC(12, 11)
            S.draw.tb.Position = Vector2.new(10, SC(44, 74))
            S.draw.tb.Color = Color3.fromRGB(255, 200, 50)
        end)
    end
end

function HUD.Update()
    if DEAD or not drawOK then return end
    local c = ScrC()
    local d = S.draw
    if d.fov then
        pcall(function()
            d.fov.Position = c
            d.fov.Radius = Cfg.Aim.FOV
            d.fov.Color = Cfg.UI.Accent
            d.fov.Filled = false
            d.fov.Transparency = 0.3
            d.fov.Thickness = 1
            d.fov.Visible = Cfg.Aim.On and Cfg.Aim.FOVOn
        end)
    end
    if d.st then
        local modes = {Minimal = "MIN", Normal = "NORM", Silent = "SIL"}
        local m = modes[Cfg.Aim.Mode] or "?"
        local t = "XENO "
        if Cfg.Aim.On then t = t .. "[" .. m .. "]" else t = t .. "[OFF]" end
        if S.tgt.part and Cfg.Aim.On then
            t = t .. string.format(" | %s %.0fHP", S.tgt.name, S.tgt.hp)
        end
        pcall(function()
            d.st.Text = t
            if Cfg.Aim.On then d.st.Color = Color3.fromRGB(100, 255, 100)
            else d.st.Color = Color3.fromRGB(255, 100, 100) end
        end)
    end
    if d.mb then
        if S.magic.on then
            pcall(function()
                d.mb.Text = "MAGIC BULLET ON"
                d.mb.Visible = true
            end)
        else
            pcall(function() d.mb.Visible = false end)
        end
    end
    if d.tb then
        if Cfg.TriggerBot.On then
            local status = "TRIGGER BOT ON"
            if ClickMethod == "none" then
                status = "TRIGGER BOT [NO CLICK]"
            end
            pcall(function()
                d.tb.Text = status
                if ClickMethod == "none" then
                    d.tb.Color = Color3.fromRGB(255, 100, 100)
                else
                    d.tb.Color = Color3.fromRGB(255, 200, 50)
                end
                d.tb.Visible = true
            end)
        else
            pcall(function() d.tb.Visible = false end)
        end
    end
    if Cfg.Aim.On and S.tgt.part and S.tgt.vis then
        local sp, on = W2S(S.tgt.part.Position)
        if sp and on then
            pcall(function()
                d.line.From = c
                d.line.To = sp
                d.line.Color = Color3.new(1, 1, 1)
                d.line.Thickness = 1.5
                d.line.Visible = true
            end)
            pcall(function()
                d.dot.Position = sp
                d.dot.Color = Color3.fromRGB(255, 50, 50)
                d.dot.Radius = SC(5, 8)
                d.dot.Visible = true
            end)
        else
            pcall(function() d.line.Visible = false end)
            pcall(function() d.dot.Visible = false end)
        end
    else
        pcall(function() d.line.Visible = false end)
        pcall(function() d.dot.Visible = false end)
    end
end

-- ---- Cleanup ----
local function Cleanup()
    DEAD = true
    task.wait(0.05)
    for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end
    S.conns = {}
    pcall(E.DelAll)
    pcall(WH.KillAll)
    pcall(HUD.Destroy)
    if S.gui then pcall(function() S.gui:Destroy() end) end
    -- cleanup speed hack
    if S.speed.bodyVel then 
        pcall(function() S.speed.bodyVel:Destroy() end) 
        S.speed.bodyVel = nil
    end
    if S.me.hum and S.me.hum.Parent then 
        pcall(function() 
            local ws = S.speed.originalWS
            if not ws or ws < 1 then ws = 16 end
            S.me.hum.WalkSpeed = ws 
        end) 
    end
    _G.XenoLoaded = false
    _G.XenoCleanup = nil
end

-- ---- Movement (improved speed hack methods) ----
local function GetMoveDirection()
    if not S.me.hum or not S.me.root then return Vector3.zero end
    local moveDir = S.me.hum.MoveDirection
    if moveDir.Magnitude < 0.01 then return Vector3.zero end
    return moveDir
end

local function CleanupSpeedHack()
    -- remove body velocity if exists
    if S.speed.bodyVel then
        pcall(function() S.speed.bodyVel:Destroy() end)
        S.speed.bodyVel = nil
    end
    -- restore walkspeed
    if S.me.hum and S.me.hum.Parent then
        pcall(function()
            if S.speed.originalWS and S.speed.originalWS >= 1 then
                S.me.hum.WalkSpeed = S.speed.originalWS
            else
                S.me.hum.WalkSpeed = 16
            end
        end)
    end
end

local function ApplyMovement(dt)
    if not S.me.alive or not S.me.root or not S.me.root.Parent then 
        CleanupSpeedHack()
        return 
    end
    if not S.me.hum or not S.me.hum.Parent then
        CleanupSpeedHack()
        return
    end
    
    -- SpinBot
    if Cfg.Spin.On then
        S.spinAng = (S.spinAng + Cfg.Spin.Spd * dt * 60) % 360
        pcall(function()
            S.me.root.CFrame = CFrame.new(S.me.root.Position) * CFrame.Angles(0, math.rad(S.spinAng), 0)
        end)
    end
    
    -- ensure originalWS is valid
    if not S.speed.originalWS or S.speed.originalWS < 1 then
        S.speed.originalWS = 16
    end
    
    -- Speed Hack (multiple methods)
    if Cfg.Speed.On then
        local mult = Cfg.Speed.Mult
        local method = Cfg.Speed.Method
        local moveDir = GetMoveDirection()
        local baseSpeed = S.speed.originalWS
        
        if method == "CFrame" then
            -- CFrame-based movement (less detectable)
            -- Only apply extra speed, doesn't touch WalkSpeed
            if moveDir.Magnitude > 0.1 then
                local extraSpeed = (mult - 1) * baseSpeed * dt
                local offset = moveDir * extraSpeed
                pcall(function()
                    S.me.root.CFrame = S.me.root.CFrame + offset
                end)
            end
            -- cleanup any leftover body velocity
            if S.speed.bodyVel and S.speed.bodyVel.Parent then
                pcall(function() S.speed.bodyVel:Destroy() end)
                S.speed.bodyVel = nil
            end
            
        elseif method == "Velocity" then
            -- BodyVelocity method
            if moveDir.Magnitude > 0.1 then
                if not S.speed.bodyVel or not S.speed.bodyVel.Parent then
                    pcall(function()
                        -- remove old one first
                        if S.speed.bodyVel then S.speed.bodyVel:Destroy() end
                        S.speed.bodyVel = Instance.new("BodyVelocity")
                        S.speed.bodyVel.MaxForce = Vector3.new(100000, 0, 100000)
                        S.speed.bodyVel.P = 10000
                        S.speed.bodyVel.Parent = S.me.root
                    end)
                end
                if S.speed.bodyVel and S.speed.bodyVel.Parent then
                    local targetVel = moveDir * baseSpeed * mult
                    pcall(function()
                        S.speed.bodyVel.Velocity = Vector3.new(targetVel.X, S.me.root.Velocity.Y, targetVel.Z)
                    end)
                end
            else
                -- not moving, zero out velocity but keep object
                if S.speed.bodyVel and S.speed.bodyVel.Parent then
                    pcall(function()
                        S.speed.bodyVel.Velocity = Vector3.zero
                    end)
                end
            end
            
        elseif method == "Teleport" then
            -- Micro-teleport method (most aggressive, can look laggy)
            if moveDir.Magnitude > 0.1 then
                local extraSpeed = (mult - 1) * baseSpeed * dt
                local offset = moveDir * extraSpeed
                pcall(function()
                    S.me.root.CFrame = S.me.root.CFrame + offset
                end)
            end
            -- cleanup any leftover body velocity
            if S.speed.bodyVel and S.speed.bodyVel.Parent then
                pcall(function() S.speed.bodyVel:Destroy() end)
                S.speed.bodyVel = nil
            end
        end
    else
        -- Speed hack off - cleanup
        CleanupSpeedHack()
    end
end

-- ---- GUI ----
local function BuildGUI()
    if S.gui then pcall(function() S.gui:Destroy() end) end
    S.theme = {accent = {}, bg = {}, panel = {}, text = {}, textDim = {}, btnBad = {}}
    local MC   = Cfg.UI.Accent
    local BG   = Cfg.UI.Background
    local PNL  = Cfg.UI.Panel
    local TXT  = Cfg.UI.Text
    local TXTD = Cfg.UI.TextDim
    local TOFF = Cfg.UI.Toggle

    local gui = Instance.new("ScreenGui")
    gui.Name = "X_" .. math.random(100000, 900000)
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
    Protect(gui)
    gui.Parent = SafeP()
    S.gui = gui

    local mW = SC(460, 380)
    local mH = SC(400, 360)
    local main = Instance.new("Frame", gui)
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, mW, 0, mH)
    main.Position = UDim2.new(0.5, -mW / 2, 0.5, -mH / 2)
    main.BackgroundColor3 = BG
    main.BorderSizePixel = 0
    main.Visible = false
    main.Active = true
    main.ClipsDescendants = true
    local mc = Instance.new("UICorner", main)
    mc.CornerRadius = UDim.new(0, 8)
    table.insert(S.theme.bg, main)

    local tl = Instance.new("TextButton", main)
    tl.Text = "XENO v17.9 [Eclipse]"
    tl.Size = UDim2.new(1, -100, 0, 28)
    tl.Position = UDim2.new(0, 10, 0, 4)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = MC
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = SC(15, 13)
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Active = true
    tl.AutoButtonColor = false
    table.insert(S.theme.accent, {obj = tl, prop = "TextColor3"})
    
    -- Hidden feature: click title to copy log
    tl.Activated:Connect(function()
        CopyDebugLog()
    end)

    local perfBtn = Instance.new("TextButton", main)
    perfBtn.Text = "P"
    perfBtn.Size = UDim2.new(0, 24, 0, 24)
    perfBtn.Position = UDim2.new(1, -60, 0, 4)
    perfBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 140)
    perfBtn.TextColor3 = Color3.new(1, 1, 1)
    perfBtn.TextSize = SC(14, 12)
    perfBtn.Font = Enum.Font.GothamBold
    perfBtn.AutoButtonColor = false
    local pbc = Instance.new("UICorner", perfBtn)
    pbc.CornerRadius = UDim.new(0, 5)

    local xb = Instance.new("TextButton", main)
    xb.Text = "X"
    xb.Size = UDim2.new(0, 24, 0, 24)
    xb.Position = UDim2.new(1, -30, 0, 4)
    xb.BackgroundColor3 = Cfg.UI.ButtonBad
    xb.TextColor3 = Color3.new(1, 1, 1)
    xb.TextSize = SC(14, 12)
    xb.Font = Enum.Font.GothamBold
    xb.AutoButtonColor = false
    local xbc = Instance.new("UICorner", xb)
    xbc.CornerRadius = UDim.new(0, 5)
    xb.MouseButton1Click:Connect(function() main.Visible = false end)
    table.insert(S.theme.btnBad, xb)

    -- ==== makeDraggable: reusable drag for any frame ====
    local function makeDraggable(target, handle)
        local h = handle or target
        local dragS, startP
        local function onBegin(i)
            local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
            local t2 = i.UserInputType == Enum.UserInputType.Touch
            if t1 or t2 then
                dragS = i.Position
                startP = target.Position
            end
        end
        h.InputBegan:Connect(onBegin)
        table.insert(S.conns, UIS.InputChanged:Connect(function(i)
            if not dragS then return end
            local t1 = i.UserInputType == Enum.UserInputType.MouseMovement
            local t2 = i.UserInputType == Enum.UserInputType.Touch
            if t1 or t2 then
                local d = i.Position - dragS
                target.Position = UDim2.new(startP.X.Scale, startP.X.Offset + d.X, startP.Y.Scale, startP.Y.Offset + d.Y)
            end
        end))
        table.insert(S.conns, UIS.InputEnded:Connect(function(i)
            local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
            local t2 = i.UserInputType == Enum.UserInputType.Touch
            if t1 or t2 then dragS = nil end
        end))
    end
    makeDraggable(main, tl)
    makeDraggable(main, main)

    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1, 0, 0, 26)
    tabBar.Position = UDim2.new(0, 0, 0, 32)
    tabBar.BackgroundTransparency = 1

    local body = Instance.new("Frame", main)
    body.Size = UDim2.new(1, -12, 1, -65)
    body.Position = UDim2.new(0, 6, 0, 62)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true

    local curTab = nil
    local tabBtns = {}
    local function mkTab(name, idx, tot)
        local btn = Instance.new("TextButton", tabBar)
        btn.Text = name
        btn.Size = UDim2.new(1 / tot, 0, 1, 0)
        btn.Position = UDim2.new((idx - 1) / tot, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.TextColor3 = TXTD
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = SC(11, 10)
        btn.AutoButtonColor = false
        local sf = Instance.new("ScrollingFrame", body)
        sf.Size = UDim2.new(1, 0, 1, 0)
        sf.BackgroundTransparency = 1
        sf.ScrollBarThickness = 2
        sf.ScrollBarImageColor3 = MC
        sf.BorderSizePixel = 0
        sf.Visible = false
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        local lay = Instance.new("UIListLayout", sf)
        lay.Padding = UDim.new(0, 4)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sf.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8)
        end)
        btn.MouseButton1Click:Connect(function()
            if curTab then curTab.Visible = false end
            sf.Visible = true
            curTab = sf
            for _, b in pairs(tabBtns) do b.TextColor3 = TXTD end
            btn.TextColor3 = MC
        end)
        tabBtns[name] = btn
        return sf
    end

    local ord = 0
    local function nOrd()
        ord = ord + 1
        return ord
    end

    local function mkTog(p, txt, t, k, cb)
        local f = Instance.new("Frame", p)
        f.Size = UDim2.new(1, 0, 0, SC(28, 34))
        f.BackgroundColor3 = PNL
        f.BorderSizePixel = 0
        f.LayoutOrder = nOrd()
        local fc = Instance.new("UICorner", f)
        fc.CornerRadius = UDim.new(0, 5)
        table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f)
        l.Text = txt
        l.Size = UDim2.new(0.75, 0, 1, 0)
        l.Position = UDim2.new(0, 8, 0, 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = TXT
        l.Font = Enum.Font.Gotham
        l.TextSize = SC(10, 11)
        l.TextXAlignment = Enum.TextXAlignment.Left
        table.insert(S.theme.text, l)
        local sw = SC(18, 22)
        local dot = Instance.new("Frame", f)
        dot.Size = UDim2.new(0, sw, 0, sw)
        dot.Position = UDim2.new(1, -sw - 6, 0.5, -sw / 2)
        if t[k] then dot.BackgroundColor3 = MC else dot.BackgroundColor3 = TOFF end
        dot.BorderSizePixel = 0
        local dc = Instance.new("UICorner", dot)
        dc.CornerRadius = UDim.new(0, 4)
        local btn = Instance.new("TextButton", f)
        btn.Text = ""
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.MouseButton1Click:Connect(function()
            t[k] = not t[k]
            if t[k] then dot.BackgroundColor3 = Cfg.UI.Accent
            else dot.BackgroundColor3 = Cfg.UI.Toggle end
            if cb then pcall(cb, t[k]) end
        end)
        table.insert(S.theme.accent, {obj = dot, prop = "BackgroundColor3", getCond = function() return t[k] end})
    end

    local function mkSld(p, txt, mn, mx, t, k, fmt, cb)
        if not fmt then fmt = "%.1f" end
        local isInt = false
        if fmt:find("%%d") or fmt:find("%%%.0f") then isInt = true end
        local f = Instance.new("Frame", p)
        f.Size = UDim2.new(1, 0, 0, SC(38, 44))
        f.BackgroundColor3 = PNL
        f.BorderSizePixel = 0
        f.LayoutOrder = nOrd()
        local fc = Instance.new("UICorner", f)
        fc.CornerRadius = UDim.new(0, 5)
        table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f)
        l.Text = string.format("%s: " .. fmt, txt, t[k])
        l.Size = UDim2.new(1, -10, 0, 14)
        l.Position = UDim2.new(0, 6, 0, 2)
        l.BackgroundTransparency = 1
        l.TextColor3 = TXT
        l.TextSize = SC(9, 10)
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        table.insert(S.theme.text, l)
        local tr = Instance.new("Frame", f)
        tr.Size = UDim2.new(1, -12, 0, SC(5, 7))
        tr.Position = UDim2.new(0, 6, 0, SC(22, 24))
        tr.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        tr.BorderSizePixel = 0
        local trc = Instance.new("UICorner", tr)
        trc.CornerRadius = UDim.new(0, 3)
        local pct = math.clamp((t[k] - mn) / (mx - mn), 0, 1)
        local fl = Instance.new("Frame", tr)
        fl.Size = UDim2.new(pct, 0, 1, 0)
        fl.BackgroundColor3 = MC
        fl.BorderSizePixel = 0
        local flc = Instance.new("UICorner", fl)
        flc.CornerRadius = UDim.new(0, 3)
        table.insert(S.theme.accent, {obj = fl, prop = "BackgroundColor3"})
        local drag = false
        local hb = Instance.new("TextButton", f)
        hb.Text = ""
        hb.Size = UDim2.new(1, 4, 0, SC(18, 24))
        hb.Position = UDim2.new(0, -2, 0, SC(16, 18))
        hb.BackgroundTransparency = 1
        hb.ZIndex = 5
        local function upd(ix)
            local ap = tr.AbsolutePosition.X
            local as = tr.AbsoluteSize.X
            if as <= 0 then return end
            local r = math.clamp((ix - ap) / as, 0, 1)
            local v = mn + r * (mx - mn)
            if isInt then v = math.floor(v + 0.5) end
            t[k] = v
            fl.Size = UDim2.new(r, 0, 1, 0)
            l.Text = string.format("%s: " .. fmt, txt, v)
            if cb then pcall(cb, v) end
        end
        hb.InputBegan:Connect(function(i)
            local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
            local t2 = i.UserInputType == Enum.UserInputType.Touch
            if t1 or t2 then
                drag = true
                upd(i.Position.X)
            end
        end)
        table.insert(S.conns, UIS.InputChanged:Connect(function(i)
            if not drag then return end
            local t1 = i.UserInputType == Enum.UserInputType.MouseMovement
            local t2 = i.UserInputType == Enum.UserInputType.Touch
            if t1 or t2 then upd(i.Position.X) end
        end))
        table.insert(S.conns, UIS.InputEnded:Connect(function(i)
            local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
            local t2 = i.UserInputType == Enum.UserInputType.Touch
            if t1 or t2 then drag = false end
        end))
    end

    local function mkDD(p, txt, opts, t, k, cb)
        local f = Instance.new("Frame", p)
        f.Size = UDim2.new(1, 0, 0, SC(28, 34))
        f.BackgroundColor3 = PNL
        f.BorderSizePixel = 0
        f.LayoutOrder = nOrd()
        local fc = Instance.new("UICorner", f)
        fc.CornerRadius = UDim.new(0, 5)
        table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f)
        l.Text = txt
        l.Size = UDim2.new(0.45, 0, 1, 0)
        l.Position = UDim2.new(0, 8, 0, 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = TXT
        l.TextSize = SC(10, 11)
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        table.insert(S.theme.text, l)
        local btn = Instance.new("TextButton", f)
        btn.Text = tostring(t[k])
        btn.Size = UDim2.new(0.5, -6, 0.75, 0)
        btn.Position = UDim2.new(0.48, 0, 0.125, 0)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.TextColor3 = MC
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = SC(10, 11)
        btn.AutoButtonColor = false
        local bc = Instance.new("UICorner", btn)
        bc.CornerRadius = UDim.new(0, 4)
        table.insert(S.theme.accent, {obj = btn, prop = "TextColor3"})
        btn.MouseButton1Click:Connect(function()
            local idx = table.find(opts, t[k]) or 0
            idx = idx % #opts + 1
            t[k] = opts[idx]
            btn.Text = tostring(opts[idx])
            if cb then pcall(cb, opts[idx]) end
        end)
    end

    local function mkSep(p, txt)
        local f = Instance.new("Frame", p)
        f.Size = UDim2.new(1, 0, 0, 18)
        f.BackgroundTransparency = 1
        f.LayoutOrder = nOrd()
        local l = Instance.new("TextLabel", f)
        l.Text = "-- " .. txt .. " --"
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = MC
        l.Font = Enum.Font.GothamBold
        l.TextSize = SC(10, 10)
        table.insert(S.theme.accent, {obj = l, prop = "TextColor3"})
    end

    local function mkRGB(p, label, t, k)
        local f = Instance.new("Frame", p)
        f.Size = UDim2.new(1, 0, 0, 32)
        f.BackgroundColor3 = PNL
        f.BorderSizePixel = 0
        f.LayoutOrder = nOrd()
        f.ClipsDescendants = true
        local fc = Instance.new("UICorner", f)
        fc.CornerRadius = UDim.new(0, 5)
        table.insert(S.theme.panel, f)
        local l = Instance.new("TextLabel", f)
        l.Text = label
        l.Size = UDim2.new(0.55, -8, 0, 32)
        l.Position = UDim2.new(0, 8, 0, 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = TXT
        l.TextSize = SC(10, 11)
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        table.insert(S.theme.text, l)
        local rgbTxt = Instance.new("TextLabel", f)
        rgbTxt.Size = UDim2.new(0, 100, 0, 32)
        rgbTxt.Position = UDim2.new(1, -140, 0, 0)
        rgbTxt.BackgroundTransparency = 1
        rgbTxt.TextColor3 = TXTD
        rgbTxt.TextSize = SC(9, 10)
        rgbTxt.Font = Enum.Font.Code
        rgbTxt.TextXAlignment = Enum.TextXAlignment.Right
        table.insert(S.theme.textDim, rgbTxt)
        local function updTxt()
            local c = t[k]
            rgbTxt.Text = string.format("%d, %d, %d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
        end
        updTxt()
        local swatch = Instance.new("TextButton", f)
        swatch.Text = ""
        swatch.Size = UDim2.new(0, 32, 0, 22)
        swatch.Position = UDim2.new(1, -38, 0, 5)
        swatch.BackgroundColor3 = t[k]
        swatch.BorderSizePixel = 0
        swatch.AutoButtonColor = false
        local sc2 = Instance.new("UICorner", swatch)
        sc2.CornerRadius = UDim.new(0, 4)
        local ss = Instance.new("UIStroke", swatch)
        ss.Color = Color3.new(1, 1, 1)
        local expanded = false
        local built = false
        local function makeChan(yOff, chName, chColor, getCur, setCur)
            local cf = Instance.new("Frame", f)
            cf.Size = UDim2.new(1, -16, 0, 22)
            cf.Position = UDim2.new(0, 8, 0, yOff)
            cf.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", cf)
            lbl.Size = UDim2.new(0, 14, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = chColor
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = SC(10, 11)
            lbl.Text = chName
            local val = Instance.new("TextLabel", cf)
            val.Size = UDim2.new(0, 28, 1, 0)
            val.Position = UDim2.new(1, -28, 0, 0)
            val.BackgroundTransparency = 1
            val.TextColor3 = TXT
            val.Font = Enum.Font.Code
            val.TextSize = SC(10, 11)
            val.Text = tostring(math.floor(getCur() * 255 + 0.5))
            local tr = Instance.new("Frame", cf)
            tr.Size = UDim2.new(1, -50, 0, 6)
            tr.Position = UDim2.new(0, 18, 0.5, -3)
            tr.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            tr.BorderSizePixel = 0
            local trc = Instance.new("UICorner", tr)
            trc.CornerRadius = UDim.new(0, 3)
            local fl = Instance.new("Frame", tr)
            fl.Size = UDim2.new(getCur(), 0, 1, 0)
            fl.BackgroundColor3 = chColor
            fl.BorderSizePixel = 0
            local flc = Instance.new("UICorner", fl)
            flc.CornerRadius = UDim.new(0, 3)
            local drag = false
            local hit = Instance.new("TextButton", cf)
            hit.Text = ""
            hit.Size = UDim2.new(1, -50, 1, 0)
            hit.Position = UDim2.new(0, 18, 0, 0)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 5
            local function upd(x)
                local ap = tr.AbsolutePosition.X
                local as = tr.AbsoluteSize.X
                if as <= 0 then return end
                local r = math.clamp((x - ap) / as, 0, 1)
                fl.Size = UDim2.new(r, 0, 1, 0)
                val.Text = tostring(math.floor(r * 255 + 0.5))
                setCur(r)
                swatch.BackgroundColor3 = t[k]
                updTxt()
            end
            hit.InputBegan:Connect(function(i)
                local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
                local t2 = i.UserInputType == Enum.UserInputType.Touch
                if t1 or t2 then
                    drag = true
                    upd(i.Position.X)
                end
            end)
            table.insert(S.conns, UIS.InputChanged:Connect(function(i)
                if not drag then return end
                local t1 = i.UserInputType == Enum.UserInputType.MouseMovement
                local t2 = i.UserInputType == Enum.UserInputType.Touch
                if t1 or t2 then upd(i.Position.X) end
            end))
            table.insert(S.conns, UIS.InputEnded:Connect(function(i)
                local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
                local t2 = i.UserInputType == Enum.UserInputType.Touch
                if t1 or t2 then drag = false end
            end))
        end
        swatch.MouseButton1Click:Connect(function()
            expanded = not expanded
            if expanded then
                if not built then
                    makeChan(36, "R", Color3.fromRGB(255, 80, 80), function() return t[k].R end, function(v) t[k] = Color3.new(v, t[k].G, t[k].B) end)
                    makeChan(62, "G", Color3.fromRGB(80, 255, 80), function() return t[k].G end, function(v) t[k] = Color3.new(t[k].R, v, t[k].B) end)
                    makeChan(88, "B", Color3.fromRGB(80, 130, 255), function() return t[k].B end, function(v) t[k] = Color3.new(t[k].R, t[k].G, v) end)
                    built = true
                end
                f.Size = UDim2.new(1, 0, 0, 32 + 3 * 26 + 6)
            else
                f.Size = UDim2.new(1, 0, 0, 32)
            end
        end)
    end

    local tA  = mkTab("AIM",    1, 7)
    local tE  = mkTab("ESP",    2, 7)
    local tW  = mkTab("WH",     3, 7)
    local tM  = mkTab("MISC",   4, 7)
    local tMB = mkTab("MAGIC",  5, 7)
    local tC  = mkTab("COLORS", 6, 7)
    local tT  = mkTab("PERF",   7, 7)
    tabBtns["AIM"].TextColor3 = MC
    tA.Visible = true
    curTab = tA

    -- AIM TAB
    ord = 0
    mkSep(tA, "AIMBOT")
    mkTog(tA, "Enabled", Cfg.Aim, "On")
    mkDD (tA, "Mode", {"Minimal", "Normal", "Silent"}, Cfg.Aim, "Mode", function(v)
        OnAimModeChanged(v)
    end)
    mkDD (tA, "Bone", {"Head", "UpperTorso", "HumanoidRootPart"}, Cfg.Aim, "Part")
    mkTog(tA, "Sticky Target", Cfg.Aim, "Sticky")
    mkTog(tA, "360 Aim", Cfg.Aim, "Aim360")
    mkTog(tA, "Visible Check", Cfg.Aim, "VisCheck")  -- отдельная настройка!
    mkTog(tA, "FOV Circle", Cfg.Aim, "FOVOn")
    mkSld(tA, "FOV Radius", 10, 500, Cfg.Aim, "FOV", "%.0f")
    mkSep(tA, "SPEED / SMOOTH")
    mkSld(tA, "Aim Speed", 0.1, 5.0, Cfg.Aim, "Speed", "%.2f")
    mkSld(tA, "Smoothness (0=instant)", 0, 100, Cfg.Aim, "Smooth", "%.0f")
    mkSep(tA, "PREDICTION")
    mkTog(tA, "Prediction", Cfg.Aim, "Prediction")
    mkSld(tA, "Pred Factor", 0.05, 0.5, Cfg.Aim, "PredFactor", "%.2f")
    mkSep(tA, "TRIGGER BOT")
    mkTog(tA, "Trigger Bot", Cfg.TriggerBot, "On")
    mkSld(tA, "Shot Delay", 0.01, 0.5, Cfg.TriggerBot, "Delay", "%.2f")
    mkSld(tA, "Burst Count", 1, 10, Cfg.TriggerBot, "BurstCount", "%.0f")
    mkSld(tA, "Burst Delay", 0.01, 0.1, Cfg.TriggerBot, "BurstDelay", "%.2f")
    mkTog(tA, "Only ADS (RMB)", Cfg.TriggerBot, "OnlyADS")
    mkSep(tA, "CHECKS")
    mkTog(tA, "Team Check", Cfg.Checks, "Team")
    mkTog(tA, "Wall Check (ESP/WH)", Cfg.Checks, "Wall")

    -- ESP TAB
    ord = 0
    mkSep(tE, "ESP")
    mkTog(tE, "Enabled", Cfg.ESP, "On", function(v) if not v then E.DelAll() end end)
    mkTog(tE, "Show Team", Cfg.ESP, "ShowTeam")
    mkSld(tE, "Max Distance", 50, 3000, Cfg.ESP, "MaxDist", "%.0f")
    mkSep(tE, "BOX")
    mkTog(tE, "Box", Cfg.Box, "On")
    mkDD (tE, "Style", {"Corner", "Full"}, Cfg.Box, "Style")
    mkSld(tE, "Thickness", 0.5, 5, Cfg.Box, "Thickness", "%.1f")
    mkTog(tE, "Outline", Cfg.Box, "Outline")
    mkSep(tE, "NAME")
    mkTog(tE, "Name Tag", Cfg.Name, "On")
    mkDD (tE, "Format", {"Name+Dist", "Name"}, Cfg.Name, "Format")
    mkSld(tE, "Font Size", 8, 24, Cfg.Name, "Size", "%.0f")
    mkSep(tE, "HEALTH BAR")
    mkTog(tE, "Health Bar", Cfg.HP, "On")
    mkSld(tE, "Bar Width", 1, 10, Cfg.HP, "Width", "%.0f")
    mkSld(tE, "Bar Offset", 0, 20, Cfg.HP, "Offset", "%.0f")
    mkSep(tE, "TRACER")
    mkTog(tE, "Tracer", Cfg.Tracer, "On")
    mkSld(tE, "Thickness", 0.5, 5, Cfg.Tracer, "Thickness", "%.1f")
    mkSep(tE, "HEAD DOT")
    mkTog(tE, "Head Dot", Cfg.HeadDot, "On")
    mkSld(tE, "Radius", 2, 10, Cfg.HeadDot, "Radius", "%.0f")

    -- WH TAB
    ord = 0
    mkSep(tW, "WALLHACK")
    mkTog(tW, "Enabled", Cfg.WH, "On", function(v) if not v then WH.KillAll() end end)
    mkTog(tW, "Show Team", Cfg.WH, "ShowTeam")
    mkSld(tW, "Fill Trans", 0, 1, Cfg.WH, "FT", "%.2f")

    -- MISC TAB
    ord = 0
    mkSep(tM, "CAMERA / TP")
    mkTog(tM, "3rd Person Fix", Cfg.TP, "On")
    mkSld(tM, "Rotation Speed", 0.05, 1, Cfg.TP, "RotSpeed", "%.2f")
    mkSld(tM, "Max Angle", 5, 180, Cfg.TP, "MaxAngle", "%.0f")
    mkSep(tM, "MOVEMENT")
    mkTog(tM, "SpinBot", Cfg.Spin, "On")
    mkSld(tM, "Spin Speed", 1, 50, Cfg.Spin, "Spd", "%.0f")
    mkTog(tM, "Speed Boost", Cfg.Speed, "On")
    mkDD (tM, "Speed Method", {"CFrame", "Velocity", "Teleport"}, Cfg.Speed, "Method")
    mkSld(tM, "Speed Mult", 1, 3, Cfg.Speed, "Mult", "%.2f")
    mkSep(tM, "LIMITS")
    mkSld(tM, "Max Distance", 100, 3000, Cfg.Limits, "MaxDist", "%.0f")
    mkSld(tM, "Min Distance", 1, 100, Cfg.Limits, "MinDist", "%.0f")
    mkSld(tM, "Max Angle", 10, 180, Cfg.Limits, "MaxAngle", "%.0f")
    mkSep(tM, "SYSTEM")
    local il = Instance.new("TextLabel", tM)
    local silentStr = "N"
    if Exec.canSilent then silentStr = "Y" end
    local clickStr = "N"
    if Exec.canClick and ClickMethod ~= "none" then clickStr = ClickMethod end
    il.Text = Exec.name .. " | Silent: " .. silentStr .. " | Click: " .. clickStr
    il.Size = UDim2.new(1, 0, 0, 18)
    il.BackgroundTransparency = 1
    il.TextColor3 = TXTD
    il.TextSize = SC(9, 10)
    il.Font = Enum.Font.Gotham
    il.LayoutOrder = nOrd()
    table.insert(S.theme.textDim, il)
    
    -- DEBUG LOG BUTTON
    local db = Instance.new("TextButton", tM)
    db.Text = "📋 COPY DEBUG LOG"
    db.Size = UDim2.new(1, 0, 0, SC(26, 32))
    db.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    db.TextColor3 = Color3.new(1, 1, 1)
    db.TextSize = SC(11, 12)
    db.Font = Enum.Font.GothamBold
    db.AutoButtonColor = false
    db.LayoutOrder = nOrd()
    local dbc = Instance.new("UICorner", db)
    dbc.CornerRadius = UDim.new(0, 5)
    db.Activated:Connect(function()
        CopyDebugLog()
    end)
    db.MouseButton1Click:Connect(function()
        CopyDebugLog()
    end)
    
    -- Live stats removed for performance. Use the copy button.
    local infoLbl = Instance.new("TextLabel", tM)
    infoLbl.Text = "Stats included in debug report"
    infoLbl.Size = UDim2.new(1, 0, 0, 14)
    infoLbl.BackgroundTransparency = 1
    infoLbl.TextColor3 = TXTD
    infoLbl.TextSize = SC(8, 9)
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.LayoutOrder = nOrd()
    table.insert(S.theme.textDim, infoLbl)
    
    local ub = Instance.new("TextButton", tM)
    ub.Text = "UNLOAD"
    ub.Size = UDim2.new(1, 0, 0, SC(26, 32))
    ub.BackgroundColor3 = Cfg.UI.ButtonBad
    ub.TextColor3 = Color3.new(1, 1, 1)
    ub.TextSize = SC(11, 12)
    ub.Font = Enum.Font.GothamBold
    ub.AutoButtonColor = false
    ub.LayoutOrder = nOrd()
    local ubc = Instance.new("UICorner", ub)
    ubc.CornerRadius = UDim.new(0, 5)
    ub.MouseButton1Click:Connect(function() Notify("XENO", "Bye", 2)
    task.delay(0.3, Cleanup) end)
    table.insert(S.theme.btnBad, ub)

    -- MAGIC BULLET TAB
    ord = 0
    mkSep(tMB, "MAGIC BULLET")
    mkTog(tMB, "Enabled", Cfg.MagicBullet, "On", function(v)
        if v ~= S.magic.on then ToggleMagicBullet() end
    end)
    mkSld(tMB, "Max Range", 50, 500, Cfg.MagicBullet, "Range", "%.0f")

    -- COLORS TAB
    ord = 0
    mkSep(tC, "MENU THEME")
    mkRGB(tC, "Accent",     Cfg.UI, "Accent")
    mkRGB(tC, "Background", Cfg.UI, "Background")
    mkRGB(tC, "Panel",      Cfg.UI, "Panel")
    mkRGB(tC, "Text",       Cfg.UI, "Text")
    mkRGB(tC, "Text Dim",   Cfg.UI, "TextDim")
    mkRGB(tC, "Toggle Off", Cfg.UI, "Toggle")
    mkRGB(tC, "Button Bad", Cfg.UI, "ButtonBad")
    mkSep(tC, "ESP COLORS")
    mkRGB(tC, "Enemy Box",  Cfg.Box,    "Color")
    mkRGB(tC, "Team Box",   Cfg.Box,    "TeamColor")
    mkRGB(tC, "Enemy Name", Cfg.Name,   "Color")
    mkRGB(tC, "Team Name",  Cfg.Name,   "TeamColor")
    mkRGB(tC, "HP Bar BG",  Cfg.HP,     "BgColor")
    mkRGB(tC, "Tracer",     Cfg.Tracer, "Color")
    mkRGB(tC, "Head Dot",   Cfg.HeadDot, "Color")
    mkSep(tC, "WH COLORS")
    mkRGB(tC, "Enemy Fill",    Cfg.WH, "EnemyFill")
    mkRGB(tC, "Enemy Outline", Cfg.WH, "EnemyLine")
    mkRGB(tC, "Team Fill",     Cfg.WH, "TeamFill")
    mkRGB(tC, "Team Outline",  Cfg.WH, "TeamLine")
    local function ApplyTheme()
        for _, obj in ipairs(S.theme.bg)    do pcall(function() obj.BackgroundColor3 = Cfg.UI.Background end) end
        for _, obj in ipairs(S.theme.panel) do pcall(function() obj.BackgroundColor3 = Cfg.UI.Panel end) end
        for _, obj in ipairs(S.theme.text)  do pcall(function() obj.TextColor3 = Cfg.UI.Text end) end
        for _, obj in ipairs(S.theme.textDim) do pcall(function() obj.TextColor3 = Cfg.UI.TextDim end) end
        for _, e in ipairs(S.theme.accent) do
            pcall(function()
                if e.getCond then
                    if e.getCond() then e.obj[e.prop] = Cfg.UI.Accent
                    else e.obj[e.prop] = Cfg.UI.Toggle end
                else
                    e.obj[e.prop] = Cfg.UI.Accent
                end
            end)
        end
        for _, obj in ipairs(S.theme.btnBad) do pcall(function() obj.BackgroundColor3 = Cfg.UI.ButtonBad end) end
    end
    local applyBtn = Instance.new("TextButton", tC)
    applyBtn.Text = "APPLY THEME"
    applyBtn.Size = UDim2.new(1, 0, 0, SC(28, 34))
    applyBtn.BackgroundColor3 = Cfg.UI.ButtonOK
    applyBtn.TextColor3 = Color3.new(1, 1, 1)
    applyBtn.TextSize = SC(11, 12)
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.AutoButtonColor = false
    applyBtn.LayoutOrder = nOrd()
    local apc = Instance.new("UICorner", applyBtn)
    apc.CornerRadius = UDim.new(0, 5)
    applyBtn.MouseButton1Click:Connect(function() ApplyTheme()
    Notify("XENO", "Theme applied", 2) end)

    -- PERF TAB
    ord = 0
    mkSep(tT, "UPDATE FREQUENCY")
    local pi = Instance.new("TextLabel", tT)
    pi.Text = "1 = every frame (max quality)\nN = every Nth frame (faster)"
    pi.Size = UDim2.new(1, 0, 0, 32)
    pi.BackgroundTransparency = 1
    pi.TextColor3 = TXTD
    pi.TextSize = SC(10, 10)
    pi.Font = Enum.Font.Gotham
    pi.LayoutOrder = nOrd()
    table.insert(S.theme.textDim, pi)
    mkSld(tT, "ESP every N players/frame", 1, 30, Cfg.Tick, "ESP", "%.0f")
    mkSld(tT, "WH every N frames", 1, 60, Cfg.Tick, "WH", "%.0f")
    mkSld(tT, "HUD every N frames", 1, 10, Cfg.Tick, "HUD", "%.0f")
    mkSep(tT, "PRESETS")
    local function preset(name, e, w, hud, col)
        local b = Instance.new("TextButton", tT)
        b.Text = name
        b.Size = UDim2.new(1, 0, 0, SC(26, 32))
        b.BackgroundColor3 = col
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = SC(11, 11)
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = true
        b.LayoutOrder = nOrd()
        local bc = Instance.new("UICorner", b)
        bc.CornerRadius = UDim.new(0, 5)
        b.MouseButton1Click:Connect(function()
            Cfg.Tick.ESP = e
            Cfg.Tick.WH = w
            Cfg.Tick.HUD = hud
            Notify("XENO", name, 2)
        end)
    end
    preset("MAX QUALITY",     1,  1,  1, Color3.fromRGB(80, 200, 80))
    preset("BALANCED",        3,  5,  2, Color3.fromRGB(80, 130, 220))
    preset("MAX PERFORMANCE", 6, 10,  4, Color3.fromRGB(220, 130, 50))
    preset("IDLE",           15, 30, 10, Color3.fromRGB(120, 120, 120))
    mkSep(tT, "STATS")
    local fpsLbl = Instance.new("TextLabel", tT)
    fpsLbl.Text = "FPS: --"
    fpsLbl.Size = UDim2.new(1, 0, 0, 18)
    fpsLbl.BackgroundColor3 = PNL
    fpsLbl.BorderSizePixel = 0
    fpsLbl.TextColor3 = TXT
    fpsLbl.Font = Enum.Font.Code
    fpsLbl.TextSize = SC(11, 11)
    fpsLbl.LayoutOrder = nOrd()
    local fc2 = Instance.new("UICorner", fpsLbl)
    fc2.CornerRadius = UDim.new(0, 4)
    table.insert(S.theme.panel, fpsLbl)
    table.insert(S.theme.text, fpsLbl)
    local activeLbl = Instance.new("TextLabel", tT)
    activeLbl.Text = "Active ESP: 0 | WH: 0"
    activeLbl.Size = UDim2.new(1, 0, 0, 18)
    activeLbl.BackgroundColor3 = PNL
    activeLbl.BorderSizePixel = 0
    activeLbl.TextColor3 = TXT
    activeLbl.Font = Enum.Font.Code
    activeLbl.TextSize = SC(11, 11)
    activeLbl.LayoutOrder = nOrd()
    local ac = Instance.new("UICorner", activeLbl)
    ac.CornerRadius = UDim.new(0, 4)
    table.insert(S.theme.panel, activeLbl)
    table.insert(S.theme.text, activeLbl)
    S.draw.fpsLbl = fpsLbl
    S.draw.activeLbl = activeLbl

    -- ==== PERF POPOVER ====
    local pop = Instance.new("Frame", gui)
    pop.Size = UDim2.new(0, 200, 0, 140)
    pop.Position = UDim2.new(1, -210, 0, SC(50, 50))
    pop.BackgroundColor3 = Cfg.UI.Background
    pop.BorderSizePixel = 0
    pop.Visible = false
    pop.ZIndex = 50
    local popc = Instance.new("UICorner", pop)
    popc.CornerRadius = UDim.new(0, 6)
    local pops = Instance.new("UIStroke", pop)
    pops.Color = Cfg.UI.Accent
    table.insert(S.theme.bg, pop)
    local ptitle = Instance.new("TextLabel", pop)
    ptitle.Text = "QUICK TICK"
    ptitle.Size = UDim2.new(1, 0, 0, 18)
    ptitle.BackgroundTransparency = 1
    ptitle.TextColor3 = Cfg.UI.Accent
    ptitle.Font = Enum.Font.GothamBold
    ptitle.TextSize = SC(11, 11)
    ptitle.ZIndex = 51
    table.insert(S.theme.accent, {obj = ptitle, prop = "TextColor3"})
    local function quickRow(yOff, lab, key, mx)
        local row = Instance.new("Frame", pop)
        row.Size = UDim2.new(1, -10, 0, 28)
        row.Position = UDim2.new(0, 5, 0, yOff)
        row.BackgroundColor3 = Cfg.UI.Panel
        row.BorderSizePixel = 0
        row.ZIndex = 51
        local rc = Instance.new("UICorner", row)
        rc.CornerRadius = UDim.new(0, 4)
        table.insert(S.theme.panel, row)
        local lbl = Instance.new("TextLabel", row)
        lbl.Text = lab .. ": " .. Cfg.Tick[key]
        lbl.Size = UDim2.new(0.55, 0, 1, 0)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Cfg.UI.Text
        lbl.Font = Enum.Font.Code
        lbl.TextSize = SC(10, 10)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 52
        table.insert(S.theme.text, lbl)
        local mn = Instance.new("TextButton", row)
        mn.Text = "-"
        mn.Size = UDim2.new(0, 22, 0, 22)
        mn.Position = UDim2.new(1, -52, 0.5, -11)
        mn.BackgroundColor3 = Cfg.UI.Toggle
        mn.TextColor3 = Cfg.UI.Text
        mn.Font = Enum.Font.GothamBold
        mn.TextSize = SC(14, 14)
        mn.ZIndex = 52
        local mnc = Instance.new("UICorner", mn)
        mnc.CornerRadius = UDim.new(0, 4)
        local pl = Instance.new("TextButton", row)
        pl.Text = "+"
        pl.Size = UDim2.new(0, 22, 0, 22)
        pl.Position = UDim2.new(1, -26, 0.5, -11)
        pl.BackgroundColor3 = Cfg.UI.Accent
        pl.TextColor3 = Color3.new(1, 1, 1)
        pl.Font = Enum.Font.GothamBold
        pl.TextSize = SC(14, 14)
        pl.ZIndex = 52
        local plc = Instance.new("UICorner", pl)
        plc.CornerRadius = UDim.new(0, 4)
        table.insert(S.theme.accent, {obj = pl, prop = "BackgroundColor3"})
        local function refresh() lbl.Text = lab .. ": " .. Cfg.Tick[key] end
        mn.MouseButton1Click:Connect(function() Cfg.Tick[key] = math.max(Cfg.Tick[key] - 1, 1)
        refresh() end)
        pl.MouseButton1Click:Connect(function() Cfg.Tick[key] = math.min(Cfg.Tick[key] + 1, mx)
        refresh() end)
    end
    quickRow(22, "ESP", "ESP", 30)
    quickRow(54, "WH",  "WH",  60)
    quickRow(86, "HUD", "HUD", 10)
    local popClose = Instance.new("TextButton", pop)
    popClose.Text = "CLOSE"
    popClose.Size = UDim2.new(1, -10, 0, 22)
    popClose.Position = UDim2.new(0, 5, 1, -26)
    popClose.BackgroundColor3 = Cfg.UI.ButtonBad
    popClose.TextColor3 = Color3.new(1, 1, 1)
    popClose.Font = Enum.Font.GothamBold
    popClose.TextSize = SC(10, 10)
    popClose.ZIndex = 52
    local pcc = Instance.new("UICorner", popClose)
    pcc.CornerRadius = UDim.new(0, 4)
    popClose.MouseButton1Click:Connect(function() pop.Visible = false end)
    table.insert(S.theme.btnBad, popClose)
    perfBtn.MouseButton1Click:Connect(function() pop.Visible = not pop.Visible end)

    -- ==== FLOATING BUTTON ====
    local obs = SC(36, 44)
    local ob = Instance.new("TextButton", gui)
    ob.Text = "X"
    ob.Size = UDim2.new(0, obs, 0, obs)
    ob.Position = UDim2.new(0, 12, 0, SC(90, 90))
    ob.BackgroundColor3 = Cfg.UI.Accent
    ob.TextColor3 = Color3.new(1, 1, 1)
    ob.TextSize = SC(16, 18)
    ob.Font = Enum.Font.GothamBlack
    ob.AutoButtonColor = false
    ob.Active = true
    ob.ZIndex = 10
    local obc = Instance.new("UICorner", ob)
    obc.CornerRadius = UDim.new(1, 0)
    local obs2 = Instance.new("UIStroke", ob)
    obs2.Color = Color3.new(1, 1, 1)
    obs2.Thickness = 2
    table.insert(S.theme.accent, {obj = ob, prop = "BackgroundColor3"})
    local oDrag = false
    local oStart, oPos, oMoved = nil, nil, false
    ob.InputBegan:Connect(function(i)
        local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
        local t2 = i.UserInputType == Enum.UserInputType.Touch
        if t1 or t2 then
            oDrag = true
            oStart = i.Position
            oPos = ob.Position
            oMoved = false
        end
    end)
    table.insert(S.conns, UIS.InputChanged:Connect(function(i)
        if not oDrag then return end
        local t1 = i.UserInputType == Enum.UserInputType.MouseMovement
        local t2 = i.UserInputType == Enum.UserInputType.Touch
        if t1 or t2 then
            local d = i.Position - oStart
            if d.Magnitude > 6 then oMoved = true end
            ob.Position = UDim2.new(oPos.X.Scale, oPos.X.Offset + d.X, oPos.Y.Scale, oPos.Y.Offset + d.Y)
        end
    end))
    table.insert(S.conns, UIS.InputEnded:Connect(function(i)
        if not oDrag then return end
        local t1 = i.UserInputType == Enum.UserInputType.MouseButton1
        local t2 = i.UserInputType == Enum.UserInputType.Touch
        if t1 or t2 then
            oDrag = false
            if not oMoved then main.Visible = not main.Visible end
        end
    end))
end

-- ---- Main Loop ----
local function MainLoop()
    table.insert(S.conns, RunService.RenderStepped:Connect(function(dt)
        if DEAD then return end
        S.frame = S.frame + 1
        Cam = WS.CurrentCamera
        if not Cam then return end
        RefreshPL()
        -- FPS calc
        local now = tick()
        local fdt = now - S.fpsLast
        S.fpsLast = now
        if fdt > 0 then S.fpsAvg = S.fpsAvg * 0.95 + (1 / fdt) * 0.05 end
        -- Aim
        local aimRate = Cfg.Tick.Aim
        if aimRate < 1 then aimRate = 1 end
        if S.frame % aimRate == 0 then
            if Cfg.Aim.On and S.me.alive and S.me.root then
                local part, plr = FindTarget()
                if part then
                    S.tgt.part = part
                    S.tgt.plr = plr
                    if plr then S.tgt.name = plr.Name end
                    S.tgt.dist = (Cam.CFrame.Position - part.Position).Magnitude
                    S.tgt.vis = true
                    local ch = plr and plr.Character
                    if ch then S.tgt.hp = GetHP(ch) end
                    ApplyAim(part)
                else
                    if not Cfg.Aim.Sticky then
                        S.tgt.part = nil
                        S.tgt.plr = nil
                        S.tgt.name = ""
                        S.tgt.lastPos = nil
                        S.tgt.vel = Vector3.zero
                    end
                    S.tgt.vis = false
                end
            else
                if not Cfg.Aim.Sticky then
                    S.tgt.part = nil
                    S.tgt.plr = nil
                end
                S.tgt.vis = false
            end
        end
        -- Trigger Bot
        UpdateTriggerBot()
        if Cfg.TP.On and S.me.alive and S.me.root and S.tgt.part then TPFix() end
        ApplyMovement(dt)
        E.UpdateBatch()
        local hudRate = Cfg.Tick.HUD
        if hudRate < 1 then hudRate = 1 end
        if S.frame % hudRate == 0 then HUD.Update() end
        -- Update stats labels
        if S.frame % 30 == 0 and S.draw.fpsLbl then
            pcall(function()
                S.draw.fpsLbl.Text = string.format("FPS: %.0f", S.fpsAvg)
                local ec, wc = 0, 0
                for _ in pairs(S.esp) do ec = ec + 1 end
                for _ in pairs(S.wh) do wc = wc + 1 end
                S.draw.activeLbl.Text = "Active ESP: " .. ec .. " | WH: " .. wc
            end)
        end
    end))
    table.insert(S.conns, RunService.Heartbeat:Connect(function()
        if DEAD then return end
        if S.frame % Cfg.Tick.WH == 0 then WH.Update() end
    end))
end

-- ---- Init ----
_G.XenoCleanup = Cleanup
table.insert(S.conns, Players.PlayerRemoving:Connect(function(p)
    if DEAD then return end
    E.Del(p.UserId)
    WH.Kill(p.UserId)
end))

SetupChar()
task.wait(0.5)
HUD.Create()
BuildGUI()
MainLoop()

Notify("XENO v17.9", "Loaded [Eclipse]. Tap X button to open menu.", 5)
