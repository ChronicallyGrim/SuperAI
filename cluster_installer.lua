-- cluster_installer.lua v11
-- Workers search all sides for their disk

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"

print("===== MODUS CLUSTER INSTALLER =====")
print("")

-- Find master disk
local myDrive = disk.getMountPath("back")
print("Master disk: " .. (myDrive or "NONE"))

-- Find worker drives and computers
-- IMPORTANT: Only include drives that will be used by worker computers, 
-- NOT drives connected to this master computer!
local workerDrives = {}
local workerComputers = {}
local masterConnectedDrives = {}  -- Drives connected to master (don't use for workers)

local myID = os.getComputerID()
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= "back" then
        local path = disk.getMountPath(name)
        if path then
            -- This drive is connected to the master - don't put worker files on it!
            table.insert(masterConnectedDrives, {name = name, path = path})
            print("  Master-connected drive: " .. name .. " -> " .. path .. " (SKIPPING)")
        end
    elseif pType == "computer" then
        local cid = peripheral.call(name, "getID")
        if cid ~= myID then
            table.insert(workerComputers, {name = name, id = cid})
        end
    end
end

-- Automatically assign drives based on naming convention:
-- disk3 = master drive (gets master startup)  
-- disk, disk2, disk4, disk5 = worker drives (get worker startup)
print("Automatically assigning drives:")
print("  disk3 -> master drive")  
print("  disk, disk2, disk4, disk5 -> worker drives")

for i, drive in ipairs(masterConnectedDrives) do
    -- Check if this drive should be a worker drive
    if drive.path == "disk" or drive.path == "disk2" or drive.path == "disk4" or drive.path == "disk5" then
        table.insert(workerDrives, drive)
        print("  " .. drive.name .. " (" .. drive.path .. ") -> worker drive")
    else
        print("  " .. drive.name .. " (" .. drive.path .. ") -> master drive") 
    end
end

print("Worker drives: " .. #workerDrives)
print("Worker computers: " .. #workerComputers)
print("")

-- Data files - download if missing
local dataFiles = {
    "word_vectors.lua",
    "knowledge_graph.lua",
    "conversation_memory.lua",
    "response_generator.lua",
    "personality.lua",
    "mood.lua",
    "attention.lua",
    "neural_net.lua",
    "meta_cognition.lua",
    "introspection.lua",
    "philosophical_reasoning.lua",
    "natural_conversation.lua"
}

print("Checking data files...")
for _, df in ipairs(dataFiles) do
    local found = false
    if fs.exists(df) then
        found = true
    elseif myDrive and fs.exists(myDrive.."/"..df) then
        found = true
    end
    
    if not found then
        write("  Downloading " .. df .. "... ")
        local r = http.get(GITHUB .. df)
        if r then
            local f = fs.open(myDrive.."/"..df, "w")
            f.write(r.readAll())
            f.close()
            r.close()
            print("OK")
        else
            print("FAILED")
        end
    else
        print("  " .. df .. " OK")
    end
end
print("")

-- Rebuild dataLoc after downloads
local dataLoc = {}
for _, df in ipairs(dataFiles) do
    if fs.exists(df) then
        dataLoc[df] = df
    elseif myDrive and fs.exists(myDrive.."/"..df) then
        dataLoc[df] = myDrive.."/"..df
    end
end

-- ============ FILE CONTENTS ============

local MASTER_STARTUP = [[
-- Enhanced Auto-startup for SuperAI master_brain.lua
-- This runs automatically after reboot on the master computer
-- Version 2.0 - Improved reliability and debugging

local LOG_FILE = "startup.log"

local function log(message)
    local timestamp = textutils.formatTime(os.time(), false)
    local logEntry = "[" .. timestamp .. "] " .. message
    print(logEntry)
    
    -- Write to log file
    local file = fs.open(LOG_FILE, "a")
    if file then
        file.writeLine(logEntry)
        file.close()
    end
end

local function findMasterBrain()
    local searchPaths = {}
    
    -- Try master_brain.lua in current directory first (primary location - same as startup)
    if fs.exists("master_brain.lua") then 
        table.insert(searchPaths, "master_brain.lua - FOUND")
        return "master_brain.lua" 
    else
        table.insert(searchPaths, "master_brain.lua - NOT FOUND")
    end
    
    -- Try disk locations (backup removed to save space)
    local p = disk.getMountPath("back")
    if p then
        local backPath = p.."/master_brain.lua"
        if fs.exists(backPath) then 
            table.insert(searchPaths, backPath .. " - FOUND")
            return backPath 
        else
            table.insert(searchPaths, backPath .. " - NOT FOUND")
        end
    else
        table.insert(searchPaths, "back disk - NOT MOUNTED")
    end
    
    -- Try numbered disk locations
    for i = 1, 10 do
        local try = "disk" .. (i > 1 and i or "")
        local diskPath = try.."/master_brain.lua"
        if fs.exists(diskPath) then 
            table.insert(searchPaths, diskPath .. " - FOUND")
            return diskPath 
        else
            table.insert(searchPaths, diskPath .. " - NOT FOUND")
        end
    end
    
    -- Log all search attempts
    log("Search results:")
    for _, path in ipairs(searchPaths) do
        log("  " .. path)
    end
    
    return nil
end

local function verifySystemHealth()
    log("=== System Health Check ===")
    
    -- Check available memory
    log("Computer ID: " .. os.getComputerID())
    log("Computer Label: " .. (os.getComputerLabel() or "UNLABELED"))
    
    -- Check disk mounts
    local disks = {}
    for _, side in ipairs({"back","front","left","right","top","bottom"}) do
        if peripheral.getType(side) == "drive" then
            local path = disk.getMountPath(side)
            table.insert(disks, side .. ": " .. (path or "UNMOUNTED"))
        end
    end
    
    if #disks > 0 then
        log("Available disks:")
        for _, disk in ipairs(disks) do
            log("  " .. disk)
        end
    else
        log("WARNING: No disks detected!")
    end
    
    -- Check for critical files
    local criticalFiles = {"cluster_installer.lua", "superai_cluster.lua"}
    for _, file in ipairs(criticalFiles) do
        if fs.exists(file) then
            log("Critical file " .. file .. ": OK")
        else
            log("WARNING: Critical file " .. file .. ": MISSING")
        end
    end
end

local function startMasterBrain(path, retries)
    retries = retries or 3
    
    for attempt = 1, retries do
        log("Starting master_brain (attempt " .. attempt .. "/" .. retries .. ")")
        log("Path: " .. path)
        
        local success, error = pcall(function()
            shell.run(path)
        end)
        
        if success then
            log("Master brain started successfully!")
            return true
        else
            log("ERROR in attempt " .. attempt .. ": " .. tostring(error))
            if attempt < retries then
                log("Retrying in 2 seconds...")
                sleep(2)
            end
        end
    end
    
    log("FAILED: All startup attempts failed!")
    return false
end

-- Main startup sequence
log("=== MODUS Enhanced Auto-Startup v2.0 ===")
log("Boot sequence initiated")

-- Perform system health check
verifySystemHealth()

-- Find and start master brain
local masterPath = findMasterBrain()
if masterPath then 
    log("Master brain located: " .. masterPath)
    log("Auto-startup enabled - will run on every reboot")
    
    local success = startMasterBrain(masterPath)
    if not success then
        log("=== STARTUP FAILED ===")
        log("Manual intervention required!")
        log("Try running: " .. masterPath)
        log("Or reinstall with: cluster_installer.lua")
    end
else 
    log("ERROR: master_brain.lua not found!")
    log("Please run cluster_installer.lua to install the system.")
    log("Check " .. LOG_FILE .. " for detailed search results")
end

log("Startup sequence completed")
]]

-- Worker startup: search ALL sides for a disk with worker_main.lua
local WORKER_STARTUP = [[
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p and fs.exists(p.."/worker_main.lua") then return p end
        end
    end
end
local d = findMyDisk()
if d then shell.run(d.."/worker_main.lua") else print("worker_main.lua not found!") end
]]

-- Worker main: search all sides for disk
local WORKER_MAIN = [[
local PROTOCOL = "MODUS_CLUSTER"
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p then return p end
        end
    end
    return ""
end
local diskPath = findMyDisk()

for _, n in ipairs(peripheral.getNames()) do if peripheral.getType(n) == "modem" then rednet.open(n) end end
term.clear() term.setCursorPos(1,1)
print("Worker " .. os.getComputerID()) print("Disk: " .. diskPath) print("Waiting...")

local ROLE, mod
while true do
    local sid, msg = rednet.receive(PROTOCOL, 2)
    if msg and msg.type == "assign_role" then
        ROLE = msg.role
        local ok, m = pcall(dofile, diskPath.."/worker_"..ROLE..".lua")
        mod = ok and m or nil
        print("Role: " .. ROLE .. " = " .. (mod and "OK" or "FAIL"))
        if not ok then print(tostring(m)) end
        rednet.send(sid, {type="role_ack", role=ROLE, ok=mod~=nil}, PROTOCOL)
    elseif msg and msg.type == "task" and mod then
        local fn = mod[msg.task]
        local ok, res = pcall(function() return fn and fn(msg.data) or {error="?"} end)
        rednet.send(sid, {type="result", taskId=msg.taskId, result=ok and res or {error=tostring(res)}}, PROTOCOL)
    elseif msg and msg.type == "shutdown" then break end
end
]]

-- Worker modules: search all sides for disk
local WORKER_LANGUAGE = [[
local M = {}
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p then return p end
        end
    end
    return ""
end
local p = findMyDisk()
local v
local ok, m = pcall(dofile, p.."/word_vectors.lua")
if ok then v = m; if v.load then v.load() end; print("Vectors OK") else print("Vec: "..tostring(m)) end
function M.analyze(d) return {sentiment = v and v.getSentiment and v.getSentiment(d.text or "") or 0} end
return M
]]

local WORKER_MEMORY = [[
local M = {}
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p then return p end
        end
    end
    return ""
end
local p = findMyDisk()
local mem
local ok, m = pcall(dofile, p.."/conversation_memory.lua")
if ok then mem = m; if mem.init then mem.init() end; print("Memory OK") else print("Mem: "..tostring(m)) end
function M.recordInteraction(d) if mem then pcall(mem.recordUserInteraction,d.name,d.message,d.sentiment,{}) end return {ok=true} end
function M.getUser(d) return {user = mem and mem.getUser and mem.getUser(d.name or "") or {}} end
return M
]]

local WORKER_RESPONSE = [[
local M = {}
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p then return p end
        end
    end
    return ""
end
local p = findMyDisk()
local g
local ok, m = pcall(dofile, p.."/response_generator.lua")
if ok then g = m; print("Response OK") else print("Resp: "..tostring(m)) end
function M.generateGreeting(d) return {response = g and g.generateGreeting and g.generateGreeting(d.context or {}) or "Hello!"} end
function M.generateStatus(d) return {response = g and g.generateStatusResponse and g.generateStatusResponse(d.sentiment or 0) or "I see."} end
function M.generateJoke(d) return {response = g and g.generateJoke and g.generateJoke(d.category) or "Why do programmers prefer dark mode? Light attracts bugs!"} end
function M.generateFarewell(d) return {response = g and g.generateFarewell and g.generateFarewell() or "Goodbye!"} end
function M.generateThanks(d) return {response = g and g.generateThanks and g.generateThanks() or "You're welcome!"} end
function M.generateAboutSelf(d) return {response = g and g.generateAboutSelf and g.generateAboutSelf() or "I'm MODUS!"} end
function M.generateContextual(d) return {response = g and g.generateContextual and g.generateContextual(d.intent or "statement", {}) or "Interesting!"} end
return M
]]

local WORKER_PERSONALITY = [[
local M = {}
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p then return p end
        end
    end
    return ""
end
local p = findMyDisk()
local pers
local ok, m = pcall(dofile, p.."/personality.lua")
if ok then pers = m; if pers.init then pers.init() end; print("Personality OK") else print("Pers: "..tostring(m)) end
function M.getTrait(d) return {value = pers and pers.getTrait and pers.getTrait(d.trait or "") or 0.5} end
function M.updateTrait(d) if pers and pers.updateTrait then pers.updateTrait(d.trait, d.change) end return {ok=true} end
function M.getPersonality(d) return {personality = pers and pers.getPersonalityState and pers.getPersonalityState() or {}} end
return M
]]

-- Enhanced master_brain.lua will be copied from standalone file

-- ============ INSTALL ============

print("Installing enhanced master...")

-- Download master_brain.lua from GitHub if it doesn't exist
if not fs.exists("master_brain.lua") then
    write("  Downloading master_brain.lua... ")
    local r = http.get(GITHUB .. "master_brain.lua")
    if r then
        local f = fs.open("master_brain.lua", "w")
        f.write(r.readAll())
        f.close()
        r.close()
        print("OK")
    else
        print("FAILED")
        print("  ERROR: Could not download master_brain.lua from GitHub!")
        return
    end
end

-- Now master_brain.lua exists in current directory (same as startup.lua)
print("  + Enhanced master_brain.lua installed in startup directory")

-- Copy to master disk if available (backup location)
if myDrive then
    fs.copy("master_brain.lua", myDrive.."/master_brain.lua")
    print("  + Enhanced master_brain.lua copied to " .. myDrive)
end

-- Skip creating backup copy to save space
-- User reported space is precious, removed redundancy backup
print("  + Backup creation skipped (space optimization)")

print("  + Enhanced master_brain.lua fully installed")

-- Install startup scripts with auto-run functionality
local f = fs.open("startup.lua", "w") f.write(MASTER_STARTUP) f.close()
if myDrive then
    f = fs.open(myDrive.."/startup.lua", "w") f.write(MASTER_STARTUP) f.close()
end
print("  + startup.lua with auto-run")

-- Install master startup on any drives connected to master that are NOT worker drives
print("\nConfiguring drives connected to master...")
for _, drive in ipairs(masterConnectedDrives) do
    local isWorkerDrive = false
    for _, workerDrive in ipairs(workerDrives) do
        if drive.name == workerDrive.name then
            isWorkerDrive = true
            break
        end
    end
    
    if not isWorkerDrive then
        -- This drive stays with master - give it master startup
        f = fs.open(drive.path.."/startup.lua", "w") 
        f.write(MASTER_STARTUP) 
        f.close()
        print("  " .. drive.path .. ": master startup installed")
    end
end

print("\nInstalling workers...")
for i, drv in ipairs(workerDrives) do
    write("  " .. drv.path .. ": ")
    f = fs.open(drv.path.."/startup.lua", "w") f.write(WORKER_STARTUP) f.close()
    f = fs.open(drv.path.."/worker_main.lua", "w") f.write(WORKER_MAIN) f.close()
    f = fs.open(drv.path.."/worker_language.lua", "w") f.write(WORKER_LANGUAGE) f.close()
    f = fs.open(drv.path.."/worker_memory.lua", "w") f.write(WORKER_MEMORY) f.close()
    f = fs.open(drv.path.."/worker_response.lua", "w") f.write(WORKER_RESPONSE) f.close()
    f = fs.open(drv.path.."/worker_personality.lua", "w") f.write(WORKER_PERSONALITY) f.close()
    local c = 0
    for _, df in ipairs(dataFiles) do
        local src = dataLoc[df]
        if src then
            if fs.exists(drv.path.."/"..df) then fs.delete(drv.path.."/"..df) end
            fs.copy(src, drv.path.."/"..df)
            c = c + 1
        end
    end
    print(c .. " data files")
end

print("\nRebooting...")
for _, c in ipairs(workerComputers) do peripheral.call(c.name, "reboot") end
sleep(2)
os.reboot()
