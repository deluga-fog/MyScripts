-- =====================================================================
-- XENO Mini v18.0 - Modern Luau (AIM + ESP only)
-- Только меню + две вкладки + новые системы наводки
-- =====================================================================

if _G.XenoLoaded and _G.XenoCleanup then _G.XenoCleanup() end
_G.XenoLoaded = true

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local WS = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local Plr = Players.LocalPlayer
local Cam = WS.CurrentCamera
local Mouse = Plr:GetMouse()

local Exec = {canSilent = typeof(hookmetamethod) == "function"}
local drawOK = pcall(function() local t = Drawing.new("Line"); t:Remove() end)

local DEAD = false
local function Notify(t, m, d) pcall(function() StarterGui:SetCore("SendNotification", {Title = t, Text = m or "", Duration = d or 3}) end) end

-- ==================== CONFIG ====================
local Cfg = {
    Aim = {
        On = false,
        Mode = "Normal", -- Normal, Flick, Silent
        Part = "Head",
        FOV = 120,
        Smooth = 25,
        Speed = 1.0,
        Sticky = false,
    },
    ESP = {
        On = false,
        MaxDist = 800,
        Box = true,
        Name = true,
        HP = true,
    }
}

local S = {
    tgt = {part = nil, plr = nil, vis = false},
    me = {char = nil, root = nil, alive = false},
    aim = {silentHooked = false, flickActive = false, flickSaved = nil},
    esp = {},
    conns = {},
    gui = nil,
    frame = 0
}

-- ==================== HELPERS ====================
local function W2S(pos)
    local ok, v = pcall(function() return Cam:WorldToViewportPoint(pos) end)
    return (ok and v and v.Z > 0) and Vector2.new(v.X, v.Y) or nil, (ok and v and v.Z > 0)
end

local function GetRoot(ch) return ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart) end
local function GetHP(ch) local h = ch:FindFirstChildOfClass("Humanoid"); return h and h.Health or 0, h and h.MaxHealth or 100 end

-- ==================== AIM SYSTEM ====================
local AimSys = {}

function AimSys.GetPos()
    return S.tgt.part and S.tgt.part.Position or nil
end

function AimSys.ShouldSilent()
    return Cfg.Aim.On and S.tgt.part and S.tgt.vis and Cfg.Aim.Mode == "Silent"
end

function AimSys.InstallSilent()
    if S.aim.silentHooked or not Exec.canSilent then return end
    local wrap = newcclosure or function(f) return f end

    pcall(function()
        hookmetamethod(game, "__namecall", wrap(function(self, ...)
            if DEAD or not AimSys.ShouldSilent() then return getmetatable(self).__namecall(self, ...) end
            local m = getnamecallmethod()
            local tp = AimSys.GetPos()
            if tp and self == WS and m == "Raycast" then
                local args = {...}
                if #args >= 2 and typeof(args[1]) == "Vector3" then
                    local d = (tp - args[1]).Unit * 1000
                    return getmetatable(self).__namecall(self, args[1], d, select(3, ...))
                end
            end
            return getmetatable(self).__namecall(self, ...)
        end))
    end)
    S.aim.silentHooked = true
    Notify("SILENT", "Hook ready", 2)
end

function AimSys.UpdateFlick()
    if DEAD or Cfg.Aim.Mode ~= "Flick" then
        if S.aim.flickActive and S.aim.flickSaved then Cam.CFrame = S.aim.flickSaved end
        S.aim.flickActive = false
        return
    end

    local holding = pcall(function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
    if holding and not S.aim.flickActive and S.tgt.part and S.tgt.vis then
        S.aim.flickSaved = Cam.CFrame
        S.aim.flickActive = true
    elseif holding and S.aim.flickActive then
        local tcf = CFrame.lookAt(Cam.CFrame.Position, S.tgt.part.Position)
        local amt = math.clamp(Cfg.Aim.Speed, 0.2, 1)
        Cam.CFrame = amt > 0.85 and tcf or Cam.CFrame:Lerp(tcf, amt)
    elseif not holding and S.aim.flickActive then
        if S.aim.flickSaved then Cam.CFrame = S.aim.flickSaved end
        S.aim.flickActive = false
    end
end

function AimSys.UpdateNormal()
    if not S.tgt.part or not S.tgt.vis then return end
    local tcf = CFrame.lookAt(Cam.CFrame.Position, S.tgt.part.Position)
    local amt = 1 / (1 + Cfg.Aim.Smooth * 0.04)
    Cam.CFrame = Cam.CFrame:Lerp(tcf, amt * Cfg.Aim.Speed)
end

-- ==================== ESP ====================
local function CreateESP(plr)
    if S.esp[plr.UserId] or not drawOK then return end
    local o = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        hp = Drawing.new("Text")
    }
    o.box.Filled = false
    o.box.Thickness = 1
    o.name.Size = 13
    o.name.Center = true
    S.esp[plr.UserId] = o
end

