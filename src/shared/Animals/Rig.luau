-- Builds a rigged, studded Model from a declarative part list.
-- Parts with `plain = true` (eyes, pupils) skip the stud texture.
-- `class` picks the part class (default "Part", e.g. "WedgePart").
-- `hidden = true` makes an invisible, untextured part (used for bones).
-- `neon = true` makes a glowing, untextured part (the snake's slit pupils).
-- `metal = true` swaps the studs for the classic Weld surface (the Icebringer's armour).
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
-- The classic Weld surface's colour map, from the Resurface plugin (QM 17:31). It's an
-- opaque image meant for a MaterialVariant, so it's tinted with the part's colour and
-- tiled twice as wide as the studs, as Resurface tiles it (2 studs to the studs' 1).
local WELD = { image = "rbxassetid://10509843977", tile = 2 }

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

		local part = Instance.new(def.class or "Part")
		part.Name = def.name
		part.Size = def.size
		part.Color = def.color
		part.Material = if def.neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		if def.hidden then
			part.Transparency = 1
		end
		for _, face in ipairs(FACES) do
			part[face .. "Surface"] = Enum.SurfaceType.Smooth
		end
		-- Fine studs from a tiled texture; surface studs are fixed at 1 stud, too coarse here.
		if spec.studTexture and not def.plain and not def.hidden and not def.neon then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local texture = Instance.new("Texture")
				if def.metal then
					texture.Texture = WELD.image
					texture.Color3 = def.color
					texture.StudsPerTileU = spec.studTexture.tile * WELD.tile
					texture.StudsPerTileV = spec.studTexture.tile * WELD.tile
				else
					texture.Texture = spec.studTexture.image
					texture.StudsPerTileU = spec.studTexture.tile
					texture.StudsPerTileV = spec.studTexture.tile
				end
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

local function catmullRom(p0, p1, p2, p3, u)
	return 0.5 * (2 * p1 + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u)
end

-- Keyframe track from a generated model module (tools/bbmodel_to_luau.py):
-- { smooth = bool, keys = { { time, x, y, z }, ... } } -> x, y, z at time t.
-- Smooth tracks are Catmull-Rom through the neighbouring keys, like Blockbench.
function Rig.sample(track, t)
	local keys = track.keys
	local n = #keys
	if t <= keys[1][1] then
		return keys[1][2], keys[1][3], keys[1][4]
	end
	if t >= keys[n][1] then
		return keys[n][2], keys[n][3], keys[n][4]
	end
	local i = 1
	while keys[i + 1][1] < t do
		i += 1
	end
	local a, b = keys[i], keys[i + 1]
	local u = (t - a[1]) / (b[1] - a[1])
	-- Returned as three values, not a table: this runs for every bone of every
	-- animal every frame, and a table each time is garbage the collector stalls on.
	if track.smooth then
		local k0, k3 = keys[math.max(i - 1, 1)], keys[math.min(i + 2, n)]
		return catmullRom(k0[2], a[2], b[2], k3[2], u), catmullRom(k0[3], a[3], b[3], k3[3], u), catmullRom(k0[4], a[4], b[4], k3[4], u)
	end
	return a[2] + (b[2] - a[2]) * u, a[3] + (b[3] - a[3]) * u, a[4] + (b[4] - a[4]) * u
end

-- Builds a model from a generated data module ({ bones, parts, animations }).
-- Each bone becomes a hidden part at its pivot, driven by a Motor6D named
-- <bone>Bone; visible parts are welded to their bone. A bone's optional `rest`
-- rotation (a Blockbench group rotation) turns it and everything on it at rest.
-- Returns model, parts by name, motors by bone name, pivots by bone name.
--
-- Each kind is built block by block only once, as a template that's never shown;
-- every model after that is a copy of it (Clone), which is far quicker than making
-- hundreds of parts and textures one at a time, so a stampede animal, nest egg or
-- hatched pet doesn't stall the frame it's made in. `size` (optional) scales the
-- whole model up from its data (Model:ScaleTo), also once, on the template.
local templates = {} -- [data][name .. size] = { model, pivots }

function Rig.fromData(data, name, studTexture, size)
	size = size or 1
	local key = name .. " " .. size
	templates[data] = templates[data] or {}
	local template = templates[data][key]
	if not template then
		local model, _, _, pivots = Rig.buildFromData(data, name, studTexture)
		if size ~= 1 then
			model:ScaleTo(size)
		end
		template = { model = model, pivots = pivots }
		templates[data][key] = template
	end
	local model = template.model:Clone()
	local byName = {}
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			byName[part.Name] = part
		end
	end
	local bones = {}
	for _, bone in ipairs(data.bones) do
		local part = byName[bone.name .. "Bone"]
		bones[bone.name] = part and part:FindFirstChildOfClass("Motor6D")
	end
	return model, byName, bones, template.pivots
end

-- The block-by-block build behind Rig.fromData's templates.
function Rig.buildFromData(data, name, studTexture)
	local list = {}
	local pivots = {}
	for _, bone in ipairs(data.bones) do
		local parentPivot = bone.parent and pivots[bone.parent] or Vector3.zero
		pivots[bone.name] = bone.pivot
		table.insert(list, {
			name = bone.name .. "Bone",
			parent = bone.parent and bone.parent .. "Bone" or "Root",
			joint = CFrame.new(bone.pivot - parentPivot) * (bone.rest or CFrame.identity),
			size = Vector3.new(0.2, 0.2, 0.2),
			color = Color3.new(1, 1, 1),
			hidden = true,
			animated = true,
		})
	end
	for _, part in ipairs(data.parts) do
		table.insert(list, {
			name = part.name,
			parent = part.bone .. "Bone",
			joint = CFrame.new(-pivots[part.bone]) * part.cframe,
			size = part.size,
			color = part.color,
			class = part.class,
			plain = part.plain,
			neon = part.neon,
			metal = part.metal,
		})
	end
	local model, byName, motors = Rig.build({ name = name, studTexture = studTexture, parts = list })
	local bones = {}
	for _, bone in ipairs(data.bones) do
		bones[bone.name] = motors[bone.name .. "Bone"]
	end
	return model, byName, bones, pivots
end

return Rig
