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
}
