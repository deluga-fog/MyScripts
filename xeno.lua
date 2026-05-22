-- =====================================================================
-- EXECUTOR TEST SCRIPT
-- Запусти этот скрипт и скажи мне, что вывелось в консоль
-- =====================================================================

local function test(name, fn)
    local ok, result = pcall(fn)
    if ok and result ~= nil then
        print("✅ " .. name .. " = " .. tostring(result))
    else
        print("❌ " .. name .. " = nil or error")
    end
end

print("===== EXECUTOR TEST START =====")

-- Основные функции
test("identifyexecutor", function() return identifyexecutor and identifyexecutor() end)
test("getexecutorname", function() return getexecutorname and getexecutorname() end)
test("hookmetamethod", function() return typeof(hookmetamethod) end)
test("getnamecallmethod", function() return typeof(getnamecallmethod) end)
test("newcclosure", function() return typeof(newcclosure) end)
test("Drawing", function() return typeof(Drawing) end)
test("gethui", function() return typeof(gethui) end)

-- Дополнительные
test("syn", function() return typeof(syn) end)
test("protect_gui", function() return typeof(protect_gui) end)
test("mouse1press", function() return typeof(mouse1press) end)
test("VirtualInputManager", function() return typeof(game:GetService("VirtualInputManager")) end)
test("setclipboard", function() return typeof(setclipboard) end)
test("request", function() return typeof(request) end)
test("isexecutorclosure", function() return typeof(isexecutorclosure) end)

print("===== TEST FINISHED =====")
