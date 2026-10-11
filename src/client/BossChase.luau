-- The boss (QM, Oct 10): when the BOSS IN timer runs out your animal stops, and the
-- boss (Shared/Bosses: each biome its own, Config.Boss.ByBiome) pops up in front of you,
-- angry. The camera zooms in on its face between
-- black bars (the middle third of the screen showing), an anger vein popping up on the
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Sounds = require(script.Parent.Sounds)

local VEIN = "rbxassetid://85408798859805" -- assets/ui/boss/AngerMarkOutlined.png (QM's 💢, Oct 10, with a black outline baked in)

local BossChase = {}

local boss -- { animal, x, z, t, scale, offset }
local bars -- the letterbox: { gui, top, bottom, vein, veinScale }

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
		f.Size = UDim2.fromScale(1, 1 / 3)
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
	TweenService:Create(b.top, info, { Position = UDim2.fromScale(0, if on then 1 / 3 else 0) }):Play()
	TweenService:Create(b.bottom, info, { Position = UDim2.fromScale(0, if on then 2 / 3 else 1) }):Play()
end

-- Its size: s x its own; stood on the ground at (x, z), facing +z (towards you).
local function place()
	local a = boss.animal
	a:setScale(math.max(boss.scale, 0.05))
	if boss.offsetAt ~= a.scale then -- (how high its root sits over its feet, at this size)
		a.model.PrimaryPart.CFrame = CFrame.new()
		local cf, size = a.model:GetBoundingBox()
		boss.offset = a.model.PrimaryPart.Position.Y - (cf.Position.Y - size.Y / 2)
		boss.offsetAt = a.scale
	end
	a.model.PrimaryPart.CFrame = CFrame.new(boss.x, boss.offset, boss.z) * CFrame.Angles(0, math.pi, 0)
end

-- (made up front, so nothing in it is loading the first time it shows: QM)
task.defer(function()
	game:GetService("ContentProvider"):PreloadAsync({ letterbox().vein })
end)

function BossChase.start(x, z)
	BossChase.stop()
	local biome = Config.Biomes[WorldColors.biomeAt(z)]
	local kind = Config.Boss.ByBiome[biome.Name] or Config.Boss.Kind -- (each biome its own boss: QM, Oct 10)
	local animal = require(ReplicatedStorage.Shared.Bosses[kind]).new()
	animal.model.Name = "Boss"
	animal.model.Parent = workspace
	local room = Config.Boss.Room[kind] or 0 -- (a bigger one stands further off)
	boss = { kind = kind, room = room, animal = animal, x = x, z = z - Config.Boss.Ahead - room, t = 0, scale = 0 }
	place()
	Sounds.play("reveal_pop", 0.8)
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
		Sounds.play("boss_" .. boss.kind, Config.Boss.CryVolume[boss.kind] or 0.6) -- (its own cry with the bars: Sounds' boss_<Kind>)
	elseif was < cfg.CutsceneTime - cfg.BarTime and boss.t >= cfg.CutsceneTime - cfg.BarTime then
		showBars(false)
	end
	-- (the vein: with the bars, popping up and then pulsing once)
	local barsIn = boss.t >= cfg.ZoomAt and boss.t < cfg.CutsceneTime - cfg.BarTime
	local b = letterbox()
	b.vein.ImageTransparency = if barsIn then 0 else 1
	if barsIn then
		local v = boss.t - cfg.ZoomAt
		local pulse = math.clamp((v - cfg.VeinPopTime) / cfg.VeinPeriod, 0, 1)
		b.veinScale.Scale = popScale(v) + cfg.VeinPulse * math.sin(pulse * math.pi)
		b.vein.Rotation = v * cfg.VeinSpin -- (turning slowly: QM)
	end
	local moving = 0
	if chasing and x then
		-- After you, never catching up: at least Behind studs back, falling behind a little.
		local want = z - cfg.Behind - boss.room
		boss.z = math.min(boss.z + (speed or 0) * cfg.ChaseSpeed * dt, want)
		boss.x += (x - boss.x) * (1 - math.exp(-2 * dt))
		moving = speed or 0
	end
	place()
	boss.animal:update(dt, moving, 0)
end

function BossChase.camera()
	if not boss or boss.t < Config.Boss.ZoomAt or boss.t > Config.Boss.CutsceneTime - Config.Boss.BarTime * 0.5 then
		return nil
	end
	-- (its face: up its front, FaceAt of the way up its box from the middle, and as far forward)
	local cf, size = boss.animal.model:GetBoundingBox()
	local own = Config.Boss.Faces[boss.kind] or {} -- (a boss's own, where its face isn't the Chicken's)
	local at, from = own.At or Config.Boss.FaceAt, own.From or Config.Boss.FaceFrom
	local face = cf.Position + Vector3.new(0, size.Y * at.Y, size.Z * at.Z)
	return CFrame.lookAt(face + from, face)
end

function BossChase.stop()
	if boss then
		boss.animal.model:Destroy()
		boss = nil
		if bars then
			bars.top.Position = UDim2.fromScale(0, 0)
			bars.bottom.Position = UDim2.fromScale(0, 1)
			bars.vein.ImageTransparency = 1
		end
	end
end

return BossChase
