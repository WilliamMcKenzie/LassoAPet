-- Riding into a locked gate with speed gates on (Shared/SpeedGates): on one of
-- your own pets that's fast enough, it shatters where it stands (Gate.client) and
-- you ride on through; the server checks it again and opens the biome for good
-- (BreakGate, PenLevel.server). Ride.client counts `GateSmash.level` as unlocked
-- straight away, so there's no wait for the server.
--
--   GateSmash.hit(mount)  at a locked gate: true if it broke
--   GateSmash.tip()       the crash screen's tip there ("NEED 28 m/s"), or nil

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.SpeedGates)

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("BreakGate")

local GateSmash = {}
GateSmash.level = nil -- the level broken this session that the server may not have confirmed yet
GateSmash.smashed = Instance.new("BindableEvent") -- (i, x, speed): shatter gate i now (Gate.client)
GateSmash.rejected = Instance.new("BindableEvent") -- the server said no: put the gates back (Gate.client)

local function nextGate()
	return math.max(Rules.level(player), GateSmash.level or 1) + 1
end

function GateSmash.hit(mount)
	if not Rules.on() or not mount or not mount.own then
		return false -- wild animals never break gates
	end
	local i = nextGate()
	local need = Rules.need(i)
	if not need or Rules.mps(mount.kind, mount.fuse, mount.stats) < need then
		return false
	end
	GateSmash.level = i
	GateSmash.smashed:Fire(i, mount.x, mount.speed) -- (it breaks round where you hit it, flung on at your speed: GlassShatter)
	task.spawn(function()
		local ok, yes = pcall(remote.InvokeServer, remote, i)
		if not (ok and yes) and GateSmash.level and GateSmash.level >= i then
			GateSmash.level = if i > 2 then i - 1 else nil
			GateSmash.rejected:Fire()
		end
	end)
	return true
end

function GateSmash.tip()
	local need = Rules.on() and Rules.need(nextGate())
	return if need then "NEED " .. need .. " m/s" else nil
end

return GateSmash
