-- World 3's base decorated with the pirate props (QM, Oct 14): ServerStorage.PirateProps
-- copies laid out by plan_pirate.py into World.BaseDecor.Pirate. Rerunnable.
local W = workspace.World
local PLACE = game:GetService("HttpService"):JSONDecode([==[[{"item": "PalmTree", "x": -68, "z": 124, "yaw": 108.82266872247804, "lean": 10, "leanTo": 90, "y": -0.4}, {"item": "PalmTreeSmall", "x": -58.598602387219636, "z": 147.19442792428737, "yaw": 168.9327303109647, "lean": 12, "leanTo": 67.93581079994429, "y": -0.4}, {"item": "PalmTree", "x": -36, "z": 196, "yaw": 92.18651558704396, "lean": 10, "leanTo": 0, "y": -0.4}, {"item": "PalmTreeSmall", "x": 60, "z": 132, "yaw": 139.6419974805334, "lean": 10, "leanTo": 0, "y": -0.4}, {"item": "PalmTreeSmall", "x": 66.87430271881746, "z": 152.73021719750903, "yaw": 314.27314683973896, "lean": 12, "leanTo": 71.65407389880208, "y": -0.4}, {"item": "PalmTreeSmall", "x": 37.858482014616115, "z": 125.61397490966687, "yaw": 282.6340845099985, "lean": 12, "leanTo": -163.91145614609792, "y": -0.4}, {"item": "PalmTree", "x": 68, "z": 204, "yaw": 92.44121442289149, "lean": 10, "leanTo": 210, "y": -0.4}, {"item": "PalmTree", "x": 44, "z": 84, "yaw": 132.69600804790178, "lean": 10, "leanTo": 300, "y": -0.4}, {"item": "PalmTreeSmall", "x": 25.260911214389346, "z": 93.54713212555761, "yaw": 80.03297055098511, "lean": 12, "leanTo": 153.00221019039182, "y": -0.4}, {"item": "PalmTreeSmall", "x": -84, "z": 268, "yaw": 52.73478754664489, "lean": 10, "leanTo": 0, "y": -0.4}, {"item": "PalmTreeSmall", "x": -65.34323208813343, "z": 259.39639354014656, "yaw": 285.75948717915463, "lean": 12, "leanTo": -24.75688530869472, "y": -0.4}, {"item": "PalmTreeSmall", "x": -101.92226458124793, "z": 285.0128865756879, "yaw": 1.7542958119916818, "lean": 12, "leanTo": 136.49109869495985, "y": -0.4}, {"item": "PalmTree", "x": 124, "z": 308, "yaw": 161.87441593955353, "lean": 10, "leanTo": 30, "y": -0.4}, {"item": "PalmTree", "x": -108, "z": 28, "yaw": 282.3341968000185, "lean": 10, "leanTo": 210, "y": -0.4}, {"item": "PalmTreeSmall", "x": -28, "z": 12, "yaw": 178.30507381695423, "lean": 10, "leanTo": 120, "y": -0.4}, {"item": "PalmTreeSmall", "x": -25.453972924564138, "z": 39.794340571191384, "yaw": 334.18872541920257, "lean": 12, "leanTo": 84.7661779892509, "y": -0.4}, {"item": "PalmTreeSmall", "x": -26.033694007584835, "z": 33.95295905906059, "yaw": 309.45189645134474, "lean": 12, "leanTo": 84.88172881490618, "y": -0.4}, {"item": "PalmTree", "x": 92, "z": 36, "yaw": 88.78275934524095, "lean": 10, "leanTo": 210, "y": -0.4}, {"item": "PalmTree", "x": -180, "z": 20, "yaw": 32.57051053065305, "lean": 10, "leanTo": 210, "y": -0.4}, {"item": "PalmTreeSmall", "x": 156, "z": 156, "yaw": 312.0172700158644, "lean": 10, "leanTo": 0, "y": -0.4}, {"item": "PalmTreeSmall", "x": 173.99715900792398, "z": 175.9337125027816, "yaw": 98.98739703865971, "lean": 12, "leanTo": 47.922687565539604, "y": -0.4}, {"item": "PalmTreeSmall", "x": 169.69038834910216, "z": 175.91670697114606, "yaw": 245.70627622623027, "lean": 12, "leanTo": 55.49606338162662, "y": -0.4}, {"item": "CrateStack", "x": -25.751288694035715, "z": 70.0, "yaw": 175.0099603191309, "y": 0}, {"item": "Barrel", "x": -38.35408628862663, "z": 75.1156126504822, "yaw": 175.0099603191309, "y": 0}, {"item": "Crate", "x": -14.057718371086454, "z": 65.967579746326, "yaw": 195.0099603191309, "y": 0}, {"item": "BarrelGroup", "x": -139.7941858768463, "z": 310.82821822166443, "yaw": 228.6520724482792, "y": 0}, {"item": "Crate", "x": -151.56538508891725, "z": 306.5341677899927, "yaw": 238.6520724482792, "y": 0}, {"item": "Crate", "x": -204.0, "z": 206.9282032302755, "yaw": 132.84017444768998, "y": 0}, {"item": "Crate", "x": -210.71686265499156, "z": 212.7008764475969, "yaw": 147.84017444768998, "y": 0}, {"item": "Barrel", "x": -213.3191019287761, "z": 203.74161583290478, "yaw": 132.84017444768998, "y": 0}, {"item": "Barrel", "x": -206.46624815153413, "z": 197.82229196038855, "yaw": 132.84017444768998, "y": 0}, {"item": "CrateStack", "x": 58.0, "z": 308.53589838486226, "yaw": 435.30954857272377, "y": 0}, {"item": "BarrelGroup", "x": 73.01684392090388, "z": 306.66656731327214, "yaw": 345.30954857272377, "y": 0}, {"item": "CrateStack", "x": 200.0, "z": 48.0, "yaw": 62.80284887030916, "y": 0}, {"item": "Barrel", "x": 209.49945453656156, "z": 57.73449349004868, "yaw": 62.80284887030916, "y": 0}, {"item": "Crate", "x": 191.84703826631403, "z": 38.69789190725821, "yaw": 82.80284887030916, "y": 0}, {"item": "PirateShip", "x": -192, "z": 284, "yaw": 200, "y": -5.5}]]==])
local old = W.BaseDecor:FindFirstChild("Pirate")
if old then old:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "Pirate"
local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Include params.FilterDescendantsInstances = { W.Ground }
local n = 0
for _, o in PLACE do
	local m = game.ServerStorage.PirateProps[o.item]:Clone()
	local hit = workspace:Raycast(Vector3.new(o.x, 50, o.z), Vector3.new(0, -100, 0), params)
	local y = (if o.item == "PirateShip" then -1 else (hit and hit.Position.Y or 0)) + o.y
	local cf = CFrame.new(o.x, y, o.z)
	if o.lean then
		local a = math.rad(o.leanTo)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		cf = cf * CFrame.fromAxisAngle(Vector3.yAxis:Cross(dir).Unit, math.rad(o.lean))
	end
	m:PivotTo(cf * CFrame.Angles(0, math.rad(o.yaw), 0))
	m.Parent = folder
	n += 1
end
-- (and none over a pen at its biggest, canopies too)
local dropped = 0
for _, m in folder:GetChildren() do
	local cf, size = m:GetBoundingBox()
	for _, pen in workspace.Pens:GetChildren() do
		local t = pen.Sizes.Size13.Tiles
		local lp = t.CFrame:PointToObjectSpace(cf.Position)
		local r = math.min(size.X, size.Z) / 2 * 0.7
		if math.abs(lp.X) < t.Size.X / 2 + r and math.abs(lp.Z) < t.Size.Z / 2 + r then
			m:Destroy()
			dropped += 1
			n -= 1
			break
		end
	end
end
folder.Parent = W.BaseDecor
return n .. " props placed, " .. dropped .. " over a pen dropped"
