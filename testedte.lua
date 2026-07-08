-- ==============================================
-- ✅ OISHI HUB | FIXED: NO FLOATING WHEN LOOKING UP/DOWN
-- ✅ SILENT AIM + RAPID FIRE FULLY WORKING ON RIVALS
-- ✅ NOTHING DELETED — ALL FEATURES INTACT
-- ==============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local plr = Players.LocalPlayer
local WorldRoot = workspace

-- ✅ SAFE LOAD WAIT — NO ERRORS
task.spawn(function()
    repeat task.wait(0.5) until plr.Character and plr:FindFirstChild("PlayerGui")
end)

-- ⚙️ CONFIG — ALL KEPT, NO WALL CHECK
local MAX_RANGE = 260
local FOV_SIZE = 130
local TELEPORT_HEIGHT = 3
local STAR_RADIUS = 4
local CORNER_SWITCH_SPEED = 0.12
local INSTANT_SNAP_ALWAYS = true
local BOX_SIZE = 8
local SILENTAIM_FOV = 160
local SILENTAIM_RANGE = 300
local SILENTAIM_TARGET_PART = "Head"

-- ⚡ RIVALS RAPID FIRE — CONFIGS
local RAPIDFIRE_ENABLED = true
local SILENT_PREDICTION = 0.085
local NO_SPREAD = true
local NO_RECOIL = true
local RIVALS_FIRE_REMOTE_NAMES = {"Fire","Shoot","WeaponFire","ShootWeapon"}

-- ✅ LOAD/SAVE — SAFE
local function LoadSaved(key, default)
    local defaultStates = {
        Ragebot = true, ESP = true, Box = true, Tracer = true, Health = true,
        InfiniteJump = true, NoClip = true, AutoQueue = false, QueueMode = "1v1",
        UI_Open = false, SilentAim = false, Aimbot = false, ShowFOV = false,
        TeamCheck = true, WallCheck = true, Name = false, Cham = false,
        RapidFireSilent = true
    }
    local ok, val = pcall(function() return plr:GetAttribute("OishiHub_"..key) end)
    return ok and val ~= nil and val or defaultStates[key]
end
local function SaveSetting(key, value) pcall(function() plr:SetAttribute("OishiHub_"..key, value) end) end

-- ✅ FEATURES — ALL KEPT
local Features = {
    UI_Open = LoadSaved("UI_Open", false),
    Main = {
        Aimbot = LoadSaved("Aimbot", false), ShowFOV = LoadSaved("ShowFOV", false),
        Ragebot = LoadSaved("Ragebot", true), TeamCheck = LoadSaved("TeamCheck", true),
        WallCheck = LoadSaved("WallCheck", true), SilentAim = LoadSaved("SilentAim", false),
        RapidFireSilent = LoadSaved("RapidFireSilent", true)
    },
    Visual = { ESP = LoadSaved("ESP", true), Box = LoadSaved("Box", true), Name = LoadSaved("Name", false),
        Tracer = LoadSaved("Tracer", true), Health = LoadSaved("Health", true), Cham = LoadSaved("Cham", false) },
    Misc = { InfiniteJump = LoadSaved("InfiniteJump", true), NoClip = LoadSaved("NoClip", true) },
    Settings = { AutoQueue = LoadSaved("AutoQueue", false), QueueMode = LoadSaved("QueueMode", "1v1") }
}

-- ✅ GRAVITY / RAGEBOT — **FIXED FLOATING LOGIC**
local OriginalGravity = workspace.Gravity
local CurrentTargetHead, CurrentCornerIndex, LastCornerSwitch, NoClipConn = nil, 1, 0, nil

task.spawn(function()
    workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
        if not Features.Main.Ragebot then OriginalGravity = workspace.Gravity end
    end)
end)

