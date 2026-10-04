-- Soul Horse: a dark ghost-green horse in steel barding with glowing blue eyes, spikes
-- on its crest and rump and ragged tatters under its belly. Epic, Godlands, medium
-- (QM, Oct 4). Built on QM's horse by tools/soul_horse.py (from QM's reference,
-- designs/godlands/SoulHorse_ref.bbmodel) into designs/godlands/SoulHorse.bbmodel,
-- converted into SoulHorseModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SoulHorseModel = require(script.Parent.SoulHorseModel)

return Horse.variant("SoulHorse", SoulHorseModel, "Epic", {
	seat = Vector3.new(0, 7.3, 1),
	neck = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 },
})
