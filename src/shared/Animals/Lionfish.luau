-- Lionfish (QM, Oct 11): the original Fish striped cream and red-orange with a crest of
-- banded spines down its back, two over the eyes and a fan on each fin. Rare, Ocean.
-- designs/ocean/Lionfish.bbmodel is built by tools/lionfish.py from the Fish (same flop
-- animations), converted by tools/bbmodel_to_luau.py --zyx. Seat and neck as the Fish's.

local Horse = require(script.Parent.Horse)
local LionfishModel = require(script.Parent.LionfishModel)

return Horse.variant("Lionfish", LionfishModel, "Rare", {
	seat = Vector3.new(0, 6.48, -0.54),
	neck = { center = Vector3.new(0, 2.97, -3.51), radius = 2.565 },
})
