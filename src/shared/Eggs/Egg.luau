-- Eggs built from Blockbench models (designs/eggs/*.bbmodel, converted by
-- tools/bbmodel_to_luau.py). Every egg shares the same bones (egg, bottom,
-- top) so the twitch and hatch animations fit them all.
--
--   local egg = Egg.new("Horse")
--   egg.model:PivotTo(cframe)  -- pivot is the centre of the egg's body
--
-- An egg is as big as its animal: Config.EggSizePerTier times bigger per size
-- tier above small (egg.size; Egg.sizeOf(kind)). Its centre is 1.6 * egg.size
-- studs up. Scaling it further: model:ScaleTo(scale * egg.size).
--   egg:play("twitch")         -- a quick wobble; hatch comes later
--   egg:update(dt)             -- every frame while it can be playing
--
-- The black plates on the crack faces stay hidden inside the egg until the
-- top shell pops off.

local Rig = require(script.Parent.Parent.Animals.Rig)
local Config = require(script.Parent.Parent.Config)
local Studs = require(script.Parent.Parent.Studs)

-- Classic stud decal, the same one the animals use.
local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 }

local KINDS = {
	Horse = { data = require(script.Parent.HorseEggModel), center = 1.6 },
	ArmoredHorse = { data = require(script.Parent.HorseEggModel), center = 1.6 }, -- (World 2's starter: the Horse's egg, QM)
	Pinto = { data = require(script.Parent.PintoEggModel), center = 1.6 },
	Pig = { data = require(script.Parent.PigEggModel), center = 1.6 },
	Fish = { data = require(script.Parent.FishEggModel), center = 1.6 },
	Rhino = { data = require(script.Parent.RhinoEggModel), center = 1.6 },
	Bunny = { data = require(script.Parent.BunnyEggModel), center = 1.6 },
	Unicorn = { data = require(script.Parent.UnicornEggModel), center = 1.6 },
	MarbleColossus = { data = require(script.Parent.MarbleColossusEggModel), center = 1.6 },
	MarbleFish = { data = require(script.Parent.MarbleFishEggModel), center = 1.6 },
	Catfish = { data = require(script.Parent.CatfishEggModel), center = 1.6 },
	Lion = { data = require(script.Parent.LionEggModel), center = 1.6 },
	Buffalo = { data = require(script.Parent.BuffaloEggModel), center = 1.6 },
	Crocodile = { data = require(script.Parent.CrocodileEggModel), center = 1.6 },
	MajesticUnicorn = { data = require(script.Parent.MajesticUnicornEggModel), center = 1.6 },
	CrystalCentipede = { data = require(script.Parent.CrystalCentipedeEggModel), center = 1.6 },
	RedMushroom = { data = require(script.Parent.RedMushroomEggModel), center = 1.6 },
	BrownMushroom = { data = require(script.Parent.BrownMushroomEggModel), center = 1.6 },
	PurpleMushroom = { data = require(script.Parent.PurpleMushroomEggModel), center = 1.6 },
	BlueCrystal = { data = require(script.Parent.BlueCrystalEggModel), center = 1.6 },
	PinkCrystal = { data = require(script.Parent.PinkCrystalEggModel), center = 1.6 },
	LivingBirch = { data = require(script.Parent.LivingBirchEggModel), center = 1.6 },
	Fox = { data = require(script.Parent.FoxEggModel), center = 1.6 },
	TombJackal = { data = require(script.Parent.TombJackalEggModel), center = 1.6 },
	NineTailedFox = { data = require(script.Parent.NineTailedFoxEggModel), center = 1.6 },
	CrystalSpider = { data = require(script.Parent.CrystalSpiderEggModel), center = 1.6 },
	CrystalElephant = { data = require(script.Parent.CrystalElephantEggModel), center = 1.6 },
	CrystalPhoenix = { data = require(script.Parent.CrystalPhoenixEggModel), center = 1.6 },
	OrangeButterfly = { data = require(script.Parent.OrangeButterflyEggModel), center = 1.6 },
	Hawkmoth = { data = require(script.Parent.HawkmothEggModel), center = 1.6 },
	EagleSentry = { data = require(script.Parent.EagleSentryEggModel), center = 1.6 },
	JadeStatue = { data = require(script.Parent.JadeStatueEggModel), center = 1.6 },
	GarnetStatue = { data = require(script.Parent.GarnetStatueEggModel), center = 1.6 },
	Seraph = { data = require(script.Parent.SeraphEggModel), center = 1.6 }, -- World 2's trophy angels (tools/seraph_egg.py)
	CrimsonSeraph = { data = require(script.Parent.CrimsonSeraphEggModel), center = 1.6 },
	CrystalSeraph = { data = require(script.Parent.CrystalSeraphEggModel), center = 1.6 },
	Cactus = { data = require(script.Parent.CactusEggModel), center = 1.6 },
	Kitten = { data = require(script.Parent.KittenEggModel), center = 1.6 },
	Scorpion = { data = require(script.Parent.ScorpionEggModel), center = 1.6 },
	Sandworm = { data = require(script.Parent.SandwormEggModel), center = 1.6 },
	Caterpillar = { data = require(script.Parent.CaterpillarEggModel), center = 1.6 },
	Eyeworm = { data = require(script.Parent.EyewormEggModel), center = 1.6 },
	Maw = { data = require(script.Parent.MawEggModel), center = 1.6 },
	CrimsonScorpion = { data = require(script.Parent.CrimsonScorpionEggModel), center = 1.6 },
	IvorySpider = { data = require(script.Parent.IvorySpiderEggModel), center = 1.6 },
	Asura = { data = require(script.Parent.AsuraEggModel), center = 1.6 },
	Snake = { data = require(script.Parent.SnakeEggModel), center = 1.6 },
	Penguin = { data = require(script.Parent.PenguinEggModel), center = 1.6 },
	Snowman = { data = require(script.Parent.SnowmanEggModel), center = 1.6 },
	SpineLizard = { data = require(script.Parent.SpineLizardEggModel), center = 1.6 },
	Boar = { data = require(script.Parent.BoarEggModel), center = 1.6 },
	IceGolem = { data = require(script.Parent.IceGolemEggModel), center = 1.6 },
	SnackYak = { data = require(script.Parent.SnackYakEggModel), center = 1.6 },
	Icebringer = { data = require(script.Parent.IcebringerEggModel), center = 1.6 },
	Kraken = { data = require(script.Parent.KrakenEggModel), center = 1.6 },
	GiantGolem = { data = require(script.Parent.GiantGolemEggModel), center = 1.6 },
	Kitsune = { data = require(script.Parent.KitsuneEggModel), center = 1.6 },
	Nut = { data = require(script.Parent.NutEggModel), center = 1.6 },
	Geb = { data = require(script.Parent.GebEggModel), center = 1.6 },
	Bes = { data = require(script.Parent.BesEggModel), center = 1.6 },
	WarElephant = { data = require(script.Parent.WarElephantEggModel), center = 1.6 },
	SoulHorse = { data = require(script.Parent.SoulHorseEggModel), center = 1.6 },
	Squid = { data = require(script.Parent.SquidEggModel), center = 1.6 },
	Whale = { data = require(script.Parent.WhaleEggModel), center = 1.6 },
	KingCrab = { data = require(script.Parent.KingCrabEggModel), center = 1.6 },
	BlueCrab = { data = require(script.Parent.BlueCrabEggModel), center = 1.6 },
	RoboShark = { data = require(script.Parent.RoboSharkEggModel), center = 1.6 },
	VolcanoTortoise = { data = require(script.Parent.VolcanoTortoiseEggModel), center = 1.6 },
	Firebird = { data = require(script.Parent.FirebirdEggModel), center = 1.6 },
	RockHog = { data = require(script.Parent.RockHogEggModel), center = 1.6 },
	Rockworm = { data = require(script.Parent.RockwormEggModel), center = 1.6 },
	FireLobster = { data = require(script.Parent.FireLobsterEggModel), center = 1.6 },
	LavaWhale = { data = require(script.Parent.LavaWhaleEggModel), center = 1.6 },
	TRex = { data = require(script.Parent.TRexEggModel), center = 1.6 },
	Raptor = { data = require(script.Parent.RaptorEggModel), center = 1.6 },
	Spinosaurus = { data = require(script.Parent.SpinosaurusEggModel), center = 1.6 },
	Pterodactyl = { data = require(script.Parent.PterodactylEggModel), center = 1.6 },
	Ankylosaurus = { data = require(script.Parent.AnkylosaurusEggModel), center = 1.6 },
	PalmGuy = { data = require(script.Parent.PalmGuyEggModel), center = 1.6 },
	BoneRex = { data = require(script.Parent.BoneRexEggModel), center = 1.6 },
	Phoenix = { data = require(script.Parent.PhoenixEggModel), center = 1.6 },
	Starfish = { data = require(script.Parent.StarfishEggModel), center = 1.6 },
	Lionfish = { data = require(script.Parent.LionfishEggModel), center = 1.6 },
	RollingLog = { data = require(script.Parent.RollingLogEggModel), center = 1.6 },
	Tiger = { data = require(script.Parent.TigerEggModel), center = 1.6 },
	LionArcher = { data = require(script.Parent.LionArcherEggModel), center = 1.6 },
	Clownfish = { data = require(script.Parent.ClownfishEggModel), center = 1.6 },
	PinkButterfly = { data = require(script.Parent.PinkButterflyEggModel), center = 1.6 },
	FishSchool = { data = require(script.Parent.FishSchoolEggModel), center = 1.6 },
	Loong = { data = require(script.Parent.LoongEggModel), center = 1.6 },
	Beholder = { data = require(script.Parent.BeholderEggModel), center = 1.6 },
	Leviathan = { data = require(script.Parent.LeviathanEggModel), center = 1.6 },
	Sludge = { data = require(script.Parent.SludgeEggModel), center = 1.6 },
}

local Egg = {}
Egg.__index = Egg

function Egg.sizeOf(kind)
	return Config.EggSizePerTier ^ ((Config.PetTiers[kind] or 1) - 1)
end

function Egg.new(kind)
	kind = kind or "Horse"
	local def = KINDS[kind]
	local model, _, bones = Rig.fromData(def.data, kind .. "Egg", STUD_TEXTURE)
	model.PrimaryPart.PivotOffset = CFrame.new(0, def.center, 0)
	local size = Egg.sizeOf(kind)
	if size ~= 1 then
		model:ScaleTo(size)
		Egg.fitStuds(model)
	end
	return setmetatable({
		model = model,
		kind = kind,
		size = size,
		animations = def.data.animations,
		bones = bones,
		playing = nil,
		t = 0,
	}, Egg)
end

-- After scaling an egg's model (ScaleTo): its studs as a material (Shared/Studs)
-- don't scale with it the way stud Textures do, so they're picked for its size.
function Egg.fitStuds(model)
	Studs.fit(model, STUD_TEXTURE.tile * model:GetScale())
end

function Egg:play(name)
	self.playing = self.animations[name]
	self.t = 0
end

function Egg:isPlaying()
	return self.playing ~= nil
end

function Egg:update(dt)
	local anim = self.playing
	if not anim then
		return
	end
	self.t += dt
	local done = self.t >= anim.length
	local s = self.model:GetScale() -- the animations are in studs at 1x
	for bone, motor in pairs(self.bones) do
		local track = anim.tracks[bone]
		if done or not track then
			motor.Transform = CFrame.identity
		else
			local px, py, pz = 0, 0, 0
			local rx, ry, rz = 0, 0, 0
			if track.position then
				px, py, pz = Rig.sample(track.position, self.t)
			end
			if track.rotation then
				rx, ry, rz = Rig.sample(track.rotation, self.t)
			end
			motor.Transform = CFrame.new(px * s, py * s, pz * s) * CFrame.Angles(rx, ry, rz)
		end
	end
	if done then
		self.playing = nil
	end
end

return Egg
