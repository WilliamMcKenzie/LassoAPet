-- World 3's base walls (QM, Oct 14): dark sand, a damp-sand band, light sand, with ragged edges:
-- each 8-stud column's dark band ends 16, 24 or 32 up and the damp band runs 8 or 16 above it
-- (a gentle random walk, so it reads as noise, not stripes). BaseWallMid takes DampSand's colours.
local W = workspace.World.Walls
local rng = Random.new(31415)
local walls = {}
for _, p in W:GetChildren() do
	if p.Name == "BaseWallLow" or p.Name == "BaseWall" or p.Name == "BaseWallMid" then table.insert(walls, p) end
end
-- group the parts of each wall run by its footprint (same X/Z line)
local runs = {}
for _, p in walls do
	local along = if p.Size.X > p.Size.Z then "X" else "Z"
	local k = string.format("%s %.1f %.1f %.1f", along, p.Position.X, p.Position.Z, along == "X" and p.Size.X or p.Size.Z)
	runs[k] = runs[k] or { along = along, parts = {}, template = nil }
	table.insert(runs[k].parts, p)
	if p.Name == "BaseWall" then runs[k].template = p end
	if p.Name == "BaseWallLow" then runs[k].low = p end
end
local made = 0
for _, r in runs do
	local light, low = r.template, r.low
	if not (light and low) then continue end
	local len = if r.along == "X" then light.Size.X else light.Size.Z
	local thick = if r.along == "X" then light.Size.Z else light.Size.X
	local startAt = (if r.along == "X" then light.Position.X else light.Position.Z) - len / 2
	local cols = math.floor(len / 8 + 0.5)
	local lowTop, band = 24, 8
	local heights = {}
	for c = 1, cols do
		if rng:NextNumber() < 0.35 then lowTop = math.clamp(lowTop + (if rng:NextNumber() < 0.5 then -8 else 8), 16, 32) end
		if rng:NextNumber() < 0.35 then band = if band == 8 then 16 else 8 end
		heights[c] = { lowTop, math.min(lowTop + band, 40) }
	end
	local tLight, tLow = light:Clone(), low:Clone()
	for _, p in r.parts do p:Destroy() end
	local function lay(template, name, c0, c1, y0, y1)
		if y1 <= y0 then return end
		local p = template:Clone()
		p.Name = name
		local w = (c1 - c0 + 1) * 8
		local mid = startAt + (c0 - 1) * 8 + w / 2
		p.Size = if r.along == "X" then Vector3.new(w, y1 - y0, thick) else Vector3.new(thick, y1 - y0, w)
		local pos = template.Position
		p.Position = if r.along == "X" then Vector3.new(mid, (y0 + y1) / 2, pos.Z) else Vector3.new(pos.X, (y0 + y1) / 2, mid)
		p.Parent = W
		made += 1
	end
	-- merge equal neighbouring columns
	local c = 1
	while c <= cols do
		local e = c
		while e < cols and heights[e + 1][1] == heights[c][1] and heights[e + 1][2] == heights[c][2] do e += 1 end
		local h = heights[c]
		lay(tLow, "BaseWallLow", c, e, 0, h[1])
		lay(tLow, "BaseWallMid", c, e, h[1], h[2])
		lay(tLight, "BaseWall", c, e, h[2], 48)
		c = e + 1
	end
	tLight:Destroy(); tLow:Destroy()
end
-- paint now so it shows in Edit (the game repaints from Config)
for _, p in W:GetChildren() do
	if p.Name == "BaseWallMid" then
		p.Color = Color3.fromRGB(233, 204, 140)
		for _, t in p:GetChildren() do if t.Name == "Checker" then t.Color3 = Color3.fromRGB(219, 189, 126) end end
	end
end
return made .. " wall parts"
