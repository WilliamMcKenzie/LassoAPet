-- Reward popups (QM, Nov 6: "when receiving stuff (cash, eggs, anything like that) should popup
-- same as how cash does here with the pulsing and weld bg (exact same as egg button)"): a
-- square tile on the Eggs button's back, but blue (QM, Nov 7: like his reference's cyan tile;
-- the Index button's blue with the Eggs button's weld texture, bevel and black outline) pops
-- up just above the egg inventory (QM, Nov 7: "a bit closer to the inventory"), the reward's
-- picture on it and its
-- amount written over the bottom, a white glow round it pulsing. After HOLD seconds it fades
-- away. Rewards that land while others are still up sit beside them in a row (QM: "multiple
-- stuff can turn into a row"). Eggs show here straight away, no RNG card (QM, Nov 6).
--
--   RewardPopups.show(image, text)   -- image: an asset id; text: "$450K", "x1"
--   RewardPopups.watchCash(money)    -- pops the gold you're given (not the pets' per-second
--                                    -- pay, which ticks by the counter); money: Hud's "$1.2k"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HudKit = require(script.Parent.HudKit)
local HudImages = require(script.Parent.HudImages)
local NativeHud = require(script.Parent.NativeHud)
local Inventory = require(script.Parent.Inventory)

local RewardPopups = {}

local fig = HudKit.fig
local TILE = 260 -- the tile's side (Figma px; the Eggs button's is 128)
local GLOW = 36 -- the glow's reach past the tile all round (Figma px)
local GAP = 24 -- between tiles in a row (Figma px)
local BOTTOM = 200 -- the row's bottom edge above the screen's while the inventory's hidden (Figma px)
local ABOVE = 10 -- the row's bottom edge above the inventory's top (Figma px; the glow fills most of it)
local HOLD = 2 -- seconds a tile stays before it fades
local LOOK = { -- the Blue button's colours on the Red one's weld (client/HudKit.LOOKS)
	top = HudKit.LOOKS.Blue.top,
	bottom = HudKit.LOOKS.Blue.bottom,
	bevel = HudKit.LOOKS.Red.bevel,
	base = HudKit.LOOKS.Red.base,
	tile = HudKit.LOOKS.Red.tile,
}
local POP = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local PULSE = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local BATCH = 0.1 -- seconds gold gains are summed over before their tile shows

