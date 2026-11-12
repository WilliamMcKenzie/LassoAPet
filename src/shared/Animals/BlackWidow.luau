-- BlackWidow: World 2's Crimson Lands trophy Legendary, 1 in 500 of its stampede (QM, Oct 13).
-- A giant armoured black widow: glossy black, a huge round abdomen with a glowing red hourglass
-- on its back and belly, rows of steel spikes, steel flank armour carved with glowing red runes,
-- a spiked steel helm, eight glowing red eyes, ivory fangs, spiked knee guards. The Ivory
-- Spider's legs and animations (tools/black_widow.py -> designs/bosses/BlackWidow.bbmodel),
-- converted --zyx into BlackWidowModel.luau. You ride on its back, on the hourglass.

local Horse = require(script.Parent.Horse)
local BlackWidowModel = require(script.Parent.BlackWidowModel)

return Horse.variant("BlackWidow", BlackWidowModel, "Legendary", {
	seat = Vector3.new(0, 3.5, 3),
	seatBone = "abdomen",
	neck = { center = Vector3.new(0, 0.7, -2.1), radius = 1.6 },
})
