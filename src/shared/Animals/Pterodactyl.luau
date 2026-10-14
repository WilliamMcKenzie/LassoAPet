-- Pterodactyl: a small purple flying dinosaur with dark stripes, a long gold beak, a swept
-- back red-orange crest and big orange leathery wings (QM, Oct 11). Epic, Jurassic. The
-- T-Rex's head on the Phoenix's flying body: it never lands (idle hovers, walk glides,
-- gallop flaps), and sprint flies it up over everything (Config.SprintSpecials).
-- designs/jurassic/Pterodactyl.bbmodel (tools/pterodactyl.py), converted by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local PterodactylModel = require(script.Parent.PterodactylModel)

return Horse.variant("Pterodactyl", PterodactylModel, "Epic", {
	seat = Vector3.new(0, 3.25, 0.4), -- on top of the back
	neck = { center = Vector3.new(0, 4.85, -3.9), radius = 1.3 },
})
