-- Riding into a locked gate with speed gates on (Shared/SpeedGates): on one of
-- your own pets that's fast enough, it shatters where it stands (Gate.client) and
-- you ride on through; the server checks it again and opens the biome for good
-- (BreakGate, PenLevel.server). Ride.client counts `GateSmash.level` as unlocked
-- straight away, so there's no wait for the server.
--
--   GateSmash.hit(mount, speed)  at a locked gate, at `speed` studs/s: true if it broke
--   GateSmash.tip()       the crash screen's tip there ("NEED 15 mph"), or nil

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

GateSmash.allow = nil -- function(i): false holds gate i shut for now (the tutorial, till its gate step)
GateSmash.mph = Rules.mph

-- speed: the live studs/s you're running at, uncurved (QM, Oct 7 21:14: sprints count).
function GateSmash.hit(mount, speed)
	local i = nextGate()
	if not Rules.on() or not mount or not (mount.own or Rules.anyAnimal(i)) then
		return false -- wild animals only break the Desert's
	end
	local need = Rules.need(i)
	if not need or Rules.mph(speed or 0) < need or (GateSmash.allow and not GateSmash.allow(i)) then
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
	return if need then "NEED " .. need .. " mph" else nil
end

return GateSmash
