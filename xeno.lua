-- =====================================================================
-- XENO PROJECT v17.5 [OFFICIAL MONOLITH]
-- Compiled for: Old Executors (Lua 5.1 Syntax)
-- Silent Aim: __namecall ONLY (Optimized FPS)
-- UI Engine: v16.1 Full Restore (7 Tabs + RGB)
-- =====================================================================

-- ---- Cleanup Logic ----
if _G.XenoLoaded and _G.XenoCleanup then 
    local ok, err = pcall(_G.XenoCleanup)
    wait(0.3)
end
_G.XenoLoaded = true

-- ---- Services ----
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local WS           = game:GetService("Workspace")
local StarterGui   = game:GetService("StarterGui")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local Plr    = Players.LocalPlayer
local Cam    = WS.CurrentCamera
local Mouse  = Plr:GetMouse()
local IsMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled)

-- ---- Core Helper Functions ----
local function SC(p, m) 
    if IsMobile then return m end 
    return p 
end

local function Notify(title, msg, dur)
    pcall(function()

