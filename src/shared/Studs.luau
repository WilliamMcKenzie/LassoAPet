-- Studs as a material (Config.StudMaterial, QM Oct 7): instead of a stud Texture on
-- every face (tens of thousands of them, each drawn on its own), a part gets a stud
-- MaterialVariant from MaterialService: "Studs" for the 1-stud studs (ground), and
-- "StudsHalf" for the 0.5-stud ones (obstacles, animals, eggs, Carl's stall). They're
-- from the "2008-2024 Studs As PBR Materials" pack (Glacier base material), tinted by
-- the part's colour like the textures were. Without them in MaterialService, or with
-- Config.StudMaterial off, everything keeps its textures.
--
--   Studs.apply(part, tile) -- the stud material for that tile size; false if there's none
--   Studs.convert(part)     -- swaps a part's stud Textures for the material (not ground
--                           -- with a checker: its studs lie over the checker)

local MaterialService = game:GetService("MaterialService")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Config)

-- (a client sees MaterialService's variants once the place has loaded in: without
-- this, the first animals and eggs built at join could miss them and keep textures)
if Config.StudMaterial and RunService:IsClient() and not game:IsLoaded() then
	game.Loaded:Wait()
end

local Studs = {}

Studs.IMAGE = "rbxassetid://7447638591" -- the classic stud decal every stud Texture uses
local NAMES = { [0.5] = "StudsHalf", [1] = "Studs" }
-- Glacier is slippery: anything you can stand on keeps plastic's grip.
local PLASTIC = PhysicalProperties.new(Enum.Material.SmoothPlastic)

function Studs.variant(tile)
	local name = Config.StudMaterial and NAMES[tile]
	local variant = name and MaterialService:FindFirstChild(name)
	return if variant and variant:IsA("MaterialVariant") then variant else nil
end

function Studs.apply(part, tile)
	local variant = Studs.variant(tile)
	if not variant then
		return false
	end
	part.Material = variant.BaseMaterial
	part.MaterialVariant = variant.Name
	if part.CanCollide then
		part.CustomPhysicalProperties = PLASTIC
	end
	return true
end

function Studs.convert(part)
	if part.Material ~= Enum.Material.SmoothPlastic and part.Material ~= Enum.Material.Plastic then
		return false -- (Neon lava and the like have no studs)
	end
	local textures, tile = {}, nil
	for _, child in part:GetChildren() do
		if child:IsA("Texture") then
			if child.Name == "Checker" then
				return false
			elseif child.Texture == Studs.IMAGE then
				tile = tile or child.StudsPerTileU
				table.insert(textures, child)
			end
		end
	end
	if #textures == 0 or not Studs.apply(part, tile) then
		return false
	end
	for _, texture in textures do
		texture:Destroy()
	end
	return true
end

return Studs