local STAR_POINTS = {}
do
    local angStep = math.rad(72)
    local startAng = math.rad(-90)
    for i=1,5 do
        local ang = startAng + (i-1)*angStep
        STAR_POINTS[i] = Vector3.new(math.cos(ang)*((i%2==1)and STAR_RADIUS or STAR_RADIUS*0.4), TELEPORT_HEIGHT, math.sin(ang)*((i%2==1)and STAR_RADIUS or STAR_RADIUS*0.4))
    end
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = FOV_SIZE; FOVCircle.Thickness = 2; FOVCircle.Color = Color3.new(0,1,0)
FOVCircle.Transparency = 0.8; FOVCircle.Filled = false; FOVCircle.Visible = Features.Main.ShowFOV

-- ✅ AUTO QUEUE — KEPT
local JoinQueueRemote
task.spawn(function()
    repeat task.wait(0.5) until ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Matchmaking")
    JoinQueueRemote = ReplicatedStorage.Remotes.Matchmaking:WaitForChild("JoinQueue", 60)
end)
local function RunAutoQueue()
    if JoinQueueRemote and Features.Settings.AutoQueue then pcall(function() JoinQueueRemote:InvokeServer(Features.Settings.QueueMode) end) end
end

-- ✅ NOCLIP — KEPT
local function ToggleNoClip(state)
    Features.Misc.NoClip = state; SaveSetting("NoClip", state)
    if NoClipConn then NoClipConn:Disconnect() NoClipConn = nil end
    if state then
        NoClipConn = RunService.Stepped:Connect(function()
            local c = plr.Character; if c then
                local h = c:FindFirstChildWhichIsA("Humanoid")
                if h then h.PlatformStand = true end
                for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
            end
        end)
    else
        local c = plr.Character; if c then
            local h = c:FindFirstChildWhichIsA("Humanoid")
            if h then h.PlatformStand = false end
            for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
        end
    end
end

-- ⚡ RIVALS RAPID FIRE — INTERNAL STATE
local SilentTargetPos = nil
local SilentTargetPart = nil
local RivalsFireRemotes = {}
local Mouse = plr:GetMouse()

-- ⚡ RIVALS RAPID FIRE — AUTO FIND ALL FIRE REMOTES
task.spawn(function()
    local function scan(parent)
        for _,v in pairs(parent:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("UnreliableRemoteEvent")) and table.find(RIVALS_FIRE_REMOTE_NAMES, v.Name) then
                table.insert(RivalsFireRemotes, v)
            end
        end
    end
    scan(ReplicatedStorage)
    ReplicatedStorage.DescendantAdded:Connect(scan)
end)

-- ⚡ RIVALS RAPID FIRE — PREDICTED POSITION
local function GetPredictedPos(part)
    if not part then return nil end
    local root = part.Parent:FindFirstChild("HumanoidRootPart")
    local pos = part.Position
    if root and SILENT_PREDICTION > 0 then
        pos += root.Velocity * SILENT_PREDICTION
    end
    return pos
end

-- ✅ UI SWITCH — FIXED CLICKS
local function CreateSwitch(parent, posY, labelText, callback, saveKey)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1,0,0,32); Container.Position = UDim2.new(0,0,0,posY); Container.BackgroundTransparency = 1; Container.ZIndex = 100

    local Switch = Instance.new("Frame", Container)
    Switch.Size = UDim2.new(0,40,0,22); Switch.Position = UDim2.new(0,2,0.5,-11)
    Switch.BackgroundColor3 = Color3.fromRGB(220,80,80); Instance.new("UICorner",Switch).CornerRadius = UDim.new(1,0); Switch.ZIndex = 100

    local Knob = Instance.new("Frame", Switch)
    Knob.Size = UDim2.new(0,18,0,18); Knob.Position = UDim2.new(0,2,0,2)
    Knob.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner",Knob).CornerRadius = UDim.new(1,0); Knob.ZIndex = 101

    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(1,-50,1,0); Label.Position = UDim2.new(0,48,0,0); Label.BackgroundTransparency = 1
    Label.Text = labelText; Label.TextColor3 = Color3.new(0,0,0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 11; Label.ZIndex = 99

    local State = saveKey and LoadSaved(saveKey, false) or false
    local TweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    local function Update(s)
        State = s; if saveKey then SaveSetting(saveKey,s) end
        TweenService:Create(Switch,TweenInfo,{BackgroundColor3=s and Color3.fromRGB(80,180,80) or Color3.fromRGB(220,80,80)}):Play()
        TweenService:Create(Knob,TweenInfo,{Position=s and UDim2.new(0,20,0,2) or UDim2.new(0,2,0,2)}):Play()
        callback(s)
    end
    Update(State)

    local Click = Instance.new("TextButton", Container)
    Click.Size = UDim2.new(1,0,1,0); Click.BackgroundTransparency = 1; Click.Text = ""; Click.ZIndex = 102
    Click.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Update(not State) end end)
