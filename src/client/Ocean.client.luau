-- Under the sea: while the camera is in a biome with a Haze entry (the Ocean),
-- the distance fades into blue fog, the picture takes a blue tint and bubbles
-- drift up from the sea floor round what you're looking at. Out of it (the
-- other biomes, home) everything fades back. Client-only, like the rest of
-- the ride's effects.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local FOG_START, FOG_END = 30, 300 -- studs, under the sea
local BUBBLE_LIFE = { 3, 5 } -- seconds
local BUBBLE_RISE = { 5, 9 } -- studs a second
local BUBBLE_SIZE = { 0.5, 1.6 }
local SPREAD_X, SPREAD_Z = 52, 70 -- studs round the point the camera looks at

local camera = workspace.CurrentCamera
local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
local dry = {
	FogColor = Lighting.FogColor,
	FogStart = Lighting.FogStart,
	FogEnd = Lighting.FogEnd,
	Tint = if correction then correction.TintColor else Color3.new(1, 1, 1),
}

local rng = Random.new()
local folder = Instance.new("Folder")
folder.Name = "Bubbles"
folder.Parent = workspace
local live, spare = {}, {}

local function newBubble()
	local part = table.remove(spare)
	if not part then
		part = Instance.new("Part")
		part.Name = "Bubble"
		part.Shape = Enum.PartType.Ball
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Glass
		part.Color = Color3.fromRGB(225, 244, 255)
		part.Transparency = 0.35
		part.Reflectance = 0.25
	end
	part.Parent = folder
	return part
end

local current -- the Haze entry we're in, or nil
local tweens = {}

local function fade(haze)
	for _, t in tweens do
		t:Cancel()
	end
	local info = TweenInfo.new((haze or current).FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tweens = {
		TweenService:Create(Lighting, info, {
			FogColor = if haze then haze.Color else dry.FogColor,
			FogStart = if haze then FOG_START else dry.FogStart,
			FogEnd = if haze then FOG_END else dry.FogEnd,
		}),
	}
	if correction then
		table.insert(tweens, TweenService:Create(correction, info, { TintColor = if haze then haze.Tint else dry.Tint }))
	end
	for _, t in tweens do
		t:Play()
	end
end

-- Where the camera's view meets the sea floor (y = 0), or straight below it.
local function lookPoint()
	local cf = camera.CFrame
	local look = cf.LookVector
	if look.Y < -0.05 then
		local p = cf.Position + look * (-cf.Position.Y / look.Y)
		if (p - cf.Position).Magnitude < 400 then
			return p
		end
	end
	return Vector3.new(cf.Position.X, 0, cf.Position.Z)
end

local owed = 0
RunService.RenderStepped:Connect(function(dt)
	local at = lookPoint()
	local haze = Config.Biomes[WorldColors.biomeAt(at.Z)].Haze
	if at.Z > 0 then
		haze = nil -- the home base counts as the first biome; never under the sea
	end
	if haze ~= current then
		fade(haze)
		current = haze
	end

	if current then
		owed += current.Bubbles * dt
		while owed >= 1 do
			owed -= 1
			local part = newBubble()
			local size = rng:NextNumber(BUBBLE_SIZE[1], BUBBLE_SIZE[2])
			part.Size = Vector3.new(size, size, size)
			local x = math.clamp(at.X + rng:NextNumber(-SPREAD_X, SPREAD_X), -Config.CourseHalfWidth, Config.CourseHalfWidth)
			table.insert(live, {
				part = part,
				x = x,
				z = at.Z + rng:NextNumber(-SPREAD_Z, SPREAD_Z),
				y = rng:NextNumber(0, 6),
				age = 0,
				life = rng:NextNumber(BUBBLE_LIFE[1], BUBBLE_LIFE[2]),
				rise = rng:NextNumber(BUBBLE_RISE[1], BUBBLE_RISE[2]),
				phase = rng:NextNumber(0, math.pi * 2),
			})
		end
	end

	for i = #live, 1, -1 do
		local b = live[i]
		b.age += dt
		if b.age >= b.life then
			b.part.Parent = nil
			table.insert(spare, b.part)
			live[i] = live[#live]
			live[#live] = nil
		else
			b.y += b.rise * dt
			local wobble = math.sin(b.age * 3 + b.phase) * 0.6
			b.part.CFrame = CFrame.new(b.x + wobble, b.y, b.z)
			-- pop in, fade out over the last second
			b.part.Transparency = 0.35 + 0.65 * math.max(1 - b.age / 0.3, b.age - (b.life - 1), 0)
		end
	end
end)
