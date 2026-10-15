-- World 3 Candyland (QM, Oct 15): its floor is now flat at top 1 (tools/world3_candyland.luau), so its
-- props stand at 1 too. Run after that floor script, in Edit, QM not in Play. Re-running is fine.
local W = workspace.World
local TOP = 1
local moved = 0
for _, folder in { W.Obstacles, W.Decor:FindFirstChild("Props") } do
	for _, m in folder and folder:GetChildren() or {} do
		if m:GetAttribute("World3Prop") == "Candyland" then
			local cf = m:GetPivot()
			if math.abs(cf.Y - TOP) > 0.01 then
				m:PivotTo(cf + Vector3.new(0, TOP - cf.Y, 0))
				moved += 1
			end
		end
	end
end
return moved .. " Candyland props set level on the floor"
