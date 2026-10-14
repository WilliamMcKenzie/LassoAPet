-- The endless Jurassic (QM, Oct 11: the temporary endgame). Config.Endless: the course
-- is cut at Cut (World.server takes away everything past it, the far wall too), and the
-- stretch just before it, Length studs from Cut + Length to Cut, is laid again and
-- again past it, forever: copy k (1, 2, ...) from Cut - (k - 1) * Length to Cut - k * Length.
--
-- Only three copies are ever made, on this client, as you near the cut: the one the
-- camera's in and one either side. As the camera moves on, the copy left furthest
-- behind leapfrogs to the far side. Each copy has its own stampede stream (as the
-- Godlands' tracks did), its obstacles go in Ride's lists so they crash and smash as
-- usual (and come back whole when their copy moves), and Shared/Ground wraps the floor
-- heights. Ride drives it:
--
--   Endless.init({ obstacles, slices, streams, newStream })  -- Ride's lists, once
--   Endless.update(camZ)                                      -- every frame
--   Endless.streamAt(z) -> stream?                            -- the stream of the copy at z

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Endless = {}
local cfg = Config.Endless
if not cfg then
	function Endless.init() end
	function Endless.update() end
	function Endless.streamAt() end
	return Endless
end

local CUT, LENGTH = cfg.Cut, cfg.Length
local TOP = CUT + LENGTH -- the stretch that's copied: TOP down to CUT
local LAST = #Config.Biomes -- the endless biome (the last)
local BIOME = Config.Biomes[LAST]
local PER_FRAME = 150 -- things cloned a frame while a copy's being made
local FOLDERS = { "Ground", "Funnel", "Walls", "Decor", "Nests", "Obstacles" }
-- Start making the first copy once the camera's this far down the course (in the
-- endless biome), well before the cut can be seen.
local START_AT = (function()
	local edge = 0
	for b = 1, LAST - 1 do
		edge -= Config.Biomes[b].Length
	end
	return edge
end)()

local ride -- Ride's { obstacles, slices, streams, newStream }
local sources -- what's copied: { inst, folder, size?, cframe? } (size and cframe: a part cut to the stretch)
local copies = {} -- { model, k, obstacleModels, entries, ready }
local holder

function Endless.init(r)
	ride = r
end

-- The stretch's pieces: models by their pivot, parts by their z span (a straight part
-- crossing either end is cut to it; a turned one goes by its middle).
local function gather()
	sources = {}
	local world = workspace:WaitForChild("World")
	for _, name in FOLDERS do
		local folder = world:FindFirstChild(name)
		for _, inst in if folder then folder:GetChildren() else {} do
			if inst:IsA("Model") then
				local z = inst:GetPivot().Position.Z
				if z <= TOP and z > CUT then
					table.insert(sources, { inst = inst, folder = name })
				end
			elseif inst:IsA("BasePart") then
				local cf, size = inst.CFrame, inst.Size
				local half = (cf.RightVector * size.X / 2):Abs() + (cf.UpVector * size.Y / 2):Abs() + (cf.LookVector * size.Z / 2):Abs()
				local lo, hi = cf.Position.Z - half.Z, cf.Position.Z + half.Z
				local a, b = math.max(lo, CUT), math.min(hi, TOP)
				if b - a >= 0.5 then
					if a > lo + 1e-3 or b < hi - 1e-3 then
						-- Which of its own axes lies along z (straight parts only).
						local axis = if math.abs(cf.LookVector.Z) > 0.999 then "Z"
							elseif math.abs(cf.RightVector.Z) > 0.999 then "X"
							elseif math.abs(cf.UpVector.Z) > 0.999 then "Y"
							else nil
						if axis then
							local newSize = Vector3.new(
								if axis == "X" then b - a else size.X,
								if axis == "Y" then b - a else size.Y,
								if axis == "Z" then b - a else size.Z
							)
							local at = Vector3.new(cf.Position.X, cf.Position.Y, (a + b) / 2)
							table.insert(sources, { inst = inst, folder = name, size = newSize, cframe = CFrame.new(at) * cf.Rotation })
						elseif cf.Position.Z <= TOP and cf.Position.Z > CUT then
							table.insert(sources, { inst = inst, folder = name })
						end
					else
						table.insert(sources, { inst = inst, folder = name })
					end
				end
			end
		end
	end
end

-- An obstacle's entry, as Ride makes them (Ride.client: its footprint from its "Base"
-- part, or else its lowest part).
local function entryFor(model)
	local base = model:FindFirstChild("Base")
	if not base then
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and (not base or part.Position.Y < base.Position.Y) then
				base = part
			end
		end
	end
	if not base then
		return nil
	end
	local parts = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, { part = part, cframe = part.CFrame, transparency = part.Transparency })
		end
	end
	return {
		x = base.Position.X,
		z = base.Position.Z,
		hx = base.Size.X / 2,
		hz = base.Size.Z / 2,
		tier = model:GetAttribute("Tier") or Config.ObstacleTiers[model.Name] or 1,
		center = model:GetPivot().Position,
		parts = parts,
	}
end

