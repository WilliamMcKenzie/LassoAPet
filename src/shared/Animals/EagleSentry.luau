-- Eagle Sentry: World 2 Ancient Tomb's falcon guardian (QM, Oct 13; Epic). A big brown falcon
-- in Egyptian gold armour: a usekh collar on its barred chest, a striped nemes with a cobra and a
-- glowing sun disc, gold-edged wings with glowing Horus eyes, and a gold spear in its talons. It
-- never lands, and sprint flies it up like the Phoenix (Config.SprintSpecials). You ride on the
-- lapis saddle on its back. designs/tomb/EagleSentry.bbmodel (tools/eagle_sentry.py), converted
-- (--zyx) into EagleSentryModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local EagleSentryModel = require(script.Parent.EagleSentryModel)

return Horse.variant("EagleSentry", EagleSentryModel, "Epic", {
	seat = Vector3.new(0, 9.4, 1),
	neck = { center = Vector3.new(0, 10.4, -3.2), radius = 2 },
})
