local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DivisionData = require(ReplicatedStorage.Information.DivisionInfo)
local TeamPrefixes = require(ReplicatedStorage.Information.Teams)
local CustomNames = require(ReplicatedStorage.Information.UsernameInfo)
local Groups = require(ReplicatedStorage.Information.Groups)
local IsAuthorized = require(ReplicatedStorage.Common.IsAuthorized)

local DivisionsFolder = ReplicatedStorage.Information.Divisions

local nametagTemplate = ServerStorage:FindFirstChild("Nametag")
if not nametagTemplate then
	warn("Nametag template not found in ServerStorage")
	return
end

--  Color helpers 

local function lightenColor(color, factor)
	local r = math.clamp(color.R + (1 - color.R) * factor, 0, 1)
	local g = math.clamp(color.G + (1 - color.G) * factor, 0, 1)
	local b = math.clamp(color.B + (1 - color.B) * factor, 0, 1)
	return Color3.new(r, g, b)
end

local function color3ToHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function setPrefixRankLabel(textLabel, prefix, prefixColor, rank, rankColor)
	textLabel.Text = string.format("<font color='%s'>%s</font> <font color='%s'>%s</font>", prefixColor, prefix, rankColor, rank)
	textLabel.TextColor3 = Color3.new(1, 1, 1) -- white so the rich text colors above actually show
end

-- CD numbers 

local playerNumbers = {}
Players.PlayerAdded:Connect(function(player)
	playerNumbers[player] = math.random(10000, 99999)
end)

-- group lookup

local function safeRank(player, groupId)
	if not groupId then
		return 0
	end
	local ok, rank = pcall(function()
		return player:GetRankInGroupAsync(groupId)
	end)
	if not ok then
		warn(("NametagManager: GetRankInGroupAsync(%s) failed for %s: %s"):format(tostring(groupId), player.Name, tostring(rank)))
		return 0
	end
	return rank
end

local function safeRole(player, groupId)
	if not groupId then
		return ""
	end
	local ok, role = pcall(function()
		return player:GetRoleInGroupAsync(groupId)
	end)
	if not ok then
		warn(("NametagManager: GetRoleInGroupAsync(%s) failed for %s: %s"):format(tostring(groupId), player.Name, tostring(role)))
		return ""
	end
	return role
end

-- dev checks

local function checkDeveloper(player)
	return IsAuthorized(player, { { "Developer", "SeniorDeveloper", "DevelopmentCommand" } }) == true
end

-- perm checks
local function getContainerPermissions(container)
	local permissionsScript = container and container:FindFirstChild("Permissions")
	if not permissionsScript then
		return nil
	end
	local ok, data = pcall(require, permissionsScript)
	if not ok then
		warn("NametagManager: failed to require Permissions under " .. container:GetFullName())
		return false
	end
	return data
end

-- fetch div perms 
local function getDivisionPermissions(teamName, divisionKey)
	local teamFolder = DivisionsFolder:FindFirstChild(teamName)
	local divModule = teamFolder and teamFolder:FindFirstChild(divisionKey)
	if not divModule then
		return false
	end
	local ok, data = pcall(require, divModule)
	if not ok or type(data) ~= "table" then
		warn("NametagManager: failed to require division module " .. divModule:GetFullName())
		return false
	end
	return data.Permissions -- nil if the division itself has no Permissions field
end

-- permissions stuff. nil is open to everyone, otherwise it runs thru isauth
local function isAuthorizedFor(player, permissionsData)
	if permissionsData == false then
		return false
	end
	if permissionsData == nil then
		return true
	end
	return IsAuthorized(player, permissionsData) == true
end

-- rank handling. devs get "Developer" tag if they have perms thru dev perks, otherwise it defaults to the group rank
local function resolveRoleText(player, rank, groupId)
	if rank > 0 then
		return safeRole(player, groupId)
	elseif checkDeveloper(player) then
		return "Developer"
	end
	return ""
end

local TeamConfig = {}

