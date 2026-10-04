-- The podium's grass snake (QM, Oct 4): QM's Snake recoloured as a grass snake, coiled
-- in its idle round a gold column with a cap that first place stands on.
-- designs/props/GrassSnake.bbmodel (QM's file) -> GrassSnakeModel via tools/bbmodel_to_luau.py.
-- Built and animated by PodiumSnake.client; Leaderboard.server stands the winner on the cap.

local GrassSnakeModel = require(script.Parent.GrassSnakeModel)

-- The middle of the cap's top in the model (studs at size 1, in its idle: QM moves the
-- Podium bone into the coil with a fixed key).
local function capTop()
	local key = GrassSnakeModel.animations.idle.tracks.Podium.position.keys[1]
	for _, part in GrassSnakeModel.parts do
		if part.name == "Cap" then
			local at = part.cframe.Position + Vector3.new(key[2], key[3], key[4])
			return at + Vector3.new(0, part.size.Y / 2, 0)
		end
	end
	error("GrassSnakeModel has no Cap")
end

return {
	data = GrassSnakeModel,
	capTop = capTop(),
}
