-- The course's walls, for the ride (QM, Nov 7: "you can just run right through walls"). Ride.client
-- asks RideWalls.hit before each step out: riding into a wall on the way out crashes you, unless
-- your mount is huge (Config.WallWalkOverTier: it walks right over). Read off workspace.World.Walls'
-- "Wall" parts (Server/Map: each painted wall's sides, under its cap), not Shared/MapData (too much
-- for a client to decode, as Shared/Ground says).

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local SLICE = 32 -- studs of course a bucket covers

local RideWalls = {}

local folder -- the World.Walls these were read from (read again when the map's rebuilt)
local slices -- [slice] = { { cf, hx, hz, top } }

local function load()
	folder = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Walls")
	slices = {}
	if not folder then
		return
	end
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Wall" then
			local cf, size = part.CFrame, part.Size
			-- (its footprint's z extent, turned or not)
			local reach = math.abs(cf.LookVector.Z) * size.Z / 2 + math.abs(cf.RightVector.Z) * size.X / 2
			local w = { cf = cf, hx = size.X / 2, hz = size.Z / 2, top = cf.Y + size.Y / 2 }
			for s = math.floor((cf.Z - reach) / SLICE), math.floor((cf.Z + reach) / SLICE) do
				slices[s] = slices[s] or {}
				table.insert(slices[s], w)
			end
		end
	end
	folder.DescendantAdded:Once(function()
		folder = nil -- (the map editor saved: read it again)
	end)
end

-- The top of the first wall a body (hx, hz studs either side, flat) at (x, z) overlaps, else nil.
function RideWalls.hit(x, z, hx, hz)
	if not folder or not folder.Parent or not folder.Parent.Parent then
		load()
	end
	for s = math.floor((z - hz) / SLICE), math.floor((z + hz) / SLICE) do
		for _, w in slices[s] or {} do
			local p = w.cf:PointToObjectSpace(Vector3.new(x, w.cf.Y, z))
			if math.abs(p.X) < w.hx + hx and math.abs(p.Z) < w.hz + hz then
				return w.top
			end
		end
	end
	return nil
end

-- Whether a mount of this tier walks over walls (titans: Ash Behemoth, Glacier Mammoth...).
function RideWalls.walksOver(tier)
	return tier >= (Config.WallWalkOverTier or math.huge)
end

return RideWalls
