local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS006-abilityUse", "PlayerInteractEvent", 700)
	plugin.registerEvent(abilityData, "HS006-cancelAbility", "PlayerDeathEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS006-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "HS006-cancelAbility" then cancelAbility(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS006-passiveCount") == nil then 
		player:setVariable("HS006-passiveCount", 0) 
		player:setVariable("HS006-cost", 0) 
		player:setVariable("HS006-requireCost", 6) 
		player:setVariable("HS006-abilityTime", 0) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS006-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS006-passiveCount")
		if count >= 1000 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS006-passiveCount", count)
	else 
		player:setVariable("HS006-passiveCount", 0)
	end
	
	local timeCount = player:getVariable("HS006-abilityTime")
	if timeCount > 0 then
		timeCount = timeCount - 2
		if timeCount <= 0 then Apocalypse(player) end
		if timeCount % 20 == 0 then effect(player, timeCount) end
		player:setVariable("HS006-abilityTime", timeCount)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS006-cost") >= LAPlayer:getVariable("HS006-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						LAPlayer:setVariable("HS006-cost", LAPlayer:getVariable("HS006-cost") - LAPlayer:getVariable("HS006-requireCost"))
						LAPlayer:setVariable("HS006-abilityTime", 1200)
						
						
						local players = util.getTableFromList(game.getPlayers())
						for i = 1, #players do
							if event:getPlayer():getWorld():getEnvironment() == players[i]:getPlayer():getPlayer():getWorld():getEnvironment() and 
								(event:getPlayer():getLocation():distance(players[i]:getPlayer():getLocation()) <= 100) then
								players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs6.useline", 1, 1)
								game.sendMessage(players[i]:getPlayer(), "§4[§c" .. event:getPlayer():getName() .. "§4] §c종말이 다가온다!!")
							end
						end
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS006-requireCost") .. "개)")
						ability:resetCooldown(id)
					end
				end
			end
		end
	end
end

function Apocalypse(player)
	local players = util.getTableFromList(game.getPlayers())
	for i = 1, #players do
		if player:getPlayer():getWorld():getEnvironment() == players[i]:getPlayer():getPlayer():getWorld():getEnvironment() and 
			(player:getPlayer():getLocation():distance(players[i]:getPlayer():getLocation()) <= 100) then
			players[i]:getPlayer():getWorld():createExplosion(players[i]:getPlayer():getLocation(), 10)
		end
	end
end

function cancelAbility(LAPlayer, event, ability, id)
	if event:getEntity() == LAPlayer:getPlayer() then
		if LAPlayer:getVariable("HS006-abilityTime") > 2 then
			if game.checkCooldown(LAPlayer, game.getPlayer(event:getEntity()), ability, id) then
				local players = util.getTableFromList(game.getPlayers())
				for i = 1, #players do
					if event:getEntity():getWorld():getEnvironment() == players[i]:getPlayer():getPlayer():getWorld():getEnvironment() and 
						(event:getEntity():getLocation():distance(players[i]:getPlayer():getLocation()) <= 100) then
						game.sendMessage(players[i]:getPlayer(), "§2파멸의 예언자§a가 사망하여 종말이 일어나지 않습니다.")
					end
				end
				LAPlayer:setVariable("HS006-abilityTime", -2)
				ability:resetCooldown("HS006-abilityUse")
			end
		end
	end
end

function effect(player, timeCount)
	local players = util.getTableFromList(game.getPlayers())
	for i = 1, #players do
		if player:getPlayer():getWorld():getEnvironment() == players[i]:getPlayer():getPlayer():getWorld():getEnvironment() and 
			(player:getPlayer():getLocation():distance(players[i]:getPlayer():getLocation()) <= 100) then
			players[i]:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, players[i]:getPlayer():getLocation():add(0,1,0), 150, 0.3, 0.5, 0.3, 0.1)
			players[i]:getPlayer():getWorld():playSound(players[i]:getPlayer():getLocation(), import("$.Sound").ITEM_FLINTANDSTEEL_USE, 0.5, 0.5 + (1.0 * ((1200 - timeCount) / 1200)))
		end
	end
end

function addCost(player, ability)
	local cost = player:getVariable("HS006-cost")
	if cost == nil then player:setVariable("HS006-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS006-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS006-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end