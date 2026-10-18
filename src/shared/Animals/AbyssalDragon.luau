-- Abyssal Sea Dragon: one of World 3 Cnidaria's two giga rares (Oct 14), about 1 in 1,000.
-- A long navy sea dragon in a gentle S-curve: turquoise belly plates, a glowing cyan and
-- violet dorsal crest, gold antlers and whiskers, googly eyes under angry brows, pyramid
-- fangs, four paddle legs and a big tail fan. You ride just behind its head.
-- Model from designs/cnidaria/AbyssalDragon.bbmodel (tools/sea_dragon.py), converted into AbyssalDragonModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

-- SCRAPPED (QM, Oct 15): in no herd, egg, quest or shop. Kept only so pets already saved still load
-- (Pen and Ride require every saved kind's module). Its design tool and .bbmodel are gone.

local Horse = require(script.Parent.Horse)
local AbyssalDragonModel = require(script.Parent.AbyssalDragonModel)

return Horse.variant("AbyssalDragon", AbyssalDragonModel, "Legendary", {
	seat = Vector3.new(0, 9.2, 3.0),
	neck = { center = Vector3.new(0, 7.3, -3.0), radius = 3.4 },
})
