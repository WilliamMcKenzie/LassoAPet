-- The ride home (QM, Oct 13): your pet walks unless you push forward (W or Up, the phone's
-- joystick, a controller's stick, or Sprint), which runs it up to full speed; anything you
-- hit on the way (an animal, an obstacle) drops it back to a walk to build up again. Every
-- second you're not at full speed brings the boss closer (BossChase.closing), and after
-- Config.ReturnRun.CatchAfter of them in all, it catches you. Ride drives it:
--   ReturnRun.reset()                -- a new run home
--   ReturnRun.pushing(controls, stickOn, padPush, sprint) -- whether they're pushing forward
--   ReturnRun.update(dt, atFull)     -- every frame of the run home; .caught once it has you
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Shared.Config)
local BossChase = require(script.Parent.BossChase)
local TutorialRide = require(script.Parent.TutorialRide)

local PUSH = 0.25 -- of a stick's reach that counts as pushing

local ReturnRun = { slow = 0, caught = false }

function ReturnRun.reset()
	ReturnRun.slow, ReturnRun.caught = 0, false
	BossChase.closing = 0
end

function ReturnRun.pushing(controls, stickOn, padPush, sprint)
	if sprint or UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		return true
	end
	return (stickOn and controls:GetMoveVector().Magnitude >= PUSH) or (padPush or 0) >= PUSH
end

-- The first biome a kind runs in (its herd), or nil.
local function biomeOf(kind)
	for i, biome in Config.Biomes do
		if biome.Herd and (biome.Herd[kind] or 0) > 0 then
			return i
		end
	end
	return nil
end

-- Whether a hit on the run home is an animal from a lesser biome than the one you're riding
-- (QM, Oct 13: those you plough through without slowing).
function ReturnRun.lesser(hit, mount)
	local a, b = hit and biomeOf(hit.kind), biomeOf(mount.kind)
	return a ~= nil and b ~= nil and a < b
end

function ReturnRun.update(dt, atFull)
	if not atFull and not TutorialRide.active then -- (the tutorial's slows time instead till you run: Client/Tutorial)
		ReturnRun.slow += dt
	end
	local limit = Config.ReturnRun.CatchAfter
	BossChase.closing = math.clamp(ReturnRun.slow / limit, 0, 1)
	ReturnRun.caught = ReturnRun.slow >= limit
end

return ReturnRun
