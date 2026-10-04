-- Kraken: a squid with a tall tilted mantle, one big eye and eight tentacles splayed on
-- the sea floor. Legendary, Ocean, XL (tier 4). QM's model designs/ocean/Kraken.bbmodel, animated by
-- tools/kraken_rig.py and converted into KrakenModel.luau by tools/bbmodel_to_luau.py.
-- Its head faces back toward the rider (QM, Oct 3), so you can see the eye while riding;
-- the mantle leans forward like a squid swimming mantle-first. You sit on the rim of its
-- head, just over the eye (QM, Oct 4): the seat used to be the mantle's tip, which its
-- lean and bob swung all over. The rim is next to the head's pivot, so it barely moves.

local Horse = require(script.Parent.Horse)
local KrakenModel = require(script.Parent.KrakenModel)

return Horse.variant("Kraken", KrakenModel, "Legendary", {
	seat = Vector3.new(0, 11.6, 3.5), -- on the back of the cap's rim, over the eye (clear of the mantle)
	seatBone = "root", -- moves with the head as it glides, staying upright
	gallopOnSprint = true, -- QM: its gallop only while sprinting, else its walk
	neck = { center = Vector3.new(0, 5.8, 0), radius = 2.4 },
})
