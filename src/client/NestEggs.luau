-- The egg nests, as this client shows them. Every nest always holds an egg, and the
-- eggs are yours alone (QM, Oct 6: no shared stock, nothing to restock): each Nest
-- in World.Nests holds the egg NestOdds rolls for it from your NestSeed, a number
-- the server gives you when you join and after every ride (Nests.server), so the
-- nests are stocked afresh each ride and the server rolls the same egg when you
-- grab one. But the egg you take is the animal you're riding (QM, Oct 6): once
-- you've lassoed a wild animal, the nests of its own biome show that animal's egg
-- instead, swapping with a bounce on every hop (setMount); nests anywhere else keep
-- their rolled eggs (QM, Oct 7: no Kraken eggs in the Meadow on the ride home;
-- NestOdds.ridden), and on your own pet you see the rolled egg everywhere.
-- EggSpot marks the egg's centre. The egg is a rigged model so it can twitch in the
-- nest. (Ride.client grabs them and draws the guide to the nearest; Nests.server
-- takes the grab. A nest you've emptied stays so for you till the ride's over.)
-- The tutorial's last nest, at the end of the Meadow (Nests.server), shows only while
-- you're in the tutorial, and its egg is in reach from wall to wall (its Reach).
--
--   NestEggs.start()            -- once the World's ready: every nest's egg, kept up with your seed
--   NestEggs.waiting[nest]      -- { egg, kind, nest, reach, ... } while the nest shows an egg
--   NestEggs.setMount(kind)     -- the wild animal you're on, or "" (every ride start and hop)
--   NestEggs.eggOf(entity)      -- what to set for `entity`: its kind, or "" on your own pet
--   NestEggs.mountKind          -- what was last set (the grab tells the server, so the two must agree)
--   NestEggs.show(nest, popIn)  -- shows what `nest` holds for you now, popping it in when `popIn`
--   NestEggs.update(dt, view)   -- every frame: twitches, swaps and pops (view: studs the camera can see)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local NestOdds = require(ReplicatedStorage.Shared.NestOdds)

local player = Players.LocalPlayer
local world = workspace:WaitForChild("World")
local camera = workspace.CurrentCamera
local rng = Random.new()

local TWITCH_EVERY = { 2, 4 } -- seconds between twitches, random in this range
-- A nest's egg popping in when it changes (your hop onto another animal): it starts
-- small, hops up and lands with a squash at Land seconds, overshoots and settles by
-- Time, then twitches once. Only nests within Swap studs of the camera swap (each
-- is a model built; further ones wait till they're near).
local POP = { Time = 0.7, Land = 0.35, Swap = 700 }

local NestEggs = {}
NestEggs.waiting = {} -- [nest] = { egg, kind, nest, nextTwitch, reach, scale, rest, pop, landed }
NestEggs.mountKind = "" -- the wild animal you're riding, else "" (the nests' own rolled eggs)
local rolled = {} -- [nest] = the egg NestOdds rolled for it from your seed (cleared with the seed)
local rolledFull = {} -- [nest] = the same from its biome's whole table (the ride home's)
NestEggs.homeward = false -- on the way home with the egg (Ride): a lassoed mount's nests show random eggs

function NestEggs.setMount(kind)
	NestEggs.mountKind = kind -- (the nests catch up in update: near ones with a bounce, far ones when they're near)
end

-- The egg the nests hold while you're on `entity`: its kind (an event's animal too:
-- QM, Oct 6, finding and riding one is the hard part), or "" (the rolled egg) on your
-- own pet (riding your best pet to a nest would copy it every ride).
function NestEggs.eggOf(entity)
	return if entity.own then "" else entity.kind
end

-- The kind of egg `nest` (its EggSpot at `z`) holds for you right now: your mount's,
-- if the nest holds one at all and it's in your mount's biome, else what your seed
-- rolled for it.
local function kindFor(nest, z)
	local kind = rolled[nest]
	if kind == nil then
		local seed = player:GetAttribute("NestSeed")
		kind = if seed then NestOdds.roll(nest, seed) else ""
		rolled[nest] = kind
	end
	if kind == "" or NestEggs.mountKind == "" then
		return kind -- (your own pet: always the rolled egg)
	end
	if NestEggs.homeward then
		-- On the way home on a lassoed animal: random eggs from the biome's whole table
		-- (QM, Oct 8: just to look at; nothing's taken on the way back).
		local full = rolledFull[nest]
		if full == nil then
			local seed = player:GetAttribute("NestSeed")
			full = if seed then NestOdds.roll(nest, seed, true) else ""
			rolledFull[nest] = full
		end
		return full
	end
	return NestOdds.ridden(NestEggs.mountKind, z) or kind
end

-- A popping egg's scale (x its rest size) and height (studs over its rest spot) at t.
local function pop(t)
	local scale = 1 - 0.35 * math.exp(-4 * t) * math.cos(13.8 * t)
	local height = 1.2 * math.sin(math.pi * math.clamp(t / POP.Land, 0, 1))
	return scale, height
end

-- Forgets `nest`'s egg (a nest that's gone, or lost its EggSpot).
local function drop(nest)
	local waiting = NestEggs.waiting[nest]
	if waiting then
		waiting.egg.model:Destroy()
	end
	NestEggs.waiting[nest], rolled[nest], rolledFull[nest] = nil, nil, nil
end

