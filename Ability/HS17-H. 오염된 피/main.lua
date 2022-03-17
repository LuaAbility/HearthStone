local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS017-abilityUse", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS017-abilityUse" and funcTable[2]:getEventName() == "EntityDamageByEntityEvent" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	
end

function onTimer(player, ability)
	if player:getVariable("HS017-blood") == nil then 
		player:setVariable("HS017-blood", 0) 
	end
	
	local count = player:getVariable("HS017-blood")
	if count >= 200 then 
		count = 0
		damage(player:getPlayer())
	end
	count = count + 1
	player:setVariable("HS017-blood", count)
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getDamager():getType():toString() == "PLAYER" and event:getEntity():getType():toString() == "PLAYER" and util.random() <= 0.2 then
		if game.checkCooldown(LAPlayer, game.getPlayer(event:getDamager()), ability, id) then
			if game.targetPlayer(LAPlayer, game.getPlayer(event:getEntity()), false) then
				event:getEntity():getWorld():playSound(event:getDamager():getLocation(), "hs17.hitsfx", 1, 1)
				event:getDamager():getWorld():spawnParticle(particle.SMOKE_NORMAL, event:getDamager():getLocation():add(0,1,0), 100, 0.3, 0.5, 0.3, 0.1)
				util.runLater(function() 
					event:getEntity():getWorld():spawnParticle(particle.REDSTONE, event:getEntity():getLocation():add(0,1,0), 50, 0.2, 0.7, 0.2, 0.9, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(139, 0, 0), 1.0 }))
					event:getEntity():getWorld():spawnParticle(particle.ITEM_CRACK, event:getEntity():getLocation():add(0,1,0), 50, 0.2, 0.7, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").COAL_BLOCK}))
					event:getEntity():getWorld():spawnParticle(particle.ITEM_CRACK, event:getEntity():getLocation():add(0,1,0), 50, 0.2, 0.7, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").REDSTONE_BLOCK}))
					
					local ablist = util.getTableFromList(game.getPlayer(event:getEntity()):getAbility())
					local count = 0
					for i = 1,  #ablist do
						if (ablist[i].abilityID == "LA-HS-017-HIDDEN") then count = count + 1 end
					end
					
					if (count < 5) then 
						game.addAbility(game.getPlayer(event:getEntity()), "LA-HS-017-HIDDEN") 
						game.sendMessage(event:getEntity(), "§4오염된 피§c에 감염되었습니다! 주기적으로 데미지를 입습니다.")
						game.sendMessage(event:getEntity(), "§4오염된 피§c를 다른 사람에게 전염 시킬 수 있습니다.")
						game.sendMessage(event:getDamager(), "§4오염된 피§c를 감염시켰습니다.")
					end
				end, 5)
			end
		end
	end
end

function damage(player)
	player:getWorld():playSound(player:getLocation(), "hs17.hitsfx", 1, 1)
	util.runLater(function() 
		player:getWorld():spawnParticle(particle.REDSTONE, player:getLocation():add(0,0.5,0), 20, 0.2, 0.7, 0.2, 0.9, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(139, 0, 0), 1.0 }))
		player:getWorld():spawnParticle(particle.ITEM_CRACK, player:getLocation():add(0,0.5,0), 20, 0.2, 0.7, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").COAL_BLOCK}))
		player:getWorld():spawnParticle(particle.ITEM_CRACK, player:getLocation():add(0,0.5,0), 20, 0.2, 0.7, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").REDSTONE_BLOCK}))
		player:damage(2) 
	end, 5)
end