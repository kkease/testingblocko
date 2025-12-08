local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local aimLockEnabled = false
local teleportTool = nil
local espEnabled = false
local tracersEnabled = false
local nameTagsEnabled = false
local triggerBotEnabled = false
local pickUpToolsEnabled = false
local showUsernamesEnabled = false
local aimlockConnection
local triggerBotConnection
local pickUpConnection
local aimLockUI = nil  -- For the on-screen aimlock toggle
local usernameUI = nil  -- For fire-type username UI

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    warn("Rayfield failed to load.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Saif's Ultimate ChicoBlocko Toolkit",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Powered by Rayfield - Enhanced Edition",
    ConfigurationSaving = {
        Enabled = true,
        FileName = "SaifUltimateChicoToolkitConfig"
    },
    Discord = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "Access Required",
        Subtitle = "Enter the key to unlock",
        FileName = "SaifUltimateChicoKeyAccess",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = { "615879", "2124267" }  -- Combined keys
    }
})

-- Organized Tabs
local CombatTab = Window:CreateTab("Combat", 4483362458)  -- For aimlock, triggerbot
local MovementTab = Window:CreateTab("Movement", 4483362458)  -- For speed, jump, fly, teleport
local VisualsTab = Window:CreateTab("Visuals", 4483362458)  -- For ESP, tracers, usernames
local UtilitiesTab = Window:CreateTab("Utilities", 4483362458)  -- For tools, prompts, teleports

-- Function to create aimlock UI
local function createAimLockUI()
    if aimLockUI then return end
    aimLockUI = Instance.new("ScreenGui", game.CoreGui)
    aimLockUI.Name = "AimLockUI"

    local frame = Instance.new("Frame", aimLockUI)
    frame.Size = UDim2.new(0, 150, 0, 60)
    frame.Position = UDim2.new(0.5, -75, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local toggleButton = Instance.new("TextButton", frame)
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    toggleButton.Text = "Disable Aim Lock"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextScaled = true

    toggleButton.MouseButton1Click:Connect(function()
        aimLockEnabled = not aimLockEnabled
        if aimLockEnabled then
            toggleButton.Text = "Disable Aim Lock"
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            -- Restart connection if it was disconnected
            if not aimlockConnection then
                local function getClosestToCursor()
                    local closestPlayer = nil
                    local shortestDistance = math.huge
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                            if onScreen then
                                local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                                if dist < shortestDistance then
                                    shortestDistance = dist
                                    closestPlayer = player
                                end
                            end
                        end
                    end
                    return closestPlayer
                end

                aimlockConnection = RunService.RenderStepped:Connect(function()
                    if aimLockEnabled then
                        local target = getClosestToCursor()
                        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
                        end
                    end
                end)
            end
        else
            toggleButton.Text = "Enable Aim Lock"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            if aimlockConnection then
                aimlockConnection:Disconnect()
                aimlockConnection = nil
            end
        end
    end)
end

local function destroyAimLockUI()
    if aimLockUI then
        aimLockUI:Destroy()
        aimLockUI = nil
    end
end

-- Function to create fire-type username UI
local function createUsernameUI()
    if usernameUI then return end
    usernameUI = Instance.new("ScreenGui", game.CoreGui)
    usernameUI.Name = "UsernameUI"

    local frame = Instance.new("Frame", usernameUI)
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0.8, -150, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 100, 0)  -- Fire-like orange
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Player Usernames (Fire Mode)"
    title.TextColor3 = Color3.fromRGB(255, 150, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold

    local scrollFrame = Instance.new("ScrollingFrame", frame)
    scrollFrame.Size = UDim2.new(1, 0, 1, -30)
    scrollFrame.Position = UDim2.new(0, 0, 0, 30)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 5

    local function updateUsernames()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        local yOffset = 0
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local label = Instance.new("TextLabel", scrollFrame)
                label.Size = UDim2.new(1, 0, 0, 25)
                label.Position = UDim2.new(0, 0, 0, yOffset)
                label.BackgroundTransparency = 1
                label.Text = player.Name
                label.TextColor3 = Color3.fromRGB(255, math.random(100, 255), 0)  -- Random fire colors
                label.TextScaled = true
                label.Font = Enum.Font.GothamBold
                label.TextStrokeTransparency = 0.5
                label.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
                yOffset = yOffset + 25
            end
        end
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end

    updateUsernames()
    Players.PlayerAdded:Connect(updateUsernames)
    Players.PlayerRemoving:Connect(updateUsernames)
end

local function destroyUsernameUI()
    if usernameUI then
        usernameUI:Destroy()
        usernameUI = nil
    end
end

-- Combat Tab Features
CombatTab:CreateToggle({
    Name = "Aimlock (with On-Screen Toggle)",
    CurrentValue = false,
    Flag = "AimlockEnabled",
    Callback = function(v)
        aimLockEnabled = v
        if aimLockEnabled then
            createAimLockUI()
            local function getClosestToCursor()
                local closestPlayer = nil
                local shortestDistance = math.huge
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                        if onScreen then
                            local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                            if dist < shortestDistance then
                                shortestDistance = dist
                                closestPlayer = player
                            end
                        end
                    end
                end
                return closestPlayer
            end

            aimlockConnection = RunService.RenderStepped:Connect(function()
                if aimLockEnabled then
                    local target = getClosestToCursor()
                    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
                    end
                end
            end)
        else
            destroyAimLockUI()
            if aimlockConnection then
                aimlockConnection:Disconnect()
                aimlockConnection = nil
            end
        end
    end,
})

CombatTab:CreateToggle({
    Name = "Trigger Bot",
    CurrentValue = false,
    Flag = "TriggerBotEnabled",
    Callback = function(state)
        triggerBotEnabled = state
        if triggerBotEnabled then
            triggerBotConnection = RunService.RenderStepped:Connect(function()
                if triggerBotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") then
                    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Handle") then
                        local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                        local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
                        if raycastResult and raycastResult.Instance and raycastResult.Instance:IsDescendantOf(workspace) then
                            for _, player in pairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer and player.Character and raycastResult.Instance:IsDescendantOf(player.Character) then
                                    tool:Activate()
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        else
            if triggerBotConnection then
                triggerBotConnection:Disconnect()
                triggerBotConnection = nil
            end
        end
    end
})

-- Movement Tab Features
MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

MovementTab:CreateToggle({
    Name = "Enable Jump",
    CurrentValue = false,
    Flag = "EnableJump",
    Callback = function(state)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = state
            LocalPlayer.Character.Humanoid.JumpPower = state and 50 or 0
        end
    end
})

MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {0, 200},
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

MovementTab:CreateButton({
    Name = "Allow Jump (Infinite)",
    Callback = function()
        UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end,
})

MovementTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(state)
        if state then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                bodyVelocity.Parent = char.HumanoidRootPart

                local flyConnection
                flyConnection = RunService.RenderStepped:Connect(function()
                    if not state then flyConnection:Disconnect() return end
                    local moveDirection = Vector3.new()
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
                    bodyVelocity.Velocity = moveDirection * 50
                end)
            end
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local bv = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity")
                if bv then bv:Destroy() end
            end
        end
    end
})

