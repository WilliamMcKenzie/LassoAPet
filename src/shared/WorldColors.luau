-- Live colour tuning for the ground and walls. In Studio, press Play, select
-- Workspace > World and edit its GroundA / GroundB / WallA / WallB attributes:
-- the map recolours instantly. Copy the values you like into Config.

local Config = require(script.Parent.Config)

local WorldColors = {}

local DEFAULTS = {
	GroundA = Config.GroundColors[1],
	GroundB = Config.GroundColors[2],
	WallA = Config.WallColors[1],
	WallB = Config.WallColors[2],
}

local function paint(part, base, checker)
	part.Color = base
	local texture = part:FindFirstChild("Checker")
	if texture then
		texture.Color3 = checker
	end
end

function WorldColors.apply(world)
	local groundA, groundB = world:GetAttribute("GroundA"), world:GetAttribute("GroundB")
	local wallA, wallB = world:GetAttribute("WallA"), world:GetAttribute("WallB")
	for _, part in world.Ground:GetChildren() do
		paint(part, groundA, groundB)
	end
	for _, part in world.Walls:GetChildren() do
		if part.Name == "Cap" then
			part.Color = groundB
		else
			paint(part, wallA, wallB)
		end
	end
end

-- Seeds the attributes (server) and repaints whenever one changes.
function WorldColors.watch(world)
	for key, default in DEFAULTS do
		if world:GetAttribute(key) == nil then
			world:SetAttribute(key, default)
		end
		world:GetAttributeChangedSignal(key):Connect(function()
			WorldColors.apply(world)
		end)
	end
	WorldColors.apply(world)
end

return WorldColors
