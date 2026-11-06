-- cobble hills logic (SCP:RP - V2)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)
if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not Drawing then warn("[cobble] Sem Drawing API"); return end

-- CONFIG
local defaults = {
    Aimbot = { 
        Enabled=false, Mode="Camera", Key=Enum.UserInputType.MouseButton2, 
        FOV=120, Smooth=0.35, ShowFOV=true, TeamCheck=true, 
        Part="Head", WallCheck=true, StickyTime=1.5, AssistStrength=0.4 
    },
    ESP = { 
        Enabled=true, Players=true, Items=true, TeamColors=true, MaxDist=1000 
    },
    Move = { Speed=false, SpeedVal=30, Jump=false, JumpVal=50, Noclip=false, Fly=false },
    Visuals = { Fullbright=false, NoFog=false }
}
local Config = getgenv().CobbleConfig or {}
local function merge(dst, src) for k,v in pairs(src) do if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v) elseif dst[k] == nil then dst[k] = v end end end
for s,tbl in pairs(defaults) do Config[s] = Config[s] or {}; merge(Config[s], tbl) end
getgenv().CobbleConfig = Config

local connections = {}
local alive = true
local function track(c) connections[#connections+1] = c; return c end

-- FUNÇÕES DE TIME E CORES
local function getTeamColor(plr)
    if plr.TeamColor then return plr.TeamColor.Color end
    if plr.Team then return plr.Team.TeamColor.Color end
    return Color3.fromRGB(255, 255, 255) -- Branco se não tiver time
end

local function isTeammate(plr)
    if not LP.Team then return false end -- Se você não tem time, todos são inimigos
    if plr.Team == LP.Team then return true end
    if LP.TeamColor and plr.TeamColor == LP.TeamColor then return true end
    return false
end

-- CACHES
local CachedPlayers, CachedTools = {}, {}
task.spawn(function()
    while alive do
        local temp = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                if hum and root and hum.Health > 0 then
                    temp[plr] = { Char=plr.Character, Hum=hum, Root=root, Head=head, Player=plr }
                end
            end
        end
        CachedPlayers = temp
        task.wait(0.3)
    end
end)

task.spawn(function()
    while alive do
        local temp = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                temp[obj] = { Name=obj.Name, Pos=obj.Handle.Position }
            end
        end
        CachedTools = temp
        task.wait(1)
    end
end)

-- AIMBOT (Sticky Target + Modos)
local aimHeld, aimTarget = false, nil
local lastTarget = nil
local lastTargetTime = 0

local function isVisible(targetChar)
    if not Config.Aimbot.WallCheck then return true end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character, targetChar}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local hit = Workspace:Raycast(Camera.CFrame.Position, (targetChar.Head.Position - Camera.CFrame.Position), rp)
    return hit == nil
end

local function pickTarget()
    -- Sticky Target: Se ele já travou em alguém, fica nele por X segundos
    if lastTarget and lastTarget.Char.Parent and lastTarget.Hum.Health > 0 then
        if (tick() - lastTargetTime) < Config.Aimbot.StickyTime then
            if Config.Aimbot.TeamCheck and isTeammate(lastTarget.Player) then
                lastTarget = nil
            elseif not isVisible(lastTarget.Char) then
                lastTarget = nil
            else
                return lastTarget
            end
        end
    end

    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aimbot.FOV
    
    for _, d in pairs(CachedPlayers) do
        if d.Hum.Health > 0 and not (Config.Aimbot.TeamCheck and isTeammate(d.Player)) then
            local part = Config.Aimbot.Part == "Head" and d.Head or d.Root
            if part then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 and on then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist < bestD and isVisible(d.Char) then
                        bestD = dist
                        best = d
                    end
                end
            end
        end
    end
    
    if best then
        lastTarget = best
        lastTargetTime = tick()
    end
    return best
end

local function isAimInput(input)
    local b = Config.Aimbot.Key
    return b.EnumType == Enum.KeyCode and input.KeyCode == b or input.UserInputType == b
end

track(UserInputService.InputBegan:Connect(function(i, gpe) if not gpe and isAimInput(i) then aimHeld = true; lastTarget = nil end end))
track(UserInputService.InputEnded:Connect(function(i) if isAimInput(i) then aimHeld = false; lastTarget = nil end end))