MovementTab:CreateButton({
    Name = "Add Teleport Tool",
    Callback = function()
        if not LocalPlayer.Backpack:FindFirstChild("TeleportTool") then
            teleportTool = Instance.new("Tool")
            teleportTool.RequiresHandle = false
            teleportTool.Name = "TeleportTool"

            teleportTool.Activated:Connect(function()
                local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
                if raycastResult then
                    local targetPos = raycastResult.Position
                    local currentPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
                    if currentPos and (targetPos - currentPos).Magnitude <= 50 then
                        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
                    end
                end
            end)

            teleportTool.Parent = LocalPlayer.Backpack
        end
    end
})

-- Visuals Tab Features
VisualsTab:CreateToggle({
    Name = "ESP (Green Highlights & Name Tags)",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(state)
        espEnabled = state
        local function setupESP(character, player)
            if character:FindFirstChild("ESP_Highlight") then
                character.ESP_Highlight:Destroy()
            end
            if character:FindFirstChild("NameTag") then
                character.NameTag:Destroy()
            end
            if espEnabled then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Adornee = character
                highlight.FillColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = character

                local billboard = Instance.new("BillboardGui")
                billboard.Name = "NameTag"
                billboard.Size = UDim2.new(2, 0, 0.5, 0)
                billboard.Adornee = character:WaitForChild("Head")
                billboard.AlwaysOnTop = true
                billboard.Parent = character

                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.BackgroundTransparency = 1
                text.TextColor3 = Color3.new(1, 1, 1)
                text.TextStrokeTransparency = 0
                text.Font = Enum.Font.GothamBold
                text.TextScaled = true
                text.Text = player.Name .. " [" .. math.floor((LocalPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude) .. "m]"
                text.Parent = billboard
            end
        end

        local function onCharacterAdded(character, player)
            if espEnabled then
                setupESP(character, player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
            if player.Character then
                onCharacterAdded(player.Character, player)
            end
        end

        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
        end)
    end
})

VisualsTab:CreateToggle({
    Name = "Tracers (Red Connections)", 
CurrentValue = false,
    Flag = "TracersEnabled",
    Callback = function(state)
        tracersEnabled = state
        local function setupTracers(character, player)
            if character:FindFirstChild("Tracer") then
                character.Tracer:Destroy()
            end
            if tracersEnabled then
                local tracer = Instance.new("Beam")
                tracer.Name = "Tracer"
                tracer.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))  -- Red color
                tracer.Width0 = 0.1
                tracer.Width1 = 0.1
                tracer.FaceCamera = true
                tracer.Parent = character

                local attachment0 = Instance.new("Attachment")
                attachment0.Position = Vector3.new(0, 0, 0)
                attachment0.Parent = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

                local attachment1 = Instance.new("Attachment")
                attachment1.Position = Vector3.new(0, 0, 0)
                attachment1.Parent = character:WaitForChild("HumanoidRootPart")

                tracer.Attachment0 = attachment0
                tracer.Attachment1 = attachment1
            end
        end

        local function onCharacterAdded(character, player)
            if tracersEnabled then
                setupTracers(character, player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
            if player.Character then
                onCharacterAdded(player.Character, player)
            end
        end

        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
        end)
    end
})

