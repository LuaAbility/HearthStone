local particle = import("$.Particle")
local material = import("$.Material")

function Init(abilityData)
	plugin.requireDataPack("HearthStone", "https://blog.kakaocdn.net/dn/sAeFO/btrrxXWPS5C/aODIDmfwRB3boWzAlG6Wo1/HearthStone.zip?attach=1&knm=tfile.zip")
	plugin.registerEvent(abilityData, "HS019-abilityUse", "PlayerInteractEvent", 200)
end

function onEvent(funcTable)
	if funcTable[1] == "HS019-abilityUse" then abilityUse(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("HS019-health") == nil then 
		player:setVariable("HS019-health", player:getPlayer():getHealth()) 
		player:setVariable("HS019-healthStack", 0) 
		player:setVariable("HS019-cost", 0) 
		player:setVariable("HS019-requireCost", 7) 
	end
	
	local str = "§1[§b마나 수정§1] §b"
	local cost = player:getVariable("HS019-cost")
	for i = 1, 10 do
		if i <= cost then str = str .. "●"
		else str = str .. "○" end
	end
	game.sendActionBarMessage(player:getPlayer(), str)
	
	if cost < 10 then
		if player:getVariable("HS019-health") < player:getPlayer():getHealth() then player:setVariable("HS019-health", player:getPlayer():getHealth()) end
		local healthAmount = (player:getVariable("HS019-health") - player:getPlayer():getHealth()) + player:getVariable("HS019-healthStack")
		
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
					if LAPlayer:getVariable("HS019-cost") >= LAPlayer:getVariable("HS019-requireCost") then
						LAPlayer:setVariable("HS019-cost", LAPlayer:getVariable("HS019-cost") - LAPlayer:getVariable("HS019-requireCost"))
						game.sendMessage(event:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b능력을 사용했습니다.")
						local players = util.getTableFromList(game.getPlayers())
						for i = 1, #players do
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs19.useline", 1, 1)
							players[i]:getPlayer():playSound(players[i]:getPlayer():getLocation(), "hs19.usebgm", 1, 1)
						end
						for i = 0, 35 do
							util.runLater(function() event:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, event:getPlayer():getLocation():add(0,1,0), 30, 0.3, 0.7, 0.3, 0.05) end, i)
						end
						util.runLater(function() hit(LAPlayer) end, 40)
					else
						game.sendMessage(event:getPlayer(), "§4[§c" .. ability.abilityName .. "§4] §c마나 수정이 부족합니다! (필요 마나 수정 : " .. LAPlayer:getVariable("HS019-requireCost") .. "개)")
					end
				end
			end
		end
	end
end

function addCost(player, ability)
	local prevCost = player:getVariable("HS019-cost")
	local cost = prevCost
	
	if cost < 10 then
		local healthAmount = (player:getVariable("HS019-health") - player:getPlayer():getHealth()) + player:getVariable("HS019-healthStack")
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
		
		if cost < 10 then player:setVariable("HS019-healthStack", healthAmount)
		else player:setVariable("HS019-healthStack", 0) end
		if (prevCost < cost) then
			player:setVariable("HS019-health", player:getPlayer():getHealth())
			player:setVariable("HS019-cost", cost)
			
			game.sendMessage(player:getPlayer(), "§1[§b" .. ability.abilityName .. "§1] §b마나 수정이 생성되었습니다! (현재 마나 수정 : " .. cost .. "개)")
			player:getPlayer():playSound(player:getPlayer():getLocation(), import("$.Sound").ENTITY_EXPERIENCE_ORB_PICKUP, 0.5, 2)
			player:getPlayer():spawnParticle(particle.ITEM_CRACK, player:getPlayer():getLocation():add(0,1,0), 50, 0.2, 0.5, 0.2, 0.05, newInstance("$.inventory.ItemStack", {import("$.Material").DIAMOND_BLOCK}))
		end
	end
end

function circleEffect(loc, radius)
    local location = loc:clone()
    for i = 0, 60 do
        local angle = 2 * math.pi * i / 60
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        location:add(x, 0, z)
		location:getWorld():spawnParticle(particle.SMOKE_NORMAL, location, 2, 0.5, 0, 0.5, 0.2)
		if radius > 5 then
			location:getWorld():spawnParticle(particle.ITEM_CRACK, location, 5, 0.5, 0, 0.5, 0.2, newInstance("$.inventory.ItemStack", {import("$.Material").PURPLE_CONCRETE}))
		end
		location:getWorld():spawnParticle(particle.ITEM_CRACK, location, 5, 0.5, 0, 0.5, 0.2, newInstance("$.inventory.ItemStack", {import("$.Material").GRAY_CONCRETE}))
		if util.random() < 0.1 then
			location:getWorld():spawnParticle(particle.ITEM_CRACK, location, 10, 0.5, 0, 0.5, 0.2, newInstance("$.inventory.ItemStack", {import("$.Material").GLOWSTONE}))
		end
        location:subtract(x, 0, z)
    end
end

function hit(player)
	local doAgain = false
	local players = util.getTableFromList(game.getPlayers())
	for i = 1, #players do
		if players[i]:getPlayer() ~= player:getPlayer() and game.targetPlayer(player, players[i], false) then
			players[i]:getPlayer():damage(4, player:getPlayer())
			players[i]:getPlayer():getWorld():playSound(players[i]:getPlayer():getLocation(), "hs19.hitsfx", 1, 1)
			players[i]:getPlayer():getWorld():spawnParticle(particle.SMOKE_NORMAL, players[i]:getPlayer():getLocation():add(0,1,0), 100, 0.3, 0.7, 0.3, 0.05)
			players[i]:getPlayer():getWorld():spawnParticle(particle.REDSTONE, players[i]:getPlayer():getLocation():add(0,1,0), 100, 0.3, 0.7, 0.3, 0.05, newInstance("$.Particle$DustOptions", { import("$.Color"):fromRGB(51, 0, 102), 1 }))
			if players[i]:getPlayer():isDead() then doAgain = true end
		end
	end
	
	for i = 0, 7 do
		util.runLater(function()
			circleEffect(player:getPlayer():getLocation():add(0,1,0), i)
		end, i)
	end
	
	if doAgain then util.runLater(function() hit(player) end, 25) end
end