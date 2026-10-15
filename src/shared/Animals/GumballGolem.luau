-- Gumball Golem: World 3 Candyland giga rare, 1 in 1,000 of its stampede (Oct 14). A walking gumball
-- machine: a cherry machine base, a glass globe full of gumballs, jawbreaker fists. XL. You ride
-- on the cushion on its chrome lid. (QM, Oct 15: globe, gumballs, jawbreakers and lid are smooth
-- meshes, converted with --meshes assets/meshes/GumballGolem.)
-- designs/candyland/GumballGolem.bbmodel (tools/gumball_golem.py), converted (no --zyx) into GumballGolemModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GumballGolemModel = require(script.Parent.GumballGolemModel)

return Horse.variant("GumballGolem", GumballGolemModel, "Legendary", {
	seat = Vector3.new(0, 18.45, 0.3),
	seatBone = "neck",
	neck = { center = Vector3.new(0, 9.5, 0), radius = 3.3 },
})
