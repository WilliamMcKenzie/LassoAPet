-- Run in Studio (Edit) on the Halloween Place: QM's lighting and the base floor's colours.
local L = game:GetService("Lighting")
local rgb = Color3.fromRGB
-- QM's Halloween lighting (Oct 15, set in Play)
L.Ambient = rgb(232, 134, 0)
L.OutdoorAmbient = rgb(177, 178, 178)
L.ColorShift_Top, L.ColorShift_Bottom = rgb(0, 0, 0), rgb(0, 0, 0)
L.FogColor = rgb(191, 191, 191)
L.Brightness = 0.1
L.ClockTime = 6.1
L.GeographicLatitude = 0
L.ExposureCompensation = 0.66
L.EnvironmentDiffuseScale = 0.134
L.EnvironmentSpecularScale = 0.963
L.FogStart, L.FogEnd = 0, 4000
L.ShadowSoftness = 0.2
L.GlobalShadows = false
local cc = L:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", L)
cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor, cc.Enabled = 0, 0.05, 0.6, rgb(255, 255, 255), true
-- the floor: QM's colours, the studs texture tinted as its checker
local C = {
	Ground = { rgb(121, 65, 137), rgb(113, 61, 130) },
	Grass = { rgb(100, 55, 105), rgb(92, 51, 97) },
	Dirt = { rgb(159, 136, 179), rgb(153, 130, 174) },
}
local n = 0
for _, p in workspace.World.Ground:GetChildren() do
	local c = p:GetAttribute("HalloweenFloor") and C[p.Name]
	if c then
		p.Color = c[1]
		for _, t in p:GetChildren() do
			if t:IsA("Texture") then t.Color3 = c[2] end
		end
		n += 1
	end
end
return n .. " floor parts recoloured, lighting set"
