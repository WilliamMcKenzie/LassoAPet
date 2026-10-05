-- The egg you've picked in the inventory, in your hands (QM, Oct 5): every
-- character holding an egg Tool (Hatchery gives each one an invisible Handle, so
-- the arm comes up to hold it) gets that egg drawn at its Handle, small enough
-- to hold. Each client draws everyone's; nothing here is replicated.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)

local SCALE = 0.4 -- x a small egg, whatever the animal's size
local ABOVE_HAND = Vector3.new(0, 0.45, 0) -- the egg's centre over the Handle: it sits in the palm

local held = {} -- [tool] = egg model

local function eggKind(tool)
	local kind = tool:GetAttribute("EggKind")
	local special = kind and Config.SpecialEggs[kind]
	return if special then special.Pet else kind
end

local function build(tool)
	local ok, egg = pcall(Egg.new, eggKind(tool))
	if not ok then
		return nil
	end
	local model = egg.model
	model:ScaleTo(SCALE)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
		end
	end
	model.Parent = workspace
	return model
end

RunService.RenderStepped:Connect(function()
	local seen = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local tool = character and character:FindFirstChildOfClass("Tool")
		local handle = tool and tool:GetAttribute("EggKind") and tool:FindFirstChild("Handle")
		if handle then
			seen[tool] = true
			if held[tool] == nil then
				held[tool] = build(tool) or false
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if held[tool] and root then
				-- Upright, facing the way the character faces (the Handle itself points
				-- along the arm).
				held[tool]:PivotTo(CFrame.new(handle.Position + ABOVE_HAND) * root.CFrame.Rotation)
			end
		end
	end
	for tool, model in held do
		if not seen[tool] then
			if model then
				model:Destroy()
			end
			held[tool] = nil
		end
	end
end)
