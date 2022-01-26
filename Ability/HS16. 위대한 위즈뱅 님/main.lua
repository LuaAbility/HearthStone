local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS016-cancelGetItem", "EntityPickupItemEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS016-cancelGetItem" then cancelGetItem(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS016-passiveCount") == nil then 
		player:setVariable("HS016-passiveCount", 0)
		util.runLater(function() giveitem(player:getPlayer()) end, 200)
	end
end

function giveitem(player)
	local startItem = {
		newInstance("$.inventory.ItemStack", {material.DIAMOND_HELMET, 1}),
		newInstance("$.inventory.ItemStack", {material.IRON_CHESTPLATE, 1}),
		newInstance("$.inventory.ItemStack", {material.IRON_LEGGINGS, 1}),
		newInstance("$.inventory.ItemStack", {material.DIAMOND_BOOTS, 1}),
		newInstance("$.inventory.ItemStack", {material.IRON_INGOT, 64}),
		newInstance("$.inventory.ItemStack", {material.GOLD_INGOT, 64}),
		newInstance("$.inventory.ItemStack", {material.GOLDEN_CARROT, 64}),
		newInstance("$.inventory.ItemStack", {material.OAK_LOG, 64}),
		newInstance("$.inventory.ItemStack", {material.IRON_SHOVEL, 1}),
		newInstance("$.inventory.ItemStack", {material.IRON_PICKAXE, 1}),
		newInstance("$.inventory.ItemStack", {material.IRON_AXE, 1}),
		newInstance("$.inventory.ItemStack", {material.IRON_SWORD, 1})
	}
	player:playSound(player:getLocation(), "hs16.usebgm", 1, 1)
	player:playSound(player:getLocation(), "hs16.useline", 2, 1)
	player:getInventory():clear()
	player:getInventory():addItem(startItem)
	player:giveExpLevels(-9999999)
	player:giveExpLevels(300)
end

function cancelGetItem(LAPlayer, event, ability, id)
	if event:getEntity():getType():toString() == "PLAYER" then
		if game.checkCooldown(LAPlayer, game.getPlayer(event:getEntity()), ability, id) then
			event:setCancelled(true)
		end
	end
end