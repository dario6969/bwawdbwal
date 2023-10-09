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

local function init(character)
    clearCons()

    local humanoid = character:WaitForChild('Humanoid')
    local root = character:WaitForChild('HumanoidRootPart')

    humanoid.Died:Once(clearCons)

    local cooldown = false

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

            local interpolated = ball.Position + (ball.Velocity * (ping * 1.35))
            local distance = 13 + (math.min(ball.Velocity.Magnitude / 600, 1) * 56)

            if (pos - interpolated).Magnitude < distance or (pos - ball.Position).Magnitude < distance then
                keypress(0x46)

                cooldown = tick()

                while ball:GetAttribute('target') == player.Name or tick() - cooldown < ping * 3 do
                    task.wait()
                end

                cooldown = false

                break
            end
        end
    end

    table.insert(shared.Connections, RunService.PostSimulation:Connect(autoParry))
end

player.CharacterAdded:Connect(init)

if player.Character then
    init(player.Character)
end
