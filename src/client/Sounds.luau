-- Sound effects and music (QM, Oct 4: the first wave). The effects are Kenney's (CC0),
-- kept in assets/sounds; the music is APM's, free in any Roblox game, straight from the
-- Creator Store. A sound whose id is "" isn't uploaded yet and stays silent.
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
	lasso_throw = "", -- the lasso leaves the player's hand
	lasso_land = "", -- landed on the animal it caught
	egg_grab = "", -- an egg lassoed mid-ride
	gallop_loop = "", -- while riding a galloping animal (Config.GallopSound)
	sprint_whoosh = "", -- Sprint starts
	smash = "", -- the pet smashes through an obstacle
	crash = "", -- crashed or bucked off
	arrive_home = "", -- back over the start line with an egg
	reveal_tick = "", -- each flick of the egg card (and the roll's)
	reveal_pop = "", -- the egg card lands on its rarity
	egg_hatch = "", -- an egg in your pen hatches
	gold_tick = "", -- gold counting up
	merge_whoosh = "", -- pets pulled together to merge
	merge_poof = "", -- the poof as they combine
	merge_pop = "", -- the merged pet pops out
	button_click = "", -- every UI button
	roll_reveal = "", -- a roll (or the shop's Legend Egg) lands on its egg
	purchase = "", -- a Robux purchase goes through
	countdown = "", -- 3, 2, 1 before an event's animal spawns
	countdown_go = "", -- it spawns
}
local MUSIC = {
	base = "rbxassetid://1840347412", -- Way Out West (APM): at home
	ride = "rbxassetid://1836101135", -- Huba Huba Cartoon Chase (APM): out riding
}
local VOLUME = 0.5
local GALLOP_VOLUME = 0.35
local MUSIC_VOLUME = 0.25
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

function Sounds.play(name, volume, speed)
	local id = IDS[name]
	if not id or id == "" then
		return
	end
	local s = newSound(id, volume or VOLUME)
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

local music = {}
local playing
function Sounds.setMusic(which)
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

-- Every button in the UI clicks when pressed, except the invisible full-screen ones
-- that close a menu when you click off it.
local hooked = setmetatable({}, { __mode = "k" })
local function hook(button)
	if not button:IsA("GuiButton") or hooked[button] then
		return
	end
	hooked[button] = true
	button.Activated:Connect(function()
		if button.Size ~= UDim2.fromScale(1, 1) then
			Sounds.play("button_click", 0.4)
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
