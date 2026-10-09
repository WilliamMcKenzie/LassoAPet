-- Buttons grow a tad under the mouse, with a soft tick (QM, Oct 7: to feel more
-- animated). Every ImageButton and TextButton in PlayerGui, from one place: each gets a
-- UIScale (or keeps its own, the press-shrink most buttons already have) tweened to
-- HOVER on MouseEnter and back to 1 on MouseLeave.
--
-- It stays out of the way of anything else that scales a button: a UIScale that isn't
-- at 1 when the mouse comes in (a picked fuse card, a throb) is left alone, a press
-- (0.93) grows back to HOVER on release, and a scale someone else set while hovering
-- isn't undone on leave. SKIP: buttons whose UIScale is driven every frame. Mouse
-- only: on touch a tap would leave it grown.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Sounds = require(script.Parent.Sounds)

local HOVER = 1.08 -- (a button's "Hover" attribute, if it has one, instead: BaseUi's are 1.04, QM Oct 9)
local GROW = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SHRINK = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TICK, TICK_VOLUME = "reveal_tick", 0.15
local TICK_GAP = 0.12 -- seconds: sweeping across a column ticks at most this often
local SKIP = {
	upgradePen = true, -- throbs every frame while you can afford it (Hud)
	lasso = true, -- the ride's action button: TAKE EGG pulses every frame (Hud)
}

local lastTick = 0
local function tick()
	local now = os.clock()
	if now - lastTick >= TICK_GAP then
		lastTick = now
		Sounds.play(TICK, TICK_VOLUME)
	end
end

local hooked = setmetatable({}, { __mode = "k" })
local function hook(button)
	if not (button:IsA("ImageButton") or button:IsA("TextButton")) or hooked[button] or SKIP[button.Name] then
		return
	end
	hooked[button] = true
	local hovering, grown = false, false
	local growing -- our grow tween, while it plays
	local function scaleOf()
		local scale = button:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Parent = button
		end
		return scale
	end
	local function invisible()
		-- the full-screen ones that close a menu when you click off it, and empty hit areas
		return button.Size == UDim2.fromScale(1, 1)
			or (button.BackgroundTransparency >= 1 and (if button:IsA("ImageButton") then button.Image == "" else button.Text == ""))
	end
	button.MouseEnter:Connect(function()
		if not UserInputService.MouseEnabled or invisible() then
			return
		end
		hovering = true
		-- (deferred, so a button's own MouseEnter handling goes first)
		task.defer(function()
			local scale = scaleOf()
			if not hovering or math.abs(scale.Scale - 1) > 0.001 then
				return
			end
			grown = true
			growing = TweenService:Create(scale, GROW, { Scale = button:GetAttribute("Hover") or HOVER })
			growing:Play()
			tick()
		end)
	end)
	button.MouseButton1Up:Connect(function()
		task.defer(function()
			local scale = button:FindFirstChildOfClass("UIScale")
			-- back up from the press (its own handler eases it to 1), unless something else set it
			if hovering and grown and scale and scale.Scale <= 1 then
				growing = TweenService:Create(scale, GROW, { Scale = button:GetAttribute("Hover") or HOVER })
				growing:Play()
			end
		end)
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		if not grown then
			return
		end
		grown = false
		task.defer(function()
			local scale = button:FindFirstChildOfClass("UIScale")
			local ours = growing and growing.PlaybackState == Enum.PlaybackState.Playing
			if scale and (ours or math.abs(scale.Scale - (button:GetAttribute("Hover") or HOVER)) < 0.001) then -- still ours
				TweenService:Create(scale, SHRINK, { Scale = 1 }):Play()
			end
		end)
	end)
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
for _, d in playerGui:GetDescendants() do
	hook(d)
end
playerGui.DescendantAdded:Connect(hook)
