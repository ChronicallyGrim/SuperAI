-- cluster_installer_v2.lua
-- Enhanced installer for SuperAI Unified Cluster
-- Distributes ALL AI modules across worker nodes

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"

print("=== SuperAI Unified Cluster Installer ===")
print("")

-- ============================================================================
-- DISCOVER CLUSTER HARDWARE
-- ============================================================================

-- Find master disk - check back side first, then all other sides and peripherals
local masterDiskPeripheral = nil
local masterDisk = nil

-- Check back side first (preferred location)
if peripheral.getType("back") == "drive" then
    local p = disk.getMountPath("back")
    if p then
        masterDiskPeripheral = "back"
        masterDisk = p
    end
end

-- If not on back, search all sides and peripheral names
if not masterDisk then
    local sides = {"front", "left", "right", "top", "bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p then
                masterDiskPeripheral = side
                masterDisk = p
                break
            end
        end
    end
end

-- If still not found, check wired network peripherals
if not masterDisk then
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            local p = disk.getMountPath(name)
            if p then
                masterDiskPeripheral = name
                masterDisk = p
                break
            end
        end
    end
end

print("Master disk: " .. (masterDisk and (masterDisk .. " (via " .. masterDiskPeripheral .. ")") or "NONE"))

if not masterDisk then
    print("ERROR: No disk found!")
    print("Please attach a disk drive to the master computer.")
    return
end

-- Find worker drives and computers
local workerDrives = {}
local workerComputers = {}

local masterID = os.getComputerID()
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= masterDiskPeripheral then
        local path = disk.getMountPath(name)
        if path then
            table.insert(workerDrives, {name = name, path = path})
        end
    elseif pType == "computer" then
        local cid = peripheral.call(name, "getID")
        if cid ~= masterID then
            table.insert(workerComputers, {name = name, id = cid})
        end
    end
end

print("Worker drives: " .. #workerDrives)
print("Worker computers: " .. #workerComputers)
print("")

-- ============================================================================
-- MODULE LIST - ALL 40+ SUPERAI MODULES
-- ============================================================================

local ALL_MODULES = {
    -- Core modules (always needed)
    "superai_cluster.lua",
    "cluster_worker.lua",
    "utils.lua",

    -- AI modules (distributed to workers)
    "neural_net.lua",
    "large_neural_net.lua",
    "neural_trainer.lua",
    "tokenization.lua",
    "embeddings.lua",
    "word_vectors.lua",
    "attention.lua",
    "machine_learning.lua",
    "learning.lua",
    "autonomous_learning.lua",
    "auto_trainer.lua",
    "advanced_ai_trainer.lua",
    "exponential_trainer.lua",
    "easy_trainer.lua",
    "unified_trainer.lua",
    "training_diagnostic.lua",
    "conversation_memory.lua",
    "memory_search.lua",
    "memory_loader.lua",
    "personality.lua",
    "mood.lua",
    "user_data.lua",
    "response_generator.lua",
    "responses.lua",
    "markov.lua",
    "context_markov.lua",
    "sampling.lua",
    "knowledge_graph.lua",
    "dictionary.lua",
    "code_generator.lua",
    "context.lua",
    "rlhf.lua",
    "ai_vs_ai.lua",
    "advanced.lua"
}

-- ============================================================================
-- CHECK/DOWNLOAD MODULES
-- ============================================================================

print("Checking modules...")
local downloadedCount = 0
local existingCount = 0

for _, module in ipairs(ALL_MODULES) do
    local found = false

    if fs.exists(module) then
        found = true
        existingCount = existingCount + 1
    elseif masterDisk and fs.exists(masterDisk .. "/" .. module) then
        found = true
        existingCount = existingCount + 1
    end

    if not found then
        write("  Downloading " .. module .. "... ")
        local response = http.get(GITHUB .. module)
        if response then
            local content = response.readAll()
            response.close()

            -- Save to master disk
            local file = fs.open(masterDisk .. "/" .. module, "w")
            file.write(content)
            file.close()

            downloadedCount = downloadedCount + 1
            print("OK")
        else
            print("FAILED")
        end
    end
end

print("")
print("Existing modules: " .. existingCount)
print("Downloaded modules: " .. downloadedCount)
print("Total: " .. (existingCount + downloadedCount) .. "/" .. #ALL_MODULES)
print("")

-- ============================================================================
-- STARTUP SCRIPTS
-- ============================================================================

-- Universal startup: auto-detects whether this computer is master or worker
-- Master = has superai_cluster.lua on ANY attached disk (any side or wired modem)
-- Worker = all other computers
local UNIVERSAL_STARTUP = [[
-- SuperAI Universal Startup
-- Auto-detects master vs worker role

local function findDiskWithFile(filename)
    -- Check all sides first
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p and fs.exists(p.."/"..filename) then return p, side end
        end
    end
    -- Check wired network peripheral drives (e.g. drive_0, drive_1, disk_3, etc.)
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            local p = disk.getMountPath(name)
            if p and fs.exists(p.."/"..filename) then return p, name end
        end
    end
    return nil, nil
end

-- Determine role by searching ALL disk locations for the master marker file
-- Master = disk contains superai_cluster.lua
-- Worker = disk contains cluster_worker.lua (but NOT superai_cluster.lua)
local diskPath, diskName = findDiskWithFile("superai_cluster.lua")
local isMaster = diskPath ~= nil

if isMaster then
    print("Role: MASTER (disk on " .. tostring(diskName) .. ")")
    if package and package.path then
        package.path = package.path .. ";" .. diskPath .. "/?.lua"
    end
    local cluster = dofile(diskPath .. "/superai_cluster.lua")
    if cluster and cluster.run then
        cluster.run()
    else
        print("ERROR: Could not load superai_cluster.lua")
    end
else
    -- Worker role: find cluster_worker.lua on any disk
    diskPath, diskName = findDiskWithFile("cluster_worker.lua")
    if diskPath then
        print("Role: WORKER (disk on " .. tostring(diskName) .. ")")
        if package and package.path then
            package.path = package.path .. ";" .. diskPath .. "/?.lua"
        end
        shell.run(diskPath .. "/cluster_worker.lua")
    else
        print("ERROR: No disk found with cluster_worker.lua!")
        print("Make sure a disk with AI modules is attached.")
    end
end
]]

local MASTER_STARTUP = [[
-- Master startup
local function findDisk()
    -- Check back side first (preferred)
    if peripheral.getType("back") == "drive" then
        local p = disk.getMountPath("back")
        if p and fs.exists(p.."/superai_cluster.lua") then return p, "back" end
    end
    -- Check all sides
    local sides = {"front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p and fs.exists(p.."/superai_cluster.lua") then return p, side end
        end
    end
    -- Check wired peripheral drives
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            local p = disk.getMountPath(name)
            if p and fs.exists(p.."/superai_cluster.lua") then return p, name end
        end
    end
    return nil, nil
end

local diskPath, diskPeripheral = findDisk()
if diskPath then
    print("Master disk: " .. diskPath .. " (via " .. diskPeripheral .. ")")
    if package and package.path then
        package.path = package.path .. ";" .. diskPath .. "/?.lua"
    end
    local cluster = dofile(diskPath .. "/superai_cluster.lua")
    if cluster and cluster.run then
        cluster.run()
    else
        print("ERROR: Could not load superai_cluster.lua")
    end
else
    print("ERROR: superai_cluster.lua not found on any disk!")
    print("Make sure master disk is attached.")
end
]]

local WORKER_STARTUP = [[
-- Worker startup
local function findDisk()
    -- Check all sides
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p and fs.exists(p.."/cluster_worker.lua") then return p, side end
        end
    end
    -- Check wired network peripheral drives
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            local p = disk.getMountPath(name)
            if p and fs.exists(p.."/cluster_worker.lua") then return p, name end
        end
    end
    return nil, nil
end

local diskPath, diskPeripheral = findDisk()
if diskPath then
    print("Worker disk: " .. diskPath .. " (via " .. tostring(diskPeripheral) .. ")")
    if package and package.path then
        package.path = package.path .. ";" .. diskPath .. "/?.lua"
    end
    shell.run(diskPath .. "/cluster_worker.lua")
else
    print("ERROR: cluster_worker.lua not found on any disk!")
    print("Make sure worker disk with AI modules is attached.")
end
]]

-- ============================================================================
-- INSTALL TO MASTER
-- ============================================================================

print("Installing master computer...")

-- Write universal startup to computer root (detects master/worker role automatically)
local file = fs.open("startup.lua", "w")
file.write(UNIVERSAL_STARTUP)
file.close()

-- Copy universal startup to disk too (backup/auto-startup for CC disk feature)
file = fs.open(masterDisk .. "/startup.lua", "w")
file.write(UNIVERSAL_STARTUP)
file.close()

print("  + startup.lua (master)")
print("  + Master computer ready")
print("")

-- ============================================================================
-- INSTALL TO WORKERS
-- ============================================================================

print("Installing worker computers...")

for i, drive in ipairs(workerDrives) do
    write("  Worker " .. i .. " (disk at " .. drive.path .. " via " .. drive.name .. "): ")

    -- Write universal startup to disk (auto-detects role)
    local file = fs.open(drive.path .. "/startup.lua", "w")
    file.write(UNIVERSAL_STARTUP)
    file.close()

    -- Copy ALL modules to each worker disk
    local copiedCount = 0
    for _, module in ipairs(ALL_MODULES) do
        local source = nil
        if fs.exists(masterDisk .. "/" .. module) then
            source = masterDisk .. "/" .. module
        elseif fs.exists(module) then
            source = module
        end

        if source then
            local dest = drive.path .. "/" .. module
            if fs.exists(dest) then
                fs.delete(dest)
            end
            fs.copy(source, dest)
            copiedCount = copiedCount + 1
        end
    end

    print(copiedCount .. " modules copied")
end

-- ============================================================================
-- INSTALL STARTUP TO WORKER COMPUTERS (via rednet)
-- ============================================================================

if #workerComputers > 0 then
    print("")
    print("Setting up worker computer startups via rednet...")

    -- Open modems
    local modemOpened = false
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            rednet.open(name)
            modemOpened = true
        end
    end

    if modemOpened then
        -- Turn on each worker and send them the worker startup script
        for i, comp in ipairs(workerComputers) do
            write("  Worker computer " .. comp.id .. ": ")
            peripheral.call(comp.name, "turnOn")
            sleep(1)

            -- Send the universal startup script for them to install
            rednet.send(comp.id, {
                type = "install_startup",
                content = UNIVERSAL_STARTUP
            }, "SUPERAI_INSTALL")

            -- Wait for acknowledgment
            local deadline = os.clock() + 5
            local acked = false
            while os.clock() < deadline do
                local sid, msg = rednet.receive("SUPERAI_INSTALL", 0.5)
                if sid == comp.id and msg and msg.type == "startup_ack" then
                    acked = true
                    break
                end
            end

            print(acked and "startup installed" or "timeout (manual setup needed)")
        end
    else
        print("  No modems found - worker computers need manual startup setup")
        print("  Copy 'startup.lua' (worker version) to each worker computer root")
    end
end

print("")
print("Installation complete!")
print("")

-- ============================================================================
-- CLUSTER CONFIGURATION SUMMARY
-- ============================================================================

print("=== Cluster Configuration ===")
print("Master Computer ID: " .. os.getComputerID())
print("Master Disk: " .. masterDisk .. " (via " .. masterDiskPeripheral .. ")")
print("Worker Drives: " .. #workerDrives)
print("Worker Computers: " .. #workerComputers)
print("Total Modules: " .. (existingCount + downloadedCount))
print("")
print("AI Roles:")
print("  - Neural: Neural networks and deep learning")
print("  - Language: Tokenization, embeddings, word vectors")
print("  - Learning: Machine learning and training systems")
print("  - Memory: Conversation memory and search")
print("  - Personality: Personality and mood management")
print("  - Generation: Response and text generation")
print("  - Knowledge: Knowledge graph and dictionary")
print("  - Code: Code generation")
print("  - Context: Context-aware processing")
print("  - Advanced: RLHF, attention, sampling")
print("")
print("NOTE: If worker computers show 'startup.lua timeout',")
print("manually run on each worker: shell.run(disk_path..'/cluster_worker.lua')")
print("Then run cluster_worker_setup.lua on each worker to install startup.")
print("")

-- ============================================================================
-- REBOOT
-- ============================================================================

print("Rebooting cluster in 3 seconds...")
sleep(1)
print("3...")
sleep(1)
print("2...")
sleep(1)
print("1...")
sleep(1)

-- Reboot workers
for _, comp in ipairs(workerComputers) do
    peripheral.call(comp.name, "reboot")
end

-- Reboot master
os.reboot()
