-- The pet lineup (QM, Oct 31 in Fight to Steal an Egg; Lasso A Pet, Nov 6): every
-- biome's animals standing like a diorama in the middle of that biome's run, a group per
-- biome (workspace.PetLineup.<Biome>), each animal at its scale in workspace.PetScale with
-- its name and scale over its head, so sizes can be seen where they're met and set. It's
-- for Studio's Edit mode: the Map Baker plugin's Pet Lineup button (or
-- tools/studio/pet_lineup.luau with lu.py) builds it and calls watch(), so changing an
-- animal's PetScale resizes it there and spaces its group out again. The game deletes it
-- when it starts (Server/World).
--
--   PetLineup.build()  -- (re)builds workspace.PetLineup from scratch
--   PetLineup.watch()  -> a connection: follows workspace.PetScale (and its CopyValues tick)

local Config = require(script.Parent.Config)
local Ground = require(script.Parent.Ground)
local PetScale = require(script.Parent.PetScale)
local WorldColors = require(script.Parent.WorldColors)

local Animals = script.Parent.Animals

local PetLineup = {}

PetLineup.NAME = "PetLineup"

local GAP = 6 -- studs between two animals side by side
local ROW_GAP = 10 -- studs between rows
local ROW_WIDTH = 150 -- a row this wide carries on in a new one behind (the course is 160+ across)

-- each biome's group: its name, the z of the middle of its run, its herd (commonest first)
local function groups()
	local out = {}
	for i, biome in Config.Biomes do
		local herd = {}
		for kind, weight in biome.Herd or {} do
			if Animals:FindFirstChild(kind) then
				table.insert(herd, { kind, weight })
			end
		end
		table.sort(herd, function(a, b)
			if a[2] ~= b[2] then
				return a[2] > b[2]
			end
			return a[1] < b[1]
		end)
		local kinds = {}
		for _, h in herd do
			table.insert(kinds, h[1])
		end
		if #kinds > 0 then
			table.insert(out, { name = biome.Name, z = WorldColors.biomeStart(i) - biome.Length / 2, kinds = kinds })
		end
	end
	return out
end

local function lineup()
	return workspace:FindFirstChild(PetLineup.NAME)
end

local function spaced(kind)
	return (string.gsub(kind, "(%l)(%u)", "%1 %2"))
end

local function label(model, kind)
	local gui = model:FindFirstChild("Label")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "Label"
		gui.Size = UDim2.fromOffset(180, 44)
		gui.LightInfluence = 0
		gui.MaxDistance = 600
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0
		text.Parent = gui
		gui.Parent = model
	end
	gui.Adornee = model.PrimaryPart
	gui.Text.Text = string.format("%s\nx%s", spaced(kind), tostring(math.round(PetScale.of(kind) * 1000) / 1000))
	return gui
end

-- puts a group's animals in place: rows back (+z) from its pivot, each row centred on it,
-- every animal's feet on the floor, all facing down the course (-z)
local function arrange(group)
	local origin = group.WorldPivot.Position
	local z = origin.Z
	local lines, line, width = {}, {}, 0
	for _, model in group:GetChildren() do
		if model:IsA("Model") then
			local _, size = model:GetBoundingBox()
			if #line > 0 and width + GAP + size.X > ROW_WIDTH then
				table.insert(lines, { line, width })
				line, width = {}, 0
			end
			width += (if #line > 0 then GAP else 0) + size.X
			table.insert(line, model)
		end
	end
	if #line > 0 then
		table.insert(lines, { line, width })
	end
	for _, l in lines do
		local x = origin.X - l[2] / 2
		local depth = 0
		for _, model in l[1] do
			local _, size = model:GetBoundingBox()
			depth = math.max(depth, size.Z)
		end
		for _, model in l[1] do
			local cf, size = model:GetBoundingBox()
			local goal = Vector3.new(x + size.X / 2, origin.Y + size.Y / 2, z + depth / 2)
			model:PivotTo(model:GetPivot() + (goal - cf.Position))
			local gui = model:FindFirstChild("Label")
			if gui and model.PrimaryPart then
				gui.StudsOffsetWorldSpace = Vector3.new(0, origin.Y + size.Y + 3 - model.PrimaryPart.Position.Y, 0)
			end
			x += size.X + GAP
		end
		z += depth + ROW_GAP
	end
end

local function add(group, kind)
	local animal = require(Animals[kind]).new()
	local model = animal.model
	model.Name = kind
	model:SetAttribute("Scale", PetScale.of(kind))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.Locked = true -- (so a stray click doesn't drag one block off an animal)
		end
	end
	label(model, kind)
	model.Parent = group
	return model
end

function PetLineup.build()
	PetScale.ensure()
	local old = lineup()
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = PetLineup.NAME
	for _, g in groups() do
		local group = Instance.new("Model")
		group.Name = g.name
		group.WorldPivot = CFrame.new(0, Ground.heightAt(0, g.z), g.z)
		for _, kind in g.kinds do
			local ok, err = pcall(add, group, kind)
			if not ok then
				warn("[Pet lineup] " .. g.name .. " " .. kind .. ": " .. tostring(err))
			end
		end
		group.Parent = root
		arrange(group)
	end
	root.Parent = workspace
	return root
end

-- one animal to its PetScale value, wherever it stands in the lineup: grown or shrunk
-- about where it stands, then its group respaced
local function resize(kind)
	local root = lineup()
	if not root then
		return
	end
	for _, group in root:GetChildren() do
		local model = group:FindFirstChild(kind)
		if model then
			local now, was = PetScale.of(kind), model:GetAttribute("Scale") or 1
			if now ~= was then
				model:ScaleTo(model:GetScale() * now / was)
				model:SetAttribute("Scale", now)
			end
			label(model, kind)
			arrange(group)
		end
	end
end

function PetLineup.watch()
	local s = PetScale.ensure()
	local root = lineup()
	if not root then
		PetLineup.build()
	else
		for _, kind in PetScale.kinds() do
			resize(kind) -- (values changed while nothing was watching)
		end
	end
	-- (the CopyValues tick on workspace.PetScale, each animal's value in its biome's group)
	local conns = {}
	table.insert(conns, s.AttributeChanged:Connect(function(name)
		if name == PetScale.COPY then
			if s:GetAttribute(name) == true then
				print("[PetScale] paste this over Config.AnimalScale (src/shared/Config.luau):\n" .. PetScale.text())
				s:SetAttribute(name, false)
			end
		end
	end))
	for _, group in s:GetChildren() do
		table.insert(conns, group.AttributeChanged:Connect(resize))
	end
	return {
		Disconnect = function()
			for _, c in conns do
				c:Disconnect()
			end
		end,
	}
end

return PetLineup
