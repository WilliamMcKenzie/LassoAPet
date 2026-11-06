-- Biome borders (QM, Nov 6): where each biome starts is a part in the place, not a number
-- in Config, so the biomes can be stretched and shrunk by dragging their borders in Studio.
--
-- workspace.World.Borders holds one part per biome after the first, named after its
-- Config.Biomes Name ("Desert", "Snow", ...), standing across the course where that biome
-- starts, and one called "End" where the course ends (the finish line). Only each part's
-- Z counts. The Meadow always starts at the start line (z = 0).
--
-- Config calls Borders.apply at the end, so Config.Biomes[i].Length and Config.CourseLength
-- come out of the borders, and everything that reads them (WorldColors.biomeAt, the herds,
-- nests, sky, finish line, quests) follows. A place without the folder keeps Config's
-- Lengths. A missing border keeps its biome's Config Length; one dragged past its
-- neighbour is pushed back to a stud after it (with a warning in the Output).
--
-- In Play the borders are hidden (World.server). In Edit, the Lasso Map plugin
-- (tools/studio/LassoMap.lua) repaints the ground and walls whenever a border moves.

local RunService = game:GetService("RunService")

local Borders = {}

local MIN = 16 -- (the shortest a biome can be)

-- workspace.World.Borders, or nil. (On a client this waits for the place to load first,
-- as Shared/Studs does: StreamingEnabled is off, so the whole map is there by then.)
function Borders.folder()
	if RunService:IsClient() and RunService:IsRunning() and not game:IsLoaded() then
		game.Loaded:Wait()
	end
	local world = workspace:FindFirstChild("World")
	return world and world:FindFirstChild("Borders")
end

-- Sets Config.Biomes[i].Length and Config.CourseLength from the borders.
function Borders.apply(Config, folder)
	folder = folder or Borders.folder()
	if not folder or Config.Endless then
		return false
	end
	local biomes = Config.Biomes
	local starts = { 0 }
	for i = 2, #biomes do
		local part = folder:FindFirstChild(biomes[i].Name)
		local z = if part and part:IsA("BasePart") then part.Position.Z else starts[i - 1] - biomes[i - 1].Length
		if z > starts[i - 1] - MIN then
			warn(string.format("[Borders] %s's border is past %s's start: moved to z %d", biomes[i].Name, biomes[i - 1].Name, starts[i - 1] - MIN))
			z = starts[i - 1] - MIN
		end
		starts[i] = z
	end
	local finish = folder:FindFirstChild("End")
	local last = #biomes
	local endZ = if finish and finish:IsA("BasePart")
		then finish.Position.Z - Config.FinishFromEnd -- (the finish line stands FinishFromEnd before the course's end)
		else starts[last] - biomes[last].Length
	if endZ > starts[last] - MIN then
		endZ = starts[last] - MIN
	end
	for i = 1, last do
		-- (a whole number of studs, so the floor's checker and the Lengths read cleanly)
		local far = if i < last then starts[i + 1] else endZ
		biomes[i].Length = math.floor(starts[i] - far + 0.5)
	end
	Config.CourseLength = math.floor(-endZ + 0.5)
	return true
end

-- Every border, made where Config has its biome start (and the end) if it isn't there yet.
-- For the Lasso Map plugin's "Make borders" and a place being set up.
function Borders.make(Config, world)
	local folder = world:FindFirstChild("Borders")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Borders"
		folder.Parent = world
	end
	local edge = 0
	local width = (Config.CourseMaxHalfWidth or 137) * 2 + 40
	local function put(name, z, color)
		local part = folder:FindFirstChild(name)
		if part then
			return part
		end
		part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Transparency = 0.6
		part.Size = Vector3.new(width, 80, 2)
		part.CFrame = CFrame.new(0, 40, z)
		local label = Instance.new("BillboardGui")
		label.Name = "Label"
		label.Size = UDim2.fromOffset(240, 48)
		label.StudsOffset = Vector3.new(0, 52, 0)
		label.AlwaysOnTop = true
		label.LightInfluence = 0
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0
		text.Text = if name == "End" then "End (finish line)" else name .. " starts"
		text.Parent = label
		label.Parent = part
		part.Parent = folder
		return part
	end
	for i, biome in Config.Biomes do
		if i > 1 then
			put(biome.Name, edge, biome.GroundColors[1])
		end
		edge -= biome.Length
	end
	put("End", -Config.CourseLength + Config.FinishFromEnd, Color3.fromRGB(255, 60, 60))
	return folder
end

-- In Play: the borders can't be seen or touched.
function Borders.hide(folder)
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = 1
		elseif d:IsA("LayerCollector") then
			d.Enabled = false
		end
	end
end

return Borders
