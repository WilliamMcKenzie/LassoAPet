-- Jade Statue: World 2 Temple's Epic (QM, Oct 13: "very badass"). A temple guardian lion come to
-- life, carved in jade greens, a gold flame crown of spikes over the mane and a glowing gem: a roaring mouth with fangs, glowing eyes under an angry brow,
-- a curled mane, a gold collar and bell, gold anklets and claws.
-- designs/temple/JadeStatue.bbmodel (tools/temple_statues.py), converted into
-- JadeStatueModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local JadeStatueModel = require(script.Parent.JadeStatueModel)

return Horse.variant("JadeStatue", JadeStatueModel, "Epic", {
	seat = Vector3.new(0, 6.8, 0.3),
	neck = { center = Vector3.new(0, 6.8, -4.6), radius = 2.8 },
})