TeamConfig["Security Corps"] = {
	Group = "SC",
	divisions = {
		["SVSD"] = { Group = "SVSD", prefix = "SVSD", color = "#ab1a39", rankColor = "#E9C1C7" },
		["SVMS"] = { Group = "SVMS", prefix = "SVMS", color = "#ab1a39", rankColor = "#E9C1C7" },
		["Honor Guard"] = { Group = "HG",   prefix = "HG",   color = "#21264F", rankColor = "#C8CADB" },
		["Crisis Intervention Unit"] = { Group = "CIU",  prefix = "CIU",  color = "#173c82", rankColor = "#C5CEE0" },
		["Operational Support Services"] = { Group = "OSS",  prefix = "OSS",  color = "#6262b8", rankColor = "#D8D8ED" },
		["Military Police"] = { Group = "MP",   prefix = "MP",   color = "#A81414", rankColor = "#E9C1C1" },
	},
}

TeamConfig["Manufacturing Department"] = { Group = "MAD" }
TeamConfig["Anomaly Actors"] = { Group = "AA" }
TeamConfig["Lore Department"] = { Group = "LD" }
TeamConfig["Administrative Department"] = { Group = "AD" }
TeamConfig["Department of External Affairs"] = { Group = "DEA" }
TeamConfig["Accountability and Corrections Office"] = { Group = "ACO" }
TeamConfig["Community Safety Office"] = { Group = "CSO" }

TeamConfig["Foundation Personnel"] = {
	Group = "SCPF",
	defaultPrefix = "",
	divisions = {
		["Site Valora"] = { Group = "SV", prefix = "SV", color = "#ab1a39", rankColor = "#E9C1C7" },
	},
}

TeamConfig["Medicinal Department"] = { Group = "MD" }

TeamConfig["Scientific Department"] = {
	Group = "SCD",
	divisions = {
		["ScD Specialists"] = { Group = "SCD>SPEC", prefix = "ScD", color = "#5A5472", rankColor = "#D6D4E2" },
		["ScD"] = { Group = "SCD", prefix = "ScD" },
	},
}

TeamConfig["Engineering and Technical Services"] = {
	Group = "ETS",
	defaultPrefix = "ETS",
	divisions = {
		["SVRE"] = { Group = "SVRE", prefix = "SVRE", color = "#ab1a39", rankColor = "#E9C1C7" },
	},
}
TeamConfig["Anderson's Robotics"] = { 
	Group = "AR",
	divisions = {
		["Advanced Logic Division"] = { Group = "AR>ALD", prefix = "ALD", color = "#4e57a7", rankColor = "#D1D5E9" },
		["Corporate Security"] = { Group = "AR>CS", prefix = "CS" },
	}
	
}

TeamConfig["Global Occult Coalition"] = {
	Group = "GOC",
	divisions = {
		["PHYSICS Division"] = { Group = "PHYSICS", prefix = "PHYSICS", color = "#e06666", rankColor = "#F5C7C7" },
		["Broken Dagger"] = { Group = "BD", prefix = "BD", color = "#253a23", rankColor = "#C9CEC8" },
	},
}

-- function to handle 1BN by group ranks
local function resolve1stBattalion(player)
	local rank = safeRank(player, Groups["1BN"])
	local prefix, prefixColor, rankColor

	if rank >= 1 and rank <= 9 then
		prefix, prefixColor, rankColor = "EIC", "#8845A0", "#E1D1E7" -- Enlistment & Instruction Command
	elseif rank >= 10 and rank <= 19 then
		prefix, prefixColor, rankColor = "DAO", "#55A9E9", "#D5EAFA" -- Diplomatic Affairs Office
	elseif rank >= 20 and rank <= 29 then
		prefix, prefixColor, rankColor = "ISC", "#B6335A", "#EDCCD6" -- Internal Standards Commission
	else
		prefix, prefixColor, rankColor = "1BN", "#ffc03d", "#FFEFCE" -- Init. Director+
	end

	return prefix, prefixColor, resolveRoleText(player, rank, Groups["1BN"]), rankColor
end

