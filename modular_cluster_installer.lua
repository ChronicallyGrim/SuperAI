-- modular_cluster_installer.lua v1.0
-- Advanced modular installer with role-specific worker deployment
-- Flow: Master installer -> Deploy worker installers -> Remote execution -> Reboot -> Ready

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"
local PROTOCOL = "MODUS_INSTALLER"

print("===== MODUS MODULAR CLUSTER INSTALLER =====")
print("Hub-and-spoke architecture with targeted worker deployment")
print("")

-- Initialize rednet for remote deployment
for _, name in ipairs(peripheral.getNames()) do 
    if peripheral.getType(name) == "modem" then 
        rednet.open(name) 
    end 
end

-- Define worker roles and their specific requirements
local WORKER_ROLES = {
    {
        id = 1,
        name = "language",
        drive = "disk",
        description = "Language Processing & Sentiment Analysis",
        files = {"word_vectors.lua"},
        modules = {"worker_language.lua"}
    },
    {
        id = 2,
        name = "memory", 
        drive = "disk2",
        description = "Conversation Memory & User Management",
        files = {"conversation_memory.lua"},
        modules = {"worker_memory.lua"}
    },
    {
        id = 4,
        name = "response",
        drive = "disk4", 
        description = "Response Generation & Context",
        files = {"response_generator.lua", "knowledge_graph.lua"},
        modules = {"worker_response.lua"}
    },
    {
        id = 5,
        name = "personality",
        drive = "disk5",
        description = "Personality & Behavioral Traits",
        files = {"personality.lua", "mood.lua", "attention.lua"},
        modules = {"worker_personality.lua"}
    }
}

-- Master computer setup
local myID = os.getComputerID()
local myDrive = disk.getMountPath("back")
print("Master Computer ID: " .. myID)
print("Master Drive: " .. (myDrive or "NONE"))

-- Step 1: Deploy worker_listener.lua to all worker computers
print("\n=== STEP 1: AUTOMATIC WORKER PREPARATION ===")
print("Deploying worker_listener.lua to all worker computers...")

-- Find all worker computers via direct connection
local allWorkerComputers = {}
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "computer" then
        local cid = peripheral.call(name, "getID")
        if cid ~= myID then
            table.insert(allWorkerComputers, {name = name, id = cid, connected = true})
            print("  Found worker computer: ID " .. cid .. " (" .. name .. ")")
        end
    end
end

if #allWorkerComputers == 0 then
    print("ERROR: No worker computers found! Check network connections.")
    return
end

-- Download worker_listener.lua content
local workerListenerContent = nil
if fs.exists("worker_listener.lua") then
    print("Reading local worker_listener.lua...")
    local f = fs.open("worker_listener.lua", "r")
    workerListenerContent = f.readAll()
    f.close()
else
    print("Downloading worker_listener.lua from GitHub...")
    local r = http.get(GITHUB .. "worker_listener.lua")
    if r then
        workerListenerContent = r.readAll()
        r.close()
        -- Save local copy for future use
        local f = fs.open("worker_listener.lua", "w")
        f.write(workerListenerContent)
        f.close()
        print("  worker_listener.lua cached locally")
    else
        print("ERROR: Could not download worker_listener.lua!")
        return
    end
end

