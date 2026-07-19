-- OISHI HUB RIVALS | FIXED LOADING + SMOOTH FOV + ANIMATIONS + FIXED BOX ESP + NO DEAD ENEMIES + ANTI-HIT (FIXED FOR RIVALS)

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local Camera = workspace.CurrentCamera 
local UserInputService = game:GetService("UserInputService") 
local TweenService = game:GetService("TweenService") 
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local Lighting = game:GetService("Lighting") 
local plr = Players.LocalPlayer 
local WorldRoot = workspace 

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- ============================================
-- 🌀 LOADING SCREEN
-- ============================================
local LoadGui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
LoadGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoadGui.DisplayOrder = 9999999
LoadGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame", LoadGui)
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.6
MainFrame.BorderSizePixel = 0

local Center = Instance.new("Frame", MainFrame)
Center.Size = UDim2.new(0, 250, 0, 200)
Center.Position = UDim2.new(0.5, -125, 0.5, -100)
Center.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Center.BackgroundTransparency = 0.1
Center.BorderSizePixel = 0
Instance.new("UICorner", Center).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", Center).Color = Color3.fromRGB(255, 80, 80)
Instance.new("UIStroke", Center).Thickness = 1.5
Instance.new("UIStroke", Center).Transparency = 0.5

local Loader = Instance.new("Frame", Center)
Loader.Size = UDim2.new(0, 50, 0, 50)
Loader.Position = UDim2.new(0.5, -25, 0.25, -25)
Loader.BackgroundTransparency = 1

local Rotation = 0
local RingConnection
RingConnection = RunService.RenderStepped:Connect(function()
    Rotation = Rotation + 5
    Loader.Rotation = Rotation
end)

local Circle = Instance.new("Frame", Loader)
Circle.Size = UDim2.new(0, 50, 0, 50)
Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Circle.BackgroundTransparency = 0.9
Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", Circle).Color = Color3.fromRGB(255, 80, 80)
Instance.new("UIStroke", Circle).Thickness = 2

local Title = Instance.new("TextLabel", Center)
Title.Size = UDim2.new(0, 200, 0, 30)
Title.Position = UDim2.new(0.5, -100, 0.55, 0)
Title.BackgroundTransparency = 1
Title.Text = "OISHI HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local Subtitle = Instance.new("TextLabel", Center)
Subtitle.Size = UDim2.new(0, 150, 0, 20)
Subtitle.Position = UDim2.new(0.5, -75, 0.65, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "RIVALS"
Subtitle.TextColor3 = Color3.fromRGB(255, 80, 80)
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextSize = 14

local BarBg = Instance.new("Frame", Center)
BarBg.Size = UDim2.new(0, 180, 0, 3)
BarBg.Position = UDim2.new(0.5, -90, 0.8, 0)
BarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local Progress = Instance.new("Frame", BarBg)
Progress.Size = UDim2.new(0, 0, 1, 0)
Progress.BackgroundColor3 = Color3.fromRGB(255, 80, 80)

local LoadingText = Instance.new("TextLabel", Center)
LoadingText.Size = UDim2.new(0, 150, 0, 15)
LoadingText.Position = UDim2.new(0.5, -75, 0.88, 0)
LoadingText.BackgroundTransparency = 1
LoadingText.Text = "Loading..."
LoadingText.TextColor3 = Color3.fromRGB(180, 180, 200)
LoadingText.Font = Enum.Font.Gotham
LoadingText.TextSize = 10
LoadingText.TextTransparency = 0.3

TweenService:Create(Progress, TweenInfo.new(2.5, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 1, 0)}):Play()

