-- Every animal's size (QM, Oct 31 in Fight to Steal an Egg; Lasso A Pet, Nov 6):
-- workspace.PetScale, a Configuration with a number attribute per animal (each biome's
-- Herd in Config.Biomes), how much bigger than its own size it's drawn: 1 is its tier's
-- size, 2 twice that. Change them in the Properties panel in Edit mode, where the pet
-- lineup (Shared/PetLineup) resizes to match as you type; they're kept with the place, so
-- your values win over Config.AnimalScale, which only seeds a place that has none (Config
-- reads them over its AnimalScale as it loads, so the game draws them at your sizes too).
-- Tick CopyValues to print them to the Output as a Config.AnimalScale line, ready to
-- paste into Config.
--
--   PetScale.of(kind)  -> its scale (workspace.PetScale, else Config.AnimalScale, else 1)
--   PetScale.kinds()   -> every animal in a biome's herd, in biome order
--   PetScale.ensure()  -- makes workspace.PetScale and an attribute for every animal
--   PetScale.text()    -> the Config.AnimalScale line for the current values

local PetScale = {}

PetScale.NAME = "PetScale"
PetScale.COPY = "CopyValues" -- (the tick box that prints them)

local Config = require(script.Parent.Config)

local function style()
	return workspace:FindFirstChild(PetScale.NAME)
end

function PetScale.of(kind)
	local s = style()
	local value = s and s:GetAttribute(kind)
	if type(value) == "number" and value > 0 then
		return value
	end
	return Config.AnimalScale[kind] or 1
end

function PetScale.kinds()
	local out, seen = {}, {}
	for _, biome in Config.Biomes do
		local herd = {}
		for kind in biome.Herd or {} do
			table.insert(herd, kind)
		end
		table.sort(herd)
		for _, kind in herd do
			if not seen[kind] then
				seen[kind] = true
				table.insert(out, kind)
			end
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
	for _, kind in PetScale.kinds() do
		if s:GetAttribute(kind) == nil then
			s:SetAttribute(kind, Config.AnimalScale[kind] or 1)
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
	for kind, value in (s and s:GetAttributes() or {}) do
		if kind ~= PetScale.COPY and type(value) == "number" and math.abs(value - 1) > 1e-4 then
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
