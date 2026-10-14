-- Jolly Roger Wyvern: World 3 Pirate Cove's second giga rare (Oct 14; about 1 in 1,000). A
-- skeleton sea dragon flying on wings of black pirate sail with a skull and crossbones on
-- each: thick bones, a ribcage round a glowing green heart, horns, plate eyes, and a gold
-- anchor for a tail tip. You ride on the red saddle between its shoulders.
-- designs/world3/pirate/JollyRogerWyvern.bbmodel (tools/pirate_wyvern.py), converted (--zyx) into JollyRogerWyvernModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local JollyRogerWyvernModel = require(script.Parent.JollyRogerWyvernModel)

return Horse.variant("JollyRogerWyvern", JollyRogerWyvernModel, "Legendary", {
	seat = Vector3.new(0, 6.28, -1.4),
	neck = { center = Vector3.new(0, 10.28, -10.3), radius = 1.8 },
})
