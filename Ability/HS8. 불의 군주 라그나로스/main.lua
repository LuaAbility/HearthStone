local particle = import("$.Particle")
local material = import("$.Material")
local types = import("$.entity.EntityType")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS008-abilityUse", "PlayerInteractEvent", 100)
	plugin.registerEvent(abilityData, "HS008-cancelAttack", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS008-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS008-cancelAttack" and funcTable[2]:getEventName() == "EntityDamageByEntityEvent" then cancelAttack(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS008-health") == nil then 
		player:setVariable("HS008-health", player:getPlayer():getHealth()) 
		player:setVariable("HS008-healthStack", 0) 
		player:setVariable("HS008-cost", 0) 
		player:setVariable("HS008-requireCost", 4) 
		player:setVariable("HS008-canAttack", false)
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS008-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS008-health") < player:getPlayer():getHealth() then player:setVariable("HS008-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS008-health") - player:getPlayer():getHealth()) + player:getVariable("HS008-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS008-cost") >= LAPlayer:getVariable("HS008-requireCost") then
						local players = util.getTableFromList(game.getTeamManager():getOpponentTeam(LAPlayer, false))
						local abilityCount = 0
						for i = 1, #players do
							if event:getPlayer() ~= players[i]:getPlayer() then
								if event:getPlayer():getWorld():getEnvironment() == players[i]:getPlayer():getPlayer():getWorld():getEnvironment() and 
									(event:getPlayer():getLocation():distance(players[i]:getPlayer():getLocation()) <= 8) and game.targetPlayer(LAPlayer, players[i], false) then
									util.runLater(function()
										local armorStand = event:getPlayer():getWorld():spawnEntity(event:getPlayer():getEyeLocation():add(0, 4, 0), types.ARMOR_STAND)
										armorStand:setSmall(true)
										armorStand:setGravity(false)
										armorStand:setVisible(false)
										
										game.sendMessage(players[i]:getPlayer(), "§c죽어라, 벌레같은 놈들!")
										
										local result = armorStand:getLocation():toVector()
										for j = 0, 30 do
											util.runLater(function()
												local timeCount = j
												local tempResult = result:clone()
												local addVec = players[i]:getPlayer():getEyeLocation():toVector():clone():subtract(tempResult:clone()):multiply(timeCount / 20)
												
												tempResult:add(addVec)
												armorStand:teleport(newInstance("$.Location", {armorStand:getWorld(), tempResult:getX(), tempResult:getY(), tempResult:getZ()}))
												
												armorStand:getWorld():spawnParticle(particle.LAVA, armorStand:getLocation(), 10, 0.2, 0.2, 0.2, 0.05)
												armorStand:getWorld():spawnParticle(particle.SMOKE_NORMAL, armorStand:getLocation(), 20, 0.2, 0.2, 0.2, 0.05)
												armorStand:getWorld():spawnParticle(particle.FLAME, armorStand:getLocation(), 5, 0.2, 0.2, 0.2, 0.05)
											end, j)
										end
										
										util.runLater(function() 
											LAPlayer:setVariable("HS008-canAttack", true)
											players[i]:getPlayer():damage(8, LAPlayer:getPlayer())
											util.runLater(function() LAPlayer:setVariable("HS008-canAttack", false) end, 1)
											players[i]:getPlayer():setFireTicks(200)
											players[i]:getPlayer():getWorld():playSound(players[i]:getPlayer():getLocation(), "hs8.hitsfx", 1, 1)
											players[i]:getPlayer():getWorld():spawnParticle(particle.FLAME, players[i]:getPlayer():getLocation(), 200, 0.2, 0.2, 0.2, 0.8)
											players[i]:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, players[i]:getPlayer():getLocation(), 200, 0.2, 0.2, 0.2, 0.8)
											armorStand:remove()
										end, 21)
									end, abilityCount)
									
									abilityCount = abilityCount + 6
								end
							end
						end
						
						if abilityCount == 0 then 
							game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c타겟할 플레이어가 없습니다.")
						else 
							event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs8.useline", 0.5, 1)
							event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs8.usebgm", 1, 1)
							event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs8.usesfx", 0.5, 1)
							game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
							LAPlayer:setVariable("HS008-cost", LAPlayer:getVariable("HS008-cost") - LAPlayer:getVariable("HS008-requireCost"))
						end
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS008-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function cancelAttack(LAPlayer, event, ability, id)
	local damager = event:getDamager()
	if event:getCause():toString() == "PROJECTILE" then damager = event:getDamager():getShooter() end
	
	if not util.hasClass(damager, "org.bukkit.projectiles.BlockProjectileSource") and damager:getType():toString() == "PLAYER" then
		if game.checkCooldown(LAPlayer, game.getPlayer(damager), ability, id) then
			if not LAPlayer:getVariable("HS008-canAttack") then
				event:setCancelled(true)
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS008-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS008-health") - player:getPlayer():getHealth()) + player:getVariable("HS008-healthStack")
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
		
		if cost < 10 then player:setVariable("HS008-healthStack", healthAmount)
		else player:setVariable("HS008-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS008-health", player:getPlayer():getHealth())
			player:setVariable("HS008-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end