-- Deploy worker_listener.lua to each worker computer
print("Deploying listeners to " .. #allWorkerComputers .. " workers...")
local listenersDeployed = 0

for _, worker in ipairs(allWorkerComputers) do
    print("  Deploying to Worker " .. worker.id .. "...")
    
    -- Deploy via direct connection (requires ComputerCraft Advanced Computer)
    if worker.connected then
        local success = pcall(function()
            -- Write worker_listener.lua to the worker computer using correct API
            local handle = peripheral.call(worker.name, "fs.open", "worker_listener.lua", "w")
            if handle then
                peripheral.call(worker.name, "fs.write", handle, workerListenerContent)
                peripheral.call(worker.name, "fs.close", handle)
                
                -- Start worker_listener.lua on the worker (run in background)
                peripheral.call(worker.name, "shell.run", "bg", "worker_listener.lua")
                listenersDeployed = listenersDeployed + 1
                print("    SUCCESS: Listener deployed and started")
            else
                print("    ERROR: Could not open file handle on worker filesystem")
            end
        end)
        
        if not success then
            print("    ERROR: Direct deployment failed, trying network method...")
            -- Fallback: Try network deployment (requires worker to already be listening)
            rednet.send(worker.id, {
                type = "deploy_file",
                filename = "worker_listener.lua",
                content = workerListenerContent,
                execute = true
            }, "MODUS_DEPLOY")
        end
    end
end

print("Listeners deployed: " .. listenersDeployed .. "/" .. #allWorkerComputers)

-- Wait for workers to start their listeners and stabilize network
print("Waiting for workers to initialize listeners and stabilize network...")
sleep(8) -- Extended initialization time for proper network setup

-- Step 2: Discover ready worker computers
local workerComputers = {}
print("\n=== STEP 2: WORKER DISCOVERY ===")
print("Discovering ready worker computers...")

-- Ping for workers with active listeners  
print("Broadcasting discovery message to all workers on protocol " .. PROTOCOL)
rednet.broadcast({type = "discover", master_id = myID}, PROTOCOL)
local pingResponses = 0
local timeout = os.startTimer(20) -- Extended timeout for worker initialization and network stabilization
local discoveryStart = os.clock()

print("Listening for worker responses for 20 seconds...")

while true do
    local event, id, message, protocol = os.pullEvent()
    
    if event == "timer" and id == timeout then
        print("Discovery timeout reached after " .. math.floor(os.clock() - discoveryStart) .. " seconds")
        break
    elseif event == "rednet_message" then
        print("Received message from " .. (id or "unknown") .. " on protocol " .. (protocol or "none"))
        
        if protocol == PROTOCOL and message and message.type == "worker_available" then
            local found = false
            for _, worker in ipairs(workerComputers) do
                if worker.id == id then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(workerComputers, {id = id, network = true, connected = false})
                print("  Ready worker found: ID " .. id)
                pingResponses = pingResponses + 1
            else
                print("  Duplicate response from worker " .. id .. " (ignored)")
            end
        else
            print("  Message not a worker_available response (type: " .. (message and message.type or "nil") .. ")")
        end
    end
end

print("Worker Discovery Complete: " .. #workerComputers .. " workers found")
if #workerComputers > 0 then
    print("Available workers:")
    for i, worker in ipairs(workerComputers) do
        print("  [" .. i .. "] Worker ID " .. worker.id .. (worker.network and " (network)" or " (direct)"))
    end
end
print("")

-- Download required data files for master
local masterDataFiles = {
    "neural_net.lua",
    "meta_cognition.lua", 
    "introspection.lua",
    "philosophical_reasoning.lua",
    "natural_conversation.lua"
}

print("Preparing master data files...")
local dataLoc = {}
for _, df in ipairs(masterDataFiles) do
    local found = false
    if fs.exists(df) then
        found = true
        dataLoc[df] = df
    elseif myDrive and fs.exists(myDrive.."/"..df) then
        found = true 
        dataLoc[df] = myDrive.."/"..df
    end
    
    if not found then
        write("  Downloading " .. df .. "... ")
        local r = http.get(GITHUB .. df)
        if r then
            local targetPath = myDrive and (myDrive.."/"..df) or df
            local f = fs.open(targetPath, "w")
            f.write(r.readAll())
            f.close()
            r.close()
            dataLoc[df] = targetPath
            print("OK")
        else
            print("FAILED")
        end
    else
        print("  " .. df .. " OK")
    end
end

-- Generate worker-specific installer scripts
local function generateWorkerInstaller(role)
    local installer = [[
-- Worker ]] .. role.name .. [[ Installer (ID: ]] .. role.id .. [[)
-- Generated by Modular Cluster Installer
-- Role: ]] .. role.description .. [[

local PROTOCOL = "MODUS_INSTALLER"
local GITHUB = "]] .. GITHUB .. [["

print("===== WORKER ]] .. string.upper(role.name) .. [[ INSTALLER =====")
print("Role: ]] .. role.description .. [[")
print("Expected Drive: ]] .. role.drive .. [[")
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
            if path == "]] .. role.drive .. [[" then 
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
    print("ERROR: No disk found! Expected: ]] .. role.drive .. [[")
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

-- Download worker-specific data files
local requiredFiles = {]] .. textutils.serialize(role.files) .. [[}
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
local modules = {]] .. textutils.serialize(role.modules) .. [[}
print("Installing " .. #modules .. " worker modules...")
for _, module in ipairs(modules) do
    write("  " .. module .. "... ")
    local r = http.get(GITHUB .. module)
    if r then
        local filepath = fs.combine(diskPath, module)
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

-- Install worker startup and main files
print("Installing worker system files...")

-- Worker startup script
local WORKER_STARTUP = ]]
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
    installer = installer .. [[local f = fs.open(fs.combine(diskPath, "startup.lua"), "w")
f.write(]] .. textutils.serialize(startupCode) .. [[)
f.close()
print("  startup.lua installed")

-- Worker main script
local WORKER_MAIN = ]]
    local mainCode = [[
local PROTOCOL = "MODUS_CLUSTER"
local ROLE = "]] .. role.name .. [["
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
print("Worker ]] .. role.id .. [[ (]] .. role.name .. [[)")
print("Disk: " .. diskPath) 
print("Role: ]] .. role.description .. [[")
print("Status: Ready")

local mod
local ok, m = pcall(dofile, diskPath.."/worker_]] .. role.name .. [[.lua")
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
    installer = installer .. [[f = fs.open(fs.combine(diskPath, "worker_main.lua"), "w")
f.write(]] .. textutils.serialize(mainCode) .. [[)
f.close()
print("  worker_main.lua installed")

print("")
print("Worker ]] .. role.name .. [[ installation complete!")
print("Drive ]] .. role.drive .. [[ is ready for deployment.")

-- Signal completion to master
rednet.broadcast({type="install_complete", role="]] .. role.name .. [[", worker=os.getComputerID()}, PROTOCOL)

print("Waiting for reboot signal...")
local timeout = os.startTimer(30)
while true do
    local event, id, sid, msg = os.pullEvent()
    if event == "timer" and id == timeout then
        print("Timeout - rebooting anyway...")
        break
    elseif event == "rednet_message" and msg and msg.type == "reboot_now" then
        print("Reboot signal received")
        break
    end
end

os.reboot()
]]
    
    return installer
end

-- Install master files first
print("Installing master system...")

-- Download and install master_brain.lua
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
        return
    end
end

-- Enhanced master startup
local MASTER_STARTUP = [[
-- Enhanced Auto-startup for SuperAI master_brain.lua
-- Modular Cluster Version - Hub and Spoke Architecture

local LOG_FILE = "startup.log"

local function log(message)
    local timestamp = textutils.formatTime(os.time(), false)
    local logEntry = "[" .. timestamp .. "] " .. message
    print(logEntry)
    
    local file = fs.open(LOG_FILE, "a")
    if file then
        file.writeLine(logEntry)
        file.close()
    end
end

log("=== MODUS MODULAR CLUSTER STARTUP ===")
log("Master computer initializing...")

-- Find master_brain.lua
local function findMasterBrain()
    if fs.exists("master_brain.lua") then 
        return "master_brain.lua" 
    end
    
    local p = disk.getMountPath("back") 
    if p and fs.exists(p.."/master_brain.lua") then 
        return p.."/master_brain.lua" 
    end
    
    return nil
end

local masterPath = findMasterBrain()
if masterPath then 
    log("Master brain located: " .. masterPath)
    log("Starting SuperAI cluster...")
    
    local success, error = pcall(function()
        shell.run(masterPath)
    end)
    
    if success then
        log("Cluster startup successful!")
    else
        log("ERROR: " .. tostring(error))
    end
else 
    log("ERROR: master_brain.lua not found!")
end
]]

-- Install master startup
local f = fs.open("startup.lua", "w")
f.write(MASTER_STARTUP)
f.close()

if myDrive then
    fs.copy("master_brain.lua", myDrive.."/master_brain.lua") 
    f = fs.open(myDrive.."/startup.lua", "w")
    f.write(MASTER_STARTUP)
    f.close()
end
print("  Master system installed")

-- Configure disk3 as additional master drive
local masterDrives = {}
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= "back" then
        local path = disk.getMountPath(name)
        if path == "disk3" then
            table.insert(masterDrives, {name = name, path = path})
            f = fs.open(path.."/startup.lua", "w")
            f.write(MASTER_STARTUP)
            f.close()
            fs.copy("master_brain.lua", path.."/master_brain.lua")
            print("  Master drive disk3 configured")
        end
    end
end

print("")

-- Step 3: Deploy role-specific worker installers
print("\n=== STEP 3: ROLE-SPECIFIC DEPLOYMENT ===")
print("Deploying specialized worker installers...")
local installResults = {}

for i, role in ipairs(WORKER_ROLES) do
    print("Deploying " .. role.name .. " worker installer...")
    
    -- Generate installer script
    local installerScript = generateWorkerInstaller(role)
    
    -- Find target worker computer for this role (use sequential index, not role.id)
    local targetWorker = nil
    if #workerComputers >= i then
        targetWorker = workerComputers[i]
    end
    
    if targetWorker then
        print("  Target: Worker " .. targetWorker.id .. " (Role: " .. role.description .. ")")
        
        -- Send installer script to worker
        local deployMsg = {
            type = "deploy_installer",
            role = role.name,
            script = installerScript,
            master_id = myID
        }
        
        print("  Sending installer script (" .. string.len(installerScript) .. " bytes) to Worker " .. targetWorker.id)
        rednet.send(targetWorker.id, deployMsg, PROTOCOL)
        
        -- Wait for installation completion with detailed debugging
        local timeout = os.startTimer(120) -- Extended 120 second timeout for complex installations
        local installComplete = false
        local startTime = os.clock()
        
        print("  Waiting for installation completion...")
        
        while not installComplete do
            local event, id, message, protocol = os.pullEvent()
            
            if event == "timer" and id == timeout then
                print("  TIMEOUT: Installation did not complete after " .. math.floor(os.clock() - startTime) .. " seconds")
                print("  No response from Worker " .. targetWorker.id .. " for role " .. role.name)
                installResults[role.name] = {success = false, reason = "timeout"}
                break
            elseif event == "rednet_message" then
                print("  Received message from " .. (id or "unknown") .. " on protocol " .. (protocol or "none"))
                
                if protocol == PROTOCOL and id == targetWorker.id then
                    if message and message.type == "install_complete" and message.role == role.name then
                        print("  SUCCESS: Installation completed after " .. math.floor(os.clock() - startTime) .. " seconds")
                        installResults[role.name] = {success = true, worker = targetWorker.id}
                        installComplete = true
                    elseif message and message.type == "install_error" then
                        print("  ERROR: " .. (message.error or "unknown error"))
                        installResults[role.name] = {success = false, reason = message.error}
                        installComplete = true
                    else
                        print("  Unexpected message type: " .. (message and message.type or "nil"))
                    end
                else
                    print("  Message not for us (wrong protocol or sender)")
                end
            end
        end
    else
        print("  ERROR: No worker computer available for role " .. role.name)
        installResults[role.name] = {success = false, reason = "no_worker"}
    end
end

print("")

-- Summary and reboot coordination
print("Installation Summary:")
local successCount = 0
for roleName, result in pairs(installResults) do
    if result.success then
        print("  " .. roleName .. ": SUCCESS (Worker " .. result.worker .. ")")
        successCount = successCount + 1
    else
        print("  " .. roleName .. ": FAILED (" .. result.reason .. ")")
    end
end

print("")
print("Modular cluster deployment: " .. successCount .. "/" .. #WORKER_ROLES .. " workers installed")

if successCount > 0 then
    print("Coordinating cluster reboot...")
    
    -- Send reboot signal to all workers
    rednet.broadcast({type = "reboot_now", master_id = myID}, PROTOCOL)
    
    print("Workers rebooting...")
    sleep(3)
    
    print("Master rebooting...")
    sleep(1)
    os.reboot()
else
    print("ERROR: No workers successfully installed!")
    print("Check network connections and try again.")
end