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
local aimlockConnection
local aimLockUI = nil  -- For the on-screen aimlock toggle

-- New variables for added features
local godModeEnabled = false
local infiniteAmmoEnabled = false
local noClipEnabled = false
local killAuraEnabled = false
local autoFarmConnection

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

local MainTab = Window:CreateTab("Main", 4483362458)
local ExtraTab = Window:CreateTab("Extras", 4483362458)  -- New tab for additional features

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

-- Aimlock Toggle (improved)
MainTab:CreateToggle({
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

-- Teleport Tool (mobile-adapted: uses raycast from camera center)
MainTab:CreateButton({
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

-- Speed Control
MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},  -- Increased range
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

-- Jump Enable
MainTab:CreateToggle({
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

-- Jump Power
MainTab:CreateSlider({
    Name = "Jump Power",
    Range = {0, 200},  -- Increased range
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

-- Allow Jump Button
MainTab:CreateButton({
    Name = "Allow Jump (Infinite)",
    Callback = function()
        UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end,
})

-- ESP Toggle (enhanced)
MainTab:CreateToggle({
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

-- Tracers Toggle (enhanced with removal)
MainTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "TracersEnabled",
    Callback = function(state)
        tracersEnabled = state
        if not state then
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("TracerLine") then
                    player.Character.TracerLine:Destroy()
                end
            end
        end
    end
})

-- New Feature: God Mode Toggle
MainTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodModeEnabled",
    Callback = function(state)
        godModeEnabled = state
        if godModeEnabled then
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
                humanoid.HealthChanged:Connect(function()
                    if godModeEnabled then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end)
            end
        end
    end
})

-- New Feature: Infinite Ammo Toggle
MainTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Flag = "InfiniteAmmoEnabled",
    Callback = function(state)
        infiniteAmmoEnabled = state
        if infiniteAmmoEnabled then
            RunService.RenderStepped:Connect(function()
                if infiniteAmmoEnabled and LocalPlayer.Character then
                    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
                            tool.Ammo.Value = 999  -- Assumes ammo is stored in a NumberValue named "Ammo"
                        end
                    end
                    if LocalPlayer.Character:FindFirstChildOfClass("Tool") and LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Ammo") then
                        LocalPlayer.Character:FindFirstChildOfClass("Tool").Ammo.Value = 999
                    end
                end
            end)
        end
    end
})

-- New Feature: No Clip Toggle
MainTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "NoClipEnabled",
    Callback = function(state)
        noClipEnabled = state
        if noClipEnabled then
            local character = LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        else
            local character = LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- New Feature: Auto Farm Button
MainTab:CreateButton({
    Name = "Auto Farm",
    Callback = function()
        if autoFarmConnection then autoFarmConnection:Disconnect() end
        autoFarmConnection = RunService.RenderStepped:Connect(function()
            for _, item in pairs(workspace:GetChildren()) do
                if item:IsA("Model") and item:FindFirstChild("Collect") then  -- Assumes collectibles have a "Collect" part or script
                    LocalPlayer.Character:SetPrimaryPartCFrame(item.Collect.CFrame)
                    wait(0.5)  -- Brief wait to simulate collection
                end
            end
        end)
        wait(10)  -- Run for 10 seconds, then stop
        if autoFarmConnection then autoFarmConnection:Disconnect() end
    end
})

-- New Feature: Kill Aura Toggle
MainTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAuraEnabled",
    Callback = function(state)
        killAuraEnabled = state
        if killAuraEnabled then
            RunService.RenderStepped:Connect(function()
                if killAuraEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                            if distance <= 10 then  -- 10-stud radius
                                player.Character.Humanoid:TakeDamage(10)  -- Deal 10 damage per frame
                            end
                        end
                    end
                end
            end)
        end
    end
