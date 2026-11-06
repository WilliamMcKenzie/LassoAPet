-- Each biome's fog (QM, Nov 6): workspace.Fog, a Folder with a Configuration per map area
-- (Base, Meadow, Desert, Ice, Lava, ...) holding its fog's Color, Start and End (studs).
-- Change them in the Properties panel; in Edit mode the Map Baker plugin shows the fog of
-- the biome the Studio camera is in as you fly about, and in the game the fog eases to the
-- biome you're in, coloured by the biomes the fog itself is in (Client/Fog). From and To are
-- the biome's edges along the course (set from the map each rebuild: just for reference). Kept with the place.
--
--   BiomeFog.ensure(areas)  -- makes workspace.Fog and an entry per area (Server/Map: the
--                              map's areas, { Name, Bounds = { x0, zTop, x1, zBottom } })
--   BiomeFog.at(z)          -> the entry (Configuration) whose biome z is in, or nil
--   BiomeFog.step(z, dt?, look?) -- eases Lighting's fog toward the fog at z; with the camera's
--                              LookVector, its colour comes from the biomes the fog is in

local Lighting = game:GetService("Lighting")
local Endless = require(script.Parent.Endless)

local BiomeFog = {}

BiomeFog.NAME = "Fog"
BiomeFog.FADE = 1.2 -- seconds, roughly, to ease from one biome's fog to the next

function BiomeFog.ensure(areas)
	local folder = workspace:FindFirstChild(BiomeFog.NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = BiomeFog.NAME
		folder.Parent = workspace
	end
	for i, area in areas do
		local entry = folder:FindFirstChild(area.Name)
		if not entry then
			entry = Instance.new("Configuration")
			entry.Name = area.Name
			entry:SetAttribute("Color", Lighting.FogColor)
			entry:SetAttribute("Start", Lighting.FogStart)
			entry:SetAttribute("End", Lighting.FogEnd)
			entry.Parent = folder
		end
		entry:SetAttribute("Order", i)
		local b = area.Bounds
		if b then
			entry:SetAttribute("From", math.max(b[2], b[4]))
			entry:SetAttribute("To", math.min(b[2], b[4]))
		else
			-- (the home base: everything before the first biome)
			entry:SetAttribute("From", 1e6)
			entry:SetAttribute("To", nil)
		end
	end
	return folder
end

function BiomeFog.at(z)
	local folder = workspace:FindFirstChild(BiomeFog.NAME)
	if not folder then
		return nil
	end
	local best, bestTo = nil, -math.huge
	for _, entry in folder:GetChildren() do
		local from, to = entry:GetAttribute("From"), entry:GetAttribute("To")
		if type(from) == "number" and z <= from and (to == nil or z >= to) then
			-- (the home base has no To: a biome inside its range wins)
			local t = to or -1e6
			if t > bestTo then
				best, bestTo = entry, t
			end
		end
	end
	return best
end

local function fogOf(entry)
	if not entry then
		return nil
	end
	local color, s, e = entry:GetAttribute("Color"), entry:GetAttribute("Start"), entry:GetAttribute("End")
	if typeof(color) ~= "Color3" or type(s) ~= "number" or type(e) ~= "number" then
		return nil
	end
	return color, s, e
end

-- Roblox has one fog for the whole screen, so the fog's colour is mixed from where the fog
-- actually is: points along the view, from where the fog starts to where it's thick, each
-- taking the colour of the biome it's in, weighted by how thick the fog is there. Looking
-- down the course from Meadow, the haze ahead is already Desert's; turn round and it's Meadow's.
local SAMPLES = 12

local function colourAlong(z, lookZ, s, e, own)
	if not lookZ or math.abs(lookZ) < 1e-3 or e <= s then
		return own
	end
	local r, g, b, total = 0, 0, 0, 0
	for i = 1, SAMPLES do
		local w = i / SAMPLES -- (linear fog: how thick it is at this distance)
		local c = fogOf(BiomeFog.at(z + lookZ * (s + (e - s) * w))) or own
		r += c.R * w
		g += c.G * w
		b += c.B * w
		total += w
	end
	return Color3.new(r / total, g / total, b / total)
end

-- look: the camera's LookVector (optional; without it, the fog of the biome z is in)
function BiomeFog.step(z, dt, look)
	local color, s, e
	local endless = Endless.fogAt(z) -- (past the Ocean: the endless stretch's biome's, Config.Endless)
	if endless then
		color, s, e = endless.Color, endless.Start, endless.End
	else
		local own
		own, s, e = fogOf(BiomeFog.at(z))
		if not own then
			return
		end
		color = colourAlong(z, look and look.Z, s, e, own)
	end
	local k = if dt then 1 - math.exp(-3 * dt / BiomeFog.FADE) else 1
	Lighting.FogColor = Lighting.FogColor:Lerp(color, k)
	Lighting.FogStart += (s - Lighting.FogStart) * k
	Lighting.FogEnd += (e - Lighting.FogEnd) * k
end

return BiomeFog
