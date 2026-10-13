-- The boss (QM, Oct 10): when the BOSS IN timer runs out your animal stops, and the
-- boss (Shared/Bosses: each biome its own, Config.Boss.ByBiome) pops up in front of you,
-- angry. The camera zooms in on its face between
-- black bars (the middle 40% of the screen showing: BAR), an anger vein popping up on the
-- screen by its head with them, pulsing once and gone as they go (QM, Oct 10: UI, not
-- in the world), then it chases you: you turn
-- round and race home with it behind you (out of sight, and never catching you: it's
-- just there to scare). Config.Boss. Ride drives it:
--
--   BossChase.start(x, z)             -- the cutscene, in front of (x, z) (outbound: -z), that biome's boss
--   BossChase.over()                  -- true once the cutscene's done (turn for home)
--   BossChase.update(dt, chasing, x, z, speed) -- every frame: chasing the rider at (x, z)
--   BossChase.camera() -> CFrame?     -- the camera during the cutscene (nil: Ride's own)
--   BossChase.stop()                  -- gone (home, or the ride over)
--   BossChase.roar() -> 0..1          -- how loud its cry on the run home is right now (ReturnVignette)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Sounds = require(script.Parent.Sounds)
local Banner = require(script.Parent.Banner)

local BAR = 0.2 -- each black bar's share of the screen's height: 40% of it in all, the strip between 60% (QM, Oct 11)
local VEIN = "rbxassetid://85408798859805" -- assets/ui/boss/AngerMarkOutlined.png (QM's 💢, Oct 10, with a black outline baked in)

local BossChase = {}

local boss -- { animal, x, z, t, scale }
-- Each boss is built once, ahead (building one, a few hundred blocks, hitched the frame
-- it popped up: QM, Oct 11), and kept for the next time: [kind] = animal, not in the world.
local spare = {}
local offsets = {} -- [kind] = how high its root sits over its feet at its own size
local bars -- the letterbox: { gui, top, bottom, vein, veinScale }
-- Its cries on the run home (Config.Boss.Roar): the sound playing, its loudest yet, the
-- boss.t of the next, and how loud it is now (0..1, following PlaybackLoudness).
local roar = { sound = nil, peak = 0, next = nil, level = 0 }

local function popScale(t) -- 0 -> overshoot -> 1, as the stampede's animals pop in (Ride)
	return 1 - math.exp(-12.6 * t) * math.cos(26 * t)
end

local function letterbox()
	if bars then
		return bars
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "BossBars"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50 -- (over the rest of the UI)
	local function bar(anchorY)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.AnchorPoint = Vector2.new(0, anchorY)
		f.Size = UDim2.fromScale(1, BAR)
		f.Position = UDim2.fromScale(0, anchorY) -- (hidden: pushed off, below)
		f.Parent = gui
		return f
	end
	-- The anger vein, in the strip (Config.Boss.VeinAt: where, of the screen).
	local vein = Instance.new("ImageLabel")
	vein.Name = "AngerVein"
	vein.BackgroundTransparency = 1
	vein.Image = VEIN
	vein.AnchorPoint = Vector2.new(0.5, 0.5)
	vein.Position = UDim2.fromScale(Config.Boss.VeinAt.X, Config.Boss.VeinAt.Y)
	vein.Size = UDim2.fromScale(Config.Boss.VeinSize, Config.Boss.VeinSize)
	vein.SizeConstraint = Enum.SizeConstraint.RelativeYY
	vein.ImageTransparency = 1 -- (drawn, but clear, till it's wanted, and preloaded below: QM)
	vein.ZIndex = 2 -- (over the bars: QM)
	local veinScale = Instance.new("UIScale")
	veinScale.Parent = vein
	vein.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	bars = { gui = gui, top = bar(1), bottom = bar(0), vein = vein, veinScale = veinScale }
	bars.top.Position = UDim2.fromScale(0, 0)
	bars.bottom.Position = UDim2.fromScale(0, 1)
	return bars
end

local function showBars(on)
	local b = letterbox()
	local info = TweenInfo.new(Config.Boss.BarTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(b.top, info, { Position = UDim2.fromScale(0, if on then BAR else 0) }):Play()
	TweenService:Create(b.bottom, info, { Position = UDim2.fromScale(0, if on then 1 - BAR else 1) }):Play()
end

local function build(kind)
	local animal = require(ReplicatedStorage.Shared.Bosses[kind]).new()
	animal.model.Name = "Boss"
	animal.model.PrimaryPart.CFrame = CFrame.new()
	local cf, size = animal.model:GetBoundingBox()
	offsets[kind] = animal.model.PrimaryPart.Position.Y - (cf.Position.Y - size.Y / 2)
	return animal
end

-- Its size: s x its own; stood on the ground at (x, z), facing +z (towards you).
-- (in steps of a 50th: rescaling every block every frame of the pop was most of its cost,
-- and once it's settled it isn't rescaled at all)
local function place()
	local a = boss.animal
	a:setScale(math.max(math.floor(boss.scale * 50 + 0.5) / 50, 0.05))
	local offset = offsets[boss.kind] * a.scale -- (it scales about its root)
	a.model.PrimaryPart.CFrame = CFrame.new(boss.x, offset, boss.z) * CFrame.Angles(0, math.pi, 0)
end

-- Every biome's boss, built a little after joining, a frame apart.
task.delay(4, function()
	local kinds = { [Config.Boss.Kind] = true }
	for _, kind in Config.Boss.ByBiome do
		kinds[kind] = true
	end
	for kind in kinds do
		if not spare[kind] and ReplicatedStorage.Shared.Bosses:FindFirstChild(kind) then
			spare[kind] = build(kind)
			task.wait(0.3)
		end
	end
end)

-- (made up front, so nothing in it is loading the first time it shows: QM)
task.defer(function()
	game:GetService("ContentProvider"):PreloadAsync({ letterbox().vein })
end)

function BossChase.start(x, z)
	BossChase.stop()
	local biome = Config.Biomes[WorldColors.biomeAt(z)]
	local kind = Config.Boss.ByBiome[biome.Name] or Config.Boss.Kind -- (each biome its own boss: QM, Oct 10)
	local animal = spare[kind] or build(kind)
	spare[kind] = nil
	animal.model.Parent = workspace
	local room = Config.Boss.Room[kind] or 0 -- (a bigger one stands further off)
	boss = { kind = kind, room = room, animal = animal, x = x, z = z - Config.Boss.Ahead - room, t = 0, scale = 0 }
	place()
	Sounds.play("reveal_pop", 0.8)
	ReplicatedStorage.RideCue:FireServer("boss", kind, x, z) -- (everyone else sees it chase you: Client/RemoteBosses, QM)
end

-- Whether it's reached the rider (charging once it's caught them: ReturnRun), so they're run over.
function BossChase.ranOver()
	return boss ~= nil and boss.riderZ ~= nil and boss.z >= boss.riderZ - boss.room * 0.5 - 4
end

function BossChase.over()
	return boss ~= nil and boss.t >= Config.Boss.CutsceneTime
end

function BossChase.update(dt, chasing, x, z, speed)
	if not boss then
		return
	end
	local cfg = Config.Boss
	local was = boss.t
	boss.t += dt
	boss.scale = popScale(boss.t)
	if was < cfg.ZoomAt and boss.t >= cfg.ZoomAt then
		showBars(true)
		Sounds.play("boss_" .. boss.kind, Config.Boss.CryVolume[boss.kind] or 0.6, (Config.Boss.CryPitch or {})[boss.kind]) -- (its own cry with the bars: Sounds' boss_<Kind>)
	elseif was < cfg.CutsceneTime - cfg.BarTime and boss.t >= cfg.CutsceneTime - cfg.BarTime then
		showBars(false)
	end
	if was < cfg.CutsceneTime and boss.t >= cfg.CutsceneTime then
		Banner.show("run") -- (QM's red "RUN!!!" banner as it starts chasing you)
	end
	-- (the vein: with the bars, popping up and then pulsing once)
	local barsIn = boss.t >= cfg.ZoomAt and boss.t < cfg.CutsceneTime - cfg.BarTime
	local b = letterbox()
	b.vein.ImageTransparency = 1 -- (no anger vein any more: QM, Oct 11)
	if barsIn then
		local v = boss.t - cfg.ZoomAt
		local pulse = math.clamp((v - cfg.VeinPopTime) / cfg.VeinPeriod, 0, 1)
		b.veinScale.Scale = popScale(v) + cfg.VeinPulse * math.sin(pulse * math.pi)
		b.vein.Rotation = v * cfg.VeinSpin -- (turning slowly: QM)
	end
	local moving = 0
	if chasing and x then
		-- After you at your own speed (QM, Oct 10), so the gap holds all the way home,
		-- never nearer than Behind studs, and pulling up short of the start line.
		local was = boss.z
		-- (closing, 0..1: how near it's got while you weren't at full speed, Client/ReturnRun;
		-- at 1 it has you)
		local closing = BossChase.closing or 0
		local caught = closing >= 1 -- (it has you: it charges and runs you over, QM)
		local gap = if caught then -boss.room - 30 else (cfg.Behind + boss.room) * (1 - 0.9 * closing)
		boss.z = math.min(boss.z + (math.max(speed or 0, cfg.ChaseMin or 0) + (if caught then 260 else 60 * closing)) * dt, z - gap, -cfg.StopShort - boss.room) -- (never slower than ChaseMin: it doesn't stall as you turn)
		boss.x += (x - boss.x) * (1 - math.exp(-2 * dt))
		moving = math.max(boss.z - was, 0) / math.max(dt, 1e-3)
	end
	boss.riderX, boss.riderZ = x, z
	place()
	boss.animal:update(dt, moving, 0)
	-- Every so often on the run home, its cry again (QM, Oct 11).
	local r = cfg.Roar
	if r and r.On and chasing and boss.t >= cfg.CutsceneTime then
		roar.next = roar.next or boss.t + r.First
		if boss.t >= roar.next then
			roar.next = boss.t + r.Every[1] + math.random() * (r.Every[2] - r.Every[1])
			roar.sound, roar.peak = Sounds.play("boss_" .. boss.kind, cfg.CryVolume[boss.kind] or 0.6, (cfg.CryPitch or {})[boss.kind]), 0
		end
	end
	-- (how loud it is, of its loudest: fast up, slower down)
	local loud = 0
	if roar.sound and roar.sound.Parent and roar.sound.IsPlaying then
		roar.peak = math.max(roar.peak, roar.sound.PlaybackLoudness, 40)
		loud = math.clamp(roar.sound.PlaybackLoudness / roar.peak, 0, 1)
	end
	roar.level += (loud - roar.level) * (1 - math.exp(-(if loud > roar.level then 25 else 5) * dt))
end

function BossChase.roar()
	return roar.level
end

-- The shake: put on the camera after Ride's camera (RideCamera) each frame and taken off
-- again before it, so Ride's easing never sees it.
local camera = workspace.CurrentCamera
local shaken -- the camera's CFrame before this frame's shake, or nil
RunService:BindToRenderStep("BossRoarUnshake", Enum.RenderPriority.Camera.Value, function()
	if shaken then
		camera.CFrame, shaken = shaken, nil
	end
end)
RunService:BindToRenderStep("BossRoarShake", Enum.RenderPriority.Camera.Value + 2, function()
	local r = Config.Boss.Roar
	local s = roar.level
	if not r or s < 0.02 then
		return
	end
	local t = os.clock()
	local function wobble(k) -- (smooth noise, not a jitter)
		return math.noise(t * 18, k) * 2
	end
	shaken = camera.CFrame
	camera.CFrame = shaken * CFrame.new(wobble(1) * r.ShakeMove * s, wobble(2) * r.ShakeMove * s, 0)
		* CFrame.Angles(math.rad(wobble(3) * r.Shake * s), math.rad(wobble(4) * r.Shake * s), math.rad(wobble(5) * r.Shake * s))
end)

-- Lingering: just after the close-up, the camera stays behind you looking down the
-- course at the boss for Linger s while you turn and it starts after you (QM, Oct 11).
function BossChase.lingering()
	local cfg = Config.Boss
	return boss ~= nil and boss.t > cfg.CutsceneTime - cfg.BarTime * 0.5 and boss.t < cfg.CutsceneTime + (cfg.Linger or 0)
end

function BossChase.camera()
	if BossChase.lingering() and boss.riderZ then
		local at = Vector3.new(boss.riderX, 0, boss.riderZ)
		return CFrame.lookAt(at + Vector3.new(0, 30, 30), Vector3.new(boss.x, 6, boss.z))
	end
	if not boss or boss.t < Config.Boss.ZoomAt or boss.t > Config.Boss.CutsceneTime - Config.Boss.BarTime * 0.5 then
		return nil
	end
	-- (its face: up its front, FaceAt of the way up its box from the middle, and as far forward)
	local cf, size = boss.animal.model:GetBoundingBox()
	local own = Config.Boss.Faces[boss.kind] or {} -- (a boss's own, where its face isn't the Chicken's)
	local at, from = own.At or Config.Boss.FaceAt, own.From or Config.Boss.FaceFrom
	local face = cf.Position + Vector3.new(size.X * at.X, size.Y * at.Y, size.Z * at.Z) -- (X: a head off to one side, the Lava Wyrm's)
	return CFrame.lookAt(face + from, face)
end

function BossChase.stop()
	roar.sound, roar.next, roar.level = nil, nil, 0
	if boss then
		if spare[boss.kind] then
			boss.animal.model:Destroy()
		else
			boss.animal.model.Parent = nil -- (kept for next time)
			spare[boss.kind] = boss.animal
		end
		boss = nil
		if bars then
			bars.top.Position = UDim2.fromScale(0, 0)
			bars.bottom.Position = UDim2.fromScale(0, 1)
			bars.vein.ImageTransparency = 1
		end
	end
end

return BossChase
