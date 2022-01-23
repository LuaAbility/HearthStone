local particle = import("$.Particle")
local material = import("$.Material")
local gameMode = import("$.GameMode")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS004-abilityUse", "PlayerInteractEvent", 100)
	plugin.registerEvent(abilityData, "HS004-cancelDamage", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS004-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS004-cancelDamage" and funcTable[2]:getEventName() == "EntityDamageByEntityEvent" then cancelDamage(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS004-passiveCount") == nil then 
		player:setVariable("HS004-passiveCount", 0) 
		player:setVariable("HS004-cost", 0) 
		player:setVariable("HS004-requireCost", 10) 
		player:setVariable("HS004-abilityTime", 0) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS004-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS004-passiveCount")
		if count >= 600 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS004-passiveCount", count)
	else 
		player:setVariable("HS004-passiveCount", 0)
	end
	
	local timeCount = player:getVariable("HS004-abilityTime")
	if timeCount > 0 then
		timeCount = timeCount - 2
		if timeCount <= 0 then ResetPlayer(player, ability) end
		player:setVariable("HS004-abilityTime", timeCount)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS004-cost") >= LAPlayer:getVariable("HS004-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						LAPlayer:setVariable("HS004-cost", LAPlayer:getVariable("HS004-cost") - LAPlayer:getVariable("HS004-requireCost"))
						
						if LAPlayer:getVariable("HS004-abilityTime") <= 0 then
							local players = util.getTableFromList(game.getAllPlayers())
							for i = 1, #players do
								if not players[i].isSurvive then 
									players[i]:getPlayer():getInventory():setHelmet(newInstance("$.inventory.ItemStack", { material.IRON_HELMET }))
									players[i]:getPlayer():getInventory():setChestplate(newInstance("$.inventory.ItemStack", { material.IRON_CHESTPLATE }))
									players[i]:getPlayer():getInventory():setLeggings(newInstance("$.inventory.ItemStack", { material.IRON_LEGGINGS }))
									players[i]:getPlayer():getInventory():setBoots(newInstance("$.inventory.ItemStack", { material.IRON_BOOTS }))
									players[i]:getPlayer():getInventory():setItemInMainHand(newInstance("$.inventory.ItemStack", { material.IRON_SWORD }))
									players[i]:getPlayer():getInventory():setItemInOffHand(newInstance("$.inventory.ItemStack", { material.SHIELD }))
									players[i]:getPlayer():teleport(event:getPlayer():getLocation():add(0,3,0))
									players[i]:getPlayer():setGameMode(event:getPlayer():getGameMode())
									players[i]:setVariable("HS004-cantDamage", LAPlayer)
									game.sendMessage(players[i]:getPlayer(), "§8느조스 §7능력을 보유한 §8" .. event:getPlayer():getName() .. "§7님에 의해 30초 간 부활합니다.")
									game.sendMessage(players[i]:getPlayer(), "§8" .. event:getPlayer():getName() .. "§7님은 공격할 수 없습니다.")
								end
							end
						end
						
						game.broadcastMessage("§7죽은 자들이 돌아왔습니다.")
						event:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, event:getPlayer():getLocation():add(0,1,0), 300, 0.2, 0.2, 0.2, 0.75)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs4.useline", 2, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs4.usebgm", 2, 1)
						LAPlayer:setVariable("HS004-abilityTime", 600)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS004-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function cancelDamage(LAPlayer, event, ability, id)
	if event:getDamager():getType():toString() == "PLAYER" and event:getEntity():getType():toString() == "PLAYER" then
		if game.getPlayer(event:getEntity()) == game.getPlayer(event:getDamager()):getVariable("HS004-cantDamage") then
			if game.checkCooldown(LAPlayer, game.getPlayer(event:getEntity()), ability, id) then
				event:setCancelled(true)
			end
		end
	end
end

function ResetPlayer(player, ability)
	local players = util.getTableFromList(game.getAllPlayers())
	for i = 1, #players do
		if not players[i].isSurvive then 
			players[i]:getPlayer():getInventory():clear()
			players[i]:getPlayer():setGameMode(gameMode.SPECTATOR)
			players[i]:removeVariable("HS004-cantDamage")
			players[i]:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, players[i]:getPlayer():getLocation():add(0,1,0), 500, 0.5, 0.7, 0.5, 0.05)
			players[i]:getPlayer():getWorld():playSound(players[i]:getPlayer():getLocation(), "hs1.endbgm", 2, 1)
		end
	end
	
	game.broadcastMessage("§7죽은 자들이 다시 저승으로 돌아갑니다.")
	game.sendMessage(player:getPlayer(), "§2[§a" .. ability.abilityName .. "§2] §a능력 시전 시간이 종료되었습니다.")
end

function Reset(player, ability)
	if player:getVariable("HS004-abilityTime") > 0 then ResetPlayer(player, ability) end
end

function addCost(player, ability)
	local cost = player:getVariable("HS004-cost")
	if cost == nil then player:setVariable("HS004-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS004-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS004-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end