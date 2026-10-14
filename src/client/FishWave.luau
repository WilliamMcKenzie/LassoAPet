-- The School of Fish's ability (Config.Abilities, Kind "Wave"; QM, Oct 3): a wall
-- of yellow tangs rushes up from behind the rider across the whole width of the
-- course, overtakes it and races on ahead, smashing everything in its path (the
-- ride script does the smashing, over the stretch the wave's front passes each
-- frame), then the fish dive up and away and are gone.
--
--   local wave = FishWave.new(z, dir, edge) -- starts behind a rider at z; dir = travel direction (-1 out, +1 home)
--   local from, to = wave:update(dt, mountSpeed, t, duration) -- the z the front swept this frame
--   wave:destroy()

local Ground = require(game:GetService("ReplicatedStorage").Shared.Ground)

local BEHIND = 40 -- studs behind the rider the wave starts
local RUSH = 70 -- studs/s faster than the rider
local SPACING = 7 -- studs between fish across a row
local ROWS = 2
local OUT_TIME = 0.6 -- seconds at the end the fish spend diving up and away
-- One fish (studs): body length, width, height. A little bigger than the school's own
-- fish so the wave reads from the riding camera.
local L, W, H = 5, 2, 3
local COLORS = {
	body = Color3.fromRGB(255, 214, 40),
	back = Color3.fromRGB(255, 186, 20),
	fin = Color3.fromRGB(255, 150, 20),
	white = Color3.fromRGB(255, 255, 255),
	black = Color3.fromRGB(20, 20, 24),
}
-- Each fish's blocks: name, size, offset from the fish's middle (it faces -z).
-- The eyes are one white block through the head (an eye each side) and a pupil
-- block through that, to keep the parts down.
local BLOCKS = {
	{ "body", Vector3.new(W, H * 0.8, L), CFrame.new(0, -0.1, 0) },
	{ "back", Vector3.new(W * 0.8, H * 0.25, L * 0.8), CFrame.new(0, H * 0.45, 0.2) },
	{ "white", Vector3.new(W + 0.1, 1.1, 1.1), CFrame.new(0, 0.2, -L / 2 + 1) },
	{ "black", Vector3.new(W + 0.16, 0.6, 0.5), CFrame.new(0, 0.1, -L / 2 + 0.85) },
}
local TAIL = { Vector3.new(0.5, H, 1.6), 0.7 } -- size, and how far behind the body the tail's middle sits

local FishWave = {}
FishWave.__index = FishWave

local function block(size, color)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Size, p.Color = size, color
	return p
end

function FishWave.new(z, dir, edge)
	local rng = Random.new()
	local folder = Instance.new("Folder")
	folder.Name = "FishWave"
	local fish, parts = {}, {}
	local across = math.floor(edge * 2 / SPACING)
	for row = 1, ROWS do
		for i = 0, across do
			local f = {
				x = -edge + i * SPACING + (if row % 2 == 0 then SPACING / 2 else 0) + rng:NextNumber(-1, 1),
				back = (row - 1) * 7 + rng:NextNumber(0, 4), -- studs behind the front
				y = rng:NextNumber(2, 6),
				phase = rng:NextNumber(0, math.pi * 2),
				blocks = {},
			}
			if f.x <= edge then
				for _, b in BLOCKS do
					local p = block(b[2], COLORS[b[1]])
					p.Parent = folder
					table.insert(f.blocks, { part = p, offset = b[3] })
					table.insert(parts, p)
				end
				f.tail = block(TAIL[1], COLORS.fin)
				f.tail.Parent = folder
				table.insert(parts, f.tail)
				table.insert(fish, f)
			end
		end
	end
	local self = setmetatable({
		folder = folder,
		fish = fish,
		parts = parts,
		cframes = table.create(#parts),
		dir = dir,
		front = z - dir * BEHIND,
		t = 0,
	}, FishWave)
	self:place(0, 0)
	folder.Parent = workspace
	return self
end

-- Puts every fish where it is now: tails wag, bodies wiggle; `rise` lifts them for the dive out.
function FishWave:place(t, rise)
	local yaw = if self.dir < 0 then 0 else math.pi -- the fish face the way the wave goes
	local floor = Ground.heightAt(0, self.front)
	local n = 0
	for _, f in self.fish do
		local z = self.front - self.dir * f.back
		local wiggle = math.sin(t * 22 + f.phase)
		local at = CFrame.new(f.x, floor + f.y + rise, z)
			* CFrame.Angles(0, yaw + wiggle * 0.12, 0)
			* CFrame.Angles(math.min(rise / 30, 0.9), 0, 0) -- nose up as it dives out
		for _, b in f.blocks do
			n += 1
			self.cframes[n] = at * b.offset
		end
		n += 1
		self.cframes[n] = at * CFrame.new(0, 0, L / 2) * CFrame.Angles(0, -wiggle * 0.6, 0) * CFrame.new(0, 0, TAIL[2])
	end
	workspace:BulkMoveTo(self.parts, self.cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

-- Moves the wave on; returns the z the front was at and is at now (it sweeps between them).
-- In its last OUT_TIME seconds the fish dive up and away and sweep nothing.
function FishWave:update(dt, mountSpeed, t, duration)
	local from = self.front
	self.front += self.dir * (mountSpeed + RUSH) * dt
	local out = math.max(t - (duration - OUT_TIME), 0) / OUT_TIME
	self:place(t, out * out * 40)
	if out > 0 then
		return from, from
	end
	return from, self.front
end

function FishWave:destroy()
	self.folder:Destroy()
end

return FishWave
