-- Console and controller play: every HUD action has a gamepad button, and the
-- menus work with the D-pad and B. (Xbox names; a PlayStation pad's buttons sit
-- in the same places: A = cross, B = circle, X = square, Y = triangle.)
--
--   At home       X      RIDE, ROLL, Hatch now (their prompts' own gamepad key)
--                 Y      MERGE
--                 LB/RB  the egg before / after in the inventory; RT puts it down
--                 D-pad  up Shop, left Roll, down Pets, right Upgrade Pen
--   Riding        A/RT   LASSO, TAKE EGG; LT sprint; RB ability;
--                        the left stick steers (pushed far out, it sprints)
--   Fail screen   A      Home; Y Continue
--   Menus         B      closes; the dictionary turns pages with LB / RB, the
--                        roll menu rolls with A and shows the odds with Y, the
--                        shop's cards are picked with the D-pad and bought with A
--
-- Each button's picture (the platform's own, Xbox or PlayStation) shows on its
-- HUD button only while a controller is the last thing used, so mouse, keyboard
-- and touch players see the HUD exactly as before.
--
--   Gamepad.active                           -- a controller was the last input
--   Gamepad.onChanged(fn)                    -- fn(active) now and on every change
--   Gamepad.hint(parent, keyCode, at, size)  -- the button picture, centred at `at` (scale) on parent
--   Gamepad.bind(name, keyCode, fn, when)    -- a press calls fn() while when() is true
--   Gamepad.openMenu(name, spec)             -- spec: close (B), keys {[KeyCode] = fn},
--                                            -- group (keeps the D-pad inside it), select (fn -> first button)
--   Gamepad.closeMenu(name)

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Sounds = require(script.Parent.Sounds)

local Gamepad = {}

-- Over the ride's own keys (Ride.client binds Sprint and Ability at High and
-- passes them on at home): a menu's keys come first, then the HUD's.
local MENU_PRIORITY = Enum.ContextActionPriority.High.Value + 10
local BIND_PRIORITY = Enum.ContextActionPriority.Medium.Value + 1

local PADS = {}
for i = 1, 8 do
	PADS[Enum.UserInputType["Gamepad" .. i]] = true
end
-- Inputs that mean the player is on mouse, keyboard or touch again.
local OTHERS = {
	[Enum.UserInputType.Keyboard] = true,
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseButton2] = true,
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.MouseWheel] = true,
	[Enum.UserInputType.Touch] = true,
}

Gamepad.active = PADS[UserInputService:GetLastInputType()] == true
	or (UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled) -- a console

local listeners = {}
local hints = setmetatable({}, { __mode = "k" }) -- [ImageLabel] = its KeyCode
local menus = {} -- open menus: name -> spec

local function selectIn(spec)
	if Gamepad.active and spec.select and not GuiService.SelectedObject then
		local first = spec.select()
		if first then
			GuiService.SelectedObject = first
		end
	end
end

local function setActive(active)
	if active == Gamepad.active then
		return
	end
	Gamepad.active = active
	for hint, keyCode in hints do
		hint.Image = UserInputService:GetImageForKeyCode(keyCode) -- (an Xbox or PlayStation pad's own)
		hint.Visible = active
	end
	if active then
		for _, spec in menus do
			selectIn(spec)
		end
	else
		GuiService.SelectedObject = nil -- no selection frame for the mouse
	end
	for _, fn in listeners do
		task.spawn(fn, active)
	end
end

UserInputService.LastInputTypeChanged:Connect(function(inputType)
	if PADS[inputType] then
		setActive(true)
	elseif OTHERS[inputType] then
		setActive(false)
	end
end)

function Gamepad.onChanged(fn)
	table.insert(listeners, fn)
	task.spawn(fn, Gamepad.active)
end

function Gamepad.hint(parent, keyCode, at, size)
	local hint = Instance.new("ImageLabel")
	hint.Name = "GamepadHint"
	hint.BackgroundTransparency = 1
	hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.Position = UDim2.fromScale(at.X, at.Y)
	hint.Size = UDim2.fromOffset(size or 52, size or 52)
	hint.ZIndex = 10
	hint.Image = UserInputService:GetImageForKeyCode(keyCode)
	hint.Visible = Gamepad.active
	hint.Parent = parent
	hints[hint] = keyCode
	return hint
end

function Gamepad.bind(name, keyCode, fn, when)
	ContextActionService:BindActionAtPriority("Gamepad" .. name, function(_, state)
		if state ~= Enum.UserInputState.Begin or not when() then
			return Enum.ContextActionResult.Pass
		end
		Sounds.click() -- (as a click on the button would)
		fn()
		return Enum.ContextActionResult.Sink
	end, false, BIND_PRIORITY, keyCode)
end

function Gamepad.openMenu(name, spec)
	Gamepad.closeMenu(name)
	menus[name] = spec
	local keys = { Enum.KeyCode.ButtonB }
	for keyCode in spec.keys or {} do
		table.insert(keys, keyCode)
	end
	ContextActionService:BindActionAtPriority("GamepadMenu" .. name, function(_, state, input)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if input.KeyCode == Enum.KeyCode.ButtonB then
			spec.close()
		else
			spec.keys[input.KeyCode]()
		end
		return Enum.ContextActionResult.Sink
	end, false, MENU_PRIORITY, table.unpack(keys))
	if spec.group then
		-- The D-pad moves between this menu's buttons only.
		spec.group.SelectionGroup = true
		spec.group.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
		spec.group.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
		spec.group.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
		spec.group.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	end
	selectIn(spec)
end

function Gamepad.closeMenu(name)
	local spec = menus[name]
	if not spec then
		return
	end
	menus[name] = nil
	ContextActionService:UnbindAction("GamepadMenu" .. name)
	local selected = GuiService.SelectedObject
	if selected and spec.group and selected:IsDescendantOf(spec.group) then
		GuiService.SelectedObject = nil
	end
end

-- With a button selected, B can be taken by the selection itself before the
-- menu's binding sees it: it still closes the menu.
UserInputService.InputBegan:Connect(function(input, processed)
	if processed and input.KeyCode == Enum.KeyCode.ButtonB then
		for _, spec in table.clone(menus) do
			spec.close()
		end
	end
end)

return Gamepad
