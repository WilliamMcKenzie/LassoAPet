-- HOLD ON! (QM, Oct 8: the new core loop): after you lasso an animal you hang off the
-- rope (RopeHang) and have to overpower it. Everything leaves the screen but the top
-- bar (Hud.setStruggle), and a tap anywhere on it (or a click, Space, A) fills the
-- bar, which drains all the time. Fill it and you hop on; let it run out and you
-- crash (Ride.client decides both from HoldOn.update). Config.HoldOn.
--
--   HoldOn.start(character, yourLevel, itsLevel) -- the struggle begins: bar at Start
--   HoldOn.update(dt) -> fill (0..1), "won" | "lost" | nil
--   HoldOn.stop()                                -- the screen comes back

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlusPopup = require(script.Parent.PlusPopup)
local Hud = require(script.Parent.Hud)

local ACTION = "HoldOnTap"

local HoldOn = {}

local active = false
local fill = 0
local who -- the character the +1s pop over
local perTap, drain = 0, 0 -- this time's (Config.HoldOn: your lasso level against its)
local goAt = 0 -- os.clock() "Ready... Set..." is over: the bar holds and taps don't count till then

function HoldOn.tap()
	if not active or os.clock() < goAt then
		return
	end
	local cfg = Config.HoldOn
	fill = math.min(fill + perTap, 1)
	if cfg.Popup then
		PlusPopup.at(who, 1, cfg.Arm, PlusPopup.SCATTER)
	end
end

function HoldOn.start(character, yours, its)
	who = character
	local cfg = Config.HoldOn
	local ratio = if its and its > 0 then math.max(yours or 0, 1) / its else 1
	perTap = math.min(cfg.PerTap * ratio, cfg.MaxTap)
	drain = cfg.PerTap * cfg.DrawTaps
	active, fill = true, cfg.Start
	goAt = os.clock() + cfg.Ready.Time + cfg.Set.Time
	Hud.setStruggle(true)
	-- A tap or click anywhere, Space or A: over everything else's while it's on.
	ContextActionService:BindActionAtPriority(ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			HoldOn.tap()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 10, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch,
		Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end

function HoldOn.update(dt)
	if not active then
		return fill, nil
	end
	-- (full is checked before this frame's drain: a tap caps it at exactly 1, and
	-- draining first took it straight back under, so it could never be won)
	if fill >= 1 then
		return 1, "won"
	end
	if os.clock() < goAt then
		return fill, nil -- (Ready... Set...)
	end
	fill -= drain * dt
	if fill <= 0 then
		return 0, "lost"
	end
	return fill, nil
end

function HoldOn.stop()
	if not active then
		return
	end
	active = false
	ContextActionService:UnbindAction(ACTION)
	Hud.setStruggle(false)
end

return HoldOn
