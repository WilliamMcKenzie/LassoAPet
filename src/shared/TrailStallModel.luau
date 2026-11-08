-- The Trails Shop's stall (QM, Nov 7): Fight to Steal an Egg's Weapon Shop stall (its
-- src/shared/VendorStallModel.luau, itself Lasso's old Carl stall) with Carl the cactus guy (QM, Nov 7) but without
-- his stock, its roof striped green and white like QM's reference. Studs, ground at Y = 0, the
-- counter facing -Z (Server/TrailShop turns, scales and places it: Config.TrailShop).

return {
	parts = {
		{ name = "Post", size = Vector3.new(0.6, 10.8, 1.2), cframe = CFrame.new(8.1, 5.4, 4.2, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(112, 74, 46) },
		{ name = "Post", size = Vector3.new(0.6, 10.8, 1.2), cframe = CFrame.new(8.1, 5.4, -4.2, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(112, 74, 46) },
		{ name = "Post", size = Vector3.new(0.6, 10.8, 1.2), cframe = CFrame.new(-8.1, 5.4, 4.2, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(112, 74, 46) },
		{ name = "Post", size = Vector3.new(0.6, 10.8, 1.2), cframe = CFrame.new(-8.1, 5.4, -4.2, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(112, 74, 46) },
		{ name = "Beam", size = Vector3.new(1.8, 2.4, 12.6), cframe = CFrame.new(8.65, 10.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(150, 100, 62) },
		{ name = "Beam", size = Vector3.new(1.8, 2.4, 12.6), cframe = CFrame.new(-8.65, 10.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(150, 100, 62) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(-3.8575, 13.8779, 4.08, 0.9239, -0.3827, 0, 0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(3.8575, 13.8779, 4.08, 0.9239, 0.3827, 0, -0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(-3.8575, 13.8779, 2.04, 0.9239, -0.3827, 0, 0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(3.8575, 13.8779, 2.04, 0.9239, 0.3827, 0, -0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(-3.8575, 13.8779, 0, 0.9239, -0.3827, 0, 0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(3.8575, 13.8779, 0, 0.9239, 0.3827, 0, -0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(-3.8575, 13.8779, -2.04, 0.9239, -0.3827, 0, 0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(3.8575, 13.8779, -2.04, 0.9239, 0.3827, 0, -0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(-3.8575, 13.8779, -4.08, 0.9239, -0.3827, 0, 0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Cloth", size = Vector3.new(9, 0.6, 2.04), cframe = CFrame.new(3.8575, 13.8779, -4.08, 0.9239, 0.3827, 0, -0.3827, 0.9239, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Ridge", size = Vector3.new(1.8, 1.2, 11.4), cframe = CFrame.new(0, 15.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(150, 100, 62) },
		{ name = "Counter", size = Vector3.new(14.4, 3.3, 2.4), cframe = CFrame.new(0, 1.65, -2.1, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(186, 132, 82) },
		{ name = "CounterTop", size = Vector3.new(15.6, 0.9, 3.3), cframe = CFrame.new(0, 3.75, -2.25, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(150, 100, 62) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2), cframe = CFrame.new(-9, 11.5, -4.1, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2), cframe = CFrame.new(-9, 11.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2), cframe = CFrame.new(-9, 11.5, 4.1, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2.1), cframe = CFrame.new(-9, 11.5, 2.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2.1), cframe = CFrame.new(-9, 11.5, -2.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2.1), cframe = CFrame.new(9, 11.5, 2.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2), cframe = CFrame.new(9, 11.5, 4.1, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2), cframe = CFrame.new(9, 11.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2.1), cframe = CFrame.new(9, 11.5, -2.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(250, 246, 236) },
		{ name = "Beam", size = Vector3.new(2.4, 2.2, 2), cframe = CFrame.new(9, 11.5, -4.1, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(80, 220, 70) },
		{ name = "CactusArm", size = Vector3.new(2.52, 1.44, 1.44), cframe = CFrame.new(8.34, 4.22, 1.7, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(118, 204, 64) },
		{ name = "CactusArm", size = Vector3.new(1.44, 2.76, 1.44), cframe = CFrame.new(8.88, 6.32, 1.7, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(118, 204, 64) },
		{ name = "Flower", size = Vector3.new(1.44, 0.84, 1.44), cframe = CFrame.new(6, 8.12, 1.7, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(255, 110, 170) },
		{ name = "Cactus", size = Vector3.new(2.16, 8, 2.16), cframe = CFrame.new(6, 3.7, 1.7, 1, 0, 0, 0, 1, 0, 0, 0, 1), color = Color3.fromRGB(118, 204, 64) },
	},
	carl = Vector3.new(0, 0, 2.1), -- his feet (Carl the cactus guy behind the counter: Server/TrailShop, Client/TrailShop)
}
