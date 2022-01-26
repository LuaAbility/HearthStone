local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS019-abilityUse", "PlayerInteractEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS019-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS019-passiveCount") == nil then 
		player:setVariable("HS019-passiveCount", 0) 
		player:setVariable("HS019-cost", 0) 
		player:setVariable("HS019-requireCost", 5) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS019-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS019-passiveCount")
		if count >= 600 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS019-passiveCount", count)
	else 
		player:setVariable("HS019-passiveCount", 0)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS019-cost") >= LAPlayer:getVariable("HS019-requireCost") then
						LAPlayer:setVariable("HS019-cost", LAPlayer:getVariable("HS019-cost") - LAPlayer:getVariable("HS019-requireCost"))
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs19.useline", 1, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs19.usebgm", 2, 1)
						util.runLater(function() hit(LAPlayer) end, 40)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS019-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local cost = player:getVariable("HS019-cost")
	if cost == nil then player:setVariable("HS019-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS019-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS019-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end

function hit(player)
	local doAgain = false
	local players = util.getTableFromList(game.getPlayers())
	for i = 1, #players do
		if players[i]:getPlayer() ~= player:getPlayer() then
			players[i]:getPlayer():damage(4, player:getPlayer())
			players[i]:getPlayer():getWorld():playSound(players[i]:getPlayer():getLocation(), "hs19.hitsfx", 1, 1)
			if players[i]:getPlayer():isDead() then doAgain = true end
		end
	end
	
	if doAgain then util.runLater(function() hit(player) end, 20) end
end