-- HOLD ON! (QM, Oct 8: the new core loop): after you lasso an animal you hang off the
-- rope (RopeHang) and have to overpower it. A big HOLD ON! button comes up bottom
-- centre; every tap of it (or Space / A) fills the top bar, which drains all the
-- time. Fill it and you hop on; let it run out and you're BUCKED OFF! (Ride.client
-- decides both from HoldOn.update). Each tap pops "+1" with a flexing arm over you,
-- just like training's (PlusPopup). A big cursor pulses at the button when it comes
-- up, goes once you're tapping, and comes back if you stop for CursorAfter seconds.
-- Config.HoldOn.
--
--   HoldOn.start(character)   -- the phase begins: bar at Start, button up
--   HoldOn.update(dt) -> fill (0..1), "won" | "lost" | nil
--   HoldOn.stop()             -- button and cursor away

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlusPopup = require(script.Parent.PlusPopup)

local CURSOR = "rbxassetid://93240211999923" -- assets/ui/TutorialCursor.png (Tutorial's)
local BUTTON_ASPECT = 960 / 435 -- assets/ui/HoldOn.png
local ACTION = "HoldOnTap"

local HoldOn = {}

local gui, button, buttonScale, cursor, cursorScale
local active = false
local fill = 0
local lastTap = -math.huge
local started = 0
local who -- the character the +1s pop over

local function build()
	local cfg = Config.HoldOn
	gui = Instance.new("ScreenGui")
	gui.Name = "HoldOn"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Enabled = false
	button = Instance.new("ImageButton")
	button.Name = "HoldOn"
	button.BackgroundTransparency = 1
	button.Image = cfg.Image
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -24)
	button.Size = UDim2.fromScale(cfg.Width, cfg.Width / BUTTON_ASPECT)
	button.SizeConstraint = Enum.SizeConstraint.RelativeXX
	buttonScale = Instance.new("UIScale")
	buttonScale.Parent = button
	button.Parent = gui
	cursor = Instance.new("ImageLabel")
	cursor.Name = "Cursor"
	cursor.BackgroundTransparency = 1
	cursor.Image = CURSOR
	cursor.AnchorPoint = Vector2.new(29 / 256, 6 / 256) -- its tip (Tutorial's CURSOR_TIP)
	cursor.Position = UDim2.fromScale(0.82, 0.55) -- on the button's right end
	cursor.SizeConstraint = Enum.SizeConstraint.RelativeYY
	cursor.Size = UDim2.fromScale(1.1, 1.1)
	cursor.ZIndex = 2
	cursorScale = Instance.new("UIScale")
	cursorScale.Parent = cursor
	cursor.Parent = button
	button.Activated:Connect(function()
		HoldOn.tap()
	end)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function HoldOn.tap()
	if not active then
		return
	end
	local cfg = Config.HoldOn
	fill = math.min(fill + cfg.PerTap, 1)
	lastTap = os.clock()
	buttonScale.Scale = 0.92 -- a press, springing back in update
	PlusPopup.at(who, 1, cfg.Arm)
end

function HoldOn.start(character)
	if not gui then
		build()
	end
	who = character
	active, fill, lastTap, started = true, Config.HoldOn.Start, -math.huge, os.clock()
	gui.Enabled = true
	-- Space / A tap it too, over the ability's Space while it's up.
	ContextActionService:BindActionAtPriority(ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			HoldOn.tap()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end

function HoldOn.update(dt)
	if not active then
		return fill, nil
	end
	local cfg = Config.HoldOn
	fill -= cfg.Drain * dt
	-- The cursor: up at the start and whenever you've stopped tapping a while.
	local now = os.clock()
	cursor.Visible = now - lastTap >= cfg.CursorAfter
	local pulse = 0.5 + 0.5 * math.sin((now - started) * math.pi * 2 * 1.6)
	cursorScale.Scale = 1 + 0.15 * pulse
	buttonScale.Scale += ((1 + (if cursor.Visible then 0.05 * pulse else 0)) - buttonScale.Scale) * (1 - math.exp(-18 * dt))
	if fill >= 1 then
		return 1, "won"
	elseif fill <= 0 then
		return 0, "lost"
	end
	return fill, nil
end

function HoldOn.stop()
	if not active then
		return
	end
	active = false
	gui.Enabled = false
	ContextActionService:UnbindAction(ACTION)
end

return HoldOn
