-- Every animal's colours, sorted by hand by what they colour (QM, Oct 6: "they must be
-- categorized categorically"), into one palette format every animal shares. A
-- fusion (Shared/Fusion) repaints its base animal in another animal's palette, slot
-- for slot. This never changes how any animal looks on its own.
--
-- The slots:
--   Body     its skin, fur, scales or shell: most of it
--   Belly    the lighter underside: belly, chest, chin, underside of a shell
--   Marking  its main pattern: mane and tail hair, stripes, bands, crest, back plates
--   Accent   a second pattern or trim: spots, rings, bib, sails, glyphs, tatters
--   Horn     hard bits on the head and body: horns, tusks, spikes, crystals, beaks
--   Hoof     the feet: hooves, claws, toes
--
-- Each entry is { slot, r, g, b }: one of the animal's colours (exactly as its
-- *Model.luau has it) and the slot it belongs to. The first colour listed for a slot
-- is that slot's own colour; any more in the same slot are its shades (darker or
-- lighter versions), which keep their shading when the slot is repainted.
-- `parts` sorts a part by name where its colour alone can't say (a colour shared by
-- the Snack Yak's snout and its saddle); "Fixed" keeps a part as it is.
--
-- Anything not listed never changes: eyes, pupils, teeth, mouths, tongues,
-- nostrils, noses, inside ears, glows, the Unicorn's rainbow, and gear (saddles,
-- armour, scarves, bags, the Snack Yak's snacks).

