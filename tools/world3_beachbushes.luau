-- World 3 (QM, Oct 15): his little beach bushes (World3Assets.Beach.BeachBush / BeachBushSmall) on the
-- sand against the walls of the base and the Pirate Cove, every 40 to 70 studs down each side, big and
-- small mixed, turned at random. World.Decor.BeachBushes; re-running replaces them.
local SS = game:GetService("ServerStorage")
local beach = SS.World3Assets.Beach
local G = workspace.World.Ground
local rng = Random.new(1015)
local old = workspace.World.Decor:FindFirstChild("BeachBushes")
if old then old:Destroy() end
local folder = Instance.new("Folder"); folder.Name = "BeachBushes"; folder.Parent = workspace.World.Decor
local WC = require(game.ReplicatedStorage.Shared.WorldColors)
-- the sand's top under a point (nil if it isn't sand)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { G }
local function sandTop(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), params)
	if hit and (hit.Instance.Name == "Ground" or hit.Instance.Name == "DampSand") then return hit.Position.Y end
	return nil
end
local n = 0
local function put(x, z)
	local y = sandTop(x, z)
	if not y then return end
	local m = (if rng:NextNumber() < 0.45 then beach.BeachBushSmall else beach.BeachBush):Clone()
	m:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0))
	m.Parent = folder
	n += 1
end
-- the Pirate Cove's sides (the walls follow WorldColors.halfWidth; their inner face 4 studs in)
local z = -30
while z > -4300 do
	for _, side in { -1, 1 } do
		local hw = WC.halfWidth(z) - 7
		put(side * hw, z + rng:NextNumber(-10, 10))
	end
	z -= rng:NextNumber(40, 70)
end
-- the base's walls (inner faces at x = +-216, z = 320), inside the sand ring
for zz = 30, 300, 55 do put(-209, zz + rng:NextNumber(-8, 8)); put(209, zz + rng:NextNumber(-8, 8)) end
for xx = -190, 190, 60 do put(xx + rng:NextNumber(-8, 8), 313) end
return n .. " beach bushes placed"
