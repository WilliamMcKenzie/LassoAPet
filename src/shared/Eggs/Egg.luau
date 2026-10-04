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

-- Classic stud decal, the same one the animals use.
local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 }

local KINDS = {
	Horse = { data = require(script.Parent.HorseEggModel), center = 1.6 },
	Pinto = { data = require(script.Parent.PintoEggModel), center = 1.6 },
	Pig = { data = require(script.Parent.PigEggModel), center = 1.6 },
	Fish = { data = require(script.Parent.FishEggModel), center = 1.6 },
	Rhino = { data = require(script.Parent.RhinoEggModel), center = 1.6 },
	Unicorn = { data = require(script.Parent.UnicornEggModel), center = 1.6 },
	Cactus = { data = require(script.Parent.CactusEggModel), center = 1.6 },
	Scorpion = { data = require(script.Parent.ScorpionEggModel), center = 1.6 },
	Sandworm = { data = require(script.Parent.SandwormEggModel), center = 1.6 },
	Snake = { data = require(script.Parent.SnakeEggModel), center = 1.6 },
	Penguin = { data = require(script.Parent.PenguinEggModel), center = 1.6 },
	Snowman = { data = require(script.Parent.SnowmanEggModel), center = 1.6 },
	SpineLizard = { data = require(script.Parent.SpineLizardEggModel), center = 1.6 },
	Boar = { data = require(script.Parent.BoarEggModel), center = 1.6 },
	IceGolem = { data = require(script.Parent.IceGolemEggModel), center = 1.6 },
	SnackYak = { data = require(script.Parent.SnackYakEggModel), center = 1.6 },
	Icebringer = { data = require(script.Parent.IcebringerEggModel), center = 1.6 },
	Kraken = { data = require(script.Parent.KrakenEggModel), center = 1.6 },
	WarElephant = { data = require(script.Parent.WarElephantEggModel), center = 1.6 },
	SoulHorse = { data = require(script.Parent.SoulHorseEggModel), center = 1.6 },
	Squid = { data = require(script.Parent.SquidEggModel), center = 1.6 },
	Whale = { data = require(script.Parent.WhaleEggModel), center = 1.6 },
	KingCrab = { data = require(script.Parent.KingCrabEggModel), center = 1.6 },
	BlueCrab = { data = require(script.Parent.BlueCrabEggModel), center = 1.6 },
	RoboShark = { data = require(script.Parent.RoboSharkEggModel), center = 1.6 },
	Starfish = { data = require(script.Parent.StarfishEggModel), center = 1.6 },
	FishSchool = { data = require(script.Parent.FishSchoolEggModel), center = 1.6 },
	Loong = { data = require(script.Parent.LoongEggModel), center = 1.6 },
	Beholder = { data = require(script.Parent.BeholderEggModel), center = 1.6 },
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
