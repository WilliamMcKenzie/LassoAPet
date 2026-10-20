-- Phones and tablets get the lighter memory settings (QM, Oct 20: crashes on <2 GB
-- phones). Creator Hub's out-of-memory exits are all phones and tablets with under
-- 4 GB, and a game can't read a device's RAM, so touch-only stands in for it.
--
--   LowMemory.on -- true on a touch-only device: don't pin pictures in memory, and
--                   skip preloading art that isn't needed straight away

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

return {
	on = UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled
		and not GuiService:IsTenFootInterface(),
}
