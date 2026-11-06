-- cobble hills UI (SCP:RP - V3)
local Players = game:GetService("Players")
local Config = getgenv().CobbleConfig
if not Config then return end

local SU = "https://raw.githubusercontent.com/PulseZax/Slate/refs/heads/main/.lua"
local ok, S = pcall(function() return loadstring(game:HttpGet(SU), "@Slate")() end)
if not ok or not S then return end

S.Theme.Preset("Violet")
S.Theme.Set({ Background = Color3.fromRGB(12, 11, 20), Surface = Color3.fromRGB(22, 19, 34), SurfaceAlt = Color3.fromRGB(31, 26, 46), Elevated = Color3.fromRGB(39, 31, 57), Accent = Color3.fromRGB(0, 255, 150), ToggleOn = Color3.fromRGB(0, 255, 150), Text = Color3.fromRGB(245, 242, 255), Muted = Color3.fromRGB(163, 154, 185), Radius = 12, RowHeight = 42, HeaderHeight = 56 })
pcall(function() S:SetFontFamily("Montserrat") end)

local Window = S:CreateWindow({ Name = "COBBLE <font color='#00FF96'>SCP</font>", Subtitle = "V3 SAFE", Icon = "shield", Logo = true, Size = UDim2.fromOffset(480, 420), ToggleKey = Enum.KeyCode.Insert, Backdrop = "aurora" })

-- ABA 1: AIMBOT
local tabAim = Window:CreateTab({ Name = "AIMBOT", Icon = "crosshair" })
tabAim:SetColumns(2)
local secAim = tabAim:CreateSection({ Name = "Aimbot Settings" })
secAim:Toggle({ Name = "Ativar Aimbot", Default = false, Callback = function(v) Config.Aimbot.Enabled = v end })
secAim:Dropdown({ Name = "Modo", Options = {"Camera", "Aim Assist"}, Default = "Camera", Callback = function(v) Config.Aimbot.Mode = v end })
secAim:Toggle({ Name = "Wall Check", Default = true, Callback = function(v) Config.Aimbot.WallCheck = v end })
secAim:Toggle({ Name = "Team Check", Default = true, Callback = function(v) Config.Aimbot.TeamCheck = v end })
secAim:Dropdown({ Name = "Parte do Corpo", Options = {"Head", "Torso"}, Default = "Head", Callback = function(v) Config.Aimbot.Part = v end })
secAim:Slider({ Name = "FOV", Min = 20, Max = 400, Default = 120, Callback = function(v) Config.Aimbot.FOV = v end })
secAim:Slider({ Name = "Suavidade", Min = 0.1, Max = 1.0, Default = 0.35, Callback = function(v) Config.Aimbot.Smooth = v end })
secAim:Slider({ Name = "Assist Força", Min = 0.1, Max = 1.0, Default = 0.4, Callback = function(v) Config.Aimbot.AssistStrength = v end })
secAim:Slider({ Name = "Sticky Time", Min = 0.5, Max = 3.0, Default = 1.5, Callback = function(v) Config.Aimbot.StickyTime = v end })

-- ABA 2: VISUAIS
local tabVis = Window:CreateTab({ Name = "ESP & VISUAL", Icon = "eye" })
tabVis:SetColumns(2)
local secEsp = tabVis:CreateSection({ Name = "ESP" })
secEsp:Toggle({ Name = "Ativar ESP", Default = true, Callback = function(v) Config.ESP.Enabled = v end })
secEsp:Toggle({ Name = "Jogadores", Default = true, Callback = function(v) Config.ESP.Players = v end })
secEsp:Toggle({ Name = "Cor do Time", Default = true, Callback = function(v) Config.ESP.TeamColors = v end })
secEsp:Toggle({ Name = "Itens", Default = true, Callback = function(v) Config.ESP.Items = v end })
secEsp:Slider({ Name = "Distância Max", Min = 100, Max = 3000, Default = 1000, Callback = function(v) Config.ESP.MaxDist = v end })

local secLuz = tabVis:CreateSection({ Name = "Luz e Câmera" })
secLuz:Toggle({ Name = "Fullbright", Default = false, Callback = function(v) Config.Visuals.Fullbright = v end })
secLuz:Toggle({ Name = "Remover Neblina", Default = false, Callback = function(v) Config.Visuals.NoFog = v end })

-- ABA 3: MOVIMENTO
local tabMove = Window:CreateTab({ Name = "MOVIMENTO", Icon = "activity" })
tabMove:SetColumns(2)
local secMove = tabMove:CreateSection({ Name = "Física" })
secMove:Toggle({ Name = "Speed Hack", Default = false, Callback = function(v) Config.Move.Speed = v end })
secMove:Slider({ Name = "Velocidade", Min = 16, Max = 60, Default = 30, Callback = function(v) Config.Move.SpeedVal = v end }) -- Travado em 60 para não dar kick
secMove:Toggle({ Name = "Super Pulo", Default = false, Callback = function(v) Config.Move.Jump = v end })
secMove:Slider({ Name = "Força do Pulo", Min = 50, Max = 200, Default = 150, Callback = function(v) Config.Move.JumpVal = v end })
secMove:Toggle({ Name = "Noclip", Default = false, Callback = function(v) Config.Move.Noclip = v end })
secMove:Paragraph({ Name = "Aviso", Text = "Fly foi removido para evitar Ban de Física." })

-- ABA 4: CONFIG
local tabConfig = Window:CreateTab({ Name = "CONFIG", Icon = "settings" })
tabConfig:SetColumns(1)
tabConfig:CreateSection({ Name = "Sessão" }):Button({ Name = "UNLOAD SCRIPT", Icon = "trash-2", Callback = function()
    if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
    Window:Destroy(); S:Destroy(); S.Cleanup()
end })

getgenv().Cobble_UI_Loaded = Window
