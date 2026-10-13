-- World 2: a fresh slate (QM, Oct 13): every asset copied from World 1 goes. Run in Studio
-- (Edit, execute_luau) on the place with World2, after the floor scripts (world2_base,
-- world2_meadow_ground, world2_crimson). Re-running is fine.
-- Goes: everything in World2.Obstacles and World2.Decor (World 1's rocks, bushes, cacti,
-- coral, icicles, pines, the ribcage...) and World2.BaseDecor's rocks and plants.
-- Stays: the floor, walls, start line, the portal gate (World travel), World 2's own pines
-- (BaseDecor.Plants' Pine, PineTall, PineSmall) and the Crimson Lands' stone plates
-- (World2.Decor.Plates, QM's ask).
local W = workspace.World2
local KEEP = { Plates = true, PortalGate = true }
local gone = 0
for _, name in { "Obstacles", "Decor", "BaseDecor" } do
	local folder = W:FindFirstChild(name)
	if folder then
		for _, c in folder:GetChildren() do
			if c.Name == "Plants" then -- (the base's: World 2's own pines stay, QM approved them)
				for _, m in c:GetChildren() do
					if not m.Name:match("^Pine") then
						m:Destroy()
						gone += 1
					end
				end
			elseif not KEEP[c.Name] then
				c:Destroy()
				gone += 1
			end
		end
	end
end
return gone .. " World 1 assets cleared"
