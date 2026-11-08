-- The leaderboards (Config.Leaderboards, QM Nov 7): Top Money, Top Luck and Top Playtime, side
-- by side left of the start line, a copy of QM's reference boards. Each is Parts: a plinth with
-- a glowing strip, a studded frame, a dark diamond over and under the list, and a trapezoid
-- title banner. Client/Leaderboards draws the title on "Title" and the list on "Screen".
--
-- Every Refresh seconds it records everyone here in each board's OrderedDataStore ("u" ..
-- UserId = their latest), reads each Top back, mixed with this server's players (so it works
-- in Studio without API access too), and puts it in ReplicatedStorage.Leaderboards.<Key> (a
-- StringValue: JSON { { id, name, value } }, best first; Luck's value is luck x 100).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Config = require(ReplicatedStorage.Shared.Config)
local Studs = require(ReplicatedStorage.Shared.Studs)

local Stands = require(ReplicatedStorage.Shared.Stands)
local CFG = Config.Leaderboards
local MAX = 2 ^ 53 -- (an OrderedDataStore holds whole numbers)

-- Each board's stat for a player (a whole number; 0 = not on the board).
local STAT = {
	Money = function(player)
		return tonumber(player:GetAttribute("PenIncome")) or 0
	end,
	Luck = function(player)
		return Config.luck(player) * 100
	end,
	Playtime = function(player)
		return tonumber(player:GetAttribute("PlayTime")) or 0
	end,
}

-- ---- the boards -------------------------------------------------------------
-- Board space: x right, y up from the ground, the board's front facing -z.

local function part(model, name, colour, size, cf, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanQuery = false
	p.CanTouch = false
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Locked = true
	p.Parent = model
	return p
end

-- A right triangle in the board's plane (thickness t, its middle at depth z): the right angle
-- at (x, y), one leg hx (+1 right, -1 left) a long, the other vy (+1 up, -1 down) b long.
-- (A WedgePart's right angle is at its bottom back: legs along its +Y and -Z.)
local function triangle(model, origin, colour, x, y, z, hx, vy, a, b, t)
	local up = Vector3.new(0, vy, 0)
	local back = Vector3.new(-hx, 0, 0)
	local right = up:Cross(back)
	local centre = Vector3.new(x + hx * a / 2, y + vy * b / 2, z)
	local w = Instance.new("WedgePart")
	w.Name = "Wedge"
	w.Anchored = true
	w.CanQuery = false
	w.CanTouch = false
	w.Color = colour
	w.Material = Enum.Material.SmoothPlastic
	w.Size = Vector3.new(t, b, a)
	w.CFrame = origin * CFrame.fromMatrix(centre, right, up, back)
	w.Locked = true
	w.Parent = model
	return w
end

-- A diamond (a rhombus) centred at (x, y): ha half as wide, hb half as tall.
local function diamond(model, origin, colour, x, y, z, ha, hb, t)
	for _, hx in { -1, 1 } do
		for _, vy in { -1, 1 } do
			triangle(model, origin, colour, x, y, z, hx, vy, ha, hb, t)
		end
	end
end

-- A trapezoid wider at the top: its bottom edge hw half wide at y0, h tall, each side d out.
local function trapezoid(model, origin, colour, y0, h, hw, d, z, t)
	part(model, "Banner", colour, Vector3.new(hw * 2, h, t), origin * CFrame.new(0, y0 + h / 2, z))
	triangle(model, origin, colour, -hw, y0 + h, z, -1, -1, d, h, t)
	triangle(model, origin, colour, hw, y0 + h, z, 1, -1, d, h, t)
end

local folder = Instance.new("Folder")
folder.Name = "Leaderboards"

for _, board in CFG.Boards do
	-- each board where the map editor put it (its Stand, by Store; Config's spot without one)
	local origin = Stands.at(board.Store)
	local model = Instance.new("Model")
	model.Name = board.Key
	local main, dark, pale = board.Main, board.Dark, board.Pale

	-- the plinth, its top a shade paler, a glowing strip along its front
	part(model, "Plinth", main, Vector3.new(14.5, 1, 4), origin * CFrame.new(0, 0.5, 0))
	part(model, "PlinthTop", main:Lerp(Color3.new(1, 1, 1), 0.25), Vector3.new(14.1, 0.3, 3.6), origin * CFrame.new(0, 1.15, 0))
	part(model, "Glow", pale:Lerp(Color3.new(1, 1, 1), 0.6), Vector3.new(11, 0.18, 0.1), origin * CFrame.new(0, 0.55, -2.03), Enum.Material.Neon)

	-- the frame: a coloured rim round a pale studded panel, a rim round the list
	local frame = part(model, "Frame", main, Vector3.new(13.7, 16.4, 1.4), origin * CFrame.new(0, 1.3 + 8.2, 0))
	Studs.apply(frame, 1)
	local panel = part(model, "Panel", pale, Vector3.new(12.9, 15.6, 0.2), origin * CFrame.new(0, 1.3 + 8.2, -0.8))
	Studs.apply(panel, 1)
	part(model, "Rim", main:Lerp(pale, 0.35), Vector3.new(11.3, 13.6, 0.2), origin * CFrame.new(0, 2.4 + 6.8, -1))
	local screen = part(model, "Screen", pale:Lerp(Color3.new(0.55, 0.57, 0.66), 0.55), Vector3.new(10.5, 12.8, 0.2), origin * CFrame.new(0, 2.8 + 6.4, -1.1))

	-- the diamonds over and under the list: a coloured edge, dark inside
	for _, y in { 16.75, 2.45 } do
		diamond(model, origin, main, 0, y, -1.3, 6, 1.3, 0.2)
		diamond(model, origin, dark, 0, y, -1.42, 5.1, 1.05, 0.2)
	end

	-- the title banner: a dark trapezoid, the board's colour inside it
	trapezoid(model, origin, dark, 17.6, 3, 7.5, 2, -1.6, 0.6)
	trapezoid(model, origin, main, 17.9, 2.4, 7.34, 1.6, -1.95, 0.1)
	local title = part(model, "Title", main, Vector3.new(19, 3, 0.05), origin * CFrame.new(0, 17.6 + 1.5, -2.05))
	title.Transparency = 1
	title.CanCollide = false

	model.PrimaryPart = screen
	model.Parent = folder
end
folder.Parent = workspace

-- ---- the lists ---------------------------------------------------------------

local values = Instance.new("Folder")
values.Name = "Leaderboards"
local stores = {} -- [key] = its OrderedDataStore, or nil (no API access)
local recorded = {} -- [key] = { [userId] = the value last saved for them }
for _, board in CFG.Boards do
	local v = Instance.new("StringValue")
	v.Name = board.Key
	v.Value = "[]"
	v.Parent = values
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.storeName(board.Store))
	stores[board.Key] = if ok then store else nil
	recorded[board.Key] = {}
end
values.Parent = ReplicatedStorage

local names = {} -- [userId] = username

local function stat(key, player)
	return math.clamp(math.floor(STAT[key](player)), 0, MAX)
end

local function record(player)
	local id = player.UserId
	if id <= 0 then
		return -- (Studio's test players have negative ids)
	end
	for _, board in CFG.Boards do
		local store = stores[board.Key]
		local value = stat(board.Key, player)
		if store and value > 0 and recorded[board.Key][id] ~= value then
			recorded[board.Key][id] = value
			pcall(store.SetAsync, store, "u" .. id, value)
		end
	end
end

local function lookUp(ids)
	local missing = {}
	for _, id in ids do
		if not names[id] and id > 0 then
			table.insert(missing, id)
		end
	end
	if #missing > 0 then
		local okInfo, infos = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, missing)
		if okInfo then
			for _, info in infos do
				names[info.Id] = info.Username
			end
		end
	end
	for _, id in ids do
		if not names[id] then
			local player = Players:GetPlayerByUserId(id)
			if player then
				names[id] = player.Name
			else
				local okName, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
				if okName and name then
					names[id] = name
				end
			end
		end
	end
end

local function refresh()
	for _, player in Players:GetPlayers() do
		record(player)
	end
	for _, board in CFG.Boards do
		local key = board.Key
		local best = {} -- [userId] = value
		local store = stores[key]
		if store then
			local okPages, pages = pcall(store.GetSortedAsync, store, false, CFG.Top)
			if okPages then
				for _, entry in pages:GetCurrentPage() do
					local id = tonumber(string.match(entry.key, "^u(%d+)$"))
					if id then
						best[id] = entry.value
					end
				end
			end
		end
		for _, player in Players:GetPlayers() do -- (theirs live: their latest)
			local mine = stat(key, player)
			if mine > 0 then
				best[player.UserId] = mine
			end
		end
		local rows = {}
		for id, v in best do
			if v > 0 then
				table.insert(rows, { id = id, value = v })
			end
		end
		table.sort(rows, function(a, b)
			return a.value > b.value
		end)
		while #rows > CFG.Top do
			table.remove(rows)
		end
		local ids = {}
		for _, row in rows do
			table.insert(ids, row.id)
		end
		lookUp(ids)
		local out = {}
		for _, row in rows do
			table.insert(out, { row.id, names[row.id] or "Player", row.value })
		end
		values[key].Value = HttpService:JSONEncode(out)
	end
end

Players.PlayerRemoving:Connect(record)
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		record(player)
	end
end)

task.spawn(function()
	task.wait(5) -- (the first players' saves loaded: their PenIncome, luck and PlayTime set)
	while true do
		refresh()
		task.wait(CFG.Refresh)
	end
end)
