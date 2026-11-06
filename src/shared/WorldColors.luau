-- Live world colours: every part (or checker Texture) with a ColorKey attribute wears
-- Config.WorldColors[ColorKey]. The server makes workspace.WorldColors, a Configuration
-- with one Color3 attribute per key, fresh from Config each run; the client repaints
-- everything with that key whenever one changes, so you can tune colours in the
-- Properties panel during Play (in the Client view). Tick PrintColors to print the
-- current set as a Config.WorldColors block for the Output (paste it into Config, or to
-- Claude). (The studs' fade is workspace.StudStyle now: Shared/StudStyle.)
-- On start everything is painted from Config, so a saved place can't keep stale colours.
--
--   WorldColors.create()  -- server, once
--   WorldColors.watch()   -- client, once

local Config = require(script.Parent.Config)

local WorldColors = {}

local NAME = "WorldColors"

function WorldColors.create()
	local old = workspace:FindFirstChild(NAME)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Configuration")
	folder.Name = NAME
	for key, color in Config.WorldColors do
		folder:SetAttribute(key, color)
	end
	folder:SetAttribute("PrintColors", false)
	folder.Parent = workspace
	WorldColors.paintAll(folder)
	return folder
end

-- a part's colour: its key's, lightened or darkened by its Shade attribute if it has one
-- (Server/Map gives each stone block its own)
function WorldColors.shaded(color, thing)
	local shade = thing:GetAttribute("Shade")
	if typeof(shade) ~= "number" then
		return color
	end
	return Color3.new(math.min(1, color.R * shade), math.min(1, color.G * shade), math.min(1, color.B * shade))
end

local function paint(key, color)
	for _, thing in workspace:GetDescendants() do
		if thing:GetAttribute("ColorKey") == key then
			if thing:IsA("BasePart") then
				thing.Color = WorldColors.shaded(color, thing)
			elseif thing:IsA("Texture") then
				thing.Color3 = color
			elseif thing:IsA("Beam") then
				thing.Color = ColorSequence.new(color)
			end
		end
	end
end

-- everything, from the folder's current values (the server does this on start, so the
-- world always wears Config's colours however the place was saved)
function WorldColors.paintAll(folder)
	for _, thing in workspace:GetDescendants() do
		local key = thing:GetAttribute("ColorKey")
		local color = key and folder:GetAttribute(key)
		if typeof(color) == "Color3" then
			if thing:IsA("BasePart") then
				thing.Color = WorldColors.shaded(color, thing)
			elseif thing:IsA("Texture") then
				thing.Color3 = color
			elseif thing:IsA("Beam") then
				thing.Color = ColorSequence.new(color)
			end
		end
	end
end

local function printAll(folder)
	local keys = {}
	for key, value in folder:GetAttributes() do
		if typeof(value) == "Color3" then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	local lines = { "WorldColors = {" }
	for _, key in keys do
		local c = folder:GetAttribute(key)
		table.insert(
			lines,
			string.format(
				"\t%s = Color3.fromRGB(%d, %d, %d),",
				key,
				math.round(c.R * 255),
				math.round(c.G * 255),
				math.round(c.B * 255)
			)
		)
	end
	table.insert(lines, "},")
	print(table.concat(lines, "\n"))
end

function WorldColors.watch()
	local folder = workspace:WaitForChild(NAME, 30)
	if not folder then
		return
	end
	WorldColors.paintAll(folder)
	folder.AttributeChanged:Connect(function(key)
		local value = folder:GetAttribute(key)
		if key == "PrintColors" then
			if value then
				printAll(folder)
				folder:SetAttribute("PrintColors", false)
			end
		elseif typeof(value) == "Color3" then
			paint(key, value)
		end
	end)
end

-- ---- Lasso's course geometry (Config.Biomes, the course's width) ----------------------

-- Index into Config.Biomes of the biome at z. The course runs toward -z from
-- z = 0; the home base (z > 0) counts as the first biome, past the end as the last.
function WorldColors.biomeAt(z)
	local edge = 0
	for i, biome in Config.Biomes do
		edge -= biome.Length
		if z >= edge then
			return i
		end
	end
	return #Config.Biomes
end

-- Where the biome called name starts (its edge nearest home), or nil if there's none.
function WorldColors.biomeNamedStart(name)
	local edge = 0
	for _, biome in Config.Biomes do
		if biome.Name == name then
			return edge
		end
		edge -= biome.Length
	end
	return nil
end

-- The course's half width at z (Config: a funnel, widening from the start line; or World 3's
-- Config.CourseProfile, { z, half width } stops widening and narrowing, straight between).
function WorldColors.halfWidth(z)
	local profile = Config.CourseProfile
	if profile then
		z = math.min(z, 0)
		for k = 2, #profile do
			local a, b = profile[k - 1], profile[k]
			if z >= b[1] then
				return a[2] + (b[2] - a[2]) * (a[1] - z) / (a[1] - b[1])
			end
		end
		return profile[#profile][2]
	end
	return math.min(Config.CourseHalfWidth + Config.CourseWidening * math.max(-z, 0), Config.CourseMaxHalfWidth)
end

-- How many times wider than at the start line the course is at z.
function WorldColors.widen(z)
	return WorldColors.halfWidth(z) / Config.CourseHalfWidth
end

-- The z of biome i's near edge (the line you cross into it).
function WorldColors.biomeStart(i)
	local edge = 0
	for j = 1, i - 1 do
		edge -= Config.Biomes[j].Length
	end
	return edge
end

-- The z of the first gate a player with this pen level can't pass (-inf if none).
function WorldColors.gateZ(level)
	if not Config.Gates then
		return -math.huge
	end
	local next = Config.Biomes[(level or 1) + 1]
	return if next then WorldColors.biomeStart((level or 1) + 1) else -math.huge
end

local function prefix(i)
	return if i == 1 then "" else Config.Biomes[i].Name
end
WorldColors.prefix = prefix

-- Where z is along biome i, 0 at its near edge to 1 at its far one.
function WorldColors.along(i, z)
	return math.clamp((WorldColors.biomeStart(i) - z) / Config.Biomes[i].Length, 0, 1)
end

-- Biome i's Depths stops (Config) either side of z and the fraction to blend
-- between them, or nil if it has none.
function WorldColors.depthAt(i, z)
	local stops = Config.Biomes[i].Depths
	if not stops then
		return nil
	end
	local t = WorldColors.along(i, z)
	for k = 2, #stops do
		if t <= stops[k].At then
			return stops[k - 1], stops[k], (t - stops[k - 1].At) / (stops[k].At - stops[k - 1].At)
		end
	end
	return stops[#stops], stops[#stops], 0
end

-- The terrain's colours as painted: Config.TerrainSaturation x their saturation
-- (QM, Oct 6; 1 leaves them as they are). The attributes and Config keep the
-- unboosted colours, so setting it back to 1 undoes it.
function WorldColors.saturate(color)
	local k = Config.TerrainSaturation or 1
	if not color or k == 1 then
		return color
	end
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.min(s * k, 1), v)
end

return WorldColors
