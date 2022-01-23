local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS002-abilityUse", "PlayerInteractEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS002-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS002-passiveCount") == nil then 
		player:setVariable("HS002-passiveCount", 0) 
		player:setVariable("HS002-cost", 0) 
		player:setVariable("HS002-requireCost", 3) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS002-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS002-passiveCount")
		if count >= 600 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS002-passiveCount", count)
	else 
		player:setVariable("HS002-passiveCount", 0)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS002-cost") >= LAPlayer:getVariable("HS002-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						local cost = LAPlayer:getVariable("HS002-cost")
						local players = util.getTableFromList(game.getPlayers())
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs2.useline", 2, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs2.usebgm", 2, 1)
						for i = 1, (cost * 3) do
							util.runLater(function() 
								local randomIndex = util.random(1, #players)
								while players[randomIndex] == LAPlayer do randomIndex = util.random(1, #players) end
								local ticks = players[randomIndex]:getPlayer():getMaximumNoDamageTicks()
								players[randomIndex]:getPlayer():setMaximumNoDamageTicks(0)
								players[randomIndex]:getPlayer():damage(2, event:getPlayer())
								players[randomIndex]:getPlayer():setMaximumNoDamageTicks(ticks)
								players[randomIndex]:getPlayer():getWorld():spawnParticle(import("$.Particle").REDSTONE, players[randomIndex]:getPlayer():getLocation():add(0,1,0), 300, 0.5, 1, 0.5, 0.05, newInstance("$.Particle$DustOptions", {import("$.Color").PURPLE, 1}))
								players[randomIndex]:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, players[randomIndex]:getPlayer():getLocation():add(0,1,0), 150, 0.2, 0.2, 0.2, 0.5)
								players[randomIndex]:getPlayer():getWorld():playSound(players[randomIndex]:getPlayer():getLocation(), "hs2.hitsfx", 0.5, 1)
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
	local cost = player:getVariable("HS002-cost")
	if cost == nil then player:setVariable("HS002-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS002-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS002-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end