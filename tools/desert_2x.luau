-- Paste into Studio's command bar in Edit mode (not Play). Makes the Desert 2x as
-- long, for QM's Oct 8 test; it goes with Config Biomes.Desert.Length = 4560.
-- Everything in Workspace.World past the Desert's far end (z -3040: the Snow, the
-- Ocean and what's left of the Godlands) moves 2280 studs further out, and the
-- Desert's floor, walls, obstacles and nests are copied into the gap, mirrored left
-- to right with each piece turned round, so the second half isn't the first again.
-- Set UNDO = true and run it again to put the map back as it was.
local UNDO = false

local NEAR, FAR, ADD = -760, -3040, -2280 -- the Desert's near and far edges today, and how far the rest moves
local world = workspace.World
local spin = CFrame.Angles(0, math.pi, 0)

local function centre(item)
	if item:IsA("Model") then
		return (item:GetBoundingBox()).Position
	elseif item:IsA("BasePart") then
		return item.Position
	end
	return nil
end

local function move(item, dz)
	if item:IsA("Model") then
		item:PivotTo(item:GetPivot() + Vector3.new(0, 0, dz))
	else
		item.CFrame += Vector3.new(0, 0, dz)
	end
end

-- Puts the copy at (-x, y, z + ADD), turned round about its own middle.
local function mirror(item, c)
	local to = CFrame.new(-c.X, c.Y, c.Z + ADD) * spin
	if item:IsA("Model") then
		item:PivotTo(to * (CFrame.new(c):Inverse() * item:GetPivot()))
	else
		item.CFrame = to * item.CFrame.Rotation
	end
end

local moved, copied, removed = 0, 0, 0
if UNDO then
	assert(world:GetAttribute("Desert2x"), "The Desert isn't 2x: nothing to undo")
	for _, folder in world:GetChildren() do
		for _, item in folder:IsA("Folder") and folder:GetChildren() or {} do
			if item:GetAttribute("Desert2xCopy") then
				item:Destroy()
				removed += 1
			elseif item:GetAttribute("Desert2xMoved") then
				move(item, -ADD)
				item:SetAttribute("Desert2xMoved", nil)
				moved += 1
			end
		end
	end
	world:SetAttribute("Desert2x", nil)
	print(string.format("[Desert2x] undone: %d moved back, %d copies removed", moved, removed))
else
	assert(not world:GetAttribute("Desert2x"), "The Desert is already 2x")
	for _, folder in world:GetChildren() do
		local here = { moved = 0, copied = 0 }
		for _, item in folder:IsA("Folder") and folder:GetChildren() or {} do -- (a snapshot: the copies aren't seen again)
			local c = centre(item)
			if c and c.Z < FAR then
				move(item, ADD)
				item:SetAttribute("Desert2xMoved", true)
				here.moved += 1
			elseif c and c.Z < NEAR then
				local copy = item:Clone()
				mirror(copy, c)
				copy:SetAttribute("Desert2xCopy", true)
				copy.Parent = folder
				here.copied += 1
			end
		end
		if here.moved + here.copied > 0 then
			print(string.format("[Desert2x] %s: %d moved out, %d desert pieces copied", folder.Name, here.moved, here.copied))
		end
		moved += here.moved
		copied += here.copied
	end
	world:SetAttribute("Desert2x", true)
	print(string.format("[Desert2x] done: %d moved out, %d copied", moved, copied))
end

-- Anything else in the Workspace past the Desert that this didn't touch: check it by hand.
for _, item in workspace:GetChildren() do
	if item ~= world and item.Name ~= "Pens" and not item:IsA("Terrain") and not item:IsA("Camera") then
		local c = centre(item)
		if c and c.Z < FAR then
			warn("[Desert2x] not moved, past the Desert: " .. item:GetFullName())
		end
	end
end
