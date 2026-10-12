-- The portal gate's swirl (QM, Oct 12: his quasicrystal, ported from his JS): a low-res
-- EditableImage in the gate's opening, both faces. Each pixel sums cos waves over Angles
-- directions (his getOpacity / getColor), drifting with time; that sets how much of the
-- fill colour shows over the backdrop colour. Drawn only while the gate's near and on
-- screen, at most FPS times a second.
--
-- Tuning, live (QM): every knob is an attribute on World.BaseDecor.PortalGate (DEFAULTS
-- below; missing ones are added with these values). Change them in Studio's Properties,
-- in Edit or while playing, and the swirl follows at once.
--   Angles      his `angles`: how many wave directions (any number, 2 to 12 or so)
--   Speed       his `speed`: how fast it drifts (his offset += speed / 16 a frame at 60 fps)
--   Scale       how big the pattern is: wave cycles per pixel (his 1 a cell; smaller: bigger blobs)
--   Modifier    his `modifier`: twists each direction by 2 x modifier x (pi / angles x i)
--   Seed        shifts each wave's phase at random (0: none, as his)
--   Contrast    his x10 on each wave: higher is harder edged
--   FillColor / FillAlpha   the pattern's colour and how opaque it is (his fill, 0..1)
--   BackColor / BackAlpha   the backdrop behind it (0: see-through, as his canvas)
--   PixelsPerStud           the pixel size (2: half-stud pixels); rebuilds the image
--   Glow        how bright the pixels are (SurfaceGui.Brightness; above 1 they glow)
--   LightBrightness / LightRange   the soft light it casts (its colour is FillColor)
--   FPS         redraws a second
-- World.BaseDecor.PortalGate (tools/portal_gate.py: the opening is 14 wide, from the base's
-- top at 2.8 up to the arch's inside, 7.2 round from 17).

local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local DEFAULTS = { -- (QM's picks, Oct 12)
	Angles = 7.1,
	Speed = 0.5,
	Scale = 0.5,
	Modifier = 0,
	Seed = 0,
	Contrast = 10,
	FillColor = Color3.fromRGB(69, 142, 157), -- his teal
	FillAlpha = 0.2,
	BackColor = Color3.fromRGB(2, 125, 156), -- his tealbg
	BackAlpha = 0.3,
	PixelsPerStud = 4,
	Glow = 5,
	LightBrightness = 0,
	LightRange = 0,
	FPS = 16,
}
local SIZE = Vector2.new(14, 22) -- studs
local CENTRE = Vector3.new(0, 2.8 + 11, 0) -- the opening's middle, in the gate's frame
local SPRING, R_IN = 17 - 2.8, 7.2 -- (in the opening's own frame, from its bottom)
local NEAR = 220 -- studs: no drawing further off

local gate = workspace:WaitForChild("World"):WaitForChild("BaseDecor"):WaitForChild("PortalGate", 30)
if not gate then
	return
end
for name, value in DEFAULTS do
	if gate:GetAttribute(name) == nil then
		gate:SetAttribute(name, value)
	end
end
local function knob(name)
	local v = gate:GetAttribute(name)
	return if typeof(v) == typeof(DEFAULTS[name]) then v else DEFAULTS[name]
end

local plane = Instance.new("Part")
plane.Name = "PortalSwirl"
plane.Anchored, plane.CanCollide, plane.CanQuery, plane.CanTouch = true, false, false, false
plane.Transparency = 1
plane.Size = Vector3.new(SIZE.X, SIZE.Y, 0.2)
plane.CFrame = (if gate:IsA("Model") then gate:GetPivot() else gate.CFrame) * CFrame.new(CENTRE) -- (29 shaded stones, pivoted on the gate's origin)
local light = Instance.new("PointLight")
light.Parent = plane
local surfaces, labels = {}, {}
for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
	local surface = Instance.new("SurfaceGui")
	surface.Face = face
	surface.CanvasSize = Vector2.new(SIZE.X * 16, SIZE.Y * 16)
	surface.LightInfluence = 0
	surface.Parent = plane
	local label = Instance.new("ImageLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.ResampleMode = Enum.ResamplerMode.Pixelated
	label.Parent = surface
	table.insert(surfaces, surface)
	table.insert(labels, label)
end
plane.Parent = workspace

-- "Coming soon" over the gate while you're near it (QM, Oct 12: it doesn't go anywhere yet).
local SOON_NEAR = 25 -- studs from the opening
local soon = Instance.new("BillboardGui")
soon.Name = "PortalComingSoon"
soon.Adornee = plane
soon.Size = UDim2.fromScale(16, 3)
soon.StudsOffsetWorldSpace = Vector3.new(0, SIZE.Y / 2 + 8, 0) -- (over the keystone)
soon.LightInfluence = 0
soon.Enabled = false
local soonText = Instance.new("TextLabel")
soonText.BackgroundTransparency = 1
soonText.Size = UDim2.fromScale(1, 1)
soonText.Text = "Coming soon"
soonText.TextScaled = true
soonText.TextColor3 = Color3.new(1, 1, 1)
soonText.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local soonStroke = Instance.new("UIStroke")
soonStroke.Thickness = 3
soonStroke.Parent = soonText
soonText.Parent = soon
soon.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
RunService.Heartbeat:Connect(function()
	local character = game:GetService("Players").LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	soon.Enabled = root ~= nil and (root.Position - plane.Position).Magnitude < SOON_NEAR + SIZE.Y / 2
end)

-- The image, its pixels' buffer and which pixels are in the opening (a rectangle with a
-- half circle on top), (re)built for a pixel size.
local image, pixels, inside, W, H, builtFor
local function build(perStud)
	perStud = math.clamp(math.floor(perStud + 0.5), 1, 8)
	if builtFor == perStud then
		return image ~= nil
	end
	builtFor = perStud
	W, H = math.floor(SIZE.X * perStud), math.floor(SIZE.Y * perStud)
	local ok, made = pcall(AssetService.CreateEditableImage, AssetService, { Size = Vector2.new(W, H) })
	if not ok or not made then
		image = nil
		return false -- (no EditableImage here: no swirl)
	end
	if image then
		image:Destroy()
	end
	image = made
	for _, label in labels do
		label.ImageContent = Content.fromObject(image)
	end
	pixels = buffer.create(W * H * 4)
	inside = table.create(W * H, false)
	for py = 0, H - 1 do
		for px = 0, W - 1 do
			local x = (px + 0.5) / W * SIZE.X - SIZE.X / 2
			local y = SIZE.Y - (py + 0.5) / H * SIZE.Y
			inside[py * W + px + 1] = y < SPRING or (x * x + (y - SPRING) * (y - SPRING) < R_IN * R_IN)
		end
	end
	return true
end

-- His waves for the knobs now: { cos, sin, phase } a direction (his angle runs from 2 pi
-- down by 2 pi / angles; bonus = pi / angles x i).
local function waves()
	local angles = math.max(knob("Angles"), 1)
	local mod = knob("Modifier")
	local seed = knob("Seed")
	local rng = Random.new(math.floor(seed))
	local list = {}
	local angle = 2 * math.pi
	local i = 0
	while i < angles do
		local bonus = math.pi / angles * i
		local phase = if seed ~= 0 then rng:NextNumber() * 2 * math.pi else 0
		table.insert(list, { math.cos(angle - 2 * (mod * bonus)), math.sin(angle + 2 * (mod * bonus)), phase })
		angle -= 2 * math.pi / angles
		i += 1
	end
	return list, angles
end

local offset = 0
local last = 0
local camera = workspace.CurrentCamera

local function draw()
	local dirs, angles = waves()
	local scale = knob("Scale")
	local contrast = knob("Contrast")
	local fill, back = knob("FillColor"), knob("BackColor")
	local fa, ba = math.clamp(knob("FillAlpha"), 0, 1), math.clamp(knob("BackAlpha"), 0, 1)
	local fr, fg, fb = fill.R, fill.G, fill.B
	local br, bg, bb = back.R, back.G, back.B
	local n = #dirs
	for py = 0, H - 1 do
		local y = (py - H / 2) * scale
		for px = 0, W - 1 do
			local i = py * W + px
			local o = i * 4
			if inside[i + 1] then
				local x = (px - W / 2) * scale
				local sum = 0
				for k = 1, n do
					local d = dirs[k]
					sum += math.cos(d[1] * x + d[2] * y + offset + d[3])
				end
				-- (his rgba alpha: opacity / angles, each wave x Contrast; then over the backdrop)
				local a = math.clamp(sum * contrast / angles, 0, 1) * fa
				local outA = a + ba * (1 - a)
				local r, g, b = 0, 0, 0
				if outA > 0 then
					r = (fr * a + br * ba * (1 - a)) / outA
					g = (fg * a + bg * ba * (1 - a)) / outA
					b = (fb * a + bb * ba * (1 - a)) / outA
				end
				buffer.writeu8(pixels, o, math.floor(r * 255))
				buffer.writeu8(pixels, o + 1, math.floor(g * 255))
				buffer.writeu8(pixels, o + 2, math.floor(b * 255))
				buffer.writeu8(pixels, o + 3, math.floor(outA * 255))
			else
				buffer.writeu32(pixels, o, 0)
			end
		end
	end
	image:WritePixelsBuffer(Vector2.zero, Vector2.new(W, H), pixels)
end

RunService.RenderStepped:Connect(function(dt)
	offset += knob("Speed") / 16 * dt * 60
	local now = os.clock()
	if now - last < 1 / math.max(knob("FPS"), 1) then
		return
	end
	if (camera.CFrame.Position - plane.Position).Magnitude > NEAR then
		return
	end
	local _, onScreen = camera:WorldToViewportPoint(plane.Position)
	if not onScreen then
		return
	end
	last = now
	if not build(knob("PixelsPerStud")) then
		return
	end
	for _, surface in surfaces do
		surface.Brightness = knob("Glow")
	end
	light.Color = knob("FillColor")
	light.Brightness = knob("LightBrightness")
	light.Range = knob("LightRange")
	local t = os.clock()
	draw()
	plane:SetAttribute("DrawMs", (os.clock() - t) * 1000) -- (for measuring)
end)
