--[[
	Minimap — Client Keybind
	Binds the M key to open (or navigate to) the Phone2 Map app.

	Uses ContextActionService so it auto-unbinds when the GUI is destroyed
	on respawn. Pressing M while the map is already open closes the phone.

	Requires Phone2 to be loaded in StarterGui (waits up to 10 s).
]]

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Fusion3 = require(ReplicatedFirst:WaitForChild("Fusion3"))
local peek = Fusion3.peek

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for Phone2 to initialize (it parents itself into PlayerGui)
local Phone2Module = PlayerGui:WaitForChild("Phone2", 10)
if not Phone2Module then
	warn("[Minimap] Phone2 not found in PlayerGui — M key binding disabled")
	return
end

local PhoneAPI = require(Phone2Module)()

local ACTION_NAME = "Minimap_ToggleMap"

ContextActionService:BindAction(ACTION_NAME, function(_actionName, inputState, _inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	-- If the phone is open and the Map app is active, close the phone
	if PhoneAPI:GetState() and peek(PhoneAPI:GetInternalAppContext()) == "Map" then
		PhoneAPI:Close()
	else
		-- Open the phone and navigate to the Map app
		if not PhoneAPI:GetState() then
			PhoneAPI:Open()
		end
		PhoneAPI:InvokeAppByName("Map")
	end

	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.M)
