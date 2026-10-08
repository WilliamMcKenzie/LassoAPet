-- The bigger home base (QM, Oct 8: pens grow faster, to 144 studs a side at the
-- Godlands): run in Studio's command bar (Edit, not Play) on the place. Resizes the
-- home floor and its back, side and front walls (and their caps) to W x D, as
-- tools/home_base.py does to src/world/World.rbxmx; the pens themselves come from
-- tools/pens.py through penpush.py.
--
--   MODE = "apply": resize (re-running is fine: it puts everything back first)
--   MODE = "undo":  put the old base back
--
-- Keep W, D the same as tools/pens.py HALF_W, DEPTH (Config.HomeHalfWidth, HomeDepth).
-- Every resized part keeps its old CFrame/Size in "BaseCF"/"BaseSize".

local MODE = "apply"
local W, D, CORRIDOR = 384, 200, 56

local world = workspace.World
local parts = {}
for _, part in world.Ground:GetChildren() do
	table.insert(parts, part)
end
for _, part in world.Walls:GetChildren() do
	table.insert(parts, part)
end

-- Put everything back first.
for _, part in parts do
	if part:IsA("BasePart") and part:GetAttribute("BaseCF") then
		part.Size, part.CFrame = part:GetAttribute("BaseSize"), part:GetAttribute("BaseCF")
		part:SetAttribute("BaseCF", nil)
		part:SetAttribute("BaseSize", nil)
	end
end
if MODE == "undo" then
	return "undone"
end

-- Which piece of the base a part is (from where it stands now), and where it goes.
local function target(part)
	local p, s = part.Position, part.Size
	local wall, cap = part.Name == "Wall", part.Name == "Cap"
	if part.Parent == world.Ground then
		if math.abs(p.X) < 1 and p.Z > 0 and s.X > 200 then
			return Vector3.new(0, -1, (D + 8) / 2), Vector3.new(2 * W, 2, D + 8) -- the floor
		end
		return nil
	end
	if math.abs(p.X) < 1 and p.Z > 100 then -- the back wall
		if wall then
			return Vector3.new(0, 24, D + 4), Vector3.new(2 * W + 16, 48, 8)
		elseif cap then
			return Vector3.new(0, 49, D + 3), Vector3.new(2 * W + 16, 2, 10)
		end
	elseif math.abs(p.X) > 100 and p.Z > 0 and s.Z > 50 then -- a side wall
		local side = math.sign(p.X)
		if wall then
			return Vector3.new(side * (W + 4), 24, D / 2 - 4), Vector3.new(8, 48, D + 8)
		elseif cap then
			return Vector3.new(side * (W + 3), 49, D / 2), Vector3.new(10, 2, D - 4)
		end
	elseif math.abs(p.X) > CORRIDOR and p.Z > -6 and p.Z < 0 and s.Z <= 10 then -- a front wall, by the start line
		local side = math.sign(p.X)
		if wall then
			return Vector3.new(side * (W + CORRIDOR) / 2, 24, -4), Vector3.new(W - CORRIDOR, 48, 8)
		elseif cap then
			return Vector3.new(side * (W + CORRIDOR + 6) / 2, 49, -3), Vector3.new(W - CORRIDOR + 10, 2, 10)
		end
	end
	return nil
end

local done = 0
for _, part in parts do
	if part:IsA("BasePart") then
		local at, size = target(part)
		if at then
			part:SetAttribute("BaseCF", part.CFrame)
			part:SetAttribute("BaseSize", part.Size)
			part.Size, part.CFrame = size, CFrame.new(at)
			done += 1
		end
	end
end
return "base resized: " .. done .. " parts (expected 11)"
