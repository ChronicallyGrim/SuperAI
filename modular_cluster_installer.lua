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

-- Load dedicated worker installer files
local function loadWorkerInstaller(role)
    local installerFile = role.name .. "_worker_installer.lua"
    
    -- First try to read from local filesystem
    if fs.exists(installerFile) then
        print("  Loading local " .. installerFile)
        local f = fs.open(installerFile, "r")
        local content = f.readAll()
        f.close()
        return content
    end
    
    -- Fallback: download from GitHub
    print("  Downloading " .. installerFile .. " from GitHub...")
    local r = http.get(GITHUB .. installerFile)
    if r then
        local content = r.readAll()
        r.close()
        -- Cache locally
        local f = fs.open(installerFile, "w")
        f.write(content)
        f.close()
        print("  " .. installerFile .. " cached locally")
        return content
    else
        print("  ERROR: Could not download " .. installerFile)
        return nil
    end
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
    
    -- Load dedicated installer script
    local installerScript = loadWorkerInstaller(role)
    
    if not installerScript then
        print("  ERROR: Could not load installer for " .. role.name .. " worker")
        installResults[role.name] = {success = false, reason = "installer_load_failed"}
        goto continue
    end
    
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
    
    ::continue::
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