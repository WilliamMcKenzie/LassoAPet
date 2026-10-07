-- A gate breaking like glass (QM, Oct 7): the sheet is cut into Delaunay triangles
-- round where it was hit (rings of cracks about the impact, finer near it, plus a
-- scatter over the rest), each triangle drawn as two WedgeParts, and each piece
-- then flies as a rigid body of its own: flung out from the impact and on the way
-- you were going, tumbling, falling under gravity, bouncing and sliding on the
-- floor, and fading out. Our own little physics (anchored parts, moved each
-- frame), so it's cheap and every phone sees the same. Client-only; at most
-- MAX_PIECES triangles, all gone after LIFE seconds.
--
--   GlassShatter.burst(opts)
--     opts = { z, width, height, color, impact = Vector2 (x, y on the sheet),
--              push = studs/s along -z (the rider's speed), dir = -1 or 1 }

local RunService = game:GetService("RunService")

local GlassShatter = {}

local MAX_PIECES = 90 -- triangles (two parts each)
local LIFE = 2.6 -- seconds before the last piece is gone
local FADE = 0.9 -- the last seconds of it, fading out
local THICK = 0.3 -- studs
local RINGS = { 3, 7, 13 } -- crack rings round the impact (studs), each RING_POINTS round
local RING_POINTS = 7
local SCATTER = 10 -- random points over the rest of the sheet
local BOUNCE, SLIDE = 0.3, 0.7 -- off the floor: what's kept of the fall, and of the slide
local MAX_PUSH = 140 -- studs/s: the most a piece is flung along with you

-- Bowyer-Watson: the Delaunay triangles of points (Vector2s), as { a, b, c } of points.
local function circumcircle(a, b, c)
	local d = 2 * (a.X * (b.Y - c.Y) + b.X * (c.Y - a.Y) + c.X * (a.Y - b.Y))
	if math.abs(d) < 1e-9 then
		return Vector2.zero, math.huge
	end
	local a2, b2, c2 = a.X * a.X + a.Y * a.Y, b.X * b.X + b.Y * b.Y, c.X * c.X + c.Y * c.Y
	local centre = Vector2.new(
		(a2 * (b.Y - c.Y) + b2 * (c.Y - a.Y) + c2 * (a.Y - b.Y)) / d,
		(a2 * (c.X - b.X) + b2 * (a.X - c.X) + c2 * (b.X - a.X)) / d
	)
	return centre, (a - centre).Magnitude
end

local function delaunay(points)
	local big = 1e5
	local s1, s2, s3 = Vector2.new(-big, -big), Vector2.new(big, -big), Vector2.new(0, big)
	local tris = {}
	local function add(a, b, c)
		local centre, r = circumcircle(a, b, c)
		table.insert(tris, { a, b, c, centre = centre, r = r })
	end
	add(s1, s2, s3)
	for _, p in points do
		local edges = {}
		local keep = {}
		for _, t in tris do
			if (p - t.centre).Magnitude < t.r then
				for k = 1, 3 do
					local e1, e2 = t[k], t[k % 3 + 1]
					-- an edge shared by two bad triangles isn't on the hole's edge
					local found = false
					for n, e in edges do
						if (e[1] == e2 and e[2] == e1) or (e[1] == e1 and e[2] == e2) then
							table.remove(edges, n)
							found = true
							break
						end
					end
					if not found then
						table.insert(edges, { e1, e2 })
					end
				end
			else
				table.insert(keep, t)
			end
		end
		tris = keep
		for _, e in edges do
			add(e[1], e[2], p)
		end
	end
	local out = {}
	for _, t in tris do
		local outer = false
		for k = 1, 3 do
			if t[k] == s1 or t[k] == s2 or t[k] == s3 then
				outer = true
			end
		end
		if not outer then
			table.insert(out, t)
		end
	end
	return out
end

local function wedge(color, transparency)
	local w = Instance.new("WedgePart")
	w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch, w.CastShadow = true, false, false, false, false
	w.Material = Enum.Material.Neon
	w.Color = color
	w.Transparency = transparency
	w.TopSurface, w.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return w
end

-- A triangle a, b, c (Vector3s) as two wedges: their sizes and CFrames.
local function triangle(a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	return Vector3.new(THICK, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back),
		Vector3.new(THICK, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back)
end

function GlassShatter.burst(opts)
	local width, height, z = opts.width, opts.height, opts.z
	local impact = opts.impact or Vector2.new(0, height * 0.25)
	local push = math.min(opts.push or 40, MAX_PUSH)
	local dir = opts.dir or -1
	local rng = Random.new()
	local hw = width / 2
	local function inside(p)
		return Vector2.new(math.clamp(p.X, -hw, hw), math.clamp(p.Y, 0, height))
	end

	-- The points: the sheet's corners and a few along its edges, the impact, rings of
	-- cracks round it (jittered), and a scatter over the rest.
	local points = { Vector2.new(-hw, 0), Vector2.new(hw, 0), Vector2.new(-hw, height), Vector2.new(hw, height) }
	for k = 1, 5 do
		local t = k / 6
		table.insert(points, Vector2.new(-hw + width * (t + rng:NextNumber(-0.05, 0.05)), 0))
		table.insert(points, Vector2.new(-hw + width * (t + rng:NextNumber(-0.05, 0.05)), height))
	end
	for k = 1, 2 do
		local t = k / 3
		table.insert(points, Vector2.new(-hw, height * t))
		table.insert(points, Vector2.new(hw, height * t))
	end
	table.insert(points, inside(impact))
	local turn = rng:NextNumber(0, math.pi * 2)
	for _, r in RINGS do
		for k = 1, RING_POINTS do
			local a = turn + (k + rng:NextNumber(-0.3, 0.3)) / RING_POINTS * math.pi * 2
			local rr = r * rng:NextNumber(0.8, 1.25)
			table.insert(points, inside(impact + Vector2.new(math.cos(a), math.sin(a)) * rr))
		end
	end
	for _ = 1, SCATTER do
		table.insert(points, Vector2.new(rng:NextNumber(-hw, hw), rng:NextNumber(0, height)))
	end
	-- (no two the same: the triangulation chokes on them)
	local seen, unique = {}, {}
	for _, p in points do
		local key = math.floor(p.X * 10) .. "," .. math.floor(p.Y * 10)
		if not seen[key] then
			seen[key] = true
			table.insert(unique, p)
		end
	end

	local tris = delaunay(unique)
	local gravity = workspace.Gravity
	local pieces = {}
	local folder = Instance.new("Folder")
	folder.Name = "GlassShatter"
	for n, t in tris do
		if n > MAX_PIECES then
			break
		end
		local a, b, c = Vector3.new(t[1].X, t[1].Y, z), Vector3.new(t[2].X, t[2].Y, z), Vector3.new(t[3].X, t[3].Y, z)
		local centre = (a + b + c) / 3
		local area = math.abs((b - a):Cross(c - a).Magnitude) / 2
		if area > 0.05 then
			local body = CFrame.new(centre)
			local transparency = 0.15 + 0.5 * math.clamp(centre.Y / height, 0, 1) -- clearer higher up, like the sheet
			local color = if rng:NextNumber() < 0.3 then Color3.new(1, 1, 1) else opts.color
			local s1, c1, s2, c2 = triangle(a, b, c)
			local w1, w2 = wedge(color, transparency), wedge(color, transparency)
			w1.Size, w2.Size = s1, s2
			w1.CFrame, w2.CFrame = c1, c2
			w1.Parent, w2.Parent = folder, folder
			-- Flung away from the impact, harder the nearer it was, and on with you.
			local from = Vector2.new(centre.X, centre.Y) - impact
			local near = 1 / (1 + from.Magnitude / 8)
			local out = if from.Magnitude > 0.01 then from.Unit else Vector2.new(0, 1)
			local speed = rng:NextNumber(10, 22) + 30 * near
			pieces[#pieces + 1] = {
				parts = { { w1, body:Inverse() * c1 }, { w2, body:Inverse() * c2 } },
				cf = body,
				start = transparency,
				-- (lighter pieces, small ones, go further)
				velocity = Vector3.new(out.X * speed, out.Y * speed * 0.6 + rng:NextNumber(4, 16), dir * push * (0.35 + 0.6 * near) * rng:NextNumber(0.8, 1.15)),
				spin = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit * rng:NextNumber(2, 4 + 8 * near), -- rad/s
				radius = math.sqrt(area) * 0.35 + THICK, -- (rests about this high off the floor)
			}
		end
	end
	folder.Parent = workspace

	local t = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		t += dt
		local fade = math.clamp((t - (LIFE - FADE)) / FADE, 0, 1)
		for _, p in pieces do
			p.velocity -= Vector3.new(0, gravity * dt, 0)
			local pos = p.cf.Position + p.velocity * dt
			if pos.Y < p.radius then -- the floor: bounce, slide, lose spin
				pos = Vector3.new(pos.X, p.radius, pos.Z)
				if p.velocity.Y < 0 then
					p.velocity = Vector3.new(p.velocity.X * SLIDE, -p.velocity.Y * BOUNCE, p.velocity.Z * SLIDE)
					p.spin *= 0.6
				end
			end
			local turn = p.spin * dt
			p.cf = CFrame.new(pos) * CFrame.Angles(turn.X, turn.Y, turn.Z) * p.cf.Rotation
			for _, w in p.parts do
				w[1].CFrame = p.cf * w[2]
				w[1].Transparency = p.start + (1 - p.start) * fade
			end
		end
		if t >= LIFE then
			connection:Disconnect()
			folder:Destroy()
		end
	end)
	return LIFE
end

return GlassShatter