local row -- the Frame the tiles line up in, made on first use
local function getRow()
	if row and row.Parent then
		return row
	end
	row = Instance.new("Frame")
	row.Name = "Rewards"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -fig(BOTTOM))
	row.Size = UDim2.new(1, 0, 0, fig(TILE + 2 * GLOW))
	row.ZIndex = 20
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, fig(GAP) - 2 * fig(GLOW)) -- (the glows overlap, the tiles don't)
	layout.Parent = row
	row.Parent = NativeHud.popupRoot()
	return row
end

-- the row just above the inventory (or BOTTOM up, while it's hidden): its top in screen px
-- into the popup root's design px (its Fit UIScale)
local function place(r)
	local root = r.Parent
	local fit = root and root:FindFirstChild("Fit")
	local top = Inventory.top()
	if top and fit and fit.Scale > 0 then
		r.Position = UDim2.new(0.5, 0, 0, (top - root.AbsolutePosition.Y) / fit.Scale - fig(ABOVE))
	else
		r.Position = UDim2.new(0.5, 0, 1, -fig(BOTTOM))
	end
end

local order = 0
function RewardPopups.show(image, text)
	local side, glow = fig(TILE), fig(GLOW)
	order += 1
	-- (a CanvasGroup, so the tile, its outline and the glow fade as one)
	local group = Instance.new("CanvasGroup")
	group.Name = "Reward"
	group.BackgroundTransparency = 1
	group.Size = UDim2.fromOffset(side + 2 * glow, side + 2 * glow)
	group.LayoutOrder = order
	group.GroupTransparency = 0
	local pop = Instance.new("UIScale")
	pop.Scale = 0.5
	pop.Parent = group

	-- the pulse: the glow and the tile in it breathe together
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = group
	local pulse = Instance.new("UIScale")
	pulse.Parent = holder

	-- the glow: two white squares round the tile, the outer one fainter
	local glows = {}
	for i, reach in { glow, math.round(glow / 2) } do
		local g = Instance.new("Frame")
		g.Name = "Glow" .. i
		g.BorderSizePixel = 0
		g.BackgroundColor3 = Color3.new(1, 1, 1)
		g.BackgroundTransparency = if i == 1 then 0.8 else 0.6
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Position = UDim2.fromScale(0.5, 0.5)
		g.Size = UDim2.fromOffset(side + 2 * reach, side + 2 * reach)
		g.ZIndex = i
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, fig(12))
		c.Parent = g
		g.Parent = holder
		glows[i] = g
	end

	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.BackgroundTransparency = 1
	tile.AnchorPoint = Vector2.new(0.5, 0.5)
	tile.Position = UDim2.fromScale(0.5, 0.5)
	tile.Size = UDim2.fromOffset(side, side)
	tile.ZIndex = 3
	tile.Parent = holder
	HudKit.back(tile, LOOK, { ZIndex = 3 })
	local pic = Instance.new("ImageLabel")
	pic.Name = "Icon"
	pic.BackgroundTransparency = 1
	pic.Image = image or ""
	pic.ScaleType = Enum.ScaleType.Fit
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	pic.Position = UDim2.fromScale(0.5, 0.42)
	pic.Size = UDim2.fromScale(0.78, 0.78)
	pic.ZIndex = 4
	pic.Parent = tile
	local amount = HudKit.label(tile, "Amount", {
		Text = text or "",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -fig(10)),
		Size = UDim2.new(1, -fig(20), 0, fig(80)),
		ZIndex = 5,
	})
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = fig(70)
	cap.Parent = amount

	local r = getRow()
	place(r)
	group.Parent = r
	TweenService:Create(pop, POP, { Scale = 1 }):Play()
	local breathe = TweenService:Create(pulse, PULSE, { Scale = 1.06 })
	breathe:Play()
	TweenService:Create(glows[1], PULSE, { BackgroundTransparency = 0.95 }):Play()
	TweenService:Create(glows[2], PULSE, { BackgroundTransparency = 0.8 }):Play()
	task.delay(HOLD, function()
		local fade = TweenService:Create(group, FADE, { GroupTransparency = 1 })
		fade.Completed:Once(function()
			breathe:Cancel()
			group:Destroy()
		end)
		fade:Play()
	end)
end

-- Gold gains as tiles. The pets' pay (PetIncome, every second) is taken back out: it lands in
-- the same BATCH window as its gold, whichever arrives first. Counts from GoldLoaded
-- (Server/Gold), so the saved gold arriving on join doesn't pop.
function RewardPopups.watchCash(money)
	local player = Players.LocalPlayer
	local last = nil
	local gained, paid, waiting = 0, 0, false
	local function flush()
		waiting = false
		local sum = gained - paid
		gained, paid = 0, 0
		if sum >= 1 then
			RewardPopups.show(HudImages.CashStack, money(sum))
		end
	end
	local function wait()
		if not waiting then
			waiting = true
			task.delay(BATCH, flush)
		end
	end
	local function changed()
		local value = player:GetAttribute("Gold") or 0
		if not player:GetAttribute("GoldLoaded") then
			return
		end
		if last == nil then
			last = value
			return
		end
		local gain = value - last
		last = value
		if gain > 0 then
			gained += gain
			wait()
		end
	end
	ReplicatedStorage:WaitForChild("PetIncome").OnClientEvent:Connect(function(earned)
		if type(earned) == "number" and earned > 0 and last ~= nil then
			paid += earned
			wait()
		end
	end)
	player:GetAttributeChangedSignal("Gold"):Connect(changed)
	player:GetAttributeChangedSignal("GoldLoaded"):Connect(changed)
	changed()
end

return RewardPopups
