local particle = import("$.Particle")
local material = import("$.Material")
local circleDelay = 20

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS001-abilityUse", "PlayerInteractEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "HS001-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS001-health") == nil then 
		player:setVariable("HS001-health", player:getPlayer():getHealth()) 
		player:setVariable("HS001-healthStack", 0) 
		player:setVariable("HS001-halfTime", 0) 
		player:setVariable("HS001-cost", 0) 
		player:setVariable("HS001-requireCost", 5) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS001-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS001-health") < player:getPlayer():getHealth() then player:setVariable("HS001-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS001-health") - player:getPlayer():getHealth()) + player:getVariable("HS001-healthStack")
		
		if healthAmount > 1 then
			addCost(player, ability)
		end
	end
	
	local timeCount = player:getVariable("HS001-halfTime")
	if timeCount > 0 then
		circleEffect(player:getPlayer():getLocation(), timeCount % circleDelay)
		timeCount = timeCount - 2
		if timeCount <= 0 then ResetTime(player, ability) end
		player:setVariable("HS001-halfTime", timeCount)
	end
	
end

function ResetTime(player)
	if player:getVariable("HS001-cooldownMultiply") ~= nil then
		player:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, player:getPlayer():getLocation():add(0,1,0), 500, 0.5, 1, 0.5, 0.9)
		local players = util.getTableFromList(game.getPlayers())
		for i = 1, #players do
			players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs1.endbgm", 1, 1)
		end
		plugin.getPlugin().gameManager.cooldownMultiply = player:getVariable("HS001-cooldownMultiply")
		player:removeVariable("HS001-cooldownMultiply")
		game.broadcastMessage("§a재사용 대기시간이 원래대로 돌아옵니다.")
	end
end

function Reset(player, ability)
	ResetTime(player)
end

function abilityUse(LAPlayer, event, ability, id)
	if event:getAction():toString() == "RIGHT_CLICK_AIR" or event:getAction():toString() == "RIGHT_CLICK_BLOCK" then
		if event:getItem() ~= nil then
			if game.isAbilityItem(event:getItem(), "IRON_INGOT") then
				if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id, false) and LAPlayer:getVariable("HS001-halfTime") <= 0 then
					if LAPlayer:getVariable("HS001-cost") >= LAPlayer:getVariable("HS001-requireCost") then
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						LAPlayer:setVariable("HS001-cost", LAPlayer:getVariable("HS001-cost") - LAPlayer:getVariable("HS001-requireCost"))
						LAPlayer:setVariable("HS001-halfTime", 1200)
						if LAPlayer:getVariable("HS001-cooldownMultiply") == nil then LAPlayer:setVariable("HS001-cooldownMultiply", plugin.getPlugin().gameManager.cooldownMultiply) end
						plugin.getPlugin().gameManager.cooldownMultiply = plugin.getPlugin().gameManager.cooldownMultiply * 2
						
						local players = util.getTableFromList(game.getPlayers())
						for i = 1, #players do
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs1.useline", 1, 1)
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs1.usebgm", 1, 1)
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs1.usesfx", 1, 1)
						end
						
						event:getPlayer():getWorld():spawnParticle(import("$.Particle").SMOKE_NORMAL, event:getPlayer():getLocation():add(0,1,0), 150, 0.5, 1, 0.5, 0.9)
						game.broadcastMessage("§6노즈도르무§e의 능력 발동으로 재사용 대기시간이 반으로 줄어듭니다!")
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS001-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS001-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS001-health") - player:getPlayer():getHealth()) + player:getVariable("HS001-healthStack")
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
		
		if cost < 10 then player:setVariable("HS001-healthStack", healthAmount)
		else player:setVariable("HS001-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS001-health", player:getPlayer():getHealth())
			player:setVariable("HS001-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end

function circleEffect(loc, count)
    local location = loc:clone()
	
    local angle = 2 * math.pi * count / circleDelay
    local x = math.cos(angle) * 0.5
    local z = math.sin(angle) * 0.5
    location:add(x, 0, z)
	location:getWorld():spawnParticle(particle.ITEM_CRACK, location:add(0, 1.2, 0), 30, 0, 0, 0, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").SAND}))
    location:subtract(x, 0, z)
end