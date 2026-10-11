-- The intro (QM, Oct 11): a new player's first moments, before the tutorial. Shown,
-- never told (no text). You're at your pen, a beautiful Phoenix egg glowing in it. The
-- villain rides up on a huge Loong and leaps off; you fight him and lose: he dodges
-- your punch, hits back twice and a spinning kick sends you flying. He jumps back on
-- his Loong, lassoes the egg away and rides off down the course with it. Only then,
-- getting up, do you get angry (red in the face, steam, an anger mark). That sets the
-- goal: ride as far as you can to catch him. (The story never has to finish.)
--
-- Plays whenever the "Tutorial" attribute turns on (Hatchery.server: a new player, or
-- "/tutorial" to see it again). Config.Intro turns it off. Its own music (Sounds'
-- "intro"), every bit of UI hidden, the controls off. The fight is posed by hand: each
-- rig's joints (Motor6D or AnimationConstraint) are set every frame, its Animator out.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Sounds = require(script.Parent.Sounds)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local rng = Random.new()

local EGG = "Phoenix" -- the egg he steals
local MOUNT = "Loong" -- what he rides
local MOUNT_SCALE = 1.6 -- x its own size: huge
local EGG_SCALE = 1.5
local VEIN = "rbxassetid://85408798859805" -- assets/ui/boss/AngerMarkOutlined.png (the boss's anger mark)
local RING = "rbxassetid://119064104030965" -- the Creator Store's "dash_shockwave_ring" (decal 76060685268692)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SFX = {
	hit = "rbxassetid://71854224710325", -- BodyHit-2 (Roblox's sound effects)
	swing = "rbxassetid://9120972444", -- Wood Whoosh Slicing Air Quick Swings 1 (ProSoundEffects)
	swing2 = "rbxassetid://9120972321", -- ... Swings 4
}
local VILLAIN_COLOR = Color3.fromRGB(34, 30, 44)
local ANGRY_RED = Color3.fromRGB(235, 60, 50)

local function ease(t)
	return t * t * (3 - 2 * t)
end
local function rad(d)
	return math.rad(d)
end
local function X(d)
	return CFrame.Angles(rad(d), 0, 0)
end
local function Y(d)
	return CFrame.Angles(0, rad(d), 0)
end
local function Z(d)
	return CFrame.Angles(0, 0, rad(d))
end

-- Poses: each joint's turn from standing. Shoulders and hips: +X swings the limb
-- forward and up, +Z takes a right arm out (a left one -Z); elbows bend up with +X,
-- knees back with -X; the waist turns the right shoulder forward with +Y.
local POSES = {
	stand = {},
	guard = { RightShoulder = X(70), RightElbow = X(100), LeftShoulder = X(85), LeftElbow = X(110), Waist = Y(-20), RightHip = X(20), RightKnee = X(-25), LeftHip = X(-10), LeftKnee = X(-15) },
	punchR = { RightShoulder = X(90), RightElbow = X(5), LeftShoulder = X(70), LeftElbow = X(110), Waist = Y(35), RightHip = X(-15), LeftHip = X(35), LeftKnee = X(-35) },
	punchL = { LeftShoulder = X(90), LeftElbow = X(5), RightShoulder = X(70), RightElbow = X(110), Waist = Y(-35), LeftHip = X(-15), RightHip = X(35), RightKnee = X(-35) },
	dodge = { Waist = X(-15) * Y(-30), Neck = X(-10), RightShoulder = X(60), RightElbow = X(100), LeftShoulder = X(80), LeftElbow = X(110), RightHip = X(-20), LeftHip = X(30), LeftKnee = X(-50) },
	kick = { RightHip = X(105), RightKnee = X(-5), Waist = X(-20), LeftShoulder = X(40) * Z(-50), RightShoulder = X(40) * Z(50), LeftKnee = X(-20) },
	hit = { Waist = X(-30), Neck = X(-25), RightShoulder = X(-30) * Z(40), LeftShoulder = X(-30) * Z(-40), RightHip = X(-10), LeftHip = X(15), LeftKnee = X(-20) },
	fly = { Waist = X(-40), Neck = X(-30), RightShoulder = X(150), LeftShoulder = X(150), RightHip = X(-30), LeftHip = X(20), RightKnee = X(-60), LeftKnee = X(-60) },
	down = { RightShoulder = Z(70), LeftShoulder = Z(-70), RightHip = Z(15), LeftHip = Z(-15), Neck = X(10) },
	kneel = { RightHip = X(90), RightKnee = X(-90), LeftHip = X(-10), LeftKnee = X(-100), Waist = X(20), Neck = X(-10), RightShoulder = X(15), LeftShoulder = X(10) },
	angry = { RightShoulder = X(25) * Z(25), RightElbow = X(85), LeftShoulder = X(25) * Z(-25), LeftElbow = X(85), Waist = X(12), Neck = X(-8), RightHip = Z(8), LeftHip = Z(-8) },
	ride = { RightHip = X(85) * Z(25), LeftHip = X(85) * Z(-25), RightKnee = X(-80), LeftKnee = X(-80), RightShoulder = X(30), LeftShoulder = X(30) },
	throw = { RightShoulder = X(165), RightElbow = X(20), LeftShoulder = X(40), RightHip = X(85) * Z(25), LeftHip = X(85) * Z(-25), RightKnee = X(-80), LeftKnee = X(-80), Waist = Y(-25) },
	jump = { RightHip = X(60), RightKnee = X(-80), LeftHip = X(40), LeftKnee = X(-70), RightShoulder = X(120) * Z(30), LeftShoulder = X(120) * Z(-30) },
}

-- A character to pose by hand: its joints by name, the Animator taken out (and put
-- back by releaseRig), every joint kinematic so the pose holds exactly.
local function takeRig(model)
	local rig = { model = model, root = model:FindFirstChild("HumanoidRootPart"), joints = {}, from = POSES.stand, to = POSES.stand, t = 1, time = 0 }
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animate = model:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		rig.animate, rig.animateWas = animate, animate.Enabled
		animate.Enabled = false
	end
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
		rig.animator, rig.animatorParent = animator, animator.Parent
		animator.Parent = nil
	end
	rig.kinematic = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
			rig.joints[d.Name] = d
			if d:IsA("AnimationConstraint") then
				rig.kinematic[d] = d.IsKinematic
				d.IsKinematic = true
			end
		end
	end
	return rig
end

local function releaseRig(rig)
	for _, joint in rig.joints do
		joint.Transform = CFrame.identity
	end
	for joint, was in rig.kinematic do
		joint.IsKinematic = was
	end
	if rig.animator then
		rig.animator.Parent = rig.animatorParent
	end
	if rig.animate then
		rig.animate.Enabled = rig.animateWas
	end
end

-- Blend a rig from where it is to `pose` over `time` seconds (0: at once).
local function poseTo(rig, pose, time)
	local now = {}
	local k = ease(math.clamp(rig.t, 0, 1))
	for name in rig.joints do
		local a = rig.from[name] or CFrame.identity
		local b = rig.to[name] or CFrame.identity
		now[name] = a:Lerp(b, k)
	end
	rig.from, rig.to = now, POSES[pose] or pose
	rig.time = time or 0
	rig.t = if rig.time <= 0 then 1 else 0
end

local function stepRig(rig, dt)
	if rig.t < 1 then
		rig.t = math.min(rig.t + dt / math.max(rig.time, 1e-3), 1)
	end
	local k = ease(rig.t)
	for name, joint in rig.joints do
		local a = rig.from[name] or CFrame.identity
		local b = rig.to[name] or CFrame.identity
		joint.Transform = a:Lerp(b, k)
	end
end

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
end

-- The villain: your own avatar, in shadow, with glowing red eyes.
local function makeVillain(character)
	local was = character.Archivable
	character.Archivable = true
	local villain = character:Clone()
	character.Archivable = was
	villain.Name = "Villain"
	for _, d in villain:GetDescendants() do
		if (d:IsA("LuaSourceContainer") and d.Name ~= "Animate") or d:IsA("Accessory") or d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("ForceField") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
			d.Color = VILLAIN_COLOR
			if d:IsA("MeshPart") then
				d.TextureID = ""
			end
		elseif d:IsA("Decal") and d.Name == "face" then
			d.Transparency = 1
		end
	end
	local humanoid = villain:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.PlatformStand = true
	end
	if villain:FindFirstChild("HumanoidRootPart") then
		villain.HumanoidRootPart.Anchored = true
	end
	local head = villain:FindFirstChild("Head")
	if head then
		for sideSign = -1, 1, 2 do
			local eye = Instance.new("Part")
			eye.Name = "Eye"
			eye.CanCollide, eye.CanQuery, eye.CanTouch, eye.Massless = false, false, false, true
			eye.Material = Enum.Material.Neon
			eye.Color = Color3.fromRGB(255, 40, 40)
			eye.Size = Vector3.new(0.22, 0.12, 0.05)
			eye.CFrame = head.CFrame * CFrame.new(sideSign * 0.2, 0.15, -head.Size.Z / 2 - 0.01)
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1 = head, eye
			weld.Parent = eye
			eye.Parent = villain
		end
	end
	return villain
end

local playing = false

local function intro()
	if playing then
		return
	end
	playing = true
	task.wait(1.2) -- ("/tutorial" respawns you just after turning the tutorial on)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local start = os.clock()
	while not myPen() and os.clock() - start < 10 do
		task.wait(0.2)
	end
	local pen = myPen()
	if not hrp or not humanoid or not pen or not pen:FindFirstChild("Area") then
		playing = false
		return
	end
	task.wait(0.4) -- (let the pen and character settle in)

	local area = pen.Area
	local floorY = area.Position.Y + area.Size.Y / 2
	local middle = Vector3.new(area.Position.X, floorY, area.Position.Z)
	local spawnPart = pen:FindFirstChild("Spawn")
	local out = if spawnPart then ((spawnPart.Position - middle) * Vector3.new(1, 0, 1)).Unit else Vector3.new(0, 0, -1)
	local side = out:Cross(Vector3.yAxis)
	local made = {} -- everything to clear away at the end

	-- Every bit of UI goes, and the controls stop, till it's over.
	player:SetAttribute("Cutscene", true) -- (BaseUi keeps itself on every frame otherwise)
	local hidden = {}
	local function hideAll()
		for _, g in player.PlayerGui:GetChildren() do
			if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "Intro" and g.Name ~= "PreloadWarm" and g.Name ~= "AnimalDexWarm" then
				g.Enabled = false
				if not table.find(hidden, g) then
					table.insert(hidden, g)
				end
			end
		end
	end
	hideAll()
	local holdHidden = RunService.RenderStepped:Connect(hideAll) -- (some of it turns itself back on)
	local controls
	pcall(function()
		controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
		controls:Disable()
	end)
	local cameraType, fov = camera.CameraType, camera.FieldOfView
	camera.CameraType = Enum.CameraType.Scriptable
	local musicWas = Sounds.music()
	Sounds.setMusic("intro", true)

	local gui = Instance.new("ScreenGui")
	gui.Name = "Intro"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 60
	local fade = Instance.new("Frame")
	fade.BorderSizePixel = 0
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.Size = UDim2.fromScale(1, 1)
	fade.Parent = gui
	local flash = Instance.new("Frame")
	flash.BorderSizePixel = 0
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.Size = UDim2.fromScale(1, 1)
	flash.Parent = gui
	gui.Parent = player.PlayerGui
	table.insert(made, gui)

	-- The camera, with a shake that dies away.
	local shake = 0
	local function cam(cf)
		if shake > 0.01 then
			cf *= CFrame.Angles(rng:NextNumber(-1, 1) * shake * 0.03, rng:NextNumber(-1, 1) * shake * 0.03, 0)
		end
		camera.CFrame = cf
	end
	local function sound(id, volume)
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volume or 0.6
		s.Parent = gui
		s:Play()
		s.Ended:Once(function()
			s:Destroy()
		end)
	end
	local function burst(at, texture, color, count, speed, size)
		local a = Instance.new("Attachment")
		a.WorldPosition = at
		a.Parent = workspace.Terrain
		local e = Instance.new("ParticleEmitter")
		e.Texture = texture
		e.Color = ColorSequence.new(color)
		e.Rate = 0
		e.Lifetime = NumberRange.new(0.3, 0.6)
		e.Speed = NumberRange.new(speed * 0.6, speed)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new(size, 0)
		e.Transparency = NumberSequence.new(0, 1)
		e.LightEmission = 0.6
		e.Drag = 4
		e.Parent = a
		e:Emit(count)
		task.delay(1.2, a.Destroy, a)
	end
	local function ring(at, to)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Transparency = 1
		p.Size = Vector3.new(2, 0.05, 2)
		p.CFrame = CFrame.new(at + Vector3.new(0, 0.15, 0))
		local d = Instance.new("Decal")
		d.Face = Enum.NormalId.Top
		d.Texture = RING
		d.Parent = p
		p.Parent = workspace
		TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(to, 0.05, to) }):Play()
		TweenService:Create(d, TweenInfo.new(0.45), { Transparency = 1 }):Play()
		task.delay(0.5, p.Destroy, p)
	end
	local function impact(at, strength)
		burst(at, SPARK, Color3.fromRGB(255, 240, 180), math.floor(18 * strength), 30, 1.6)
		shake = math.max(shake, strength)
		flash.BackgroundTransparency = 1 - 0.25 * strength
		TweenService:Create(flash, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
		sound(SFX.hit, 0.7)
	end
	local hold = 0 -- a hit's freeze-frame: seconds left with everything stopped

	local rigs = {}
	-- Runs step(u, dt) every frame for `duration` seconds, posing the rigs and easing
	-- the shake; a hit freezes it all for a beat.
	local function play(duration, step)
		local t = 0
		while t < duration do
			local dt = RunService.RenderStepped:Wait()
			shake *= math.exp(-6 * dt)
			if hold > 0 then
				hold -= dt
				dt = 0
			end
			t = math.min(t + dt, duration)
			for _, rig in rigs do
				stepRig(rig, dt)
			end
			step(t / duration, dt)
		end
	end

	-- 1. Your pen, the Phoenix egg glowing in it, you beside it.
	local egg = Egg.new(EGG)
	egg.model:ScaleTo(egg.model:GetScale() * EGG_SCALE)
	Egg.fitStuds(egg.model)
	local eggSpot = middle + Vector3.new(0, 1.6 * egg.model:GetScale(), 0)
	local eggTurn = CFrame.Angles(0, math.atan2(-out.X, -out.Z), 0)
	egg.model:PivotTo(CFrame.new(eggSpot) * eggTurn)
	egg.model.Parent = workspace
	table.insert(made, egg.model)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 160, 60)
	glow.Range = 18
	glow.Brightness = 2
	glow.Parent = egg.model.PrimaryPart
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = SPARK
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120))
	sparkle.Rate = 14
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new(0.6, 0)
	sparkle.LightEmission = 1
	sparkle.Parent = egg.model.PrimaryPart

	local standY = hrp.Position.Y - floorY -- (how high your root stands over the floor)
	local fightAt = middle + out * (area.Size.Z / 2 + 18)
	local youAt = fightAt - side * 4.5
	local wasAnchored = hrp.Anchored
	hrp.Anchored = true
	humanoid.PlatformStand = true
	local you = takeRig(character)
	table.insert(rigs, you)
	local function place(rig, at, facing, lift, tilt)
		local p = at + Vector3.new(0, standY + (lift or 0), 0)
		rig.root.CFrame = CFrame.lookAt(p, p + facing) * (tilt or CFrame.identity)
	end
	place(you, youAt, -out)

	local wide = CFrame.lookAt(fightAt + out * 26 + side * 16 + Vector3.new(0, 12, 0), middle + Vector3.new(0, 3, 0))
	local close = CFrame.lookAt(eggSpot + out * 14 + Vector3.new(0, 4, 0), eggSpot)
	TweenService:Create(fade, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	play(2.2, function(u)
		cam(close:Lerp(wide, ease(u)))
	end)

	-- 2. The villain rides up on a huge Loong; you turn to face him.
	local Mount = require(ReplicatedStorage.Shared.Animals[MOUNT])
	local mount = Mount.new()
	mount:setScale(MOUNT_SCALE)
	mount.model.Name = "VillainMount"
	mount.model.PrimaryPart.CFrame = CFrame.new()
	local box, size = mount.model:GetBoundingBox()
	local lift = mount.model.PrimaryPart.Position.Y - (box.Position.Y - size.Y / 2)
	mount.model.Parent = workspace
	table.insert(made, mount.model)
	local villainModel = makeVillain(character)
	villainModel.Parent = workspace
	table.insert(made, villainModel)
	local villain = takeRig(villainModel)
	table.insert(rigs, villain)
	poseTo(villain, "ride")
	local mountFacing = side
	local function ride(at, facing, dt, speed)
		mountFacing = facing
		mount.model.PrimaryPart.CFrame = CFrame.lookAt(at + Vector3.new(0, lift, 0), at + Vector3.new(0, lift, 0) + facing)
		pcall(mount.update, mount, dt, speed, 0)
	end
	local function onMount()
		villain.root.CFrame = mount:getSeatCFrame() * CFrame.new(0, 2.6, 0)
	end
	local parkAt = fightAt + side * 30 + out * 6
	local enterFrom = parkAt + out * 170 + side * 30
	Sounds.play("boss_LavaWyrm", 0.5)
	poseTo(you, "guard", 0.6)
	play(2.6, function(u, dt)
		local at = enterFrom:Lerp(parkAt, ease(math.min(u * 1.1, 1)))
		ride(at, (parkAt - enterFrom).Unit, dt, if u < 0.85 then 90 else 0)
		onMount()
		place(you, youAt, (-out):Lerp(side, ease(u)))
		cam(camera.CFrame:Lerp(CFrame.lookAt(fightAt + out * 34 + Vector3.new(0, 14, 0), at:Lerp(fightAt, 0.5) + Vector3.new(0, 5, 0)), 1 - math.exp(-4 * dt)))
	end)

	-- He leaps off and lands in front of you.
	local villainAt = fightAt + side * 4.5
	local leapFrom = villain.root.Position - Vector3.new(0, standY, 0)
	poseTo(villain, "jump", 0.15)
	local fightCam = CFrame.lookAt(fightAt + out * 13 + Vector3.new(0, 3.5, 0), fightAt + Vector3.new(0, 2.5, 0))
	play(0.7, function(u, dt)
		local p = leapFrom:Lerp(villainAt, u) + Vector3.new(0, math.sin(u * math.pi) * 10, 0)
		place(villain, p, -side)
		ride(parkAt, mountFacing, dt, 0)
		cam(camera.CFrame:Lerp(fightCam, 1 - math.exp(-5 * dt)))
	end)
	poseTo(villain, "guard", 0.2)
	ring(villainAt, 26)
	burst(villainAt + Vector3.new(0, 0.5, 0), SMOKE, Color3.fromRGB(190, 160, 120), 16, 14, 3)
	shake = 1
	Sounds.play("crash", 0.6)
	play(0.7, function(_, dt)
		ride(parkAt, mountFacing, dt, 0)
		cam(fightCam)
	end)

	-- 3. The fight. You charge and swing; he dodges.
	local function swingCam(dt)
		cam(camera.CFrame:Lerp(fightCam, 1 - math.exp(-8 * dt)))
	end
	poseTo(you, "punchR", 0.12)
	sound(SFX.swing, 0.6)
	poseTo(villain, "dodge", 0.12)
	local youFrom, villainFrom = youAt, villainAt
	play(0.35, function(u, dt)
		place(you, youFrom:Lerp(fightAt - side * 1.5, ease(u)), side)
		place(villain, villainFrom:Lerp(villainFrom + side * 1.2, ease(u)), -side)
		ride(parkAt, mountFacing, dt, 0)
		swingCam(dt)
	end)
	youAt = fightAt - side * 1.5
	villainAt = villainFrom + side * 1.2
	-- He hits back: left, right...
	for i, punch in { "punchL", "punchR" } do
		poseTo(villain, "guard", 0.08)
		poseTo(you, "guard", 0.15)
		play(0.12, function(_, dt)
			ride(parkAt, mountFacing, dt, 0)
			swingCam(dt)
		end)
		poseTo(villain, punch, 0.08)
		sound(SFX.swing2, 0.5)
		play(0.1, function(_, dt)
			ride(parkAt, mountFacing, dt, 0)
			swingCam(dt)
		end)
		local head = character:FindFirstChild("Head")
		impact(if head then head.Position else youAt + Vector3.new(0, 4, 0), 0.6 + 0.2 * i)
		hold = 0.07
		poseTo(you, "hit", 0.08)
		local back = youAt
		play(0.3, function(u, dt)
			place(you, back - side * u * 0.8, side)
			ride(parkAt, mountFacing, dt, 0)
			swingCam(dt)
		end)
		youAt = back - side * 0.8
	end
	-- ...and a spinning kick sends you flying.
	poseTo(villain, "kick", 0.18)
	sound(SFX.swing, 0.7)
	play(0.3, function(u, dt)
		place(villain, villainAt, -side, nil, CFrame.Angles(0, u * math.pi * 2, 0))
		ride(parkAt, mountFacing, dt, 0)
		swingCam(dt)
	end)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or hrp
	impact(torso.Position, 1.4)
	hold = 0.12
	Sounds.play("crash", 0.7)
	poseTo(you, "fly", 0.15)
	local flyFrom, flyTo = youAt, youAt - side * 16
	play(1.1, function(u, dt)
		local k = 1 - (1 - u) ^ 2
		local p = flyFrom:Lerp(flyTo, k) + Vector3.new(0, math.sin(u * math.pi) * 6, 0)
		place(you, p, side, 0, CFrame.Angles(rad(-80 * u), 0, 0))
		ride(parkAt, mountFacing, dt, 0)
		cam(camera.CFrame:Lerp(CFrame.lookAt(fightAt + out * 16 - side * 4 + Vector3.new(0, 4, 0), p + Vector3.new(0, 2, 0)), 1 - math.exp(-6 * dt)))
	end)
	youAt = flyTo
	poseTo(you, "down", 0.15)
	place(you, youAt, side, -standY + 1, CFrame.Angles(rad(-88), 0, 0))
	ring(youAt, 20)
	burst(youAt + Vector3.new(0, 0.5, 0), SMOKE, Color3.fromRGB(190, 160, 120), 22, 12, 3.5)
	shake = 1.2
	Sounds.play("crash", 0.5)
	play(0.8, function(_, dt)
		ride(parkAt, mountFacing, dt, 0)
		cam(camera.CFrame:Lerp(CFrame.lookAt(youAt + out * 10 + side * 6 + Vector3.new(0, 5, 0), youAt + Vector3.new(0, 1, 0)), 1 - math.exp(-4 * dt)))
	end)

	-- 4. He jumps back on his Loong, lassoes your egg and rides off with it.
	poseTo(villain, "jump", 0.12)
	local seat = mount:getSeatCFrame().Position + Vector3.new(0, 2.6 - standY, 0)
	local hopFrom = villainAt
	play(0.6, function(u, dt)
		local p = hopFrom:Lerp(seat, u) + Vector3.new(0, math.sin(u * math.pi) * 8, 0)
		place(villain, p, mountFacing)
		ride(parkAt, mountFacing, dt, 0)
		cam(camera.CFrame:Lerp(CFrame.lookAt(fightAt + out * 34 + Vector3.new(0, 14, 0), parkAt:Lerp(middle, 0.5) + Vector3.new(0, 5, 0)), 1 - math.exp(-4 * dt)))
	end)
	poseTo(villain, "throw", 0.15)
	local facing = ((middle - parkAt) * Vector3.new(1, 0, 1)).Unit
	local hand = villainModel:FindFirstChild("RightHand") or villainModel:FindFirstChild("Right Arm") or villain.root
	local from = Instance.new("Attachment")
	from.Parent = hand
	local to = Instance.new("Attachment")
	to.Parent = egg.model.PrimaryPart
	local rope = Instance.new("Beam")
	rope.Attachment0, rope.Attachment1 = from, to
	rope.Color = ColorSequence.new(Color3.fromRGB(196, 150, 90))
	rope.Width0, rope.Width1 = 0.35, 0.35
	rope.FaceCamera = true
	rope.Segments = 12
	rope.CurveSize0 = 6
	rope.Parent = hand
	table.insert(made, rope)
	table.insert(made, from)
	Sounds.play("lasso_throw")
	play(0.6, function(u, dt)
		rope.CurveSize0 = 6 * (1 - u)
		ride(parkAt, facing, dt, 0)
		onMount()
		cam(camera.CFrame:Lerp(CFrame.lookAt(parkAt:Lerp(middle, 0.5) + out * 34 + Vector3.new(0, 18, 0), parkAt:Lerp(middle, 0.5) + Vector3.new(0, 4, 0)), 1 - math.exp(-5 * dt)))
	end)
	Sounds.play("lasso_land")
	Sounds.play("egg_grab", 0.8)
	sparkle.Rate = 40
	local eggFrom = egg.model:GetPivot()
	play(0.9, function(u, dt)
		ride(parkAt, facing, dt, 0)
		onMount()
		local target = mount:getSeatCFrame().Position + Vector3.new(0, 5, 0)
		local p = eggFrom.Position:Lerp(target, ease(u)) + Vector3.new(0, math.sin(u * math.pi) * 14, 0)
		egg.model:PivotTo(CFrame.new(p) * eggTurn * CFrame.Angles(0, u * 6, 0))
	end)
	rope:Destroy()
	poseTo(villain, "ride", 0.2)
	local leaveTo = parkAt + Vector3.new(0, 0, -700)
	play(2.4, function(u, dt)
		local at = parkAt:Lerp(leaveTo, u * u)
		ride(at, (leaveTo - parkAt).Unit, dt, 120)
		onMount()
		egg.model:PivotTo(CFrame.new(mount:getSeatCFrame().Position + Vector3.new(0, 5, 0)) * eggTurn)
		cam(camera.CFrame:Lerp(CFrame.lookAt(youAt + out * 6 + Vector3.new(0, 5, 0), at + Vector3.new(0, 6, 0)), 1 - math.exp(-5 * dt)))
	end)
	for _, thing in { mount.model, villainModel, egg.model } do
		thing.Parent = nil
	end

	-- 5. Only now, getting up, do you get angry.
	poseTo(you, "kneel", 0.5)
	play(0.6, function(u)
		place(you, youAt, out, (-standY + 1) * (1 - u) - 1.2 * u, CFrame.Angles(rad(-88 * (1 - u)), 0, 0))
		cam(camera.CFrame:Lerp(CFrame.lookAt(youAt + out * 9 + Vector3.new(0, 2.5, 0), youAt + Vector3.new(0, 1.5, 0)), 0.15))
	end)
	poseTo(you, "angry", 0.35)
	local head = character:FindFirstChild("Head")
	local headWas = head and head.Color
	play(0.4, function(u)
		place(you, youAt, out, -1.2 * (1 - u))
		if head then
			cam(CFrame.lookAt(head.Position + out * (7 - u * 2) + Vector3.new(0, 0.6, 0), head.Position))
		end
	end)
	if head then
		camera.FieldOfView = 45
		TweenService:Create(head, TweenInfo.new(0.6), { Color = ANGRY_RED }):Play()
		for sideSign = -1, 1, 2 do -- steam puffing out either side of your head
			local a = Instance.new("Attachment")
			a.Position = Vector3.new(sideSign * head.Size.X * 0.6, head.Size.Y * 0.3, 0)
			a.Parent = head
			local steam = Instance.new("ParticleEmitter")
			steam.Texture = SMOKE
			steam.Color = ColorSequence.new(Color3.new(1, 1, 1))
			steam.Transparency = NumberSequence.new(0.2, 1)
			steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) })
			steam.Lifetime = NumberRange.new(0.5, 0.8)
			steam.Speed = NumberRange.new(5, 8)
			steam.EmissionDirection = Enum.NormalId.Top
			steam.SpreadAngle = Vector2.new(25, 25)
			steam.Rate = 30
			steam.Parent = a
			table.insert(made, a)
		end
		-- The anger mark, by your head: a decal on a little card turned to face the camera
		-- every frame (in the world, not UI).
		local markPart = Instance.new("Part")
		markPart.Anchored, markPart.CanCollide, markPart.CanQuery, markPart.CanTouch, markPart.CastShadow = true, false, false, false, false
		markPart.Transparency = 1
		markPart.Size = Vector3.new(0.05, 0.05, 0.05)
		local decal = Instance.new("Decal")
		decal.Face = Enum.NormalId.Front
		decal.Texture = VEIN
		decal.Parent = markPart
		markPart.Parent = workspace
		table.insert(made, markPart)
		play(2.2, function(u)
			local v = u * 2.2
			local s = math.max((1 - math.exp(-12.6 * v) * math.cos(26 * v)) + 0.15 * math.sin(v * math.pi * 3), 0.05)
			local look = head.Position + Vector3.new(0, 0.9, 0) -- (a little over your head: the steam and the mark in view)
			cam(CFrame.lookAt(look + out * (8.5 - u * 1.5) + Vector3.new(0, 0.3, 0), look))
			-- (up and off to one side of your head, a stud toward the camera: clear of any hat)
			local at = head.Position + Vector3.new(0, 1.3, 0) - side * 1.7 + out * 1
			markPart.Size = Vector3.new(1.8 * s, 1.8 * s, 0.05)
			markPart.CFrame = CFrame.lookAt(at, camera.CFrame.Position) * CFrame.Angles(0, 0, rad(v * 20))
		end)
	else
		task.wait(2)
	end

	-- Back to the game.
	TweenService:Create(fade, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
	task.wait(0.55)
	for _, thing in made do
		if thing then
			thing:Destroy()
		end
	end
	if head and headWas then
		head.Color = headWas
	end
	releaseRig(you)
	hrp.Anchored = wasAnchored
	humanoid.PlatformStand = false
	local standAt = fightAt - side * 4 + Vector3.new(0, standY, 0)
	hrp.CFrame = CFrame.lookAt(standAt, standAt - out)
	camera.FieldOfView = fov
	camera.CameraType = cameraType
	if controls then
		controls:Enable()
	end
	Sounds.setMusic(musicWas or "base")
	holdHidden:Disconnect()
	player:SetAttribute("Cutscene", nil)
	for _, g in hidden do
		if g.Parent then
			g.Enabled = true
		end
	end
	playing = false
end

local function check()
	if Config.Intro ~= false and player:GetAttribute("Tutorial") == true then
		task.spawn(intro)
	end
end
player:GetAttributeChangedSignal("Tutorial"):Connect(check)
check()
