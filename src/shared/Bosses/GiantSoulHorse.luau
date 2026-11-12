-- The Giant Soul Horse: the Halloween world's Soul Valley boss (QM, Oct 15: "a giant soul horse make it
-- reskinned to be cooler"). The Soul Horse's model and animations in obsidian and steel, its spikes,
-- trim, mane, tail and hooves glowing teal soul fire (Shared/HalloweenSkins).

local Horse = require(script.Parent.Parent.Animals.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)
local SoulHorseModel = require(script.Parent.Parent.Animals.SoulHorseModel)

return Horse.variant("GiantSoulHorse", HalloweenSkins.model("GiantSoulHorse", SoulHorseModel), "Legendary", {
	seat = Vector3.new(0, 7.3, 1), -- (the Soul Horse's; no one rides the boss)
	neck = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 },
	size = 5.3, -- x the model: about 65 studs tall (a guess; Studio tunes it)
})
