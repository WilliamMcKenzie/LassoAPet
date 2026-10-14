-- The Robo Shark's ability (Config.Abilities, Kind "Missiles"; QM, Oct 4): two
-- missiles fired straight ahead from its sides. They kick off, speed away down
-- their lanes with a fiery trail and burst at the end; the ride script smashes every
-- obstacle and animal in the stretch of lane each one covers per frame.
--
--   local m = Missiles.new(x, y, z, dir, spread, scale) -- launched beside a rider; dir = travel direction (-1 out, +1 home)
--   local lanes = m:update(dt, mountSpeed, t, duration) -- { { x = , from = , to = }, ... } swept this frame
--   m:destroy() -- bursts them
--   Missiles.show(x, y, z, dir, spread, scale, duration, speed) -- just the look (another player's), flies itself

local RunService = game:GetService("RunService")
local Poof = require(script.Parent.Poof)

local RUSH = 150 -- studs/s faster than the rider, at full thrust
local THRUST_TIME = 0.25 -- seconds to reach full thrust
local LAUNCH_DROP = 1.5 -- studs each dips as it leaves the rack, before the motor catches
-- One missile (studs, before `scale`): name, size, colour, offset from its middle (it faces -z)
local BLOCKS = {
	{ "Body", Vector3.new(1, 1, 4.4), Color3.fromRGB(196, 200, 210), CFrame.new(0, 0, 0) },
	{ "Nose", Vector3.new(0.8, 0.8, 0.9), Color3.fromRGB(230, 50, 50), CFrame.new(0, 0, -2.6) },
	{ "Band", Vector3.new(1.1, 1.1, 0.4), Color3.fromRGB(230, 50, 50), CFrame.new(0, 0, -1.2) },
	{ "FinUp", Vector3.new(0.25, 0.9, 1.1), Color3.fromRGB(230, 50, 50), CFrame.new(0, 0.9, 1.6) },
	{ "FinDown", Vector3.new(0.25, 0.9, 1.1), Color3.fromRGB(230, 50, 50), CFrame.new(0, -0.9, 1.6) },
	{ "FinL", Vector3.new(0.9, 0.25, 1.1), Color3.fromRGB(230, 50, 50), CFrame.new(-0.9, 0, 1.6) },
	{ "FinR", Vector3.new(0.9, 0.25, 1.1), Color3.fromRGB(230, 50, 50), CFrame.new(0.9, 0, 1.6) },
	{ "Flame", Vector3.new(0.7, 0.7, 0.5), Color3.fromRGB(255, 170, 40), CFrame.new(0, 0, 2.4), true },
}

local Missiles = {}
Missiles.__index = Missiles

local function trail(parent, scale)
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 140)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 110, 110)),
	})
	fire.LightEmission = 0.7
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * scale), NumberSequenceKeypoint.new(1, 3.5 * scale) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.3, 0.5)
	fire.Speed = NumberRange.new(2, 5)
	fire.SpreadAngle = Vector2.new(15, 15)
	fire.EmissionDirection = Enum.NormalId.Back
	fire.Rate = 90
	fire.Parent = parent
end

function Missiles.new(x, y, z, dir, spread, scale)
	local folder = Instance.new("Folder")
	folder.Name = "Missiles"
	local self = setmetatable({ folder = folder, dir = dir, scale = scale, y = y, list = {}, parts = {}, cframes = {} }, Missiles)
	for _, side in { -1, 1 } do
		local m = { x = x + side * spread, z = z, blocks = {} }
		for _, b in BLOCKS do
			local p = Instance.new("Part")
			p.Name = "Missile" .. b[1]
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
			p.CastShadow = false
			p.Material = if b[5] then Enum.Material.Neon else Enum.Material.SmoothPlastic
			p.Size, p.Color = b[2] * scale, b[3]
			p.Parent = folder
			table.insert(m.blocks, { part = p, offset = CFrame.new(b[4].Position * scale) })
			table.insert(self.parts, p)
			if b[1] == "Flame" then
				trail(p, scale)
			end
		end
		table.insert(self.list, m)
	end
	self:place(0)
	folder.Parent = workspace
	return self
end

-- Puts both missiles where they are, `t` seconds after launch.
function Missiles:place(t)
	local yaw = if self.dir < 0 then 0 else math.pi
	local drop = LAUNCH_DROP * self.scale * math.sin(math.min(t / THRUST_TIME, 1) * math.pi) -- a dip off the rack
	local n = 0
	for i, m in self.list do
		local wobble = math.sin(t * 30 + i * 2) * 0.04
		local at = CFrame.new(m.x, self.y - drop, m.z) * CFrame.Angles(0, yaw + wobble, 0)
		for _, b in m.blocks do
			n += 1
			self.cframes[n] = at * b.offset
		end
	end
	workspace:BulkMoveTo(self.parts, self.cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

-- Flies them on; returns each one's lane (x) and the z it was at and is at now.
function Missiles:update(dt, mountSpeed, t)
	local thrust = math.min(t / THRUST_TIME, 1)
	local lanes = {}
	for _, m in self.list do
		local from = m.z
		m.z += self.dir * (mountSpeed + RUSH * thrust * thrust) * dt
		table.insert(lanes, { x = m.x, from = from, to = m.z })
	end
	self:place(t)
	return lanes
end

function Missiles:destroy()
	for _, m in self.list do
		Poof.at(Vector3.new(m.x, self.y - 1, m.z))
	end
	self.folder:Destroy()
end

-- Another player's missiles: the same look, flying themselves for `duration` seconds.
function Missiles.show(x, y, z, dir, spread, scale, duration, speed)
	local self = Missiles.new(x, y, z, dir, spread, scale)
	local t = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t >= duration or not self.folder.Parent then
			conn:Disconnect()
			if self.folder.Parent then
				self:destroy()
			end
			return
		end
		self:update(dt, speed, t)
	end)
end

return Missiles
