-- Sprinting builds up (QM, Oct 7): the longer you hold a sprint on the way out, the
-- faster you go, for ever, but slower and slower: 1 + Rate * ln(1 + t / Over) times
-- the sprint (Config.SprintCreep). Letting go, running out of Hold, or the ride ending
-- starts it over. The speed readout and the gates count it (it's live speed); pet
-- nameplates still show the plain sprint.
--
--   SprintCreep.step(dt, on) -> the multiplier this frame (1 when not on)

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local SprintCreep = {}

local held = 0 -- seconds of this sprint
local last = 0 -- os.clock() of the last step (a gap means a new ride)

function SprintCreep.step(dt, on)
	local cfg = Config.SprintCreep
	local now = os.clock()
	if not on or not cfg or now - last > 0.5 then
		held = 0
	end
	last = now
	if not on or not cfg then
		return 1
	end
	held += dt
	return 1 + cfg.Rate * math.log(1 + held / cfg.Over)
end

return SprintCreep
