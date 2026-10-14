-- Leviathan: a sea serpent built like the Snake (a chain of body segments) with an
-- axolotl head after QM's pixel art: red feathery gills, gold eyes and a vicious
-- underbite full of razor teeth. Epic, medium, Godlands (QM, Oct 4).
-- designs/leviathan/Leviathan.bbmodel is QM's edit of the one tools/leviathan_design.py
-- built, converted (--zyx) into LeviathanModel.luau by tools/bbmodel_to_luau.py.
-- You sit on its front segment, behind the head. Ability: Hunt, like the Robo Shark's
-- but for one animal, speeding up as it goes; sprint: a short flamethrower
-- (Config.Abilities / SprintSpecials.Leviathan).

local Horse = require(script.Parent.Horse)
local LeviathanModel = require(script.Parent.LeviathanModel)

return Horse.variant("Leviathan", LeviathanModel, "Epic", {
	seat = Vector3.new(0, 4.5, 1.6), -- on the front segment, just behind the head
	seatBone = "root", -- (not the head: it rears and sways)
	neck = { center = Vector3.new(0, 3.8, -2), radius = 3.6 }, -- round the head
})
