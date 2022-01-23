local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS003-abilityUse", "PlayerInteractEvent", 100)
end

function onEvent(funcTable)
	if funcTable[1] == "HS003-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS003-passiveCount") == nil then 
		player:setVariable("HS003-passiveCount", 0) 
		player:setVariable("HS003-cost", 0) 
		player:setVariable("HS003-requireCost", 8) 
		player:setVariable("HS003-abilities", {}) 
		player:setVariable("HS003-abilityTime", 0)
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS003-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		local count = player:getVariable("HS003-passiveCount")
		if count >= 600 * plugin.getPlugin().gameManager.cooldownMultiply then 
			count = 0
			addCost(player, ability)
		end
		count = count + 2
		player:setVariable("HS003-passiveCount", count)
	else 
		player:setVariable("HS003-passiveCount", 0)
	end
	
	local timeCount = player:getVariable("HS003-abilityTime")
	if timeCount > 0 then
		timeCount = timeCount - 2
		if timeCount <= 0 then ResetAbility(player, ability) end
		player:setVariable("HS003-abilityTime", timeCount)
	end
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "LEFT_CLICK_AIR" or event:getAction():toString() == "LEFT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) then
					if LAPlayer:getVariable("HS003-cost") >= LAPlayer:getVariable("HS003-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						LAPlayer:setVariable("HS003-cost", LAPlayer:getVariable("HS003-cost") - LAPlayer:getVariable("HS003-requireCost"))
						LAPlayer:setVariable("HS003-abilityTime", 200)
						
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs3.useline", 2, 1)
						event:getPlayer():getWorld():playSound(event:getPlayer():getLocation(), "hs3.usebgm", 2, 1)
						
						event:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, event:getPlayer():getLocation():add(0,1,0), 150, 0.2, 0.2, 0.2, 0.05)
						
						local players = util.getTableFromList(game.getPlayers())
						for i = 1, #players do
							if players[i]:getPlayer() ~= LAPlayer:getPlayer() then
								local ability = util.getTableFromList(players[i]:getAbility())
								util.runLater(function()
									for j = 1, #ability do
										table.insert(LAPlayer:getVariable("HS003-abilities"), ability[j].abilityID)
										game.addAbility(LAPlayer, ability[j].abilityID)
									end
								end, 2)
							end
						end
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS003-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function ResetAbility(player, ability)
	local abilities = player:getVariable("HS003-abilities")
	if #abilities > 0 then
		util.runLater(function()
			for i = 1, #abilities do
				game.removeAbilityAsID(player, abilities[i])
			end
		end, 2)
	end
	
	player:setVariable("HS003-abilities", { })
	
	game.sendMessage(player:getPlayer(), "§2[§a" .. ability.abilityName .. "§2] §a능력 시전 시간이 종료되었습니다.")
	player:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, player:getPlayer():getLocation():add(0,1,0), 150, 0.2, 0.2, 0.2, 0.05)
	player:getPlayer():getWorld():playSound(player:getPlayer():getLocation(), "hs1.endbgm", 2, 1)
end

function Reset(player, ability)
	if player:getVariable("HS003-abilityTime") > 0 then ResetAbility(player, ability) end
end

function addCost(player, ability)
	local cost = player:getVariable("HS003-cost")
	if cost == nil then player:setVariable("HS003-cost", 0) cost = 0 end
	if cost < 10 then
		cost = cost + 1
		player:setVariable("HS003-cost", cost)
		game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. player:getVariable("HS003-cost") .. "개)")
		player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
		player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
	end
end