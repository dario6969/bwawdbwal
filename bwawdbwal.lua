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

    local function autoParry()
        if not root.Parent then
            return
        end

        local pos = root.Position

        local ping = game.Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000

        for _, ball in workspace.Balls:GetChildren() do
            if not (ball:GetAttribute('realBall') and ball:GetAttribute('target') == player.Name) then
                continue
            end

            local interpolated = ball.Position + (ball.Velocity * ping)
            local distance = 8 + (math.min(ball.Velocity.Magnitude / 1000, 1) * 100) + (ping * 100)

            if (pos - interpolated).Magnitude < distance or (pos - ball.Position).Magnitude < distance then
                keypress(0x46)

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