function NestEggs.show(nest, popIn)
	local spot = nest:FindFirstChild("EggSpot")
	if not spot or nest.Parent ~= world.Nests then
		drop(nest) -- (not a whole nest: it showed up in live error reports)
		return
	end
	if nest:GetAttribute("Tutorial") then
		local mine = player:GetAttribute("Tutorial") == true
		if not mine then
			drop(nest)
		end
		for _, part in nest:GetDescendants() do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.LocalTransparencyModifier = if mine then 0 else 1
			end
		end
		if not mine then
			return
		end
	end
	local kind = kindFor(nest, spot.Position.Z)
	local waiting = NestEggs.waiting[nest]
	if waiting and waiting.kind == kind then
		return
	end
	if waiting then
		waiting.egg.model:Destroy()
		NestEggs.waiting[nest] = nil
	end
	if kind ~= "" then
		waiting = { egg = Egg.new(kind), kind = kind, nest = nest, nextTwitch = 0.5 + math.random() * 1.5 }
		-- A bigger nest (Nests.server: its biome's NestScale) is takeable from that much
		-- further, and its egg is as much bigger, there and the whole ride home (QM, Oct 6;
		-- others see it so from your "CarriedEggScale"). The tutorial's last nest sets its own.
		local scale = nest:GetScale() / (nest:GetAttribute("BaseScale") or nest:GetScale())
		waiting.reach = nest:GetAttribute("Reach") or Config.LassoRange * scale
		waiting.scale = scale
		if scale ~= 1 then
			waiting.egg.model:ScaleTo(waiting.egg.size * scale)
			Egg.fitStuds(waiting.egg.model)
		end
		-- (EggSpot is a 1x egg's centre, scaled with the nest: a bigger egg sits higher so it stays on the nest)
		waiting.rest = spot.CFrame * CFrame.new(0, 1.6 * scale * (waiting.egg.size - 1), 0) * CFrame.Angles(0, math.pi, 0)
		waiting.egg.model:PivotTo(waiting.rest)
		waiting.egg.model.Parent = nest
		NestEggs.waiting[nest] = waiting
		if popIn then
			waiting.pop = 0
		end
	end
end

-- The waiting eggs twitch now and then: something's alive in there (only the ones
-- near enough to see). One showing the wrong animal (you hopped: setMount) swaps
-- once it's within POP.Swap studs, with a bounce if in view.
function NestEggs.update(dt, view)
	local camPos = camera.CFrame.Position
	local stale, gone = nil, nil
	for nest, waiting in NestEggs.waiting do
		local spot = nest:FindFirstChild("EggSpot")
		if not spot or nest.Parent ~= world.Nests then
			gone = gone or {}
			table.insert(gone, nest)
		elseif waiting.egg.model.Parent then
			local away = (spot.Position - camPos).Magnitude
			if waiting.kind ~= kindFor(nest, spot.Position.Z) and away < POP.Swap then
				stale = stale or {}
				table.insert(stale, { nest = nest, pop = away < view })
			elseif waiting.pop then
				waiting.pop += dt
				local scale, height = pop(waiting.pop)
				if waiting.pop >= POP.Time then
					waiting.pop, scale, height = nil, 1, 0
				elseif waiting.pop >= POP.Land and not waiting.landed then
					waiting.landed = true
					waiting.egg:play("twitch")
				end
				waiting.egg.model:ScaleTo(waiting.egg.size * waiting.scale * scale)
				waiting.egg.model:PivotTo(waiting.rest * CFrame.new(0, height, 0))
			end
			waiting.nextTwitch -= dt
			if waiting.nextTwitch <= 0 and away > view then
				waiting.nextTwitch = rng:NextNumber(TWITCH_EVERY[1], TWITCH_EVERY[2])
			elseif waiting.nextTwitch <= 0 then
				waiting.egg:play("twitch")
				waiting.nextTwitch = rng:NextNumber(TWITCH_EVERY[1], TWITCH_EVERY[2])
			end
			waiting.egg:update(dt)
		end
	end
	for _, nest in gone or {} do -- (after the loop, like the swaps)
		drop(nest)
	end
	for _, swap in stale or {} do -- (after the loop: show re-keys waiting)
		NestEggs.show(swap.nest, swap.pop)
	end
end

-- Every nest's egg, rolled again from each new seed (a ride's over: Nests.server).
function NestEggs.start()
	local function watch(nest)
		if nest:FindFirstChild("EggSpot") then
			NestEggs.show(nest)
		else
			task.spawn(function() -- (a new Godlands nest's parts can land a moment after it)
				if nest:WaitForChild("EggSpot", 10) then
					NestEggs.show(nest)
				end
			end)
		end
		nest.Destroying:Connect(function() -- (a Godlands nest no one's near any more: Nests.server)
			drop(nest)
		end)
	end
	for _, nest in world.Nests:GetChildren() do
		watch(nest)
	end
	world.Nests.ChildAdded:Connect(watch) -- the Godlands' nests come and go (Nests.server)
	player:GetAttributeChangedSignal("NestSeed"):Connect(function()
		table.clear(rolled)
		table.clear(rolledFull)
		for _, nest in world.Nests:GetChildren() do
			if not NestEggs.waiting[nest] then
				NestEggs.show(nest) -- one you emptied is full again (the rest swap as you near them: update)
			end
		end
	end)
	player:GetAttributeChangedSignal("Tutorial"):Connect(function()
		for _, nest in world.Nests:GetChildren() do
			if nest:GetAttribute("Tutorial") then
				NestEggs.show(nest) -- the tutorial's last nest: there for the tutorial, gone after it
			end
		end
	end)
end

return NestEggs
