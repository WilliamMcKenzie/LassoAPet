-- Run in Studio (Edit, execute_luau): rebuilds workspace.World2 from workspace.World.
-- World 2's starting terrain (QM, Oct 13): World 1's terrain copied 1000 studs over in X,
-- each biome's colours hue-rotated. Self-contained in workspace.World2 so it can move
-- into its own Place later.
local OFFSET = Vector3.new(1000, 0, 0)
local COPY = { "Ground", "Walls", "Decor", "Obstacles", "StartLine", "BaseDecor", "Funnel" }
-- biomes by Z (the track runs to -Z): { from Z, hue shift }
local BIOMES = {
	{ 1e9, 0.55, "Meadow" }, -- green grass and orange walls -> pink grass, blue walls
	{ -2168, 0.6, "Desert" }, -- sand -> lilac
	{ -3984, 0.35, "Tundra" }, -- ice blue -> pink ice
	{ -5904, 0.2, "Ocean" }, -- blue -> violet
	{ -9024, 0.45, "Volcano" }, -- orange lava -> blue fire
	{ -14064, 0.75, "Jurassic" }, -- green jungle -> autumn
}
local function shiftFor(z)
	local s = BIOMES[1][2]
	for _, b in BIOMES do
		if z <= b[1] then
			s = b[2]
		end
	end
	return s
end
local function rotate(c, shift)
	local h, s, v = c:ToHSV()
	if s < 0.12 then
		return c -- (greys, white and black stay)
	end
	return Color3.fromHSV((h + shift) % 1, s, v)
end
local old = workspace:FindFirstChild("World2")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "World2"
root:SetAttribute("Offset", OFFSET)
local n = 0
for _, name in COPY do
	local copy = workspace.World[name]:Clone()
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			local shift = shiftFor(d.Position.Z)
			d.Color = rotate(d.Color, shift)
			d.CFrame += OFFSET
			n += 1
		elseif d:IsA("Model") then
			d.WorldPivot += OFFSET
		elseif d:IsA("Texture") or d:IsA("Decal") then
			local p = d.Parent
			if p:IsA("BasePart") then
				d.Color3 = rotate(d.Color3, shiftFor(p.Position.Z - OFFSET.Z))
			end
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	if copy:IsA("Model") then
		copy.WorldPivot += OFFSET
	end
	copy.Parent = root
end
root.Parent = workspace
return n .. " parts"
