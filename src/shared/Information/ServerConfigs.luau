local ServerConfig = {}

local places = {
	
	[17355769359] = { name = "PRISM RESEARCH CENTER", environment = "STAGING", branchName = "MANUFACTURING BUILD" }, -- Staging
	
	[18327835858] = { name = "PRISM RESEARCH CENTER", environment = "DEVELOPMENT", branchName = "ACTOR DEVELOPMENT" }, -- Actor Development
	
	[112083436165587] = { name = "PRISM RESEARCH CENTER", environment = "LIVE", branchName = nil }, -- Main
	
}

local defaultConfig = { name = "PRISM RESEARCH CENTER", environment = "DEVELOPMENT", branchName = "DEVELOPER BRANCH" }

function ServerConfig.get()
	return places[game.PlaceId] or defaultConfig
end

return ServerConfig