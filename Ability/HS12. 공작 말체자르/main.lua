local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS012-abilityUse", "PlayerInteractEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS012-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS012-passiveCount") == nil then 
		player:setVariable("HS012-passiveCount", 0) 
		player:setVariable("HS012-cost", 0) 
		player:setVariable("HS012-requireCost", 5) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS012-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS012-passiveCount")
		if count >= 720 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS012-passiveCount", count)
	else 
		player:setVariable("HS012-passiveCount", 0)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS012-cost") >= LAPlayer:getVariable("HS012-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						LAPlayer:setVariable("HS012-cost", LAPlayer:getVariable("HS012-cost") - LAPlayer:getVariable("HS012-requireCost"))
						randomAbility(LAPlayer)
						
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs12.useline", 0.5, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs12.usebgm", 1, 1)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS012-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function randomAbility(player)
	local abilityList = util.getTableFromList(game.getAbilityList())
	local targetList = {}
	for i = 1, #abilityList do
		if string.find(abilityList[i].abilityID, "HIDDEN") == nil and (abilityList[i].abilityRank == "A" or abilityList[i].abilityRank == "S") then
			table.insert(targetList, abilityList[i].abilityID)
		end
	end
	
	local abilityIndex = 3
	if #targetList < 1 then return 0
	elseif #targetList < 3 then abilityIndex = #targetList end
	
	for i = 1, 100 do
		local randomIndex = util.random(1, #targetList)
		local temp = targetList[randomIndex]
		targetList[randomIndex] = targetList[1]
		targetList[1] = temp
	end
	
	for i = 1, abilityIndex do
		util.runLater(function() 
			game.addAbility(player, targetList[i]) 
			player:getPlayer():spawnParticle(particle.PORTAL, player:getPlayer():getLocation():add(0,1,0), 1000, 0.1, 0.1, 0.1, 0.9)
		end, (i * 25) - 20)
	end
	
	for i = 1, ((abilityIndex * 25) - 20) do
		util.runLater(function() 
			player:getPlayer():spawnParticle(particle.SMOKE_NORMAL, player:getPlayer():getLocation():add(0,1,0), 50, 0.5, 0.7, 0.5, 0.1) 
			player:getPlayer():spawnParticle(particle.REDSTONE, player:getPlayer():getLocation():add(0,1,0), 20, 0.5, 0.7, 0.5, 0.1, newInstance("$.Particle$DustOptions", {import("$.Color").PURPLE, 1})) 
		end, i)
	end
	
	util.runLater(function() 
		player:getPlayer():spawnParticle(particle.SMOKE_NORMAL, player:getPlayer():getLocation():add(0,1,0), 750, 0.5, 0.7, 0.5, 0.5) 
	end, ((abilityIndex + 1) * 25))
	
	util.runLater(function() game.removeAbilityAsID(player, "LA-HS-012") end, 2)
end

function addCost(player, ability)
	local cost = player:getVariable("HS012-cost")
	if cost == nil then player:setVariable("HS012-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS012-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS012-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end