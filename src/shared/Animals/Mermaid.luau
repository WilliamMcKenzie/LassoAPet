-- Mermaid: World 3 Cnidaria's Legendary (Oct 14), built on the Tomb's Nut. She swims flat
-- out with you on a scallop-shell saddle between her shoulder blades: coral-pink hair in
-- streaming locks, a gold crown of pyramid points and pearls, googly eyes, seashells and pearls,
-- a gold trident held forward with glowing prongs, a glowing pearl in her other hand, big hip
-- fins and a chunky teal tail ending in a forked fluke. Sprint flies her up like Nut.
-- Model from designs/cnidaria/Mermaid.bbmodel (tools/mermaid.py), converted into
-- MermaidModel.luau by tools/bbmodel_to_luau.py (no --zyx, as Nut).

local Horse = require(script.Parent.Horse)
local MermaidModel = require(script.Parent.MermaidModel)

return Horse.variant("Mermaid", MermaidModel, "Legendary", {
	seat = Vector3.new(0, 8.94, -1.125),
	neck = { center = Vector3.new(0, 9.75, -5.0), radius = 1.875 },
})
