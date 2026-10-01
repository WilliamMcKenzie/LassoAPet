-- Eggs built from Blockbench models (designs/eggs/*.bbmodel, converted by
-- tools/bbmodel_to_luau.py). Every egg shares the same bones (egg, bottom,
-- top) so the twitch and hatch animations fit them all.
--
--   local egg = Egg.new("Horse")
--   egg.model:PivotTo(cframe)  -- pivot is the centre of the egg's body
--   egg:play("twitch")         -- a quick wobble; hatch comes later
--   egg:update(dt)             -- every frame while it can be playing
--
-- The black plates on the crack faces stay hidden inside the egg until the
-- top shell pops off.

local Rig = require(script.Parent.Parent.Animals.Rig)

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
	PolarBear = { data = require(script.Parent.PolarBearEggModel), center = 1.6 },
	IceWyvern = { data = require(script.Parent.IceWyvernEggModel), center = 1.6 },
}

local Egg = {}
Egg.__index = Egg

function Egg.new(kind)
	kind = kind or "Horse"
	local def = KINDS[kind]
	local model, _, bones = Rig.fromData(def.data, kind .. "Egg", STUD_TEXTURE)
	model.PrimaryPart.PivotOffset = CFrame.new(0, def.center, 0)
	return setmetatable({
		model = model,
		kind = kind,
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
			motor.Transform = CFrame.new(px, py, pz) * CFrame.Angles(rx, ry, rz)
		end
	end
	if done then
		self.playing = nil
	end
end

return Egg
