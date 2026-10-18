-- Try biome colours in Studio's Edit mode, no Play (QM, Oct 15). It lives as ServerStorage.ColorTest.
-- In the command bar:
--   require(game.ServerStorage.ColorTest).start()   -- workspace.World gets every biome's colour attributes
--       (GroundA, WetSandB, GardenGroundA, GardenSoilB...) from Config; edit them in Properties and the
--       map repaints as you go
--   require(game.ServerStorage.ColorTest).stop()    -- prints the values as Config lines for each
--       biome (send them to Claude), and clears the attributes so they're never published
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ColorTest = {}
local connections = {}

local function fresh(name)
	local m = ReplicatedStorage.Shared[name]:Clone()
	m.Name = name .. "ColorTest"
	m.Parent = ReplicatedStorage.Shared
	return m
end

local function clear(world)
	for key in world:GetAttributes() do
		if key:match("[AB]$") and typeof(world:GetAttribute(key)) == "Color3" then
			world:SetAttribute(key, nil)
		end
	end
end

function ColorTest.start()
	local world = workspace.World
	for _, c in connections do c:Disconnect() end
	table.clear(connections)
	clear(world)
	-- (fresh copies, so Config edits since the last require count)
	local config = fresh("Config")
	local wc = fresh("WorldColors")
	wc.Source = wc.Source:gsub("require%(script%.Parent%.Config%)", "require(script.Parent.ConfigColorTest)")
	local Config, WorldColors = require(config), require(wc)
	config:Destroy(); wc:Destroy()
	for i, biome in Config.Biomes do
		local prefix = if i == 1 then "" else biome.Name
		local keys = { GroundA = biome.GroundColors[1], GroundB = biome.GroundColors[2], WallA = biome.WallColors[1], WallB = biome.WallColors[2] }
		for name, colors in biome.Patches or {} do
			keys[name .. "A"], keys[name .. "B"] = colors[1], colors[2]
		end
		for key, value in keys do
			world:SetAttribute(prefix .. key, value)
			table.insert(connections, world:GetAttributeChangedSignal(prefix .. key):Connect(function()
				WorldColors.apply(world)
			end))
		end
	end
	WorldColors.apply(world)
	print("ColorTest: edit workspace.World's colour attributes; require(game.ServerStorage.ColorTest).stop() when done")
end

function ColorTest.stop()
	local world = workspace.World
	local lines = {}
	local function rgb(c) return string.format("rgb(%d, %d, %d)", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255)) end
	local seen = {}
	for key, value in world:GetAttributes() do
		local base = key:match("^(.*)A$")
		if base and typeof(value) == "Color3" and not seen[base] then
			seen[base] = true
			local b = world:GetAttribute(base .. "B")
			table.insert(lines, base .. " = { " .. rgb(value) .. ", " .. (if b then rgb(b) else rgb(value)) .. " },")
		end
	end
	table.sort(lines)
	print("ColorTest values:\n" .. table.concat(lines, "\n"))
	for _, c in connections do c:Disconnect() end
	table.clear(connections)
	clear(world)
end

return ColorTest
