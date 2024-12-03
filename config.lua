-- config.lua
Config = {}

Config.Blackmarket = {
    moveOnRestart = false, -- choose if the blackmarket should move to a different coordinate on restart
    changeItemsOnRestart = true, -- choose if the items should change on restart
    coords = vector3(2523.65, 2286.13, 177.35),
    locations = {
        vector3(2518.22, 2285.33, 177.35),
        vector3(2523.72, 2282.70, 177.35),
        -- Add more locations as needed
    },
    radius = 2.5,
    openHoursEnabled = true, -- Enable or disable open hours
    openHour = 1, -- Opening hour (24-hour format)
    closeHour = 23, -- Closing hour (24-hour format)
    options = {
        {
            type = "client",
            event = "blackmarket:client:openMenu",
            icon = "fa-solid fa-shopping-cart",
            label = "Open Blackmarket"
        }
    },
    ped = {
        model = "re_drunkdueler_males_01",
        coords = vector4(2523.65, 2286.13, 177.35, 160.06)
    },
    items = {
        { title = 'Rollinblock Sniperrifle', description = 'A very dangerous sniper!', item = 'weapon_sniperrifle_rollingblock', price = 1000, icon = 'fa-solid fa-gun' },
        { title = 'Dynamite', description = 'High explosive dynamite.', item = 'weapon_thrown_dynamite', price = 100, icon = 'fa-solid fa-bomb' },
        -- Add more items as needed
    },
    possibleItems = { -- List of possible items
        { title = 'Rollinblock Sniperrifle', description = 'A very dangerous sniper!', item = 'weapon_sniperrifle_rollingblock', price = 1000, icon = 'fa-solid fa-gun' },
        { title = 'Dynamite', description = 'High explosive dynamite.', item = 'weapon_thrown_dynamite', price = 100, icon = 'fa-solid fa-bomb' },
        -- Add more possible items as needed
    },
    barter = {
        minPercent = 50, -- Minimum barter price as a percentage of the standard price
        maxPercent = 150 -- Maximum barter price as a percentage of the standard price
    }
}