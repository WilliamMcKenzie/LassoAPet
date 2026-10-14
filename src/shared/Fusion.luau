-- FUSE (QM, Oct 6): two of your pets of different kinds become one hybrid. The one
-- picked first (on the left) is the base: its model and animations (QM, Oct 6 20:00;
-- it used to be the rarer one). The other one, the donor, on the right, gives its
-- ability, or the base's if it has none (QM, 20:13/20:19: Ride's vfx.abilityOf), and
-- sets its size if it's the bigger (a Loong donor makes a giant Pig; QM, Oct 8: never smaller) and
-- paints it in its own colours, slot for slot (Shared/Palettes). It earns what both
-- earned, and runs as fast and lasts as long as the better of the two (QM, Oct 6
-- 20:53). Two of the same hybrid merge like any other pets (Shared/Merge).
--
-- A pen item or the ridden pet keeps its base in `pet` (or `ride`) as before, and
-- the donor in `fuse`; what it earns a second is in `income`, its Speed and Stamina
-- in `stats` (`rideStats`).
--
--   Fusion.key(kind, fuse)        "Loong:Pig", or just the kind for a plain pet
--   Fusion.split(key)             kind, fuse
--   Fusion.combine(a, aFuse, b, bFuse)  what fusing two pets (hybrids too) makes
--   Fusion.stats(kind, fuse, saved)  its Speed and Stamina (Config.AnimalStats)
--   Fusion.best(a, b)             the higher Speed and higher Stamina of two stats
--   Fusion.tier(kind, fuse, saved)  its size tier (a hybrid's saved one, else the bigger of its two)
--   Fusion.scale(kind, fuse, saved) how much bigger that makes it than its base (never smaller)
--   Fusion.name(kind, fuse)       "Poong": the donor's front and the base's back
--   Fusion.paint(model, kind, fuse)  repaints a built model in the donor's palette
--   Fusion.worth(kind, fuse, saved) what went into a pet by rarity (a hybrid: all its pets; saved, no longer priced)
--   Fusion.earning(kind, merged, income)  what a pet earns a second
--   Fusion.price(income)             the gold FUSE charges for two earning that (Config.FusePriceSeconds)

local Config = require(script.Parent.Config)
local Palettes = require(script.Parent.Palettes)

local Fusion = {}

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

local function rgbKey(r, g, b)
	return r * 65536 + g * 256 + b
end

-- [kind] = { slots = { [rgb key] = slot }, base = { [slot] = Color3 }, parts = { [name] = slot } }
local sorted = {}
for kind, list in Palettes do
	local s = { slots = {}, base = {}, parts = list.parts or {} }
	for _, entry in ipairs(list) do
		local slot, r, g, b = entry[1], entry[2], entry[3], entry[4]
		s.slots[rgbKey(r, g, b)] = slot
		s.base[slot] = s.base[slot] or Color3.fromRGB(r, g, b)
	end
	sorted[kind] = s
end

function Fusion.key(kind, fuse)
	return if fuse then kind .. ":" .. fuse else kind
end

function Fusion.split(key)
	local kind, fuse = string.match(key, "^([^:]+):(.+)$")
	if kind then
		return kind, fuse
	end
	return key, nil
end

local function rarityRank(kind)
	local Animals = script.Parent.Animals
	local module = Animals:FindFirstChild(kind)
	local ok, class = pcall(require, module)
	return ok and class and table.find(RARITIES, class.Rarity) or 0
end

-- A pet's rarity: a hybrid's is the rarer of its two animals' (QM, Oct 7), so
-- fusing never lowers it. (An Exclusive, past Legendary, outranks the lot.)
function Fusion.rarity(kind, fuse)
	local function of(k)
		local module = k and script.Parent.Animals:FindFirstChild(k)
		local ok, class = pcall(require, module)
		local rarity = ok and class and class.Rarity or "Common"
		return rarity, table.find(RARITIES, rarity) or #RARITIES + 1
	end
	local rarity, rank = of(kind)
	if fuse then
		local other, otherRank = of(fuse)
		if otherRank > rank then
			rarity = other
		end
	end
	return rarity
end

-- Fusing two pets, either of them a hybrid already (QM, Oct 6: hybrids fuse again):
-- pet A (the left one) gives the body, its base animal, and pet B (the right one)
-- what it looks like, its donor's colours and size if it's a hybrid, else its own.
-- Returns the new base and donor, and true (pet A is the base). Two of the same
-- animal fuse too (QM, Oct 7: same rules, it's worth it): a Horse with a Horse is a
-- hybrid whose donor is its own kind.
function Fusion.combine(a, aFuse, b, bFuse)
	return a, bFuse or b, true
end

local ONE = { Speed = 1, Stamina = 1 }

-- A pet's Speed and Stamina (Config.AnimalStats, 1x if not listed). A hybrid's are
-- the best of the two pets fused into it, saved when it was made (`saved`, as a
-- hybrid of hybrids keeps what its picks had); one fused before that has the
-- better of its base's and donor's.
function Fusion.stats(kind, fuse, saved)
	if not fuse then
		return Config.AnimalStats[kind] or ONE
	end
	local stats = if typeof(saved) == "table" and tonumber(saved.Speed) and tonumber(saved.Stamina) then saved
		else Fusion.best(Config.AnimalStats[kind] or ONE, Config.AnimalStats[fuse] or ONE)
	if Config.slowedHere(kind, fuse) then -- (a World 1 hybrid in World 2: a Horse's speed, QM Oct 14)
		return { Speed = Config.AnimalStats.Horse.Speed, Stamina = stats.Stamina }
	end
	return stats
end

-- The best of both worlds (QM): the faster one's Speed plus Config.FuseSpeedShare of the
-- slower one's (QM, Oct 11: 0.15; Oct 7 had half), and the longer one's Stamina.
function Fusion.best(a, b)
	return {
		Speed = math.max(a.Speed, b.Speed) + math.min(a.Speed, b.Speed) * Config.FuseSpeedShare,
		Stamina = math.max(a.Stamina, b.Stamina),
	}
end

-- A hybrid is the size of the bigger of its two (QM, Oct 8: merging only ever makes
-- a pet bigger; it used to take the donor's size tier, so a Pig donor shrank a Loong
-- 4x). Each tier is Config.TierGrowth bigger than the one below: a Loong (tier 4)
-- with a Pig donor stays Loong-sized, a Pig with a Loong donor is 1.6^3 = 4x bigger.
-- A pet's size tier: a hybrid's saved one (`tier`, the bigger of the two fused into it,
-- so fusing it again can't shrink it either), else the bigger of its base's and donor's.
function Fusion.tier(kind, fuse, tier)
	local own = Config.PetTiers[kind] or 1
	if not fuse then
		return own
	end
	return tonumber(tier) or math.max(own, Config.PetTiers[fuse] or 1)
end

function Fusion.scale(kind, fuse, tier)
	if not fuse then
		return 1
	end
	return Config.TierGrowth ^ math.max(Fusion.tier(kind, fuse, tier) - (Config.PetTiers[kind] or 1), 0)
end

-- Hybrid names (QM, Oct 6): the donor's front half and the base's back half, so a
-- Unicorn donor on a Robo Shark is a "Unishark". Split by hand: compound names at
-- the join, longer ones by syllable, one-syllable ones before the vowel. Those
-- have a second front with the vowel ("Sna"), for a back that starts with a
-- consonant (Snake on a Horse: "Snase", not "Snse"). Where two vowels meet, one
-- goes ("Kra" + "ale" = "Krale"). Names can repeat: they're only for show.
local NAMES = {
	Horse = { "Hor", "se" }, Pinto = { "Pin", "to" }, Pig = { "P", "ig", "Pi" }, Bunny = { "Bun", "ny" }, Fish = { "F", "ish", "Fi" },
	Rhino = { "Rhi", "no" }, Unicorn = { "Uni", "corn" }, MarbleColossus = { "Mar", "lossus" }, MarbleFish = { "Mar", "fish" }, Catfish = { "Cat", "fish" }, Lion = { "L", "ion", "Li" }, Buffalo = { "Buf", "falo" }, Crocodile = { "Croc", "dile" }, MajesticUnicorn = { "Majes", "corn" }, CrystalCentipede = { "Crys", "pede" }, CrystalPhoenix = { "Crys", "nix" }, PinkButterfly = { "Pink", "fly" }, RedMushroom = { "Red", "shroom" }, BrownMushroom = { "Brown", "shroom" }, PurpleMushroom = { "Purp", "shroom" }, BlueCrystal = { "Blue", "crystal" }, PinkCrystal = { "Pink", "crystal" }, CrystalSpider = { "Crys", "pider" }, Cactus = { "Cac", "tus" }, Kitten = { "Kit", "ten" }, Scorpion = { "Scor", "pion" }, CrystalElephant = { "Crys", "phant" }, OrangeButterfly = { "Or", "fly" }, LivingBirch = { "Birch", "birch" }, Hawkmoth = { "Hawk", "moth" }, Fox = { "F", "ox", "Fo" }, TombJackal = { "Jack", "kal" }, NineTailedFox = { "Nine", "tails" },
	Sandworm = { "Sand", "worm" }, Eyeworm = { "Eye", "worm" }, Caterpillar = { "Cater", "pillar" }, Maw = { "M", "aw", "Ma" }, CrimsonScorpion = { "Crim", "pion" }, IvorySpider = { "Ivo", "spider" }, BlackWidow = { "Black", "dow", "Wid" }, Asura = { "As", "ura", "Asu" }, Seraph = { "Ser", "aph" }, CrimsonSeraph = { "Crim", "raph" }, CrystalSeraph = { "Crys", "raph" }, SpineLizard = { "Spine", "lizard" }, Snake = { "Sn", "ake", "Sna" },
	EagleSentry = { "Ea", "sentry" },
	Beholder = { "Be", "holder" }, Penguin = { "Pen", "guin" }, Snowman = { "Snow", "man" }, Boar = { "B", "oar", "Bo" },
	IceGolem = { "Ice", "golem" }, SnackYak = { "Snack", "yak" }, Icebringer = { "Ice", "bringer" },
	Starfish = { "Star", "fish" }, Lionfish = { "Lion", "fish" }, Clownfish = { "Clown", "fish" }, Whale = { "Wh", "ale", "Wha" }, Squid = { "Sq", "uid", "Squi" },
	JadeStatue = { "Jade", "tue" }, GarnetStatue = { "Gar", "net" },
	Kraken = { "Kra", "ken" }, GiantGolem = { "Gi", "golem" }, KingCrab = { "King", "crab" }, BlueCrab = { "Blue", "crab" }, VolcanoTortoise = { "Volca", "toise" }, Firebird = { "Fire", "bird" }, RockHog = { "Rock", "hog" }, Rockworm = { "Rock", "worm" }, FireLobster = { "Fire", "lobster" }, LavaWhale = { "Lava", "whale" }, TRex = { "T-", "Rex" }, BoneRex = { "Bone", "rex" }, Ankylosaurus = { "Ankylo", "saurus" }, PalmGuy = { "Palm", "guy" }, Spinosaurus = { "Spino", "saurus" }, Pterodactyl = { "Ptero", "dactyl" }, Raptor = { "Rap", "tor" }, Phoenix = { "Phoe", "nix" }, Kitsune = { "Kit", "sune" }, Nut = { "N", "ut", "Nu" }, Geb = { "G", "eb", "Ge" }, Bes = { "Be", "es", "Bes" }, BloatedMummy = { "Bloat", "mummy" }, Scarab = { "Sca", "rab" },
	RollingLog = { "Rol", "log" },
	Tiger = { "Ti", "ger" }, LionArcher = { "Lion", "archer" },
	RoboShark = { "Robo", "shark" }, FishSchool = { "Fish", "school" }, Loong = { "L", "oong", "Loo" },
	WarElephant = { "War", "elephant" }, SoulHorse = { "Soul", "horse" }, Sludge = { "Slu", "udge" },
	Leviathan = { "Levi", "athan" },
}
local VOWELS = { a = true, e = true, i = true, o = true, u = true }

local function spaced(kind)
	return (string.gsub(kind, "(%l)(%u)", "%1 %2"))
end

-- What a pet adds to FUSE's price: its rarity's (Config.FusePrice), so a Legendary
-- and a Rare are $1,010,000. A hybrid's is every pet that went into it added up
-- (QM), saved on it as `worth`; one fused before that counts its two kinds.
function Fusion.worth(kind, fuse, saved)
	if fuse and tonumber(saved) then
		return tonumber(saved)
	end
	local function one(k)
		return Config.FusePrice[RARITIES[rarityRank(k)] or "Common"] or 0
	end
	return one(kind) + (if fuse then one(fuse) else 0)
end

-- What a pet earns a second: a hybrid's saved income, else its kind's times its merges.
function Fusion.earning(kind, merged, income)
	return tonumber(income) or (Config.PetIncome[kind] or 0) * (merged or 1)
end

-- The gold FUSE charges for two pets earning `income` a second between them
-- (Config.FusePriceSeconds of it: QM, Oct 11).
function Fusion.price(income)
	return math.floor(income * Config.FusePriceSeconds + 0.5)
end

function Fusion.name(kind, fuse)
	if not fuse or fuse == kind then
		return spaced(kind) -- (two of the same: just its name, "Buny" and "Kiten" read wrong)
	end
	local front, back = NAMES[fuse], NAMES[kind]
	if not front or not back then
		return spaced(kind) .. " x " .. spaced(fuse) -- (a new animal not split yet)
	end
	local f, b = front[1], back[2]
	local first = string.sub(b, 1, 1)
	if not VOWELS[first] and front[3] then
		f = front[3]
	end
	local last = string.lower(string.sub(f, -1))
	if (VOWELS[last] and VOWELS[first]) or last == first then
		b = string.sub(b, 2)
	end
	return f .. b -- (the front is capitalised, the back isn't)
end

-- The donor's colour for a slot it doesn't have, made from the ones it does.
local function lighter(c, f)
	return c:Lerp(Color3.new(1, 1, 1), f)
end
local function darker(c, f)
	return c:Lerp(Color3.new(0, 0, 0), f)
end
local function donorColor(base, slot)
	if base[slot] then
		return base[slot]
	end
	local body = base.Body or Color3.fromRGB(200, 200, 200)
	if slot == "Belly" then
		return lighter(body, 0.55)
	elseif slot == "Marking" then
		return darker(body, 0.35)
	elseif slot == "Accent" then
		return if base.Marking then lighter(base.Marking, 0.3) else lighter(body, 0.3)
	elseif slot == "Horn" then
		return base.Hoof or lighter(body, 0.6)
	elseif slot == "Hoof" then
		return base.Horn or darker(body, 0.5)
	end
	return body
end

-- A shade of the base's slot colour `from` (`c`) moved onto the donor's `to`: as
-- much darker or lighter, as much more or less saturated, and a hue nudge if it
-- was only a nudge (a bigger jump in hue is a different colour, and takes the
-- donor's).
local function shade(c, from, to)
	if c == from then
		return to
	end
	local h, s, v = c:ToHSV()
	local h0, s0, v0 = from:ToHSV()
	local h1, s1, v1 = to:ToHSV()
	local dh = (h - h0 + 0.5) % 1 - 0.5
	local hue = (h1 + (if math.abs(dh) < 0.08 then dh else 0)) % 1
	local sat = if s0 > 0.05 then s1 * s / s0 else s1 + (s - s0)
	local val
	if v <= v0 then
		val = v1 * (if v0 > 0 then v / v0 else 1)
	else
		val = v1 + (1 - v1) * (v - v0) / math.max(1 - v0, 0.01)
	end
	return Color3.fromHSV(hue, math.clamp(sat, 0, 1), math.clamp(val, 0, 1))
end

local function round(c)
	return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
end

-- What `color` (one of `kind`'s, on a part called `name`) becomes in `fuse`'s palette.
function Fusion.recolor(kind, fuse, name, color)
	local own, donor = sorted[kind], sorted[fuse]
	if not own or not donor then
		return color
	end
	local slot = own.parts[name] or own.slots[rgbKey(round(color))]
	if not slot or slot == "Fixed" then
		return color
	end
	local from = own.base[slot] or color
	return shade(color, from, donorColor(donor.base, slot))
end

-- Repaints a model built from `kind` (Rig.fromData's parts, and the stud textures
-- tinted to match) in `fuse`'s palette. Every part keeps its original colour in
-- the "BaseColor" attribute, so painting again (another donor) starts from it; no
-- donor puts its own colours back.
function Fusion.paint(model, kind, fuse)
	if not model then
		return
	end
	for _, part in model:GetDescendants() do
		local original = part:IsA("BasePart") and (part:GetAttribute("BaseColor") or (fuse and part.Color))
		if original then
			part:SetAttribute("BaseColor", original)
			local color = if fuse then Fusion.recolor(kind, fuse, part.Name, original) else original
			for _, texture in part:GetChildren() do
				if texture:IsA("Texture") and texture.Color3 == part.Color then -- (only the metal weld's is tinted to match)
					texture.Color3 = color
				end
			end
			part.Color = color
		end
	end
end

return Fusion
