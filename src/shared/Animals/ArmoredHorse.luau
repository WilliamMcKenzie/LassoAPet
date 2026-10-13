-- Armored Horse: World 2's starter pet. The Horse with #907D72 stone plating on its
-- head and a Loong-style saddle. Same bones and animations as the Horse; its model
-- is QM's edit of designs/horses/ArmoredHorse.bbmodel (first made by
-- tools/armored_horse.py), converted into ArmoredHorseModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ArmoredHorseModel = require(script.Parent.ArmoredHorseModel)

-- rider hips on the saddle's cushion
return Horse.variant("ArmoredHorse", ArmoredHorseModel, "Common", { seat = Vector3.new(0, 7.4, 1.2) })
