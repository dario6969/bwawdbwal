local RunService = game:GetService('RunService')

local player = game.Players.LocalPlayer

local function clearCons()
    for _, con in shared.Connections do
        con:Disconnect()
    end

    table.clear(shared.Connections)

    if shared.Visualizer then
        shared.Visualizer:Destroy()
    end

    if shared.Interpolated then
        shared.Interpolated:Destroy()
    end

    print('disconnected old')
end

if shared.Connections then
    clearCons()
end

shared.Connections = {}

local function isAlive(entity)
    return entity:FindFirstChild('Humanoid') and entity.Humanoid.Health > 0
end

local function init(character)
    clearCons()

    local humanoid = character:WaitForChild('Humanoid')
    local root = character:WaitForChild('HumanoidRootPart')

    humanoid.Died:Once(clearCons)

    local cooldown = false

    local targetUpdate = 0
    local lastTarget

    local lastVelocity = Vector3.zero

    local visualizer = Instance.new('Part')
    visualizer.Size = Vector3.zero
    visualizer.Shape = Enum.PartType.Ball
    visualizer.Color = Color3.fromRGB(255, 255, 255)
    visualizer.Material = Enum.Material.Neon
    visualizer.Transparency = 0.99
    visualizer.CanCollide = false
    visualizer.Parent = workspace

    local fakeBall = Instance.new('Part')
    fakeBall.Size = Vector3.one * 3
    fakeBall.Shape = Enum.PartType.Ball
    fakeBall.Color = Color3.fromRGB(255, 106, 106)
    fakeBall.Material = Enum.Material.Neon
    fakeBall.Transparency = 0.5
    fakeBall.CanCollide = false
    fakeBall.Parent = workspace

    shared.Visualizer = visualizer
    shared.Interpolated = fakeBall

    local function autoParry()
        if not root.Parent then
            return
        end

        if cooldown then
            return
        end

        local pos = root.Position

        visualizer.Position = pos

        local ping = game.Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000

        for _, ball in workspace.Balls:GetChildren() do
            if not (ball:GetAttribute('realBall')) then
                continue
            end

            local velocity = ball.Velocity

            if velocity.Magnitude < lastVelocity.Magnitude then
                velocity = lastVelocity:Lerp(velocity, (1 / ping) * 0.01)
            end

            lastVelocity = velocity

            local interpolated = ball.Position + (ball.Velocity * (ping / 2))
            local distance = 1 + (velocity.Magnitude / 5) + (ping * 100)

            fakeBall.Position = interpolated
            visualizer.Size = Vector3.one * distance

            if ball:GetAttribute('target') ~= player.Name then
                return
            end
            
            if (pos - interpolated).Magnitude < distance then
                keypress(0x46)

                if lastTarget then
                    if isAlive(lastTarget) and os.clock() - targetUpdate < ping then
                        return
                    else
                        lastTarget = nil
                    end
                end
                
                cooldown = true

                ball:GetAttributeChangedSignal('target'):Wait()

                local target = ball:GetAttribute('target')

                cooldown = false

                if target and target.Name ~= player.Name then
                    local entity = workspace.Alive:FindFirstChild(target)

                    if entity and isAlive(entity) then
                        lastTarget = entity
                        targetUpdate = os.clock()
                    end
                end
                
                break
            end

            return
        end

        visualizer.Size = Vector3.one
    end

    table.insert(shared.Connections, RunService.PostSimulation:Connect(autoParry))
    table.insert(shared.Connections, RunService.PreSimulation:Connect(autoParry))
end

if shared.Poop then
    shared.Poop:Disconnect()
end

shared.Poop = player.CharacterAdded:Connect(init)

if player.Character then
    init(player.Character)
end
