-- Majestic Unicorn: World 2 Meadow's Legendary. Pearl white with lilac socks and muzzle,
-- gold hooves, brows and twisted horn, and a long rainbow mane and tail on their own bones
-- that stream back and ripple in its animations. It trails a rainbow (the Unicorn's Leap
-- rainbow, as Ride's vfx.rainbowFx) whenever it moves, ridden or not (QM, Oct 13): the
-- trails are on its model from the start, and a Trail only draws while it moves.
-- Model: QM's edit of designs/world2/MajesticUnicorn.bbmodel (first made by
-- tools/majestic_unicorn.py), converted with --zyx into MajesticUnicornModel.luau.

local Horse = require(script.Parent.Horse)
local MajesticUnicornModel = require(script.Parent.MajesticUnicornModel)

local RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(170, 90, 240),
}
local LIFETIME = 1.4 -- seconds each band trails (the Leap's)

local MajesticUnicorn = Horse.variant("MajesticUnicorn", MajesticUnicornModel, "Legendary", {
	seat = Vector3.new(0, 7.3, 1.3),
	neck = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 },
})

local new = MajesticUnicorn.new
function MajesticUnicorn.new()
	local self = new()
	local root = self.model.PrimaryPart
	local middle, size = self.model:GetBoundingBox()
	local back = root.CFrame:ToObjectSpace(middle * CFrame.new(0, 0, size.Z * 0.3)) -- toward its tail (it faces -Z)
	local band = size.Y * 0.6 / #RAINBOW
	for k, color in RAINBOW do
		local y = size.Y * 0.3 - (k - 1) * band
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "Rainbow" .. k .. "Top", "Rainbow" .. k .. "Bottom"
		a0.CFrame = back * CFrame.new(0, y, 0)
		a1.CFrame = back * CFrame.new(0, y - band, 0)
		a0.Parent, a1.Parent = root, root
		local trail = Instance.new("Trail")
		trail.Name = "Rainbow" .. k
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = ColorSequence.new(color)
		trail.Lifetime = LIFETIME
		trail.MinLength = 0.2
		trail.LightEmission = 0.4
		trail.LightInfluence = 0
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 1) })
		trail.Parent = root
	end
	return self
end

return MajesticUnicorn