return {
	Horse = {
		{ "Body", 226, 130, 50 }, -- head, neck, body, legs, ears
		{ "Marking", 92, 54, 34 }, -- mane, forelock, stripe, tail
		{ "Hoof", 74, 78, 102 },
	},
	Pinto = {
		{ "Body", 248, 248, 244 }, -- white body, legs, snout, blaze
		{ "Marking", 70, 42, 30 }, -- mane, forelock, stripe, tail
		{ "Accent", 150, 84, 46 }, -- brown head, neck and spots
		{ "Hoof", 60, 60, 72 },
	},
	Unicorn = {
		{ "Body", 252, 250, 255 },
		{ "Marking", 160, 100, 220 }, -- purple mane, forelock, tail tip
		{ "Horn", 255, 200, 60 }, -- golden horn
		parts = { HoofFL = "Hoof", HoofFR = "Hoof", HoofHL = "Hoof", HoofHR = "Hoof" }, -- (gold like the horn)
	},
	Pig = {
		{ "Body", 246, 164, 184 },
		{ "Body", 250, 196, 208 }, -- snout
		{ "Hoof", 176, 96, 116 },
	},
	Bunny = {
		{ "Body", 206, 150, 98 },
		{ "Belly", 250, 236, 212 }, -- muzzle
		parts = { HoofFL = "Hoof", HoofFR = "Hoof", HoofHL = "Hoof", HoofHR = "Hoof" }, -- (cream paws, like the muzzle)
	},
	MajesticUnicorn = {
		{ "Body", 252, 250, 255 }, -- pearl coat
		{ "Belly", 226, 214, 246 }, -- lilac socks and muzzle
		{ "Horn", 255, 200, 60 }, -- gold horn and brows
		parts = { HoofFL = "Hoof", HoofFR = "Hoof", HoofHL = "Hoof", HoofHR = "Hoof" }, -- (gold like the horn)
	},
	MarbleColossus = {
		{ "Body", 246, 244, 238 }, -- marble
		{ "Body", 208, 205, 198 }, -- chest, shoulders, brow (shade)
		{ "Hoof", 226, 223, 216 }, -- fists
		{ "Horn", 240, 190, 24 }, -- gold spikes, bracers, headband
	},
	Rhino = {
		{ "Body", 150, 156, 170 },
		{ "Marking", 112, 118, 134 }, -- back plates, tail tip
		{ "Horn", 240, 232, 208 },
		{ "Hoof", 84, 88, 102 },
	},
	Fish = {
		{ "Body", 60, 132, 232 },
		{ "Belly", 222, 240, 255 },
		{ "Marking", 36, 88, 184 }, -- fins
	},
	Catfish = {
		{ "Body", 112, 146, 52 },
		{ "Belly", 243, 231, 181 },
		{ "Marking", 74, 104, 38 }, -- fins
		{ "Marking", 78, 108, 36 }, -- spots
		{ "Whisker", 58, 40, 24 },
	},
	BloatedMummy = {
		{ "Body", 242, 232, 200 }, -- fresh bandages: body, head, arms, legs
		{ "Body", 220, 201, 152 }, -- sand wraps
		{ "Body", 208, 184, 134 }, -- darker sand wraps, loose ends
		{ "Belly", 176, 150, 104 }, -- grime seams, lip
		{ "Accent", 240, 190, 24 }, -- gold collar, amulet, cuffs, anklets, headband
		{ "Accent", 196, 140, 16 }, -- darker gold
		{ "Marking", 40, 92, 206 }, -- lapis collar band, wings, gems
		{ "Horn", 226, 72, 40 }, -- carnelian collar band, sun disc
	},
	MarbleFish = {
		{ "Body", 255, 204, 36 },
		{ "Belly", 255, 244, 196 },
		{ "Marking", 232, 150, 16 }, -- fins
		{ "Horn", 246, 244, 238 }, -- marble horn
		{ "Horn", 208, 205, 198 },
	},
	Lion = {
		{ "Body", 232, 172, 72 },
		{ "Belly", 255, 238, 200 }, -- muzzle, chest, paws
		{ "Marking", 196, 102, 34 }, -- mane
		{ "Marking", 150, 70, 26 }, -- back of the mane, inner ears, tail tuft
		parts = { HoofFL = "Hoof", HoofFR = "Hoof", HoofHL = "Hoof", HoofHR = "Hoof" },
	},
	Buffalo = {
		{ "Body", 178, 114, 64 },
		{ "Marking", 120, 74, 44 }, -- hump, head, beard, cuffs, tufts
		{ "Belly", 184, 136, 98 }, -- snout
		{ "Horn", 240, 230, 205 },
		{ "Horn", 150, 146, 140 }, -- horn tips
		{ "Hoof", 58, 46, 42 },
	},
	Crocodile = {
		{ "Body", 88, 158, 64 },
		{ "Marking", 54, 112, 44 }, -- scutes, brows, feet, ridges
		{ "Belly", 214, 222, 140 },
		{ "Accent", 236, 120, 140 }, -- mouth
	},
	LionArcher = {
		{ "Body", 238, 192, 112 }, -- coat, legs, head, tail
		{ "Body", 214, 160, 84 }, -- haunches
		{ "Belly", 255, 238, 204 }, -- muzzle, chin, belly, paws
		{ "Marking", 34, 86, 210 }, -- nemes stripes, lappets, saddle cloth, beard bands, armband gems
		{ "Marking", 24, 56, 150 }, -- the nemes' back
		{ "Accent", 252, 200, 40 }, -- gold: nemes stripes, headband, cobra, collar, cuffs, trims, rings
		{ "Accent", 206, 150, 22 },
	},
	Tiger = {
		{ "Body", 247, 133, 32 },
		{ "Belly", 255, 248, 236 }, -- muzzle, chin, cheeks, chest, belly
		{ "Marking", 34, 30, 36 }, -- stripes, tail rings and tip
		parts = { PawFL = "Hoof", PawFR = "Hoof", PawHL = "Hoof", PawHR = "Hoof", EarLIn = "Fixed", EarRIn = "Fixed" },
	},
	Cactus = {
		{ "Body", 118, 204, 64 },
		{ "Marking", 72, 150, 44 }, -- ribs
		{ "Horn", 214, 176, 96 }, -- spines
	},
	Kitten = {
		{ "Body", 244, 150, 58 },
		{ "Belly", 255, 250, 242 }, -- muzzle, chest, tail tip
		{ "Marking", 204, 104, 34 }, -- tabby stripes, tail ring
		parts = { HoofFL = "Hoof", HoofFR = "Hoof", HoofHL = "Hoof", HoofHR = "Hoof" }, -- (white paws, like the chest)
	},
	Scorpion = {
		{ "Body", 230, 160, 74 },
		{ "Body", 184, 110, 50 }, -- every other tail segment, pincer fingers, shins
		{ "Marking", 160, 70, 60 }, -- shoulders, arms, thighs, tail bulb
		{ "Horn", 70, 44, 40 }, -- stinger
	},
	PurpleMushroom = {
		{ "Body", 226, 212, 194 }, -- the cream body
		{ "Hoof", 196, 178, 156 }, -- feet and the shaded bottom
		{ "Marking", 134, 83, 142 }, -- cap
		{ "Marking", 96, 59, 102 }, -- cap's underside (shade)
		{ "Accent", 250, 248, 252 }, -- spots
	},
	BrownMushroom = {
		{ "Body", 226, 212, 194 }, -- the cream body
		{ "Hoof", 196, 178, 156 }, -- feet and the shaded bottom
		{ "Marking", 131, 98, 103 }, -- cap
		{ "Marking", 94, 70, 74 }, -- cap's underside (shade)
	},
	RedMushroom = {
		{ "Body", 226, 212, 194 }, -- the cream body
		{ "Hoof", 196, 178, 156 }, -- feet and the shaded bottom
		{ "Marking", 210, 62, 40 }, -- cap
		{ "Marking", 151, 44, 28 }, -- cap's underside (shade)
		{ "Accent", 250, 248, 252 }, -- spots
	},
	BlueCrystal = {
		{ "Body", 0, 190, 231 }, -- crystal
		{ "Body", 90, 220, 245 }, -- facet stripe (lighter)
		{ "Hoof", 0, 150, 190 }, -- legs
		parts = { EyeL = "Fixed", EyeR = "Fixed", Mouth = "Fixed" },
	},
	PinkCrystal = {
		{ "Body", 229, 131, 251 }, -- crystal
		{ "Body", 242, 170, 253 }, -- facet stripe (lighter)
		{ "Hoof", 190, 100, 214 }, -- legs
		parts = { EyeL = "Fixed", EyeR = "Fixed", Mouth = "Fixed" },
	},
	LivingBirch = {
		{ "Body", 238, 234, 226 }, -- white bark
		{ "Body", 226, 221, 211 }, -- bark, legs
		{ "Marking", 52, 46, 44 }, -- birch bands and marks
		{ "Accent", 242, 109, 57 }, -- autumn leaves
		{ "Accent", 214, 72, 43 },
		{ "Accent", 248, 168, 64 },
		{ "Accent", 254, 234, 92 },
		{ "Accent", 196, 58, 36 },
		parts = { EyeL = "Fixed", EyeR = "Fixed", Mouth = "Fixed" },
	},
	TombJackal = {
		{ "Body", 58, 54, 84 },
		{ "Marking", 255, 196, 46 }, -- gold armour, collar, cuffs
		{ "Accent", 38, 92, 214 }, -- lapis stripes and drapes
		{ "Hoof", 34, 32, 46 }, -- paws, tail tip
	},
	Scarab = {
		{ "Body", 31, 181, 168 }, -- teal shell, shield, tibias
		{ "Body", 18, 120, 120 }, -- darker teal head and tail
		{ "Belly", 42, 38, 52 }, -- dark underside, femurs, mandibles, claws
		{ "Marking", 242, 194, 48 }, -- gold seam, rims, ankhs, shovel, knees, feet
		{ "Accent", 46, 91, 216 }, -- lapis stripes and glyph tiles
		{ "Horn", 196, 146, 30 }, -- dark gold studs, spikes and horn
	},
	Fox = {
		{ "Body", 240, 128, 36 },
		{ "Belly", 255, 250, 242 }, -- chest, cheeks, chin, tail tip
		{ "Accent", 214, 40, 46 }, -- shrine bib
		{ "Hoof", 52, 40, 40 }, -- stockings, ear tips
	},
	NineTailedFox = {
		{ "Body", 250, 184, 52 },
		{ "Belly", 255, 250, 242 }, -- chest, cheeks, chin, tail tips
		{ "Marking", 200, 30, 60 }, -- ear tips, forehead flame, bib
		{ "Hoof", 52, 40, 40 }, -- stockings
	},
	CrystalElephant = {
		{ "Body", 138, 142, 182 }, -- lavender skin
		{ "Marking", 86, 54, 168 }, -- crystal armour plates
		{ "Horn", 0, 190, 231 }, -- cyan crystals and trim
		{ "Accent", 229, 131, 251 }, -- pink crystals
	},
	PinkButterfly = {
		{ "Body", 110, 44, 112 }, -- plum body
		{ "Marking", 255, 126, 200 }, -- bubblegum wings
		{ "Marking", 255, 200, 232 }, -- pale pink by the body
		{ "Accent", 255, 52, 156 }, -- hot-pink wing edges
		{ "Accent", 255, 110, 190 }, -- stripes and antenna tips
	},
	JadeStatue = {
		{ "Body", 64, 176, 110 }, -- jade body, legs, head, tail
		{ "Body", 34, 128, 80 }, -- mane, brow, shoulders, haunches
		{ "Belly", 132, 222, 164 }, -- muzzle, chin, paws, curls, tail plume
		{ "Marking", 24, 96, 62 }, -- carved veins
		{ "Horn", 240, 190, 24 }, -- gold crown, collar, bell, anklets, claws, ridge
		{ "Horn", 196, 140, 16 },
	},
	GarnetStatue = {
		{ "Body", 186, 28, 52 }, -- garnet body, legs, head, tail
		{ "Body", 122, 14, 36 }, -- mane, brow, shoulders, haunches
		{ "Belly", 236, 84, 102 }, -- muzzle, chin, paws, curls, tail plume, spine shards
		{ "Marking", 92, 8, 26 }, -- carved veins
		{ "Horn", 240, 190, 24 }, -- gold horns, collar, bell, anklets, claws, ridge
		{ "Horn", 196, 140, 16 },
	},
	EagleSentry = {
		{ "Body", 128, 78, 42 }, -- body, head, wing coverts, thighs
		{ "Body", 84, 50, 28 }, -- flight feathers, chest bars
		{ "Belly", 246, 232, 196 }, -- chest, cheeks, feather bands
		{ "Horn", 246, 192, 44 }, -- gold armour, headdress, spear, feather tips
		{ "Horn", 204, 146, 30 }, -- dark gold brows, rims, spear shaft
		{ "Accent", 36, 84, 196 }, -- lapis stripes and saddle
		{ "Marking", 34, 196, 196 }, -- turquoise collar row
	},
	Hawkmoth = {
		{ "Body", 62, 48, 44 }, -- body, head
		{ "Body", 84, 54, 40 }, -- forewings
		{ "Body", 32, 26, 28 }, -- collar, legs, antennae
		{ "Marking", 242, 109, 57 }, -- abdomen rings, hindwings, antenna tips
		{ "Accent", 160, 72, 38 }, -- forewing bands
		{ "Belly", 246, 228, 182 }, -- the skull on its back
		{ "Horn", 24, 20, 22 }, -- spikes, stinger, brows, wing edges, black rings
	},
	CrystalPhoenix = {
		{ "Body", 104, 58, 184 }, -- body, wing arms
		{ "Body", 146, 96, 226 }, -- head, neck, wing bands
		{ "Marking", 229, 131, 251 }, -- pink feathers
		{ "Accent", 0, 190, 231 }, -- cyan beak, feathers and crystals
	},
	OrangeButterfly = {
		{ "Body", 255, 128, 26 }, -- wings
		{ "Body", 242, 109, 57 }, -- wing edges
		{ "Body", 214, 74, 30 }, -- wing tips
		{ "Belly", 255, 196, 58 }, -- the wings' yellow by the body
		{ "Marking", 107, 63, 42 }, -- body, head, legs, antennae
		{ "Accent", 255, 200, 58 }, -- abdomen bands, eye spot middles
		{ "Accent", 255, 240, 214 }, -- collar fluff
		{ "Accent", 255, 244, 214 }, -- forewing spots
		{ "Hoof", 92, 50, 30 }, -- eye spots
	},
	CrystalSpider = {
		{ "Body", 96, 108, 200 },
		{ "Hoof", 66, 74, 152 }, -- lower legs
		{ "Horn", 0, 190, 231 }, -- cyan crystals, claws and fangs
		{ "Accent", 229, 131, 251 }, -- the pink crystal
	},
	CrystalCentipede = {
		{ "Body", 124, 72, 200 },
		{ "Hoof", 72, 44, 124 }, -- leg bars, tail feelers
		{ "Horn", 0, 190, 231 }, -- cyan crystals and pincers
		{ "Accent", 229, 131, 251 }, -- pink crystals
	},
	Caterpillar = {
		{ "Body", 112, 206, 58 },
		{ "Body", 156, 226, 70 }, -- the lime segments
		{ "Belly", 196, 232, 96 }, -- belly, snout
		{ "Accent", 255, 212, 40 }, -- back spots
		{ "Horn", 242, 109, 57 }, -- antenna tips
		{ "Hoof", 46, 122, 44 }, -- feet, antenna stalks
		parts = { Eye = "Fixed", Pupil = "Fixed", Mouth = "Fixed" },
	},
	Eyeworm = {
		{ "Body", 170, 22, 48 },
		{ "Belly", 214, 70, 92 },
		{ "Marking", 122, 44, 168 }, -- rings, brow, tail tip
		parts = { Eye = "Fixed", Pupil = "Fixed", Mouth = "Fixed" },
	},
	CrimsonScorpion = {
		{ "Body", 186, 26, 52 },
		{ "Body", 132, 16, 40 }, -- every other tail segment, pincer fingers, shins
		{ "Marking", 122, 44, 168 }, -- shoulders, arms, thighs, tail bulb
		{ "Horn", 44, 16, 48 }, -- stinger
	},
	Maw = {
		{ "Body", 170, 22, 48 },
		{ "Marking", 122, 44, 168 }, -- lips, tentacle tips
	},
	IvorySpider = {
		{ "Body", 246, 240, 226 },
		{ "Accent", 200, 190, 174 }, -- knees, spinnerets
		{ "Hoof", 150, 138, 126 }, -- feet, fangs
	},
	GreenCrab = { -- World 3 Pirate Cove (QM's green, Oct 14)
		{ "Body", 19, 139, 58 },
		{ "Body", 10, 105, 74 }, -- knees, elbows (darker)
		{ "Belly", 255, 226, 176 }, -- belly, mandibles
		{ "Hoof", 1, 56, 53 }, -- claw and leg tips
	},
	Parrot = {
		{ "Body", 232, 36, 44 },
		{ "Body", 168, 20, 36 }, -- back, belly (darker)
		{ "Belly", 250, 246, 240 }, -- face patches
		{ "Marking", 255, 206, 30 }, -- wing bands
		{ "Accent", 36, 112, 236 }, -- wings, tail tip
		{ "Accent", 24, 70, 180 }, -- flight feathers (darker)
		{ "Horn", 250, 236, 200 }, -- beak
	},
	BananaMonkey = {
		{ "Body", 140, 82, 44 },
		{ "Body", 96, 54, 30 }, -- back, brow, nose (darker)
		{ "Belly", 246, 200, 150 }, -- face, muzzle, hands, feet
		{ "Belly", 214, 160, 112 }, -- knuckles, inner ears
	},
	TreasureHermit = {
		{ "Body", 160, 70, 220 },
		{ "Body", 104, 40, 160 }, -- knees, eyeballs (darker)
		{ "Belly", 250, 200, 236 }, -- face
		{ "Hoof", 40, 30, 50 }, -- claw and leg tips
	},
	EyepatchShark = {
		{ "Body", 40, 150, 255 },
		{ "Body", 26, 96, 200 }, -- fins (darker)
		{ "Belly", 244, 244, 240 }, -- underside, teeth (QM's model, Oct 14)
	},
	TreasureTurtle = {
		{ "Body", 52, 196, 172 },
		{ "Body", 28, 140, 128 }, -- spots, head top (darker)
		{ "Marking", 60, 150, 60 }, -- shell
		{ "Marking", 34, 100, 44 }, -- shell's bottom tier
		{ "Horn", 250, 220, 120 }, -- beak, belly plate
	},
	GhostShip = {
		{ "Body", 124, 66, 170 }, -- hull
		{ "Body", 78, 38, 114 }, -- keel, jaw, brows (darker)
		{ "Marking", 176, 118, 72 }, -- decks, barrels
	},
	JollyRogerWyvern = {
		{ "Body", 248, 242, 222 }, -- bones
		{ "Body", 196, 182, 156 }, -- horns, spikes, joints (darker)
		{ "Accent", 36, 32, 48 }, -- sail wings
		{ "Accent", 24, 20, 32 }, -- sail wings (darker)
	},
	BlackWidow = {
		{ "Body", 22, 22, 28 },
		{ "Body", 48, 48, 62 }, -- glossy top of the abdomen, spinnerets (lighter)
		{ "Horn", 96, 100, 116 }, -- spikes, helm, flank armour, knee guards
		{ "Hoof", 62, 64, 78 }, -- claws, spike tips, helm rim
		{ "Horn", 236, 230, 214 }, -- fangs
	},
	Asura = {
		{ "Body", 72, 84, 85 }, -- armour
		{ "Body", 53, 67, 69 }, -- cape, grip (darker)
		{ "Marking", 121, 191, 202 }, -- hair, sword guard
		{ "Accent", 111, 120, 121 }, -- helm, mask, shoulder pads, belt
		{ "Horn", 130, 138, 140 }, -- blade
	},
	Sandworm = {
		{ "Body", 228, 178, 104 },
		{ "Belly", 248, 224, 172 },
		{ "Marking", 156, 98, 56 }, -- back plates, brow, tail spike
		{ "Horn", 54, 40, 50 }, -- horns, fins, mandibles, hooks
	},
	SpineLizard = {
		{ "Body", 236, 178, 84 },
		{ "Body", 206, 132, 60 }, -- back and tail stripes
		{ "Belly", 252, 234, 186 },
		{ "Marking", 170, 50, 78 }, -- crest spikes and sail rays
		{ "Accent", 250, 150, 52 }, -- sail
		{ "Accent", 252, 204, 76 }, -- sail, lighter panels
		{ "Hoof", 254, 246, 222 }, -- claws
	},
	Snake = {
		{ "Body", 240, 186, 72 },
		{ "Body", 212, 150, 70 }, -- middle rattle
		{ "Belly", 252, 234, 186 }, -- belly scales, rattle
		{ "Marking", 168, 48, 78 }, -- bands
		{ "Horn", 48, 196, 214 }, -- back spikes, brows, swept horns
		parts = { Nostril_L = "Fixed", Nostril_R = "Fixed" }, -- (band coloured)
	},
	Beholder = {
		{ "Body", 222, 136, 56 },
		{ "Body", 160, 92, 34 }, -- tentacle tips
		{ "Marking", 246, 186, 112 }, -- tentacle bands
	},
	Penguin = {
		{ "Body", 40, 46, 64 },
		{ "Belly", 250, 250, 250 },
		{ "Accent", 255, 200, 60 }, -- gold bib
		{ "Accent", 255, 170, 40 }, -- cheeks
		{ "Horn", 255, 140, 30 }, -- beak
		{ "Horn", 230, 100, 30 }, -- lower beak
		{ "Hoof", 255, 150, 30 }, -- feet
	},
	Snowman = {
		{ "Body", 246, 249, 255 },
		{ "Body", 226, 236, 252 }, -- middle snowball
		{ "Marking", 124, 82, 48 }, -- twig arms
	},
	Boar = {
		{ "Body", 176, 108, 68 },
		{ "Marking", 112, 66, 46 }, -- jaw, cheek tufts, mane
		{ "Marking", 236, 190, 136 }, -- brows
		{ "Horn", 254, 246, 222 }, -- tusks
		{ "Hoof", 86, 60, 52 },
	},
	IceGolem = {
		{ "Body", 160, 218, 250 }, -- head, chest, shoulders
		{ "Body", 82, 150, 226 }, -- legs, forearms, knuckles
		{ "Marking", 252, 253, 255 }, -- snow on its brow, shoulders and head
		{ "Horn", 96, 222, 255 }, -- crystals
	},
	SnackYak = {
		{ "Body", 95, 44, 32 }, -- body
		{ "Body", 102, 50, 34 }, -- thighs
		{ "Body", 66, 45, 28 }, -- head
		{ "Body", 51, 36, 30 }, -- shins
		{ "Body", 110, 58, 36 }, -- rump fringe
		{ "Body", 120, 66, 38 },
		{ "Body", 101, 50, 34 },
		{ "Body", 92, 41, 32 },
		{ "Marking", 234, 192, 74 }, -- golden fur
		{ "Marking", 230, 183, 72 }, -- fur on its head
		{ "Marking", 219, 163, 68 }, -- cheek fur
		{ "Marking", 245, 216, 78 }, -- bangs
		{ "Marking", 243, 211, 77 },
		{ "Marking", 232, 188, 72 },
		{ "Marking", 221, 163, 69 },
		{ "Horn", 199, 187, 131 },
		{ "Hoof", 49, 44, 35 },
		parts = { Snout = "Body" }, -- (its colour is the saddle's too)
	},
	Icebringer = {
		{ "Body", 49, 162, 242 },
		{ "Body", 25, 118, 237 }, -- biceps, jaw, chest, tusk roots
		{ "Marking", 196, 240, 252 }, -- brows and head crest
		{ "Horn", 170, 228, 248 }, -- head spikes, claws
		{ "Horn", 110, 220, 245 },
		{ "Horn", 243, 243, 243 }, -- tusks
	},
	Clownfish = {
		{ "Body", 255, 112, 16 },
		{ "Belly", 255, 150, 60 },
		{ "Marking", 255, 255, 255 }, -- bands
		{ "Accent", 24, 24, 30 }, -- band edges, fin tips
	},
	Starfish = {
		{ "Body", 255, 128, 64 },
		{ "Body", 232, 88, 52 }, -- arm tips
		{ "Belly", 255, 200, 156 },
		{ "Marking", 255, 214, 96 }, -- bumps
	},
	RollingLog = {
		{ "Body", 170, 100, 52 }, -- bark
		{ "Marking", 118, 66, 36 }, -- bark strips
		{ "Belly", 242, 206, 148 }, -- cut ends
		{ "Belly", 206, 148, 88 }, -- growth ring
		{ "Belly", 228, 180, 116 }, -- core
		{ "Horn", 176, 182, 196 }, -- spikes
		{ "Horn", 96, 100, 116 }, -- spike collars
	},
	Lionfish = {
		{ "Body", 255, 240, 214 },
		{ "Marking", 232, 72, 40 }, -- stripes, spines
		{ "Belly", 255, 214, 186 },
		{ "Accent", 150, 36, 52 }, -- fins
	},
	Whale = {
		{ "Body", 40, 116, 206 },
		{ "Belly", 214, 244, 250 },
		{ "Marking", 96, 226, 246 }, -- glyphs
		{ "Marking", 84, 170, 232 }, -- specks
	},
	Squid = {
		{ "Body", 255, 150, 160 }, -- tentacles
		{ "Body", 236, 112, 132 }, -- head, funnel
		{ "Marking", 255, 138, 72 }, -- cap
		{ "Marking", 226, 100, 50 }, -- cap rim
	},
	GiantGolem = {
		{ "Body", 150, 142, 132 }, -- stone
		{ "Body", 104, 97, 90 }, -- chest, forearms, head, spikes (shade)
		{ "Marking", 184, 177, 166 }, -- pale plates, caps, brow, knuckles
		{ "Accent", 110, 186, 68 }, -- moss
	},
	Geb = {
		{ "Body", 118, 150, 70 }, -- the bull's earth body and legs
		{ "Body", 92, 184, 84 }, -- the god's green skin
		{ "Marking", 168, 156, 132 }, -- stone plates, pauldrons, knees
		{ "Accent", 255, 196, 52 }, -- gold nemes, collar, bow, trims, hoof caps
	},
	Bes = {
		{ "Body", 220, 201, 152 }, -- sandstone
		{ "Belly", 208, 184, 134 }, -- darker stone: hips, shins, arms
		{ "Marking", 40, 86, 206 }, -- lapis stripes, pleats, kohl
		{ "Accent", 246, 196, 46 }, -- gold collar, kilt, crown, throne
	},
	Kitsune = {
		{ "Body", 250, 248, 244 }, -- white fur, tails, paws
		{ "Belly", 236, 228, 214 }, -- belly, jaw, chest tuft
		{ "Marking", 222, 38, 52 }, -- red markings, socks, mask, saddle cloth, bow
		{ "Accent", 255, 196, 52 }, -- gold anklets, ear rings, bell, trims
	},
	Nut = {
		{ "Body", 92, 150, 255 }, -- sky-blue skin, arms, feet
		{ "Belly", 252, 250, 244 }, -- white linen robe
		{ "Marking", 36, 44, 128 }, -- night-blue flight feathers, starry hem
		{ "Accent", 255, 196, 40 }, -- gold collar, diadem, wing bars, trims
	},
	Kraken = {
		{ "Body", 58, 76, 128 }, -- tentacles
		{ "Body", 40, 52, 94 }, -- head, funnel
		{ "Marking", 146, 46, 60 }, -- cap
		{ "Marking", 104, 30, 46 }, -- cap rim
	},
	FireLobster = {
		{ "Body", 226, 52, 36 }, -- shell
		{ "Body", 170, 32, 30 }, -- seams, fingers, shins, antennae
		{ "Marking", 255, 124, 40 }, -- shoulders, arms, thighs
	},
	Phoenix = {
		{ "Body", 206, 34, 40 }, -- body, wing arms
		{ "Body", 240, 72, 32 }, -- head, neck, wing bands
		{ "Marking", 255, 132, 24 }, -- feathers
		{ "Accent", 255, 188, 36 }, -- beak, feather ends, plumes
	},
	TRex = {
		{ "Body", 240, 140, 52 },
		{ "Belly", 252, 218, 166 },
		{ "Marking", 168, 82, 32 }, -- stripes, brow
	},
	Raptor = {
		{ "Body", 76, 154, 226 },
		{ "Belly", 252, 218, 166 },
		{ "Marking", 36, 70, 140 }, -- stripes
		{ "Accent", 255, 146, 46 }, -- crest, arm and tail feathers
	},
	Spinosaurus = {
		{ "Body", 64, 172, 132 },
		{ "Belly", 252, 218, 166 },
		{ "Marking", 36, 116, 92 }, -- stripes
		{ "Accent", 255, 136, 40 }, -- sail
	},
	PalmGuy = {
		{ "Body", 150, 110, 66 }, -- trunk
		{ "Body", 132, 96, 58 }, -- trunk, legs
		{ "Marking", 104, 74, 44 }, -- joint rings
		{ "Accent", 70, 156, 52 }, -- fronds, tufts
	},
	Ankylosaurus = {
		{ "Body", 236, 190, 62 },
		{ "Belly", 252, 218, 166 }, -- belly, beak
		{ "Marking", 138, 84, 40 }, -- armour bands, head plate, club
		{ "Accent", 250, 240, 214 }, -- spikes
	},
	BoneRex = {
		{ "Body", 66, 60, 76 }, -- bones
		{ "Body", 46, 42, 56 }, -- joints
		{ "Accent", 60, 255, 110 }, -- soul fire, spike tips, talons
	},
	Pterodactyl = {
		{ "Body", 150, 98, 222 },
		{ "Belly", 252, 218, 166 },
		{ "Marking", 82, 50, 156 }, -- stripes, brow
		{ "Accent", 255, 150, 72 }, -- wings
		{ "Accent", 255, 198, 52 }, -- beak
	},
	LavaWhale = {
		{ "Body", 182, 100, 62 }, -- rock
		{ "Body", 136, 74, 50 }, -- brow, horn bands
		{ "Belly", 246, 196, 140 }, -- ash
		{ "Marking", 255, 140, 30 }, -- lava glyphs
	},
	Firebird = {
		{ "Body", 255, 128, 32 }, -- feathers
		{ "Belly", 232, 98, 22 },
		{ "Marking", 64, 62, 70 }, -- beak, shins, feet, wing bars
		{ "Accent", 34, 32, 38 }, -- crest, brows, wing tips, tail
		{ "Hoof", 232, 224, 204 }, -- claws
	},
	RockHog = {
		{ "Body", 88, 98, 128 }, -- basalt coat
		{ "Marking", 54, 58, 82 }, -- jaw, cheeks, brows
		{ "Horn", 255, 120, 20 }, -- fiery horns, tusks and spikes
		{ "Hoof", 36, 38, 52 },
	},
	Rockworm = {
		{ "Body", 88, 98, 128 }, -- basalt segments
		{ "Marking", 54, 58, 82 }, -- plates
		{ "Belly", 120, 130, 162 },
		{ "Horn", 255, 120, 20 }, -- lava fins, horn, tail spike and fangs
	},
	VolcanoTortoise = {
		{ "Body", 178, 150, 102 }, -- skin, beak
		{ "Belly", 150, 122, 82 }, -- belly, lower jaw, brows
		{ "Marking", 122, 66, 44 }, -- shell
		{ "Marking", 92, 50, 36 }, -- shell rim
		{ "Marking", 118, 78, 62 }, -- shell top
		{ "Horn", 112, 96, 90 }, -- volcano
		{ "Horn", 92, 78, 74 }, -- volcano top
		{ "Hoof", 236, 214, 170 }, -- nails
	},
	KingCrab = {
		{ "Body", 226, 58, 48 }, -- shell, claws, eye stalks
		{ "Body", 160, 32, 40 }, -- face, pincer undersides
		{ "Body", 244, 104, 66 }, -- lower legs
		{ "Body", 232, 70, 52 }, -- upper legs
		{ "Belly", 252, 196, 150 },
		{ "Belly", 250, 226, 190 }, -- mandibles
	},
	BlueCrab = {
		{ "Body", 0, 144, 255 }, -- shell, claws, eye stalks
		{ "Body", 0, 86, 255 }, -- face, upper legs, pincer undersides
		{ "Body", 0, 183, 255 }, -- lower legs
		{ "Belly", 252, 196, 150 },
		{ "Belly", 250, 226, 190 }, -- mandibles
	},
	RoboShark = {
		{ "Body", 81, 65, 72 }, -- metal body and its panels
		{ "Body", 95, 81, 86 },
		{ "Body", 84, 67, 74 },
		{ "Body", 84, 67, 73 },
		{ "Body", 82, 64, 70 },
		{ "Body", 79, 63, 71 },
		{ "Body", 97, 78, 82 },
		{ "Body", 72, 52, 60 },
		{ "Body", 90, 61, 65 },
		{ "Body", 114, 85, 81 },
		{ "Body", 97, 84, 91 },
		{ "Marking", 187, 164, 88 }, -- gold trim
		{ "Marking", 184, 152, 81 },
		{ "Marking", 186, 168, 91 },
		{ "Marking", 182, 136, 71 },
	},
	FishSchool = {
		{ "Body", 255, 214, 40 },
		{ "Marking", 255, 186, 20 }, -- backs
		{ "Marking", 255, 150, 20 }, -- tails
	},
	Loong = {
		{ "Body", 121, 146, 53 },
		{ "Belly", 233, 197, 115 },
		{ "Belly", 210, 170, 119 }, -- jaw
		{ "Marking", 130, 38, 41 }, -- back fins, head spikes, whiskers
		{ "Accent", 255, 216, 21 }, -- gold rings
		{ "Accent", 227, 142, 22 },
		{ "Horn", 201, 189, 162 }, -- antlers, claws
	},
	WarElephant = {
		{ "Body", 156, 152, 166 },
		{ "Body", 122, 118, 134 }, -- ear lobes
		{ "Marking", 60, 56, 64 }, -- tail tip
		{ "Horn", 246, 238, 214 }, -- tusk
		{ "Hoof", 226, 218, 198 },
	},
	SoulHorse = {
		{ "Body", 34, 60, 52 },
		{ "Marking", 24, 40, 36 }, -- mane, forelock, tail
		{ "Accent", 112, 96, 156 }, -- ghostly tatters
		{ "Horn", 132, 144, 162 }, -- head plate, cheeks, crest and mane spikes
		{ "Hoof", 196, 186, 120 },
	},
	Sludge = {
		{ "Body", 126, 112, 38 },
		{ "Body", 150, 134, 52 }, -- lighter tier
		{ "Marking", 112, 58, 26 }, -- arms, nub, brow
		{ "Marking", 78, 38, 20 }, -- twigs
	},
	Leviathan = {
		{ "Body", 140, 226, 214 },
		{ "Belly", 246, 250, 250 }, -- belly, jaw
		{ "Marking", 198, 246, 238 }, -- back ridges
		{ "Accent", 186, 52, 40 }, -- stalks
		{ "Accent", 130, 30, 30 }, -- stalk tips and nubs
		parts = { EyeL = "Fixed", EyeR = "Fixed" }, -- (belly coloured)
	},
	Seraph = { -- (its white feathers, eyes and halo stay as they are)
		{ "Body", 255, 194, 38 }, -- gold rings and core
		{ "Body", 222, 146, 24 }, -- darker gold
		{ "Marking", 255, 244, 214 }, -- cream feathers
		{ "Accent", 255, 214, 120 }, -- wing tips
	},
	CrimsonSeraph = {
		{ "Body", 84, 22, 30 }, -- blood-red rings and core
		{ "Body", 56, 14, 20 }, -- darker
		{ "Marking", 168, 30, 46 }, -- crimson feathers
		{ "Marking", 136, 22, 38 }, -- darker feathers
		{ "Accent", 255, 92, 116 }, -- wing tips
	},
	CrystalSeraph = {
		{ "Body", 0, 190, 231 }, -- cyan crystal rings and core
		{ "Body", 0, 146, 186 }, -- darker cyan
		{ "Marking", 229, 131, 251 }, -- pink feathers
		{ "Marking", 242, 170, 253 }, -- lighter feathers
		{ "Accent", 92, 225, 255 }, -- glowing wing tips (and halo)
	},
	-- World 3's Garden (tools/garden_*.py)
	Ladybug = {
		{ "Body", 214, 26, 38 }, -- red
		{ "Body", 150, 14, 28 }, -- reddark
		{ "Belly", 250, 246, 236 }, -- white
		{ "Marking", 30, 26, 32 }, -- black
		{ "Accent", 255, 196, 92 }, -- wing
		{ "Accent", 176, 98, 30 }, -- wingvein
	},
	Bumblebee = {
		{ "Body", 255, 196, 20 }, -- yellow
		{ "Body", 224, 146, 10 }, -- yellowdark
		{ "Belly", 255, 226, 120 }, -- fuzz
		{ "Marking", 34, 28, 30 }, -- black
		{ "Accent", 176, 226, 255 }, -- wing
		{ "Accent", 90, 160, 214 }, -- wingrim
		{ "Accent", 250, 120, 150 }, -- pink
		{ "Hoof", 255, 140, 30 }, -- pollen
	},
	ToadstoolFrog = {
		{ "Body", 150, 222, 40 }, -- green
		{ "Belly", 246, 236, 140 }, -- belly
		{ "Belly", 240, 218, 176 }, -- gill
		{ "Marking", 156, 72, 214 }, -- cap
		{ "Marking", 98, 40, 150 }, -- capdark
		{ "Accent", 60, 150, 40 }, -- greendark
		{ "Horn", 252, 248, 236 }, -- spot
		{ "Hoof", 250, 160, 70 }, -- toe
	},
	VineMonster = {
		{ "Body", 64, 192, 64 }, -- vine
		{ "Body", 96, 210, 70 }, -- vinemid
		{ "Body", 30, 116, 46 }, -- vinedark
		{ "Marking", 150, 226, 70 }, -- vinelight
		{ "Marking", 124, 214, 60 }, -- leaf
		{ "Accent", 250, 84, 140 }, -- rose
		{ "Accent", 198, 30, 92 }, -- rosedark
		{ "Horn", 150, 64, 40 }, -- thorn
		{ "Horn", 246, 236, 200 }, -- tooth
		{ "Hoof", 110, 70, 44 }, -- bark
	},
	VenusFlytrap = {
		{ "Body", 78, 186, 50 }, -- green
		{ "Body", 34, 120, 40 }, -- greendark
		{ "Belly", 214, 30, 52 }, -- red
		{ "Belly", 140, 14, 40 }, -- reddark
		{ "Marking", 110, 210, 60 }, -- leaf
		{ "Horn", 252, 240, 200 }, -- spike
		{ "Hoof", 118, 76, 46 }, -- root
		{ "Hoof", 78, 50, 34 }, -- rootdark
	},
	SunflowerLion = {
		{ "Body", 228, 146, 58 }, -- fur
		{ "Body", 176, 96, 34 }, -- furdark
		{ "Belly", 252, 232, 176 }, -- cream
		{ "Marking", 255, 214, 30 }, -- petal
		{ "Marking", 246, 156, 20 }, -- petaldark
		{ "Accent", 96, 56, 30 }, -- seed
		{ "Accent", 56, 32, 22 }, -- seeddark
		{ "Hoof", 70, 176, 52 }, -- leaf
		{ "Hoof", 36, 120, 40 }, -- leafdark
	},
	RafflesiaBeast = {
		{ "Body", 70, 140, 60 }, -- moss
		{ "Body", 40, 92, 44 }, -- mossdark
		{ "Body", 120, 186, 70 }, -- mosslight
		{ "Belly", 246, 226, 200 }, -- rim
		{ "Marking", 220, 62, 40 }, -- petal
		{ "Marking", 150, 30, 30 }, -- petaldark
		{ "Marking", 196, 44, 60 }, -- bud
		{ "Accent", 250, 222, 196 }, -- wart
		{ "Accent", 90, 18, 34 }, -- well
		{ "Accent", 60, 150, 50 }, -- vine
		{ "Horn", 250, 236, 210 }, -- spine
		{ "Horn", 252, 244, 220 }, -- tooth
		{ "Hoof", 110, 72, 46 }, -- root
		{ "Hoof", 70, 46, 32 }, -- rootdark
	},
	AncientTreant = {
		{ "Body", 126, 84, 52 }, -- bark
		{ "Body", 84, 54, 36 }, -- barkdark
		{ "Body", 160, 112, 70 }, -- barklight
		{ "Belly", 96, 170, 60 }, -- moss
		{ "Belly", 56, 120, 44 }, -- mossdark
		{ "Marking", 60, 160, 60 }, -- leaf
		{ "Marking", 34, 112, 46 }, -- leafdark
		{ "Marking", 120, 200, 70 }, -- leaflight
		{ "Accent", 255, 140, 190 }, -- blossom
		{ "Accent", 220, 80, 150 }, -- blossomdark
		{ "Horn", 240, 132, 40 }, -- shroom
		{ "Horn", 190, 90, 30 }, -- shroomdark
	},
	GiantRafflesia = { -- World 3 Garden's boss (Oct 15, replaces the Flytrap Queen)
		{ "Body", 60, 150, 50 }, -- vine: stem, leaves
		{ "Body", 120, 186, 70 }, -- mosslight: stem leaves
		{ "Belly", 246, 226, 200 }, -- rim
		{ "Marking", 220, 62, 40 }, -- petal
		{ "Marking", 150, 30, 30 }, -- petaldark
		{ "Accent", 250, 222, 196 }, -- wart
		{ "Accent", 90, 18, 34 }, -- well
		{ "Horn", 250, 236, 210 }, -- spine
	},
	GummyBear = { -- World 3 Candyland
		{ "Body", 236, 36, 72 }, -- body, head, legs, ears
		{ "Belly", 255, 92, 150 }, -- belly, chest, muzzle
		{ "Hoof", 168, 18, 50 }, -- paws
	},
	GumdropFrog = { -- World 3 Candyland
		{ "Body", 255, 140, 30 }, -- gumdrop body, head, thighs
		{ "Body", 222, 96, 18 }, -- base band, feet (darker)
		{ "Belly", 255, 200, 120 }, -- belly, jaw
		{ "Marking", 255, 252, 246 }, -- sugar crystals
	},
	GingerbreadMan = { -- World 3 Candyland
		{ "Body", 204, 112, 44 }, -- cookie
		{ "Body", 150, 72, 26 }, -- baked edges (darker)
		{ "Marking", 255, 255, 255 }, -- piped icing
	},
	Creampuff = { -- World 3 Candyland
		{ "Body", 238, 172, 84 }, -- pastry bun and lid
		{ "Body", 200, 124, 50 }, -- bun base, feet (darker)
		{ "Marking", 255, 252, 246 }, -- whipped cream
		{ "Accent", 236, 36, 72 }, -- cherry (QM Oct 15: no longer spoiled; was green mould)
	},
	SwollFairy = { -- World 3 Candyland
		{ "Body", 255, 150, 206 }, -- skin
		{ "Body", 232, 98, 170 }, -- knuckles, nose (darker)
		{ "Marking", 60, 230, 176 }, -- tank top, slippers
		{ "Marking", 24, 176, 136 }, -- darker top
		{ "Accent", 204, 150, 255 }, -- tutu, lower wings
		{ "Horn", 70, 196, 255 }, -- upper wings
	},
	DesireTroll = { -- World 3 Candyland
		{ "Body", 255, 92, 150 }, -- skin
		{ "Body", 214, 52, 118 }, -- darker skin
		{ "Belly", 255, 150, 206 }, -- belly, chest, jaw
		{ "Hoof", 160, 80, 240 }, -- fists, feet
		{ "Hoof", 110, 46, 196 }, -- knuckles
		{ "Marking", 204, 150, 255 }, -- cotton-candy hair
	},
	RockCandyDragon = { -- World 3 Candyland
		{ "Body", 236, 36, 72 }, -- head, neck, body, tail, legs
		{ "Body", 168, 18, 50 }, -- darker red
		{ "Belly", 255, 252, 246 }, -- belly and chest plates
	},
	GumballGolem = { -- World 3 Candyland
		{ "Body", 236, 36, 72 }, -- machine base, fists
		{ "Marking", 250, 254, 255 }, -- glass globe
	},
	Gigacorn = { -- World 3 Candyland's boss
		{ "Body", 255, 252, 246 }, -- white coat
		{ "Marking", 255, 150, 206 }, -- cotton-candy mane and tail, frosting
		{ "Marking", 232, 98, 170 }, -- darker pink
		{ "Accent", 70, 196, 255 }, -- sky frosting and puffs
		{ "Hoof", 200, 124, 50 }, -- waffle-cone hooves
	},
}
