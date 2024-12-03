local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('blackmarket:server:buyItem', function(item, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local itemLabel = RSGCore.Shared.Items[item].label

    if Player.Functions.RemoveMoney('cash', price) then
        Player.Functions.AddItem(item, 1)
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = locale('bought') .. itemLabel .. " " .. locale('for') .. price,
            duration = 5000
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = locale('no_cash'),
            duration = 5000
        })
    end
end)