-- Loop de Aimbot e Aim Assist
RunService:BindToRenderStep("cobble_aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not Config.Aimbot.Enabled or not aimHeld then return end
    local t = pickTarget()
    if not t then return end
    
    local part = Config.Aimbot.Part == "Head" and t.Head or t.Root
    local targetPos = part.Position
    
    if Config.Aimbot.Mode == "Aim Assist" then
        -- Move o mouse físico levemente (Legit)
        local sp, on = Camera:WorldToViewportPoint(targetPos)
        if on then
            local center = Camera.ViewportSize * 0.5
            local dx = (sp.X - center.X) * Config.Aimbot.AssistStrength
            local dy = (sp.Y - center.Y) * Config.Aimbot.AssistStrength
            if mousemoverel then mousemoverel(dx, dy) end
        end
    else
        -- Move a câmera (Camera)
        local want = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        local s = math.clamp(Config.Aimbot.Smooth, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(want, 1 - (1 - s) ^ (dt * 60))
    end
end)

-- MOVIMENTO E LUZ
local flyBV, flyConn = nil, nil
local FB_Defaults = { Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, FogEnd=Lighting.FogEnd }
local fbCC = nil

track(UserInputService.JumpRequest:Connect(function()
    if Config.Move.Jump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

track(RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if hum then
        hum.WalkSpeed = Config.Move.Speed and Config.Move.SpeedVal or 16
        if Config.Move.Jump then hum.UseJumpPower = true; hum.JumpPower = Config.Move.JumpVal end
    end

    if Config.Move.Noclip then
        for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    end

    if Config.Move.Fly and not flyBV and root then
        hum.PlatformStand = true
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5); flyBV.Parent = root
        flyConn = RunService.RenderStepped:Connect(function()
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * 50 or Vector3.zero
        end)
    elseif not Config.Move.Fly and flyBV then
        hum.PlatformStand = false; flyBV:Destroy(); flyBV = nil
        if flyConn then flyConn:Disconnect(); flyConn = nil end
    end

    if Config.Visuals.Fullbright then
        if not fbCC then fbCC = Instance.new("ColorCorrectionEffect"); fbCC.Brightness = 1; fbCC.Parent = Lighting end
        Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.Brightness = 3; Lighting.ClockTime = 14
    else
        if fbCC then fbCC:Destroy(); fbCC = nil end
        for k, v in pairs(FB_Defaults) do pcall(function() Lighting[k] = v end) end
    end
    Lighting.FogEnd = Config.Visuals.NoFog and 1e5 or FB_Defaults.FogEnd
end))

-- ESP DRAWINGS
local pDraw, tDraw = {}, {}
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1; fovCircle.Filled = false; fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(0, 255, 150); fovCircle.Transparency = 0.7

track(RunService.RenderStepped:Connect(function()
    local camPos = Camera.CFrame.Position
    local activeP, activeT = {}, {}

    if Config.ESP.Enabled and Config.ESP.Players then
        for plr, data in pairs(CachedPlayers) do
            if data.Hum.Health > 0 then
                activeP[plr] = true
                local o = pDraw[plr]
                if not o then
                    o = { box=Drawing.new("Square"), name=Drawing.new("Text"), dist=Drawing.new("Text") }
                    o.box.Thickness = 1; o.name.Outline = true; o.name.Center = true; o.dist.Center = true; o.dist.Outline = true
                    pDraw[plr] = o
                end
                
                -- Cor do ESP baseada no time
                local color = Color3.fromRGB(255, 0, 0) -- Vermelho padrão
                if Config.ESP.TeamColors then
                    color = getTeamColor(plr)
                    -- Se for o seu time, deixa verde/azul brilhante pra destacar
                    if isTeammate(plr) then color = color:Lerp(Color3.fromRGB(0, 255, 0), 0.5) end
                else
                    if isTeammate(plr) then color = Color3.fromRGB(0, 255, 150) end
                end

                o.box.Color = color; o.name.Color = color; o.dist.Color = color

                local sp, on = Camera:WorldToViewportPoint(data.Root.Position + Vector3.new(0,2.5,0))
                local spBot, onBot = Camera:WorldToViewportPoint(data.Root.Position - Vector3.new(0,2.5,0))
                local dist = (camPos - data.Root.Position).Magnitude

                if sp.Z > 0 and on and onBot and dist < Config.ESP.MaxDist then
                    local h = spBot.Y - sp.Y; local w = h * 0.6
                    o.box.Position = Vector2.new(sp.X - w/2, sp.Y); o.box.Size = Vector2.new(w, h); o.box.Visible = true
                    o.name.Text = plr.Name; o.name.Position = Vector2.new(sp.X, sp.Y - 16); o.name.Visible = true
                    o.dist.Text = math.floor(dist) .. "m"; o.dist.Position = Vector2.new(sp.X, spBot.Y + 4); o.dist.Visible = true
                else o.box.Visible=false; o.name.Visible=false; o.dist.Visible=false end
            end
        end
    end
    for p, o in pairs(pDraw) do if not activeP[p] then o.box:Remove(); o.name:Remove(); o.dist:Remove(); pDraw[p] = nil end end

    if Config.ESP.Enabled and Config.ESP.Items then
        for tool, info in pairs(CachedTools) do
            local dist = (camPos - info.Pos).Magnitude
            if dist < 150 then
                activeT[tool] = true
                local d = tDraw[tool]
                if not d then d = Drawing.new("Text"); d.Center=true; d.Outline=true; d.Size=12; d.Color=Color3.fromRGB(255,200,0); tDraw[tool] = d end
                local sp, on = Camera:WorldToViewportPoint(info.Pos)
                if sp.Z > 0 and on then d.Text = "🔫 " .. info.Name .. " [" .. math.floor(dist) .. "m]"; d.Position = Vector2.new(sp.X, sp.Y); d.Visible = true else d.Visible = false end
            end
        end
    end
    for t, d in pairs(tDraw) do if not activeT[t] then d:Remove(); tDraw[t] = nil end end

    if Config.Aimbot.Enabled and Config.Aimbot.ShowFOV and aimHeld then
        fovCircle.Position = Camera.ViewportSize * 0.5; fovCircle.Radius = Config.Aimbot.FOV; fovCircle.Visible = true
    else fovCircle.Visible = false end
end))

getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, o in pairs(pDraw) do o.box:Remove(); o.name:Remove(); o.dist:Remove() end
    for _, d in pairs(tDraw) do d:Remove() end
    pcall(function() fovCircle:Remove() end)
    if flyBV then flyBV:Destroy() end
    if flyConn then flyConn:Disconnect() end
    if fbCC then fbCC:Destroy() end
    if getgenv().Cobble_UI_Loaded then getgenv().Cobble_UI_Loaded:Destroy() end
end
