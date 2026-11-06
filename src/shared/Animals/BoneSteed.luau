-- BoneSteed: The Horse as a skeleton: bone white, a crypt-dark mane and hooves, ribs
-- down its sides and the dungeon's green glowing in its eye sockets.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Divine there is Lasso's Rare, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local BoneSteedModel = require(script.Parent.BoneSteedModel)

return Horse.variant("BoneSteed", BoneSteedModel, "Rare")
