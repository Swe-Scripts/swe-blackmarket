local RSGCore = exports['rsg-core']:GetCoreObject()
local blackmarketPed = nil
local pedSpawned = false
local currentCoords = nil
lib.locale()

local function getRandomLocation()
    local locations = Config.Blackmarket.locations
    return locations[math.random(#locations)]
end

local function getRandomItems()
    local possibleItems = Config.Blackmarket.possibleItems
    local selectedItems = {}
    local numItems = math.random(1, #possibleItems)

    for i = 1, numItems do
        local item = table.remove(possibleItems, math.random(#possibleItems))
        table.insert(selectedItems, item)
    end

    return selectedItems
end

local function spawnBlackmarketPed()
    local pedModel = GetHashKey(Config.Blackmarket.ped.model)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(50)
    end

    currentCoords = Config.Blackmarket.moveOnRestart and getRandomLocation() or Config.Blackmarket.ped.coords
    blackmarketPed = CreatePed(pedModel, currentCoords.x, currentCoords.y, currentCoords.z - 1.0, currentCoords.w, false, false, 0, 0)
    SetEntityAlpha(blackmarketPed, 0, false)
    SetRandomOutfitVariation(blackmarketPed, true)
    SetEntityCanBeDamaged(blackmarketPed, false)
    SetEntityInvincible(blackmarketPed, true)
    FreezeEntityPosition(blackmarketPed, true)
    SetBlockingOfNonTemporaryEvents(blackmarketPed, true)
    SetPedRelationshipGroupHash(blackmarketPed, GetPedRelationshipGroupHash(blackmarketPed))
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(blackmarketPed), `PLAYER`)

    for i = 0, 255, 51 do
        Wait(50)
        SetEntityAlpha(blackmarketPed, i, false)
    end

    pedSpawned = true
end

local function removeBlackmarketPed()
    for i = 255, 0, -51 do
        Wait(50)
        SetEntityAlpha(blackmarketPed, i, false)
    end
    DeleteEntity(blackmarketPed)
    pedSpawned = false
end

local function updateTargetZone()
    exports['rsg-target']:RemoveZone("swe_blackmarket")
    exports['rsg-target']:AddCircleZone("swe_blackmarket", currentCoords, Config.Blackmarket.radius, {
        name = "swe_blackmarket",
        debugPoly = false,
        useZ = true
    }, {
        options = Config.Blackmarket.options,
        distance = Config.Blackmarket.radius
    })
end

CreateThread(function()
    if Config.Blackmarket.changeItemsOnRestart then
        Config.Blackmarket.items = getRandomItems()
    end
    spawnBlackmarketPed()
    updateTargetZone()
end)

CreateThread(function()
    while true do
        Wait(1000)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - vector3(currentCoords.x, currentCoords.y, currentCoords.z))

        local visibleDistance = Config.Blackmarket.radius * 2

        if distance > visibleDistance and pedSpawned then
            removeBlackmarketPed()
            exports['rsg-target']:RemoveZone("swe_blackmarket")
        elseif distance <= visibleDistance and not pedSpawned then
            spawnBlackmarketPed()
            updateTargetZone()
        end
    end
end)

local function openBlackmarketMenu()
    local options = {}
    for _, item in ipairs(Config.Blackmarket.items) do
        table.insert(options, {
            title = item.title,
            description = string.format("%s\nPrice: $%d", item.description, item.price),
            event = 'blackmarket:client:choosePurchaseMethod',
            args = { item = item.item, price = item.price },
            icon = item.icon
        })
    end

    lib.registerContext({
        id = 'blackmarket_menu',
        title = 'Blackmarket',
        options = options
    })
    lib.showContext('blackmarket_menu')
end

local function openPurchaseMethodMenu(item, price)
    local options = {
        {
            title = "Barter",
            description = "Negotiate the price",
            event = 'blackmarket:client:initiateBarter',
            args = { item = item, price = price },
            icon = 'fa-solid fa-handshake'
        },
        {
            title = "Buy Now",
            description = string.format("Buy for $%d", price),
            event = 'blackmarket:client:buyItem',
            args = { item = item, price = price },
            icon = 'fa-solid fa-money-bill'
        }
    }

    lib.registerContext({
        id = 'purchase_method_menu',
        title = 'Choose Purchase Method',
        options = options
    })
    lib.showContext('purchase_method_menu')
end

local function openBarterMenu(item, price)
    local minPrice = math.floor(price * (Config.Blackmarket.barter.minPercent / 100))
    local maxPrice = math.floor(price * (Config.Blackmarket.barter.maxPercent / 100))
    local options = {}
    for i = minPrice, maxPrice, 10 do
        table.insert(options, {
            title = string.format("Offer $%d", i),
            event = 'blackmarket:client:barterItem',
            args = { item = item, price = price, offer = i }
        })
    end

    lib.registerContext({
        id = 'barter_menu',
        title = 'Barter Price',
        options = options
    })
    lib.showContext('barter_menu')
end

RegisterNetEvent('blackmarket:client:openMenu', function()
    if Config.Blackmarket.openHoursEnabled then
        local hour = GetClockHours()
        if (Config.Blackmarket.openHour < Config.Blackmarket.closeHour and hour >= Config.Blackmarket.openHour and hour < Config.Blackmarket.closeHour) or
           (Config.Blackmarket.openHour > Config.Blackmarket.closeHour and (hour >= Config.Blackmarket.openHour or hour < Config.Blackmarket.closeHour)) then
            openBlackmarketMenu()
        else
            lib.notify({
                type = 'error',
                description = locale('bm_closed'),
                duration = 5000
            })
        end
    else
        openBlackmarketMenu()
    end
end)

RegisterNetEvent('blackmarket:client:choosePurchaseMethod', function(data)
    openPurchaseMethodMenu(data.item, data.price)
end)

RegisterNetEvent('blackmarket:client:initiateBarter', function(data)
    openBarterMenu(data.item, data.price)
end)

RegisterNetEvent('blackmarket:client:barterItem', function(data)
    local item = data.item
    local price = data.price
    local offer = data.offer
    local player = RSGCore.Functions.GetPlayerData()
    local cash = player.money['cash']

    if cash >= offer then
        local chance = math.random(0, 100)
        local acceptanceChance = 100 - ((price - offer) / price * 100)

        if chance <= acceptanceChance then
            TriggerServerEvent('blackmarket:server:buyItem', item, offer)
        else
            lib.notify({
                type = 'error',
                description = locale('declined'),
                duration = 5000
            })
        end
    else
        lib.notify({
            type = 'error',
            description = locale('no_cash_offer'),
            duration = 5000
        })
    end
end)

RegisterNetEvent('blackmarket:client:buyItem', function(data)
    local item = data.item
    local price = data.price
    local player = RSGCore.Functions.GetPlayerData()
    local cash = player.money['cash']

    if cash >= price then
        TriggerServerEvent('blackmarket:server:buyItem', item, price)
    else
        lib.notify({
            type = 'error',
            description = locale('no_cash'),
            duration = 5000
        })
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if DoesEntityExist(blackmarketPed) then
            DeleteEntity(blackmarketPed)
        end
        exports['rsg-target']:RemoveZone("swe_blackmarket")
    end
end)