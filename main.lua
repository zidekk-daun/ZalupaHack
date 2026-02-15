local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()

Aimbot:Load()
local AimbotSettings = Aimbot.Settings
local FOVSettings = Aimbot.FOVSettings

-- [ WINDOW SETUP ]
local Window = Fluent:CreateWindow({
    Title = "ZalupaHack v1.1.1",
    SubTitle = "by zidekk-daun",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.K
})

local Tabs = {
    Main = Window:AddTab({ Title = "Movement", Icon = "navigation" }),
    Aimbot = Window:AddTab({ Title = "Combat", Icon = "box" }),
    Hitboxes = Window:AddTab({ Title = "Hitboxes", Icon = "target" }),
    Esp = Window:AddTab({ Title = "ESP", Icon = "eye" }), 
    Farm = Window:AddTab({ Title = "Auto-Farm", Icon = "rbxassetid://4483345998" }),
    Dev = Window:AddTab({ Title = "Development", Icon = "code" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- [ VARIABLES ]
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local flying = false
local hrp, anchor
local inputMap = {}
local speedHorizontal = 52
local speedVertical = 60
local verticalInput = 0

local tracersEnabled = false
local tracerColor = Color3.fromRGB(255, 255, 255)
local tracerThickness = 1
local tracerTransparency = 1
local tracerOrigin = "Bottom"
local tracerTargetTeam = "All"

local espMaxDistance = 500      
local tracerMaxDistance = 500   

local farmActive = false
local farmAnchor = nil
local farmDistance = 9.9
local lockedTarget = nil
local targetPlayerName = "None" 

local notificationSound = 4590662766

-- Rainbow FOV Variable
local rainbowFOV = false

-- [ RAINBOW LOOP ]
runService.RenderStepped:Connect(function()
    if rainbowFOV then
        local hue = tick() % 3 / 3
        local color = Color3.fromHSV(hue, 1, 1)
        FOVSettings.Color = color
    end
end)

local function Notify(title, value)
    local state = value and "Enabled" or "Disabled"
    
    if notificationSound and notificationSound ~= "None" then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(notificationSound)
        sound.Volume = 2
        sound.Parent = game:GetService("SoundService")
        
        if not sound.IsLoaded then sound.Loaded:Wait() end
        
        sound:Play()
        
        task.delay(2, function()
            sound:Destroy()
        end)
    end

    Fluent:Notify({
        Title = title,
        Content = "Status: " .. state,
        Duration = 2
    })
end

local boxesEnabled = false
local boxColor = Color3.fromRGB(255, 255, 255)
local boxThickness = 1
local espSettings = {
    boxType = "2D",
    fillBox = false,
    fillTransparency = 0.3,
    fillColor = Color3.fromRGB(255, 0, 0),
    borderRadius = 8,        
    borderThickness = 1,     
    names = false,
    showDistance = true,  
    showHealth = false,   
    teamColor = true
}

local hitboxEnabled = false
local hitboxSize = 1
local hitboxTransparency = 0.7
local hitboxPart = "HumanoidRootPart"

local reachEnabled = false
local reachSize = 10
local showPoints = true

local safePos = Vector3.new(157.10513305664062, 21.129531860351562, -69.63561248779297)
local minBound = Vector3.new(-370.39, 0.36, -310.27)
local maxBound = Vector3.new(307.71, 576.15, 446.21)

-- [ CORE LOGIC ]

-- Farm

local function isWithinFarmZone(pos)
    local xOK = pos.X >= math.min(minBound.X, maxBound.X) and pos.X <= math.max(minBound.X, maxBound.X)
    local yOK = pos.Y >= math.min(minBound.Y, maxBound.Y) and pos.Y <= math.max(minBound.Y, maxBound.Y)
    local zOK = pos.Z >= math.min(minBound.Z, maxBound.Z) and pos.Z <= math.max(minBound.Z, maxBound.Z)
    return xOK and yOK and zOK
end

local function isParrying(target)
    if not target or not target.Character then return false end
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, anim in pairs(animator:GetPlayingAnimationTracks()) do
            if anim.Name == "ParriedIdle" then return true end
        end
    end
    return false
end

local function moveFarm(targetPos, lookTarget)
    if not farmAnchor then
        farmAnchor = Instance.new("Part")
        farmAnchor.Size = Vector3.new(1, 1, 1)
        farmAnchor.Transparency = 1
        farmAnchor.Anchored = true
        farmAnchor.CanCollide = false
        farmAnchor.Parent = workspace
    end
    local diff = lookTarget.Position - targetPos.Position
    local angle = math.atan2(diff.X, diff.Z)
    local finalCFrame = CFrame.new(targetPos.Position) * CFrame.Angles(0, angle + math.pi, 0)
    farmAnchor.CFrame = finalCFrame
    player.Character:PivotTo(finalCFrame)
end

runService.Heartbeat:Connect(function()
    if hitboxEnabled then
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= player and v.Character then
                local part = v.Character:FindFirstChild(hitboxPart)
                if part and part:IsA("BasePart") then
                    part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    part.Transparency = hitboxTransparency
                    part.CanCollide = false 
                    part.Massless = true 
                    
                    if hitboxPart == "HumanoidRootPart" then
                        part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        part.AssemblyAngularVelocity = Vector2.new(0, 0)
                    end
                end
            end
        end
    end

    if not farmActive then 
        lockedTarget = nil 
        if farmAnchor then farmAnchor:Destroy() farmAnchor = nil end
    else
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

            if lockedTarget then
                if not lockedTarget.Parent or not lockedTarget.Character or 
                   not lockedTarget.Character:FindFirstChild("Humanoid") or 
                   lockedTarget.Character.Humanoid.Health <= 0 then
                    lockedTarget = nil
                end
            end

            if not lockedTarget then
                if targetPlayerName ~= "None" then
                    local p = game.Players:FindFirstChild(targetPlayerName)
                    if p and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                        lockedTarget = p
                    end
                else
                    local closestDist = math.huge
                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                            local hum = v.Character:FindFirstChild("Humanoid")
                            if hum and hum.Health > 0 and isWithinFarmZone(v.Character.HumanoidRootPart.Position) then
                                local d = (root.Position - v.Character.HumanoidRootPart.Position).Magnitude
                                if d < closestDist then
                                    closestDist = d
                                    lockedTarget = v
                                end
                            end
                        end
                    end
                end
            end

            if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
                local tHRP = lockedTarget.Character.HumanoidRootPart
                if isWithinFarmZone(tHRP.Position) then
                    local offset = isParrying(lockedTarget) and CFrame.new(0, -12, 0) or CFrame.new(0, 0, farmDistance)
                    local finalCF = (tHRP.CFrame + (tHRP.AssemblyLinearVelocity * 0.1)) * offset
                    char:PivotTo(CFrame.new(finalCF.Position, tHRP.Position))
                else
                    lockedTarget = nil 
                    char:PivotTo(CFrame.new(safePos))
                end
            else
                char:PivotTo(CFrame.new(safePos))
            end
        end
    end

    if reachEnabled then
        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            tool.Handle.Size = Vector3.new(reachSize, reachSize, reachSize)
            tool.Handle.Transparency = showPoints and 0.5 or 0
            tool.Handle.CanCollide = false
        end
    end
end)

-- Fly Logic
local function setupFly()
    local character = player.Character or player.CharacterAdded:Wait()
    hrp = character:WaitForChild("HumanoidRootPart")
    anchor = Instance.new("Part")
    anchor.Size = Vector3.new(2,2,2)
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.CFrame = hrp.CFrame
    anchor.Parent = workspace

    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part ~= hrp then
            local ap = Instance.new("AlignPosition")
            local ao = Instance.new("AlignOrientation")
            ap.Attachment0 = Instance.new("Attachment", part)
            ap.Attachment1 = Instance.new("Attachment", anchor)
            ap.RigidityEnabled = true
            ap.Parent = part
            ao.Attachment0 = Instance.new("Attachment", part)
            ao.Attachment1 = Instance.new("Attachment", anchor)
            ao.MaxTorque = 100000
            ao.Parent = part
        end
    end
end

local function toggleFly(state)
    flying = state
    if state then setupFly() else if anchor then anchor:Destroy() end end
end

userInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    inputMap[input.KeyCode] = true
    if input.KeyCode == Enum.KeyCode.Space then verticalInput = 1 end
    if input.KeyCode == Enum.KeyCode.LeftShift then verticalInput = -1 end
end)

userInput.InputEnded:Connect(function(input, gpe)
    inputMap[input.KeyCode] = false
    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift then verticalInput = 0 end
end)

runService.RenderStepped:Connect(function(delta)
    if flying and hrp and anchor then
        local moveVector = Vector3.new()
        if inputMap[Enum.KeyCode.W] then moveVector = moveVector + Vector3.new(0,0,-1) end
        if inputMap[Enum.KeyCode.S] then moveVector = moveVector + Vector3.new(0,0,1) end
        if inputMap[Enum.KeyCode.A] then moveVector = moveVector + Vector3.new(-1,0,0) end
        if inputMap[Enum.KeyCode.D] then moveVector = moveVector + Vector3.new(1,0,0) end

        local camLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
        local camRight = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit
        local horizontalDir = (camLook * -moveVector.Z + camRight * moveVector.X)
        if horizontalDir.Magnitude > 0 then horizontalDir = horizontalDir.Unit end

        local finalDir = horizontalDir * speedHorizontal + Vector3.new(0, verticalInput * speedVertical, 0)
        local newPos = anchor.Position + finalDir * delta
        local lookAt = CFrame.new(newPos, newPos + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z))
        anchor.CFrame = lookAt
        hrp.CFrame = lookAt
    end
end)

-- ESP Logic
local function createESP(targetPlayer)
    local lines = {
        top = Drawing.new("Line"),
        bottom = Drawing.new("Line"),
        left = Drawing.new("Line"),
        right = Drawing.new("Line")
    }
    
    local corners = {}
    for i = 1, 8 do
        corners[i] = Drawing.new("Line")
    end

    local fill = Drawing.new("Square")
    local nameTag = Drawing.new("Text")

    local connection
    connection = runService.RenderStepped:Connect(function()
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
            local root = targetPlayer.Character.HumanoidRootPart
            local head = targetPlayer.Character:FindFirstChild("Head")
            if not head then return end

            local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
            local dist = (camera.CFrame.Position - root.Position).Magnitude

            if onScreen and dist <= espMaxDistance and boxesEnabled then
                local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 1.5
                local x, y = rootPos.X - width / 2, rootPos.Y - height / 2

                local radius = math.min(espSettings.borderRadius, width/2, height/2)
                local color = boxColor
                local thick = espSettings.borderThickness

                if espSettings.boxType == "2D" then
                    if radius > 0 then
                        lines.top.From = Vector2.new(x + radius, y); lines.top.To = Vector2.new(x + width - radius, y)
                        lines.bottom.From = Vector2.new(x + radius, y + height); lines.bottom.To = Vector2.new(x + width - radius, y + height)
                        lines.left.From = Vector2.new(x, y + radius); lines.left.To = Vector2.new(x, y + height - radius)
                        lines.right.From = Vector2.new(x + width, y + radius); lines.right.To = Vector2.new(x + width, y + height - radius)

                        corners[1].From = Vector2.new(x, y + radius); corners[1].To = Vector2.new(x + radius * 0.3, y + radius * 0.3)
                        corners[2].From = Vector2.new(x + radius * 0.3, y + radius * 0.3); corners[2].To = Vector2.new(x + radius, y)
                        corners[3].From = Vector2.new(x + width - radius, y); corners[3].To = Vector2.new(x + width - radius * 0.3, y + radius * 0.3)
                        corners[4].From = Vector2.new(x + width - radius * 0.3, y + radius * 0.3); corners[4].To = Vector2.new(x + width, y + radius)
                        corners[5].From = Vector2.new(x, y + height - radius); corners[5].To = Vector2.new(x + radius * 0.3, y + height - radius * 0.3)
                        corners[6].From = Vector2.new(x + radius * 0.3, y + height - radius * 0.3); corners[6].To = Vector2.new(x + radius, y + height)
                        corners[7].From = Vector2.new(x + width - radius, y + height); corners[7].To = Vector2.new(x + width - radius * 0.3, y + height - radius * 0.3)
                        corners[8].From = Vector2.new(x + width - radius * 0.3, y + height - radius * 0.3); corners[8].To = Vector2.new(x + width, y + height - radius)

                        for _, l in pairs(lines) do l.Visible = true; l.Color = color; l.Thickness = thick end
                        for _, c in pairs(corners) do c.Visible = true; c.Color = color; c.Thickness = thick end
                    else
                        lines.top.From = Vector2.new(x, y); lines.top.To = Vector2.new(x + width, y)
                        lines.bottom.From = Vector2.new(x, y + height); lines.bottom.To = Vector2.new(x + width, y + height)
                        lines.left.From = Vector2.new(x, y); lines.left.To = Vector2.new(x, y + height)
                        lines.right.From = Vector2.new(x + width, y); lines.right.To = Vector2.new(x + width, y + height)

                        for _, l in pairs(lines) do l.Visible = true; l.Color = color; l.Thickness = thick end
                        for _, c in pairs(corners) do c.Visible = false end
                    end

                elseif espSettings.boxType == "Corner" then
                    for _, l in pairs(lines) do l.Visible = false end
                    for i = 1, 8 do
                        local c = corners[i]
                        c.Visible = true; c.Color = color; c.Thickness = thick
                        local length = width / 4
                        if i == 1 then c.From = Vector2.new(x, y); c.To = Vector2.new(x + length, y) end
                        if i == 2 then c.From = Vector2.new(x, y); c.To = Vector2.new(x, y + length) end
                        if i == 3 then c.From = Vector2.new(x + width, y); c.To = Vector2.new(x + width - length, y) end
                        if i == 4 then c.From = Vector2.new(x + width, y); c.To = Vector2.new(x + width, y + length) end
                        if i == 5 then c.From = Vector2.new(x, y + height); c.To = Vector2.new(x + length, y + height) end
                        if i == 6 then c.From = Vector2.new(x, y + height); c.To = Vector2.new(x, y + height - length) end
                        if i == 7 then c.From = Vector2.new(x + width, y + height); c.To = Vector2.new(x + width - length, y + height) end
                        if i == 8 then c.From = Vector2.new(x + width, y + height); c.To = Vector2.new(x + width, y + height - length) end
                    end

                elseif espSettings.boxType == "Bracket" then
                    for _, l in pairs(lines) do l.Visible = false end
                    for i = 1, 8 do
                        local c = corners[i]
                        c.Visible = true; c.Color = color; c.Thickness = thick
                        local bSize = width / 5
                        if i == 1 then c.From = Vector2.new(x, y); c.To = Vector2.new(x + bSize, y) end
                        if i == 2 then c.From = Vector2.new(x, y); c.To = Vector2.new(x, y + height) end
                        if i == 3 then c.From = Vector2.new(x, y + height); c.To = Vector2.new(x + bSize, y + height) end
                        if i == 4 then c.From = Vector2.new(x + width, y); c.To = Vector2.new(x + width - bSize, y) end
                        if i == 5 then c.From = Vector2.new(x + width, y); c.To = Vector2.new(x + width, y + height) end
                        if i == 6 then c.From = Vector2.new(x + width, y + height); c.To = Vector2.new(x + width - bSize, y + height) end
                        if i > 6 then c.Visible = false end
                    end

                elseif espSettings.boxType == "Octagon" then
                    local cut = math.min(width, height) / 4
                    for _, l in pairs(lines) do l.Visible = false end
                    for i = 1, 8 do
                        local c = corners[i]
                        c.Visible = true; c.Color = color; c.Thickness = thick
                        if i == 1 then c.From = Vector2.new(x + cut, y); c.To = Vector2.new(x + width - cut, y) end
                        if i == 2 then c.From = Vector2.new(x + width, y + cut); c.To = Vector2.new(x + width, y + height - cut) end
                        if i == 3 then c.From = Vector2.new(x + width - cut, y + height); c.To = Vector2.new(x + cut, y + height) end
                        if i == 4 then c.From = Vector2.new(x, y + height - cut); c.To = Vector2.new(x, y + cut) end
                        if i == 5 then c.From = Vector2.new(x + cut, y); c.To = Vector2.new(x, y + cut) end
                        if i == 6 then c.From = Vector2.new(x + width - cut, y); c.To = Vector2.new(x + width, y + cut) end
                        if i == 7 then c.From = Vector2.new(x + width, y + height - cut); c.To = Vector2.new(x + width - cut, y + height) end
                        if i == 8 then c.From = Vector2.new(x, y + height - cut); c.To = Vector2.new(x + cut, y + height) end
                    end
                end

                fill.Visible = espSettings.fillBox
                if fill.Visible then
                    fill.Size = Vector2.new(width, height)
                    fill.Position = Vector2.new(x, y)
                    fill.Color = espSettings.fillColor
                    fill.Transparency = espSettings.fillTransparency
                    fill.Filled = true
                end

                nameTag.Visible = espSettings.names
                if nameTag.Visible then
                    nameTag.Text = targetPlayer.Name .. " [" .. math.floor(dist) .. "m]"
                    nameTag.Position = Vector2.new(x + width / 2, y - 15)
                    nameTag.Color = Color3.new(1, 1, 1)
                    nameTag.Outline = true
                    nameTag.Center = true
                    nameTag.Size = 13
                end
            else
                for _, l in pairs(lines) do l.Visible = false end
                for _, c in pairs(corners) do c.Visible = false end
                fill.Visible = false
                nameTag.Visible = false
            end
        else
            if not targetPlayer.Parent then
                for _, l in pairs(lines) do l:Remove() end
                for _, c in pairs(corners) do c:Remove() end
                fill:Remove()
                nameTag:Remove()
                connection:Disconnect()
            end
        end
    end)
end


local function createNameESP(targetPlayer)
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Size = 13
    nameTag.Color = Color3.new(1, 1, 1)

    local connection
    connection = runService.RenderStepped:Connect(function()
        nameTag.Visible = false
        nameTag.Position = Vector2.new(-1000, -1000)

        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") and targetPlayer ~= player then
            local head = targetPlayer.Character.Head
            local hum = targetPlayer.Character:FindFirstChild("Humanoid")
            local headPos, onScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
            local dist = (camera.CFrame.Position - head.Position).Magnitude

            if onScreen and espSettings.names and dist <= espMaxDistance then
                local content = targetPlayer.Name
                
                if espSettings.showDistance then
                    content = content .. string.format(" [%dm]", math.floor(dist))
                end
                
                if espSettings.showHealth and hum then
                    content = content .. string.format(" (%d HP)", math.floor(hum.Health))
                end

                if espSettings.teamColor and targetPlayer.TeamColor then
                    nameTag.Color = targetPlayer.TeamColor.Color
                else
                    nameTag.Color = Color3.new(1, 1, 1)
                end

                nameTag.Text = content
                nameTag.Position = Vector2.new(headPos.X, headPos.Y)
                nameTag.Visible = true
            end
        elseif not targetPlayer.Parent then
            nameTag:Remove()
            connection:Disconnect()
        end
    end)
end

for _, v in pairs(game.Players:GetPlayers()) do
    createESP(v)      
    createNameESP(v)  
end

game.Players.PlayerAdded:Connect(function(v)
    createESP(v)
    createNameESP(v)
end)






runService.RenderStepped:Connect(function()
    if hitboxEnabled then
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= player and v.Character then
                local parts = {v.Character:FindFirstChild("HumanoidRootPart"), v.Character:FindFirstChild("Head")}
                
                for _, p in pairs(parts) do
                    if p then
                        if p.Name == hitboxPart then
                            p.Size = Vector3.new(Options.HitboxSlider.Value, Options.HitboxSlider.Value, Options.HitboxSlider.Value)
                            p.Transparency = Options.HitboxTrans.Value
                            p.Transparency = hitboxTransparency
                            p.CanCollide = false
                        else
                            if p.Name == "Head" then p.Size = Vector3.new(1.2, 1.2, 1.2) else p.Size = Vector3.new(2, 2, 1) end
                            p.Transparency = (p.Name == "Head" and 0 or 1) -- Голову обычно видно, торс - нет
                        end
                    end
                end
            end
        end
    end
end)


runService.Heartbeat:Connect(function()
    if reachEnabled then
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        
        if tool then
            for _, v in pairs(tool:GetDescendants()) do
                if v:IsA("Attachment") and v.Name == "DmgPoint" then
                    
                    if not v:FindFirstChild("OriginalPos") then
                        local origin = Instance.new("Vector3Value", v)
                        origin.Name = "OriginalPos"
                        origin.Value = v.Position
                    end
                    
                    local multiplier = 1 + (reachSize * 0.2)
                    v.Position = v.OriginalPos.Value * Vector3.new(1, 1, multiplier)
                    
                    if showPoints then
                        local p = v:FindFirstChild("ReachVisual") or Instance.new("Part")
                        if p.Name ~= "ReachVisual" then
                            p = Instance.new("Part")
                            p.Name = "ReachVisual"
                            p.Parent = v
                            p.Anchored = true
                            p.CanCollide = false
                            p.Shape = Enum.PartType.Ball
                            p.Size = Vector3.new(0.2, 0.2, 0.2)
                            p.Color = Color3.fromRGB(0, 255, 0)
                            p.Material = Enum.Material.Neon
                        end
                        p.CFrame = v.WorldCFrame
                        p.Transparency = 0
                    elseif v:FindFirstChild("ReachVisual") then
                        v.ReachVisual.Transparency = 1
                    end
                end
            end
        end
    else
        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _, v in pairs(tool:GetDescendants()) do
                if v:IsA("Attachment") and v:FindFirstChild("OriginalPos") then
                    v.Position = v.OriginalPos.Value
                    if v:FindFirstChild("ReachVisual") then
                        v.ReachVisual:Destroy()
                    end
                    v.OriginalPos:Destroy()
                end
            end
        end
    end
end)


local function scanWeapon()
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    
    if tool then
        print("--- [ SCANNING WEAPON: " .. tool.Name .. " ] ---")
        for _, v in pairs(tool:GetDescendants()) do
            if v:IsA("Attachment") then
                print("FOUND POINT: " .. v.Name .. " | Path: " .. v:GetFullName())
                
                local p = Instance.new("Part")
                p.Name = "DebugVisual"
                p.Shape = Enum.PartType.Ball
                p.Size = Vector3.new(0.4, 0.4, 0.4)
                p.Color = Color3.fromRGB(255, 0, 0) -- Красный для поиска
                p.Material = Enum.Material.Neon
                p.Anchored = true
                p.CanCollide = false
                p.Parent = workspace

                task.spawn(function()
                    while v and v.Parent and p.Parent do
                        p.CFrame = v.WorldCFrame
                        task.wait()
                    end
                    p:Destroy()
                end)

                task.delay(10, function() if p then p:Destroy() end end)
            end
        end
        print("--- [ SCAN COMPLETE ] ---")
    else
        Fluent:Notify({ Title = "Debug", Content = "Take a weapon in your hand first!", Duration = 3 })
    end
end


-- [ INTERFACE ELEMENTS ]
do
    -- // MOVEMENT TAB
    Tabs.Main:AddParagraph({ Title = "Movement", Content = "fly and speed settings" })

    local FlyToggle = Tabs.Main:AddToggle("FlyToggle", { Title = "Fly", Default = false })
    FlyToggle:OnChanged(function() 
        toggleFly(Options.FlyToggle.Value)
        Notify("Fly", Options.FlyToggle.Value)
    end)

    Tabs.Main:AddSlider("FlySpeed", {
        Title = "Speed", Default = 52, Min = 10, Max = 500, Rounding = 0, ID = "FlySpeed",
        Callback = function(Value) speedHorizontal = Value end
    })

    Tabs.Main:AddKeybind("FlyKeybind", {
        Title = "Bind", Mode = "Toggle", Default = "G", ID = "FlyKeybind",
        Callback = function(Value) Options.FlyToggle:SetValue(Value) end,
    })


    -- // COMBAT TAB
    Tabs.Aimbot:AddParagraph({ Title = "Aimbot", Content = "auto aiming settings" })

    local AimToggle = Tabs.Aimbot:AddToggle("AimEnabled", { Title = "Enabled", Default = false })
    AimToggle:OnChanged(function(Value) 
        AimbotSettings.Enabled = Value 
        Notify("Aimbot", Value)
    end)

    Tabs.Aimbot:AddDropdown("AimPart", {
        Title = "Target Part", Values = {"Head", "HumanoidRootPart"}, Default = "Head", ID = "AimPart",
        Callback = function(Value) AimbotSettings.LockPart = Value end
    })

    Tabs.Aimbot:AddKeybind("AimBind", {
        Title = "Bind", Mode = "Toggle", Default = "V", ID = "AimBind",
        Callback = function(Value) Options.AimEnabled:SetValue(Value) end,
    })

    Tabs.Aimbot:AddSlider("AimSmooth", {
        Title = "Smoothness", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2, ID = "AimSmooth",
        Callback = function(Value) AimbotSettings.Sensitivity = Value end
    })

    Tabs.Aimbot:AddParagraph({ Title = "FOV", Content = "fov circle settings" })

    Tabs.Aimbot:AddToggle("FOVVisible", { Title = "Show FOV", Default = true, ID = "FOVVisible" }):OnChanged(function(Value)
        FOVSettings.Visible = Value
        FOVSettings.Enabled = Value
    end)

    Tabs.Aimbot:AddColorpicker("FOVColor", {
        Title = "FOV Color", Default = Color3.fromRGB(255, 255, 255), ID = "FOVColor",
        Callback = function(Value) if not rainbowFOV then FOVSettings.Color = Value end end
    })
    
    Tabs.Aimbot:AddSlider("AimFOV", {
        Title = "FOV Radius", Default = 150, Min = 10, Max = 800, Rounding = 0, ID = "AimFOV",
        Callback = function(Value) FOVSettings.Radius = Value end
    })

    Tabs.Aimbot:AddToggle("FOVRainbow", { Title = "Rainbow FOV", Default = false, ID = "FOVRainbow" }):OnChanged(function(Value)
        rainbowFOV = Value
    end)


    -- // ESP TAB
    Tabs.Esp:AddParagraph({ Title = "ESP", Content = "player esp settings" })

    local BoxToggle = Tabs.Esp:AddToggle("BoxEnabledToggle", { Title = "Boxes", Default = false })
    BoxToggle:OnChanged(function(Value)
        boxesEnabled = Value
        Notify("Boxes", Value)
    end)

    Tabs.Esp:AddDropdown("BoxTypeDropdown", {
        Title = "Box Type", Values = {"2D", "Corner", "Bracket", "Octagon"}, Default = "2D",
        Callback = function(Value) espSettings.boxType = Value end
    })

    Tabs.Esp:AddColorpicker("BoxColorPickerID", {
        Title = "Box Color", Default = Color3.fromRGB(255, 255, 255),
        Callback = function(Value) boxColor = Value end
    })

    Tabs.Esp:AddSlider("BoxThickSliderID", {
        Title = "Thickness", Default = 1, Min = 1, Max = 10, Rounding = 1,
        Callback = function(Value) espSettings.borderThickness = Value boxThickness = Value end
    })

    Tabs.Esp:AddSlider("BorderRadius", {
        Title = "Rounding", Default = 0, Min = 0, Max = 20, Rounding = 0,
        Callback = function(Value) espSettings.borderRadius = Value espSettings.rounded = (Value > 0) end
    })

    Tabs.Esp:AddParagraph({ Title = "Fill", Content = "box transparency settings" })

    Tabs.Esp:AddToggle("BoxFillToggle", { Title = "Fill", Default = false }):OnChanged(function(Value)
        espSettings.fillBox = Value
    end)

    Tabs.Esp:AddColorpicker("FillColorPicker", {
        Title = "Fill Color", Default = Color3.fromRGB(255, 0, 0),
        Callback = function(Value) espSettings.fillColor = Value end
    })

    Tabs.Esp:AddSlider("FillTransparencySlider", {
        Title = "Transparency", Default = 0.3, Min = 0, Max = 1, Rounding = 2,
        Callback = function(Value) espSettings.fillTransparency = Value end
    })

    Tabs.Esp:AddParagraph({ Title = "Extra", Content = "names and distance settings" })

    Tabs.Esp:AddToggle("ShowNamesToggle", { Title = "Show Names", Default = false }):OnChanged(function(Value)
        espSettings.names = Value
    end)

    Tabs.Esp:AddToggle("ShowDistToggle", { Title = "Show Distance", Default = true }):OnChanged(function(Value)
        espSettings.showDistance = Value
    end)

    Tabs.Esp:AddToggle("ShowHealthToggle", { Title = "Show Health", Default = false }):OnChanged(function(Value)
        espSettings.showHealth = Value
    end)

    Tabs.Esp:AddToggle("UseTeamColorToggle", { Title = "Team Color", Default = false }):OnChanged(function(Value)
        espSettings.teamColor = Value
    end)

    Tabs.Esp:AddSlider("EspDistanceSlider", {
        Title = "Max Distance", Default = 500, Min = 50, Max = 3000, Rounding = 0,
        Callback = function(Value) espMaxDistance = Value end
    })


    -- // AUTO-FARM TAB
    Tabs.Farm:AddParagraph({ Title = "Farm", Content = "kill aura farm" })

    local FarmToggle = Tabs.Farm:AddToggle("FarmToggle", { Title = "Enabled", Default = false })
    FarmToggle:OnChanged(function(Value)
        farmActive = Value
        Notify("Auto-Farm", Value)
    end)

    Tabs.Farm:AddKeybind("FarmBind", {
        Title = "Bind", Mode = "Toggle", Default = "H", ID = "FarmBind",
        Callback = function(Value) Options.FarmToggle:SetValue(Value) end,
    })

    Tabs.Farm:AddSlider("FarmDistance", {
        Title = "Distance", Default = 9.9, Min = 1, Max = 20, Rounding = 1, ID = "FarmDistance",
        Callback = function(Value) farmDistance = Value end
    })

    local function getPlayerList()
        local list = {"None"}
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= player then table.insert(list, v.Name) end
        end
        return list
    end

    local PlayerDropdown = Tabs.Farm:AddDropdown("TargetDropdown", {
        Title = "Target Player", Values = getPlayerList(), Default = "None",
        Callback = function(Value) targetPlayerName = Value end
    })

    game.Players.PlayerAdded:Connect(function() PlayerDropdown:SetValues(getPlayerList()) end)
    game.Players.PlayerRemoving:Connect(function() PlayerDropdown:SetValues(getPlayerList()) end)


    -- // DEVELOPMENT TAB
    Tabs.Dev:AddParagraph({ Title = "Tools", Content = "development utilities" })

    Tabs.Dev:AddButton({
        Title = "Copy Position",
        Description = "copies Vector3 to clipboard",
        Callback = function()
            local pos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
            if pos then
                setclipboard(tostring(pos))
                Fluent:Notify({
                    Title = "Development",
                    Content = "Position copied!",
                    Duration = 2
                })
            end
        end
    })

    Tabs.Dev:AddButton({
        Title = "Server Hop",
        Description = "join a different server",
        Callback = function()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            
            for _, s in pairs(Servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player)
                    break
                end
            end
        end
    })

    Tabs.Dev:AddButton({
        Title = "Re-join",
        Description = "reconnect to this server",
        Callback = function()
            local TeleportService = game:GetService("TeleportService")
            if #game.Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, player)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
            end
        end
    })

    Tabs.Dev:AddButton({
        Title = "Scan Points",
        Description = "scan weapon hit-points",
        Callback = function()
            scanWeapon()
        end
    })


    -- // HITBOXES TAB
    Tabs.Hitboxes:AddParagraph({ Title = "Hitbox", Content = "expand player hitboxes" })

    local HitboxToggle = Tabs.Hitboxes:AddToggle("HitboxToggle", { Title = "Enabled", Default = false })
    HitboxToggle:OnChanged(function(Value)
        hitboxEnabled = Value

        if not Value then
            for _, v in pairs(game.Players:GetPlayers()) do
                if v ~= player and v.Character then
                    local head = v.Character:FindFirstChild("Head")
                    local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                    
                    if head then
                        head.Size = Vector3.new(1.2, 1.2, 1.2) 
                        head.Transparency = 0
                    end
                    if hrp then
                        hrp.Size = Vector3.new(2, 2, 1) 
                        hrp.Transparency = 1
                    end
                end
            end
        end
        
        Notify("Hitboxes", Value)
    end)

    Tabs.Hitboxes:AddDropdown("HitboxPartSelector", {
        Title = "Target Part", Values = {"HumanoidRootPart", "Head"}, Default = "Head",
        Callback = function(Value) hitboxPart = Value end
    })

    Tabs.Hitboxes:AddSlider("HitboxSlider", {
        Title = "Size", Default = 2, Min = 1, Max = 20, Rounding = 1,
        Callback = function(Value) hitboxSize = Value end
    })

    Tabs.Hitboxes:AddSlider("HitboxTrans", {
        Title = "Transparency", Default = 0.7, Min = 0, Max = 1, Rounding = 1,
        Callback = function(Value) hitboxTransparency = Value end
    })

    Tabs.Hitboxes:AddParagraph({ Title = "Reach", Content = "expand weapon range" })

    local ReachToggle = Tabs.Hitboxes:AddToggle("ReachToggle", { Title = "Enabled", Default = false })
    ReachToggle:OnChanged(function(Value)
        reachEnabled = Value
        Notify("Reach", Value)
    end)

    Tabs.Hitboxes:AddSlider("ReachDistance", {
        Title = "Distance", Default = 10, Min = 1, Max = 15, Rounding = 1,
        Callback = function(Value) reachSize = Value end
    })

    Tabs.Hitboxes:AddToggle("ShowReachPoints", { Title = "Show Points", Default = true, Callback = function(Value) showPoints = Value end })

    Tabs.Settings:AddParagraph({ Title = "Telegram", Content = "https://t.me/ubogiyinject" })

    Tabs.Settings:AddDropdown("NotifSound", { 
        Title = "Notification Sound",
        Values = {"no", "zipp", "default", "osu", "bricks"},
        Default = "default",
        Callback = function(Value)
            if Value == "no" then
                notificationSound = nil
            elseif Value == "zipp" then
                notificationSound = 12222124 
            elseif Value == "default" then
                notificationSound = 4590662766 
            elseif Value == "osu" then
                notificationSound = 7147454322
            elseif Value == "bricks" then
                notificationSound = 6895079853
            end
        end
    })

end

-- [ CONFIG MANAGEMENT ]
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()
