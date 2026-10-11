-- Sound effects and music (QM, Oct 4: the first wave). The effects are Kenney's (CC0),
-- kept in assets/sounds; the music is APM's, free in any Roblox game, straight from the
-- Creator Store. The effects are uploaded to the egg hatcha community (Oct 4). A sound
-- whose id is "" isn't uploaded yet and stays silent.
--
--   Sounds.play(name, volume?, speed?)  -- a one-shot (IDS below)
--   Sounds.setGallop(on, pace?)          -- the gallop loop while riding a galloping animal;
--                                        -- pace 0..1+ (its speed over MountSpeed) sets its volume and rate
--   Sounds.setMusic("base" | "ride")     -- crossfades between the two themes
-- Every UI button clicks (button_click) on its own: see the end.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sounds = {}

local IDS = {
	lasso_throw = "rbxassetid://80604101469428", -- the lasso leaves the player's hand
	lasso_land = "rbxassetid://132698985263025", -- landed on the animal it caught
	egg_grab = "rbxassetid://94379425317312", -- an egg lassoed mid-ride
	gallop_loop = "rbxassetid://129029116650332", -- while riding a galloping animal (Config.GallopSound)
	sprint_tier = "rbxassetid://137322083927464", -- Up a sprint tier: Speed Burst SFX (dash cloth, QM's pick, Oct 9)
	sprint_whoosh = "rbxassetid://79833203443837", -- Sprint starts: speed woosh (compressed cloth sfx dash, QM's pick, Oct 9; was 73983934702758)
	ability_use = "rbxassetid://9085320874", -- a pet's ability goes off: Speed Up (Brawl Stars SFX, QM's pick, Oct 9)
	-- A rush of wind looping while you sprint on a mount, a subtle sense of speed (QM, Oct 9):
	-- Spiraling Wind Data Tunnel Travelling 2 (ProSoundEffects, 0:31). Others tried: Plasma
	-- Trails Constant Airy Whooshing Windy 9125742262, Desert Wind Whistley Light Gusts 1 9114057104.
	sprint_wind = "rbxassetid://9119462999",
	-- each lasso throw at your training dummy (Training.client; QM, Oct 8). For now Sprint's
	-- whoosh: assets/sfx/LassoWhoosh.ogg needs uploading in Studio (audio can't be from here)
	training_whoosh = "rbxassetid://73983934702758",
	smash = "rbxassetid://90604529915688", -- the pet smashes through an obstacle
	gate_break = "rbxassetid://139826391278483", -- a biome barrier shatters: glassshatter09 (QM's pick, Oct 9; was Mirror Break 9116938119)
	crash = "rbxassetid://94142874131984", -- crashed or bucked off
	arrive_home = "rbxassetid://87800549075293", -- back over the start line with an egg
	record_scratch = "rbxassetid://112792997660073", -- RECORD SCRATCH (Creator Store, QM's pick): the run home's music cut off at the line (QM, Oct 9)
	reveal_tick = "rbxassetid://91812796089050", -- each flick of the egg card (and the roll's)
	reveal_roll = "rbxassetid://77968740492426", -- under the egg card's flicking roulette, stopped as it lands: GAMBLING (QM's pick, Oct 9)
	-- Each boss's cry as the camera cuts to its face (QM's picks, Oct 10; BossChase, volumes:
	-- Config.Boss.CryVolume):
	boss_Chicken = "rbxassetid://77584650945481", -- chicken cluck
	boss_ElderBoar = "rbxassetid://129162115855106", -- monstergrowl
	boss_SharkBoss = "rbxassetid://9125409840", -- Bubbles Small Underwater
	boss_CactusBoss = "rbxassetid://95169379454314", -- angry alien cat growl
	reveal_pop = "rbxassetid://4612378086", -- the egg card lands on its rarity (after the flicks): rewardscreenreveal (QM's pick, Oct 9; was 117371326373841)
	egg_hatch = "rbxassetid://96102213526905", -- an egg in your pen hatches: Rewards (QM's pick, Oct 9; was 112644148635720)
	gold_tick = "rbxassetid://123673857032707", -- gold counting up
	merge_whoosh = "rbxassetid://131427370077297", -- pets pulled together to merge
	merge_poof = "rbxassetid://102947888103382", -- the poof as they combine
	merge_pop = "rbxassetid://130377429757922", -- the merged pet pops out
	button_click = "rbxassetid://102399207280537", -- every UI button
	roll_reveal = "rbxassetid://101552385373858", -- a roll (or the shop's Legend Egg) lands on its egg
	purchase = "rbxassetid://127625005664662", -- a Robux purchase goes through
	book_open = "rbxassetid://93383284601909", -- a menu (shop, roll, dictionary) opens or closes
	book_flip = "rbxassetid://121038229911289", -- a menu turns a page (the dictionary's arrows, a ? flip)
}
local MUSIC = {
	base = "rbxassetid://1840347412", -- Way Out West (APM): at home
	ride = "rbxassetid://1836101135", -- Huba Huba Cartoon Chase (APM): out riding
	-- The run home (QM, Oct 9: more panicked; Oct 10: the Meadow's wherever you turned
	-- round), APM's "Crime Scene - Action, Race & Chase":
	home1 = "rbxassetid://1847683499", -- Running Faster A (Moritz Bintig, 2:19)
}
local VOLUME = 0.5
local GALLOP_VOLUME = 0.35
local MUSIC_VOLUME = 0.175 -- 70% of 0.25 (QM, Oct 7: a touch quieter)
local MUSIC_FADE = 1.2 -- seconds

local folder = Instance.new("Folder")
folder.Name = "GameSounds"
folder.Parent = SoundService

local function newSound(id, volume, looped)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.Looped = looped or false
	s.Parent = folder
	return s
end

-- Each effect loaded once up front (so the first play of each isn't late or silent);
-- a play is a copy of it.
local templates = {}
for name, id in IDS do
	if id ~= "" then
		templates[name] = newSound(id, VOLUME)
	end
end
task.spawn(function()
	local list = {}
	for _, t in templates do
		table.insert(list, t)
	end
	pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), list)
end)

function Sounds.play(name, volume, speed)
	local template = templates[name]
	if not template then
		return
	end
	local s = template:Clone()
	s.Volume = volume or VOLUME
	s.Parent = folder
	s.PlaybackSpeed = speed or 1
	s.Ended:Once(function()
		s:Destroy()
	end)
	s:Play()
	task.delay(10, function() -- (in case Ended never comes)
		if s.Parent then
			s:Destroy()
		end
	end)
	return s -- (to stop it early)
end

local gallop
function Sounds.setGallop(on, pace)
	if IDS.gallop_loop == "" then
		return
	end
	gallop = gallop or newSound(IDS.gallop_loop, 0, true)
	if not on then
		if gallop.IsPlaying then
			gallop:Stop()
		end
		return
	end
	pace = math.clamp(pace or 1, 0, 3)
	gallop.Volume = GALLOP_VOLUME * math.min(pace, 1)
	gallop.PlaybackSpeed = 0.8 + 0.3 * math.min(pace, 2)
	if not gallop.IsPlaying then
		gallop:Play()
	end
end

-- The sprint's wind loop, faded in and out (Sounds.setSprintWind(on, loudness)):
-- loudness x SPRINT_WIND_VOLUME (QM, Oct 9: louder the faster you go, up to 2x).
local SPRINT_WIND_VOLUME = 0.15 -- (subtle: QM; at a horse's sprint)
local wind, windTween
local windLoud = 1
function Sounds.setSprintWind(on, loudness)
	if IDS.sprint_wind == "" then
		return
	end
	wind = wind or newSound(IDS.sprint_wind, 0, true)
	windLoud = loudness or windLoud
	if on == (wind:GetAttribute("On") == true) then
		if on and not (windTween and windTween.PlaybackState == Enum.PlaybackState.Playing) then
			wind.Volume = SPRINT_WIND_VOLUME * windLoud -- (following the speed once it's in)
		end
		return
	end
	wind:SetAttribute("On", on)
	if on and not wind.IsPlaying then
		wind:Play()
	end
	if windTween then
		windTween:Cancel()
	end
	windTween = TweenService:Create(wind, TweenInfo.new(if on then 0.25 else 0.5), { Volume = if on then SPRINT_WIND_VOLUME * windLoud else 0 })
	windTween:Play()
end

local music = {}
local playing
-- cut: switch with no fade (the old track stops dead, the new one's straight in).
function Sounds.setMusic(which, cut)
	if which == playing then
		return
	end
	playing = which
	for name, id in MUSIC do
		local s = music[name]
		if not s then
			s = newSound(id, 0, true)
			music[name] = s
		end
		local on = name == which
		if on and not s.IsPlaying then
			s.TimePosition = 0
			s:Play()
		end
		if cut then
			s.Volume = if on then MUSIC_VOLUME else 0
			if not on then
				s:Stop()
			end
			continue
		end
		local fade = TweenService:Create(s, TweenInfo.new(MUSIC_FADE), { Volume = if on then MUSIC_VOLUME else 0 })
		if not on then
			fade.Completed:Once(function(state)
				if state == Enum.PlaybackState.Completed and playing ~= name then
					s:Stop()
				end
			end)
		end
		fade:Play()
	end
end

-- Every button in the UI clicks the moment it's pressed down (not on release, QM), except
-- the invisible full-screen ones that close a menu when you click off it. The click
-- is one ready-made Sound, restarted each time, so nothing is built per click.
local click
local function playClick()
	if not templates.button_click then
		return
	end
	if not click then
		click = templates.button_click:Clone()
		click.Volume = 0.4
		click.Parent = folder
	end
	click.TimePosition = 0
	click:Play()
end
Sounds.click = playClick -- (a controller's press on a HUD button: Gamepad)
local hooked = setmetatable({}, { __mode = "k" })
local function hook(button)
	if not button:IsA("GuiButton") or hooked[button] then
		return
	end
	hooked[button] = true
	button.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and button.Size ~= UDim2.fromScale(1, 1) then
			playClick()
		end
	end)
end
task.spawn(function()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, d in playerGui:GetDescendants() do
		hook(d)
	end
	playerGui.DescendantAdded:Connect(hook)
end)

return Sounds
