-- World 3: every wall cap painted from Config's CapColor for the biome it's in (shows Config's colours in Edit).
local m = game.ReplicatedStorage.Shared.Config:Clone(); m.Name = "ConfigCopy"; m.Parent = game.ReplicatedStorage.Shared
local C = require(m); m:Destroy()
local n = 0
for _, p in workspace.World.Walls:GetChildren() do
	if p:IsA("BasePart") and (p.Name == "Cap" or p.Name == "Wall") and p.Position.Z < 0 then
		local edge, i = 0, #C.Biomes
		for k, b in C.Biomes do edge -= b.Length; if p.Position.Z > edge then i = k; break end end
		local b = C.Biomes[i]
		if p.Name == "Cap" then if b.CapColor then p.Color = b.CapColor; n += 1 end else p.Color = b.WallColors[1]; for _, t in p:GetChildren() do if t.Name == "Checker" then t.Color3 = b.WallColors[2] end end; n += 1 end
	end
end
return n .. " walls and caps painted from Config"
