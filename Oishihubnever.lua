local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local Camera = workspace.CurrentCamera 
local UserInputService = game:GetService("UserInputService") 
local TweenService = game:GetService("TweenService") 
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local Lighting = game:GetService("Lighting") 
local plr = Players.LocalPlayer 
local WorldRoot = workspace 

-- ⚙️ CONFIG — FULLY KEPT 
local MAX_RANGE = 260 
local FOV_SIZE = 130 
local VISIBILITY_TOLERANCE = 2 
local TELEPORT_HEIGHT = 3 
local STAR_RADIUS = 4 
local CORNER_SWITCH_SPEED = 0.12 
local INSTANT_SNAP_ALWAYS = true 
local BOX_SIZE = 8 

-- ✅ LOAD/SAVE — FULLY KEPT (Adjusted defaults based on requirements)
local function LoadSaved(key, default) 
    local defaultStates = { 
        Aimbot = true,      -- Now defaults to true
        ShowFOV = true,     -- Now defaults to true
        Ragebot = false,    -- Turned off by default
        ESP = true, 
        Box = true, 
        Tracer = true, 
        Health = true, 
        InfiniteJump = true, 
        NoClip = false,     -- Turned off by default
        AutoQueue = false,  -- Turned off by default
        QueueMode = "1v1", 
        UI_Open = false 
    } 
    local p_default = defaultStates[key] ~= nil and defaultStates[key] or default
    local ok, val = pcall(function() return plr:GetAttribute("OishiHub_"..key) end) 
    return ok and val ~= nil and val or p_default
end 

local function SaveSetting(key, value) 
    pcall(function() plr:SetAttribute("OishiHub_"..key, value) end) 
end 

-- ✅ FEATURES TABLE 
local Features = { 
    UI_Open = LoadSaved("UI_Open", false), 
    Main = { 
        Aimbot = LoadSaved("Aimbot", true), 
        ShowFOV = LoadSaved("ShowFOV", true), 
        Ragebot = LoadSaved("Ragebot", false), 
        TeamCheck = LoadSaved("TeamCheck", true), 
        WallCheck = LoadSaved("WallCheck", true) 
    }, 
    Visual = { 
        ESP = LoadSaved("ESP", true), 
        Box = LoadSaved("Box", true), 
        Name = LoadSaved("Name", false), 
        Tracer = LoadSaved("Tracer", true), 
        Health = LoadSaved("Health", true), 
        Cham = LoadSaved("Cham", false) 
    }, 
    Misc = { 
        InfiniteJump = LoadSaved("InfiniteJump", true), 
        NoClip = LoadSaved("NoClip", false) 
    }, 
    Settings = { 
        AutoQueue = LoadSaved("AutoQueue", false), 
        QueueMode = LoadSaved("QueueMode", "1v1") 
    } 
} 

-- ✅ GRAVITY FIX — NOW SAVES ORIGINAL VALUE PERMANENTLY 
local OriginalGravity = workspace.Gravity 
local CurrentTargetHead = nil 
local CurrentCornerIndex = 1 
local LastCornerSwitch = 0 
local NoClipConn = nil 

-- ✅ SAVE ORIGINAL GRAVITY ON START + WHEN IT CHANGES 
task.spawn(function() 
    workspace:GetPropertyChangedSignal("Gravity"):Connect(function() 
        OriginalGravity = workspace.Gravity 
    end) 
end) 

-- ✅ STAR MOVEMENT POINTS — FULLY KEPT 
local STAR_POINTS = {} 
do 
    local angleStep = math.rad(72) 
    local startAngle = math.rad(-90) 
    for i = 1, 5 do 
        local ang = startAngle + (i-1)*angleStep 
        local r = (i % 2 == 1) and STAR_RADIUS or STAR_RADIUS * 0.4 
        STAR_POINTS[i] = Vector3.new( 
            math.cos(ang) * r, 
            TELEPORT_HEIGHT, 
            math.sin(ang) * r 
        ) 
    end 
end 

-- 🎯 FOV CIRCLE — FULLY KEPT 
local FOVCircle = Drawing.new("Circle") 
FOVCircle.Radius = FOV_SIZE; FOVCircle.Thickness = 2; FOVCircle.Color = Color3.new(0, 1, 0) 
FOVCircle.Transparency = 0.8; FOVCircle.Filled = false; FOVCircle.Visible = Features.Main.ShowFOV 