task.wait(3.5)
if RingConnection then RingConnection:Disconnect() end
TweenService:Create(MainFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
TweenService:Create(Center, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
task.wait(0.5)
LoadGui:Destroy()

-- ============================================
-- 🔔 NOTIFICATION SOUND
-- ============================================
local function PlayNotificationSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9120398095"
    sound.Volume = 0.5
    sound.Parent = plr.Character or workspace
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    task.wait(2)
    if sound and sound.Parent then
        sound:Destroy()
    end
end

-- ============================================
-- ⚙️ CONFIGURATION
-- ============================================
local MAX_RANGE = 260 
local VISIBILITY_TOLERANCE = 2 
local SMOOTH_FOV_SPEED = 0.15

-- ============================================
-- ✅ ANTI-HIT SYSTEM (ORBIT - STABLE, NO BOUNCING, CONFIGURABLE SPEED, 8 STUD RADIUS)
-- ============================================
local AntiHitActive = false
local AntiHitConn = nil
local OriginalMotorData = {}
local RandomOffsets = {}

local function StoreMotorData(char)
    if not char then return end
    OriginalMotorData = {}
    RandomOffsets = {}
    for _, motor in pairs(char:GetDescendants()) do
        if motor:IsA("Motor6D") then
            OriginalMotorData[motor] = {
                C0 = motor.C0,
                C1 = motor.C1
            }
            RandomOffsets[motor] = {
                speed = math.random(8, 15),
                radius = 8,
                angleOffset = math.random() * math.pi * 2
            }
        end
    end
end

local function ResetMotors()
    local char = plr.Character
    if not char then return end
    
    for motor, data in pairs(OriginalMotorData) do
        if motor and motor.Parent then
            pcall(function()
                motor.C0 = data.C0
                motor.C1 = data.C1
            end)
        end
    end
end

local function ToggleAntiHit(state)
    if state then
        AntiHitActive = true
        
        if AntiHitConn then 
            AntiHitConn:Disconnect() 
            AntiHitConn = nil 
        end
        
        local char = plr.Character
        if char then
            StoreMotorData(char)
        end
        
        AntiHitConn = RunService.Heartbeat:Connect(function()
            if not AntiHitActive then return end
            
            local char = plr.Character
            if not char then return end
            
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if not humanoid then return end
            
            local time = tick()
            local speedMult = Options.OrbitSpeedSlider and Options.OrbitSpeedSlider.Value or 1
            
            for _, motor in pairs(char:GetDescendants()) do
                if motor:IsA("Motor6D") and OriginalMotorData[motor] and RandomOffsets[motor] then
                    local motorName = motor.Name
                    local part0Name = motor.Part0 and motor.Part0.Name or ""
                    local part1Name = motor.Part1 and motor.Part1.Name or ""
                    
                    local rand = RandomOffsets[motor]
                    local orbitSpeed = rand.speed * speedMult
                    local orbitRadius = rand.radius
                    local angleOffset = rand.angleOffset
                    
                    local angle = time * orbitSpeed + angleOffset
                    local orbitX = math.cos(angle) * orbitRadius
                    local orbitZ = math.sin(angle) * orbitRadius
                    
                    local isWaist = (motorName == "Waist" or motorName == "Root" or 
                                   motorName == "TorsoMotor" or motorName == "UpperTorsoMotor" or
                                   (part0Name == "HumanoidRootPart" and part1Name == "UpperTorso") or
                                   part1Name == "UpperTorso" or part1Name == "Torso")
                    
                    local isNeck = (motorName == "Neck" or motorName == "HeadMotor" or
                                   (part0Name == "UpperTorso" and part1Name == "Head") or
                                   part1Name == "Head")
                    
                    local isLeftArm = (motorName == "LeftShoulder" or motorName == "LeftArmMotor" or
                                      (part0Name == "UpperTorso" and part1Name == "LeftUpperArm") or
                                      part1Name == "LeftUpperArm" or part1Name == "Left Arm")
                    
                    local isRightArm = (motorName == "RightShoulder" or motorName == "RightArmMotor" or
                                       (part0Name == "UpperTorso" and part1Name == "RightUpperArm") or
                                       part1Name == "RightUpperArm" or part1Name == "Right Arm")
                    
                    local isLeftLeg = (motorName == "LeftHip" or motorName == "LeftLegMotor" or
                                      (part0Name == "LowerTorso" and part1Name == "LeftUpperLeg") or
                                      part1Name == "LeftUpperLeg" or part1Name == "Left Leg")
                    
                    local isRightLeg = (motorName == "RightHip" or motorName == "RightLegMotor" or
                                       (part0Name == "LowerTorso" and part1Name == "RightUpperLeg") or
                                       part1Name == "RightUpperLeg" or part1Name == "Right Leg")
                    
                    if isWaist or isNeck then
                        motor.C0 = OriginalMotorData[motor].C0 * CFrame.new(orbitX, 0, orbitZ)
                    elseif isLeftArm then
                        motor.C0 = OriginalMotorData[motor].C0 * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(orbitX, 0, orbitZ)
                    elseif isRightArm then
                        motor.C0 = OriginalMotorData[motor].C0 * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(orbitX, 0, orbitZ)
                    elseif isLeftLeg then
                        motor.C0 = OriginalMotorData[motor].C0 * CFrame.new(orbitX, 0, orbitZ)
                    elseif isRightLeg then
                        motor.C0 = OriginalMotorData[motor].C0 * CFrame.new(orbitX, 0, orbitZ)
                    end
                end
            end
        end)
    else
        AntiHitActive = false
        if AntiHitConn then
            AntiHitConn:Disconnect()
            AntiHitConn = nil
        end
        ResetMotors()
    end
end

-- ============================================
-- ✅ RAPID FIRE SYSTEM
-- ============================================
local OriginalItemData = {} 
local function ToggleRapidFire(state)
    if game.GameId ~= 6035872082 then return end
    local Storage = ReplicatedStorage
    local ItemsOk, Items = pcall(function() return require(Storage.Modules.ItemLibrary).Items end)
    if not ItemsOk or not Items then return end

    if state then
        for name, data in pairs(Items) do
            if typeof(data) == "table" then
                OriginalItemData[name] = OriginalItemData[name] or {}
                for _, field in pairs({"ShootSpread","ShootAccuracy","ShootRecoil","ShootCooldown","ShootBurstCooldown","AttackCooldown","SwingCooldown","MeleeCooldown","Cooldown","RecoveryTime","ResetTime"}) do
                    OriginalItemData[name][field] = data[field]
                end
            end
        end
        local gunExceptions = {Sniper=true, Crossbow=true, Bow=true, RPG=true}
        for name, data in pairs(Items) do
            if typeof(data) == "table" and not gunExceptions[name] then
                if data.ShootSpread then data.ShootSpread = 0 end
                if data.ShootAccuracy then data.ShootAccuracy = 0 end
                if data.ShootRecoil then data.ShootRecoil = 0 end
                if data.ShootCooldown then data.ShootCooldown = 0.001 end
                if data.ShootBurstCooldown then data.ShootBurstCooldown = 0.001 end
                if data.AttackCooldown then data.AttackCooldown = 0.001 end
                if data.SwingCooldown then data.SwingCooldown = 0.001 end
                if data.MeleeCooldown then data.MeleeCooldown = 0.001 end
                if data.Cooldown then data.Cooldown = 0.001 end
                if data.RecoveryTime then data.RecoveryTime = 0.001 end
                if data.ResetTime then data.ResetTime = 0.001 end
            end
        end
    else
        for name, data in pairs(Items) do
            if typeof(data) == "table" and OriginalItemData[name] then
                local orig = OriginalItemData[name]
                for k, v in pairs(orig) do if data[k] then data[k] = v end end
            end
        end
    end
end

-- ============================================
-- ✅ MOVEMENT SYSTEMS
-- ============================================
local OriginalGravity = workspace.Gravity 
local NoClipConn = nil 
local JumpConn = nil 

task.spawn(function() 
    workspace:GetPropertyChangedSignal("Gravity"):Connect(function() OriginalGravity = workspace.Gravity end) 
end) 

local function ToggleJump(state) 
    if JumpConn then JumpConn:Disconnect(); JumpConn = nil end
    if state then JumpConn = UserInputService.JumpRequest:Connect(function()
        local c = plr.Character; if c then local h = c:FindFirstChildWhichIsA("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end) end
end 

local function ToggleNoClip(state) 
    local char = plr.Character
    if char then
        for _, p in pairs(char:GetDescendants()) do 
            if p:IsA("BasePart") then p.CanCollide = true end 
        end
    end
    
    if NoClipConn then NoClipConn:Disconnect(); NoClipConn = nil end
    
    if state then
        NoClipConn = RunService.Stepped:Connect(function()
            local c = plr.Character
            if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            for _, p in pairs(c:GetDescendants()) do 
                if p:IsA("BasePart") and p.CanCollide == true then
                    p.CanCollide = false
                end 
            end
            
            local h = c:FindFirstChildWhichIsA("Humanoid")
            if h then 
                h.PlatformStand = false
                h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end
        end)
    else
        local c = plr.Character
        if c then 
            for _, p in pairs(c:GetDescendants()) do 
                if p:IsA("BasePart") then p.CanCollide = true end 
            end
            local h = c:FindFirstChildWhichIsA("Humanoid")
            if h then 
                h.PlatformStand = false
                h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            end
        end 
    end 
end

-- ============================================
-- 🎯 FOV CIRCLES
-- ============================================
local FOVCircle = Drawing.new("Circle") 
FOVCircle.Radius = 50; FOVCircle.Thickness = 2; FOVCircle.Filled = true
FOVCircle.Color = Color3.new(0,0,0); FOVCircle.Transparency = 0.5; FOVCircle.Visible = true
FOVCircle.Position = Camera.ViewportSize / 2

local FOVHalf = Drawing.new("Circle")
FOVHalf.Radius = 50; FOVHalf.Thickness = 0; FOVHalf.Filled = true
FOVHalf.Color = Color3.new(1,1,1); FOVHalf.Transparency = 0.5; FOVHalf.Sides = 180
FOVHalf.StartAngle = 180; FOVHalf.EndAngle = 360; FOVHalf.Visible = true
FOVHalf.Position = Camera.ViewportSize / 2

local MainFOVCurrentPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
local MainFOVTargetPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

local SilentFOVCircle = Drawing.new("Circle")
SilentFOVCircle.Radius = 120
SilentFOVCircle.Thickness = 2
SilentFOVCircle.Filled = true
SilentFOVCircle.Color = Color3.new(1, 0, 0)
SilentFOVCircle.Transparency = 0.3
SilentFOVCircle.Visible = false
SilentFOVCircle.Position = Camera.ViewportSize / 2

local SilentFOVHalf = Drawing.new("Circle")
SilentFOVHalf.Radius = 120
SilentFOVHalf.Thickness = 0
SilentFOVHalf.Filled = true
SilentFOVHalf.Color = Color3.new(1, 0, 0)
SilentFOVHalf.Transparency = 0.3
SilentFOVHalf.Sides = 180
SilentFOVHalf.StartAngle = 180
SilentFOVHalf.EndAngle = 360
SilentFOVHalf.Visible = false
SilentFOVHalf.Position = Camera.ViewportSize / 2

local ShowSilentFOV = false
local SilentFOVCurrentPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
local SilentFOVTargetPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- ============================================
-- ✅ AUTO QUEUE
-- ============================================
local JoinQueueRemote = nil 
task.spawn(function()
    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Matchmaking")
        JoinQueueRemote = remotes:FindFirstChild("JoinQueue") or remotes:WaitForChild("JoinQueue", 10)
    end)
end)

local function RunAutoQueue(QueueMode) 
    if JoinQueueRemote then 
        pcall(function() JoinQueueRemote:InvokeServer(QueueMode) end) 
    end 
end 

-- ============================================
-- 🎯 TARGET SYSTEM
-- ============================================
local RayParams = RaycastParams.new(); RayParams.IgnoreWater = true

local function IsValidTarget(char, TeamCheck, WallCheck) 
    if not char then return false end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return false end
    local ply = Players:GetPlayerFromCharacter(char)
    if not ply or ply == plr then return false end
    if TeamCheck and plr.Team and ply.Team and plr.Team == ply.Team then return false end
    if (hrp.Position - Camera.CFrame.Position).Magnitude > MAX_RANGE then return false end
    return true, char:FindFirstChild("Head")
end 

local function GetClosestTarget(ignoreFOV, ignoreWallCheck) 
    local bestDist, bestHead = math.huge, nil 
    local camPos = Camera.CFrame.Position; local center = Camera.ViewportSize / 2
    local currentFOVSize = Options.AimbotFOV and Options.AimbotFOV.Value or 50
    
    for _, ply in pairs(Players:GetPlayers()) do 
        local valid, head = IsValidTarget(ply.Character, true, not ignoreWallCheck)
        if valid and head then 
            local pos = Camera:WorldToViewportPoint(head.Position)
            local dist = ignoreFOV and (head.Position - camPos).Magnitude or (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if ignoreFOV or dist <= currentFOVSize then
                if not ignoreWallCheck then 
                    RayParams.FilterDescendantsInstances = {plr.Character, Camera, workspace:FindFirstChild("ViewModel")} 
                    local ray = WorldRoot:Raycast(camPos, (head.Position - camPos).Unit * MAX_RANGE, RayParams) 
                    if ray and (ray.Position - head.Position).Magnitude > VISIBILITY_TOLERANCE then continue end 
                end 
                if dist < bestDist then bestDist = dist; bestHead = head end 
            end 
        end 
    end 
    return bestHead 
end

local function GetSilentTarget() 
    local bestDist, bestHead = math.huge, nil 
    local camPos = Camera.CFrame.Position
    local center = Camera.ViewportSize / 2
    local currentSilentFOVSize = Options.SilentAimFOV and Options.SilentAimFOV.Value or 120
    
    for _, ply in pairs(Players:GetPlayers()) do 
        local valid, head = IsValidTarget(ply.Character, true, true)
        if valid and head then 
            local pos = Camera:WorldToViewportPoint(head.Position)
            local screenPos = Vector2.new(pos.X, pos.Y)
            local dist = (screenPos - center).Magnitude
            
            if dist <= currentSilentFOVSize then
                RayParams.FilterDescendantsInstances = {plr.Character, Camera, workspace:FindFirstChild("ViewModel")} 
                local ray = WorldRoot:Raycast(camPos, (head.Position - camPos).Unit * MAX_RANGE, RayParams) 
                if ray and (ray.Position - head.Position).Magnitude > VISIBILITY_TOLERANCE then continue end 
                if dist < bestDist then bestDist = dist; bestHead = head end 
            end 
        end 
    end 
    return bestHead 
end

-- ============================================
-- 💥 RAGEBOT SYSTEM (UPDATED WITH ORBIT DESYNC)
-- ============================================
local RagebotData = {Target=nil, IsDesynced=false, CurrentEnemy=nil, HeartbeatConn=nil, DesyncConn=nil, OldStartShooting=nil, GunModule=nil, UtilModule=nil}
pcall(function()
    local ps = plr:WaitForChild("PlayerScripts", 10)
    if ps and ps:FindFirstChild("Modules") and ps.Modules:FindFirstChild("ItemTypes") and ps.Modules.ItemTypes:FindFirstChild("Gun") then
        RagebotData.GunModule = require(ps.Modules.ItemTypes.Gun)
    end
    if ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Utility") then
        RagebotData.UtilModule = require(ReplicatedStorage.Modules.Utility)
    end
end)

local function StopDesync() 
    RagebotData.IsDesynced = false
    RagebotData.CurrentEnemy = nil
    if RagebotData.DesyncConn then 
        RagebotData.DesyncConn:Disconnect()
        RagebotData.DesyncConn = nil 
    end 
end

local function StartDesync(enemy) 
    if RagebotData.DesyncConn then RagebotData.DesyncConn:Disconnect() end
    RagebotData.IsDesynced = true
    RagebotData.CurrentEnemy = enemy
    
    local orbitSpeed = math.random(8, 15)
    local orbitRadius = 1
    local angleOffset = math.random() * math.pi * 2
    local spinSpeed = math.random(5, 10)
    local startTime = tick()
    
    RagebotData.DesyncConn = RunService.Heartbeat:Connect(function()
        if not RagebotData.IsDesynced or not Toggles.Ragebot.Value then return end
        
        local myChar = plr.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        
        local eChar = enemy.Character
        local eHead = eChar and eChar:FindFirstChild("Head")
        if not eHead then 
            StopDesync()
            return 
        end
        
        local time = tick() - startTime
        local angle = time * orbitSpeed + angleOffset
        local orbitX = math.cos(angle) * orbitRadius
        local orbitZ = math.sin(angle) * orbitRadius
        local orbitY = math.sin(time * spinSpeed * 0.5) * 0.5
        
        local spinAngle = time * spinSpeed
        local randomSpin = CFrame.Angles(
            math.rad(math.sin(time * 7) * 30),
            math.rad(spinAngle),
            math.rad(math.cos(time * 5) * 30)
        )
        
        local origC = myRoot.CFrame
        local origV = myRoot.Velocity
        local origR = myRoot.RotVelocity
        
        local targetPos = eHead.Position + Vector3.new(orbitX, orbitY, orbitZ)
        myRoot.CFrame = CFrame.new(targetPos) * randomSpin
        
        RunService:BindToRenderStep("__restore", 101, function() 
            if myRoot and myRoot.Parent then
                myRoot.CFrame = origC
                myRoot.Velocity = origV
                myRoot.RotVelocity = origR
            end
            RunService:UnbindFromRenderStep("__restore") 
        end)
    end) 
end

local function HookGunFramework() 
    if not RagebotData.GunModule or not RagebotData.UtilModule or RagebotData.OldStartShooting then return end
    RagebotData.OldStartShooting = RagebotData.GunModule.StartShooting
    RagebotData.GunModule.StartShooting = function(gun, ...) 
        local res = {RagebotData.OldStartShooting(gun, ...)}
        if not Toggles.Ragebot.Value or not gun.ClientFighter or not gun.ClientFighter.IsLocalPlayer then 
            return unpack(res) 
        end
        local pkt = res[3]
        if not pkt or typeof(pkt) ~= "table" then return unpack(res) end
        res[4] = true
        local t = RagebotData.Target
        if not t or not t.Character then return unpack(res) end
        local h = t.Character:FindFirstChild("Head")
        if not h then return unpack(res) end
        local hp = h.Position
        local hc = h.CFrame
        local off = hc:ToObjectSpace(CFrame.new(hp + Vector3.new(math.random()*0.1, math.random()*0.1, math.random()*0.1)))
        pkt[utf8.char(0)] = RagebotData.UtilModule:EncodeCFrame(CFrame.new(hp, hp + hc.LookVector))
        pkt[utf8.char(1)] = RagebotData.UtilModule:EncodeCFrame(CFrame.new(hp))
        pkt[utf8.char(2)] = h
        pkt[utf8.char(3)] = RagebotData.UtilModule:EncodeCFrame(off)
        return unpack(res)
    end 
end

local function UnhookGunFramework() 
    if RagebotData.OldStartShooting and RagebotData.GunModule then 
        RagebotData.GunModule.StartShooting = RagebotData.OldStartShooting
        RagebotData.OldStartShooting = nil 
    end
    StopDesync() 
end

local function UpdateRagebotState(s) 
    if s then 
        HookGunFramework()
        if RagebotData.HeartbeatConn then RagebotData.HeartbeatConn:Disconnect() end
        RagebotData.HeartbeatConn = RunService.Heartbeat:Connect(function()
            if not Toggles.Ragebot.Value then return end
            local t = GetClosestTarget(true, true)
            if t and t.Parent then 
                local p = Players:GetPlayerFromCharacter(t.Parent)
                RagebotData.Target = p
                if p and (not RagebotData.IsDesynced or RagebotData.CurrentEnemy ~= p) then 
                    StartDesync(p) 
                end
            else 
                RagebotData.Target = nil
                StopDesync() 
            end
        end)
    else 
        UnhookGunFramework()
        if RagebotData.HeartbeatConn then RagebotData.HeartbeatConn:Disconnect()
        RagebotData.HeartbeatConn = nil end 
    end 
end

-- ============================================
-- 🎯 CLIENT AIMBOT
-- ============================================
local AimbotConnection = nil

local function StartAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() end
    
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not Toggles.Aimbot.Value or Toggles.Ragebot.Value then return end
        
        local target = GetClosestTarget(false, false)
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end)
end

local function StopAimbot()
    if AimbotConnection then
        AimbotConnection:Disconnect()
        AimbotConnection = nil
    end
end

-- ============================================
-- 🎯 SILENT AIM
-- ============================================
local SilentAimState = {Active=false, Instance=nil, HeartbeatConn=nil, OriginalFunc=nil, Target=nil}

local function ToggleSilentAim(s) 
    if s then 
        if SilentAimState.Instance then return end
        
        local ok, GunModule = pcall(function() 
            return require(plr.PlayerScripts.Modules.ItemTypes.Gun) 
        end)
        local ok2, UtilModule = pcall(function() 
            return require(ReplicatedStorage.Modules.Utility) 
        end)
        
        if not ok or not ok2 then 
            warn("Failed to load Silent Aim modules")
            return 
        end
        
        SilentAimState.OriginalFunc = GunModule.StartShooting
        SilentAimState.Instance = {Shutdown = function() 
            SilentAimState.Active = false
            if SilentAimState.HeartbeatConn then 
                SilentAimState.HeartbeatConn:Disconnect()
                SilentAimState.HeartbeatConn = nil 
            end
            if SilentAimState.OriginalFunc then 
                GunModule.StartShooting = SilentAimState.OriginalFunc
                SilentAimState.OriginalFunc = nil 
            end
            SilentAimState.Instance = nil
        end}
        
        SilentAimState.HeartbeatConn = RunService.Heartbeat:Connect(function()
            if not SilentAimState.Active then return end
            if ShowSilentFOV then
                SilentAimState.Target = GetSilentTarget()
            else
                SilentAimState.Target = nil
            end
        end)
        
        GunModule.StartShooting = function(gun, ...) 
            local res = {SilentAimState.OriginalFunc(gun, ...)}
            
            if not SilentAimState.Active or not gun.ClientFighter or not gun.ClientFighter.IsLocalPlayer then 
                return unpack(res) 
            end
            
            if not ShowSilentFOV or not SilentAimState.Target then
                return unpack(res)
            end
            
            local pkt = res[3]
            if not pkt or typeof(pkt) ~= "table" then return unpack(res) end
            res[4] = true
            
            local t = SilentAimState.Target
            if not t or not t.Parent then return unpack(res) end
            
            local h = t.Parent:FindFirstChild("Head")
            if not h then return unpack(res) end
            
            local hp = h.Position
            local hc = h.CFrame
            local off = hc:ToObjectSpace(CFrame.new(hp + Vector3.new(math.random()*0.1, math.random()*0.1, math.random()*0.1)))
            
            pkt[utf8.char(0)] = UtilModule:EncodeCFrame(CFrame.new(hp, hp + hc.LookVector))
            pkt[utf8.char(1)] = UtilModule:EncodeCFrame(CFrame.new(hp))
            pkt[utf8.char(2)] = h
            pkt[utf8.char(3)] = UtilModule:EncodeCFrame(off)
            
            return unpack(res)
        end
        
        SilentAimState.Active = true
        
    elseif SilentAimState.Instance then 
        SilentAimState.Instance:Shutdown() 
    end
end

-- ============================================
-- ✅ ESP SYSTEM (FIXED - CLEARS ON PLAYER LEAVE)
-- ============================================
local function createBox()
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Thickness = 2
    box.Transparency = 1
    box.Filled = false
    return box
end

local function createHealthBar()
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Thickness = 1
    healthBar.Transparency = 1
    healthBar.Filled = true
    return healthBar
end

local function createHealthBarBg()
    local healthBarBg = Drawing.new("Square")
    healthBarBg.Visible = false
    healthBarBg.Color = Color3.fromRGB(40, 40, 40)
    healthBarBg.Thickness = 1
    healthBarBg.Transparency = 1
    healthBarBg.Filled = true
    return healthBarBg
end

local function createSkeletonLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Thickness = 1
    line.Transparency = 1
    return line
end

local ESP_Drawings = {}
local ChamHighlights = {}

local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function SetupESP(char)
    if ESP_Drawings[char] then return end
    
    local drawings = {
        Box = createBox(),
        HealthBarBg = createHealthBarBg(),
        HealthBar = createHealthBar(),
        Tracer = Drawing.new("Line"),
        HealthText = Drawing.new("Text"),
        Name = Drawing.new("Text"),
        SkeletonLines = {}
    }
    
    for i = 1, #SkeletonConnections do
        drawings.SkeletonLines[i] = createSkeletonLine()
    end
    
    drawings.Tracer.Thickness = 1
    drawings.Tracer.Color = Color3.new(1, 1, 1)
    
    drawings.HealthText.Size = 14
    drawings.HealthText.Color = Color3.new(0, 1, 0)
    drawings.HealthText.Center = true
    
    drawings.Name.Size = 14
    drawings.Name.Color = Color3.new(1, 1, 1)
    drawings.Name.Center = true
    
    ESP_Drawings[char] = drawings
end

local function ClearESP(char)
    local espData = ESP_Drawings[char]
    if espData then
        pcall(function() espData.Box:Remove() end)
        pcall(function() espData.HealthBarBg:Remove() end)
        pcall(function() espData.HealthBar:Remove() end)
        pcall(function() espData.Tracer:Remove() end)
        pcall(function() espData.HealthText:Remove() end)
        pcall(function() espData.Name:Remove() end)
        for _, line in pairs(espData.SkeletonLines) do
            pcall(function() line:Remove() end)
        end
        ESP_Drawings[char] = nil
    end
    if ChamHighlights[char] then
        pcall(function() ChamHighlights[char]:Destroy() end)
        ChamHighlights[char] = nil
    end
end

local function UpdateChams()
    for _, p in pairs(Players:GetPlayers()) do
        if p == plr then continue end
        local c = p.Character
        if not c then continue end
        local hum = c:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then
            if ChamHighlights[c] then
                ChamHighlights[c].Enabled = false
            end
            continue
        end
        if Toggles.ChamESP.Value and Toggles.EnableESP.Value then
            if not ChamHighlights[c] then
                local h = Instance.new("Highlight")
                h.FillColor = Color3.new(1, 0, 0)
                h.OutlineColor = Color3.new(1, 1, 1)
                h.FillTransparency = 0.4
                h.OutlineTransparency = 0.2
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = c
                ChamHighlights[c] = h
            end
            ChamHighlights[c].Enabled = true
        else
            if ChamHighlights[c] then
                ChamHighlights[c].Enabled = false
            end
        end
    end
end

local function UpdateESP()
    for char, _ in pairs(ESP_Drawings) do
        if not char or not char.Parent then
            ClearESP(char)
        end
    end
    
    if not Toggles.EnableESP.Value then
        for char, drawings in pairs(ESP_Drawings) do
            drawings.Box.Visible = false
            drawings.HealthBarBg.Visible = false
            drawings.HealthBar.Visible = false
            drawings.Tracer.Visible = false
            drawings.HealthText.Visible = false
            drawings.Name.Visible = false
            for _, line in pairs(drawings.SkeletonLines) do
                line.Visible = false
            end
        end
        UpdateChams()
        return
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p == plr then continue end
        local c = p.Character
        if not c then continue end
        
        local hum = c:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then
            if ESP_Drawings[c] then
                ESP_Drawings[c].Box.Visible = false
                ESP_Drawings[c].HealthBarBg.Visible = false
                ESP_Drawings[c].HealthBar.Visible = false
                ESP_Drawings[c].Tracer.Visible = false
                ESP_Drawings[c].HealthText.Visible = false
                ESP_Drawings[c].Name.Visible = false
                for _, line in pairs(ESP_Drawings[c].SkeletonLines) do
                    line.Visible = false
                end
            end
            if ChamHighlights[c] then
                ChamHighlights[c].Enabled = false
            end
            continue
        end
        
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
        if distance > MAX_RANGE then
            if ESP_Drawings[c] then
                ESP_Drawings[c].Box.Visible = false
                ESP_Drawings[c].HealthBarBg.Visible = false
                ESP_Drawings[c].HealthBar.Visible = false
                ESP_Drawings[c].Tracer.Visible = false
                ESP_Drawings[c].HealthText.Visible = false
                ESP_Drawings[c].Name.Visible = false
                for _, line in pairs(ESP_Drawings[c].SkeletonLines) do
                    line.Visible = false
                end
            end
            continue
        end
        
        SetupESP(c)
        local h = c:FindFirstChild("Head")
        if not h then continue end
        
        local s = ESP_Drawings[c]
        local vis = true
        if p.Team and plr.Team and p.Team == plr.Team then
            vis = false
        end
        
        local hrpPos, hrpVis = Camera:WorldToViewportPoint(hrp.Position)
        local hPos = Camera:WorldToViewportPoint(h.Position + Vector3.new(0, 0.5, 0))
        
        if not hrpVis or hrpPos.Z <= 0 then
            s.Box.Visible = false
            s.HealthBarBg.Visible = false
            s.HealthBar.Visible = false
            s.Tracer.Visible = false
            s.HealthText.Visible = false
            s.Name.Visible = false
            for _, line in pairs(s.SkeletonLines) do
                line.Visible = false
            end
            continue
        end
        
        local headPos = h.Position
        local footPos = hrp.Position - Vector3.new(0, 3, 0)
        
        local headScreenPos = Camera:WorldToViewportPoint(headPos)
        local footScreenPos = Camera:WorldToViewportPoint(footPos)
        
        local boxHeight = math.abs(headScreenPos.Y - footScreenPos.Y)
        local boxWidth = boxHeight * 0.65
        
        s.Box.Visible = vis and Toggles.BoxESP.Value
        if s.Box.Visible then
            s.Box.Color = Color3.fromRGB(0, 255, 0)
            s.Box.Size = Vector2.new(boxWidth, boxHeight)
            s.Box.Position = Vector2.new(hPos.X - boxWidth / 2, headScreenPos.Y)
        end
        
        local showHealthBar = vis and Toggles.HealthBarESP and Toggles.HealthBarESP.Value
        if not Toggles.HealthBarESP then showHealthBar = false end
        
        s.HealthBarBg.Visible = showHealthBar
        s.HealthBar.Visible = showHealthBar
        
        if showHealthBar then
            local barWidth = 3
            local barHeight = boxHeight
            local barX = hPos.X - boxWidth / 2 - barWidth - 2
            
            s.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
            s.HealthBarBg.Position = Vector2.new(barX, headScreenPos.Y)
            
            local healthPercent = hum.Health / hum.MaxHealth
            local healthBarHeight = barHeight * healthPercent
            
            s.HealthBar.Size = Vector2.new(barWidth, healthBarHeight)
            s.HealthBar.Position = Vector2.new(barX, headScreenPos.Y + (barHeight - healthBarHeight))
            
            if healthPercent > 0.5 then
                s.HealthBar.Color = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.25 then
                s.HealthBar.Color = Color3.fromRGB(255, 255, 0)
            else
                s.HealthBar.Color = Color3.fromRGB(255, 0, 0)
            end
        end
        
        local showSkeleton = vis and Toggles.SkeletonESP and Toggles.SkeletonESP.Value
        if not Toggles.SkeletonESP then showSkeleton = false end
        
        for i, connection in pairs(SkeletonConnections) do
            local line = s.SkeletonLines[i]
            if line then
                line.Visible = showSkeleton
                if showSkeleton then
                    local part1 = c:FindFirstChild(connection[1])
                    local part2 = c:FindFirstChild(connection[2])
                    
                    if part1 and part2 then
                        local pos1 = Camera:WorldToViewportPoint(part1.Position)
                        local pos2 = Camera:WorldToViewportPoint(part2.Position)
                        
                        line.From = Vector2.new(pos1.X, pos1.Y)
                        line.To = Vector2.new(pos2.X, pos2.Y)
                        line.Color = Color3.fromRGB(255, 255, 255)
                    else
                        line.Visible = false
                    end
                end
            end
        end
        
        s.Tracer.Visible = vis and Toggles.TracerESP.Value
        if s.Tracer.Visible then
            s.Tracer.From = Camera.ViewportSize / 2
            s.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
        end
        
        s.HealthText.Visible = vis and Toggles.HealthESP.Value
        if s.HealthText.Visible then
            local hpPercent = math.round((hum.Health / hum.MaxHealth) * 100)
            s.HealthText.Text = hpPercent .. "%"
            s.HealthText.Position = Vector2.new(hPos.X, hPos.Y + boxHeight * 0.5 + 10)
            s.HealthText.Color = hpPercent > 50 and Color3.new(0, 1, 0) or hpPercent > 25 and Color3.new(1, 1, 0) or Color3.new(1, 0, 0)
        end
        
        s.Name.Visible = vis and Toggles.NameESP.Value
        if s.Name.Visible then
            s.Name.Text = p.Name
            s.Name.Position = Vector2.new(hPos.X, headScreenPos.Y - 10)
        end
    end
    UpdateChams()
end

-- ============================================
-- 💥 DAMAGE INDICATOR SYSTEM (FIXED - HEALTH TRACKING)
-- ============================================
local DamageIndicators = {}
local EnemyHealthCache = {}

local function CreateDamageIndicator(position, damage)
    local indicator = {
        Text = Drawing.new("Text"),
        StartTime = tick(),
        Duration = 1.5,
        Damage = damage,
        StartPosition = position,
        OffsetX = math.random(-30, 30)
    }
    
    indicator.Text.Text = "-" .. tostring(damage)
    indicator.Text.Size = 22
    indicator.Text.Color = Color3.fromRGB(255, 255, 50)
    indicator.Text.Center = true
    indicator.Text.Outline = true
    indicator.Text.OutlineColor = Color3.fromRGB(0, 0, 0)
    indicator.Text.Font = Drawing.Fonts.UI
    indicator.Text.Visible = true
    
    return indicator
end

local function UpdateDamageIndicators()
    local currentTime = tick()
    
    -- Check enemy health changes
    for _, player in pairs(Players:GetPlayers()) do
        if player == plr then continue end
        
        local char = player.Character
        if not char then
            EnemyHealthCache[player] = nil
            continue
        end
        
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then
            EnemyHealthCache[player] = nil
            continue
        end
        
        local currentHealth = hum.Health
        local previousHealth = EnemyHealthCache[player]
        
        if previousHealth and currentHealth < previousHealth then
            local damage = math.floor(previousHealth - currentHealth)
            if damage > 0 then
                local head = char:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local pos = Vector2.new(screenPos.X, screenPos.Y - 20)
                        table.insert(DamageIndicators, CreateDamageIndicator(pos, damage))
                    end
                end
            end
        end
        
        EnemyHealthCache[player] = currentHealth
    end
    
    -- Update existing indicators
    for i = #DamageIndicators, 1, -1 do
        local indicator = DamageIndicators[i]
        local elapsed = currentTime - indicator.StartTime
        
        if elapsed >= indicator.Duration then
            pcall(function() indicator.Text:Remove() end)
            table.remove(DamageIndicators, i)
        else
            local progress = elapsed / indicator.Duration
            
            local floatY = -60 * progress
            local driftX = indicator.OffsetX * math.sin(progress * math.pi * 2)
            local currentPos = indicator.StartPosition + Vector2.new(driftX, floatY)
            
            indicator.Text.Position = currentPos
            
            local scale
            if progress < 0.15 then
                scale = 0.5 + (progress / 0.15) * 1.0
            else
                scale = 1.5 - ((progress - 0.15) / 0.85) * 0.5
            end
            indicator.Text.Size = math.floor(22 * scale)
            
            local alpha
            if progress < 0.7 then
                alpha = 1
            else
                alpha = 1 - ((progress - 0.7) / 0.3)
            end
            indicator.Text.Transparency = 1 - alpha
            
            local damageColor
            if indicator.Damage > 50 then
                damageColor = Color3.fromRGB(255, 30, 30)
            elseif indicator.Damage > 25 then
                damageColor = Color3.fromRGB(255, 140, 30)
            else
                damageColor = Color3.fromRGB(255, 255, 50)
            end
            indicator.Text.Color = damageColor
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    local char = player.Character
    if char then
        ClearESP(char)
    end
    EnemyHealthCache[player] = nil
end)

-- ============================================
-- 🎨 CREATE LINORIA WINDOW
-- ============================================
local Window = Library:CreateWindow({
    Title = "OISHI HUB",
    Footer = "RIVALS | v1.0",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "crosshair"),
    Visual = Window:AddTab("Visual", "eye"),
    Misc = Window:AddTab("Misc", "wrench"),
    ["UI Settings"] = Window:AddTab("UI Settings", "palette"),
}

-- ============================================
-- MAIN TAB
-- ============================================
local CombatGroup = Tabs.Main:AddLeftGroupbox("Combat", "swords")

CombatGroup:AddToggle("Aimbot", {
    Text = "Aimbot",
    Tooltip = "Automatically aims at enemies within FOV",
    Default = false,
    Callback = function(Value)
        if Value then
            StartAimbot()
            local center = Camera.ViewportSize / 2
            MainFOVCurrentPos = center
            MainFOVTargetPos = center
            FOVCircle.Position = center
            FOVHalf.Position = center
        else
            StopAimbot()
        end
    end,
})

CombatGroup:AddToggle("ShowFOV", {
    Text = "Show Aimbot FOV",
    Tooltip = "Displays the aimbot field of view circle",
    Default = true,
    Callback = function(Value)
        FOVCircle.Visible = Value
        FOVHalf.Visible = Value
        if not Value then
            local cen = Camera.ViewportSize/2
            MainFOVCurrentPos = cen
            MainFOVTargetPos = cen
            FOVCircle.Position = cen
            FOVHalf.Position = cen
        end
    end,
})

CombatGroup:AddSlider("AimbotFOV", {
    Text = "Aimbot FOV Size",
    Tooltip = "Adjust the aimbot field of view radius",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        FOVCircle.Radius = Value
        FOVHalf.Radius = Value
    end,
})

CombatGroup:AddToggle("SilentAim", {
    Text = "Silent Aim",
    Tooltip = "Aims without moving your camera",
    Default = false,
    Callback = function(Value)
        ToggleSilentAim(Value)
    end,
})

CombatGroup:AddToggle("ShowSilentFOV", {
    Text = "Show Silent FOV",
    Tooltip = "Displays the silent aim field of view circle",
    Default = false,
    Callback = function(Value)
        ShowSilentFOV = Value
        SilentFOVCircle.Visible = Value
        SilentFOVHalf.Visible = Value
        if not Value then
            local cen = Camera.ViewportSize/2
            SilentFOVCurrentPos = cen
            SilentFOVTargetPos = cen
            SilentFOVCircle.Position = cen
            SilentFOVHalf.Position = cen
        end
    end,
})

CombatGroup:AddSlider("SilentAimFOV", {
    Text = "Silent Aim FOV Size",
    Tooltip = "Adjust the silent aim field of view radius",
    Default = 120,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        SilentFOVCircle.Radius = Value
        SilentFOVHalf.Radius = Value
    end,
})

local RagebotGroup = Tabs.Main:AddRightGroupbox("Ragebot", "zap")

RagebotGroup:AddToggle("Ragebot", {
    Text = "Ragebot",
    Tooltip = "Aggressive aimbot with orbit desync around enemies",
    Default = false,
    Callback = function(Value)
        UpdateRagebotState(Value)
    end,
})

-- ============================================
-- VISUAL TAB
-- ============================================
local ESPGroup = Tabs.Visual:AddLeftGroupbox("ESP Settings", "eye")

ESPGroup:AddToggle("EnableESP", {
    Text = "Enable ESP",
    Tooltip = "Master toggle for all ESP features",
    Default = true,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("BoxESP", {
    Text = "Box ESP",
    Tooltip = "Draws 2D boxes around enemies",
    Default = true,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("HealthBarESP", {
    Text = "Health Bar",
    Tooltip = "Shows a health bar on the left side of enemies",
    Default = true,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("SkeletonESP", {
    Text = "Skeleton ESP",
    Tooltip = "Draws skeleton lines on enemies",
    Default = false,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("HealthESP", {
    Text = "Health Text",
    Tooltip = "Shows enemy health percentage as text",
    Default = true,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("TracerESP", {
    Text = "Tracer ESP",
    Tooltip = "Draws lines from crosshair to enemies",
    Default = true,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("ChamESP", {
    Text = "Chams",
    Tooltip = "Highlights enemies through walls",
    Default = false,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("NameESP", {
    Text = "Name ESP",
    Tooltip = "Shows enemy names above their head",
    Default = false,
    Callback = function(Value) end,
})

ESPGroup:AddToggle("DamageIndicators", {
    Text = "Damage Indicators",
    Tooltip = "Shows floating damage numbers when you hit enemies",
    Default = true,
    Callback = function(Value) end,
})

-- ============================================
-- MISC TAB
-- ============================================
local MovementGroup = Tabs.Misc:AddLeftGroupbox("Movement", "move")

MovementGroup:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Tooltip = "Allows you to jump infinitely",
    Default = true,
    Callback = function(Value)
        ToggleJump(Value)
    end,
})

MovementGroup:AddToggle("NoClip", {
    Text = "NoClip",
    Tooltip = "Walk through walls and objects",
    Default = false,
    Callback = function(Value)
        ToggleNoClip(Value)
    end,
})

local CameraGroup = Tabs.Misc:AddLeftGroupbox("Camera", "camera")

CameraGroup:AddToggle("ThirdPerson", {
    Text = "3rd Person",
    Tooltip = "Instantly switch to third person camera view",
    Default = false,
    Callback = function(Value)
        if Value then
            pcall(function()
                plr.CameraMode = Enum.CameraMode.Classic
                plr.CameraMinZoomDistance = 15
                plr.CameraMaxZoomDistance = 15
                
                local char = plr.Character
                if char then
                    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
                    if humanoid then
                        humanoid.CameraOffset = Vector3.new(0, 0, 0)
                    end
                end
                
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = plr.Character and plr.Character:FindFirstChildWhichIsA("Humanoid")
                
                task.wait(0.05)
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = plr.Character.HumanoidRootPart
                    Camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 15), hrp.Position)
                end
            end)
            
            Library:Notify({
                Title = "Camera",
                Description = "3rd Person mode enabled",
                Time = 2,
            })
        else
            pcall(function()
                plr.CameraMode = Enum.CameraMode.LockFirstPerson
                plr.CameraMinZoomDistance = 0
                plr.CameraMaxZoomDistance = 0
                
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = plr.Character and plr.Character:FindFirstChildWhichIsA("Humanoid")
            end)
            
            Library:Notify({
                Title = "Camera",
                Description = "1st Person mode restored",
                Time = 2,
            })
        end
    end,
})

local WeaponGroup = Tabs.Misc:AddRightGroupbox("Weapons", "gun")

WeaponGroup:AddToggle("RapidFire", {
    Text = "Rapid Fire",
    Tooltip = "Removes weapon cooldowns for instant fire rate",
    Default = false,
    Callback = function(Value)
        ToggleRapidFire(Value)
    end,
})

local ProtectionGroup = Tabs.Misc:AddRightGroupbox("Protection", "shield")

ProtectionGroup:AddToggle("AntiHit", {
    Text = "Orbit Anti-Hit",
    Tooltip = "Body parts orbit at 8 studs with configurable speed (stable, no bouncing)",
    Default = false,
    Callback = function(Value)
        ToggleAntiHit(Value)
    end,
})

ProtectionGroup:AddSlider("OrbitSpeedSlider", {
    Text = "Orbit Speed",
    Tooltip = "Adjust the orbit speed multiplier (1 = normal, 2 = double, 0.5 = half)",
    Default = 1,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Compact = false,
    Callback = function(Value) end,
})

local MatchGroup = Tabs.Misc:AddLeftGroupbox("Matchmaking", "play")

MatchGroup:AddToggle("AutoQueue", {
    Text = "Auto Queue",
    Tooltip = "Automatically joins matches when available",
    Default = false,
    Callback = function(Value) end,
})

MatchGroup:AddDropdown("QueueMode", {
    Values = {"1v1", "2v2", "3v3", "4v4", "5v5"},
    Default = "1v1",
    Multi = false,
    Text = "Queue Mode",
    Tooltip = "Select the match type to queue for",
    Callback = function(Value) end,
})

MatchGroup:AddButton({
    Text = "Join Queue Now",
    Func = function()
        RunAutoQueue(Options.QueueMode.Value)
        Library:Notify({
            Title = "Matchmaking",
            Description = "Attempting to join " .. Options.QueueMode.Value .. " queue...",
            Time = 3,
        })
    end,
    DoubleClick = false,
    Tooltip = "Manually join the selected queue",
})

-- ============================================
-- UI SETTINGS TAB
-- ============================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})

ThemeManager:SetFolder("OishiHub")
SaveManager:SetFolder("OishiHub/Rivals")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "settings")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddSlider("UICornerSlider", {
    Text = "Corner Radius",
    Default = Library.CornerRadius,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(value)
        Window:SetCornerRadius(value)
    end
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

-- ============================================
-- CHARACTER RESPAWN HANDLER
-- ============================================
plr.CharacterAdded:Connect(function()
    task.wait(0.3)
    workspace.Gravity = OriginalGravity
    
    if Toggles.ThirdPerson and Toggles.ThirdPerson.Value then
        task.wait(0.1)
        pcall(function()
            plr.CameraMode = Enum.CameraMode.Classic
            plr.CameraMinZoomDistance = 15
            plr.CameraMaxZoomDistance = 15
            
            local char = plr.Character
            if char then
                local humanoid = char:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    task.wait(0.05)
                    Camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 15), hrp.Position)
                end
            end
            
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = plr.Character and plr.Character:FindFirstChildWhichIsA("Humanoid")
        end)
    end
    
    if Toggles.AntiHit.Value then
        ToggleAntiHit(true)
    end
    
    if Toggles.Ragebot.Value then UpdateRagebotState(true) end
    if Toggles.SilentAim.Value then ToggleSilentAim(true) end
    if Toggles.RapidFire.Value then ToggleRapidFire(true) end
    if Toggles.NoClip.Value then ToggleNoClip(true) end
    if Toggles.InfiniteJump.Value then ToggleJump(true) end
    if Toggles.Aimbot.Value then StartAimbot() end
    
    if Options.AimbotFOV then
        FOVCircle.Radius = Options.AimbotFOV.Value
        FOVHalf.Radius = Options.AimbotFOV.Value
    end
    if Options.SilentAimFOV then
        SilentFOVCircle.Radius = Options.SilentAimFOV.Value
        SilentFOVHalf.Radius = Options.SilentAimFOV.Value
    end
end)

-- ============================================
-- INITIAL SETUP
-- ============================================
task.spawn(function()
    PlayNotificationSound()
    task.wait(0.3)
    Library:Notify({
        Title = "✨ OISHI HUB",
        Description = "RIVALS Loaded Successfully!\nPress Right Shift to open menu",
        Time = 5,
    })
end)

FOVCircle.Radius = Options.AimbotFOV and Options.AimbotFOV.Value or 50
FOVHalf.Radius = Options.AimbotFOV and Options.AimbotFOV.Value or 50
SilentFOVCircle.Radius = Options.SilentAimFOV and Options.SilentAimFOV.Value or 120
SilentFOVHalf.Radius = Options.SilentAimFOV and Options.SilentAimFOV.Value or 120

if Toggles.Ragebot.Value then UpdateRagebotState(true) end
if Toggles.SilentAim.Value then ToggleSilentAim(true) end
if Toggles.RapidFire.Value then ToggleRapidFire(true) end
if Toggles.NoClip.Value then ToggleNoClip(true) end
if Toggles.InfiniteJump.Value then ToggleJump(true) end
if Toggles.AntiHit.Value then ToggleAntiHit(true) end
if Toggles.Aimbot.Value then StartAimbot() end
if Toggles.ThirdPerson and Toggles.ThirdPerson.Value then
    pcall(function()
        plr.CameraMode = Enum.CameraMode.Classic
        plr.CameraMinZoomDistance = 15
        plr.CameraMaxZoomDistance = 15
    end)
end

-- ============================================
-- MAIN RENDER LOOP
-- ============================================
RunService:BindToRenderStep("MainLoop", Enum.RenderPriority.Camera.Value + 10, function() 
    local viewportSize = Camera.ViewportSize
    local center = viewportSize / 2
    
    if Toggles.AutoQueue.Value then
        RunAutoQueue(Options.QueueMode.Value)
    end
    
    if FOVCircle.Visible then
        if Toggles.Aimbot.Value then
            local centerPos = Camera.ViewportSize / 2
            FOVCircle.Position = centerPos
            FOVHalf.Position = centerPos
            MainFOVCurrentPos = centerPos
            MainFOVTargetPos = centerPos
        else
            local follow = GetClosestTarget(true, true)
            if follow then 
                local sp = Camera:WorldToViewportPoint(follow.Position)
                MainFOVTargetPos = Vector2.new(sp.X, sp.Y)
            else 
                MainFOVTargetPos = center
            end
            
            MainFOVCurrentPos = MainFOVCurrentPos:Lerp(MainFOVTargetPos, SMOOTH_FOV_SPEED)
            FOVCircle.Position = MainFOVCurrentPos
            FOVHalf.Position = MainFOVCurrentPos
        end
    end
    
    if ShowSilentFOV then
        local follow = GetSilentTarget()
        if follow then 
            local sp = Camera:WorldToViewportPoint(follow.Position)
            SilentFOVTargetPos = Vector2.new(sp.X, sp.Y)
        else 
            SilentFOVTargetPos = center
        end
        
        SilentFOVCurrentPos = SilentFOVCurrentPos:Lerp(SilentFOVTargetPos, SMOOTH_FOV_SPEED)
        SilentFOVCircle.Position = SilentFOVCurrentPos
        SilentFOVHalf.Position = SilentFOVCurrentPos
    end
    
    UpdateESP()
    
    if Toggles.DamageIndicators.Value then
        UpdateDamageIndicators()
    end
end)

print("✨ OISHI HUB RIVALS - Linoria Edition loaded successfully!")
print("⌨️ Press Right Shift to open/close the menu!")
