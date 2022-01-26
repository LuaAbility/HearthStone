local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS017-abilityUse", "EntityDamageEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS017-abilityUse" and funcTable[2]:getEventName() == "EntityDamageByEntityEvent" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS017-passiveCount") == nil then 
		player:setVariable("HS017-passiveCount", 0) 
		player:setVariable("HS017-cost", 0) 
		player:setVariable("HS017-requireCost", 10) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS017-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS017-passiveCount")
		if count >= 600 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS017-passiveCount", count)
	else 
		player:setVariable("HS017-passiveCount", 0)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getDamager():getType():toString() == "PLAYER" and event:getEntity():getType():toString() == "PLAYER" then
		local item = event:getDamager():getInventory():getItemInMainHand()
		if game.isAbilityItem(item, "IRON_INGOT") then
			if game.checkCooldown(LAPlayer, game.getPlayer(event:getDamager()), ability, id) then
				if LAPlayer:getVariable("HS017-cost") >= LAPlayer:getVariable("HS017-requireCost") then
					game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
					LAPlayer:setVariable("HS017-cost", LAPlayer:getVariable("HS017-cost") - LAPlayer:getVariable("HS017-requireCost"))
					event:getDamager():getWorld():playSound(event:getDamager():getLocation(), "hs17.useline", 1, 1)
					event:getDamager():getWorld():playSound(event:getDamager():getLocation(), "hs17.usebgm", 2, 1)
					util.runLater(function() game.addAbility(game.getPlayer(event:getEntity()), "LA-HS-017-HIDDEN") end, 1)
					game.sendMessage(event:getEntity(), "§4오염된 피§c에 감염되었습니다.")
				else
					game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS017-requireCost") .. "개)")
				end
			end
		end
	end
end

function addCost(player, ability)
	local cost = player:getVariable("HS017-cost")
	if cost == nil then player:setVariable("HS017-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS017-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS017-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end