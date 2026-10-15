-- SkeletonDog: the Halloween world's Soul Valley Uncommon (QM, Oct 15): a white bone dog with a teal collar.
-- designs/halloween/SkeletonDog.bbmodel (tools/halloween_skeleton_dog.py), converted (--zyx --meshes) into
-- SkeletonDogModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SkeletonDogModel = require(script.Parent.SkeletonDogModel)

return Horse.variant("SkeletonDog", SkeletonDogModel, "Uncommon", {
	seat = Vector3.new(0, 5.9, 0.8),
	neck = { center = Vector3.new(0, 6.6, -3.4), radius = 2.0 },
})
