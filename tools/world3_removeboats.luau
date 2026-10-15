-- World 3 (QM, Oct 15): the rowboats and the pebbles (World.Decor.Plates) out of the game, moved to
-- ServerStorage.W3Removed (not deleted).
local SS = game:GetService("ServerStorage")
local bin = SS:FindFirstChild("W3Removed") or Instance.new("Folder")
bin.Name = "W3Removed"; bin.Parent = SS
local boats, plates = 0, 0
for _, d in workspace:GetDescendants() do
	if d:IsA("Model") and d.Name == "Rowboat" and d.Parent then d.Parent = bin; boats += 1 end
end
local p = workspace.World.Decor:FindFirstChild("Plates")
if p then plates = #p:GetChildren(); p.Parent = bin end
return boats .. " rowboats and " .. plates .. " pebbles moved to ServerStorage.W3Removed"
