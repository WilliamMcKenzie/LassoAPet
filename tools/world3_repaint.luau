local m = game.ReplicatedStorage.Shared.Config:Clone(); m.Parent = game.ReplicatedStorage.Shared
local C = require(m); m:Destroy()
local b = C.Biomes[1]
local function cols(name)
	if name == "Ground" then return b.GroundColors end
	if name == "Wall" then return b.WallColors end
	if name == "Cap" then return { b.CapColor, b.CapColor } end
	return b.Patches[name]
end
local n, w = 0, 0
for _, folder in { workspace.World.Ground, workspace.World.Walls } do
	for _, p in folder:GetChildren() do
		if p:IsA("BasePart") and p.Position.Z > -4336 then
			local c = cols(p.Name)
			if c then
				p.Color = c[1]
				for _, t in p:GetChildren() do
					if t.Name == "Checker" then t.Color3 = c[2] elseif t.Name == "Texture" then t.Color3 = c[1] end
					if t:IsA("Texture") and t.Name == "Water" then t.Texture = C.Water.Image; t.Color3 = Color3.new(1, 1, 1); w += 1 end
				end
				n += 1
			end
		end
	end
end
return n .. " parts repainted, " .. w .. " water textures"
