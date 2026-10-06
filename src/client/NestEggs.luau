-- The egg nests, as this client shows them: shared stock kept by the server
-- (Nests.server.luau). Each Nest in World.Nests holds the egg its "Egg" attribute
-- names ("" = empty, taken by someone), rolled from its biome's odds. But the egg
-- you take is the animal you're riding (QM, Oct 6): once you've lassoed a wild
-- animal, the nests show that animal's egg instead, swapping with a bounce on every
-- hop (setMount); on your own pet you see the rolled egg. EggSpot marks the egg's
-- centre. The egg is a rigged model so it can twitch in the nest. (Ride.client
-- grabs them and draws the guide to the nearest; Nests.server takes the grab.)
--
--   NestEggs.start()            -- once the World's ready: every nest's egg, kept up with the server's changes
--   NestEggs.waiting[nest]      -- { egg, kind, nest, reach, ... } while the nest shows an egg
--   NestEggs.setMount(kind)     -- the wild animal you're on, or "" (every ride start and hop)
--   NestEggs.eggOf(entity)      -- what to set for `entity`: its kind, or "" on your own pet
--   NestEggs.mountKind          -- what was last set (the grab tells the server, so the two must agree)
--   NestEggs.show(nest, popIn)  -- shows what `nest` holds for you now, popping it in when `popIn`
--   NestEggs.update(dt, view)   -- every frame: twitches, swaps and pops (view: studs the camera can see)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Tutorial = require(script.Parent.Tutorial)

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

function NestEggs.setMount(kind)
	NestEggs.mountKind = kind -- (the nests catch up in update: near ones with a bounce, far ones when they're near)
end

-- The egg the nests hold while you're on `entity`: its kind (an event's animal too:
-- QM, Oct 6, finding and riding one is the hard part), or "" (the rolled egg) on your
-- own pet (riding your best pet to a nest would copy it every ride).
function NestEggs.eggOf(entity)
	return if entity.own then "" else entity.kind
end

-- The kind of egg `nest` holds for you right now: your mount's, if the nest holds
-- one at all, else what the server rolled.
local function kindFor(nest)
	local kind = nest:GetAttribute("Egg") or ""
	if kind == "" and Tutorial.active and nest == Tutorial.nest and not Tutorial.eggTaken then
		kind = Config.TutorialEgg -- the tutorial's egg, only for you (Tutorial)
	end
	return if kind ~= "" and NestEggs.mountKind ~= "" then NestEggs.mountKind else kind
end

-- A popping egg's scale (x its rest size) and height (studs over its rest spot) at t.
local function pop(t)
	local scale = 1 - 0.35 * math.exp(-4 * t) * math.cos(13.8 * t)
	local height = 1.2 * math.sin(math.pi * math.clamp(t / POP.Land, 0, 1))
	return scale, height
end

function NestEggs.show(nest, popIn)
	local kind = kindFor(nest)
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
		-- others see it so from your "CarriedEggScale").
		local scale = nest:GetScale() / (nest:GetAttribute("BaseScale") or nest:GetScale())
		waiting.reach = Config.LassoRange * scale
		waiting.scale = scale
		if scale ~= 1 then
			waiting.egg.model:ScaleTo(waiting.egg.size * scale)
		end
		-- (EggSpot is a 1x egg's centre, scaled with the nest: a bigger egg sits higher so it stays on the nest)
		waiting.rest = nest.EggSpot.CFrame * CFrame.new(0, 1.6 * scale * (waiting.egg.size - 1), 0) * CFrame.Angles(0, math.pi, 0)
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
	local stale = nil
	for nest, waiting in NestEggs.waiting do
		if waiting.egg.model.Parent then
			local away = (nest.EggSpot.Position - camPos).Magnitude
			if waiting.kind ~= kindFor(nest) and away < POP.Swap then
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
	for _, swap in stale or {} do -- (after the loop: show re-keys waiting)
		NestEggs.show(swap.nest, swap.pop)
	end
end

-- Every nest's egg, kept up with the server's changes, and the tutorial's: its nest
-- shows this player an egg while the tutorial's on (Tutorial).
function NestEggs.start()
	local function watch(nest)
		NestEggs.show(nest)
		nest.Destroying:Connect(function() -- (a Godlands nest no one's near any more: Nests.server)
			NestEggs.waiting[nest] = nil
		end)
		nest:GetAttributeChangedSignal("Egg"):Connect(function()
			NestEggs.show(nest)
		end)
	end
	for _, nest in world.Nests:GetChildren() do
		watch(nest)
	end
	world.Nests.ChildAdded:Connect(watch) -- the Godlands' nests come and go (Nests.server)
	Tutorial.init(function()
		if Tutorial.nest then
			NestEggs.show(Tutorial.nest)
		end
	end)
end

return NestEggs
