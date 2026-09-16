local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)
local DivisionsFolder = ReplicatedStorage.Information.Divisions
local DivisionData = require(ReplicatedStorage.Information.DivisionInfo)

-- Create RemoteEvent if it doesn't exist
local DivisionRemote = ReplicatedStorage:FindFirstChild("DivisionRemote")
if not DivisionRemote then
	DivisionRemote = Instance.new("RemoteEvent")
	DivisionRemote.Name = "DivisionRemote"
	DivisionRemote.Parent = ReplicatedStorage
end

-- Extra checks
local function canSelectDivision(player, divisionKey)
	if divisionKey == "None" then
		return true
	end

	local team = player.Team
	if not team then
		return false
	end

	local teamFolder = DivisionsFolder:FindFirstChild(team.Name)
	if not teamFolder then
		return false
	end

	local divModule = teamFolder:FindFirstChild(divisionKey)
	if not divModule then
		return false
	end

	local success, data = pcall(require, divModule)
	if not success or type(data) ~= "table" then
		warn("DivisionManager: failed to require division module " .. divModule:GetFullName())
		return false
	end

	if not data.Permissions then
		return true
	end

	return IsAuthorized(player, data.Permissions) == true
end

-- Handle RemoteEvent
DivisionRemote.OnServerEvent:Connect(function(player, action, divisionKey)
	if action ~= "SelectDivision" then
		return
	end
	if type(divisionKey) ~= "string" then
		return
	end

	if not canSelectDivision(player, divisionKey) then
		return -- player doesn't meet the requirements for this division
	end

	DivisionData.SetPlayerDivision(player, divisionKey)
	player:LoadCharacterAsync()
end)