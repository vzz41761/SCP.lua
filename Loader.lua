-- cobble hills loader (SCP:RP)
-- ⚠️ Troque o "vzz41761" pelo seu usuário do GitHub se for diferente ⚠️
local baseUrl = "https://raw.githubusercontent.com/vzz41761/scp/main/"

if getgenv().Cobble_Unload then 
    pcall(getgenv().Cobble_Unload) 
end

local function loadFile(name)
    local success, err = pcall(function()
        local src = game:HttpGet(baseUrl .. name, true)
        if not src or src == "" or src:find("404: Not Found") then
            error("Arquivo não encontrado (404).")
        end
        local fn, compileErr = loadstring(src)
        if not fn then
            error("Erro de sintaxe: " .. tostring(compileErr))
        end
        fn()
    end)
    if not success then
        warn("[cobble] Erro no " .. name .. ": " .. tostring(err))
    end
end

loadFile("Logic.lua")
task.wait(0.5)
loadFile("UI.lua")
