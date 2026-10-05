-- Manually invoked, edit-mode-only thumbnail poses. Never required by gameplay.
-- local renders = require(game.ReplicatedStorage.Shared.Studio.RiderRenders)
-- renders.create(); renders.view("Horse"); renders.view("Cactus"); renders.cleanup()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Selection = game:GetService("Selection")
local Animals = script.Parent.Parent.Animals

local Renders = {}
local STAGE = "RiderRenderStage"
local ORIGIN = Vector3.new(20000, 1000, 0)
local ROPE_COLOR = Color3.fromRGB(222, 184, 120)
local CAMERA_DIRECTION = Vector3.new(-0.34, 0.79, 0.51).Unit

local function editOnly()
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Rider renders are only available in Studio edit mode")
end

local function part(parent, name, size, cf, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Motor transforms don't advance in edit mode. Bake the actual game's pose once.
local function bakeAnimal(animal)
	local known = { [animal.model.PrimaryPart] = true }
	local joints = {}
	for _, item in animal.model:GetDescendants() do
		if item:IsA("JointInstance") then table.insert(joints, item) end
	end
	for _ = 1, #joints do
		local advanced = false
		for _, joint in joints do
			if known[joint.Part0] and not known[joint.Part1] then
				local transform = if joint:IsA("Motor6D") then joint.Transform else CFrame.identity
				joint.Part1.CFrame = joint.Part0.CFrame * joint.C0 * transform * joint.C1:Inverse()
				known[joint.Part1], advanced = true, true
			end
		end
		if not advanced then break end
	end
	for _, item in animal.model:GetDescendants() do
		if item:IsA("BasePart") then item.Anchored = true end
	end
end

local function ropeSegment(parent, a, b)
	local delta = b - a
	local p = part(parent, "Rope", Vector3.new(delta.Magnitude, 0.15, 0.15),
		CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), ROPE_COLOR)
	p.Shape = Enum.PartType.Cylinder
end