-- ✅ AUTO QUEUE — FULLY KEPT 
local JoinQueueRemote = nil 
task.spawn(function() 
    pcall(function() 
        JoinQueueRemote = ReplicatedStorage:WaitForChild("Remotes", 60):WaitForChild("Matchmaking", 60):WaitForChild("JoinQueue", 60) 
    end) 
end) 

local function RunAutoQueue() 
    if not JoinQueueRemote or not Features.Settings.AutoQueue then return end 
    pcall(function() JoinQueueRemote:InvokeServer(Features.Settings.QueueMode) end) 
end 

-- ⬆️ INFINITE JUMP 
local JumpConn = nil 
local function ToggleJump(state) 
    Features.Misc.InfiniteJump = state 
    SaveSetting("InfiniteJump", state) 
    if JumpConn then 
        JumpConn:Disconnect() 
        JumpConn = nil 
    end 
    if state then 
        JumpConn = UserInputService.JumpRequest:Connect(function() 
            local c = plr.Character; 
            if c then 
                local h = c:FindFirstChildWhichIsA("Humanoid", true) 
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end 
            end 
        end) 
    end 
end 

-- ✅ NOCLIP — FULLY KEPT 
local function ToggleNoClip(state) 
    Features.Misc.NoClip = state 
    SaveSetting("NoClip", state) 
    if NoClipConn then 
        NoClipConn:Disconnect() 
        NoClipConn = nil 
    end 
    if state then 
        NoClipConn = RunService.Stepped:Connect(function() 
            local char = plr.Character 
            if char then 
                local hum = char:FindFirstChildWhichIsA("Humanoid") 
                if hum then hum.PlatformStand = true end 
                for _, part in pairs(char:GetDescendants()) do 
                    if part:IsA("BasePart") then part.CanCollide = false end 
                end 
            end 
        end) 
    else 
        local char = plr.Character 
        if char then 
            local hum = char:FindFirstChildWhichIsA("Humanoid") 
            if hum then hum.PlatformStand = false end 
            for _, part in pairs(char:GetDescendants()) do 
                if part:IsA("BasePart") then part.CanCollide = true end 
            end 
        end 
    end 
end 

-- 🎨 SWITCH UI — MADE BUTTONS SMALLER 
local function CreateSwitch(parent, posY, labelText, callback, saveKey) 
    local Container = Instance.new("Frame", parent) 
    Container.Size = UDim2.new(1,0,0,24) 
    Container.Position = UDim2.new(0,0,0,posY) 
    Container.BackgroundTransparency = 1 
     
    local Switch = Instance.new("Frame", Container) 
    Switch.Size = UDim2.new(0,26,0,14) 
    Switch.Position = UDim2.new(0,2,0.5,-7) 
    Switch.BackgroundColor3 = Color3.fromRGB(220,80,80) 
    Switch.BorderSizePixel = 0 
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1,0) 
     
    local Knob = Instance.new("Frame", Switch) 
    Knob.Size = UDim2.new(0,10,0,10) 
    Knob.Position = UDim2.new(0,2,0,2) 
    Knob.BackgroundColor3 = Color3.new(1,1,1) 
    Knob.BorderSizePixel = 0 
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0) 
     
    local Label = Instance.new("TextLabel", Container) 
    Label.Size = UDim2.new(1,-36,1,0) 
    Label.Position = UDim2.new(0,34,0,0) 
    Label.BackgroundTransparency = 1 
    Label.Text = labelText 
    Label.TextColor3 = Color3.new(0,0,0) 
    Label.Font = Enum.Font.GothamSemibold 
    Label.TextSize = 10 
    Label.TextXAlignment = Enum.TextXAlignment.Left 
     
    local State = saveKey and LoadSaved(saveKey, false) or false 
    local TweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad) 
     
    local function Update(newState) 
        State = newState 
        if saveKey then SaveSetting(saveKey, State) end 
        TweenService:Create(Switch, TweenInfo, {BackgroundColor3 = State and Color3.fromRGB(80,180,80) or Color3.fromRGB(220,80,80)}):Play() 
        TweenService:Create(Knob, TweenInfo, {Position = State and UDim2.new(0,14,0,2) or UDim2.new(0,2,0,2)}):Play() 
        callback(State) 
    end 
     
    Update(State) 
    Switch.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Update(not State) 
        end 
    end) 
    return Switch, function() return State end, Update 
