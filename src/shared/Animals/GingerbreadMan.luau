-- Gingerbread Man: World 3 Candyland Uncommon (Oct 14). A thick gingerbread cookie on two legs with
-- piped icing, gumdrop buttons and a bite out of his head; he sprints. You ride on the peppermint
-- cushion on his back.
-- designs/candyland/GingerbreadMan.bbmodel (tools/gingerbread_man.py), converted (no --zyx) into GingerbreadManModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GingerbreadManModel = require(script.Parent.GingerbreadManModel)

return Horse.variant("GingerbreadMan", GingerbreadManModel, "Uncommon", {
	seat = Vector3.new(0, 6.6, 1.0), -- (on its back: QM took the cushion off, Oct 15; was z 1.5)
	neck = { center = Vector3.new(0, 8.2, 0), radius = 2.2 },
})
