-- Manual edit-mode photo set; gameplay never imports this module.
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local ContentProvider = game:GetService("ContentProvider")
local Config = require(script.Parent.Parent.Config)
local Desert = Config.Biomes[2]
local LENGTH = 760
local START_Z = -Config.Biomes[1].Length

local Diorama = {}
local NAME = "DesertDiorama"
local ORIGIN = Vector3.new(30000, 1000, 4000)

local function editOnly()
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Desert diorama requires Studio edit mode")
end

function Diorama.cleanup()
	editOnly()
	local stage = workspace:FindFirstChild(NAME)
	if not stage then return end
	assert(stage:GetAttribute("PhotoStage"), "An unrelated DesertDiorama already exists")
	local camera = workspace.CurrentCamera
	camera.CFrame, camera.Focus = stage:GetAttribute("PreviousCamera"), stage:GetAttribute("PreviousFocus")
	camera.FieldOfView = stage:GetAttribute("PreviousFOV")
	local selected = {}
	for _, reference in stage.PreviousSelection:GetChildren() do
		if reference.Value and reference.Value.Parent then table.insert(selected, reference.Value) end
	end
	Selection:Set(selected)
	stage:Destroy()
end

function Diorama.view()
	editOnly()
	assert(workspace:FindFirstChild(NAME), "Call create() first")
	local camera = workspace.CurrentCamera
	camera.FieldOfView = 60
	-- Level camera puts the open-sky horizon at the middle of the frame.
	camera.CFrame = CFrame.lookAt(ORIGIN + Vector3.new(0, 8, -100), ORIGIN + Vector3.new(0, 8, -300))
	camera.Focus = CFrame.new(ORIGIN + Vector3.new(0, 8, -300))
	Selection:Set({})
end

function Diorama.create()
	editOnly()
	Diorama.cleanup()
	local world = workspace:FindFirstChild("World")
	assert(world and world:FindFirstChild("Ground") and world:FindFirstChild("Obstacles"), "World desert assets are missing")
	local stage = Instance.new("Folder")
	stage.Name = NAME
	stage:SetAttribute("PhotoStage", true)
	stage:SetAttribute("Origin", ORIGIN)
	local camera = workspace.CurrentCamera
	stage:SetAttribute("PreviousCamera", camera.CFrame)
	stage:SetAttribute("PreviousFocus", camera.Focus)
	stage:SetAttribute("PreviousFOV", camera.FieldOfView)
	local selected = Instance.new("Folder")
	selected.Name, selected.Parent = "PreviousSelection", stage
	for _, item in Selection:Get() do
		local reference = Instance.new("ObjectValue")
		reference.Value, reference.Parent = item, selected
	end
	stage.Parent = workspace
	local ok, err = pcall(function()
		local ground = Instance.new("Folder")
		ground.Name, ground.Parent = "Ground", stage
		local decor = Instance.new("Folder")
		decor.Name, decor.Parent = "Decor", stage
		local template
		local function paint(part)
			local colors = if part.Name == "Ground" then Desert.GroundColors else Desert.Patches[part.Name]
			part.Color = world:GetAttribute("Desert" .. part.Name .. "A") or colors[1]
			for _, texture in part:GetChildren() do
				if texture:IsA("Texture") and texture.Name == "Checker" then
					texture.Color3 = world:GetAttribute("Desert" .. part.Name .. "B") or colors[2]
				end
			end
			part.Anchored = true
		end
		-- Three copies of the first desert section, preserving its raised stone patches.
		-- Never clone walls, spawns, nests, scripts, or the playable World itself.
		for _, source in world.Ground:GetChildren() do
			if not source:IsA("BasePart") then continue end
			local lo = math.max(source.Position.Z - source.Size.Z / 2, START_Z - LENGTH)
			local hi = math.min(source.Position.Z + source.Size.Z / 2, START_Z)
			if hi > lo then
				if source.Name == "Ground" then template = template or source end
				for column = -1, 1 do
					local part = source:Clone()
					paint(part)
					part.Size = Vector3.new(source.Size.X, source.Size.Y, hi - lo)
					part.CFrame = CFrame.new(source.Position.X, source.Position.Y, (lo + hi) / 2)
					part.CFrame += ORIGIN + Vector3.new(column * 112, 0, -START_Z)
					part.Parent = ground
				end
			end
		end
		assert(template, "No desert sand found")
		local function fill(x, z, width, depth)
			local part = template:Clone()
			paint(part)
			part.Size = Vector3.new(width, 2, depth)
			part.CFrame = CFrame.new(ORIGIN + Vector3.new(x, -1, z))
			part.Parent = ground
		end
		-- Continue the same sand to the horizon without stretching the textures.
		for _, side in { -1, 1 } do
			for _, z in { -1024, 1024 } do fill(side * 1108, z, 1880, 2048) end
		end
		fill(0, -(2048 + LENGTH) / 2, 336, 2048 - LENGTH)
		fill(0, 1024, 336, 2048)
		local templates = {}
		for _, source in world.Obstacles:GetChildren() do
			if source:IsA("Model") then
				local z = source:GetPivot().Position.Z
				if z < START_Z and z > START_Z - LENGTH then templates[source.Name] = templates[source.Name] or source end
			end
		end
		for _, placement in {
			{ "Cactus", -30, -150 }, { "Sandstone", -23, -143 }, { "SandBoulder", -43, -162 },
			{ "Cactus", 30, -156 }, { "Cactus", 38, -164 }, { "Sandstone", 23, -168 },
			{ "Cactus", -56, -231 }, { "Sandstone", -48, -244 },
			{ "Cactus", 70, -272 }, { "SandBoulderCarved", 78, -285 }, { "Sandstone", -9, -345 },
		} do
			local source = assert(templates[placement[1]], "Missing desert prop: " .. placement[1])
			local clone = source:Clone()
			local pivot = clone:GetPivot()
			local x, z, top = placement[2], placement[3], 0
			for _, part in ground:GetChildren() do
				local position = part.Position - ORIGIN
				if math.abs(position.X - x) < part.Size.X / 2 and math.abs(position.Z - z) < part.Size.Z / 2 then
					top = position.Y + part.Size.Y / 2
					break
				end
			end
			local sourceTop = 0
			for _, part in world.Ground:GetChildren() do
				if part:IsA("BasePart") and math.abs(part.Position.X - pivot.Position.X) < part.Size.X / 2
					and math.abs(part.Position.Z - pivot.Position.Z) < part.Size.Z / 2 then
					sourceTop = part.Position.Y + part.Size.Y / 2
					break
				end
			end
			clone:PivotTo(CFrame.new(ORIGIN + Vector3.new(x, pivot.Position.Y - sourceTop + top, z)) * pivot.Rotation)
			for _, part in clone:GetDescendants() do
				if part:IsA("BasePart") then part.Anchored = true end
			end
			clone.Parent = decor
		end
		ContentProvider:PreloadAsync({ stage })
		Diorama.view()
	end)
	if not ok then Diorama.cleanup(); error(err) end
	return "Created Workspace.DesertDiorama at " .. tostring(ORIGIN)
end

return Diorama
