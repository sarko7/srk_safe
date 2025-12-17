fx_version "cerulean"
game "gta5"
lua54 "yes"

shared_scripts {
    '@ox_lib/init.lua',
    "build/config.lua",
    "build/config_functions.lua"
}

client_scripts {
    "@utility_lib/client/native.lua",
    "@utility_objectify/build/client/api.lua",
    "build/client/modules/*.lua",
    "build/client/*.lua",
    "build/shared/*.lua"
}

server_scripts {
    "@utility_lib/server/native.lua",
    "@utility_objectify/build/server/api.lua",
    "build/server/modules/*.lua",
    "build/server/*.lua",
    "build/shared/*.lua"
}

dependency "leap"