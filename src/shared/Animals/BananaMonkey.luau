-- Banana Monkey: World 3 Pirate Cove's Uncommon (Oct 14), the pirate's monkey. A chunky brown
-- monkey knuckle-walking on all fours: a tan grinning face, a red pirate bandana, a gold hoop
-- earring, and its tail curled up over its back holding a banana. You ride on its back.
-- designs/world3/pirate/BananaMonkey.bbmodel (tools/pirate_monkey.py), converted (--zyx) into BananaMonkeyModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local BananaMonkeyModel = require(script.Parent.BananaMonkeyModel)

return Horse.variant("BananaMonkey", BananaMonkeyModel, "Uncommon", {
	seat = Vector3.new(0, 7.9, -1.0),
	neck = { center = Vector3.new(0, 7.2, -4.6), radius = 2.0 },
})
