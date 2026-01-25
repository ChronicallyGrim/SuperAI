-- user_data.lua
-- Stores user preferences, nicknames, and personalization data

local M = {}

-- User database stored per user
local users = {}

-- Load user data from RAID if available (with fallback to local)
local function loadUserData()
    local loaded = false
    
    -- Try RAID first
    local success, raid = pcall(require, "raid_system")
    if success then
        local init_ok = pcall(function() raid.init() end)
        if init_ok then
            local exists_ok, exists = pcall(function() return raid.exists("superai_data/users.dat") end)
            if exists_ok and exists then
                local read_ok, content = pcall(function() return raid.read("superai_data/users.dat") end)
                if read_ok and content then
                    users = textutils.unserialize(content) or {}
                    loaded = true
                end
            end
        end
    end
    
    -- Fall back to local storage
    if not loaded and fs.exists("users.dat") then
        local f = fs.open("users.dat", "r")
        if f then
            local content = f.readAll()
            f.close()
            users = textutils.unserialize(content) or {}
        end
    end
end

-- Save user data to RAID (with fallback to local)
local function saveUserData()
    local saved = false
    
    -- Try RAID first
    local success, raid = pcall(require, "raid_system")
    if success then
        local init_ok = pcall(function() raid.init() end)
        if init_ok then
            local write_ok = pcall(function()
                raid.write("superai_data/users.dat", textutils.serialize(users))
            end)
            if write_ok then
                saved = true
            end
        end
    end
    
    -- Always save locally as backup (and fallback)
    if not saved then
        local f = fs.open("users.dat", "w")
        if f then
            f.write(textutils.serialize(users))
            f.close()
        end
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