TeamConfig["Mobile Task Forces"] = {
	Group = "MTFI",
	divisions = {
		["Omega-1"] = { Group = "O1",  prefix = "O-1",  color = "#35731b", rankColor = "#C9E3C1" },
		["Titan-1"] = { Group = "T1",  prefix = "T-1",  color = "#4e3d8a", rankColor = "#D3CFE2" },
		["Alpha-9"] = { Group = "A9",  prefix = "A-9",  color = "#a81f1f", rankColor = "#E9C7C7" },
		["Iota-10"] = { Group = "I10", prefix = "I-10", color = "#4c3d62", rankColor = "#D3CFDC" },
		["Epsilon-11"] = { Group = "E11", prefix = "E-11", color = "#d37033", rankColor = "#F4DBCC" },
		["Nu-7"] = { Group = "N7",  prefix = "N-7",  color = "#44506B", rankColor = "#D0D3DA" },
		["Alpha-1"] = { Group = "A1",  prefix = "A-1",  color = "#8D0505", rankColor = "#E3C1C1" },
		["Zeta-19"] = { Group = "Z19", prefix = "Z-19", color = "#0A0A0A", rankColor = "#C4C4C4" },
		["Tau-5"] = { Group = "T5",  prefix = "T-5",  color = "#11217C", rankColor = "#C4C8DE" },
		["Epsilon-9"] = { Group = "E9",  prefix = "E-9",  color = "#CA3D16", rankColor = "#F2CEC5" },
		["1st Battalion"] = { Group = "1BN", resolve = resolve1stBattalion },
	},
}

--  

-- rank handling, handles devs and all that fun stuff

local function applyTeamLabel(player, textLabel, teamColor, team)
	local teamName = team.Name
	local config = TeamConfig[teamName]
	if not config then
		return
	end

	local teamColorHex = color3ToHex(teamColor)
	local selectedDivision = DivisionData.GetPlayerDivision(player)

	if selectedDivision and selectedDivision ~= "None" and config.divisions then
		local divConfig = config.divisions[selectedDivision]
		if divConfig then
			local divisionPermissions = getDivisionPermissions(teamName, selectedDivision)
			if isAuthorizedFor(player, divisionPermissions) then
				local groupId = Groups[divConfig.Group]
				local rank = safeRank(player, groupId)

				if divConfig.resolve then
					local prefix, prefixColor, roleText, rankColor = divConfig.resolve(player)
					setPrefixRankLabel(textLabel, prefix, prefixColor, roleText, rankColor)
				else
					local prefixColor = divConfig.color or teamColorHex
					local rankColor = divConfig.rankColor or color3ToHex(lightenColor(teamColor, 0.75))
					local roleText = resolveRoleText(player, rank, groupId)
					setPrefixRankLabel(textLabel, divConfig.prefix, prefixColor, roleText, rankColor)
				end
				return
			end
			-- sets label to team default if div stuff is invalid/they arent authed
		end
		-- sets label to base team if selected division doesnt belong to the team
	end

	-- Default: team-wide Permissions + prefix.
	local teamPermissions = getContainerPermissions(team)
	if isAuthorizedFor(player, teamPermissions) then
		local defaultGroupId = Groups[config.Group]
		local rank = safeRank(player, defaultGroupId)
		local prefix = config.defaultPrefix or TeamPrefixes[teamName]
		local rankColor = (prefix == "") and teamColorHex or color3ToHex(lightenColor(teamColor, 0.75))
		local roleText = resolveRoleText(player, rank, defaultGroupId)
		setPrefixRankLabel(textLabel, prefix, teamColorHex, roleText, rankColor)
	end
end

--  Nametag application 

local function applyNametagToCharacter(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	local nametag = head:FindFirstChild("Nametag")
	if not nametag then
		nametag = nametagTemplate:Clone()
		nametag.Adornee = head
		nametag.Parent = head
	end

	local team = player.Team
	if not team then
		return
	end
	local teamName = team.Name
	local teamColor = player.TeamColor.Color
	local isClassD = team == game.Teams["Class-D"]

	-- Username / display name
	local usernameLabel = nametag:FindFirstChild("UsernameLabel")
	if usernameLabel then
		usernameLabel.Text = isClassD and player.Name or CustomNames.GetDisplayName(player)
	end

	-- Team + rank display
	local textLabel = nametag:FindFirstChild("TeamLabel")
	if textLabel then
		textLabel.Text = teamName
		textLabel.TextColor3 = teamColor

		if isClassD then
			textLabel.Text = "D-" .. tostring(playerNumbers[player])
		else
			applyTeamLabel(player, textLabel, teamColor, team)
		end
	end

	-- Anomaly extra label
	local extraLabel = nametag:FindFirstChild("ExtraLabel")
	if extraLabel and team == game.Teams["Anomaly Actors"] then
		local anomaly = player:GetAttribute("Anomaly")
		extraLabel.Text = (anomaly and anomaly ~= "None") and anomaly or ""
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(applyNametagToCharacter)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		if player.Character then
			applyNametagToCharacter(player.Character)
		end
	end)
	if player.Character then
		applyNametagToCharacter(player.Character)
	end
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)