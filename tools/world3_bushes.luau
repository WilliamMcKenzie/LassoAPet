-- World 3's base: bushes along the tops of its walls (QM, Oct 14: the bushes from the cove
-- draft, nothing else). Run in Studio (Edit, execute_luau) on the World 3 Place, QM not in Play,
-- after uploading design/w3_base/pieces/Bush_1..3.obj (colours.txt) as the Model
-- ServerStorage.World3Assets.Base.Bush (pivot at the middle of its base). Re-running is fine:
-- it replaces World.BaseDecor.Bushes. Touches nothing else.
local W = workspace.World
local SS = game:GetService("ServerStorage")
local GAP_MIN, GAP_MAX = 20, 40 -- studs between bushes along a wall (the draft's density)
local SCALE_MIN, SCALE_MAX = 0.9, 1.4

local template = SS:FindFirstChild("World3Assets") and SS.World3Assets:FindFirstChild("Base") and SS.World3Assets.Base:FindFirstChild("Bush")
assert(template, "no ServerStorage.World3Assets.Base.Bush")
local old = W.BaseDecor:FindFirstChild("Bushes")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "Bushes"
folder.Parent = W.BaseDecor

local rng = Random.new(7)
local n = 0
for _, cap in W.Walls:GetChildren() do
	if cap:IsA("BasePart") and cap.Name == "BaseCap" then
		local along = if cap.Size.X >= cap.Size.Z then cap.CFrame.RightVector else cap.CFrame.LookVector
		local across = if cap.Size.X >= cap.Size.Z then cap.CFrame.LookVector else cap.CFrame.RightVector
		local L = math.max(cap.Size.X, cap.Size.Z)
		local top = cap.Position + cap.CFrame.UpVector * cap.Size.Y / 2
		local s = rng:NextNumber(6, GAP_MIN)
		while s < L - 6 do
			local p = top + along * (s - L / 2) + across * rng:NextNumber(-1.5, 1.5)
			local m = template:Clone()
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
				end
			end
			m:ScaleTo(rng:NextNumber(SCALE_MIN, SCALE_MAX))
			m:PivotTo(CFrame.new(p) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0))
			m.Parent = folder
			n += 1
			s += rng:NextNumber(GAP_MIN, GAP_MAX)
		end
	end
end
print("bushes:", n)
