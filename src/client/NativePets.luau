-- The Pets popup in the native UI (Config.NativeUi, QM Nov 6): Fight to Steal an Egg's Active
-- Pets (its client/PetsPanel, 1:1 in look), sliding in on the right (client/SidePanel). A gold
-- header with "5 Active", and a row per pet you have: its headshot (PetFaces), its name, its
-- cash a second, and Riding (yellow: the one at your pen's gap, that a ride sets off on),
-- Unequip (red: the pen's other pets, out to storage) or Equip (green: a stored one, back in).
-- Equip and Unequip are Hatchery's EquipPet / UnequipPet. Client/PetsPanel hands its toggle,
-- close and isOpen to this while the native UI's on.
--
--   NativePets.toggle() / NativePets.close() / NativePets.isOpen()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local PetFaces = require(script.Parent.PetFaces)
local SidePanel = require(script.Parent.SidePanel)
local Ui = require(script.Parent.Ui)
local UiFx = require(script.Parent.UiFx)

local NativePets = {}

local player = Players.LocalPlayer
local fig, label, button = HudKit.fig, HudKit.label, HudKit.button
local function hex(h)
	return Color3.fromHex(h)
end
local OUTLINES = { -- text outlines (QM's Figma)
	Title = hex("8a3a00"),
	Cash = hex("0a5a00"),
	Unequip = hex("7a0000"),
	Equip = hex("006b10"),
	Riding = hex("8a5a00"),
}
local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Exclusive" }

local panel, template

local function decode(text)
	local ok, t = pcall(HttpService.JSONDecode, HttpService, text or "{}")
	return if ok and typeof(t) == "table" then t else {}
end

-- an animal's name and rarity's place, from its module
local info = {}
local function about(kind)
	if not info[kind] then
		local module = ReplicatedStorage.Shared.Animals:FindFirstChild(kind)
		local ok, class = pcall(require, module)
		local name = ok and typeof(class) == "table" and class.Name
		info[kind] = {
			name = if type(name) == "string" then name else (kind:gsub("(%l)(%u)", "%1 %2")),
			rank = ok and typeof(class) == "table" and table.find(RARITIES, class.Rarity) or 0,
		}
	end
	return info[kind]
end

local function myPen()
	local pens = workspace:FindFirstChild("Pens")
	return pens and pens:FindFirstChild("Pen" .. tostring(player:GetAttribute("Pen")))
end

-- every pet you have: { id, kind, equipped, riding, income }, rarest first, then by income
local function pets()
	local out = {}
	local pen = myPen()
	for id, item in decode(pen and pen:GetAttribute("Contents")) do
		if typeof(item) == "table" and item.pet then
			table.insert(out, { id = id, kind = item.pet, equipped = true, income = tonumber(item.income) })
		end
	end
	local ride = player:GetAttribute("RidePet")
	if typeof(ride) == "string" and ride ~= "" then
		table.insert(out, { id = "ride", kind = ride, equipped = true, riding = true })
	end
	for id, item in decode(player:GetAttribute("StoredPets")) do
		if typeof(item) == "table" and item.pet then
			table.insert(out, { id = id, kind = item.pet, equipped = false, income = tonumber(item.income) })
		end
	end
	for _, pet in out do
		pet.income = pet.income or Config.PetIncome[pet.kind] or 0
	end
	table.sort(out, function(a, b)
		if a.riding ~= b.riding then
			return a.riding == true
		end
		local ra, rb = about(a.kind).rank, about(b.kind).rank
		if ra ~= rb then
			return ra > rb
		end
		if a.income ~= b.income then
			return a.income > b.income
		end
		return a.id < b.id
	end)
	return out
end

-- a row (QM's Figma Card: 876 x 207)
local function rowTemplate()
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(fig(876), fig(207))
	HudKit.back(row, "PetCard", {})
	local picture = Instance.new("ImageLabel")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1
	picture.ScaleType = Enum.ScaleType.Fit
	picture.Position = UDim2.fromOffset(fig(13), fig(15))
	picture.Size = UDim2.fromOffset(fig(177), fig(177))
	picture.ZIndex = 2
	picture.Parent = row
	label(row, "PetName", {
		Text = "Horse",
		TextSize = fig(50),
		Position = UDim2.fromOffset(fig(252), fig(28)),
		Size = UDim2.fromOffset(fig(300), fig(61)),
		ZIndex = 2,
	})
	local cash = label(row, "PetCash", {
		Text = "($100/s)",
		FontFace = HudKit.ITALIC,
		TextColor3 = Color3.fromRGB(0, 255, 0),
		TextSize = fig(40),
		Position = UDim2.fromOffset(fig(243), fig(91)),
		Size = UDim2.fromOffset(fig(300), fig(49)),
		ZIndex = 2,
	})
	cash.Outline.Color = OUTLINES.Cash
	for _, b in {
		{ "PetUnequip", "RedPlain", "Unequip" },
		{ "PetEquip", "GreenPlain", "Equip" },
		{ "PetRiding", "YellowPlain", "Riding" },
	} do
		local btn = button(row, b[1], 272, 112, { Position = UDim2.fromOffset(fig(567), fig(47)), ZIndex = 3 }, b[2])
		local text = label(btn, "Text", {
			Text = b[3],
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(45),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
		})
		text.Outline.Color = OUTLINES[b[3]]
	end
	return row
end

local made = {}
local busy = false
local function refresh()
	if not panel then
		return
	end
	for _, r in made do
		r:Destroy()
	end
	table.clear(made)
	local list = pets()
	local active = 0
	for _, pet in list do
		if pet.equipped then
			active += 1
		end
	end
	panel.title.Text = active .. " Active"
	for i, pet in list do
		local row = Ui.copy(template, "Row" .. i, panel.rows)
		row.LayoutOrder = i
		row.Picture.Image = PetFaces.HEADSHOTS[pet.kind] or ""
		row.Picture.ImageTransparency = if pet.equipped then 0 else 0.2
		row.PetName.Text = about(pet.kind).name
		row.PetCash.Text = "($" .. Config.short(pet.income) .. "/s)"
		row.PetRiding.Visible = pet.riding == true
		row.PetUnequip.Visible = pet.equipped and not pet.riding
		row.PetEquip.Visible = not pet.equipped
		for _, b in { row.PetUnequip, row.PetEquip } do
			HudKit.hover(b) -- (a copy doesn't keep the template's)
			b.Activated:Connect(function()
				if busy then
					return
				end
				busy = true
				if not pet.equipped then
					UiFx.play("Equip")
				end
				ReplicatedStorage:WaitForChild(if pet.equipped then "UnequipPet" else "EquipPet"):FireServer(pet.id)
				task.delay(0.4, function()
					busy = false
				end)
			end)
		end
		table.insert(made, row)
	end
end

local function ensure()
	if panel then
		return
	end
	panel = SidePanel.new(NativeHud.popupRoot(), "PetsPanel", "GoldHeader", "0 Active", OUTLINES.Title)
	template = Ui.template(panel.rows, "RowTemplate", rowTemplate)
	-- kept up to date while it's open
	local watched
	local function watchPen()
		if watched then
			watched:Disconnect()
			watched = nil
		end
		local pen = myPen()
		if pen then
			watched = pen:GetAttributeChangedSignal("Contents"):Connect(function()
				if panel:isOpen() then
					refresh()
				end
			end)
		end
	end
	player:GetAttributeChangedSignal("Pen"):Connect(watchPen)
	watchPen()
	for _, name in { "RidePet", "StoredPets" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			if panel:isOpen() then
				refresh()
			end
		end)
	end
	-- (its haze follows it, however it closes: its tab, another menu opening)
	panel.gui:GetPropertyChangedSignal("Visible"):Connect(function()
		NativeHud.haze("Pets", panel.gui.Visible)
	end)
end

function NativePets.isOpen()
	return panel ~= nil and panel:isOpen()
end

function NativePets.toggle()
	ensure()
	if not panel:isOpen() then
		refresh()
		panel.rows.CanvasPosition = Vector2.zero
	end
	panel:toggle()
end

function NativePets.close()
	if panel then
		panel:close()
	end
end

return NativePets
