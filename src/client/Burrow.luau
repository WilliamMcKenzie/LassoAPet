-- The Sandworm's burrow (its special sprint, Config.SprintSpecials): dirt sprays up
-- over where it is and a sand mound pushes up every few studs, the ones behind
-- slowly sinking back into the floor (QM's pick). Your own worm's comes and goes
-- with Sprint (Ride.client); another rider's shows whenever their worm is under
-- the floor, so it doesn't look like an egg floating along on its own.
--
--   Burrow.start(z)              -> a burrow for a worm at depth z of the course
--   Burrow.follow(b, x, z)       -- every frame: the spray moves over it, mounds go up
--   Burrow.stop(b)               -- the spray goes (the mounds sink away on their own)
--   Burrow.rider(rider, entity)  -- every frame for another rider's mount (or nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

local Burrow = {}

Burrow.MOUND_EVERY = 4.5 -- studs between the Sandworm's mounds (QM: a bit more spread out than 3)
Burrow.MOUND_LIFE = 1.8 -- seconds a mound takes to sink away
Burrow.UNDER = -2 -- another rider's worm this far below its feet is burrowing (as Ride's "under everything")
-- Three mound shapes, one picked at random each time (QM): blocks of sand as
-- { x, z, height, width } from the worm.
Burrow.MOUNDS = {
	{ { 0, 0, 2.2, 6 }, { -2.2, 0.8, 1.4, 4 }, { 2.2, -0.8, 1.4, 4 } },
	{ { 0, 0.5, 2.6, 5 }, { -1.6, -1.6, 1.6, 4.5 }, { 2.4, 0.6, 1, 3.5 }, { -2.6, 1.4, 0.8, 3 } },
	{ { 0.4, 0, 1.8, 7 }, { -1.8, -1.2, 1.2, 3.5 }, { 1.4, 1.8, 1.5, 3 } },
}

local rng = Random.new()

local function groundColors(z)
	return Config.Biomes[WorldColors.biomeAt(z)].GroundColors
end

function Burrow.mound(x, z, floor)
	local ground = groundColors(z)
	local size = rng:NextNumber(0.8, 1.2) -- a little bigger or smaller each time
	for k, shape in Burrow.MOUNDS[rng:NextInteger(1, #Burrow.MOUNDS)] do
		local s = { shape[1] * size, shape[2] * size, shape[3] * size, shape[4] * size }
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Color = ground[(k % 2) + 1]
		p.Material = Enum.Material.SmoothPlastic
		p.Size = Vector3.new(s[4], s[3], s[4] * 0.8)
		p.CFrame = CFrame.new(x + s[1], floor + s[3] / 2, z + s[2]) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		p.Parent = workspace
		local sunk = Vector3.new(p.Size.X * 0.6, 0.05, p.Size.Z * 0.6)
		TweenService:Create(p, TweenInfo.new(Burrow.MOUND_LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = sunk,
			CFrame = p.CFrame - Vector3.new(0, s[3] / 2, 0),
		}):Play()
		task.delay(Burrow.MOUND_LIFE, function()
			p:Destroy()
		end)
	end
end

function Burrow.start(z)
	local spray = Instance.new("Part")
	spray.Anchored, spray.CanCollide, spray.CanQuery, spray.CanTouch = true, false, false, false
	spray.Transparency = 1
	spray.Size = Vector3.new(4, 1, 4)
	spray.Parent = workspace
	local dirt = Instance.new("ParticleEmitter")
	dirt.Texture = "rbxasset://textures/particles/smoke_main.dds"
	local ground = groundColors(z)
	dirt.Color = ColorSequence.new(ground[1], ground[2])
	dirt.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
	dirt.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	dirt.Lifetime = NumberRange.new(0.6, 1)
	dirt.Speed = NumberRange.new(2, 5)
	dirt.SpreadAngle = Vector2.new(80, 80)
	dirt.Rate = 25
	dirt.Parent = spray
	return { spray = spray, at = nil } -- (at: where the last mound went up)
end

function Burrow.follow(b, x, z)
	local floor = Ground.heightAt(x, z)
	b.spray.CFrame = CFrame.new(x, floor + 0.5, z)
	local here = Vector2.new(x, z)
	if not b.at or (here - b.at).Magnitude > Burrow.MOUND_EVERY then
		b.at = here
		Burrow.mound(x, z, floor)
	end
end

function Burrow.stop(b)
	if b then
		b.spray:Destroy()
	end
end

-- Another rider's mount, placed where their updates say: a Sandworm (or a hybrid
-- built on one, as their own sprint goes by the base kind) sunk under the floor
-- is burrowing, so it gets the spray and mounds over it, as on their screen.
function Burrow.rider(rider, entity)
	local root = entity and entity.animal.model.PrimaryPart
	local special = root and Config.SprintSpecials[(Fusion.split(rider.kind or ""))]
	local under = false
	if special and special.Kind == "Burrow" then
		under = root.Position.Y - Ground.heightAt(entity.x, entity.z) - entity.rootY < Burrow.UNDER
	end
	if under and not rider.burrow then
		rider.burrow = Burrow.start(entity.z)
	elseif not under and rider.burrow then
		Burrow.stop(rider.burrow)
		rider.burrow = nil
	end
	if rider.burrow then
		Burrow.follow(rider.burrow, entity.x, entity.z)
	end
end

return Burrow
