
local hasAlreadyEnteredMarker, hasPaid, currentActionData = false, false, {}
local lastZone, currentAction, currentActionMsg
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function OpenShopMenu()
	hasPaid = false

	TriggerEvent('esx_skin:openRestrictedMenu', function(data, menu)
		menu.close()

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_confirm', {
			title = _U('valid_this_purchase'),
			align = 'top-left',
			elements = {
				{label = _U('no'), value = 'no'},
				{label = _U('yes'), value = 'yes'}
		}}, function(data, menu)
			menu.close()

			if data.current.value == 'yes' then
				ESX.TriggerServerCallback('esx_negozioborsoni:buyClothes', function(bought)
					if bought then
						TriggerEvent('skinchanger:getSkin', function(skin)
							TriggerServerEvent('esx_skin:save', skin)
						end)

						hasPaid = true

						ESX.TriggerServerCallback('esx_negozioborsoni:checkPropertyDataStore', function(foundStore)
							if foundStore then
								ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'save_dressing', {
									title = _U('save_in_dressing'),
									align = 'top-left',
									elements = {
										{label = _U('no'),  value = 'no'},
										{label = _U('yes'), value = 'yes'}
								}}, function(data2, menu2)
									menu2.close()

									if data2.current.value == 'yes' then
										ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'outfit_name', {
											title = _U('name_outfit')
										}, function(data3, menu3)
											menu3.close()

											TriggerEvent('skinchanger:getSkin', function(skin)
												TriggerServerEvent('esx_negozioborsoni:saveOutfit', data3.value, skin)
												ESX.ShowNotification(_U('saved_outfit'))
											end)
										end, function(data3, menu3)
											menu3.close()
										end)
									end
								end)
							end
						end)

					else
						ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
							TriggerEvent('skinchanger:loadSkin', skin)
						end)

						ESX.ShowNotification(_U('not_enough_money'))
					end
				end)
			elseif data.current.value == 'no' then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
					TriggerEvent('skinchanger:loadSkin', skin)
				end)
			end

			currentAction     = 'shop_menu'
			currentActionMsg  = _U('press_menu')
			currentActionData = {}
		end, function(data, menu)
			menu.close()

			currentAction     = 'shop_menu'
			currentActionMsg  = _U('press_menu')
			currentActionData = {}
		end)

	end, function(data, menu)
		menu.close()

		currentAction     = 'shop_menu'
		currentActionMsg  = _U('press_menu')
		currentActionData = {}
	end, {
		'bags_1',
		'bags_2'
	})
end

AddEventHandler('esx_negozioborsoni:hasEnteredMarker', function(zone)
	currentAction     = 'shop_menu'
	currentActionMsg  = _U('press_menu')
	currentActionData = {}
end)

AddEventHandler('esx_negozioborsoni:hasExitedMarker', function(zone)
	ESX.UI.Menu.CloseAll()
	currentAction = nil

	if not hasPaid then
		TriggerEvent('esx_skin:getLastSkin', function(skin)
			TriggerEvent('skinchanger:loadSkin', skin)
		end)
	end
end)

-- Create Blips
Citizen.CreateThread(function()
	for k,v in ipairs(Config.Shops) do
		local blip = AddBlipForCoord(v)

		SetBlipSprite (blip, 586)
		SetBlipColour (blip, 69)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(_U('clothes'))
		EndTextCommandSetBlipName(blip)
	end
end)

-- Enter / Exit marker events & draw markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords, isInMarker, currentZone, letSleep = GetEntityCoords(PlayerPedId()), false, nil, true

		for k,v in pairs(Config.Shops) do
			local distance = #(playerCoords - v)

			if distance < Config.DrawDistance then
				letSleep = false
				DrawMarker(Config.MarkerType, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)

				if distance < Config.MarkerSize.x then
					isInMarker, currentZone = true, k
				end
			end
		end

		if (isInMarker and not hasAlreadyEnteredMarker) or (isInMarker and lastZone ~= currentZone) then
			hasAlreadyEnteredMarker, lastZone = true, currentZone
			TriggerEvent('esx_negozioborsoni:hasEnteredMarker', currentZone)
		end

		if not isInMarker and hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = false
			TriggerEvent('esx_negozioborsoni:hasExitedMarker', lastZone)
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

-- Key controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if currentAction then
			ESX.ShowHelpNotification(currentActionMsg)

			if IsControlJustReleased(0, 38) then
				if currentAction == 'shop_menu' then
					OpenShopMenu()
				end

				currentAction = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)
