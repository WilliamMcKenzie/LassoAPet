-- The inventory bar: our own version of the Roblox hotbar (which is turned off),
-- styled after QM's reference. A row of dark see-through squares at the bottom
-- centre, each with its number in the corner, the item's picture fitted inside
-- (never stretched) and "xN" when you have more than one. The equipped one gets
-- a white outline. Click a square or press its number to equip it; again to put
-- it away. On a controller, LB / RB step to the egg before / after (Gamepad).
--
-- The items are the Tools the server puts in your Backpack (eggs, for now: see
-- Hatchery). An item's picture is its TextureId and its count its "Count" attribute.
--
--   Inventory.init(parent) -- builds the bar in a HUD frame (sizes in HUD pixels)
--   Inventory.setVisible(v) -- hidden while riding
--   Inventory.holdBack(kind, n) -- shows n fewer of that egg (n < 0 lets them back: BaseUi's quest egg, till its reveal's done)

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Inventory = {}

local SLOT = 84
local OUTLINE = 2 -- px of black round each egg picture (QM: about the slot number's stroke)
local PANEL = "rbxassetid://86824541929406" -- assets/ui/InventoryBG.png (96 px, grey with a dark border: QM, Oct 11; was CommonPanel.png)
local PANEL_SIZE = 96
local PANEL_CORNER = 18 / 96 -- its corners' radius, of its width (measured from the PNG)
local SCALE = 0.96 -- the whole bar, slots, numbers and outlines alike (QM, Oct 9: 20% smaller, was 1.2)
local GAP = 10
local BOTTOM = GAP * SCALE -- (QM, Oct 9: the same gap under the bar as between its slots, on screen; was 24)
local MAX_SLOTS = 16 -- (more slots as you get more kinds of egg: QM, Oct 14)
local MIN_SLOTS = 8 -- always this many, empty ones too (QM, Oct 14)
local FONT = Enum.Font.FredokaOne

-- Square backgrounds by the item's rarity: QM's slot pictures (the colour is a
-- fallback for a rarity without one).
local RARITY = {
	Common = { color = Color3.fromRGB(150, 160, 175), image = "rbxassetid://137596967858841" }, -- SlotCommon.png
	Uncommon = { color = Color3.fromRGB(70, 170, 60), image = "rbxassetid://120075276423928" }, -- assets/ui/SlotUncommon.png
	Rare = { color = Color3.fromRGB(50, 120, 220), image = "rbxassetid://92909054184182" }, -- assets/ui/SlotRare.png
	Epic = { color = Color3.fromRGB(150, 60, 200), image = "rbxassetid://75096704585668" }, -- assets/ui/SlotEpic.png
	Legendary = { color = Color3.fromRGB(230, 170, 30), image = "rbxassetid://100279863676585" }, -- assets/ui/SlotLegendary.png
}
local Animals = game:GetService("ReplicatedStorage").Shared.Animals
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Gamepad = require(script.Parent.Gamepad)

local function rarityOf(tool)
	local kind = tool:GetAttribute("EggKind")
	local special = kind and Config.SpecialEggs[kind]
	if special then
		kind = special.Pet -- (looks like its pet's egg: the Giant Horse's is a horse egg)
	end
	local module = kind and Animals:FindFirstChild(kind)
	return module and RARITY[require(module).Rarity]
end

local player = Players.LocalPlayer
local bar
local order = {} -- tool names in the order they first showed up, so squares don't jump around
local tools = {} -- what's in each square, left to right

local function stroked(label, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = label
end

local function text(parent, size, textSize, strokeThickness)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = Color3.new(1, 1, 1)
	if strokeThickness then
		stroked(l, strokeThickness)
	end
	l.Parent = parent
	return l
end

local function humanoid()
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function toggle(tool)
	local h = humanoid()
	if not h or not tool then
		return
	end
	if tool.Parent == player.Character then
		h:UnequipTools()
	else
		h:EquipTool(tool)
	end
end

local function allTools()
	local found = {}
	for _, holder in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		for _, child in holder and holder:GetChildren() or {} do
			if child:IsA("Tool") then
				found[child.Name] = child
				if not table.find(order, child.Name) then
					table.insert(order, child.Name)
				end
			end
		end
	end
	return found
end

local heldBack = {} -- [EggKind] = how many of it not to show yet
local function shown(tool)
	return (tool:GetAttribute("Count") or 1) - (heldBack[tool:GetAttribute("EggKind")] or 0)
end

local function redraw()
	if not bar then
		return
	end
	for _, child in bar:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local found = allTools()
	table.clear(tools)
	for _, name in order do
		if found[name] and #tools < MAX_SLOTS and shown(found[name]) > 0 then
			table.insert(tools, found[name])
		end
	end
	for i, tool in tools do
		local slot = Instance.new("TextButton")
		slot.Text = ""
		slot.AutoButtonColor = false
		slot.Size = UDim2.fromOffset(SLOT, SLOT)
		slot.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
		slot.BackgroundTransparency = 0.45
		slot.LayoutOrder = i
		slot.Name = tool.Name
		Instance.new("UICorner", slot).CornerRadius = UDim.new(PANEL_CORNER, 0) -- (the selected ring follows it: the panel's own corners)
		-- Every slot on QM's InventoryBG (Oct 11; CommonPanel from Oct 8): a 9-slice, so its
		-- border and round corners stay crisp at slot size.
		slot.BackgroundTransparency = 1
		local bg = Instance.new("ImageLabel")
		bg.BackgroundTransparency = 1
		bg.Size = UDim2.fromScale(1, 1)
		bg.Image = PANEL
		bg.ScaleType = Enum.ScaleType.Slice
		bg.SliceCenter = Rect.new(24, 24, 72, 72) -- (just past its rounded corners)
		bg.SliceScale = SLOT / PANEL_SIZE -- (the art's proportions at slot size)
		bg.ZIndex = 0 -- (under the egg's outline)
		bg.Parent = slot
		if tool.Parent == player.Character then
			local ring = Instance.new("UIStroke")
			ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ring.Color = Color3.new(1, 1, 1)
			ring.Thickness = 2.5 -- (QM, Oct 8: a bit thinner than 4)
			ring.Parent = slot
		end
		local picture = Instance.new("ImageLabel")
		picture.BackgroundTransparency = 1
		picture.AnchorPoint = Vector2.new(0.5, 0.5)
		picture.Position = UDim2.fromScale(0.5, 0.54)
		picture.Size = UDim2.fromScale(0.72, 0.72)
		picture.Image = tool.TextureId
		picture.ScaleType = Enum.ScaleType.Fit -- keep the picture's own shape
		picture.ZIndex = 2
		picture.Parent = slot
		-- A black outline round the egg (QM, Oct 8; back Oct 11): the same picture in black,
		-- nudged OUTLINE px out in 8 directions behind it (no Highlight: phones).
		for k = 0, 7 do
			local a = k * math.pi / 4
			local shadow = picture:Clone()
			shadow.ImageColor3 = Color3.new(0, 0, 0)
			shadow.ZIndex = 1
			shadow.Position = picture.Position + UDim2.fromOffset(math.round(math.cos(a) * OUTLINE), math.round(math.sin(a) * OUTLINE))
			shadow.Parent = slot
		end
		local number = text(slot, UDim2.fromOffset(24, 24), 20, 2)
		number.Position = UDim2.fromOffset(4, 2)
		number.Text = tostring(i)
		number.ZIndex = 3
		number.Visible = false -- (no slot numbers: QM, Oct 14; the keys 1-8 still work)
		local count = shown(tool)
		if count > 1 then
			local label = text(slot, UDim2.fromScale(1, 1), 34, 3)
			label.Text = "x" .. count
			label.ZIndex = 3
		end
		slot.Activated:Connect(function()
			toggle(tool)
		end)
		-- A controller's buttons: LB and RB either end of the bar, RT on the egg in hand.
		if i == 1 then
			Gamepad.hint(slot, Enum.KeyCode.ButtonL1, Vector2.new(-0.38, 0.5), 44)
		end
		if i == #tools then
			Gamepad.hint(slot, Enum.KeyCode.ButtonR1, Vector2.new(1.38, 0.5), 44)
		end
		if tool.Parent == player.Character then
			Gamepad.hint(slot, Enum.KeyCode.ButtonR2, Vector2.new(0.84, 0.16), 36)
		end
		slot.Parent = bar
	end
	-- The rest of the MIN_SLOTS, empty: just the panel and its number.
	for i = #tools + 1, MIN_SLOTS do
		local slot = Instance.new("Frame")
		slot.Name = "Empty"
		slot.BackgroundTransparency = 1
		slot.Size = UDim2.fromOffset(SLOT, SLOT)
		slot.LayoutOrder = i
		local bg = Instance.new("ImageLabel")
		bg.BackgroundTransparency = 1
		bg.Size = UDim2.fromScale(1, 1)
		bg.Image = PANEL
		bg.ScaleType = Enum.ScaleType.Slice
		bg.SliceCenter = Rect.new(24, 24, 72, 72)
		bg.SliceScale = SLOT / PANEL_SIZE
		bg.ZIndex = 0
		bg.Parent = slot
		local number = text(slot, UDim2.fromOffset(24, 24), 20, 2)
		number.Position = UDim2.fromOffset(4, 2)
		number.Text = tostring(i)
		number.ZIndex = 3
		number.Visible = false -- (no slot numbers: QM, Oct 14; the keys 1-8 still work)
		slot.Parent = bar
	end
end

local watched = {}
local function watch(holder)
	if not holder or watched[holder] then
		return
	end
	watched[holder] = true
	holder.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			child:GetAttributeChangedSignal("Count"):Connect(redraw)
			task.defer(redraw)
		end
	end)
	holder.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(redraw)
		end
	end)
	for _, child in holder:GetChildren() do
		if child:IsA("Tool") then
			child:GetAttributeChangedSignal("Count"):Connect(redraw)
		end
	end
	redraw()
end

function Inventory.init(parent)
	-- The Roblox hotbar stays off (this bar stands in for it). SetCoreGuiEnabled can
	-- fail or be undone just after joining, so it's set again for the first while.
	task.spawn(function()
		for _ = 1, 20 do
			pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)
			task.wait(0.5)
		end
	end)
	bar = Instance.new("Frame")
	bar.Name = "Inventory"
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -BOTTOM)
	bar.Size = UDim2.fromOffset(0, SLOT)
	bar.AutomaticSize = Enum.AutomaticSize.X
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar
	local scale = Instance.new("UIScale")
	scale.Scale = SCALE
	scale.Parent = bar
	bar.Parent = parent
	-- Keep the slot pictures drawn (1 pixel, nearly invisible) so a square never shows up blank.
	for _, rarity in RARITY do
		if rarity.image ~= "" then
			local warm = Instance.new("ImageLabel")
			warm.BackgroundTransparency = 1
			warm.Size = UDim2.fromOffset(1, 1)
			warm.Image = rarity.image
			warm.ImageTransparency = 0.99
			warm.Parent = parent
		end
	end

	watch(player:FindFirstChildOfClass("Backpack"))
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			watch(child)
		end
	end)
	watch(player.Character)
	player.CharacterAdded:Connect(watch)

	local KEYS = {
		Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
		Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
	}
	UserInputService.InputBegan:Connect(function(input, processed)
		local i = table.find(KEYS, input.KeyCode)
		if i and not processed and bar.Visible then
			toggle(tools[i])
		end
	end)
	-- LB / RB: the egg before or after the one in hand (from the first or last
	-- with none); with only one egg, RB takes it out and puts it away.
	local function shown()
		local screen = bar:FindFirstAncestorOfClass("ScreenGui")
		return bar.Visible and #tools > 0 and screen ~= nil and screen.Enabled
	end
	local function step(by)
		local at
		for n, tool in tools do
			if tool.Parent == player.Character then
				at = n
			end
		end
		local n = if at then (at - 1 + by) % #tools + 1 elseif by > 0 then 1 else #tools
		toggle(tools[n])
	end
	Gamepad.bind("EggBefore", Enum.KeyCode.ButtonL1, function()
		step(-1)
	end, shown)
	Gamepad.bind("EggAfter", Enum.KeyCode.ButtonR1, function()
		step(1)
	end, shown)
end

-- The square showing the tool called `name`, while the bar is up (the tutorial
-- points at it).
function Inventory.holdBack(kind, n)
	heldBack[kind] = math.max((heldBack[kind] or 0) + n, 0)
	if heldBack[kind] == 0 then
		heldBack[kind] = nil
	end
	redraw()
end

-- The bar itself (World2Bar sits on top of it).
function Inventory.frame()
	return bar
end

function Inventory.slot(name)
	return bar and bar.Visible and bar:FindFirstChild(name) or nil
end

-- Whether the HUD wants the bar up; Inventory.hideFor keeps it down regardless.
local wanted, hiddenFor = true, {}
local function show()
	if bar then
		bar.Visible = wanted and next(hiddenFor) == nil
	end
end

function Inventory.setVisible(visible)
	wanted = visible
	show()
end

-- Keeps the bar down while `reason` holds (BaseUi's Upgrade button by your bull: QM, Oct 9).
function Inventory.hideFor(reason, hide)
	hiddenFor[reason] = if hide then true else nil
	show()
end

return Inventory
