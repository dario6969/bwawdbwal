local RunService = game:GetService('RunService')

local player = game.Players.LocalPlayer

local function clearCons()
    for _, con in shared.Connections do
        con:Disconnect()
    end

    table.clear(shared.Connections)

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

    local lastTarget
    local lastClash

    local function clash(ball)
        if tick() - (lastClash or 0) > 0.25 then
            lastClash = 0
            lastTarget = nil

            return
        end

        if not (lastTarget and isAlive(lastTarget)) then
            return
        end

        local targetRoot = lastTarget:FindFirstChild('HumanoidRootPart')

        if not targetRoot then
            return
        end

        local maxDistance = math.clamp(ball.Velocity.Magnitude / 3, 6, 26)

        if (targetRoot.Position - root.Position).Magnitude < maxDistance then
            lastClash = tick()

            return true
        end
    end

    local function setLastTarget(ball)
        local targetName = ball:GetAttribute('target')
        local target = targetName and workspace.Alive:FindFirstChild(targetName)

        if not target or target == player.Name or not isAlive(target) then
            lastTarget = nil

            return
        end

        lastTarget = target
    end

    local function autoParry()
        if not root.Parent then
            return
        end

        if cooldown then
            return
        end

        local pos = root.Position

        local ping = game.Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000

        for _, ball in workspace.Balls:GetChildren() do
            if not (ball:GetAttribute('realBall') and ball:GetAttribute('target') == player.Name) then
                continue
            end

            local interpolated = ball.Position + (ball.Velocity * (ping * 1.4))
            local distance = 13 + (math.min(ball.Velocity.Magnitude / 600, 1) * 57)

            if lastTarget and isAlive(lastTarget) and tick() - (lastClash or 0) < ping * 2 and (root.Position - lastTarget.PrimaryPart.Position).Magnitude < 50 then
                distance *= 1.33
            end

            if (pos - interpolated).Magnitude < distance or (pos - ball.Position).Magnitude < distance then
                keypress(0x46)
                mouse1click()

                if clash(ball) then
                    return
                end
                
                cooldown = tick()

                while ball:GetAttribute('target') == player.Name or tick() - cooldown < ping * 3 do
                    task.wait()
                end

                cooldown = false

                setLastTarget(ball)

                break
            end
        end
    end

    table.insert(shared.Connections, RunService.PostSimulation:Connect(autoParry))
    table.insert(shared.Connections, RunService.PreSimulation:Connect(autoParry))
end

player.CharacterAdded:Connect(init)

if player.Character then
    init(player.Character)
end
