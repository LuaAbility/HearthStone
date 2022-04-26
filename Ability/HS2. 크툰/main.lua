local particle = import("$.Particle")
local material = import("$.Material")
local types = import("$.entity.EntityType")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS002-abilityUse", "PlayerInteractEvent", 200)
end

function onEvent(funcTable)
	if funcTable[1] == "HS002-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end
-- 아자리 불덩이
function onTimer(player, ability)
	if player:getVariable("HS002-health") == nil then 
		player:setVariable("HS002-health", player:getPlayer():getHealth()) 
		player:setVariable("HS002-healthStack", 0) 
		player:setVariable("HS002-cost", 0) 
		player:setVariable("HS002-requireCost", 3) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS002-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), "HS002", str)
	
	if cost < 10 then
		if player:getVariable("HS002-health") < player:getPlayer():getHealth() then player:setVariable("HS002-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS002-health") - player:getPlayer():getHealth()) + player:getVariable("HS002-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
end

function Reset(player, ability)
	game.sendActionBarMessageToAll("HS002", "")
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS002-cost") >= LAPlayer:getVariable("HS002-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						local cost = LAPlayer:getVariable("HS002-cost")
						local players = util.getTableFromList(game.getTeamManager():getOpponentTeam(LAPlayer, false))
						for i = 1, #players do
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs2.useline", 1, 1)
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs2.usebgm", 1, 1)
						end
						
						for i = 1, (cost * 3) do
							util.runLater(function() 
								if #players < 2 then return 0 end
								local randomIndex = util.random(1, #players)
								while players[randomIndex] == LAPlayer do randomIndex = util.random(1, #players) end
								
								if game.targetPlayer(LAPlayer, players[randomIndex], false) then
									local armorStand = players[randomIndex]:getPlayer():getWorld():spawnEntity(players[randomIndex]:getPlayer():getEyeLocation():add(0, 2, 0), types.ARMOR_STAND)
									armorStand:setSmall(true)
									armorStand:setGravity(false)
									armorStand:setVisible(false)
									local result = armorStand:getLocation():toVector()
									for j = 0, 2 do
										util.runLater(function()
											local timeCount = j
											local tempResult = result:clone()
											local addVec = players[randomIndex]:getPlayer():getLocation():add(0, 0.5, 0):toVector():clone():subtract(tempResult:clone()):multiply(timeCount / 2)
											
											tempResult:add(addVec)
											armorStand:teleport(newInstance("$.Location", {armorStand:getWorld(), tempResult:getX(), tempResult:getY(), tempResult:getZ()}))
											
											armorStand:getWorld():spawnParticle(particle.REDSTONE, armorStand:getLocation(), 50, 0.15, 0.5, 0.15, 0.05, newInstance("$.Particle$DustOptions", { import("$.Color").PURPLE, 1 }))
											armorStand:getWorld():spawnParticle(particle.SMOKE_NORMAL, armorStand:getLocation(), 50, 0.2, 0.5, 0.2, 0.05)
										end, j)
									end
									
									util.runLater(function() 
										local ticks = players[randomIndex]:getPlayer():getMaximumNoDamageTicks()
										players[randomIndex]:getPlayer():getWorld():spawnParticle(particle.REDSTONE, players[randomIndex]:getPlayer():getLocation():add(0, 1, 0), 150, 0.3, 0.5, 0.3, 0.2, newInstance("$.Particle$DustOptions", { import("$.Color").PURPLE, 1 }))
										players[randomIndex]:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, players[randomIndex]:getPlayer():getLocation():add(0, 1, 0), 100, 0.3, 0.5, 0.3, 0.2)
										players[randomIndex]:getPlayer():setMaximumNoDamageTicks(0)
										players[randomIndex]:getPlayer():damage(2, event:getPlayer())
										players[randomIndex]:getPlayer():setMaximumNoDamageTicks(ticks)
										players[randomIndex]:getPlayer():getWorld():playSound(players[randomIndex]:getPlayer():getLocation(), "hs2.hitsfx", 0.5, 1)
									end, 4)
								end
							end, (i - 1) * 5)
						end
						
						LAPlayer:setVariable("HS002-cost", 0)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS002-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS002-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS002-health") - player:getPlayer():getHealth()) + player:getVariable("HS002-healthStack")
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
		
		if cost < 10 then player:setVariable("HS002-healthStack", healthAmount)
		else player:setVariable("HS002-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS002-health", player:getPlayer():getHealth())
			player:setVariable("HS002-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end