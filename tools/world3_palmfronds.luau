-- World 3's palms (QM, Oct 14): fronds Camo (the lighter ones) and Parsley green (the darker), as he set one.
local CAMO, PARSLEY = Color3.fromRGB(58, 125, 21), Color3.fromRGB(44, 101, 29)
local n, palms = 0, 0
for _, d in game:GetDescendants() do
	if d:IsA("Model") and d.Name:match("^PalmTree") then
		palms += 1
		local fronds = {}
		for _, p in d:GetDescendants() do if p:IsA("BasePart") and p.Name == "Fronds" then table.insert(fronds, p) end end
		table.sort(fronds, function(a, b) return (a.Color.R + a.Color.G + a.Color.B) > (b.Color.R + b.Color.G + b.Color.B) end)
		for i, p in fronds do p.Color = if i == 1 then CAMO else PARSLEY; n += 1 end
	end
end
return palms .. " palms, " .. n .. " frond parts recoloured"
