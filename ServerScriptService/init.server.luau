--[[
	Minimap Builder (Server)
	Clones every descendant of Workspace named "Road", "Grass", "Tree",
	"Sidewalk", "Roof", or "Wood" into a Folder stored in ReplicatedStorage
	so clients can use it inside a ViewportFrame without scanning Workspace.

	Also creates invisible marker Parts for CollectionService-tagged "MapLabel"
	instances so the client Map app can render location dots and navigation.

	Output: ReplicatedStorage.PhoneMinimap (Folder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

task.wait(5)

local CLONE_NAMES = { Road = true, Grass = true, Tree = true, Sidewalk = true, Roof = true, Wood = true, Rock = true }

local minimapFolder = Instance.new("Folder")
minimapFolder.Name = "PhoneMinimap"

-- Walk every descendant. When we find a match, clone it and skip
-- any descendants that are children of something already cloned.
local clonedSet: { [Instance]: boolean } = {}

for _, descendant in Workspace:GetDescendants() do
	if CLONE_NAMES[descendant.Name] then
		-- Check if an ancestor was already cloned (avoids duplicates)
		local alreadyCovered = false
		local ancestor = descendant.Parent
		while ancestor ~= nil and ancestor ~= Workspace do
			if clonedSet[ancestor] then
				alreadyCovered = true
				break
			end
			ancestor = ancestor.Parent
		end

		if not alreadyCovered then
			local ok, clone = pcall(function()
				return descendant:Clone()
			end)
			if ok and clone then
				-- Anchor parts, strip non-visual objects
				if clone:IsA("BasePart") then
					clone.Anchored = true
				end
				for _, child in clone:GetDescendants() do
					if child:IsA("BasePart") then
						child.Anchored = true
					end
					if child:IsA("BaseScript") or child:IsA("Sound")
						or child:IsA("ParticleEmitter") or child:IsA("Fire")
						or child:IsA("Smoke") or child:IsA("Sparkles") then
						child:Destroy()
					end
				end
				clone.Parent = minimapFolder
				clonedSet[descendant] = true
			end
		end
	end
end

-- Also create marker parts for MapLabel-tagged instances (Part OR Model)
local mapLabelCount = 0
for _, inst in CollectionService:GetTagged("MapLabel") do
	local pos: Vector3
	if inst:IsA("BasePart") then
		pos = inst.Position
	elseif inst:IsA("Model") then
		pos = inst:GetPivot().Position
	else
		continue
	end

	local labelText = inst:GetAttribute("Label")
	if not labelText or labelText == "" then
		labelText = inst.Name
	end

	local marker = Instance.new("Part")
	marker.Name = "MapLabel_" .. tostring(labelText)
	marker.Position = pos
	marker.Size = Vector3.new(0.1, 0.1, 0.1)
	marker.Transparency = 1
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker:SetAttribute("Label", labelText)

	-- Copy floor and stairs attributes so the client can route vertically
	local floor = inst:GetAttribute("Floor")
	if floor ~= nil then
		marker:SetAttribute("Floor", floor)
	end

	-- Stairs detection: explicit boolean attribute OR label text contains "stair"
	local isStairs = inst:GetAttribute("Stairs")
	if not isStairs and string.find(string.lower(tostring(labelText)), "stair") then
		isStairs = true
	end
	if isStairs then
		marker:SetAttribute("Stairs", true)
	end

	marker.Parent = minimapFolder
	mapLabelCount += 1
end

minimapFolder.Parent = ReplicatedStorage
print("[Minimap] PhoneMinimap built —", #minimapFolder:GetChildren(), "top-level objects,", mapLabelCount, "MapLabel markers")
