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

local settings = {
    ParrySphere = true,
    BallPrediction = true,
} do
    if shared.Settings then
        for name, value in shared.Settings do
            settings[name] = value
        end
    end
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

    local visualizer
    local fakeBall

    if settings.ParrySphere then
        visualizer = Instance.new('Part')
        visualizer.Size = Vector3.zero
        visualizer.Shape = Enum.PartType.Ball
        visualizer.Color = Color3.fromRGB(255, 255, 255)
        visualizer.Material = Enum.Material.Neon
        visualizer.Transparency = 0.99
        visualizer.CanCollide = false
        visualizer.Parent = workspace

        shared.Visualizer = visualizer
    end

    if settings.BallPrediction then
        fakeBall = Instance.new('Part')
        fakeBall.Size = Vector3.one * 3
        fakeBall.Shape = Enum.PartType.Ball
        fakeBall.Color = Color3.fromRGB(255, 106, 106)
        fakeBall.Material = Enum.Material.Neon
        fakeBall.Transparency = 0.5
        fakeBall.CanCollide = false
        fakeBall.Parent = workspace

        shared.Interpolated = fakeBall
    end

    local function autoParry()
        if not root.Parent then
            return
        end

        if cooldown then
            return
        end

        local pos = root.Position

        if visualizer then
            visualizer.Position = pos
        end

        local ping = game.Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000

        for _, ball in workspace.Balls:GetChildren() do
            if not (ball:GetAttribute('realBall')) then
                continue
            end

            local velocity = ball.Velocity

            if velocity.Magnitude < 3 then
                return
            end

            if velocity.Magnitude < lastVelocity.Magnitude then
                velocity = lastVelocity:Lerp(velocity, (1 / ping) * 0.01)
            end

            local interpolated = ball.Position + (ball.Velocity * (ping / 2))
            local distance = 3 + (velocity.Magnitude / 5) + (ping * 100)

            if visualizer then
                visualizer.Size = Vector3.one * distance
            end

            if fakeBall then
                fakeBall.Position = interpolated
            end

            if ball:GetAttribute('target') ~= player.Name then
                return
            end
            
            --if (pos - interpolated).Magnitude < distance or (pos - ball.Position).Magnitude < distance then
            if (pos - interpolated).Magnitude < distance then
                keypress(0x46)

                if lastTarget then
                    if isAlive(lastTarget) and os.clock() - targetUpdate < ping then
                        return
                    else
                        lastTarget = nil
                    end
                end
                
                cooldown = tick()

                while ball:GetAttribute('target') == player.Name do
                    if tick() - cooldown > ping * 1.5 then
                        break
                    end

                    task.wait()
                end

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

        if visualizer then
            visualizer.Size = Vector3.one
        end
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
