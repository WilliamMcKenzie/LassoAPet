-- How the menus pop in and out (QM, Oct 4): the roll menu, the animal dictionary and
-- the shop. Opening, the menu bounces in from a little small (Back out). Closing, it
-- swells a touch first (anticipation), then pulls back and shrinks away (Back in),
-- and only then does the menu hide. Each menu passes its own apply(scale), which
-- sets its size from the scale given (1 = its normal size).
--
--   ModalPop.open(apply)
--   ModalPop.close(apply, done)   -- done() once it's shrunk away (not if reopened first)

local TweenService = game:GetService("TweenService")

local ModalPop = {}

local OPEN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SWELL = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SHRINK = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local FROM = 0.85 -- opening starts this small
local PEAK = 1.06 -- closing swells to this first
local TO = 0.4 -- and shrinks to this as it hides

local values = {} -- [apply] = the NumberValue tweened for it
local runs = {} -- [apply] = counts up each open/close, so an older one stops

local function valueFor(apply)
	local value = values[apply]
	if not value then
		value = Instance.new("NumberValue")
		value.Value = 1
		value.Changed:Connect(apply)
		values[apply] = value
	end
	runs[apply] = (runs[apply] or 0) + 1
	return value, runs[apply]
end

function ModalPop.open(apply)
	local value = valueFor(apply)
	value.Value = FROM
	TweenService:Create(value, OPEN, { Value = 1 }):Play()
end

function ModalPop.close(apply, done)
	local value, run = valueFor(apply)
	local swell = TweenService:Create(value, SWELL, { Value = PEAK })
	swell.Completed:Connect(function()
		if runs[apply] ~= run then
			return
		end
		local shrink = TweenService:Create(value, SHRINK, { Value = TO })
		shrink.Completed:Connect(function()
			if runs[apply] == run then
				done()
			end
		end)
		shrink:Play()
	end)
	swell:Play()
end

return ModalPop