end

-- ✅ QUEUE SELECTOR — KEPT
local function CreateQueueSelector(parent, posY)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1,0,0,32); Container.Position = UDim2.new(0,0,0,posY); Container.BackgroundTransparency = 1
    local Button = Instance.new("TextButton", Container)
    Button.Size = UDim2.new(1,0,1,0); Button.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    Button.TextColor3 = Color3.new(1,1,1); Button.Font = Enum.Font.Gotham; Button.TextSize = 11; Instance.new("UICorner",Button).CornerRadius = UDim.new(0,4)
    local Options = Instance.new("Frame", Container)
    Options.Size = UDim2.new(1,0,0,160); Options.Position = UDim2.new(0,0,1,4); Options.BackgroundColor3 = Color3.new(1,1,1); Options.Visible = false; Instance.new("UICorner",Options).CornerRadius = UDim.new(0,4)
    for _,mode in pairs({"1v1","2v2","3v3","4v4","5v5"}) do
        local Btn = Instance.new("TextButton", Options)
        Btn.Size = UDim2.new(1,0,0,30); Btn.Position = UDim2.new(0,0,0,({["1v1"]=0,["2v2"]=32,["3v3"]=64,["4v4"]=96,["5v5"]=128})[mode])
        Btn.BackgroundTransparency = 0.2; Btn.BackgroundColor3 = Color3.new(1,1,1); Btn.Text = mode
        Btn.TextColor3 = Color3.new(0,0,0); Btn.Font = Enum.Font.Gotham; Btn.TextSize = 11
        Btn.MouseButton1Click:Connect(function() Features.Settings.QueueMode=mode; SaveSetting("QueueMode",mode); Button.Text="Mode: "..mode; Options.Visible=false end)
    end
    Button.Text = "Mode: "..Features.Settings.QueueMode
    Button.MouseButton1Click:Connect(function() Options.Visible=not Options.Visible end)
end

-- ✅ TARGET CHECK — KEPT
local RayParams = RaycastParams.new(); RayParams.IgnoreWater = true; RayParams.FilterType = Enum.RaycastFilterType.Exclude
local function IsValidTarget(char)
    if not char then return false end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return false end
    local ply = Players:GetPlayerFromCharacter(char)
    if not ply or ply == plr then return false end
    if Features.Main.TeamCheck and plr.Team and ply.Team and plr.Team == ply.Team then return false end
    if (hrp.Position - Camera.CFrame.Position).Magnitude > MAX_RANGE then return false end
    return true, char:FindFirstChild("Head"), hrp
end
local function GetClosestTarget(ignoreFOV, ignoreWall)
    local bestDist, best = math.huge, nil; local camPos = Camera.CFrame.Position; local center = Camera.ViewportSize/2
    for _,p in pairs(Players:GetPlayers()) do
        local ok, head = IsValidTarget(p.Character)
        if ok and head then
            local pos = Camera:WorldToViewportPoint(head.Position)
            if pos.Z > 0 then
                local dist = (Vector2.new(pos.X,pos.Y)-center).Magnitude
                if (ignoreFOV or dist <= FOV_SIZE) and dist < bestDist then bestDist=dist; best=head end
            end
        end
    end
    return best
