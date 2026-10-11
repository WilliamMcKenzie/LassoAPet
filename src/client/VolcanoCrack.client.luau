-- The big lava crack at the volcano's end (QM, Oct 10-11): a hole in the floor glowing
-- red to yellow, drawn with ViewportStencil (Shared/ViewportStencil) so the floor isn't
-- cut. Later it's a geyser that launches you on to the next biome; for now it's only
-- there. Config.VolcanoCrack says where; the Model (CrackMask and CrackInside, imported
-- from design/volcano/VolcanoCrack.gltf) waits in ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ViewportStencil = require(ReplicatedStorage.Shared.ViewportStencil)

local settings = Config.VolcanoCrack
if not settings then
	return
end
local template = ReplicatedStorage:WaitForChild(settings.Model, 30)
if not template then
	warn("VolcanoCrack: no " .. settings.Model .. " model in ReplicatedStorage (import design/volcano/VolcanoCrack.gltf)")
	return
end

local model = template:Clone()
for _, part in model:GetDescendants() do
	if part:IsA("BasePart") then
		part.Anchored = true
		part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
		part.Color = Color3.new(1, 1, 1) -- (the mesh's own vertex colours show as they are)
	end
end
-- The stencil sets the model's top flush with the floor: the mask's top is the floor.
model.PrimaryPart = model:FindFirstChild("CrackMask", true) or model.PrimaryPart

-- Where the volcano ends (the finish line was there before the Jurassic came after it).
local volcanoEnd = -Config.CourseLength
local edge = 0
for _, biome in Config.Biomes do
	edge -= biome.Length
	if biome.Name == "Volcano" then
		volcanoEnd = edge
		break
	end
end
local z = volcanoEnd + Config.FinishFromEnd + settings.FromFinish
ViewportStencil.new(model, CFrame.new(0, 0, z) * CFrame.Angles(0, math.rad(settings.Yaw or 0), 0), {
	ambient = Color3.new(1, 1, 1), -- lit evenly: it glows
	lightInfluence = 0,
	brightness = settings.Brightness or 1,
	maxDistance = settings.MaxDistance or 1000,
})
