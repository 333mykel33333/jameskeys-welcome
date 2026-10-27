local ESX = exports['es_extended']:getSharedObject()
local claimCooldowns = {}
local claimAuthorizations = {}
local garageReservations = {}
local newCharacterAuthorizations = {}

exports('authorizeNewCharacter', function(playerId, identifier)
    playerId = tonumber(playerId)
    if not playerId or type(identifier) ~= 'string' or identifier == '' then
        return false
    end

    newCharacterAuthorizations[playerId] = identifier
    return true
end)

local function notify(source, success, message)
    TriggerClientEvent('jameskeys-welcome:client:claimResult', source, {
        success = success,
        message = message,
    })
end

local function commandFeedback(source, message)
    TriggerClientEvent('jameskeys-welcome:client:commandFeedback', source, message)
end

local function getVehicle(model)
    for i = 1, #Config.Vehicles do
        if Config.Vehicles[i].model == model then
            return Config.Vehicles[i]
        end
    end
end

local function showWelcomeMenu(source, xPlayer)
    local alreadyClaimed = MySQL.scalar.await(
        'SELECT 1 FROM `jameskeys_welcome_claims` WHERE `identifier` = ? LIMIT 1',
        { xPlayer.identifier }
    )

    if alreadyClaimed then
        claimAuthorizations[source] = nil
    else
        claimAuthorizations[source] = true
    end

    TriggerClientEvent('jameskeys-welcome:client:show', source, {
        vehicles = Config.Vehicles,
        alreadyClaimed = alreadyClaimed ~= nil,
    })
end

local function generatePlate()
    for _ = 1, 10 do
        local plate = ('JWK%05d'):format(math.random(0, 99999))
        local exists = MySQL.scalar.await(
            'SELECT 1 FROM `owned_vehicles` WHERE `plate` = ? LIMIT 1',
            { plate }
        )

        if not exists then
            return plate
        end
    end
end

local function releaseGarage(source, garage)
    if garage and garageReservations[garage.name] == source then
        garageReservations[garage.name] = nil
    end
end

local function isGarageSpotAvailable(coords)
    local vehicles = GetAllVehicles()

    for i = 1, #vehicles do
        local entity = vehicles[i]
        if DoesEntityExist(entity) then
            local vehicleCoords = GetEntityCoords(entity)
            local dx = vehicleCoords.x - coords.x
            local dy = vehicleCoords.y - coords.y
            local dz = vehicleCoords.z - coords.z
            if dx * dx + dy * dy + dz * dz < 25.0 then
                return false
            end
        end
    end

    return true
end

local function reserveNearestGarage(source)
    local ped = GetPlayerPed(source)
    if not DoesEntityExist(ped) then
        return nil
    end

    local playerCoords = GetEntityCoords(ped)
    local nearestGarage
    local nearestDistance = math.huge

    for i = 1, #Config.GarageSpawnPoints do
        local garage = Config.GarageSpawnPoints[i]
        local coords = garage.coords

        if not garageReservations[garage.name] and isGarageSpotAvailable(coords) then
            local dx = playerCoords.x - coords.x
            local dy = playerCoords.y - coords.y
            local dz = playerCoords.z - coords.z
            local distance = dx * dx + dy * dy + dz * dz

            if distance < nearestDistance then
                nearestGarage = garage
                nearestDistance = distance
            end
        end
    end

    if nearestGarage then
        garageReservations[nearestGarage.name] = source
    end

    return nearestGarage
end

local function deleteClaimAndVehicle(identifier, owner, plate)
    local vehicleRows = MySQL.update.await(
        'DELETE FROM `owned_vehicles` WHERE `owner` = ? AND `plate` = ?',
        { owner, plate }
    )

    if vehicleRows ~= 1 then
        return false
    end

    local claimRows = MySQL.update.await(
        'DELETE FROM `jameskeys_welcome_claims` WHERE `identifier` = ?',
        { identifier }
    )

    return claimRows == 1
end

local function rollbackItems(source, addedItems)
    local complete = true

    for i = #addedItems, 1, -1 do
        local item = addedItems[i]
        local removed = exports.ox_inventory:RemoveItem(
            source,
            item.name,
            item.count,
            item.metadata,
            item.slot
        )

        if not removed then
            complete = false
            print(('[jameskeys-welcome] Could not roll back %s for player %s'):format(
                item.name,
                source
            ))
        end
    end

    return complete
end

