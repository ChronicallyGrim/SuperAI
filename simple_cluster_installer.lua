-- simple_cluster_installer.lua
-- Simplified installer that deploys dedicated worker installer files
-- Master -> Sends real installer files -> Workers run them -> Reboot -> Ready

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"
local PROTOCOL = "MODUS_INSTALLER"

print("===== SIMPLE CLUSTER INSTALLER =====")
print("Deploying dedicated worker installer files to worker computers")
print("")

-- Initialize rednet
for _, name in ipairs(peripheral.getNames()) do 
    if peripheral.getType(name) == "modem" then 
        rednet.open(name) 
    end 
end

local myID = os.getComputerID()
print("Master Computer ID: " .. myID)

-- Define worker installer files mapping
local WORKER_INSTALLERS = {
    {file = "language_worker_installer.lua", role = "language", description = "Language Processing Worker"},
    {file = "memory_worker_installer.lua", role = "memory", description = "Memory Management Worker"},
    {file = "response_worker_installer.lua", role = "response", description = "Response Generation Worker"},
    {file = "personality_worker_installer.lua", role = "personality", description = "Personality & Behavior Worker"}
}

-- Step 1: Find and deploy to worker computers
print("\n=== STEP 1: DISCOVERING WORKER COMPUTERS ===")
local workerComputers = {}

-- Find worker computers via direct connection
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "computer" then
        local cid = peripheral.call(name, "getID")
        if cid ~= myID then
            table.insert(workerComputers, {name = name, id = cid})
            print("  Found worker computer: ID " .. cid .. " (" .. name .. ")")
        end
    end
end

if #workerComputers == 0 then
    print("ERROR: No worker computers found!")
    return
end

print("Found " .. #workerComputers .. " worker computers")
print("")

-- Step 2: Deploy installer files to each worker
print("=== STEP 2: DEPLOYING INSTALLER FILES ===")

for i, installer in ipairs(WORKER_INSTALLERS) do
    if workerComputers[i] then
        local worker = workerComputers[i]
        print("Deploying " .. installer.file .. " to Worker " .. worker.id .. " (" .. installer.description .. ")")
        
        -- Get installer file content
        local installerContent = nil
        
        -- Try local file first
        if fs.exists(installer.file) then
            print("  Reading local " .. installer.file)
            local f = fs.open(installer.file, "r")
            installerContent = f.readAll()
            f.close()
        else
            print("  Downloading " .. installer.file .. " from GitHub...")
            local r = http.get(GITHUB .. installer.file)
            if r then
                installerContent = r.readAll()
                r.close()
                -- Cache locally
                local f = fs.open(installer.file, "w")
                f.write(installerContent)
                f.close()
                print("  Cached " .. installer.file .. " locally")
            else
                print("  ERROR: Could not download " .. installer.file)
                installerContent = nil
            end
        end
        
        if installerContent then
            -- Deploy directly to worker computer using peripheral API
            local success = pcall(function()
                local handle = peripheral.call(worker.name, "fs.open", installer.file, "w")
                if handle then
                    peripheral.call(worker.name, "fs.write", handle, installerContent)
                    peripheral.call(worker.name, "fs.close", handle)
                    print("  SUCCESS: " .. installer.file .. " deployed to Worker " .. worker.id)
                    
                    -- Run the installer on the worker computer
                    print("  Starting " .. installer.file .. " on Worker " .. worker.id)
                    peripheral.call(worker.name, "shell.run", installer.file)
                    
                else
                    print("  ERROR: Could not open file handle on Worker " .. worker.id)
                end
            end)
            
            if not success then
                print("  ERROR: Direct deployment failed to Worker " .. worker.id)
            end
        end
        
        print("")
    else
        print("No worker available for " .. installer.description)
    end
end

-- Step 3: Install master files
print("=== STEP 3: INSTALLING MASTER SYSTEM ===")

-- Download and install master_brain.lua if needed
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
    end
end

-- Master startup script
local MASTER_STARTUP = [[
-- Enhanced Auto-startup for SuperAI master_brain.lua

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

log("=== SIMPLE CLUSTER STARTUP ===")
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

-- Also install on disk3 if it exists
local myDrive = disk.getMountPath("back")
if myDrive then
    fs.copy("master_brain.lua", myDrive.."/master_brain.lua") 
    f = fs.open(myDrive.."/startup.lua", "w")
    f.write(MASTER_STARTUP)
    f.close()
end

-- Configure disk3 as master drive
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= "back" then
        local path = disk.getMountPath(name)
        if path == "disk3" then
            f = fs.open(path.."/startup.lua", "w")
            f.write(MASTER_STARTUP)
            f.close()
            fs.copy("master_brain.lua", path.."/master_brain.lua")
            print("  Master drive disk3 configured")
        end
    end
end

print("  Master system installed")
print("")

print("=== DEPLOYMENT COMPLETE ===")
print("Workers are installing their specific files...")
print("All systems will reboot automatically when installation completes.")
print("")
print("Master rebooting in 10 seconds...")
sleep(10)
os.reboot()