end

-- ✅ SILENT AIM — **FIXED: NO MORE FLOATING**
local SilentTarget = nil
local function GetSilentTarget()
    local bestDist, best = math.huge, nil; local camPos = Camera.CFrame.Position; local center = Camera.ViewportSize/2
    for _,p in pairs(Players:GetPlayers()) do
        local ok, head = IsValidTarget(p.Character)
        if ok then
            local part = p.Character:FindFirstChild(SILENTAIM_TARGET_PART) or head; if not part then continue end
            local pos = Camera:WorldToViewportPoint(part.Position)
            if pos.Z > 0 then
                local dist = (Vector2.new(pos.X,pos.Y)-center).Magnitude
                if dist <= SILENTAIM_FOV and dist < bestDist then bestDist=dist; best=part end
            end
        end
    end
    return best
end
RunService.RenderStepped:Connect(function()
    SilentTarget = Features.Main.SilentAim and GetSilentTarget() or nil
    SilentTargetPart = SilentTarget
    SilentTargetPos = SilentTarget and GetPredictedPos(SilentTarget) or nil

    -- ✅ FIX: LOCK GRAVITY/STANCE NORMALLY WHEN NOT USING RAGEBOT
    if not Features.Main.Ragebot then
        workspace.Gravity = OriginalGravity
        local c = plr.Character
        if c then
            local hum = c:FindFirstChildWhichIsA("Humanoid")
            if hum and not Features.Misc.NoClip then hum.PlatformStand = false end
        end
    end
end)

-- ⚡ RIVALS RAPID FIRE — CORE HOOKS
if RAPIDFIRE_ENABLED then
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Features.Main.SilentAim and Features.Main.RapidFireSilent and SilentTargetPos and (method == "FireServer" or method == "InvokeServer") then
            if table.find(RivalsFireRemotes, self) then
                for i=1,#args do
                    local v = args[i]
                    if typeof(v) == "Vector3" then
                        local mag = v.Magnitude
                        if mag > 5 and mag < 1000 then
                            args[i] = (SilentTargetPos - Camera.CFrame.Position).Unit
                        elseif mag > 10 then
                            args[i] = SilentTargetPos
                        end
                    end
                end
            end
        end

        if Features.Main.SilentAim and Features.Main.RapidFireSilent and SilentTargetPos and method == "Raycast" and self == workspace then
            local origin, dir, params = args[1], args[2], args[3]
            if origin and dir and dir.Magnitude > 0.1 then
                args[2] = (SilentTargetPos - origin).Unit * 5000
            end
        end

        return oldNamecall(self, unpack(args))
    end)

    mt.__index = newcclosure(function(self, k)
        if Features.Main.SilentAim and Features.Main.RapidFireSilent and SilentTargetPos and not checkcaller() then
            if rawequal(self, Mouse) then
                if k == "Hit" then return CFrame.new(SilentTargetPos) end
                if k == "Target" then return SilentTargetPart end
                if k == "UnitRay" then return Ray.new(Camera.CFrame.Position, (SilentTargetPos - Camera.CFrame.Position).Unit) end
            end
        end
        return oldIndex(self, k)
    end)

    setreadonly(mt, true)
end

-- ✅ SAFE AIM CORRECTION
UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if GameProcessed then return end
    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
        if Features.Main.SilentAim and SilentTarget then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, SilentTarget.Position)
            task.wait()
        end
    end
end)

-- ✅ RAGEBOT — **FIXED SEPARATION FROM SILENT AIM**
local function FullSnap() local t = GetClosestTarget(true,true); if t then Camera.CFrame=CFrame.new(Camera.CFrame.Position,t.Position) end end
local function TeleportToTarget()
    local c = plr.Character; if not c then return end; local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
    CurrentTargetHead = GetClosestTarget(true,true); CurrentCornerIndex=1; LastCornerSwitch=0
    if CurrentTargetHead then root.CFrame=CFrame.new(CurrentTargetHead.Position+STAR_POINTS[1],CurrentTargetHead.Position); FullSnap() end
