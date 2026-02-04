--[[
    mp3 - Background Music Controller for FFXI
    Author: Garyfromwork
    Version: 1.0.0

    Commands: //mp3 or //music

    Change background music in-game using packet injection.
    Features favorites list and startup song configuration.
]]

_addon.name = 'mp3'
_addon.author = 'Garyfromwork'
_addon.version = '1.0.0'
_addon.commands = {'mp3', 'music'}

require('tables')
require('strings')
require('logger')
local config = require('config')
local res = require('resources')

-- Default settings
local defaults = {
    startup_song = nil,         -- Song ID to play on load (nil = don't change)
    startup_type = 0,           -- Music type for startup song (0=day, 1=night, etc)
    favorites = {},             -- List of favorite song IDs
    last_played = nil,          -- Last played song ID
    volume = 100,               -- Not directly controllable, but stored for reference
    shuffle_interval = 180,     -- Seconds between auto-shuffle songs (default 3 min)
    shuffle_type = 0,           -- Music type for shuffle (0=day, 1=night, etc)
    shuffle_from_favorites = false, -- Shuffle from favorites only
}

local settings = config.load(defaults)

-- Shuffle state
local shuffle_active = false
local shuffle_history = {}     -- Recently played songs to avoid repeats
local shuffle_history_max = 10 -- How many songs to remember

-- Music type constants
local MUSIC_TYPES = {
    [0] = 'Day BGM',
    [1] = 'Night BGM',
    [2] = 'Solo Battle',
    [3] = 'Party Battle',
    [4] = 'Mount/Chocobo',
}

-- Cache the music list from resources
local music_list = {}
local music_by_name = {}

-- Forward declare for proper ordering
local init_fallback_music

-- Initialize music list from resources
local function init_music_list()
    music_list = {}
    music_by_name = {}

    -- Load from resources
    if res.bgm then
        for id, data in pairs(res.bgm) do
            if data and data.en then
                music_list[id] = {
                    id = id,
                    name = data.en,
                }
                music_by_name[data.en:lower()] = id
            end
        end
    end

    -- If resources don't have bgm, use a fallback list of common tracks
    if not next(music_list) then
        log('Loading fallback music list (resources.bgm not available)')
        init_fallback_music()
    end
end

-- Fallback music list if resources don't have bgm
init_fallback_music = function()
    local fallback = {
        [0] = "Silence",
        [1] = "Vana'diel March",
        [2] = "Vana'diel March #2",
        [3] = "Kingdom of San d'Oria",
        [4] = "Republic of Bastok",
        [5] = "Federation of Windurst",
        [6] = "Metalworks",
        [7] = "Mhaura",
        [8] = "Selbina",
        [9] = "Recollection",
        [10] = "Ronfaure",
        [11] = "Gustaberg",
        [12] = "Sarutabaruta",
        [13] = "The Grand Duchy of Jeuno",
        [14] = "Heaven's Tower",
        [15] = "Chateau d'Oraguille",
        [16] = "Ru'Lude Gardens",
        [17] = "Voyager",
        [18] = "Airship",
        [19] = "Battle Theme",
        [20] = "Battle Theme #2",
        [21] = "Battle in the Dungeon",
        [22] = "Battle in the Dungeon #2",
        [23] = "Anxiety",
        [24] = "Mog House",
        [25] = "Hopelessness",
        [26] = "Despair",
        [27] = "Tough Battle",
        [28] = "Tough Battle #2",
        [29] = "Awakening",
        [30] = "Sometime, Somewhere",
        [31] = "Monastic Cavern",
        [32] = "Castle Zvahl",
        [33] = "Shadow Lord",
        [34] = "Xarcabard",
        [35] = "Delkfutt's Tower",
        [36] = "Rolanberry Fields",
        [37] = "The Northlands",
        [38] = "Hume Male",
        [39] = "Hume Female",
        [40] = "Elvaan Male",
        [41] = "Elvaan Female",
        [42] = "Tarutaru Male",
        [43] = "Tarutaru Female",
        [44] = "Mithra",
        [45] = "Galka",
        [46] = "Prelude",
        [47] = "Victory Fanfare",
        [48] = "Game Over",
        [49] = "Sorrow",
        [50] = "Repression",
        [51] = "Eald'narche",
        [52] = "End Credits",
        [53] = "Fury",
        [54] = "Faded Memories",
        [55] = "Tavnazia",
        [56] = "Chains of Promathia",
        [57] = "Unity",
        [58] = "A New Morning",
        [59] = "Depths of the Soul",
        [60] = "Turmoil",
        [61] = "Moblin Menagerie",
        [62] = "Assault",
        [63] = "Salvage",
        [64] = "Aht Urhgan",
        [65] = "Imperial Palace",
        [66] = "Mercenaries' Delight",
        [67] = "Bustle of the Capital",
        [68] = "Eastward Bound",
        [69] = "Ululations from Beyond",
        [70] = "The Colosseum",
        [71] = "Run Chocobo, Run!",
        [72] = "Chocobo Circuit",
        [73] = "Dash de Chocobo",
        [74] = "Selbina (Starlight)",
        [75] = "Wings of the Goddess",
        [76] = "Griffons Never Die",
        [77] = "Forbidden Fruit",
        [78] = "Flowers on the Battlefield",
        [79] = "Echoes of a Zephyr",
        [80] = "Dancer in Distress",
        [81] = "Clash of Standards",
        [82] = "A Puppet's Slumber",
        [83] = "Stargazing",
        [84] = "Under a Clouded Moon",
        [85] = "Encampment Dreams",
        [86] = "Abyssea",
        [87] = "A Realm Reborn",
        [88] = "The Price of Freedom",
        [89] = "Iron Colossus",
        [90] = "Shinryu",
        [91] = "Seekers of Adoulin",
        [92] = "Ulbuka",
        [93] = "Roar of the Lion",
        [94] = "Steel Sings, Blades Dance",
        [95] = "Into Lands Primeval",
        [96] = "The Sacred City of Adoulin",
        [97] = "Whispers of the Gods",
        [98] = "Arciela",
        [99] = "Forever Today",
        [100] = "The Big One",
        [101] = "Provenance Watcher",
        [102] = "The Pioneers",
        [103] = "Order and Chaos",
        [104] = "Rhapsodies of Vana'diel",
        [105] = "A Shantotto Ascension",
        [106] = "Ark Angel",
        [107] = "Dynamis",
        [108] = "Limbus",
        [109] = "Einherjar",
        [110] = "Nyzul Isle",
    }

    for id, name in pairs(fallback) do
        music_list[id] = {
            id = id,
            name = name,
        }
        music_by_name[name:lower()] = id
    end
end

-- Set music using packet injection
local function set_music(song_id, music_type)
    music_type = music_type or 0

    if song_id < 0 or song_id > 255 then
        error('Song ID must be between 0 and 255')
        return false
    end

    -- Inject music change packet (incoming packet 0x05F)
    -- Packet format: 'IHH' = unsigned int header, unsigned short music_type, unsigned short song_id
    -- 0x45F is the packet header (includes packet ID 0x05F with length bits)
    windower.packets.inject_incoming(0x05F, ('IHH'):pack(0x45F, music_type, song_id))

    settings.last_played = song_id
    config.save(settings)

    return true
end

-- Find a song by name or ID
local function find_song(query)
    -- Check if it's a number
    local id = tonumber(query)
    if id then
        if music_list[id] then
            return music_list[id]
        end
        return nil
    end

    -- Search by name (case-insensitive, partial match)
    query = query:lower()

    -- Exact match first
    if music_by_name[query] then
        return music_list[music_by_name[query]]
    end

    -- Partial match
    local matches = {}
    for name, song_id in pairs(music_by_name) do
        if name:find(query, 1, true) then
            table.insert(matches, music_list[song_id])
        end
    end

    if #matches == 1 then
        return matches[1]
    elseif #matches > 1 then
        return nil, matches
    end

    return nil
end

-- Get song name by ID
local function get_song_name(song_id)
    if music_list[song_id] then
        return music_list[song_id].name
    end
    return 'Unknown (' .. song_id .. ')'
end

-- Display song list (paginated)
local function show_list(page, filter)
    page = page or 1
    local per_page = 20

    -- Build filtered list
    local filtered = {}
    for id, song in pairs(music_list) do
        if not filter or song.name:lower():find(filter:lower(), 1, true) then
            table.insert(filtered, song)
        end
    end

    -- Sort by ID
    table.sort(filtered, function(a, b) return a.id < b.id end)

    local total_pages = math.ceil(#filtered / per_page)
    page = math.max(1, math.min(page, total_pages))

    local start_idx = (page - 1) * per_page + 1
    local end_idx = math.min(start_idx + per_page - 1, #filtered)

    log('=== Music List (Page ' .. page .. '/' .. total_pages .. ') ===')

    for i = start_idx, end_idx do
        local song = filtered[i]
        local fav_marker = ''
        for _, fav_id in ipairs(settings.favorites) do
            if fav_id == song.id then
                fav_marker = ' [*]'
                break
            end
        end
        log('[' .. string.format('%3d', song.id) .. '] ' .. song.name .. fav_marker)
    end

    if filter then
        log('Showing ' .. #filtered .. ' results for "' .. filter .. '"')
    end
    log('Use: //mp3 list <page> or //mp3 search <name>')
end

-- Display favorites
local function show_favorites()
    if #settings.favorites == 0 then
        log('No favorites saved. Use: //mp3 fav add <song>')
        return
    end

    log('=== Favorites ===')
    for i, song_id in ipairs(settings.favorites) do
        local name = get_song_name(song_id)
        log('[' .. i .. '] ' .. name .. ' (ID: ' .. song_id .. ')')
    end
end

-- Add to favorites
local function add_favorite(query)
    local song, matches = find_song(query)

    if matches then
        log('Multiple matches found:')
        for _, s in ipairs(matches) do
            log('  [' .. s.id .. '] ' .. s.name)
        end
        log('Please be more specific.')
        return
    end

    if not song then
        error('Song not found: ' .. query)
        return
    end

    -- Check if already in favorites
    for _, fav_id in ipairs(settings.favorites) do
        if fav_id == song.id then
            log(song.name .. ' is already in favorites.')
            return
        end
    end

    table.insert(settings.favorites, song.id)
    config.save(settings)
    log('Added to favorites: ' .. song.name)
end

-- Remove from favorites
local function remove_favorite(query)
    local song, matches = find_song(query)

    if matches then
        log('Multiple matches found. Please be more specific.')
        return
    end

    if not song then
        -- Try by index
        local idx = tonumber(query)
        if idx and settings.favorites[idx] then
            local removed_id = settings.favorites[idx]
            local name = get_song_name(removed_id)
            table.remove(settings.favorites, idx)
            config.save(settings)
            log('Removed from favorites: ' .. name)
            return
        end
        error('Song not found: ' .. query)
        return
    end

    for i, fav_id in ipairs(settings.favorites) do
        if fav_id == song.id then
            table.remove(settings.favorites, i)
            config.save(settings)
            log('Removed from favorites: ' .. song.name)
            return
        end
    end

    log(song.name .. ' is not in favorites.')
end

-- Set startup song
local function set_startup(query, music_type)
    if not query or query == 'off' or query == 'none' then
        settings.startup_song = nil
        config.save(settings)
        log('Startup song disabled.')
        return
    end

    local song, matches = find_song(query)

    if matches then
        log('Multiple matches found:')
        for _, s in ipairs(matches) do
            log('  [' .. s.id .. '] ' .. s.name)
        end
        log('Please be more specific.')
        return
    end

    if not song then
        error('Song not found: ' .. query)
        return
    end

    settings.startup_song = song.id
    settings.startup_type = music_type or 0
    config.save(settings)
    log('Startup song set to: ' .. song.name .. ' (Type: ' .. MUSIC_TYPES[settings.startup_type] .. ')')
end

-- Play a song
local function play_song(query, music_type)
    local song, matches = find_song(query)

    if matches then
        log('Multiple matches found:')
        for _, s in ipairs(matches) do
            log('  [' .. s.id .. '] ' .. s.name)
        end
        log('Please be more specific or use the ID number.')
        return
    end

    if not song then
        error('Song not found: ' .. query)
        return
    end

    music_type = music_type or 0

    if set_music(song.id, music_type) then
        log('Now playing: ' .. song.name .. ' (Type: ' .. MUSIC_TYPES[music_type] .. ')')
    end
end

-- Play from favorites by index
local function play_favorite(index, music_type)
    index = tonumber(index)
    if not index or not settings.favorites[index] then
        error('Invalid favorite index. Use //mp3 favorites to see list.')
        return
    end

    local song_id = settings.favorites[index]
    local name = get_song_name(song_id)

    music_type = music_type or 0

    if set_music(song_id, music_type) then
        log('Now playing favorite: ' .. name .. ' (Type: ' .. MUSIC_TYPES[music_type] .. ')')
    end
end

-- Check if song was recently played (for shuffle)
local function was_recently_played(song_id)
    for _, id in ipairs(shuffle_history) do
        if id == song_id then
            return true
        end
    end
    return false
end

-- Add song to shuffle history
local function add_to_shuffle_history(song_id)
    table.insert(shuffle_history, 1, song_id)
    while #shuffle_history > shuffle_history_max do
        table.remove(shuffle_history)
    end
end

-- Get random song (from all or favorites)
local function get_random_song(from_favorites)
    local pool = {}

    if from_favorites then
        -- Build pool from favorites
        for _, song_id in ipairs(settings.favorites) do
            if music_list[song_id] and not was_recently_played(song_id) then
                table.insert(pool, music_list[song_id])
            end
        end
        -- If all favorites were recently played, reset history
        if #pool == 0 and #settings.favorites > 0 then
            shuffle_history = {}
            for _, song_id in ipairs(settings.favorites) do
                if music_list[song_id] then
                    table.insert(pool, music_list[song_id])
                end
            end
        end
    else
        -- Build pool from all songs
        for id, song in pairs(music_list) do
            if id > 0 and not was_recently_played(id) then -- Skip silence (ID 0)
                table.insert(pool, song)
            end
        end
        -- If somehow all songs were recently played, reset
        if #pool == 0 then
            shuffle_history = {}
            for id, song in pairs(music_list) do
                if id > 0 then
                    table.insert(pool, song)
                end
            end
        end
    end

    if #pool == 0 then
        return nil
    end

    -- Seed random if needed
    math.randomseed(os.time())
    local index = math.random(1, #pool)
    return pool[index]
end

-- Play a random song
local function play_shuffle(from_favorites, music_type)
    local song = get_random_song(from_favorites)

    if not song then
        if from_favorites then
            error('No favorites to shuffle. Add songs with: //mp3 fav add <song>')
        else
            error('No songs available to shuffle.')
        end
        return nil
    end

    music_type = music_type or settings.shuffle_type

    if set_music(song.id, music_type) then
        add_to_shuffle_history(song.id)
        local source = from_favorites and ' (from favorites)' or ''
        log('Shuffle: ' .. song.name .. source .. ' (Type: ' .. MUSIC_TYPES[music_type] .. ')')
        return song
    end
    return nil
end

-- Auto-shuffle timer callback
local function shuffle_timer_callback()
    if not shuffle_active then
        return
    end

    play_shuffle(settings.shuffle_from_favorites, settings.shuffle_type)

    -- Schedule next shuffle
    coroutine.schedule(shuffle_timer_callback, settings.shuffle_interval)
end

-- Start auto-shuffle mode
local function start_shuffle(from_favorites, interval, music_type)
    if shuffle_active then
        log('Shuffle already active. Use //mp3 shuffle off to stop.')
        return
    end

    -- Update settings if provided
    if from_favorites ~= nil then
        settings.shuffle_from_favorites = from_favorites
    end
    if interval then
        settings.shuffle_interval = interval
    end
    if music_type then
        settings.shuffle_type = music_type
    end
    config.save(settings)

    -- Check if we have songs to shuffle
    if settings.shuffle_from_favorites and #settings.favorites == 0 then
        error('No favorites to shuffle. Add songs with: //mp3 fav add <song>')
        return
    end

    shuffle_active = true
    shuffle_history = {}

    local source = settings.shuffle_from_favorites and 'favorites' or 'all songs'
    log('Shuffle ON - Playing from ' .. source .. ' every ' .. settings.shuffle_interval .. 's')

    -- Play first song immediately
    play_shuffle(settings.shuffle_from_favorites, settings.shuffle_type)

    -- Schedule next shuffle
    coroutine.schedule(shuffle_timer_callback, settings.shuffle_interval)
end

-- Stop auto-shuffle mode
local function stop_shuffle()
    if not shuffle_active then
        log('Shuffle is not active.')
        return
    end

    shuffle_active = false
    log('Shuffle OFF')
end

-- Show shuffle status
local function show_shuffle_status()
    log('=== Shuffle Status ===')
    log('Active: ' .. (shuffle_active and 'Yes' or 'No'))
    log('Source: ' .. (settings.shuffle_from_favorites and 'Favorites' or 'All Songs'))
    log('Interval: ' .. settings.shuffle_interval .. ' seconds')
    log('Music Type: ' .. MUSIC_TYPES[settings.shuffle_type])
    log('History: ' .. #shuffle_history .. ' songs')
end

-- Show current status
local function show_status()
    log('=== mp3 Status ===')

    if settings.last_played then
        log('Last played: ' .. get_song_name(settings.last_played) .. ' (ID: ' .. settings.last_played .. ')')
    else
        log('Last played: None')
    end

    if settings.startup_song then
        log('Startup song: ' .. get_song_name(settings.startup_song) .. ' (Type: ' .. MUSIC_TYPES[settings.startup_type] .. ')')
    else
        log('Startup song: Disabled')
    end

    -- Shuffle status
    local shuffle_source = settings.shuffle_from_favorites and 'Favorites' or 'All'
    log('Shuffle: ' .. (shuffle_active and 'ON' or 'OFF') .. ' (' .. shuffle_source .. ', ' .. settings.shuffle_interval .. 's)')

    log('Favorites: ' .. #settings.favorites .. ' songs')
    log('Music library: ' .. (function()
        local count = 0
        for _ in pairs(music_list) do count = count + 1 end
        return count
    end)() .. ' tracks')
end

-- Show help
local function show_help()
    log('=== mp3 - Music Player ===')
    log('//mp3 play <song>       - Play a song by name or ID')
    log('//mp3 play <song> <type>- Play with music type (0-4)')
    log('//mp3 list [page]       - Show song list')
    log('//mp3 search <name>     - Search for songs')
    log('//mp3 favorites         - Show favorites')
    log('//mp3 fav add <song>    - Add song to favorites')
    log('//mp3 fav remove <song> - Remove from favorites')
    log('//mp3 fav play <#>      - Play favorite by number')
    log('//mp3 shuffle           - Play random song')
    log('//mp3 shuffle fav       - Play random from favorites')
    log('//mp3 shuffle on [sec]  - Auto-shuffle every N seconds')
    log('//mp3 shuffle fav on    - Auto-shuffle from favorites')
    log('//mp3 shuffle off       - Stop auto-shuffle')
    log('//mp3 startup <song>    - Set startup song')
    log('//mp3 startup off       - Disable startup song')
    log('//mp3 status            - Show current status')
    log('//mp3 types             - Show music type info')
    log('//mp3 help              - Show this help')
    log('')
    log('Music Types: 0=Day, 1=Night, 2=Solo Battle, 3=Party Battle, 4=Mount')
end

-- Show music types
local function show_types()
    log('=== Music Types ===')
    for type_id, name in pairs(MUSIC_TYPES) do
        log('[' .. type_id .. '] ' .. name)
    end
    log('')
    log('Use: //mp3 play <song> <type>')
    log('Example: //mp3 play "Ronfaure" 0')
end

-- Command handler
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    local args = {...}

    if command == 'play' or command == 'p' then
        if #args == 0 then
            error('Usage: //mp3 play <song name or ID> [type]')
            return
        end

        -- Check if last arg is a music type number
        local music_type = 0
        local query_parts = args

        if #args > 1 then
            local last_arg = tonumber(args[#args])
            if last_arg and last_arg >= 0 and last_arg <= 4 then
                music_type = last_arg
                query_parts = {}
                for i = 1, #args - 1 do
                    table.insert(query_parts, args[i])
                end
            end
        end

        local query = table.concat(query_parts, ' ')
        play_song(query, music_type)

    elseif command == 'list' or command == 'l' then
        local page = tonumber(args[1]) or 1
        show_list(page)

    elseif command == 'search' or command == 's' then
        if #args == 0 then
            error('Usage: //mp3 search <name>')
            return
        end
        local query = table.concat(args, ' ')
        show_list(1, query)

    elseif command == 'favorites' or command == 'favs' or command == 'f' then
        show_favorites()

    elseif command == 'fav' then
        local subcmd = args[1] and args[1]:lower()

        if subcmd == 'add' or subcmd == 'a' then
            if #args < 2 then
                error('Usage: //mp3 fav add <song name or ID>')
                return
            end
            local query = table.concat(args, ' ', 2)
            add_favorite(query)

        elseif subcmd == 'remove' or subcmd == 'rem' or subcmd == 'r' then
            if #args < 2 then
                error('Usage: //mp3 fav remove <song name or ID or #>')
                return
            end
            local query = table.concat(args, ' ', 2)
            remove_favorite(query)

        elseif subcmd == 'play' or subcmd == 'p' then
            if #args < 2 then
                error('Usage: //mp3 fav play <#> [type]')
                return
            end
            local index = args[2]
            local music_type = tonumber(args[3]) or 0
            play_favorite(index, music_type)

        else
            show_favorites()
        end

    elseif command == 'shuffle' or command == 'random' or command == 'r' then
        local subcmd = args[1] and args[1]:lower()

        if not subcmd then
            -- Just play a random song from all
            play_shuffle(false)

        elseif subcmd == 'fav' or subcmd == 'favorites' or subcmd == 'f' then
            -- Check if next arg is 'on' for auto-shuffle from favorites
            local next_arg = args[2] and args[2]:lower()
            if next_arg == 'on' then
                local interval = tonumber(args[3]) or settings.shuffle_interval
                local music_type = tonumber(args[4]) or settings.shuffle_type
                start_shuffle(true, interval, music_type)
            else
                -- One-time shuffle from favorites
                local music_type = tonumber(args[2]) or settings.shuffle_type
                play_shuffle(true, music_type)
            end

        elseif subcmd == 'on' then
            local interval = tonumber(args[2]) or settings.shuffle_interval
            local music_type = tonumber(args[3]) or settings.shuffle_type
            start_shuffle(false, interval, music_type)

        elseif subcmd == 'off' or subcmd == 'stop' then
            stop_shuffle()

        elseif subcmd == 'status' then
            show_shuffle_status()

        elseif subcmd == 'interval' then
            local interval = tonumber(args[2])
            if not interval or interval < 10 then
                error('Usage: //mp3 shuffle interval <seconds> (minimum 10)')
                return
            end
            settings.shuffle_interval = interval
            config.save(settings)
            log('Shuffle interval set to ' .. interval .. ' seconds')

        elseif subcmd == 'type' then
            local music_type = tonumber(args[2])
            if not music_type or music_type < 0 or music_type > 4 then
                error('Usage: //mp3 shuffle type <0-4>')
                return
            end
            settings.shuffle_type = music_type
            config.save(settings)
            log('Shuffle music type set to ' .. MUSIC_TYPES[music_type])

        elseif subcmd == 'next' or subcmd == 'skip' then
            -- Skip to next song (works in auto-shuffle or one-time)
            play_shuffle(settings.shuffle_from_favorites, settings.shuffle_type)

        else
            -- Try to parse as music type for one-time shuffle
            local music_type = tonumber(subcmd)
            if music_type and music_type >= 0 and music_type <= 4 then
                play_shuffle(false, music_type)
            else
                error('Unknown shuffle command. Use: //mp3 shuffle [on/off/fav/status]')
            end
        end

    elseif command == 'next' or command == 'skip' then
        -- Quick skip command
        play_shuffle(settings.shuffle_from_favorites, settings.shuffle_type)

    elseif command == 'startup' then
        if #args == 0 then
            if settings.startup_song then
                log('Startup song: ' .. get_song_name(settings.startup_song))
            else
                log('No startup song set. Use: //mp3 startup <song>')
            end
            return
        end

        local query = args[1]
        local music_type = tonumber(args[2]) or 0

        if query:lower() == 'off' or query:lower() == 'none' then
            set_startup(nil)
        else
            query = table.concat(args, ' ')
            -- Check if last arg is type
            if #args > 1 then
                local last_arg = tonumber(args[#args])
                if last_arg and last_arg >= 0 and last_arg <= 4 then
                    music_type = last_arg
                    query = table.concat(args, ' ', 1, #args - 1)
                end
            end
            set_startup(query, music_type)
        end

    elseif command == 'status' then
        show_status()

    elseif command == 'types' then
        show_types()

    elseif command == 'help' or command == 'h' then
        show_help()

    else
        -- Treat as a direct play command
        local query = command .. ' ' .. table.concat(args, ' ')
        query = query:trim()
        play_song(query, 0)
    end
end)

-- Initialize on load
windower.register_event('load', function()
    init_music_list()
    log('mp3 loaded. Use //mp3 help for commands.')

    -- Play startup song if configured
    if settings.startup_song then
        -- Small delay to ensure game is ready
        coroutine.schedule(function()
            local name = get_song_name(settings.startup_song)
            if set_music(settings.startup_song, settings.startup_type) then
                log('Playing startup song: ' .. name)
            end
        end, 3)
    end
end)

-- Also play startup song on login
windower.register_event('login', function()
    if settings.startup_song then
        coroutine.schedule(function()
            local name = get_song_name(settings.startup_song)
            if set_music(settings.startup_song, settings.startup_type) then
                log('Playing startup song: ' .. name)
            end
        end, 5)
    end
end)
