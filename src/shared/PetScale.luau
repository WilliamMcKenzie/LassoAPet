-- Every animal's size (QM, Oct 31 in Fight to Steal an Egg; Lasso A Pet, Nov 6):
-- workspace.PetScale, a Configuration per biome ("1 Meadow", "2 Desert", ...) with a number
-- attribute per animal of its Herd in Config.Biomes, how much bigger than its own size it's drawn: 1 is its tier's
-- size, 2 twice that. Change them in the Properties panel in Edit mode, where the pet
-- lineup (Shared/PetLineup) resizes to match as you type; they're kept with the place, so
-- your values win over Config.AnimalScale, which only seeds a place that has none (Config
-- reads them over its AnimalScale as it loads, so the game draws them at your sizes too).
-- Tick CopyValues to print them to the Output as a Config.AnimalScale line, ready to
-- paste into Config.
--
--   PetScale.of(kind)  -> its scale (workspace.PetScale, else Config.AnimalScale, else 1)
--   PetScale.kinds()   -> every animal in a biome's herd, in biome order
--   PetScale.groups()  -> { { name = "1 Meadow", kinds = {...} }, ... }: each biome's group
--   PetScale.ensure()  -- makes workspace.PetScale, its groups and an attribute for every animal
--   PetScale.text()    -> the Config.AnimalScale line for the current values

local PetScale = {}

PetScale.NAME = "PetScale"
PetScale.COPY = "CopyValues" -- (the tick box that prints them)
PetScale.SPARE = "99 Not in a biome yet" -- (was "9 ...": 9 is Marble Meadow now; renamed in place by ensure) -- (animals no biome has now: their values, kept)

local Config = require(script.Parent.Config)

local function style()
	return workspace:FindFirstChild(PetScale.NAME)
end

-- Each biome's group: a Configuration in workspace.PetScale named "<n> <biome>" (numbered so
-- the Explorer lists them in biome order; QM, Nov 6: sorted by biome), its animals' values.
function PetScale.groups()
	local out = {}
	local seen = {}
	for i, biome in Config.allBiomes() do -- (the endless biomes too: 9, 10, 11)
		local herd = {}
		for kind in biome.Herd or {} do
			if not seen[kind] then
				seen[kind] = true
				table.insert(herd, kind)
			end
		end
		table.sort(herd)
		-- (named as players see it, the Castle's slot "7 Jurassic": QM Nov 7; was "7 Castle", renamed in place)
		local name = i .. " " .. (biome.DisplayName or biome.Name or ("Biome " .. i))
		table.insert(out, { name = name, was = i .. " " .. (biome.Name or ""), kinds = herd })
	end
	return out
end

function PetScale.of(kind)
	local s = style()
	if s then
		for _, group in s:GetChildren() do
			local value = group:GetAttribute(kind)
			if type(value) == "number" and value > 0 then
				return value
			end
		end
		local value = s:GetAttribute(kind) -- (a place from before the groups)
		if type(value) == "number" and value > 0 then
			return value
		end
	end
	return Config.AnimalScale[kind] or 1
end

function PetScale.kinds()
	local out = {}
	for _, group in PetScale.groups() do
		for _, kind in group.kinds do
			table.insert(out, kind)
		end
	end
	return out
end

function PetScale.ensure()
	local s = style()
	if not s then
		s = Instance.new("Configuration")
		s.Name = PetScale.NAME
		s.Parent = workspace
	end
	local oldSpare = s:FindFirstChild("9 Not in a biome yet")
	if oldSpare and not s:FindFirstChild(PetScale.SPARE) then
		oldSpare.Name = PetScale.SPARE
	end
	for _, g in PetScale.groups() do
		local group = s:FindFirstChild(g.name)
		if not group and g.was ~= g.name then
			group = s:FindFirstChild(g.was) -- (its values kept under its new name)
			if group then
				group.Name = g.name
			end
		end
		if not group then
			group = Instance.new("Configuration")
			group.Name = g.name
			group.Parent = s
		end
		for _, kind in g.kinds do
			if group:GetAttribute(kind) == nil then
				-- (a value kept on workspace.PetScale itself, from before the groups, moves in)
				local old = s:GetAttribute(kind)
				group:SetAttribute(kind, if type(old) == "number" then old else (Config.AnimalScale[kind] or 1))
			end
			s:SetAttribute(kind, nil)
		end
	end
	-- (values left on workspace.PetScale itself, for animals in no biome's herd now: kept, out
	-- of the way, in a group of their own)
	local spare = nil
	for kind, value in s:GetAttributes() do
		if kind ~= PetScale.COPY and type(value) == "number" then
			spare = spare or s:FindFirstChild(PetScale.SPARE) or Instance.new("Configuration")
			spare.Name = PetScale.SPARE
			spare.Parent = s
			if spare:GetAttribute(kind) == nil then
				spare:SetAttribute(kind, value)
			end
			s:SetAttribute(kind, nil)
		end
	end
	if s:GetAttribute(PetScale.COPY) == nil then
		s:SetAttribute(PetScale.COPY, false)
	end
	return s
end

function PetScale.text()
	local kinds = {}
	local s = style()
	for _, kind in PetScale.kinds() do
		if s and math.abs(PetScale.of(kind) - 1) > 1e-4 then
			table.insert(kinds, kind)
		end
	end
	table.sort(kinds)
	local entries = {}
	for _, kind in kinds do
		table.insert(entries, string.format("%s = %s", kind, tostring(math.round(PetScale.of(kind) * 1000) / 1000)))
	end
	return "\tAnimalScale = { " .. table.concat(entries, ", ") .. " }, -- (workspace.PetScale)"
end

return PetScale