RegisterNetEvent('jameskeys-welcome:server:open', function()
    local source = source
    claimAuthorizations[source] = nil

    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        commandFeedback(source, 'Your character is not ready. Try /welcome again in a moment.')
        return
    end

    showWelcomeMenu(source, xPlayer)
end)

RegisterNetEvent('jameskeys-welcome:server:openForNewCharacter', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local authorizedIdentifier = newCharacterAuthorizations[source]

    if not xPlayer or not authorizedIdentifier or xPlayer.identifier ~= authorizedIdentifier then
        return
    end

    newCharacterAuthorizations[source] = nil
    showWelcomeMenu(source, xPlayer)
end)

AddEventHandler('playerDropped', function()
    local source = source
    newCharacterAuthorizations[source] = nil
    claimAuthorizations[source] = nil
    claimCooldowns[source] = nil

    for garageName, reservedBy in pairs(garageReservations) do
        if reservedBy == source then
            garageReservations[garageName] = nil
        end
    end
end)

RegisterNetEvent('jameskeys-welcome:server:claim', function(payload)
    local source = source
    local now = os.time()

    if claimAuthorizations[source] ~= true then
        notify(source, false, 'Open /welcome before submitting a vehicle choice.')
        return
    end

    if type(payload) ~= 'table'
        or type(payload.vehicle) ~= 'string'
        or #payload.vehicle > 64
    then
        notify(source, false, 'The claim request was invalid.')
        return
    end

    local vehicle = getVehicle(payload.vehicle)
    if not vehicle or GetResourceState(vehicle.resource) ~= 'started' then
        notify(source, false, 'That vehicle is unavailable. Please choose another.')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or type(xPlayer.identifier) ~= 'string' or xPlayer.identifier == '' then
        notify(source, false, 'Your character is not ready to claim the reward.')
        return
    end

    if claimCooldowns[source] and now - claimCooldowns[source] < Config.ClaimCooldownSeconds then
        notify(source, false, 'Please wait a moment before trying again.')
        return
    end

    claimCooldowns[source] = now

    for i = 1, #Config.RewardItems do
        local reward = Config.RewardItems[i]
        if not exports.ox_inventory:Items(reward.name) then
            print(('[jameskeys-welcome] Required ox_inventory item is missing: %s'):format(
                reward.name
            ))
            notify(source, false, ('The reward item "%s" is not configured on the server.'):format(
                reward.name
            ))
            return
        end
    end

    local plate = generatePlate()
    if not plate then
        notify(source, false, 'A vehicle plate could not be generated. Please try again.')
        return
    end

    local garage = reserveNearestGarage(source)
    if not garage then
        notify(source, false, 'All configured public garage delivery spots are occupied. Move to a clear area and try again.')
        return
    end

    local claimId = MySQL.insert.await(
        'INSERT IGNORE INTO `jameskeys_welcome_claims` (`identifier`, `chosen_vehicle`) VALUES (?, ?)',
        { xPlayer.identifier, vehicle.model }
    )

    if not claimId or claimId == 0 then
        releaseGarage(source, garage)
        claimAuthorizations[source] = nil
        notify(source, false, 'This character has already claimed the welcome reward.')
        return
    end

    local deliveryCoords = {
        x = garage.coords.x,
        y = garage.coords.y,
        z = garage.coords.z,
        w = garage.coords.w,
    }

    local vehicleProperties = {
        model = joaat(vehicle.model),
        plate = plate,
        plateIndex = 0,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        tankHealth = 1000.0,
        fuelLevel = 100.0,
        dirtLevel = 0.0,
        color1 = 0,
        color2 = 0,
        pearlescentColor = 0,
        wheelColor = 0,
        wheels = 0,
        windowTint = 0,
        extras = {},
        coords = deliveryCoords,
    }

    local vehicleId = MySQL.insert.await(
        [[
            INSERT INTO `owned_vehicles`
                (`owner`, `plate`, `vehicle`, `type`, `garage`, `stored`)
            VALUES (?, ?, ?, 'vehicle', 'OUT', 0)
        ]],
        {
            xPlayer.identifier,
            plate,
            json.encode(vehicleProperties),
        }
    )

    if not vehicleId or vehicleId == 0 then
        releaseGarage(source, garage)
        local claimRows = MySQL.update.await(
            'DELETE FROM `jameskeys_welcome_claims` WHERE `identifier` = ?',
            { xPlayer.identifier }
        )

        if claimRows ~= 1 then
            print(('[jameskeys-welcome] Could not release failed claim for player %s'):format(
                source
            ))
            notify(source, false, 'The vehicle could not be registered and your claim is protected. Please contact staff.')
        else
            notify(source, false, 'The vehicle could not be registered. Please try again.')
        end
        return
    end

    local addedItems = {}
    for i = 1, #Config.RewardItems do
        local reward = Config.RewardItems[i]
        local added, response = exports.ox_inventory:AddItem(
            source,
            reward.name,
            reward.count,
            reward.metadata
        )

        if not added then
            local itemsRolledBack = rollbackItems(source, addedItems)
            local rowsRemoved = false

            if itemsRolledBack then
                rowsRemoved = deleteClaimAndVehicle(
                    xPlayer.identifier,
                    xPlayer.identifier,
                    plate
                )
            end

            if not itemsRolledBack or not rowsRemoved then
                print(('[jameskeys-welcome] Reward rollback incomplete for player %s; claim remains protected'):format(
                    source
                ))
                releaseGarage(source, garage)
                notify(source, false, 'Your claim is protected, but the reward could not be completed. Please contact staff.')
            else
                releaseGarage(source, garage)
                notify(source, false, 'Your inventory is full or a reward could not be added. Make room and try again.')
            end

            return
        end

        addedItems[#addedItems + 1] = {
            name = reward.name,
            count = reward.count,
            metadata = response and response.metadata or reward.metadata,
            slot = response and response.slot,
        }
    end

    local moneyAdded = xPlayer.addMoney(Config.CashReward, 'Welcome package reward')
    if not moneyAdded then
        local itemsRolledBack = rollbackItems(source, addedItems)
        local rowsRemoved = false

        if itemsRolledBack then
            rowsRemoved = deleteClaimAndVehicle(
                xPlayer.identifier,
                xPlayer.identifier,
                plate
            )
        end

        if not itemsRolledBack or not rowsRemoved then
            print(('[jameskeys-welcome] Cash rollback incomplete for player %s; claim remains protected'):format(
                source
            ))
            releaseGarage(source, garage)
            notify(source, false, 'Your claim is protected, but the reward could not be completed. Please contact staff.')
        else
            releaseGarage(source, garage)
            notify(source, false, 'Cash could not be added. Please make room and try again.')
        end

        return
    end

    local keyGranted, keyError = pcall(function()
        exports['qs-vehiclekeys']:GiveKeysServer(source, plate, vehicle.model)
    end)

    if not keyGranted then
        print(('[jameskeys-welcome] Could not grant keys for plate %s to player %s: %s'):format(
            plate,
            source,
            keyError
        ))
    end

    local spawnSucceeded, spawnedVehicle = pcall(function()
        return exports['qs-advancedgarages']:SpawnVehicle(
            vehicleId,
            xPlayer.identifier,
            'vehicle',
            garage.coords,
            vehicleProperties
        )
    end)

    local message
    local networkId

    if spawnSucceeded and type(spawnedVehicle) == 'table' and spawnedVehicle.netID then
        networkId = spawnedVehicle.netID
        message = ('Welcome! Your %s is now your personal vehicle, delivered to %s. Your vehicle and keys are saved.'):format(
            vehicle.label,
            garage.name
        )
    else
        if not spawnSucceeded then
            print(('[jameskeys-welcome] Garage spawn failed for plate %s: %s'):format(
                plate,
                spawnedVehicle
            ))
        else
            print(('[jameskeys-welcome] Garage spawn returned no network ID for plate %s'):format(
                plate
            ))
        end

        local storedRows = MySQL.update.await(
            'UPDATE `owned_vehicles` SET `garage` = ?, `stored` = 1 WHERE `owner` = ? AND `plate` = ?',
            { garage.name, xPlayer.identifier, plate }
        )

        if storedRows == 1 then
            message = ('Welcome! Your %s is registered to you and safely stored at %s. Take it out from that garage.'):format(
                vehicle.label,
                garage.name
            )
        else
            print(('[jameskeys-welcome] Could not save fallback garage location for plate %s'):format(
                plate
            ))
            message = ('Your rewards were delivered. The vehicle registration needs staff attention; provide plate %s.'):format(
                plate
            )
        end
    end

    releaseGarage(source, garage)

    if networkId then
        TriggerClientEvent('jameskeys-welcome:client:vehicleDelivered', source, {
            networkId = networkId,
            plate = plate,
            garage = garage.name,
        })
    end

    TriggerClientEvent('jameskeys-welcome:client:claimResult', source, {
        success = true,
        message = message,
        plate = plate,
    })
    claimAuthorizations[source] = nil
end)
