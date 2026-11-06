-- Breakable barriers (Config.BreakGates, QM Oct 9): a sheet at each biome line you've
-- never ridden through, just its colour fading up (no card). Ride through one and it
-- shatters, gone for good for you (BreakGate: the server saves "GatesBroken", the last
-- biome whose barrier you broke). Nothing stops you at them. Each sheet runs across the
-- corridor, the biome's GateColor at the floor fading to clear GateHeight studs up.
-- (The old locked gates, Config.Gates, are gone: QM, Nov 6.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Sounds = require(script.Parent.Sounds)

local player = Players.LocalPlayer
local SHARDS_X, SHARDS_Y = 14, 7 -- the gate breaks into this many pieces
local SHARD_TIME = 1.6 -- seconds the pieces fly before they're gone
local PIXELS_PER_STUD = 20

local gates = {} -- [biome index] = { part, fades }

local function build(i)
	local width, height = WorldColors.halfWidth(WorldColors.biomeStart(i)) * 2, Config.GateHeight
	local part = Instance.new("Part")
	part.Name = "Gate" .. i
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(width, height, 0.2)
	part.CFrame = CFrame.new(0, height / 2, WorldColors.biomeStart(i))

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- faces home (+z), the way you ride up to it
	gui.CanvasSize = Vector2.new(width, height) * PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Adornee = part

	local sheet = Instance.new("Frame")
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BorderSizePixel = 0
	local color = Config.Biomes[i].GateColor or Config.GateColor -- each biome's own (QM)
	sheet.BackgroundColor3 = color
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90 -- top (0) to bottom (1)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.75),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	gradient.Parent = sheet
	sheet.Parent = gui

	-- (the part goes in first and carries its own sheet: a sheet adorned from PlayerGui
	-- stopped drawing on these parts, Oct 5)
	part.Parent = workspace
	gui.Adornee = nil
	gui.Parent = part
	gui.Enabled = not player:GetAttribute("EventRun")
	gates[i] = { part = part, gui = gui }
end

-- The gate bursts into pieces flung on into the biome, tumbling and fading.
local function shatter(i)
	-- It shatters like glass (QM, Oct 7: Mirror Break), then a little jingle (egg_hatch's) (QM).
	Sounds.play("gate_break", 0.6) -- (a bit quieter, the reward a bit louder: QM, Oct 9; were 0.8, 0.6)
	Sounds.play("egg_hatch", 1.2) -- (1.5x louder, with the shatter: QM)
	local width, height = WorldColors.halfWidth(WorldColors.biomeStart(i)) * 2, Config.GateHeight
	local z = WorldColors.biomeStart(i)
	local w, h = width / SHARDS_X, height / SHARDS_Y
	local rng = Random.new()
	local shards = {}
	for gx = 1, SHARDS_X do
		for gy = 1, SHARDS_Y do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Material = Enum.Material.Neon
			part.Color = if rng:NextNumber() < 0.3 then Color3.new(1, 1, 1) else Config.Biomes[i].GateColor or Config.GateColor
			part.Transparency = 0.15 + 0.5 * (gy - 1) / SHARDS_Y -- clearer higher up, like the sheet
			part.Size = Vector3.new(w * rng:NextNumber(0.6, 1), h * rng:NextNumber(0.6, 1), 0.3)
			local at = Vector3.new(-width / 2 + (gx - 0.5) * w, (gy - 0.5) * h, z)
			part.CFrame = CFrame.new(at)
			part.Parent = workspace
			table.insert(shards, {
				part = part,
				start = part.Transparency,
				velocity = Vector3.new((at.X / width) * rng:NextNumber(20, 40), rng:NextNumber(8, 30), -rng:NextNumber(25, 60)),
				spin = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)),
			})
		end
	end
	local t = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		t += dt
		for _, s in shards do
			s.velocity -= Vector3.new(0, 60 * dt, 0)
			s.part.CFrame = (s.part.CFrame + s.velocity * dt) * CFrame.Angles(s.spin.X * dt, s.spin.Y * dt, s.spin.Z * dt)
			s.part.Transparency = s.start + (1 - s.start) * math.clamp(t / SHARD_TIME, 0, 1) ^ 2
		end
		if t >= SHARD_TIME then
			connection:Disconnect()
			for _, s in shards do
				s.part:Destroy()
			end
		end
	end)
end

-- Breakable barriers: one at each biome line past the last you've broken; riding
-- through it (you crossing its line) shatters it and tells the server.
local breakGate = ReplicatedStorage:WaitForChild("BreakGate")
local function refreshBreakable()
	local broken = player:GetAttribute("GatesBroken") or 1
	for i = 2, #Config.Biomes do
		if i > broken and not gates[i] then
			build(i)
		elseif i <= broken and gates[i] then
			gates[i].gui:Destroy() -- (broken elsewhere)
			gates[i].part:Destroy()
			gates[i] = nil
		end
	end
end
if Config.BreakGates then
	player:GetAttributeChangedSignal("GatesBroken"):Connect(refreshBreakable)
	refreshBreakable()
	RunService.RenderStepped:Connect(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		for i, gate in gates do
			if hrp.Position.Z < WorldColors.biomeStart(i) then
				gates[i] = nil
				gate.gui:Destroy()
				gate.part:Destroy()
				shatter(i)
				breakGate:FireServer(i)
			end
		end
	end)
end

-- Riding an exclusive event's animal (Ride.client sets "EventRun" on you, locally):
-- every barrier is gone for that ride, and back after it (QM).
player:GetAttributeChangedSignal("EventRun"):Connect(function()
	for _, gate in gates do
		gate.gui.Enabled = not player:GetAttribute("EventRun")
	end
end)
