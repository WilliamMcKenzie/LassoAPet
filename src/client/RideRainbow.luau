-- Ride's rainbows (moved out of Ride.client for its size: Ride passes its vfx table in).
-- vfx.RAINBOW and vfx.rainbowFx(entity, lifetime, scale, colors): the Unicorn's Leap, the
-- Rainbow Trail and the finish line's trails (Config.trailColors).
return function(vfx)
	-- A rainbow streaming out behind a leaping animal while it's in the air: six
	-- trails stacked one above another, a band of colour each. lifetime: how long
	-- each band trails (the Leap's 1.4 s by default).
	vfx.RAINBOW = {
		Color3.fromRGB(255, 70, 70),
		Color3.fromRGB(255, 160, 50),
		Color3.fromRGB(255, 235, 70),
		Color3.fromRGB(80, 220, 90),
		Color3.fromRGB(70, 150, 255),
		Color3.fromRGB(170, 90, 240),
	}
	-- scale: x the bands' height (the bought Rainbow Trail's Config.RainbowTrail.Width);
	-- a taller rainbow is lifted so its bottom stays at the ground.
	function vfx.rainbowFx(entity, lifetime, scale, colors)
		colors = colors or vfx.RAINBOW
		local root = entity.animal.model.PrimaryPart
		local middle, size = entity.animal.model:GetBoundingBox()
		local back = root.CFrame:ToObjectSpace(middle * CFrame.new(0, 0, size.Z * 0.3)) -- toward its tail (it faces -Z)
		scale = scale or 1
		local band = size.Y * 0.6 * scale / #colors
		local lift = math.max(size.Y * 0.3 * scale - size.Y * 0.5, 0)
		local parts = {}
		for k, color in colors do
			local y = size.Y * 0.3 * scale + lift - (k - 1) * band
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame = back * CFrame.new(0, y, 0)
			a1.CFrame = back * CFrame.new(0, y - band, 0)
			a0.Parent, a1.Parent = root, root
			local trail = Instance.new("Trail")
			trail.Attachment0, trail.Attachment1 = a0, a1
			trail.Color = ColorSequence.new(color)
			trail.Lifetime = lifetime or 1.4
			trail.MinLength = 0.2
			trail.LightEmission = 0.4
			trail.LightInfluence = 0
			trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 1) })
			trail.Parent = root
			table.insert(parts, trail)
			table.insert(parts, a0)
			table.insert(parts, a1)
		end
		return parts
	end
end
