local serverSide = IsDuplicityVersion()
LOGGER_PATH = 'https://gist.githubusercontent.com/itIsMaku/a603a23c34582464083ba0ce5d2bbcff/raw/d6488d0d1d09d96dee8076c3add72c2580be6c5d/logger.lua'

GIT_NATIVES_TREE_PATH = 'https://api.github.com/repos/citizenfx/natives/git/trees/master?recursive=1'
STARTING_PATHS = {
    'APP',
    'AUDIO',
    'BRAIN',
    'CAM',
    'CLOCK',
    'CUTSCENE',
    'DATAFILE',
    'DECORATOR',
    'DLC',
    'ENTITY',
    'EVENT',
    'FILES',
    'FIRE',
    'GRAPHICS',
    'HUD',
    'INTERIOR',
    'ITEMSET',
    'LOADINGSCREEN',
    'LOCALIZATION',
    'MISC',
    'MOBILE',
    'MONEY',
    'NETSHOPPING',
    'NETWORK',
    'OBJECT',
    'PAD',
    'PATHFIND',
    'PED',
    'PHYSICS',
    'PLAYER',
    'RECORDING',
    'REPLAY',
    'SAVEMIGRATION',
    'SCRIPT',
    'SHAPETEST',
    'SOCIALCLUB',
    'STATS',
    'STREAMING',
    'SYSTEM',
    'TASK',
    'VEHICLE',
    'WATER',
    'WEAPON',
    'ZONE',
}

IGNORE_NATIVES = {
    ['Wait'] = true
}

local function overload(native)
    load(string.format([[
        local _%s = %s
        %s = function(...)
            print('^3[overloader] | ^7Native: ^3%s^7, params: ', ...)
            return _%s(...)
        end
    ]], native, native, native, native, native))()
end

if serverSide then
    local function getPathContent(path, expectJson)
        local p = promise.new()
        PerformHttpRequest(path, function(statusCode, response, headers)
            p:resolve(expectJson and json.decode(response) or response)
        end, 'GET', '', { ['Content-Type'] = 'application/json' })

        return Citizen.Await(p)
    end

    local logger = getPathContent(LOGGER_PATH, false)
    load(logger)()

    log.info('Fetching natives tree from [%s]...', GIT_NATIVES_TREE_PATH)

    local nativesResponse = getPathContent(GIT_NATIVES_TREE_PATH, true)

    log.info('Response received, parsing...')

    local nativesTree = nativesResponse.tree
    if nativesTree == nil then
        log.error('Failed to fetch natives tree.')
        return
    end

    local natives = {}
    local size = 0
    for _, nativeEntry in ipairs(nativesTree) do
        for _, startingPath in ipairs(STARTING_PATHS) do
            if nativeEntry.path:find(startingPath) == 1 then
                local nativeName = nativeEntry.path:match('([^/]+)%.md$')
                if nativeName and not IGNORE_NATIVES[nativeName] then
                    natives[nativeName] = true
                    size = size + 1
                end
            end
        end
    end

    log.info('Found %d natives, overloading...', size)

    for native, _ in pairs(natives) do
        overload(native)
    end

    log.info('Overloading completed.')

    TriggerClientEvent('overloader:natives', -1, logger, natives, size)
end

RegisterNetEvent('overloader:natives', function(logger, natives, size)
    load(logger)()

    log.info('Overloading %d natives...', size)

    for native, _ in pairs(natives) do
        overload(native)
    end

    log.info('Overloading completed.')
end)