VisualsTab:CreateToggle({
    Name = "Name Tags",
    CurrentValue = false,
    Flag = "NameTagsEnabled",
    Callback = function(state)
        nameTagsEnabled = state
        -- Note: Name tags are already included in ESP, but this could be a separate toggle if needed
        -- For simplicity, this can toggle the text part of ESP or create standalone name tags
        -- Assuming it's separate, similar to ESP but only name tags
        local function setupNameTags(character, player)
            if character:FindFirstChild("NameTag") then
                character.NameTag:Destroy()
            end
            if nameTagsEnabled then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "NameTag"
                billboard.Size = UDim2.new(2, 0, 0.5, 0)
                billboard.Adornee = character:WaitForChild("Head")
                billboard.AlwaysOnTop = true
                billboard.Parent = character

                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.BackgroundTransparency = 1
                text.TextColor3 = Color3.new(1, 1, 1)
                text.TextStrokeTransparency = 0
                text.Font = Enum.Font.GothamBold
                text.TextScaled = true
                text.Text = player.Name
                text.Parent = billboard
            end
        end

        local function onCharacterAdded(character, player)
            if nameTagsEnabled then
                setupNameTags(character, player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
            if player.Character then
                onCharacterAdded(player.Character, player)
            end
        end

        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
        end)
    end
})

VisualsTab:CreateToggle({
    Name = "Show Usernames (Fire UI)",
    CurrentValue = false,
    Flag = "ShowUsernamesEnabled",
    Callback = function(state)
        showUsernamesEnabled = state
        if showUsernamesEnabled then
            createUsernameUI()
        else
            destroyUsernameUI()
        end
    end
})

-- Utilities Tab Features
UtilitiesTab:CreateToggle({
    Name = "Auto Pick Up Tools",
    CurrentValue = false,
    Flag = "PickUpToolsEnabled",
    Callback = function(state)
        pickUpToolsEnabled = state
        if pickUpToolsEnabled then
            pickUpConnection = RunService.RenderStepped:Connect(function()
                if pickUpToolsEnabled and LocalPlayer.Character then
                    for _, tool in ipairs(workspace:GetChildren()) do
                        if tool:IsA("Tool") and (tool.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 10 then
                            tool.Parent = LocalPlayer.Backpack
                        end
                    end
                end
            end)
        else
            if pickUpConnection then
                pickUpConnection:Disconnect()
                pickUpConnection = nil
            end
        end
    end
})

UtilitiesTab:CreateButton({
    Name = "Teleport to Random Player",
    Callback = function()
        local players = Players:GetPlayers()
        local randomPlayer = players[math.random(1, #players)]
        if randomPlayer ~= LocalPlayer and randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:SetPrimaryPartCFrame(randomPlayer.Character.HumanoidRootPart.CFrame)
        end
    end
})

UtilitiesTab:CreateButton({
    Name = "Destroy All UIs",
    Callback = function()
        destroyAimLockUI()
        destroyUsernameUI()
        -- Add more if needed
    end
})

-- End of script
