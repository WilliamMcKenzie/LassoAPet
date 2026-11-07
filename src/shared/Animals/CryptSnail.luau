-- Crypt Snail: World 1 Dungeon's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_dungeon.py (crypt_snail), rigged by tools/filler_export.py into
-- designs/filler/rigged/CryptSnail.bbmodel and converted into CryptSnailModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local CryptSnailModel = require(script.Parent.CryptSnailModel)

return Horse.variant("CryptSnail", CryptSnailModel, "Uncommon", {
	seat = Vector3.new(0, 8.84, -0.62),
	neck = { center = Vector3.new(0, 5.6, -4.42), radius = 3.92 },
})
