-------------------------------------------------
-- variables
-------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)

local player = Players.LocalPlayer

local Permissions = {
	{ "Team:AA" }, -- AA
	{ "Team:LD" }, -- Lore
	{ "Group:AA:125-255" }, -- Acting Instructor+
	{ "Group:LD:125-255" }, -- Lore Instructor+
	{ "Group:CSO:50-255" }, -- Safety Officer+
	{ "Group:MAD:50-255" }, -- Development Coordinator+
	{ "Group:SCPF:250-255" }, -- Board of Directors+
}

local Blacklist = {
	["Security Corps"] = true,
	["Anderson's Robotics"] = true,
	["Global Occult Coalition"] = true,
	["Mobile Task Forces"] = true,
	["Class-D"] = true,
	["Pending"] = true,
}

local ccopen = false

-------------------------------------------------
-- checks
-------------------------------------------------

local function hasAccess()
	return IsAuthorized(player, Permissions) == true
end

local function updateAuth()
	local teamName = player.Team and player.Team.Name or ""
	local auth = hasAccess() and not Blacklist[teamName]

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, auth)

	if ccopen and not auth then
		ChatService.ChatWindowConfiguration.Enabled = false
		ccopen = false
	end
end

-- Initial auth
updateAuth()

-- Update on team change
player:GetPropertyChangedSignal("Team"):Connect(updateAuth)

-------------------------------------------------
-- toggle chatbox
-------------------------------------------------

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.LeftBracket then
		return
	end
	local teamName = player.Team and player.Team.Name or ""
	if not hasAccess() or Blacklist[teamName] then
		return
	end
	ccopen = not ccopen
	ChatService.ChatWindowConfiguration.Enabled = ccopen
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)