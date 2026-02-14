-- cluster_installer.lua v11
-- Workers search all sides for their disk

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"

print("===== MODUS CLUSTER INSTALLER =====")
print("")

-- Find master disk
local myDrive = disk.getMountPath("back")
print("Master disk: " .. (myDrive or "NONE"))

-- Find worker drives and computers
local workerDrives = {}
local workerComputers = {}

local myID = os.getComputerID()
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= "back" then
        local path = disk.getMountPath(name)
        if path then
            table.insert(workerDrives, {name = name, path = path})
        end
    elseif pType == "computer" then
        local cid = peripheral.call(name, "getID")
        if cid ~= myID then
            table.insert(workerComputers, {name = name, id = cid})
        end
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
-- Auto-startup for enhanced master_brain.lua
-- This runs automatically after reboot on the advanced computer

local function findMasterBrain()
    -- Try local computer installation first (primary location after installer runs)
    if fs.exists("master_brain_local.lua") then 
        return "master_brain_local.lua" 
    end
    
    -- Try original master_brain.lua in current directory
    if fs.exists("master_brain.lua") then 
        return "master_brain.lua" 
    end
    
    -- Try backup location
    if fs.exists("master_brain_backup.lua") then
        return "master_brain_backup.lua"
    end
    
    -- Try disk locations
    local p = disk.getMountPath("back")
    if p and fs.exists(p.."/master_brain.lua") then 
        return p.."/master_brain.lua" 
    end
    
    for i = 1, 10 do
        local try = "disk" .. (i > 1 and i or "")
        if fs.exists(try.."/master_brain.lua") then 
            return try.."/master_brain.lua" 
        end
    end
    
    return nil
end

print("=== MODUS Enhanced Auto-Startup ===")
local masterPath = findMasterBrain()
if masterPath then 
    print("Starting enhanced master_brain from: " .. masterPath)
    shell.run(masterPath)
else 
    print("ERROR: master_brain.lua not found!")
    print("Please run cluster_installer.lua to install the system.")
    print("Searched locations: master_brain_local.lua, master_brain.lua, master_brain_backup.lua, disk locations")
end
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

-- Copy the enhanced master_brain.lua from current directory to multiple locations
if fs.exists("master_brain.lua") then
    -- Copy to master disk if available
    if myDrive then
        fs.copy("master_brain.lua", myDrive.."/master_brain.lua")
        print("  + Enhanced master_brain.lua copied to " .. myDrive)
    end
    
    -- CRITICAL: Copy to local computer directory for auto-startup after reboot
    -- This ensures the master_brain.lua is available on the installer's computer
    if not fs.exists("master_brain_local.lua") then
        fs.copy("master_brain.lua", "master_brain_local.lua")
        print("  + Enhanced master_brain.lua installed to local computer")
    end
    
    -- Create backup copy
    if not fs.exists("master_brain_backup.lua") then
        fs.copy("master_brain.lua", "master_brain_backup.lua")
        print("  + Enhanced master_brain.lua backup created")
    end
    
    print("  + Enhanced master_brain.lua fully installed")
else
    print("  ERROR: master_brain.lua not found! Please ensure it's in the same directory.")
end

-- Install startup scripts with auto-run functionality
local f = fs.open("startup.lua", "w") f.write(MASTER_STARTUP) f.close()
if myDrive then
    f = fs.open(myDrive.."/startup.lua", "w") f.write(MASTER_STARTUP) f.close()
end
print("  + startup.lua with auto-run")

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
