-- A banner sweep, as the tutorial's (Client/Tutorial's, viggle-chess's PhaseBanner): a band
-- wider than the screen fades in and out near the top while QM's words sweep straight
-- across it from off the left to off the right, fast at both edges and slowest in the
-- middle. The boss's red "RUN!!!" one (QM, Oct 13) as the chase starts.
--   Banner.show(key) -- one of BANNERS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BANNERS = {
	run = {
		strips = { { "120342028003991", 863 }, { "139392495812157", 862 }, { "96189903736044", 862 } }, -- assets/ui/BossBanner1-3.png (QM's red PromptBanner 2.png, 2587 x 113, in thirds)
		words = { "130252233835389", Vector2.new(136, 40) }, -- assets/ui/BossRun.png "RUN!!!"
		tall = 0.55, -- the words' height x the band's
	},
}
local SIZE = Vector2.new(2587, 113) -- the band's pixels
local WIDTH, AT, TRAVEL = 1.3, 0.17, 0.6 -- (the tutorial's: x the screen's width; its middle down the screen; how far the words go)
local A, B = 2.592, 0.136 -- the words' speed A (2u - 1)^2 + B of their average
local FADE, TIME = 0.16, 3 -- of the sweep fading in and out; seconds in all

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "Banner"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
local band = Instance.new("Frame")
band.BackgroundTransparency = 1
band.AnchorPoint = Vector2.new(0.5, 0.5)
band.Position = UDim2.fromScale(0.5, AT)
band.Size = UDim2.fromScale(WIDTH, 1)
band.Visible = false
local ratio = Instance.new("UIAspectRatioConstraint")
ratio.AspectRatio = SIZE.X / SIZE.Y
ratio.Parent = band
local pieces = {}
for i = 1, 3 do
	local piece = Instance.new("ImageLabel")
	piece.BackgroundTransparency = 1
	piece.ImageTransparency = 1
	piece.Parent = band
	pieces[i] = piece
end
local words = Instance.new("ImageLabel")
words.BackgroundTransparency = 1
words.AnchorPoint = Vector2.new(0.5, 0.5)
words.ZIndex = 2
words.ImageTransparency = 1
words.Parent = band
band.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

task.spawn(function() -- (loaded before they're needed)
	local labels = {}
	for _, b in BANNERS do
		for _, strip in b.strips do
			local l = Instance.new("ImageLabel")
			l.Image = "rbxassetid://" .. strip[1]
			table.insert(labels, l)
		end
		local l = Instance.new("ImageLabel")
		l.Image = "rbxassetid://" .. b.words[1]
		table.insert(labels, l)
	end
	pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), labels)
end)

local Banner = {}
local sweep

function Banner.show(key)
	local b = BANNERS[key]
	if not b then
		return
	end
	local from = 0
	for i, strip in b.strips do
		pieces[i].Image = "rbxassetid://" .. strip[1]
		pieces[i].Position = UDim2.fromScale(from / SIZE.X, 0)
		pieces[i].Size = UDim2.fromScale(strip[2] / SIZE.X, 1)
		from += strip[2]
	end
	words.Image = "rbxassetid://" .. b.words[1]
	local w = b.words[2]
	words.Size = UDim2.fromScale(b.tall * w.X / w.Y * SIZE.Y / SIZE.X, b.tall)
	band.Visible = true
	if sweep then
		sweep:Disconnect()
	end
	local started = os.clock()
	local this
	this = RunService.RenderStepped:Connect(function()
		local u = math.min((os.clock() - started) / TIME, 1)
		local along = A * ((2 * u - 1) ^ 3 + 1) / 6 + B * u -- 0 to 1 (the speed's integral)
		words.Position = UDim2.fromScale(0.5 + (2 * along - 1) * TRAVEL / WIDTH, 0.5)
		local shown = math.clamp(math.min(u / FADE, (1 - u) / FADE), 0, 1)
		for _, piece in pieces do
			piece.ImageTransparency = 1 - shown
		end
		words.ImageTransparency = 1 - shown
		if u >= 1 then
			this:Disconnect()
			band.Visible = false
		end
	end)
	sweep = this
end

return Banner
