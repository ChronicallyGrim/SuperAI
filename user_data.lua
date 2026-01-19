-- user_data.lua
-- Stores user preferences, nicknames, and personalization data

local M = {}

-- User database stored per user
local users = {}

-- Load user data from RAID if available
local function loadUserData()
    local raid = nil
    local success, module = pcall(require, "raid_system")
    if success then
        raid = module
        raid.init()
        
        if raid.exists("superai_data/users.dat") then
            local content = raid.read("superai_data/users.dat")
            if content then
                users = textutils.unserialize(content) or {}
            end
        end
    else
        -- Fallback to local storage
        if fs.exists("users.dat") then
            local f = fs.open("users.dat", "r")
            local content = f.readAll()
            f.close()
            users = textutils.unserialize(content) or {}
        end
    end
end

-- Save user data to RAID
local function saveUserData()
    local raid = nil
    local success, module = pcall(require, "raid_system")
    if success then
        raid = module
        raid.init()
        raid.write("superai_data/users.dat", textutils.serialize(users))
    else
        -- Fallback to local storage
        local f = fs.open("users.dat", "w")
        f.write(textutils.serialize(users))
        f.close()
    end
end

-- Get user data (creates if doesn't exist)
function M.getUser(username)
    if not users[username] then
        users[username] = {
            nickname = username,
            chatColor = colors.white,
            preferences = {},
            firstSeen = os.epoch("utc"),
            lastSeen = os.epoch("utc"),
            messageCount = 0
        }
        saveUserData()
    end
    
    users[username].lastSeen = os.epoch("utc")
    users[username].messageCount = (users[username].messageCount or 0) + 1
    
    return users[username]
end

-- Set user nickname
function M.setNickname(username, nickname)
    local user = M.getUser(username)
    user.nickname = nickname
    saveUserData()
end

-- Get user nickname
function M.getNickname(username)
    local user = M.getUser(username)
    return user.nickname or username
end

-- Set user chat color
function M.setChatColor(username, color)
    local user = M.getUser(username)
    user.chatColor = color
    saveUserData()
end

-- Get user chat color
function M.getChatColor(username)
    local user = M.getUser(username)
    return user.chatColor or colors.white
end

-- Set user preference
function M.setPreference(username, key, value)
    local user = M.getUser(username)
    user.preferences[key] = value
    saveUserData()
end

-- Get user preference
function M.getPreference(username, key, default)
    local user = M.getUser(username)
    return user.preferences[key] or default
end

-- Get all users
function M.listUsers()
    return users
end

-- Get user stats
function M.getUserStats(username)
    local user = M.getUser(username)
    return {
        nickname = user.nickname,
        messageCount = user.messageCount,
        firstSeen = user.firstSeen,
        lastSeen = user.lastSeen
    }
end

-- Initialize
loadUserData()

return M
