-- Bone Rex: a skeletal T-Rex, the final Legendary (QM, Oct 11: "the most badass model in the
-- entire game"). Black obsidian bones, glowing green soul-fire eyes trailing flames, a glowing
-- mouth, a ribcage round a glowing soul gem, spiked vertebrae with glowing discs and green
-- spike tips and talons. Built on QM's T-Rex rig and runs on its animations
-- (tools/bone_rex.py obsidian -> designs/jurassic/BoneRex.bbmodel, converted by
-- tools/bbmodel_to_luau.py --zyx). Its sprint scares everything off and smashes every
-- obstacle in a huge radius (Config.SprintSpecials).

local Horse = require(script.Parent.Horse)
local BoneRexModel = require(script.Parent.BoneRexModel)

return Horse.variant("BoneRex", BoneRexModel, "Legendary", {
	seat = Vector3.new(0, 10.62, 0.6), -- on the spine, between the low blades over the back
	neck = { center = Vector3.new(0, 9.9, -5.2), radius = 2.2 },
})
