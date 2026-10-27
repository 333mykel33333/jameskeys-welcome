fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jameskeys-welcome'
author 'JamesKeys'
description 'One-time welcome reward claim with vehicle selection'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/jameskeys-logo.jpg',
    'html/assets/*.png',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/main.lua',
}

client_script 'client/main.lua'

dependencies {
    'es_extended',
    'ox_inventory',
    'oxmysql',
    'qs-advancedgarages',
    'qs-vehiclekeys',
    'bbghost',
    'dc_rs7animated',
    'm2',
}
