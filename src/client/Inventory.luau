-- The inventory bar: our own version of the Roblox hotbar (which is turned off),
-- styled after QM's reference. A row of dark see-through squares at the bottom
-- centre, each with its number in the corner, the item's picture fitted inside
-- (never stretched) and "xN" when you have more than one. The equipped one gets
-- a white outline. Click a square or press its number to equip it; again to put
-- it away.
--
-- The items are the Tools the server puts in your Backpack (eggs, for now: see
-- Hatchery). An item's picture is its TextureId and its count its "Count" attribute.
--
--   Inventory.init(parent) -- builds the bar in a HUD frame (sizes in HUD pixels)
--   Inventory.setVisible(v) -- hidden while riding

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Inventory = {}

local SLOT = 84
local SCALE = 1.2 -- the whole bar, slots, numbers and outlines alike
local GAP = 10
local BOTTOM = 24
local MAX_SLOTS = 9
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
	stroked(l, strokeThickness)
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
		if found[name] and #tools < MAX_SLOTS then
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
		Instance.new("UICorner", slot).CornerRadius = UDim.new(52 / 256, 0) -- the corners of QM's slot pictures (52px on 256)
		local rarity = rarityOf(tool)
		if rarity and rarity.image ~= "" then
			slot.BackgroundTransparency = 1
			local bg = Instance.new("ImageLabel")
			bg.BackgroundTransparency = 1
			bg.Size = UDim2.fromScale(1, 1)
			bg.Image = rarity.image
			bg.Parent = slot
		elseif rarity then
			slot.BackgroundColor3 = rarity.color
			slot.BackgroundTransparency = 0.25
		end
		if tool.Parent == player.Character then
			local ring = Instance.new("UIStroke")
			ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ring.Color = Color3.new(1, 1, 1)
			ring.Thickness = 4
			ring.Parent = slot
		end
		local picture = Instance.new("ImageLabel")
		picture.BackgroundTransparency = 1
		picture.AnchorPoint = Vector2.new(0.5, 0.5)
		picture.Position = UDim2.fromScale(0.5, 0.54)
		picture.Size = UDim2.fromScale(0.72, 0.72)
		picture.Image = tool.TextureId
		picture.ScaleType = Enum.ScaleType.Fit -- keep the picture's own shape
		picture.Parent = slot
		local number = text(slot, UDim2.fromOffset(24, 24), 20, 2)
		number.Position = UDim2.fromOffset(4, 2)
		number.Text = tostring(i)
		local count = tool:GetAttribute("Count") or 1
		if count > 1 then
			local label = text(slot, UDim2.fromScale(1, 1), 34, 3)
			label.Text = "x" .. count
			label.ZIndex = 2
		end
		slot.Activated:Connect(function()
			toggle(tool)
		end)
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
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)
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
end

-- The square showing the tool called `name`, while the bar is up (the tutorial
-- points at it).
function Inventory.slot(name)
	return bar and bar.Visible and bar:FindFirstChild(name) or nil
end

function Inventory.setVisible(visible)
	if bar then
		bar.Visible = visible
	end
end

return Inventory
