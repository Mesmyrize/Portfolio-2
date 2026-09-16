local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DivisionData = require(ReplicatedStorage.Information.DivisionInfo)

local CustomNames = {}

local function getPlayerDivision(player)
	return DivisionData.GetPlayerDivision(player)
end

local function hasOverride(container, key)
	return container ~= nil and container[key] ~= nil
end

-- division-wide overrides
CustomNames.GeneralDivisionNames = {
	
}

CustomNames.Names = {
	
	[859791892] = { -- Mesmyrize
		["Mobile Task Forces"] = "Commissioner Venusch",	
		["Anderson's Robotics"] = "Emissary Chambers",
		
		["Global Occult Coalition"] = "Secretary ",
		
		divisions = {
			["Mobile Task Forces"] = {
				["Alpha-1"] = "",
			},
		},
		default = "O5-9",
	},
	
}

function CustomNames.GetDisplayName(player)
	local userEntry = CustomNames.Names[player.UserId] -- may be nil; every tier below guards for that
	local teamName = player.Team and player.Team.Name or ""
	local division = getPlayerDivision(player)
	local hasDivision = division and division ~= "None"

	-- divisions override
	if userEntry and hasDivision then
		local teamDivisions = userEntry.divisions and userEntry.divisions[teamName]
		if teamDivisions and hasOverride(teamDivisions, division) then
			return teamDivisions[division]
		end
	end

	-- division-wide names (i.e. SVSD getting blank names)
	if hasDivision then
		local generalTeamDivisions = CustomNames.GeneralDivisionNames[teamName]
		if generalTeamDivisions and hasOverride(generalTeamDivisions, division) then
			return generalTeamDivisions[division]
		end
	end

	-- team-specific names (i.e. Commissioner Winters rather than Dr. Winters)
	if userEntry and hasOverride(userEntry, teamName) then
		return userEntry[teamName]
	end

	-- defaults
	if userEntry and hasOverride(userEntry, "default") then
		return userEntry.default
	end

	-- return normal name if they dont have any customs
	return player.Name
end

return CustomNames