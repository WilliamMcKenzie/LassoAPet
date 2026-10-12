-- The portal gate's swirl (QM, Oct 12: his quasicrystal, ported from his JS): a low-res
-- EditableImage in the gate's opening, both faces, see-through where the waves cancel,
-- a sum of cos waves over ANGLES directions drifting with time, in big square pixels,
-- with a soft light. Drawn only while the gate's near and on screen, at most FPS a second.
-- World.BaseDecor.PortalGate (tools/portal_gate.py: the opening is 14 wide, from the base's
-- top at 2.8 up to the arch's inside, 7.2 round from 17).

local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local W, H = 28, 44 -- pixels (each half a stud)
local SIZE = Vector2.new(14, 22) -- studs
local CENTRE = Vector3.new(0, 2.8 + 11, 0) -- the opening's middle, in the gate's frame
local SPRING, R_IN = 17 - 2.8, 7.2 -- (in the opening's own frame, from its bottom)
local ANGLES = 7
local FILL = Color3.fromRGB(69, 142, 157) -- QM's teal
local SPEED = 1 / 16 -- his offset step a frame, at 60 a second
local FPS = 24
local NEAR = 220 -- studs: no drawing further off

local gate = workspace:WaitForChild("World"):WaitForChild("BaseDecor"):WaitForChild("PortalGate", 30)
if not gate then
	return
end

local okImage, image = pcall(AssetService.CreateEditableImage, AssetService, { Size = Vector2.new(W, H) })
if not okImage or not image then
	return -- (no EditableImage here: no swirl)
end

local plane = Instance.new("Part")
plane.Name = "PortalSwirl"
plane.Anchored, plane.CanCollide, plane.CanQuery, plane.CanTouch = true, false, false, false
plane.Transparency = 1
plane.Size = Vector3.new(SIZE.X, SIZE.Y, 0.2)
plane.CFrame = (if gate:IsA("Model") then gate:GetPivot() else gate.CFrame) * CFrame.new(CENTRE) -- (29 shaded stones, pivoted on the gate's origin)
local light = Instance.new("PointLight")
light.Color = FILL
light.Range = 20
light.Brightness = 1.5
light.Parent = plane
for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
	local surface = Instance.new("SurfaceGui")
	surface.Face = face
	surface.CanvasSize = Vector2.new(W * 8, H * 8)
	surface.LightInfluence = 0
	surface.Brightness = 1.6 -- (a little brighter than lit: it glows)
	surface.Parent = plane
	local label = Instance.new("ImageLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.ResampleMode = Enum.ResamplerMode.Pixelated
	label.ImageContent = Content.fromObject(image)
	label.Parent = surface
end
plane.Parent = workspace

-- Which pixels are in the opening (a rectangle with a half circle on top).
local inside = table.create(W * H, false)
for py = 0, H - 1 do
	for px = 0, W - 1 do
		local x = (px + 0.5) / W * SIZE.X - SIZE.X / 2
		local y = SIZE.Y - (py + 0.5) / H * SIZE.Y
		inside[py * W + px + 1] = y < SPRING or (x * x + (y - SPRING) * (y - SPRING) < R_IN * R_IN)
	end
end

local dirs = {}
for i = 0, ANGLES - 1 do
	local a = 2 * math.pi - 2 * math.pi / ANGLES * i
	dirs[i + 1] = { math.cos(a), math.sin(a) }
end
local r, g, b = math.floor(FILL.R * 255), math.floor(FILL.G * 255), math.floor(FILL.B * 255)
local pixels = buffer.create(W * H * 4)
local offset = 0
local last = 0
local camera = workspace.CurrentCamera

local function draw()
	for py = 0, H - 1 do
		local y = py - H / 2
		for px = 0, W - 1 do
			local i = py * W + px
			local alpha = 0
			if inside[i + 1] then
				local x = px - W / 2
				local sum = 0
				for k = 1, ANGLES do
					local d = dirs[k]
					sum += math.cos(d[1] * x + d[2] * y + offset)
				end
				alpha = math.clamp(sum * 10 / ANGLES, 0, 1) -- (his: opacity / angles, each wave x10)
			end
			local o = i * 4
			buffer.writeu8(pixels, o, r)
			buffer.writeu8(pixels, o + 1, g)
			buffer.writeu8(pixels, o + 2, b)
			buffer.writeu8(pixels, o + 3, math.floor(alpha * 255 * 0.85))
		end
	end
	image:WritePixelsBuffer(Vector2.zero, Vector2.new(W, H), pixels)
end

RunService.RenderStepped:Connect(function(dt)
	offset += SPEED * dt * 60
	local now = os.clock()
	if now - last < 1 / FPS then
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
	local t = os.clock()
	draw()
	plane:SetAttribute("DrawMs", (os.clock() - t) * 1000) -- (for measuring)
end)
