-- Where the base's stands stand (QM, Nov 7): the three leaderboards, the Trails Shop, the three
-- limiteds and the free gift are "Stand" objects in the map editor (tools/mapeditor), each by its
-- `kind`, so QM moves them there. One the map hasn't got stands at its Config spot (these
-- defaults; the editor's STAND_DEFAULTS are the same spots).
--
--   Stands.at(kind) -> CFrame: its foot on the ground, turned its yaw (degrees, as Config's Yaw)
--
-- kinds: TopMoney, TopLuck, TopPlaytime (Config.Leaderboards.Boards' Store), TrailShop, FreeGift,
-- and each limited's Kind (Loong, MajesticUnicorn, RoboShark: Config.PetOffers)
local Config = require(script.Parent.Config)
local MapData = require(script.Parent.MapData)

local Stands = {}

local function yawed(pos, yaw)
	return CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local defaults = {}
do
	local lb = Config.Leaderboards
	if lb then
		local base = yawed(lb.Position, lb.Yaw)
		for i, board in lb.Boards do
			defaults[board.Store] = base * CFrame.new((2 - i) * lb.Spacing, 0, 0)
		end
	end
	local shop = Config.TrailShop
	if shop then
		defaults.TrailShop = yawed(shop.Position, shop.Yaw)
	end
	local gift = Config.FreeGift
	if gift then
		local y = require(script.Parent.MapFile).groundAt(MapData, gift.X, gift.Z)
		defaults.FreeGift = yawed(Vector3.new(gift.X, y, gift.Z), gift.Yaw)
	end
	local offers = Config.PetOffers
	if offers and #offers > 0 and Config.Podium then
		-- (the row turned about its first stand, the others along it 28 studs apart)
		local row = CFrame.new(Config.Podium.Position + (offers[1].Offset or Vector3.zero))
			* CFrame.Angles(0, -math.rad(Config.LimitedsTurn or 0), 0)
		for i, offer in offers do
			defaults[offer.Kind] = row * CFrame.new((i - 1) * 28, 0, 0)
		end
	end
end

function Stands.at(kind)
	local s = MapData.Stands and MapData.Stands[kind]
	if s then
		return yawed(Vector3.new(s[1], s[4], s[2]), s[3])
	end
	return defaults[kind]
end

return Stands