end 

-- 📋 QUEUE SELECTOR 
local function CreateQueueSelector(parent, posY) 
    local Container = Instance.new("Frame", parent) 
    Container.Size = UDim2.new(1,0,0,26) 
    Container.Position = UDim2.new(0,0,0,posY) 
    Container.BackgroundTransparency = 1 
     
    local Button = Instance.new("TextButton", Container) 
    Button.Size = UDim2.new(1,0,1,0) 
    Button.BackgroundColor3 = Color3.new(0.2,0.2,0.2) 
    Button.TextColor3 = Color3.new(1,1,1) 
    Button.Font = Enum.Font.Gotham 
    Button.TextSize = 10 
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0,4) 
     
    local Options = Instance.new("Frame", Container) 
    Options.Size = UDim2.new(1,0,0,130) 
    Options.Position = UDim2.new(0,0,1,4) 
    Options.BackgroundColor3 = Color3.new(1,1,1) 
    Options.Visible = false 
    Instance.new("UICorner", Options).CornerRadius = UDim.new(0,4) 
     
    local List = {"1v1","2v2","3v3","4v4","5v5"} 
    for i,mode in pairs(List) do 
        local OptBtn = Instance.new("TextButton", Options) 
        OptBtn.Size = UDim2.new(1,0,0,24) 
        OptBtn.Position = UDim2.new(0,0,0,(i-1)*26) 
        OptBtn.BackgroundTransparency = 0.2 
        OptBtn.BackgroundColor3 = Color3.new(1,1,1) 
        OptBtn.Text = mode 
        OptBtn.TextColor3 = Color3.new(0,0,0) 
        OptBtn.Font = Enum.Font.Gotham 
        OptBtn.TextSize = 10 
        OptBtn.MouseButton1Click:Connect(function() 
            Features.Settings.QueueMode = mode 
            SaveSetting("QueueMode", mode) 
            Button.Text = "Mode: "..mode 
            Options.Visible = false 
        end) 
    end 
     
    Button.Text = "Mode: "..Features.Settings.QueueMode 
    Button.MouseButton1Click:Connect(function() 
        Options.Visible = not Options.Visible 
    end) 
    return Container 
end 

-- 🎯 RAYCAST & TARGET CHECK — FULLY KEPT 
local RayParams = RaycastParams.new() 
RayParams.IgnoreWater = true 
local function IsValidTarget(char) 
    if not char then return false end 
    local hum = char:FindFirstChildWhichIsA("Humanoid", true) 
    local hrp = char:FindFirstChild("HumanoidRootPart", true) 
    if not hum or not hrp or hum.Health <= 0 then return false end 
    local ply = Players:GetPlayerFromCharacter(char) 
    if not ply or ply == plr then return false end 
    if Features.Main.TeamCheck then 
        local myTeam = plr.Team 
        local theirTeam = ply.Team 
        if myTeam and theirTeam and myTeam == theirTeam then return false end 
    end 
    if (hrp.Position - Camera.CFrame.Position).Magnitude > MAX_RANGE then return false end 
    return true, char:FindFirstChild("Head", true) 
end 

local function GetClosestTarget(ignoreFOV, ignoreWallCheck) 
    local bestDist, bestHead = math.huge, nil 
    local camPos = Camera.CFrame.Position 
    local center = Camera.ViewportSize / 2 
    for _, ply in Players:GetPlayers() do 
        local valid, head = IsValidTarget(ply.Character) 
        if valid and head then 
            local pos = Camera:WorldToViewportPoint(head.Position) 
            if pos.Z > 0 then 
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude 
                if (ignoreFOV or dist <= FOV_SIZE) and dist < bestDist then 
                    if not ignoreWallCheck and Features.Main.WallCheck then 
                        RayParams.FilterDescendantsInstances = {plr.Character, Camera, workspace:FindFirstChild("ViewModel")} 
                        local ray = WorldRoot:Raycast(camPos, (head.Position - camPos).Unit * MAX_RANGE, RayParams) 
                        if ray and (ray.Position - head.Position).Magnitude > VISIBILITY_TOLERANCE then continue end 
                    end 
                    bestDist = dist 
                    bestHead = head 
                end 
            end 
        end 
    end 
    return bestHead 