local function addEntries(copy)
	local slices = ride.slices
	copy.entries = {}
	for _, model in copy.obstacleModels do
		local o = entryFor(model)
		if o then
			table.insert(copy.entries, o)
			table.insert(ride.obstacles, o)
			slices.add(slices.swerve, o, o.z - o.hz - slices.SWERVE_AFTER, o.z + o.hz + slices.SWERVE_BEFORE)
			slices.add(slices.block, o, o.z - o.hz - slices.BLOCK_PAD, o.z + o.hz + slices.BLOCK_PAD)
		end
	end
end

local function dropFrom(list, o, zMin, zMax)
	for slice = math.floor(zMin / ride.slices.SIZE), math.floor(zMax / ride.slices.SIZE) do
		local i = list[slice] and table.find(list[slice], o)
		if i then
			table.remove(list[slice], i)
		end
	end
end

-- Takes a copy's obstacles out of Ride's lists, whole again if they'd been smashed.
local function removeEntries(copy)
	local slices = ride.slices
	for _, o in copy.entries or {} do
		if o.smashed then
			o.smashed, o.remoteSmash = nil, nil
			for _, p in o.parts do
				p.part.CFrame, p.part.Transparency = p.cframe, p.transparency
			end
		end
		local i = table.find(ride.obstacles, o)
		if i then
			table.remove(ride.obstacles, i)
		end
		dropFrom(slices.swerve, o, o.z - o.hz - slices.SWERVE_AFTER, o.z + o.hz + slices.SWERVE_BEFORE)
		dropFrom(slices.block, o, o.z - o.hz - slices.BLOCK_PAD, o.z + o.hz + slices.BLOCK_PAD)
	end
	copy.entries = nil
end

-- Copy k's stampede: its own stream, popping in at its top and gone at its bottom.
local function streamIndex(k)
	return LAST + 1 + k % 900
end
local function setStream(k, on)
	local b = streamIndex(k)
	if on then
		local s = ride.newStream(CUT - (k - 1) * LENGTH - 2, CUT - k * LENGTH + 2, BIOME.Herd)
		s.every = BIOME.HerdSpawnEvery or Config.HerdSpawnEvery
		s.keep = BIOME.HerdKeep
		s.k = k
		ride.streams[b] = s
	elseif ride.streams[b] and ride.streams[b].k == k then
		ride.streams[b] = nil
	end
end

-- Makes a copy at k, a few things a frame.
local function make(k)
	local copy = { k = k, obstacleModels = {}, ready = false }
	table.insert(copies, copy)
	local model = Instance.new("Model")
	model.Name = "EndlessCopy"
	model.WorldPivot = CFrame.new()
	model.Parent = holder
	copy.model = model
	local shift = Vector3.new(0, 0, -copy.k * LENGTH)
	task.spawn(function()
		for i, s in sources do
			local c = s.inst:Clone()
			if s.size then
				c.Size, c.CFrame = s.size, s.cframe
			end
			if c:IsA("Model") then
				c:PivotTo(c:GetPivot() + shift)
			else
				c.CFrame += shift
			end
			c.Parent = model
			if s.folder == "Obstacles" and c:IsA("Model") then
				table.insert(copy.obstacleModels, c)
			end
			if i % PER_FRAME == 0 then
				RunService.Heartbeat:Wait()
			end
		end
		-- (it may have been sent elsewhere while it was being made)
		local placed = copy.k
		if placed ~= k then
			model:PivotTo(model:GetPivot() + Vector3.new(0, 0, -(placed - k) * LENGTH))
		end
		addEntries(copy)
		copy.ready = true
		setStream(placed, true)
	end)
	return copy
end

-- Sends a made copy to k.
local function move(copy, k)
	if copy.k == k then
		return
	end
	if copy.ready then
		removeEntries(copy)
		setStream(copy.k, false)
		copy.model:PivotTo(copy.model:GetPivot() + Vector3.new(0, 0, -(k - copy.k) * LENGTH))
		copy.k = k
		addEntries(copy)
		setStream(k, true)
	else
		copy.k = k -- (make() puts it there once it's done)
	end
end

function Endless.update(camZ)
	if not ride or camZ > START_AT then
		return
	end
	if not sources then
		gather()
		holder = Instance.new("Folder")
		holder.Name = "EndlessCourse"
		holder.Parent = workspace
	end
	-- The copy the camera's in (0: not past the cut yet), and the ones either side.
	local here = if camZ < CUT then math.floor((CUT - camZ) / LENGTH) + 1 else 0
	local want = {}
	for k = math.max(here - 1, 1), here + 1 do
		want[k] = true
	end
	local spare = {}
	for _, copy in copies do
		if want[copy.k] then
			want[copy.k] = nil
		else
			table.insert(spare, copy)
		end
	end
	for k in want do
		local copy = table.remove(spare)
		if copy then
			move(copy, k)
		elseif #copies < 3 then
			make(k)
		end
	end
end

function Endless.streamAt(z)
	if not ride or z >= CUT then
		return nil
	end
	local k = math.floor((CUT - z) / LENGTH) + 1
	local s = ride.streams[streamIndex(k)]
	return if s and s.k == k then s else nil
end

return Endless