local function makeRider(parent, seat)
	local description = Instance.new("HumanoidDescription")
	description.HairAccessory = "63690008" -- Pal Hair
	description.Shirt = 144076358 -- Blue and Black Motorcycle Shirt
	description.Pants = 144076760 -- Dark Green Jeans
	description.Face = 406001308 -- Roblox's classic Smug face
	local skin = Color3.fromRGB(245, 205, 148)
	description.HeadColor, description.LeftArmColor, description.RightArmColor = skin, skin, skin
	description.TorsoColor, description.LeftLegColor, description.RightLegColor = skin, skin, skin
	local rider = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6)
	description:Destroy()
	rider.Name = "BaconHair"
	rider.Parent = parent
	rider.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local scale = 1.45
	rider:ScaleTo(scale)
	local head, torso = rider.Head, rider.Torso
	local accessories = {}
	for _, item in rider:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
		elseif item:IsA("Weld") and item.Name == "AccessoryWeld" then
			table.insert(accessories, { handle = item.Part0, body = item.Part1, c0 = item.C0, c1 = item.C1 })
		end
	end
	for _, item in rider:GetDescendants() do
		if item:IsA("JointInstance") or item:IsA("BaseScript") then item:Destroy() end
	end
	local hips = CFrame.new(seat.Position)
	torso.CFrame = hips * CFrame.new(0, scale, 0) * CFrame.Angles(0, math.rad(35), 0)
	head.CFrame = torso.CFrame * CFrame.new(0, 1.5 * scale, 0)
		* CFrame.Angles(0, math.rad(110), 0) * CFrame.Angles(math.rad(43), 0, 0)
	rider.HumanoidRootPart.CFrame = torso.CFrame
	rider["Left Leg"].CFrame = hips * CFrame.new(-0.55 * scale, 0, 0)
		* CFrame.Angles(math.rad(30), 0, math.rad(-45)) * CFrame.new(0, -scale, 0)
	rider["Right Leg"].CFrame = hips * CFrame.new(0.55 * scale, 0, 0)
		* CFrame.Angles(math.rad(30), 0, math.rad(45)) * CFrame.new(0, -scale, 0)
	rider["Left Arm"].CFrame = torso.CFrame * CFrame.new(-1.5 * scale, 0.65 * scale, 0)
		* CFrame.Angles(math.rad(25), 0, math.rad(-20)) * CFrame.new(0, -0.65 * scale, 0)
	local arm = rider["Right Arm"]
	arm.CFrame = torso.CFrame * CFrame.new(1.5 * scale, 0.65 * scale, 0)
		* CFrame.Angles(math.rad(15), 0, math.rad(155)) * CFrame.new(0, -0.65 * scale, 0)
	for _, accessory in accessories do
		accessory.handle.CFrame = accessory.body.CFrame * accessory.c1 * accessory.c0:Inverse()
	end
	local hand = (arm.CFrame * CFrame.new(0, -0.95 * scale, 0)).Position
	local center = hand + Vector3.new(0.6, 1.65, -0.4)
	local loop = Instance.new("Folder")
	loop.Name, loop.Parent = "OverheadLasso", parent
	local basis = CFrame.new(center) * CFrame.Angles(math.rad(8), 0, math.rad(-6))
	local points = {}
	for i = 0, 47 do
		local angle = i / 48 * math.pi * 2
		points[i + 1] = (basis * CFrame.new(math.cos(angle) * 2.9, 0, math.sin(angle) * 2.9)).Position
	end
	local closest = points[1]
	for i, point in points do
		ropeSegment(loop, point, points[i % #points + 1])
		if (point - hand).Magnitude < (closest - hand).Magnitude then closest = point end
	end
	ropeSegment(loop, hand, closest)
	return rider
end

function Renders.cleanup()
	editOnly()
	local stage = workspace:FindFirstChild(STAGE)
	if not stage then return end
	local camera = workspace.CurrentCamera
	camera.CFrame, camera.Focus = stage:GetAttribute("CameraCFrame"), stage:GetAttribute("CameraFocus")
	camera.FieldOfView = stage:GetAttribute("CameraFOV")
	local selected = {}
	for _, item in stage.PreviousSelection:GetChildren() do
		if item.Value and item.Value.Parent then table.insert(selected, item.Value) end
	end
	Selection:Set(selected)
	stage:Destroy()
end

function Renders.create()
	editOnly()
	Renders.cleanup()
	local stage = Instance.new("Folder")
	stage.Name = STAGE
	local camera = workspace.CurrentCamera
	stage:SetAttribute("CameraCFrame", camera.CFrame)
	stage:SetAttribute("CameraFocus", camera.Focus)
	stage:SetAttribute("CameraFOV", camera.FieldOfView)
	local selected = Instance.new("Folder")
	selected.Name, selected.Parent = "PreviousSelection", stage
	for _, item in Selection:Get() do
		local reference = Instance.new("ObjectValue")
		reference.Value, reference.Parent = item, selected
	end
	stage.Parent = workspace
	Selection:Set({})
	local ok, err = pcall(function()
		for i, kind in { "Horse", "Cactus" } do
			local scene = Instance.new("Model")
			scene.Name, scene.Parent = kind, stage
			local animal = require(Animals[kind]).new()
			animal.model.Parent = scene
			animal.model.PrimaryPart.CFrame = CFrame.new(ORIGIN + Vector3.new((i - 1) * 100, 0, 0))
			animal.speed = 36
			animal:update(if kind == "Horse" then 0.22 else 0.1, 36, 0)
			bakeAnimal(animal)
			makeRider(scene, animal:getSeatCFrame())
		end
		ContentProvider:PreloadAsync({ stage })
	end)
	if not ok then Renders.cleanup(); error(err) end
	return "Created Horse and Cactus poses in Workspace." .. STAGE
end

function Renders.view(kind, backdropColor)
	editOnly()
	assert(kind == "Horse" or kind == "Cactus", "Choose Horse or Cactus")
	local stage = assert(workspace:FindFirstChild(STAGE), "Call create() first")
	local scene = stage[kind]
	local box, size = scene:GetBoundingBox()
	local target = box.Position
	local camera = workspace.CurrentCamera
	camera.FieldOfView = 32
	local rotation = CFrame.lookAt(target + CAMERA_DIRECTION, target).Rotation
	local tangent = math.tan(math.rad(camera.FieldOfView / 2)) * 0.84
	local aspect = camera.ViewportSize.X / camera.ViewportSize.Y
	local distance = 1
	for _, item in scene:GetDescendants() do
		if item:IsA("BasePart") and item.Transparency < 1 then
			for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do
				local corner = item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
				local p = rotation:VectorToObjectSpace(corner - target)
				distance = math.max(distance, math.abs(p.Y) / tangent + p.Z, math.abs(p.X) / (tangent * aspect) + p.Z)
			end end end
		end
	end
	camera.CFrame = CFrame.lookAt(target + CAMERA_DIRECTION * distance, target)
	camera.Focus = CFrame.new(target)
	local backdrop = stage:FindFirstChild("Backdrop")
	if not backdrop then
		backdrop = part(stage, "Backdrop", Vector3.new(400, 400, 1), CFrame.identity, Color3.new(1, 1, 1))
		backdrop.Material = Enum.Material.Neon
		backdrop.CastShadow = false
	end
	backdrop.Color = backdropColor or Color3.new(1, 1, 1)
	backdrop.CFrame = CFrame.new(target - CAMERA_DIRECTION * 40) * camera.CFrame.Rotation
	Selection:Set({})
	return { kind = kind, camera = tostring(camera.CFrame), size = tostring(size) }
end

return Renders
