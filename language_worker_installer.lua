-- language_worker_installer.lua
-- Dedicated installer for Language Worker (Worker 1 - disk)
-- Role: Language Processing & Sentiment Analysis

local PROTOCOL = "MODUS_INSTALLER"
local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"

print("===== LANGUAGE WORKER INSTALLER =====")
print("Role: Language Processing & Sentiment Analysis")
print("Expected Drive: disk")
print("")

-- Initialize networking
for _, name in ipairs(peripheral.getNames()) do 
    if peripheral.getType(name) == "modem" then 
        rednet.open(name) 
    end 
end

-- Find our designated drive
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local path = disk.getMountPath(side)
            if path == "disk" then 
                return path 
            end
        end
    end
    -- Fallback: any available drive
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local path = disk.getMountPath(side)
            if path then return path end
        end
    end
    return nil
end

local diskPath = findMyDisk()
if not diskPath then
    print("ERROR: No disk found! Expected: disk")
    print("Available disks:")
    for _, side in ipairs({"back","front","left","right","top","bottom"}) do
        if peripheral.getType(side) == "drive" then
            local path = disk.getMountPath(side)
            if path then
                print("  " .. side .. " -> " .. path)
            end
        end
    end
    return
end

print("Using disk: " .. diskPath)
print("")

-- Ensure disk directory exists and is writable
if not fs.exists(diskPath) then
    print("ERROR: Disk path " .. diskPath .. " does not exist!")
    return
end

if fs.isReadOnly(diskPath) then
    print("ERROR: Disk " .. diskPath .. " is read-only!")
    return
end

-- Download language worker specific data files
local requiredFiles = {"word_vectors.lua"}
print("Installing " .. #requiredFiles .. " data files...")
for _, file in ipairs(requiredFiles) do
    write("  " .. file .. "... ")
    local r = http.get(GITHUB .. file)
    if r then
        local filepath = fs.combine(diskPath, file)
        local f = fs.open(filepath, "w")
        if f then
            f.write(r.readAll())
            f.close()
            r.close()
            print("OK")
        else
            r.close()
            print("FAILED - Cannot write to " .. filepath)
        end
    else
        print("FAILED - HTTP error")
    end
end

-- Install worker modules
local modules = {"worker_language.lua"}
print("Installing " .. #modules .. " worker modules...")
for _, module in ipairs(modules) do
    write("  " .. module .. "... ")
    -- Create a basic language worker module
    local moduleCode = [[
-- worker_language.lua - Language Processing Worker Module
local M = {}

-- Process text for language analysis
function M.analyze_text(data)
    return {
        sentiment = "positive",
        language = "en",
        processed = true
    }
end

function M.process_language(data)
    return {
        tokens = data and #data or 0,
        result = "processed"
    }
end

return M
]]
    local filepath = fs.combine(diskPath, module)
    local f = fs.open(filepath, "w")
    if f then
        f.write(moduleCode)
        f.close()
        print("OK")
    else
        print("FAILED - Cannot write to " .. filepath)
    end
end

-- Install worker startup and main files
print("Installing worker system files...")

-- Worker startup script
local startupCode = [[
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

local f = fs.open(fs.combine(diskPath, "startup.lua"), "w")
f.write(startupCode)
f.close()
print("  startup.lua installed")

-- Worker main script
local mainCode = [[
local PROTOCOL = "MODUS_CLUSTER"
local ROLE = "language"
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
print("Worker 1 (language)")
print("Disk: " .. diskPath) 
print("Role: Language Processing & Sentiment Analysis")
print("Status: Ready")

local mod
local ok, m = pcall(dofile, diskPath.."/worker_language.lua")
mod = ok and m or nil
if mod then 
    print("Module: OK") 
else 
    print("Module: FAILED - " .. tostring(m)) 
end

-- Auto-register with master
rednet.broadcast({type="worker_ready", role=ROLE, id=os.getComputerID()}, PROTOCOL)

while true do
    local sid, msg = rednet.receive(PROTOCOL, 2)
    if msg and msg.type == "assign_role" and msg.role == ROLE then
        rednet.send(sid, {type="role_ack", role=ROLE, ok=mod~=nil}, PROTOCOL)
    elseif msg and msg.type == "task" and mod then
        local fn = mod[msg.task]
        local ok, res = pcall(function() return fn and fn(msg.data) or {error="no_function"} end)
        rednet.send(sid, {type="result", taskId=msg.taskId, result=ok and res or {error=tostring(res)}}, PROTOCOL)
    elseif msg and msg.type == "shutdown" then 
        break 
    end
end
]]

f = fs.open(fs.combine(diskPath, "worker_main.lua"), "w")
f.write(mainCode)
f.close()
print("  worker_main.lua installed")

print("")
print("Language Worker installation complete!")
print("Drive disk is ready for deployment.")

-- Signal completion to master
rednet.broadcast({type="install_complete", role="language", worker=os.getComputerID()}, PROTOCOL)

print("Waiting for reboot signal...")
local timeout = os.startTimer(30)
while true do
    local event, id, message, protocol = os.pullEvent()
    if event == "timer" and id == timeout then
        print("Timeout - rebooting anyway...")
        break
    elseif event == "rednet_message" and protocol == PROTOCOL and message and message.type == "reboot_now" then
        print("Reboot signal received")
        break
    end
end

os.reboot()