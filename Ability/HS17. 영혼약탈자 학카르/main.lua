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
	if player:getVariable("HS017-health") == nil then 
		player:setVariable("HS017-health", player:getPlayer():getHealth()) 
		player:setVariable("HS017-healthStack", 0) 
		player:setVariable("HS017-cost", 0) 
		player:setVariable("HS017-requireCost", 8) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS017-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS017-health") < player:getPlayer():getHealth() then player:setVariable("HS017-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS017-health") - player:getPlayer():getHealth()) + player:getVariable("HS017-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getDamager():getType():toString() == "PLAYER" and event:getEntity():getType():toString() == "PLAYER" then
		local item = event:getDamager():getInventory():getItemInMainHand()
		if game.isAbilityItem(item, "IRON_INGOT") then
			if game.checkCooldown(LAPlayer, game.getPlayer(event:getDamager()), ability, id) then
				if LAPlayer:getVariable("HS017-cost") >= LAPlayer:getVariable("HS017-requireCost") then
					game.sendMessage(event:getDamager(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
					LAPlayer:setVariable("HS017-cost", LAPlayer:getVariable("HS017-cost") - LAPlayer:getVariable("HS017-requireCost"))
					event:getDamager():getWorld():spawnParticle(particle.SMOKE_NORMAL, event:getDamager():getLocation():add(0,1,0), 100, 0.3, 0.5, 0.3, 0.1)
					event:getDamager():getWorld():playSound(event:getDamager():getLocation(), "hs17.useline", 0.5, 1)
					event:getDamager():getWorld():playSound(event:getDamager():getLocation(), "hs17.usebgm", 1, 1)
					util.runLater(function() 
						event:getEntity():getWorld():spawnParticle(particle.REDSTONE, event:getEntity():getLocation():add(0,1,0), 50, 0.2, 0.7, 0.2, 0.9, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(139, 0, 0), 1.0 }))
						event:getEntity():getWorld():spawnParticle(particle.ITEM_CRACK, event:getEntity():getLocation():add(0,1,0), 50, 0.2, 0.7, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").COAL_BLOCK}))
						event:getEntity():getWorld():spawnParticle(particle.ITEM_CRACK, event:getEntity():getLocation():add(0,1,0), 50, 0.2, 0.7, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").REDSTONE_BLOCK}))
						game.addAbility(game.getPlayer(event:getEntity()), "LA-HS-017-HIDDEN") 
					end, 1)
					game.sendMessage(event:getEntity(), "§4오염된 피§c에 감염되었습니다.")
				else
					game.sendMessage(event:getDamager(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS017-requireCost") .. "개)")
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS017-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS017-health") - player:getPlayer():getHealth()) + player:getVariable("HS017-healthStack")
		while cost <= 10 do
			if cost <= 6 then
				if (healthAmount - 2 >= 0) then
					cost = cost + 1
					healthAmount = healthAmount - 2
				else break end
			else
				if (healthAmount - 4 >= 0) then
					cost = cost + 1
					healthAmount = healthAmount - 4
				else break end
			end
		end
		
		if cost < 10 then player:setVariable("HS017-healthStack", healthAmount)
		else player:setVariable("HS017-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS017-health", player:getPlayer():getHealth())
			player:setVariable("HS017-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end