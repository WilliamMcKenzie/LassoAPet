-- Pet pictures: each pet's headshot (assets/ui/Pet<Kind>.png, tools/pet_headshots.py)
-- and its card, the headshot faded into its rarity's slot picture, as the
-- selected-animal card (Hud) shows it. (The old Pets panel this came from is gone:
-- the Pets button opens the animal dictionary, AnimalDex.)
--
--   PetFaces.face(kind, size, flip) -- a Frame, size px square; flip mirrors the headshot
--   PetFaces.HEADSHOTS[kind]       -- the headshot's image id ("" if not uploaded)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animals = ReplicatedStorage.Shared.Animals

local PetFaces = {}

-- Headshots rendered from each pet's model; "" until uploaded, when the card
-- shows the pet's name instead.
local HEADSHOTS = {
	Horse = "rbxassetid://129206679931938", -- PetHorse.png
	Pinto = "rbxassetid://137788325926698", -- PetPinto.png
	Pig = "rbxassetid://126771183103796", -- PetPig.png
	Fish = "rbxassetid://73704828076245", -- PetFish.png
	Rhino = "rbxassetid://135065306024440", -- PetRhino.png
	Unicorn = "rbxassetid://123940745305285", -- PetUnicorn.png
	Cactus = "rbxassetid://95422181220957", -- PetCactus.png
	Scorpion = "rbxassetid://85451012004987", -- PetScorpion.png
	Sandworm = "rbxassetid://122144649250110", -- PetSandworm.png
	Snake = "rbxassetid://91376372256857", -- PetSnake.png
	Penguin = "rbxassetid://126516601606999", -- PetPenguin.png
	Snowman = "rbxassetid://131420314948529", -- PetSnowman.png
	SpineLizard = "rbxassetid://88911086754037", -- PetSpineLizard.png
	Boar = "rbxassetid://110647985191783", -- PetBoar.png
	IceGolem = "rbxassetid://97270712812416", -- PetIceGolem.png
	SnackYak = "rbxassetid://94992992543344", -- PetSnackYak.png
	Icebringer = "rbxassetid://76507499572286", -- PetIcebringer.png
	Kraken = "rbxassetid://97706370740023", -- PetKraken.png
	Squid = "rbxassetid://114559155845756", -- PetSquid.png
	Whale = "rbxassetid://109306533952798", -- PetWhale.png
	KingCrab = "rbxassetid://131403632828209", -- PetKingCrab.png
	BlueCrab = "rbxassetid://122498091168554", -- PetBlueCrab.png
	Starfish = "rbxassetid://112526271674778", -- PetStarfish.png
	FishSchool = "rbxassetid://132126224577278", -- PetFishSchool.png
	Loong = "rbxassetid://110728718265049", -- PetLoong.png
}
-- QM's slot pictures by rarity (as the inventory bar); a plain colour until one is uploaded.
local SLOTS = {
	Common = "rbxassetid://137596967858841", -- assets/ui/SlotCommon.png
	Uncommon = "rbxassetid://120075276423928",
	Rare = "rbxassetid://92909054184182",
	Epic = "rbxassetid://75096704585668",
	Legendary = "rbxassetid://100279863676585",
}
local COMMON_COLOR = Color3.fromRGB(150, 160, 175)


local FONT = Enum.Font.FredokaOne
-- Headshot transparency across the card: clear at the edges, solid in the middle.
local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.2, 0),
	NumberSequenceKeypoint.new(0.8, 0),
	NumberSequenceKeypoint.new(1, 1),
})

local function rarityOf(kind)
	local module = Animals:FindFirstChild(kind)
	return module and require(module).Rarity or "Common"
end

local function stroked(object, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = object
	return s
end

-- A pet's picture: its rarity's slot with its headshot faded into it (or its
-- name, without one), size px square. flip mirrors the headshot.
local function petFace(kind, size, flip)
	local face = Instance.new("Frame")
	face.Size = UDim2.fromOffset(size, size)
	face.BackgroundColor3 = COMMON_COLOR
	Instance.new("UICorner", face).CornerRadius = UDim.new(52 / 256, 0) -- the slot pictures' corners
	local slot = SLOTS[rarityOf(kind)]
	if not slot or slot == "" then
		stroked(face, 5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- the slot pictures have their own
	else
		face.BackgroundTransparency = 1
		local bg = Instance.new("ImageLabel")
		bg.BackgroundTransparency = 1
		bg.Size = UDim2.fromScale(1, 1)
		bg.Image = slot
		bg.Parent = face
	end
	local shot = HEADSHOTS[kind]
	if shot and shot ~= "" then
		-- The headshot fades out toward every edge so it melts into the slot
		-- picture instead of being cut off hard: one gradient fades it left and
		-- right, the CanvasGroup around it fades the result top and bottom.
		local fade = Instance.new("CanvasGroup")
		fade.BackgroundTransparency = 1
		fade.AnchorPoint = Vector2.new(0.5, 0.5)
		fade.Position = UDim2.fromScale(0.5, 0.5)
		fade.Size = UDim2.fromScale(0.92, 0.92) -- inside the slot picture's own border
		fade.ZIndex = 2
		local picture = Instance.new("ImageLabel")
		picture.BackgroundTransparency = 1
		picture.Size = UDim2.fromScale(1, 1)
		picture.Image = shot
		if flip then -- mirrored: the 512px headshot read right to left
			picture.ImageRectOffset, picture.ImageRectSize = Vector2.new(512, 0), Vector2.new(-512, 512)
		end
		picture.Parent = fade
		local sides = Instance.new("UIGradient")
		sides.Transparency = FADE
		sides.Parent = picture
		local ends = Instance.new("UIGradient")
		ends.Rotation = 90
		ends.Transparency = FADE
		ends.Parent = fade
		fade.Parent = face
	else
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.fromScale(1, 1)
		name.Font = FONT
		name.TextSize = 30
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = kind
		name.ZIndex = 2
		stroked(name, 3)
		name.Parent = face
	end
	return face
end

PetFaces.HEADSHOTS = HEADSHOTS
PetFaces.face = petFace

return PetFaces
