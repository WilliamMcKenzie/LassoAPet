-- Reads the animal lineup (tools/lineup.luau) back: every animal whose model was
-- rescaled in Studio, and what Config.AnimalScale should become for it (its old value
-- x the change). Run in Edit mode; prints and returns them as Luau table entries.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local copy = ReplicatedStorage.Shared.Config:Clone() -- (fresh: the command bar caches what it required)
copy.Parent = game:GetService("ServerStorage")
local Config = require(copy)
copy:Destroy()

local lineup = workspace:FindFirstChild("AnimalLineup")
if not lineup then
	return "no lineup"
end
local out = {}
for _, model in lineup:GetChildren() do
	local built = model:IsA("Model") and model:GetAttribute("LineupScale")
	if built then
		local change = model:GetScale() / built
		if math.abs(change - 1) > 0.005 then
			local now = (Config.AnimalScale[model.Name] or 1) * change
			table.insert(out, string.format("%s = %.2f", model.Name, now))
		end
	end
end
table.sort(out)
local text = if #out > 0 then table.concat(out, ", ") else "nothing changed"
print(text)
return text
