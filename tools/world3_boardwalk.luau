-- World 3 (QM, Oct 15): the Pirate Cove boardwalk (its Planks floor parts) a stud higher.
local n = 0
for _, p in workspace.World.Ground:GetChildren() do
	if p:IsA("BasePart") and p.Name == "Planks" and p.Position.Z < 0 and p.Position.Z > -4336 then
		p.Size += Vector3.new(0, 1, 0)
		p.Position += Vector3.new(0, 0.5, 0)
		n += 1
	end
end
return n .. " boardwalk parts a stud higher"
