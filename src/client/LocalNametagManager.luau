local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)

local localPlayer = Players.LocalPlayer

local Permissions = {
	
	{ "Team:AA" }, -- AA
	{ "Team:LD" }, -- Lore
	
	{"Group:AA:125-255"}, -- Acting Instructor+
	{"Group:LD:125-255"}, -- Lore Instructor+
	
	{ "Group:CSO:50-255" }, -- Safety Officer+
	{ "Group:MAD:50-255" }, -- Development Coordinator+
	
	{ "Group:SCPF:250-255" }, -- Board of Directors+
}

local function hasAccess()
	return IsAuthorized(localPlayer, Permissions) == true
end

local function updateNametag(player)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local nametag = head:FindFirstChild("Nametag")
	if not nametag then
		return
	end

	local visible = hasAccess()
	nametag.Enabled = visible

	local extraLabel = nametag:FindFirstChild("ExtraLabel")
	if extraLabel then
		extraLabel.Visible = visible
	end

	for _, label in nametag:GetDescendants() do
		if label:IsA("TextLabel") then
			label.TextTransparency = visible and 0.3 or 0
		end
	end
end

local function refreshAllNametags()
	for _, player in Players:GetPlayers() do
		updateNametag(player)
	end
end

-- New players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateNametag(player)
	end)
end)

-- Existing players
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateNametag(player)
	end)
end

-- Update when YOUR access changes
localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	refreshAllNametags()
end)

-- Manual refresh
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.J then
		refreshAllNametags()
	end
end)

-- Initial load
task.wait(1)
refreshAllNametags()