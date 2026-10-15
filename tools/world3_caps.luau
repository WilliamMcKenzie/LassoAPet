-- World 3: every wall cap painted from Config's CapColor for the biome it's in (shows Config's colours in Edit).
local m = game.ReplicatedStorage.Shared.Config:Clone(); m.Name = "ConfigCopy"; m.Parent = game.ReplicatedStorage.Shared
local C = require(m); m:Destroy()
local n = 0
for _, p in workspace.World.Walls:GetChildren() do
	if p:IsA("BasePart") and p.Name == "Cap" and p.Position.Z < 0 then
		local edge, i = 0, #C.Biomes
		for k, b in C.Biomes do edge -= b.Length; if p.Position.Z > edge then i = k; break end end
		local c = C.Biomes[i].CapColor
		if c then p.Color = c; n += 1 end
	end
end
return n .. " caps painted from Config"