end 

-- ✅ SNAP AIM FUNCTION — FULLY KEPT 
local function FullInstantSnap() 
    if not INSTANT_SNAP_ALWAYS then return end 
    local snapTarget = GetClosestTarget(true, true) 
    if snapTarget then 
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, snapTarget.Position) 
    end 
end 

-- 💥 INTEGRATED RAGEBOT IMPLEMENTATION
local RagebotData = {
    Target = nil,
    IsDesynced = false,
    CurrentEnemy = nil,
    HeartbeatConn = nil,
    DesyncConn = nil,
    DelayTask = nil,
    OldStartShooting = nil,
    GunModule = nil,
    UtilModule = nil
}

-- Safe library gathering matching your structure
pcall(function()
    local playerScripts = plr:WaitForChild("PlayerScripts", 5)
    if playerScripts then
        local modules = playerScripts:WaitForChild("Modules", 5)
        if modules then
            local itemTypes = modules:WaitForChild("ItemTypes", 5)
            if itemTypes and itemTypes:FindFirstChild("Gun") then
                RagebotData.GunModule = require(itemTypes.Gun)
            end
        end
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

local function StartDesync(enemyPlayer)
    if RagebotData.DesyncConn then RagebotData.DesyncConn:Disconnect() end
    RagebotData.IsDesynced = true
    RagebotData.CurrentEnemy = enemyPlayer

    RagebotData.DesyncConn = RunService.Heartbeat:Connect(function()
        if not RagebotData.IsDesynced or not Features.Main.Ragebot then return end
        
        local myChar = plr.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local enemyHead = enemyPlayer.Character and enemyPlayer.Character:FindFirstChild("Head")
        if not enemyHead then
            StopDesync()
            return
        end

        local originalCFrame = myRoot.CFrame
        local originalVelocity = myRoot.Velocity
        local originalRotVelocity = myRoot.RotVelocity

        -- Teleport local player structure directly onto enemy head
        myRoot.CFrame = enemyHead.CFrame

        RunService:BindToRenderStep("__restore", 101, function()
            myRoot.CFrame = originalCFrame
            myRoot.Velocity = originalVelocity
            myRoot.RotVelocity = originalRotVelocity
            RunService:UnbindFromRenderStep("__restore")
        end)
    end)
end

local function HookGunFramework()
    if not RagebotData.GunModule or not RagebotData.UtilModule or RagebotData.OldStartShooting then return end
    
    RagebotData.OldStartShooting = RagebotData.GunModule.StartShooting
    RagebotData.GunModule.StartShooting = function(gunInstance, ...)
        local results = {RagebotData.OldStartShooting(gunInstance, ...)}
        
        if not Features.Main.Ragebot then return unpack(results) end
        if not gunInstance.ClientFighter or not gunInstance.ClientFighter.IsLocalPlayer then
            return unpack(results)
        end

        local dataTable = results[3]
        if not dataTable or typeof(dataTable) ~= "table" then
            return unpack(results)
        end

        results[4] = true
        local currentTarget = RagebotData.Target

        if not currentTarget or not currentTarget.Character then
            return unpack(results)
        end

        if not RagebotData.IsDesynced or RagebotData.CurrentEnemy ~= currentTarget then
            StartDesync(currentTarget)
            task.wait(0.1)
        end

        if RagebotData.DelayTask then
            task.cancel(RagebotData.DelayTask)
            RagebotData.DelayTask = nil
        end

        local targetHead = currentTarget.Character:FindFirstChild("Head")
        if not targetHead then return unpack(results) end

        local headPos = targetHead.Position
        local headCFrame = targetHead.CFrame
        local objectSpaceOffset = headCFrame:ToObjectSpace(CFrame.new(headPos + Vector3.new(math.random() * 0.1, math.random() * 0.1, math.random() * 0.1)))

        -- Redirect bullet vectors directly into the networked data table
        dataTable[utf8.char(0)] = RagebotData.UtilModule:EncodeCFrame(CFrame.new(headPos, headPos + targetHead.CFrame.LookVector))
        dataTable[utf8.char(1)] = RagebotData.UtilModule:EncodeCFrame(CFrame.new(headPos))
        dataTable[utf8.char(2)] = targetHead
        dataTable[utf8.char(3)] = RagebotData.UtilModule:EncodeCFrame(objectSpaceOffset)

        RagebotData.DelayTask = task.delay(0.15, function()
            StopDesync()
        end)

        return unpack(results)
    end
end

local function UnhookGunFramework()
    if RagebotData.OldStartShooting and RagebotData.GunModule then
        RagebotData.GunModule.StartShooting = RagebotData.OldStartShooting
        RagebotData.OldStartShooting = nil
    end
    StopDesync()
end

local function UpdateRagebotState(state) 
    Features.Main.Ragebot = state 
    SaveSetting("Ragebot", state) 
    if state then
        HookGunFramework()
        if RagebotData.HeartbeatConn then RagebotData.HeartbeatConn:Disconnect() end
        RagebotData.HeartbeatConn = RunService.Heartbeat:Connect(function()
            if not Features.Main.Ragebot then return end
            -- Uses your closest target picker script
            local targetHead = GetClosestTarget(true, true)
            if targetHead and targetHead.Parent then
                RagebotData.Target = Players:GetPlayerFromCharacter(targetHead.Parent)
            else
                RagebotData.Target = nil
            end
        end)
    else
        UnhookGunFramework()
        if RagebotData.HeartbeatConn then
            RagebotData.HeartbeatConn:Disconnect()
            RagebotData.HeartbeatConn = nil
        end
    end
end

-- ✅ RESPAWN HANDLER 
plr.CharacterAdded:Connect(function() 
    task.wait(0.3) 
    workspace.Gravity = OriginalGravity 
    UpdateRagebotState(Features.Main.Ragebot) 
    ToggleNoClip(Features.Misc.NoClip) 
    ToggleJump(Features.Misc.InfiniteJump) 
end) 

-- 📡 ESP SYSTEM & FIXED CHAM ESP (HIGHLIGHT METHOD)
local ESP_Drawings = {} 
local ChamHighlights = {} 

local function SetupESP(char) 
    if ESP_Drawings[char] then return end 
    ESP_Drawings[char] = { 
        Box = Drawing.new("Square"), 
        Name = Drawing.new("Text"), 
        Tracer = Drawing.new("Line"), 
        Health = Drawing.new("Text") 
    } 
    ESP_Drawings[char].Box.Thickness = 2 
    ESP_Drawings[char].Box.Filled = false 
    ESP_Drawings[char].Box.Size = Vector2.new(BOX_SIZE, BOX_SIZE * 1.5) 
    ESP_Drawings[char].Name.Size = 14 
    ESP_Drawings[char].Tracer.Thickness = 1 
     
    char.Destroying:Once(function() 
        for _,set in pairs(ESP_Drawings) do 
            if set then 
                for _,d in pairs(set) do d:Remove() end 
            end 
        end 
        ESP_Drawings[char] = nil
        if ChamHighlights[char] then 
            ChamHighlights[char]:Destroy() 
            ChamHighlights[char] = nil 
        end
    end) 
end 

local function UpdateChams() 
    for _, ply in Players:GetPlayers() do 
        if ply == plr then continue end 
        local char = ply.Character 
        if not char then continue end 
         
        if Features.Visual.Cham and Features.Visual.ESP then 
            local highlight = ChamHighlights[char]
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ChamHighlight"
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.4
                highlight.OutlineTransparency = 0.2
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = char
                ChamHighlights[char] = highlight
            end
            highlight.Enabled = true
        else 
            if ChamHighlights[char] then 
                ChamHighlights[char].Enabled = false
            end 
        end 
    end 
end 

local function UpdateESP() 
    if not Features.Visual.ESP then 
        for _,set in pairs(ESP_Drawings) do 
            for _,d in pairs(set) do 
                if d then d.Visible = false end 
            end 
        end 
        UpdateChams() 
        return 
    end 
    for _, ply in Players:GetPlayers() do 
        if ply == plr then continue end 
        local char = ply.Character 
        if not char then continue end 
        local hrp = char:FindFirstChild("HumanoidRootPart", true) 
        if not hrp then continue end 
        if (hrp.Position - Camera.CFrame.Position).Magnitude > MAX_RANGE then 
            if ESP_Drawings[char] then 
                for _,d in pairs(ESP_Drawings[char]) do 
                    if d then d.Visible = false end 
                end 
            end 
            continue 
        end 
        SetupESP(char) 
        local hum = char:FindFirstChildWhichIsA("Humanoid", true) 
        local head = char:FindFirstChild("Head", true) 
        if not hum or not head then continue end 
        local set = ESP_Drawings[char] 
        local visible = true 
        if Features.Main.TeamCheck and ply.Team and plr.Team and ply.Team == plr.Team then 
            visible = false 
        end 
        local hrpPos, vis = Camera:WorldToViewportPoint(hrp.Position) 
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0)) 
        set.Box.Visible = visible and Features.Visual.Box and vis and hrpPos.Z > 0 
        if set.Box.Visible then 
            set.Box.Position = Vector2.new(headPos.X - BOX_SIZE/2, headPos.Y) 
            set.Box.Color = Color3.new(1,1,1) 
        end 
        set.Name.Visible = visible and Features.Visual.Name and vis 
        if set.Name.Visible then 
            set.Name.Position = Vector2.new(headPos.X, headPos.Y - 15) 
            set.Name.Text = ply.Name 
            set.Name.Color = Color3.new(1,1,1) 
        end 
        set.Tracer.Visible = visible and Features.Visual.Tracer and vis 
        if set.Tracer.Visible then 
            set.Tracer.From = Camera.ViewportSize / 2 
            set.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y) 
            set.Tracer.Color = Color3.new(1,1,1) 
        end 
        set.Health.Visible = visible and Features.Visual.Health and vis 
        if set.Health.Visible then 
            local hp = math.round((hum.Health / hum.MaxHealth) * 100) 
            set.Health.Color = hp > 50 and Color3.new(0,1,0) or hp > 25 and Color3.new(1,1,0) or Color3.new(1,0,0) 
            set.Health.Position = Vector2.new(headPos.X, headPos.Y + 15) 
            set.Health.Text = hp .. "%" 
        end 
    end 
    UpdateChams() 
