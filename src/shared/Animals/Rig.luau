-- Builds a rigged, studded Model from a declarative part list.
-- Parts with `plain = true` (eyes, pupils) skip the stud texture.
--
-- Every part hangs off a joint in its parent's space:
--   joint  = CFrame of the joint relative to the parent part's center (C0)
--   offset = where this part's center sits relative to that joint (C1 = -offset)
-- Parts with `animated = true` get a Motor6D named after the part, driven
-- through Motor6D.Transform. Everything else is welded.
--
-- The model faces -Z. Root is an anchored, invisible part at ground level and
-- is the PrimaryPart: move the animal by setting Root.CFrame.

local Rig = {}

local FACES = { "Top", "Bottom", "Front", "Back", "Left", "Right" }

function Rig.build(spec)
	local model = Instance.new("Model")
	model.Name = spec.name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	local parts = { Root = root }
	local motors = {}

	for _, def in ipairs(spec.parts) do
		local parent = parts[def.parent]
		assert(parent, spec.name .. ": " .. def.name .. " has unknown parent " .. tostring(def.parent))

		local part = Instance.new("Part")
		part.Name = def.name
		part.Size = def.size
		part.Color = def.color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		for _, face in ipairs(FACES) do
			part[face .. "Surface"] = Enum.SurfaceType.Smooth
		end
		-- Fine studs from a tiled texture; surface studs are fixed at 1 stud, too coarse here.
		if spec.studTexture and not def.plain then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local texture = Instance.new("Texture")
				texture.Texture = spec.studTexture.image
				texture.StudsPerTileU = spec.studTexture.tile
				texture.StudsPerTileV = spec.studTexture.tile
				texture.Face = face
				texture.Parent = part
			end
		end

		local c0 = def.joint or CFrame.new()
		local c1 = CFrame.new(-(def.offset or Vector3.new()))
		part.CFrame = parent.CFrame * c0 * c1:Inverse()

		local joint = Instance.new(def.animated and "Motor6D" or "Weld")
		joint.Name = def.name
		joint.Part0 = parent
		joint.Part1 = part
		joint.C0 = c0
		joint.C1 = c1
		joint.Parent = part
		if def.animated then
			motors[def.name] = joint
		end

		part.Parent = model
		parts[def.name] = part
	end

	return model, parts, motors
end

return Rig
