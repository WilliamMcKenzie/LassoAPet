-- The Godly trail's lock (QM, Nov 7: "also have to unlock all animals for this one"): every
-- animal the Index lists (Client/NativeIndex's: each biome's Herd, the endless course's
-- too, but not the starter) must be in your "Caught" list (Server/Hatchery).
--
--   Trails.allAnimals() -> { kind }
--   Trails.hasAllAnimals(player) -> bool, have, total

local HttpService = game:GetService("HttpService")

local Config = require(script.Parent.Config)

local Trails = {}

local list
function Trails.allAnimals()
	if not list then
		list = {}
		local seen = {}
		local animals = script.Parent:FindFirstChild("Animals")
		for _, biome in Config.allBiomes() do
			for kind, weight in biome.Herd or {} do
				if weight >= 0 and kind ~= Config.DefaultPet and not seen[kind] and animals and animals:FindFirstChild(kind) then
					seen[kind] = true
					table.insert(list, kind)
				end
			end
		end
	end
	return list
end

function Trails.hasAllAnimals(player)
	local ok, caught = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Caught") or "[]")
	local set = {}
	for _, kind in if ok and typeof(caught) == "table" then caught else {} do
		set[kind] = true
	end
	local all, have = Trails.allAnimals(), 0
	for _, kind in all do
		if set[kind] then
			have += 1
		end
	end
	return have >= #all, have, #all
end

return Trails