local function UpdateESP()
    if not Cfg.ESP.On then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Plr then
            local ch = p.Character
            local root = GetRoot(ch)
            if root and GetHP(ch) > 0 then
                local dist = (root.Position - (S.me.root and S.me.root.Position or Vector3.zero)).Magnitude
                if dist < Cfg.ESP.MaxDist then
                    if not S.esp[p.UserId] then CreateESP(p) end
                    local o = S.esp[p.UserId]
                    local sp, on = W2S(root.Position)
                    if on and sp then
                        if Cfg.ESP.Box then
                            o.box.Position = sp - Vector2.new(30, 50)
                            o.box.Size = Vector2.new(60, 100)
                            o.box.Color = Color3.fromRGB(255, 80, 80)
                            o.box.Visible = true
                        end
                        if Cfg.ESP.Name then
                            o.name.Text = p.DisplayName
                            o.name.Position = sp - Vector2.new(0, 65)
                            o.name.Visible = true
                        end
                    else
                        o.box.Visible = false
                        o.name.Visible = false
                    end
                end
            end
        end
    end
end

-- ==================== GUI ====================
local function BuildGUI()
    if S.gui then S.gui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "XenoMini"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 380, 0, 320)
    main.Position = UDim2.new(0.5, -190, 0.5, -160)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    main.BorderSizePixel = 0
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", main)
    title.Text = "XENO Mini v18"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(100, 150, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16

    -- Tabs
    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1, 0, 0, 28)
    tabBar.Position = UDim2.new(0, 0, 0, 32)
    tabBar.BackgroundTransparency = 1

    local aimTab = Instance.new("TextButton", tabBar)
    aimTab.Text = "AIM"
    aimTab.Size = UDim2.new(0.5, 0, 1, 0)
    aimTab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    aimTab.TextColor3 = Color3.new(1, 1, 1)

    local espTab = Instance.new("TextButton", tabBar)
    espTab.Text = "ESP"
    espTab.Size = UDim2.new(0.5, 0, 1, 0)
    espTab.Position = UDim2.new(0.5, 0, 0, 0)
    espTab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    espTab.TextColor3 = Color3.new(1, 1, 1)

    local aimFrame = Instance.new("Frame", main)
    aimFrame.Size = UDim2.new(1, -20, 1, -70)
    aimFrame.Position = UDim2.new(0, 10, 0, 65)
    aimFrame.BackgroundTransparency = 1

    local espFrame = Instance.new("Frame", main)
    espFrame.Size = UDim2.new(1, -20, 1, -70)
    espFrame.Position = UDim2.new(0, 10, 0, 65)
    espFrame.BackgroundTransparency = 1
    espFrame.Visible = false

    -- AIM Controls
    local aimToggle = Instance.new("TextButton", aimFrame)
    aimToggle.Text = "AIMBOT: OFF"
    aimToggle.Size = UDim2.new(1, 0, 0, 30)
    aimToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)

    local modeBtn = Instance.new("TextButton", aimFrame)
    modeBtn.Text = "Mode: Normal"
    modeBtn.Size = UDim2.new(1, 0, 0, 28)
    modeBtn.Position = UDim2.new(0, 0, 0, 40)
    modeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)

    aimToggle.MouseButton1Click:Connect(function()
        Cfg.Aim.On = not Cfg.Aim.On
        aimToggle.Text = Cfg.Aim.On and "AIMBOT: ON" or "AIMBOT: OFF"
    end)

    modeBtn.MouseButton1Click:Connect(function()
        local modes = {"Normal", "Flick", "Silent"}
        local idx = table.find(modes, Cfg.Aim.Mode) or 1
        idx = idx % #modes + 1
        Cfg.Aim.Mode = modes[idx]
        modeBtn.Text = "Mode: " .. Cfg.Aim.Mode
        if Cfg.Aim.Mode == "Silent" then AimSys.InstallSilent() end
    end)

    -- ESP Controls
    local espToggle = Instance.new("TextButton", espFrame)
    espToggle.Text = "ESP: OFF"
    espToggle.Size = UDim2.new(1, 0, 0, 30)
    espToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)

    espToggle.MouseButton1Click:Connect(function()
        Cfg.ESP.On = not Cfg.ESP.On
        espToggle.Text = Cfg.ESP.On and "ESP: ON" or "ESP: OFF"
    end)

    aimTab.MouseButton1Click:Connect(function()
        aimFrame.Visible = true
        espFrame.Visible = false
    end)
    espTab.MouseButton1Click:Connect(function()
        aimFrame.Visible = false
        espFrame.Visible = true
    end)

    S.gui = gui
end

-- ==================== MAIN ====================
local function MainLoop()
    table.insert(S.conns, RunService.RenderStepped:Connect(function()
        if DEAD then return end
        S.frame += 1
        Cam = WS.CurrentCamera

        -- Простая цель (ближайший)
        local best, bestD = nil, 9999
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Plr then
                local ch = p.Character
                local r = GetRoot(ch)
                if r and GetHP(ch) > 0 then
                    local d = (r.Position - (S.me.root and S.me.root.Position or Vector3.zero)).Magnitude
                    if d < bestD then bestD = d; best = r end
                end
            end
        end
        S.tgt.part = best
        S.tgt.vis = true

        -- AIM
        if Cfg.Aim.On and S.tgt.part then
            if Cfg.Aim.Mode == "Silent" then
                if not S.aim.silentHooked then AimSys.InstallSilent() end
            elseif Cfg.Aim.Mode == "Flick" then
                AimSys.UpdateFlick()
            else
                AimSys.UpdateNormal()
            end
        end

        -- ESP
        UpdateESP()
    end))
end

_G.XenoCleanup = function()
    DEAD = true
    for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end
    if S.gui then S.gui:Destroy() end
end

BuildGUI()
MainLoop()
Notify("XENO Mini v18", "Loaded | AIM + ESP", 4)
```