end 

-- 📦 UI ENVIRONMENT 
local LMG2L = {} 
LMG2L["ScreenGui_1"] = Instance.new("ScreenGui") 
LMG2L["ScreenGui_1"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
LMG2L["ScreenGui_1"].ResetOnSpawn = false 
LMG2L["ScreenGui_1"].DisplayOrder = 999999
LMG2L["ScreenGui_1"].Parent = plr:WaitForChild("PlayerGui", 60) 

local BackgroundBlur = Instance.new("BlurEffect") 
BackgroundBlur.Name = "UIBlur" 
BackgroundBlur.Size = 12 
BackgroundBlur.Enabled = Features.UI_Open 
BackgroundBlur.Parent = Lighting 

-- === MAIN TAB === 
local MainWin = Instance.new("Frame", LMG2L["ScreenGui_1"]) 
MainWin.BorderSizePixel=0; MainWin.BackgroundColor3=Color3.new(1,1,1); MainWin.BackgroundTransparency=0.6 
MainWin.Size=UDim2.new(0,112,0,182); MainWin.Position=UDim2.new(0,132,0,4) 
Instance.new("UICorner",MainWin).CornerRadius=UDim.new(0,16) 
Instance.new("UIDragDetector",MainWin) 

local MainInner = Instance.new("Frame",MainWin) 
MainInner.BorderSizePixel=0; MainInner.BackgroundColor3=Color3.new(1,1,1); MainInner.BackgroundTransparency=0.4 
MainInner.Size=UDim2.new(0,102,0,170); MainInner.Position=UDim2.new(0,6,0,6) 
Instance.new("UICorner",MainInner).CornerRadius=UDim.new(0,16) 

local MainHeader = Instance.new("TextLabel",MainInner) 
MainHeader.BorderSizePixel=0; MainHeader.BackgroundColor3=Color3.new(1,1,1); MainHeader.BackgroundTransparency=0.3 
MainHeader.Size=UDim2.new(0,98,0,22); MainHeader.Position=UDim2.new(0,2,0,0); MainHeader.Text="Main"; MainHeader.TextColor3=Color3.new(0,0,0) 
Instance.new("UICorner",MainHeader).CornerRadius=UDim.new(0,16) 

CreateSwitch(MainInner, 30, "Aimbot", function(s) Features.Main.Aimbot = s end, "Aimbot") 
CreateSwitch(MainInner, 58, "Show FOV circle", function(s) Features.Main.ShowFOV = s; FOVCircle.Visible = s end, "ShowFOV") 
CreateSwitch(MainInner, 86, "Ragebot", UpdateRagebotState, "Ragebot") 

-- === VISUAL TAB === 
local VisualWin = Instance.new("Frame", LMG2L["ScreenGui_1"]) 
VisualWin.BorderSizePixel=0; VisualWin.BackgroundColor3=Color3.new(1,1,1); VisualWin.BackgroundTransparency=0.6 
VisualWin.Size=UDim2.new(0,114,0,182); VisualWin.Position=UDim2.new(0,258,0,4) 
Instance.new("UICorner",VisualWin).CornerRadius=UDim.new(0,16) 
Instance.new("UIDragDetector",VisualWin) 

local VisualInner = Instance.new("Frame",VisualWin) 
VisualInner.BorderSizePixel=0; VisualInner.BackgroundColor3=Color3.new(1,1,1); VisualInner.BackgroundTransparency=0.4 
VisualInner.Size=UDim2.new(0,102,0,172); VisualInner.Position=UDim2.new(0,6,0,6) 
Instance.new("UICorner",VisualInner).CornerRadius=UDim.new(0,16) 

local VisHeader = Instance.new("TextLabel",VisualInner) 
VisHeader.BorderSizePixel=0; VisHeader.BackgroundColor3=Color3.new(1,1,1); VisHeader.BackgroundTransparency=0.3 
VisHeader.Size=UDim2.new(0,98,0,22); VisHeader.Position=UDim2.new(0,2,0,0); VisHeader.Text="Visual"; VisHeader.TextColor3=Color3.new(0,0,0) 
Instance.new("UICorner",VisHeader).CornerRadius=UDim.new(0,16) 

CreateSwitch(VisualInner, 30, "Enable ESP", function(s) Features.Visual.ESP = s end, "ESP") 
CreateSwitch(VisualInner, 58, "Box ESP", function(s) Features.Visual.Box = s end, "Box") 
CreateSwitch(VisualInner, 114, "Tracer ESP", function(s) Features.Visual.Tracer = s end, "Tracer") 
CreateSwitch(VisualInner, 86, "Health ESP", function(s) Features.Visual.Health = s end, "Health") 
CreateSwitch(VisualInner, 142, "Cham ESP", function(s) Features.Visual.Cham = s end, "Cham") 

-- === MISC TAB === 
local MiscWin = Instance.new("Frame", LMG2L["ScreenGui_1"]) 
MiscWin.BorderSizePixel=0; MiscWin.BackgroundColor3=Color3.new(1,1,1); MiscWin.BackgroundTransparency=0.6 
MiscWin.Size=UDim2.new(0,114,0,210); MiscWin.Position=UDim2.new(0,386,0,4) 
Instance.new("UICorner",MiscWin).CornerRadius=UDim.new(0,16) 
Instance.new("UIDragDetector",MiscWin) 

local MiscInner = Instance.new("Frame",MiscWin) 
MiscInner.BorderSizePixel=0; MiscInner.BackgroundColor3=Color3.new(1,1,1); MiscInner.BackgroundTransparency=0.4 
MiscInner.Size=UDim2.new(0,102,0,198); MiscInner.Position=UDim2.new(0,6,0,6) 
Instance.new("UICorner",MiscInner).CornerRadius=UDim.new(0,16) 

local MiscHeader = Instance.new("TextLabel",MiscInner) 
MiscHeader.BorderSizePixel=0; MiscHeader.BackgroundColor3=Color3.new(1,1,1); MiscHeader.BackgroundTransparency=0.3 
MiscHeader.Size=UDim2.new(0,98,0,22); MiscHeader.Position=UDim2.new(0,2,0,0); MiscHeader.Text="Misc"; MiscHeader.TextColor3=Color3.new(0,0,0) 
Instance.new("UICorner",MiscHeader).CornerRadius=UDim.new(0,16) 

CreateSwitch(MiscInner, 30, "Infinite Jump", ToggleJump, "InfiniteJump") 
CreateSwitch(MiscInner, 58, "NoClip", ToggleNoClip, "NoClip") 

-- === SETTINGS TAB === 
local SettingsWin = Instance.new("Frame", LMG2L["ScreenGui_1"]) 
SettingsWin.BorderSizePixel=0; SettingsWin.BackgroundColor3=Color3.new(1,1,1); SettingsWin.BackgroundTransparency=0.6 
SettingsWin.Size=UDim2.new(0,114,0,220); SettingsWin.Position=UDim2.new(0,514,0,6) 
Instance.new("UICorner",SettingsWin).CornerRadius=UDim.new(0,16) 
Instance.new("UIDragDetector",SettingsWin) 

local SettingsInner = Instance.new("Frame",SettingsWin) 
SettingsInner.BorderSizePixel=0; SettingsInner.BackgroundColor3=Color3.new(1,1,1); SettingsInner.BackgroundTransparency=0.4 
SettingsInner.Size=UDim2.new(0,102,0,208); SettingsInner.Position=UDim2.new(0,6,0,6) 
Instance.new("UICorner",SettingsInner).CornerRadius=UDim.new(0,16) 

local SetHeader = Instance.new("TextLabel",SettingsInner) 
SetHeader.BorderSizePixel=0; SetHeader.BackgroundColor3=Color3.new(1,1,1); SetHeader.BackgroundTransparency=0.3 
SetHeader.Size=UDim2.new(0,98,0,22); SetHeader.Position=UDim2.new(0,2,0,0); SetHeader.Text="Settings"; SetHeader.TextColor3=Color3.new(0,0,0) 
Instance.new("UICorner",SetHeader).CornerRadius=UDim.new(0,16) 

CreateSwitch(SettingsInner, 30, "Auto Queue", function(s) Features.Settings.AutoQueue = s; SaveSetting("AutoQueue",s) end, "AutoQueue") 
CreateQueueSelector(SettingsInner, 60) 

-- === TOGGLE BUTTON (MOVED TO LEFT SIDE) === 
local ToggleBtn = Instance.new("TextButton", LMG2L["ScreenGui_1"]) 
ToggleBtn.BorderSizePixel=0; ToggleBtn.BackgroundColor3=Color3.new(1,1,1); ToggleBtn.BackgroundTransparency=0.3 
ToggleBtn.Size=UDim2.new(0,40,0,30); 
ToggleBtn.Position=UDim2.new(0, 10, 0, 10); -- Moved strictly to top-left corner
ToggleBtn.Text=Features.UI_Open and "Hide" or "Open"; ToggleBtn.TextColor3=Color3.new(0,0,0) 
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function() 
    Features.UI_Open = not Features.UI_Open 
    SaveSetting("UI_Open", Features.UI_Open) 
    MainWin.Visible = Features.UI_Open 
    VisualWin.Visible = Features.UI_Open 
    MiscWin.Visible = Features.UI_Open 
    SettingsWin.Visible = Features.UI_Open 
    BackgroundBlur.Enabled = Features.UI_Open 
    ToggleBtn.Text = Features.UI_Open and "Hide" or "Open" 
end) 

-- ✅ APPLY — ALL UI STARTS CLOSED 
MainWin.Visible = Features.UI_Open 
VisualWin.Visible = Features.UI_Open 
MiscWin.Visible = Features.UI_Open 
SettingsWin.Visible = Features.UI_Open 

-- Initial trigger logic for loaded settings
UpdateRagebotState(Features.Main.Ragebot)

-- ✅ MAIN LOOP 
RunService:BindToRenderStep("MainLoop", Enum.RenderPriority.Camera.Value + 10, function() 
    if Features.Main.Aimbot and not Features.Main.Ragebot then 
        local target = GetClosestTarget(false, false) 
        if target then 
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position) 
        end 
    end 
    RunAutoQueue() 
    if FOVCircle.Visible then 
        FOVCircle.Position = Camera.ViewportSize / 2 
    end 
    UpdateESP() 
end) 

return LMG2L["ScreenGui_1"]
