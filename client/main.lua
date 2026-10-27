local ESX = exports['es_extended']:getSharedObject()
local nuiReady = false
local pendingMenuData
local menuRequestId = 0
local renderedRequestId = 0

RegisterCommand('welcome', function()
    TriggerServerEvent('jameskeys-welcome:server:open')
end, false)

local function showMenu(data)
    menuRequestId = menuRequestId + 1
    local requestId = menuRequestId
    local function sendOpen(attempt)
        if menuRequestId ~= requestId or renderedRequestId == requestId then
            return
        end

        SendNUIMessage({
            action = 'open',
            vehicles = data.vehicles,
            alreadyClaimed = data.alreadyClaimed,
            requestId = requestId,
        })

        if attempt >= 4 then
            SetTimeout(1000, function()
                if menuRequestId == requestId and renderedRequestId ~= requestId then
                    menuRequestId = menuRequestId + 1
                    SetNuiFocus(false, false)
                    SendNUIMessage({ action = 'hide' })
                    ESX.ShowNotification('The welcome menu could not be displayed. Try /welcome again or contact staff.', 'error')
                end
            end)
            return
        end

        SetTimeout(750, function()
            sendOpen(attempt + 1)
        end)
    end

    SetNuiFocus(true, true)
    sendOpen(1)
end

RegisterNetEvent('jameskeys-welcome:client:commandFeedback', function(message)
    ESX.ShowNotification(message, 'error')
end)

RegisterNetEvent('jameskeys-welcome:client:show', function(data)
    if not nuiReady then
        pendingMenuData = data
        return
    end

    showMenu(data)
end)

RegisterNetEvent('jameskeys-welcome:client:claimResult', function(result)
    SendNUIMessage({
        action = 'claimResult',
        success = result.success,
        message = result.message,
        plate = result.plate,
    })
end)

RegisterNetEvent('jameskeys-welcome:client:vehicleDelivered', function(data)
    if type(data) ~= 'table' or type(data.networkId) ~= 'number' then
        return
    end

    CreateThread(function()
        local deadline = GetGameTimer() + 15000
        local vehicle

        while GetGameTimer() < deadline do
            if NetworkDoesNetworkIdExist(data.networkId) then
                vehicle = NetworkGetEntityFromNetworkId(data.networkId)
                if DoesEntityExist(vehicle) then
                    break
                end
            end
            Wait(100)
        end

        if not vehicle or not DoesEntityExist(vehicle) then
            ESX.ShowNotification(
                ('Your vehicle is saved at %s, but could not be loaded nearby. Use that garage to retrieve it.'):format(
                    data.garage or 'your nearest public garage'
                ),
                'error'
            )
            return
        end

        SetVehicleNumberPlateText(vehicle, data.plate)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
end)

RegisterNUICallback('close', function(_, callback)
    menuRequestId = menuRequestId + 1
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    callback({ ok = true })
end)

RegisterNUICallback('opened', function(data, callback)
    if data and data.requestId == menuRequestId then
        renderedRequestId = menuRequestId
    end
    callback({ ok = true })
end)

RegisterNUICallback('ready', function(_, callback)
    nuiReady = true
    callback({ ok = true })

    if pendingMenuData then
        showMenu(pendingMenuData)
        pendingMenuData = nil
    end
end)

RegisterNUICallback('claim', function(data, callback)
    TriggerServerEvent('jameskeys-welcome:server:claim', {
        vehicle = data.vehicle,
    })
    callback({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    menuRequestId = menuRequestId + 1
    SetNuiFocus(false, false)
end)
