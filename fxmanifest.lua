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
    'build/objectify.lua',
    -- "@utility_objectify/build/shared/api.lua",
    "build/client/modules/*.lua",
    "build/client/*.lua",
    "build/shared/*.lua",
}

server_scripts {
    "@utility_lib/server/native.lua",
    'build/objectify.lua',
    -- "@utility_objectify/build/shared/api.lua",
    "build/server/modules/*.lua",
    "build/server/*.lua",
    "build/shared/*.lua"
}

dependency "leap"