-- World 3 (QM, Oct 14): the base's walls in two bands, BaseWallLow (the bottom three 8-stud
-- tiles) and BaseWall (the rest), and their caps BaseCap: Config's World 3 Patches paint them
-- dark sand, light sand and grass (WorldColors.paintWall). No marble engraving. Rerunnable.
local rgb = Color3.fromRGB
local LOW = 24 -- three tiles
local COLORS = { BaseWallLow = { rgb(206, 172, 110), rgb(194, 160, 98) }, BaseWall = { rgb(240, 218, 160), rgb(230, 206, 146) } }
local walls, caps = 0, 0
for _, p in workspace.World.Walls:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z + p.Size.Z / 2 > -10 then
		if p.Name == "Cap" or p.Name == "BaseCap" then
			p.Name = "BaseCap"
			p.Color = rgb(96, 204, 60)
			caps += 1
		elseif p.Name == "Wall" then
			local bottom = p.Position.Y - p.Size.Y / 2
			local top = p.Position.Y + p.Size.Y / 2
			for name, band in { BaseWallLow = { bottom, bottom + LOW }, BaseWall = { bottom + LOW, top } } do
				local q = p:Clone()
				q.Name = name
				q.Size = Vector3.new(p.Size.X, band[2] - band[1], p.Size.Z)
				q.CFrame = p.CFrame + Vector3.new(0, (band[1] + band[2]) / 2 - p.Position.Y, 0)
				q.Color = COLORS[name][1]
				for _, t in q:GetChildren() do
					if t.Name == "Engraving" then
						t:Destroy()
					elseif t.Name == "Checker" then
						t.Color3 = COLORS[name][2]
					end
				end
				if name == "BaseWall" then
					for k in q:GetAttributes() do q:SetAttribute(k, nil) end -- (the funnel's notes stay on the bottom band)
				end
				q.Parent = p.Parent
			end
			p:Destroy()
			walls += 1
		end
	end
end
return walls .. " walls split, " .. caps .. " caps"
