Config = {}

Config.CashReward = 350000
Config.AmmoReward = 500
Config.ClaimCooldownSeconds = 5

-- Keep these public spawn points aligned with qs-advancedgarages/config/config.lua.
Config.GarageSpawnPoints = {
    { name = 'Legion Square', coords = vec4(232.931870, -790.087891, 29.454932, 158.740158) },
    { name = 'Pillbox Hill Garage', coords = vec4(113.87, -1071.64, 28.19, 85.48) },
    { name = 'Vinewood West', coords = vec4(-334.443939, 283.410980, 84.777344, 178.582672) },
    { name = 'Vinewood Center', coords = vec4(75.890114, 19.292309, 67.927490, 158.740158) },
    { name = 'Motel Parking', coords = vec4(285.428558, -347.894501, 43.950195, 161.574799) },
    { name = 'Spanish Ave Parking', coords = vec4(-1151.973633, -749.512085, 17.929663, 223.937012) },
    { name = 'Little Seoul Parking', coords = vec4(-357.771423, -883.226379, 29.893042, 0.0) },
    { name = 'Laguna Parking', coords = vec4(367.503296, 296.004395, 102.195654, 348.661407) },
    { name = 'Airport Los Santos', coords = vec4(-790.153870, -2022.949463, 7.719800, 56.692913) },
    { name = 'San Andreas Beach', coords = vec4(-1183.516479, -1501.912109, 3.254590, 218.267715) },
    { name = 'The Motor Hotel', coords = vec4(1137.441772, 2654.175781, 36.919409, 0.0) },
    { name = 'Alamo Sea Parking', coords = vec4(950.703308, 3615.586914, 31.610596, 90.708656) },
    { name = 'Sandy Shore Parking', coords = vec4(1737.797852, 3718.839600, 32.876538, 19.842520) },
    { name = 'Paleto Bay Parking', coords = vec4(85.200005, 6427.846191, 30.214307, 45.354328) },
    { name = 'Elysian Parking', coords = vec4(203.498901, -3129.336182, 4.753149, 87.874016) },
    { name = 'Airport Parking', coords = vec4(-982.325256, -2700.131836, 12.660034, 56.692913) },
    { name = 'Centro Parking', coords = vec4(-349.028564, -688.101074, 31.628516, 0.0) },
    { name = 'Cypress Flats Parking', coords = vec4(740.479126, -2016.553833, 28.291260, 263.622070) },
    { name = 'El Burro Parking', coords = vec4(1382.320923, -2052.065918, 50.893408, 36.850395) },
    { name = 'La Mesa Parking', coords = vec4(871.437378, -1567.081299, 29.488623, 104.881889) },
    { name = 'Big Ranch Station', coords = vec4(357.125275, -1691.419800, 31.393750, 138.897629) },
    { name = 'Rancho Garage', coords = vec4(461.037354, -1993.648315, 21.888306, 130.393707) },
    { name = 'La Mesa Mechanics', coords = vec4(814.892334, -822.725281, 24.840259, 93.543304) },
    { name = 'Mirror Park Parking', coords = vec4(1040.676880, -775.608765, 56.822290, 8.503937) },
    { name = 'Vinewood Small Park', coords = vec4(-559.345032, 327.336273, 83.374365, 269.291351) },
    { name = 'Gran Señora Desert', coords = vec4(192.290115, 2787.613281, 44.802881, 280.629913) },
    { name = 'Small Paleto Park', coords = vec4(-398.597809, 6051.204590, 30.515381, 133.228333) },
    { name = 'Grapeseed Parking', coords = vec4(2550.817627, 4682.188965, 32.740698, 17.007874) },
    { name = 'Grapeseed Village Park', coords = vec4(1697.195557, 4804.549316, 40.744360, 141.732285) },
}

Config.Vehicles = {
    {
        model = 'bbghost2',
        label = 'Rolls-Royce Ghost',
        subtitle = 'A custom animated luxury sedan',
        resource = 'bbghost',
    },
    {
        model = 'dc_rs7animated',
        label = 'Audi RS7 Mansory',
        subtitle = 'A custom animated performance sedan',
        resource = 'dc_rs7animated',
    },
    {
        model = 'm2',
        label = 'BMW M2',
        subtitle = 'A custom animated sports coupe',
        resource = 'm2',
    },
}

Config.RewardItems = {
    { name = 'WEAPON_GLIZZYG30', count = 1, metadata = { ammo = 0 } },
    { name = 'ammo-9', count = Config.AmmoReward },
    { name = 'darknet_tablet', count = 1 },
    { name = 'darknet_vpn', count = 1 },
    { name = 'house_robbery_tablet', count = 1 },
}
