-- World 3 (QM, Oct 14): every prop in the Pirate Cove course (World3Prop, z 0 to -4336) 2x, grown
-- about its pivot (the middle of its base), so it stays on the floor.
local n, names = 0, {}
for _, d in workspace.World:GetDescendants() do
	if d:IsA("Model") and d:GetAttribute("World3Prop") then
		local z = d:GetPivot().Position.Z
		if z < 0 and z > -4336 then
			d:ScaleTo(d:GetScale() * 2)
			n += 1
			names[d.Name] = (names[d.Name] or 0) + 1
		end
	end
end
local t = {} for k, v in names do table.insert(t, k .. "=" .. v) end table.sort(t)
return n .. " props 2x: " .. table.concat(t, ", ")
