-- A biome's own sky (QM, Oct 11: the Volcano's lava orange): while the camera's over a
-- biome with a Sky (Config.Biomes[i].Sky, a flat image), the Sky's six faces show it;
-- anywhere else they're put back as World.server made them. A Skybox can't be tinted,
-- so it's a swap at the biome's line.
--
-- The sky also lights the scene (Roblox's environment lighting takes its colour), which
-- is what turns everything red-orange in the Volcano. How much, and a tint over it all,
-- are the biome's SkyLight (QM, Oct 11): Diffuse (how strongly the sky colours things,
-- 0 not at all), Specular (how much shiny surfaces reflect it) and Tint (the screen's
-- colour correction tint, white for none). In Studio the camera gets BiomeSkyDiffuse,
-- BiomeSkySpecular and BiomeSkyTint attributes at the Volcano's values (Workspace >
-- Camera, in the Client view of a playtest); while set they win, in any biome with a sky.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local FACES = { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }
local usual -- [face] = World.server's image
local showing -- the biome sky up now (nil: the usual)
local lit -- the lighting as it was before a biome's sky changed it: { diffuse, specular, tint }

local NO_LIGHT = { Diffuse = 0.4, Specular = 1, Tint = Color3.new(1, 1, 1) } -- (a sky without SkyLight)

if RunService:IsStudio() then
	local function seed()
		local camera = workspace.CurrentCamera
		local light
		for _, biome in Config.Biomes do
			light = light or biome.SkyLight
		end
		if camera and light then
			for _, key in { "Diffuse", "Specular", "Tint" } do
				if camera:GetAttribute("BiomeSky" .. key) == nil then
					camera:SetAttribute("BiomeSky" .. key, light[key])
				end
			end
		end
	end
	seed()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(seed)
end

local function lightOf(biome)
	local light = biome.SkyLight or NO_LIGHT
	local camera = workspace.CurrentCamera
	local function get(key)
		local v = camera and camera:GetAttribute("BiomeSky" .. key)
		if v == nil then
			return light[key] or NO_LIGHT[key]
		end
		return v
	end
	return get("Diffuse"), get("Specular"), get("Tint")
end

RunService.RenderStepped:Connect(function()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		return
	end
	local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local z = workspace.CurrentCamera.CFrame.Position.Z
	local biome = if z < 0 then Config.Biomes[WorldColors.biomeAt(z)] else nil
	local want = biome and biome.Sky
	-- The sky's light (every frame while it's up, so the attributes take at once).
	if want then
		if not lit then
			lit = {
				diffuse = Lighting.EnvironmentDiffuseScale,
				specular = Lighting.EnvironmentSpecularScale,
				tint = if correction then correction.TintColor else nil,
			}
		end
		local diffuse, specular, tint = lightOf(biome)
		Lighting.EnvironmentDiffuseScale = diffuse
		Lighting.EnvironmentSpecularScale = specular
		if correction then
			correction.TintColor = tint
		end
	elseif lit then
		Lighting.EnvironmentDiffuseScale = lit.diffuse
		Lighting.EnvironmentSpecularScale = lit.specular
		if correction and lit.tint then
			correction.TintColor = lit.tint
		end
		lit = nil
	end
	if want == showing then
		return
	end
	if not usual then
		usual = {}
		for _, face in FACES do
			usual[face] = sky["Skybox" .. face]
		end
	end
	for _, face in FACES do
		sky["Skybox" .. face] = want or usual[face]
	end
	showing = want
end)
