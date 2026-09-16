local MarketplaceService = game:GetService("MarketplaceService")

return function(player, gamepassIdStr)
	local id = tonumber(gamepassIdStr)
	if not id then return false end
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
	return ok and owns
end