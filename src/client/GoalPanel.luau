-- The Goal panel, top left (Fight to Steal an Egg's, QM Nov 6: "replace quest with goal").
-- A little orange "Goal", the goal's title under it ("Reach Desert") and a lime bar towards
-- it with "1/3" across it. The goal is one of your quests (Server/Quests, the "Quests"
-- attribute; BaseUi picks which: one ready to claim first, else the first line's). Once it's
-- done a green "Claim!" button takes the bar's place; claiming pulses the panel out with
-- "Done!", swaps to the next goal while it's big and settles back. Tapping the title shows
-- how to do it (BaseUi's quest hints). Laid out in design px (1080 tall: NativeHud's Root).
-- "Upgrade slingshot" (QM, Nov 7) is money: its bar is your cash towards the next biome's
-- unlock ("$40k/$100k"), and once you have it a "Buy!" takes the bar's place, which opens
-- the Slingshot's menu on that biome (Client/SlingshotMenu, its cursor on the buy button).
-- Buying it there moves the goal on (Server/Quests' publish), with the same "Done!" pulse.
--
--   local goal = GoalPanel.init(root, { claim = function(i) end, hint = function(quest) end })
--   goal.set(quest or nil)   -- the quest to show ({ i, text, have, need, ... }); nil hides it
--   goal.claimButton         -- (BaseUi puts the starter quest's tap hand on it)
--   goal.panel

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HudKit = require(script.Parent.HudKit)
local UiFx = require(script.Parent.UiFx)
local Ui = require(script.Parent.Ui)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local GoalPanel = {}
local player = Players.LocalPlayer

-- a slingshot goal as cash towards its biome's price (the rest as the server sent it)
local function money(q)
	if not (q and q.kind == "slingshot" and q.biome) then
		return q
	end
	local m = table.clone(q)
	m.need = math.max(Config.unlockCost(player, q.biome), 1)
	m.have = math.min(player:GetAttribute("Gold") or 0, m.need)
	m.money = true
	return m
end

local TOP = 150 -- design px from the screen's top (under Roblox's buttons)
local W, H = 420, 160
local BAR_X, BAR_Y, BAR_W, BAR_H = 18, 94, 340, 52
local CLAIM_W, CLAIM_H = 340, 60
local EASE = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_UP = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_DOWN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP = 1.15
local DONE_FILL = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SIZE = 0.85 -- the whole panel's scale (QM, Nov 6: 15% smaller)
-- claimed (QM, Nov 6: a pop and swap, not held): a quick squash in (anticipation), out past
-- full size, the next goal swapped in at the peak, then a springy settle back (overshoot)
local SQUASH, SQUASH_IN = 0.9, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PULSE, PULSE_OUT = 1.2, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PULSE_BACK = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLAIM_THROB = 0.05 -- the Claim button breathes this much

function GoalPanel.init(root, handlers)
	local label = HudKit.label
	local panel, fresh = Ui.make(root, "Goal", "Frame")
	if fresh then
		panel.BackgroundTransparency = 1
		panel.Position = UDim2.fromOffset(0, TOP)
		panel.Size = UDim2.fromOffset(W, H)
		panel.Visible = false
	end

	-- a black band behind it, fading out to the right (like the counters')
	local band
	band, fresh = Ui.make(panel, "Band", "Frame")
	if fresh then
		band.BackgroundColor3 = HudKit.BLACK
		band.BorderSizePixel = 0
		band.Size = UDim2.fromScale(1, 1)
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(0.54, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		})
		fade.Parent = band
	end

	local small = label(panel, "Label", {
		Text = "Goal",
		TextColor3 = Config.NativeUi.GoalColor,
		TextSize = 32,
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.fromOffset(200, 34),
		ZIndex = 2,
	})
	small.Outline.Thickness = 3

	local title = label(panel, "Title", {
		Text = "",
		TextSize = 46,
		TextScaled = true,
		Position = UDim2.fromOffset(16, 38),
		Size = UDim2.fromOffset(W - 24, 50),
		ZIndex = 2,
	})
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 46 -- (a long title shrinks to fit instead)
	cap.Parent = title

	local track = HudKit.back(panel, "GoalTrack", {
		Name = "Track",
		Position = UDim2.fromOffset(BAR_X, BAR_Y),
		Size = UDim2.fromOffset(BAR_W, BAR_H),
		ZIndex = 2,
	})
	local clip
	clip, fresh = Ui.make(track, "Clip", "Frame")
	if fresh then
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Size = UDim2.fromScale(0, 1)
		clip.ZIndex = 3
	end
	-- (the lime keeps the whole track's size, so it's cut, not squashed)
	HudKit.back(clip, "GoalFill", { Name = "Fill", Size = UDim2.fromOffset(BAR_W, BAR_H), ZIndex = 3 })
	local progress = label(track, "Progress", {
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 38,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	})

	-- the whole panel: tap it for the goal's hint (under the Claim button)
	local tap = Ui.make(panel, "Hint", "TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
	})

	-- Claim! in the bar's place once the goal's done (in a holder that breathes, so the
	-- button's own UIScale stays its hover and press)
	local holder
	holder, fresh = Ui.make(panel, "ClaimHolder", "Frame")
	if fresh then
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromOffset(BAR_X + BAR_W / 2, BAR_Y + BAR_H / 2)
		holder.Size = UDim2.fromOffset(CLAIM_W, CLAIM_H)
		holder.ZIndex = 7
		holder.Visible = false
	end
	local throb = Ui.make(holder, "Throb", "UIScale")
	local claim = Ui.make(holder, "Claim", "ImageButton", {
		BackgroundTransparency = 1,
		Image = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 7,
	})
	HudKit.back(claim, "Green", { ZIndex = 7 })
	Ui.make(claim, "Hover", "UIScale")
	HudKit.hover(claim)
	local claimText = label(claim, "Text", {
		Text = "Claim!",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 44,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
	})

	local grow = Ui.make(panel, "Pop", "UIScale")
	grow.Scale = SIZE
	local api = { panel = panel, claimButton = claim }
	local current -- the quest up
	local lastFraction
	local busy = false -- (mid completion pulse: set leaves the panel alone)
	local pending -- (the quest set while busy: shown once it's over)
	local claimed -- the i of the quest last claimed from here

	local function pop()
		local up = TweenService:Create(grow, POP_UP, { Scale = POP * SIZE })
		up.Completed:Connect(function(how)
			if how == Enum.PlaybackState.Completed then
				TweenService:Create(grow, POP_DOWN, { Scale = SIZE }):Play()
			end
		end)
		up:Play()
	end

	-- show a quest's title, count and bar (fresh: the bar fills up from empty)
	local function show(q, fresh)
		local fraction = if q.need > 0 then math.clamp(q.have / q.need, 0, 1) else 1
		local done = q.have >= q.need
		title.Text = q.text
		progress.Text = if q.money
			then "$" .. Config.short(q.have) .. "/$" .. Config.short(q.need)
			else string.format("%d/%d", q.have, q.need)
		claimText.Text = if q.money then "Buy!" elseif q.kind == "rebirth" then "Rebirth!" else "Claim!" -- (QM, Nov 7)
		if fraction ~= lastFraction or fresh then
			if fresh then
				clip.Size = UDim2.fromScale(0, 1)
			end
			TweenService:Create(clip, EASE, { Size = UDim2.fromScale(fraction, 1) }):Play()
		end
		lastFraction = fraction
		track.Visible = not done
		holder.Visible = done
		tap.Visible = not done
	end

	-- the goal's claimed: the bar fills with "Done!", the panel squashes in, pops out, swaps to
	-- the next goal at the peak and springs back
	local function complete()
		busy = true
		UiFx.play("Claim")
		holder.Visible = false
		track.Visible = true
		TweenService:Create(clip, DONE_FILL, { Size = UDim2.fromScale(1, 1) }):Play()
		progress.Text = "Done!"
		local squash = TweenService:Create(grow, SQUASH_IN, { Scale = SQUASH * SIZE })
		squash:Play()
		squash.Completed:Wait()
		local out = TweenService:Create(grow, PULSE_OUT, { Scale = PULSE * SIZE })
		out:Play()
		out.Completed:Wait()
		busy = false
		local q = pending
		pending = nil
		current = nil
		api.set(q, true)
		TweenService:Create(grow, PULSE_BACK, { Scale = SIZE }):Play()
	end

	function api.set(q, settling)
		q = money(q)
		if busy then
			pending = q
			return
		end
		if not q then
			current = nil
			panel.Visible = false
			return
		end
		local was = current
		current = q
		panel.Visible = true
		if was and was.i ~= q.i and claimed == was.i then
			-- (the one up was claimed: Done! first, then this)
			pending = q
			task.spawn(complete)
			return
		end
		local swapped = was and was.i ~= q.i
		local becameDone = was and was.have < was.need and q.have >= q.need
		show(q, was == nil or swapped)
		if (becameDone or swapped) and not settling then
			pop()
			UiFx.play("Claim")
		end
	end

	claim.Activated:Connect(function()
		if current and not busy then
			claimed = current.i
			if current.money then
				-- (Buy!: the Slingshot's menu on its biome; buying there moves the goal on.
				-- Required here, not above: SlingshotMenu needs NativeHud, which needs this)
				require(script.Parent.SlingshotMenu).open(nil, current.biome)
			else
				handlers.claim(current.i)
			end
		end
	end)
	-- (a slingshot goal's bar follows your cash, and its price after a rebirth)
	for _, name in { "Gold", "Reborn" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			if current and current.money and not busy then
				api.set(current)
			end
		end)
	end
	tap.Activated:Connect(function()
		if current and not busy then
			handlers.hint(current)
		end
	end)

	task.spawn(function()
		while panel.Parent do
			throb.Scale = 1 + CLAIM_THROB * math.sin(os.clock() * 5)
			task.wait()
		end
	end)
	return api
end

return GoalPanel