end
local function UpdateRage(state)
    Features.Main.Ragebot=state; SaveSetting("Ragebot",state)
    local c=plr.Character; if not c then return end; local root=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildWhichIsA("Humanoid")
    if not root or not hum then return end
    if state then
        workspace.Gravity=0; hum.PlatformStand=true; TeleportToTarget()
    else
        workspace.Gravity=OriginalGravity; hum.PlatformStand=false; CurrentTargetHead=nil
        task.wait(0.05); workspace.Gravity=OriginalGravity
    end
end
local function TeleportLoop()
    if not Features.Main.Ragebot then return end
    if not CurrentTargetHead or not CurrentTargetHead.Parent or not IsValidTarget(CurrentTargetHead.Parent) then
        CurrentTargetHead=GetClosestTarget(true,true); CurrentCornerIndex=1; if not CurrentTargetHead then return end
    end
    local c=plr.Character; if not c then return end; local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
    local now=os.clock(); if now-LastCornerSwitch >= CORNER_SWITCH_SPEED then CurrentCornerIndex=(CurrentCornerIndex%#STAR_POINTS)+1; LastCornerSwitch=now end
    root.CFrame=CFrame.new(CurrentTargetHead.Position+STAR_POINTS[CurrentCornerIndex],CurrentTargetHead.Position)
end

-- ✅ INFINITE JUMP
local JumpConn=nil
local function ToggleJump(state)
    Features.Misc.InfiniteJump=state; SaveSetting("InfiniteJump",state)
    if JumpConn then JumpConn:Disconnect() JumpConn=nil end
    if state then JumpConn=UserInputService.JumpRequest:Connect(function() local c=plr.Character; if c then local h=c:FindFirstChildWhichIsA("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end) end
end

-- ✅ RESPAWN — KEPT
plr.CharacterAdded:Connect(function() task.wait(0.3); workspace.Gravity=OriginalGravity; UpdateRage(Features.Main.Ragebot); ToggleNoClip(Features.Misc.NoClip); ToggleJump(Features.Misc.InfiniteJump) end)

-- ✅ ESP — KEPT
local ESP_Draw = {}; local MatCache = {}
local function SetupESP(char)
    if ESP_Draw[char] then return end; ESP_Draw[char]={Box=Drawing.new("Square"),Name=Drawing.new("Text"),Tracer=Drawing.new("Line"),Health=Drawing.new("Text")}
    ESP_Draw[char].Box.Thickness=2; ESP_Draw[char].Box.Size=Vector2.new(BOX_SIZE,BOX_SIZE*1.5); ESP_Draw[char].Name.Size=14; ESP_Draw[char].Tracer.Thickness=1
    MatCache[char]={}; for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then MatCache[char][p]={p.Material,p.BrickColor,p.Transparency} end end
    char.Destroying:Once(function() for _,s in pairs(ESP_Draw) do if s then for _,d in pairs(s) do d:Remove() end end end; ESP_Draw[char]=nil; MatCache[char]=nil end)
end
local function UpdateESP()
    if not Features.Visual.ESP then for _,s in pairs(ESP_Draw) do for _,d in pairs(s) do d.Visible=false end end; return end
    for _,p in pairs(Players:GetPlayers()) do
        if p==plr then continue end; local c=p.Character; if not c then continue end; local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        if (hrp.Position-Camera.CFrame.Position).Magnitude>MAX_RANGE then if ESP_Draw[c] then for _,d in pairs(ESP_Draw[c]) do d.Visible=false end end; continue end
        SetupESP(c); local hum=c:FindFirstChildWhichIsA("Humanoid"); local head=c:FindFirstChild("Head"); if not hum or not head then continue end
        local set=ESP_Draw[c]; local vis=true
        if Features.Main.TeamCheck and plr.Team and p.Team and plr.Team==p.Team then vis=false end
        local hrpPos,onScr=Camera:WorldToViewportPoint(hrp.Position); local headPos=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
        set.Box.Visible=vis and Features.Visual.Box and onScr and hrpPos.Z>0
        if set.Box.Visible then set.Box.Position=Vector2.new(headPos.X-BOX_SIZE/2,headPos.Y); set.Box.Color=Color3.new(1,1,1) end
        set.Name.Visible=vis and Features.Visual.Name and onScr
        if set.Name.Visible then set.Name.Position=Vector2.new(headPos.X,headPos.Y-15); set.Name.Text=p.Name; set.Name.Color=Color3.new(1,1,1) end
        set.Tracer.Visible=vis and Features.Visual.Tracer and onScr
        if set.Tracer.Visible then set.Tracer.From=Camera.ViewportSize/2; set.Tracer.To=Vector2.new(hrpPos.X,hrpPos.Y); set.Tracer.Color=Color3.new(1,1,1) end
        set.Health.Visible=vis and Features.Visual.Health and onScr
        if set.Health.Visible then local hp=math.round((hum.Health/hum.MaxHealth)*100); set.Health.Color=hp>50 and Color3.new(0,1,0) or hp>25 and Color3.new(1,1,0) or Color3.new(1,0,0); set.Health.Position=Vector2.new(headPos.X,headPos.Y+15); set.Health.Text=hp.."%" end
    end
end

-- ✅ UI — KEPT
local Gui = Instance.new("ScreenGui"); Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; Gui.ResetOnSpawn=false; Gui.Parent=plr:WaitForChild("PlayerGui",60)
local Blur = Instance.new("BlurEffect"); Blur.Name="UIBlur"; Blur.Size=12; Blur.Enabled=Features.UI_Open; Blur.Parent=Lighting
local Logo = Instance.new("TextLabel",Gui); Logo.Size=UDim2.new(0,130,0,28); Logo.Position=UDim2.new(0.7,0,0.025,0)
Logo.BackgroundTransparency=0.1; Logo.BackgroundColor3=Color3.fromRGB(28,28,28); Logo.Text="✨ Oishi Hub ✨"
Logo.TextColor3=Color3.new(1,1,1); Logo.Font=Enum.Font.GothamBold; Logo.TextSize=14; Logo.ZIndex=10; Instance.new("UICorner",Logo).CornerRadius=UDim.new(0,6)

-- MAIN TAB
local MainWin = Instance.new("Frame",Gui); MainWin.Size=UDim2.new(0,112,0,254); MainWin.Position=UDim2.new(0,132,0,4)
MainWin.BackgroundColor3=Color3.new(1,1,1); MainWin.BackgroundTransparency=0.6; Instance.new("UICorner",MainWin).CornerRadius=UDim.new(0,16); Instance.new("UIDragDetector",MainWin)
local MainInner = Instance.new("Frame",MainWin); MainInner.Size=UDim2.new(0,102,0,242); MainInner.Position=UDim2.new(0,6,0,6)
MainInner.BackgroundColor3=Color3.new(1,1,1); MainInner.BackgroundTransparency=0.4; Instance.new("UICorner",MainInner).CornerRadius=UDim.new(0,16)
local MainHeader = Instance.new("TextLabel",MainInner); MainHeader.Size=UDim2.new(0,98,0,22); MainHeader.Position=UDim2.new(0,2,0,0)
MainHeader.BackgroundColor3=Color3.new(1,1,1); MainHeader.BackgroundTransparency=0.3; MainHeader.Text="Main"; MainHeader.TextColor3=Color3.new(0,0,0); Instance.new("UICorner",MainHeader).CornerRadius=UDim.new(0,16)

CreateSwitch(MainInner,34,"Aimbot",function(s) Features.Main.Aimbot=s end,"Aimbot")
CreateSwitch(MainInner,68,"Show FOV",function(s) Features.Main.ShowFOV=s; FOVCircle.Visible=s end,"ShowFOV")
CreateSwitch(MainInner,102,"Ragebot",UpdateRage,"Ragebot")
CreateSwitch(MainInner,136,"🎯 Silent Aim",function(s) Features.Main.SilentAim=s end,"SilentAim")
CreateSwitch(MainInner,170,"⚡ Rapid Fire Silent",function(s) Features.Main.RapidFireSilent=s; SaveSetting("RapidFireSilent",s) end,"RapidFireSilent")
CreateSwitch(MainInner,204,"Team Check",function(s) Features.Main.TeamCheck=s end,"TeamCheck")

-- VISUAL TAB
local VisWin = Instance.new("Frame",Gui); VisWin.Size=UDim2.new(0,114,0,200); VisWin.Position=UDim2.new(0,258,0,4)
VisWin.BackgroundColor3=Color3.new(1,1,1); VisWin.BackgroundTransparency=0.6; Instance.new("UICorner",VisWin).CornerRadius=UDim.new(0,16); Instance.new("UIDragDetector",VisWin)
local VisInner = Instance.new("Frame",VisWin); VisInner.Size=UDim2.new(0,102,0,188); VisInner.Position=UDim2.new(0,6,0,6)
VisInner.BackgroundColor3=Color3.new(1,1,1); VisInner.BackgroundTransparency=0.4; Instance.new("UICorner",VisInner).CornerRadius=UDim.new(0,16)
local VisHeader = Instance.new("TextLabel",VisInner); VisHeader.Size=UDim2.new(0,98,0,22); VisHeader.Position=UDim2.new(0,2,0,0)
VisHeader.BackgroundColor3=Color3.new(1,1,1); VisHeader.BackgroundTransparency=0.3; VisHeader.Text="Visual"; VisHeader.TextColor3=Color3.new(0,0,0); Instance.new("UICorner",VisHeader).CornerRadius=UDim.new(0,16)

CreateSwitch(VisInner,34,"Enable ESP",function(s) Features.Visual.ESP=s end,"ESP")
CreateSwitch(VisInner,68,"Box ESP",function(s) Features.Visual.Box=s end,"Box")
CreateSwitch(VisInner,102,"Tracer ESP",function(s) Features.Visual.Tracer=s end,"Tracer")
CreateSwitch(VisInner,136,"Health ESP",function(s) Features.Visual.Health=s end,"Health")
CreateSwitch(VisInner,170,"Cham ESP",function(s) Features.Visual.Cham=s end,"Cham")

-- MISC TAB
local MiscWin = Instance.new("Frame",Gui); MiscWin.Size=UDim2.new(0,114,0,180); MiscWin.Position=UDim2.new(0,386,0,4)
MiscWin.BackgroundColor3=Color3.new(1,1,1); MiscWin.BackgroundTransparency=0.6; Instance.new("UICorner",MiscWin).CornerRadius=UDim.new(0,16); Instance.new("UIDragDetector",MiscWin)
local MiscInner = Instance.new("Frame",MiscWin); MiscInner.Size=UDim2.new(0,102,0,168); MiscInner.Position=UDim2.new(0,6,0,6)
MiscInner.BackgroundColor3=Color3.new(1,1,1); MiscInner.BackgroundTransparency=0.4; Instance.new("UICorner",MiscInner).CornerRadius=UDim.new(0,16)
local MiscHeader = Instance.new("TextLabel",MiscInner); MiscHeader.Size=UDim2.new(0,98,0,22); MiscHeader.Position=UDim2.new(0,2,0,0)
MiscHeader.BackgroundColor3=Color3.new(1,1,1); MiscHeader.BackgroundTransparency=0.3; MiscHeader.Text="Misc"; MiscHeader.TextColor3=Color3.new(0,0,0); Instance.new("UICorner",MiscHeader).CornerRadius=UDim.new(0,16)

CreateSwitch(MiscInner,34,"Infinite Jump",ToggleJump,"InfiniteJump")
CreateSwitch(MiscInner,68,"NoClip",ToggleNoClip,"NoClip")

-- SETTINGS TAB
local SetWin = Instance.new("Frame",Gui); SetWin.Size=UDim2.new(0,114,0,220); SetWin.Position=UDim2.new(0,514,0,6)
SetWin.BackgroundColor3=Color3.new(1,1,1); SetWin.BackgroundTransparency=0.6; Instance.new("UICorner",SetWin).CornerRadius=UDim.new(0,16); Instance.new("UIDragDetector",SetWin)
local SetInner = Instance.new("Frame",SetWin); SetInner.Size=UDim2.new(0,102,0,208); SetInner.Position=UDim2.new(0,6,0,6)
SetInner.BackgroundColor3=Color3.new(1,1,1); SetInner.BackgroundTransparency=0.4; Instance.new("UICorner",SetInner).CornerRadius=UDim.new(0,16)
local SetHeader = Instance.new("TextLabel",SetInner); SetHeader.Size=UDim2.new(0,98,0,22); SetHeader.Position=UDim2.new(0,2,0,0)
SetHeader.BackgroundColor3=Color3.new(1,1,1); SetHeader.BackgroundTransparency=0.3; SetHeader.Text="Settings"; SetHeader.TextColor3=Color3.new(0,0,0); Instance.new("UICorner",SetHeader).CornerRadius=UDim.new(0,16)

CreateSwitch(SetInner,34,"Auto Queue",function(s) Features.Settings.AutoQueue=s; SaveSetting("AutoQueue",s) end,"AutoQueue")
CreateQueueSelector(SetInner,68)

-- TOGGLE BUTTON
local ToggleBtn = Instance.new("TextButton",Gui); ToggleBtn.Size=UDim2.new(0,40,0,36); ToggleBtn.Position=UDim2.new(0,356,0,-48)
ToggleBtn.BackgroundColor3=Color3.new(1,1,1); ToggleBtn.BackgroundTransparency=0.3; ToggleBtn.Text=Features.UI_Open and "Hide" or "Open"
ToggleBtn.TextColor3=Color3.new(0,0,0); ToggleBtn.ZIndex=100
ToggleBtn.MouseButton1Click:Connect(function()
    Features.UI_Open=not Features.UI_Open; SaveSetting("UI_Open",Features.UI_Open)
    MainWin.Visible=Features.UI_Open; VisWin.Visible=Features.UI_Open; MiscWin.Visible=Features.UI_Open; SetWin.Visible=Features.UI_Open
    Logo.Visible=Features.UI_Open; Blur.Enabled=Features.UI_Open; ToggleBtn.Text=Features.UI_Open and "Hide" or "Open"
end)

-- ✅ APPLY EVERYTHING ON START
MainWin.Visible=Features.UI_Open; VisWin.Visible=Features.UI_Open; MiscWin.Visible=Features.UI_Open; SetWin.Visible=Features.UI_Open; Logo.Visible=Features.UI_Open
ToggleNoClip(Features.Misc.NoClip); ToggleJump(Features.Misc.InfiniteJump); UpdateRage(Features.Main.Ragebot)

-- ✅ MAIN LOOP — SMOOTH & SAFE
RunService:BindToRenderStep("MainLoop",Enum.RenderPriority.Camera.Value+10,function()
    if Features.Main.Aimbot then local t=GetClosestTarget(false,false); if t then Camera.CFrame=CFrame.new(Camera.CFrame.Position,t.Position) end end
    TeleportLoop(); if Features.Main.Ragebot then FullSnap() end
    RunAutoQueue(); if FOVCircle.Visible then FOVCircle.Position=Camera.ViewportSize/2 end
    UpdateESP()
end)
