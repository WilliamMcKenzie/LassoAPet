-- The "+120" popups beside the Cash and Luck counters (QM, Nov 7: "copy the other game btw how
-- we increment stats counters": Fight to Steal an Egg's client/GainPopups, 1:1). Each gain pops
-- up just right of the counter's number, then straight away floats up and fades, so the next
-- one has room. Gains that land together (a pen's cash/s tick, a goal's cash) are summed into
-- one popup: the first gain opens a BATCH-second window and everything that lands in it shows
-- as one number. Losses (buying, rebirth) don't pop.
--
-- Each popup is a CanvasGroup (so it fades as one): Amount, the italic number, and the icon
-- after it, outlined the same colour and thickness as the number (HudKit.outlineArt).
-- Popups count from the server's GoldLoaded attribute (Server/Gold), so the saved Gold and
-- LuckBonus arriving on join don't pop up.
--
--   GainPopups.init(row, name, counter, color, band, opts)  -- row: the counter's Frame (NativeHud);
--       counter: its Value; band: its band's Figma y; opts = { attribute, text(amount), min }
--   GainPopups.pulse(name)  -- the counter's icon (Cash's notes, Luck's clover) bounces
--
-- Each popup also pulses the counter's icon: a quick grow and Back settle, from its middle.

local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local HudKit = require(script.Parent.HudKit)
local HudImages = require(script.Parent.HudImages)
local Ui = require(script.Parent.Ui)

local GainPopups = {}

local fig = HudKit.fig
local BATCH = 0.1 -- seconds gains are summed over before their popup shows
local LIFE = 0.7 -- seconds a popup takes to float up and fade
local RISE = 120 -- how far it floats, in Figma px
local POP = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FLOAT = TweenInfo.new(LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local PAD = 8 -- Figma px of room round it in the CanvasGroup, for the outlines
-- the counter's number in QM's Figma when the popup sits where the template does
local REFERENCE = "14K"
-- the icon's pulse on each gain: up to PULSE in PULSE_UP, then a Back settle to 1
local PULSE = 1.2
local PULSE_UP = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PULSE_DOWN = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local player = Players.LocalPlayer
local parts = {} -- [name] = { row, template, counter }

-- the counter's icon (NativeHud > Root > Cash > CashIcon), its Pulse UIScale made on first use;
-- the icon is re-anchored to its middle (same spot on screen) so it grows from the centre
local function pulseScale(name)
	local p = parts[name]
	local icon = p and p.row:FindFirstChild(name .. "Icon")
	if not (icon and icon:IsA("GuiObject")) then
		return nil
	end
	local scale = icon:FindFirstChild("Pulse")
	if not scale then
		local d = Vector2.new(0.5, 0.5) - icon.AnchorPoint
		local size = icon.Size
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position += UDim2.new(size.X.Scale * d.X, size.X.Offset * d.X, size.Y.Scale * d.Y, size.Y.Offset * d.Y)
		scale = Instance.new("UIScale")
		scale.Name = "Pulse"
		scale.Parent = icon
	end
	return scale
end

function GainPopups.pulse(name)
	local scale = pulseScale(name)
	if not scale then
		return
	end
	local up = TweenService:Create(scale, PULSE_UP, { Scale = PULSE })
	up.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed then
			TweenService:Create(scale, PULSE_DOWN, { Scale = 1 }):Play()
		end
	end)
	up:Play()
end

-- the popup in its Figma px (the 25px number, then the 34px icon starting 8px before the
-- number's end), scaled up so the number is the counter's size, 60
local function k(n)
	return fig(n * 60 / 25)
end

local function build(name, band, color)
	local group = Instance.new("CanvasGroup")
	group.BackgroundTransparency = 1
	group.AnchorPoint = Vector2.new(0, 0.5)
	group.Position = UDim2.fromOffset(fig(336) - fig(PAD), fig(band + 36))
	group.Size = UDim2.fromOffset(0, k(34) + 2 * fig(PAD))
	group.AutomaticSize = Enum.AutomaticSize.X
	group.ZIndex = 6
	local pad = Instance.new("UIPadding")
	for _, side in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do
		pad[side] = UDim.new(0, fig(PAD))
	end
	pad.Parent = group
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, -k(8))
	layout.Parent = group
	HudKit.label(group, "Amount", {
		Text = "+120",
		FontFace = HudKit.ITALIC,
		TextSize = k(25),
		TextColor3 = color,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, k(30)),
		LayoutOrder = 1,
		ZIndex = 8, -- (over the icon)
	})
	local holder = Instance.new("Frame")
	holder.Name = "Icon"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(k(34), k(34))
	holder.LayoutOrder = 2
	holder.ZIndex = 7
	holder.Parent = group
	local icon = HudKit.art(holder, name .. "GainIcon", {
		-- (Luck has no gain art of its own: its clover)
		Image = HudImages[name .. "GainIcon"] or HudImages[name .. "Icon"] or "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
	})
	HudKit.outlineArt(icon, HudKit.TEXT_OUTLINE)
	return group
end

-- the counter's number's width at its own font and size (in its unscaled design px)
local function width(counter, text)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = counter.FontFace
	params.Size = counter.TextSize
	params.Width = math.huge
	local ok, size = pcall(TextService.GetTextBoundsAsync, TextService, params)
	return if ok then size.X else 0
end

function GainPopups.init(row, name, counter, color, band, opts)
	local attribute = opts.attribute
	local min = opts.min or 1
	local template = Ui.template(row, "GainTemplate", function()
		return build(name, band, color)
	end)
	if not Ui.live then
		return
	end
	parts[name] = { row = row, template = template, counter = counter }

	local function show(amount)
		GainPopups.pulse(name)
		local popup = Ui.copy(template, "Gain", row)
		popup.Amount.Text = "+" .. opts.text(amount)
		-- (right of the number, however long it's got: the template's spot is for "14K")
		local extra = math.max(0, width(counter, counter.Text) - width(counter, REFERENCE))
		local at = template.Position + UDim2.fromOffset(extra, 0)
		popup.Position = at
		local scale = Instance.new("UIScale")
		scale.Scale = 0.6
		scale.Parent = popup
		TweenService:Create(scale, POP, { Scale = 1 }):Play()
		TweenService:Create(popup, FLOAT, { Position = at - UDim2.fromOffset(0, fig(RISE)) }):Play()
		local fade = TweenService:Create(popup, FADE, { GroupTransparency = 1 })
		fade.Completed:Once(function()
			popup:Destroy()
		end)
		fade:Play()
	end

	local last = nil -- the value popups count from (nil until Server/Gold has GoldLoaded)
	local pending = 0
	local waiting = false
	local function changed()
		local value = player:GetAttribute(attribute) or 0
		if not player:GetAttribute("GoldLoaded") then
			return
		end
		if last == nil then
			last = value
			return
		end
		local gain = value - last
		last = value
		if gain <= 0 then
			return
		end
		pending += gain
		if not waiting then
			waiting = true
			task.delay(BATCH, function()
				waiting = false
				-- (under min it waits for more rather than show +0)
				if pending >= min then
					local sum = pending
					pending = 0
					show(sum)
				end
			end)
		end
	end
	player:GetAttributeChangedSignal(attribute):Connect(changed)
	player:GetAttributeChangedSignal("GoldLoaded"):Connect(changed)
	changed()
end

return GainPopups
