-- World 2's portal gate in the base's rock shades (QM, Oct 13: the same as the other base
-- stones, not white marble): each stone one of the five warm greys, in turn.
-- Run in Studio (Edit) on the World 2 Place (workspace.World) or World 1's copy (World2).
local ROOT = workspace:FindFirstChild("World2") or workspace.World
local rgb = Color3.fromRGB
local ROCKS = { rgb(153, 146, 135), rgb(129, 124, 115), rgb(173, 166, 150), rgb(140, 137, 117), rgb(164, 153, 144) }
local n = 0
for _, p in ROOT.BaseDecor.PortalGate:GetDescendants() do
	if p:IsA("BasePart") then
		n += 1
		p.Color = ROCKS[(n - 1) % #ROCKS + 1]
	end
end
return n .. " portal stones recoloured"
