-- The Halloween world's giga rares (QM, Oct 15: "giga rare haloween colored reskins of
-- legenaries"): nine Legendaries recoloured, the same models, bones and animations. Each
-- skin is its base's colours swapped one for one ("RRGGBB" from = "RRGGBB" to, exactly
-- as the base's *Model.luau and its egg's have them); any colour not listed stays.
-- Animals/Halloween<Base>.luau and their eggs (Eggs/Egg.luau) build from the base's data
-- through HalloweenSkins.model; tools/halloween_giga.py renders them from the same lists.
-- The Soul Valley boss (Bosses/GiantSoulHorse) is a skin too.
-- How often they run: Config.HalloweenGiga.

local SKINS = {
	HalloweenSnake = { -- a pumpkin snake: orange scales, black bands, a lime crest
		["F0BA48"] = "FF7A14", ["FCEABA"] = "3C2850", ["30C4D6"] = "8CF03C", ["A8304E"] = "241C2C",
		["EE6892"] = "B04CE0", ["D49646"] = "C85A10", ["FFD640"] = "AAFF50",
	},
	HalloweenUnicorn = { -- a night mare: black coat, purple horn and hooves, a Halloween rainbow
		["FCFAFF"] = "2C2438", ["F8F8F4"] = "2C2438", ["FFC83C"] = "B45AFF", ["F296C0"] = "8C46C8",
		["A064DC"] = "FF8218", ["B46EF0"] = "FF8218",
		["EC4848"] = "FF6A10", ["FF5A5A"] = "FF6A10", ["F89632"] = "FFA82A", ["FFAA3C"] = "FFA82A",
		["FAD63C"] = "C8FF46", ["FFE650"] = "C8FF46", ["60C85A"] = "6ED23C", ["6ED26E"] = "6ED23C",
		["4696EC"] = "A050F0", ["5AA0FF"] = "A050F0",
	},
	HalloweenKraken = { -- purple tentacles under a pumpkin cap, a lime eye
		["3A4C80"] = "6E32AA", ["28345E"] = "461E6E", ["922E3C"] = "FF8C1E", ["681E2E"] = "B4500A",
		["FFFFFF"] = "A0FF3C",
	},
	HalloweenBoneRex = { -- QM: "white and purple": bone-white bones, purple soul fire
		["423C4C"] = "EEE8DC", ["2E2A38"] = "C8C0B6", ["282232"] = "3C1E56",
		["3CFF6E"] = "B450FF", ["DCFFC8"] = "F0C8FF",
		["34303E"] = "EEE8DC", ["968CA6"] = "C8C0B6", ["766C86"] = "D8D0C4", ["24202C"] = "3C1E56", ["14101A"] = "28143C",
	},
	HalloweenSeraph = { -- purple rings, glowing orange wings and eyes, a lime halo
		["FFFFFF"] = "FFA02A", ["FFC226"] = "8C46D2", ["DE9218"] = "50248C", ["FFD678"] = "FF8C1E",
		["FFF4D6"] = "FFBE5A", ["FFE25A"] = "96FF3C", ["46B2FF"] = "FF7800",
	},
	HalloweenKitsune = { -- a black fox spirit with purple fox-fire, orange rope and bow
		["FAF8F4"] = "2C2438", ["ECE4D6"] = "463A58", ["50C4FF"] = "B446FF",
		["C4F0FF"] = "E6B4FF", ["DE2634"] = "FF7410", ["FFC434"] = "A0E63C", ["FFB01E"] = "96FF3C",
		["78E6FF"] = "C878FF", ["261E2C"] = "8C46C8", ["E8CE8C"] = "6E4A2C",
	},
	HalloweenLoong = { -- a purple dragon with orange spikes and whiskers and lime bands
		["799235"] = "7832B4", ["C9BDA2"] = "F08C28", ["822629"] = "FF6E14",
		["961C24"] = "FF6E14", ["FFD815"] = "A0F032", ["E9C573"] = "D2A0F0", ["E38E16"] = "C85A0A",
		["00FF86"] = "FF8C00",
	},
	HalloweenPhoenix = { -- a purple firebird with a black body and lime flame tips
		["FF8418"] = "8C3CD2", ["FFBC24"] = "BE64FF", ["FFE854"] = "A0FF46", ["CE2228"] = "281E32",
		["F04820"] = "50287A",
	},
	HalloweenCrystalElephant = { -- black armour, orange glowing crystals, lime crystal spikes
		["00BEE7"] = "FF780A", ["E583FB"] = "96F03C", ["5636A8"] = "282034", ["8A8EB6"] = "5A4A78",
		["B0F6FF"] = "FFC878", ["D2D6EC"] = "C8AAE6", ["686A96"] = "3C3250", ["3A2478"] = "1C1626",
	},
	-- The Soul Valley boss (QM, Oct 15: "a giant soul horse make it reskinned to be cooler"): an
	-- obsidian war horse with soul fire for a mane and tail and glowing teal spikes, trim and hooves.
	GiantSoulHorse = {
		["223C34"] = "141A1E", ["182824"] = "141A1E", ["8490A2"] = "465264", ["70609C"] = "2AD6B4",
		["464A2E"] = "3C1E56", ["50DCFF"] = "C8FFF0",
	},
}
-- Parts whose names have any of `names` in them glow (Neon) in `color` (a skin's soul fire).
local GLOW = {
	GiantSoulHorse = { color = "3CFFD2", names = { "Spike", "Trim", "Mane", "Tail", "Hoof" } },
}

local HalloweenSkins = {}

-- The base each skin recolours (its Animals/ module's name).
HalloweenSkins.Base = {
	HalloweenSnake = "Snake",
	HalloweenUnicorn = "Unicorn",
	HalloweenKraken = "Kraken",
	HalloweenBoneRex = "BoneRex",
	HalloweenSeraph = "Seraph",
	HalloweenKitsune = "Kitsune",
	HalloweenLoong = "Loong",
	HalloweenPhoenix = "Phoenix",
	HalloweenCrystalElephant = "CrystalElephant",
}

local function hex(c)
	return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

-- `data` (a *Model.luau's table: an animal's or its egg's) with its parts in `kind`'s colours.
function HalloweenSkins.model(kind, data)
	local swap = SKINS[kind]
	local out = table.clone(data)
	out.parts = {}
	local glow = GLOW[kind]
	for i, part in data.parts do
		local to = swap[hex(part.color)]
		if to then
			part = table.clone(part)
			part.color = Color3.fromHex(to)
		end
		for _, name in if glow then glow.names else {} do
			if string.find(part.name, name, 1, true) then
				part = table.clone(part)
				part.color, part.neon = Color3.fromHex(glow.color), true
				break
			end
		end
		out.parts[i] = part
	end
	return out
end

HalloweenSkins.SKINS, HalloweenSkins.GLOW = SKINS, GLOW
return HalloweenSkins
