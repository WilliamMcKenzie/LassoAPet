-- Other riders' bosses (QM, Oct 11): when someone's BOSS IN runs out, everyone sees their
-- boss pop up in front of them and chase them home, as BossChase draws your own. Their
-- client tells the server ("boss" kind x z over RideCue, Riders.server), and it goes
-- when their ride ends ("end"). It follows their character, which their own client moves.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local cfg = Config.Boss
local LONGEST = 90 -- seconds a boss is kept at most (in case its rider's "end" never comes)

local bosses = {} -- [player] = { animal, kind, room, x, z, t, offset }

local function popScale(t) -- 0 -> overshoot -> 1 (BossChase's)
	return 1 - math.exp(-12.6 * t) * math.cos(26 * t)
end

local function remove(player)
	local b = bosses[player]
	if b then
		b.animal.model:Destroy()
		bosses[player] = nil
	end
end

local function spawnFor(player, kind, x, z)
	remove(player)
	local module = ReplicatedStorage.Shared.Bosses:FindFirstChild(kind)
	if not module or typeof(x) ~= "number" or typeof(z) ~= "number" then
		return
	end
	local animal = require(module).new()
	animal.model.Name = "Boss"
	animal.model.PrimaryPart.CFrame = CFrame.new()
	local box, size = animal.model:GetBoundingBox()
	local offset = animal.model.PrimaryPart.Position.Y - (box.Position.Y - size.Y / 2) -- (its root over its feet, at its own size)
	animal.model.Parent = workspace
	local room = cfg.Room[kind] or 0
	bosses[player] = { animal = animal, kind = kind, room = room, x = x, z = z - cfg.Ahead - room, t = 0, offset = offset }
end

ReplicatedStorage:WaitForChild("RideCue").OnClientEvent:Connect(function(player, what, kind, x, z)
	if what == "boss" then
		spawnFor(player, kind, x, z)
	elseif what == "end" then
		remove(player)
	end
end)
Players.PlayerRemoving:Connect(remove)

RunService.Heartbeat:Connect(function(dt)
	for player, b in bosses do
		b.t += dt
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if b.t > LONGEST or not hrp then
			remove(player)
			continue
		end
		local moving = 0
		if b.t >= cfg.CutsceneTime then
			-- After them, never nearer than Behind, pulling up short of the start line.
			-- (at their speed, as yours chases you, from how far their character moved)
			local riderSpeed = if b.lastZ then math.max(hrp.Position.Z - b.lastZ, 0) / math.max(dt, 1e-3) else 0
			local was = b.z
			b.z = math.min(b.z + math.max(riderSpeed, cfg.ChaseMin or 0) * dt, hrp.Position.Z - cfg.Behind - b.room, -cfg.StopShort - b.room)
			b.x += (hrp.Position.X - b.x) * (1 - math.exp(-2 * dt))
			moving = math.max(b.z - was, 0) / math.max(dt, 1e-3)
		end
		b.lastZ = hrp.Position.Z
		local a = b.animal
		a:setScale(math.max(math.floor(popScale(b.t) * 50 + 0.5) / 50, 0.05))
		a.model.PrimaryPart.CFrame = CFrame.new(b.x, b.offset * a.scale, b.z) * CFrame.Angles(0, math.pi, 0)
		a:update(dt, moving, 0)
	end
end)
