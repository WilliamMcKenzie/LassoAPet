-- World 3 (QM, Oct 15): where one biome's wall (and cap) runs past the line into the next biome's,
-- the two overlap and z-fight; trim each piece to end at its own biome's lines.
local LINES = { -4336, -7968, -11808 } -- the biome lines (Config.Biomes lengths)
local function biomeRange(z)
	local near = 0
	for _, line in LINES do
		if z > line then return near, line end
		near = line
	end
	return near, -math.huge
end
local fixed = 0
for _, p in workspace.World.Walls:GetChildren() do
	if p:IsA("BasePart") and (p.Name == "Wall" or p.Name == "Cap") and p.Position.Z < 0 then
		local alongZ = p.Size.Z >= p.Size.X
		local axis = if alongZ then p.CFrame.LookVector else p.CFrame.RightVector
		local L = if alongZ then p.Size.Z else p.Size.X
		local a, b = p.Position - axis * L / 2, p.Position + axis * L / 2
		local near, far = biomeRange(p.Position.Z)
		local function clamp(e, other)
			local edge = if e.Z > near and near < 0 then near elseif e.Z < far then far else nil
			if not edge then return e end
			local t = (edge - other.Z) / (e.Z - other.Z) -- along other -> e
			return other + (e - other) * t
		end
		local a2, b2 = clamp(a, b), clamp(b, a)
		if (a2 - a).Magnitude > 0.01 or (b2 - b).Magnitude > 0.01 then
			local newL = (b2 - a2).Magnitude
			local rot = p.CFrame - p.Position
			p.Size = if alongZ then Vector3.new(p.Size.X, p.Size.Y, newL) else Vector3.new(newL, p.Size.Y, p.Size.Z)
			p.CFrame = rot + (a2 + b2) / 2
			fixed += 1
		end
	end
end
return fixed .. " wall and cap pieces trimmed to their biome lines"
