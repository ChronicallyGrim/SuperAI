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
-- MODULE LIST - DIVIDED INTO 4 WORKER CATEGORIES
-- ============================================================================

-- Core files needed on master disk
local MASTER_MODULES = {
    "superai_cluster.lua",
    "utils.lua"
}

-- Core files needed on EVERY worker disk
local WORKER_CORE = {
    "cluster_worker.lua",
    "utils.lua"
}

-- Modules per worker role (4 workers, 4 categories)
local WORKER_MODULES = {
    -- Worker 1: Neural - neural networks and language representation
    neural = {
        "neural_net.lua",
        "large_neural_net.lua",
        "neural_trainer.lua",
        "tokenization.lua",
        "embeddings.lua",
        "word_vectors.lua",
        "attention.lua"
    },
    -- Worker 2: Learning - training and reinforcement learning
    learning = {
        "machine_learning.lua",
        "learning.lua",
        "autonomous_learning.lua",
        "auto_trainer.lua",
        "advanced_ai_trainer.lua",
        "exponential_trainer.lua",
        "easy_trainer.lua",
        "unified_trainer.lua",
        "training_diagnostic.lua",
        "rlhf.lua",
        "ai_vs_ai.lua"
    },
    -- Worker 3: Memory - memory, knowledge and context
    memory = {
        "conversation_memory.lua",
        "memory_search.lua",
        "memory_loader.lua",
        "knowledge_graph.lua",
        "dictionary.lua",
        "context.lua",
        "user_data.lua"
    },
    -- Worker 4: Generation - response generation, personality and mood
    generation = {
        "response_generator.lua",
        "responses.lua",
        "markov.lua",
        "context_markov.lua",
        "sampling.lua",
        "personality.lua",
        "mood.lua",
        "advanced.lua",
        "code_generator.lua"
    }
}

-- Ordered role list (worker index -> role name)
local WORKER_ROLES = {"neural", "learning", "memory", "generation"}

-- Flatten all unique modules for download purposes
local ALL_MODULES = {}
local _seen = {}
for _, m in ipairs(MASTER_MODULES) do
    if not _seen[m] then _seen[m] = true; table.insert(ALL_MODULES, m) end
end
for _, m in ipairs(WORKER_CORE) do
    if not _seen[m] then _seen[m] = true; table.insert(ALL_MODULES, m) end
end
for _, mods in pairs(WORKER_MODULES) do
    for _, m in ipairs(mods) do
        if not _seen[m] then _seen[m] = true; table.insert(ALL_MODULES, m) end
    end
end

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
print("(Each worker only gets modules for its assigned role)")
print("")

for i, drive in ipairs(workerDrives) do
    local role = WORKER_ROLES[i]
    if not role then
        print("  Worker " .. i .. ": No role assigned (only 4 roles defined). Skipping.")
    else
        write("  Worker " .. i .. " [" .. role:upper() .. "] (disk at " .. drive.path .. " via " .. drive.name .. "): ")

        -- Write universal startup to disk (auto-detects role)
        local file = fs.open(drive.path .. "/startup.lua", "w")
        file.write(UNIVERSAL_STARTUP)
        file.close()

        -- Write worker role config so this disk knows its role
        file = fs.open(drive.path .. "/worker_role.txt", "w")
        file.write(role)
        file.close()

        -- Copy core worker files + role-specific modules only
        local copiedCount = 0
        local modulesToCopy = {}
        for _, m in ipairs(WORKER_CORE) do table.insert(modulesToCopy, m) end
        for _, m in ipairs(WORKER_MODULES[role]) do table.insert(modulesToCopy, m) end

        for _, module in ipairs(modulesToCopy) do
            local source = nil
            if fs.exists(masterDisk .. "/" .. module) then
                source = masterDisk .. "/" .. module
            elseif fs.exists(module) then
                source = module
            end

            if source then
                local dest = drive.path .. "/" .. module
                if fs.exists(dest) then fs.delete(dest) end
                fs.copy(source, dest)
                copiedCount = copiedCount + 1
            end
        end

        print(copiedCount .. " modules copied (" .. #WORKER_MODULES[role] .. " role modules + " .. #WORKER_CORE .. " core)")
    end
end

-- ============================================================================
-- INSTALL STARTUP TO WORKER COMPUTERS (via rednet)
-- ============================================================================

if #workerComputers > 0 then
    print("")
    print("Worker computers found: " .. #workerComputers)
    print("IMPORTANT: Workers need startup.lua on their computer root.")
    print("The installer cannot write directly to remote computer roots.")
    print("")
    print("Each worker disk already has startup.lua (UNIVERSAL_STARTUP) on it.")
    print("You have two options for each worker computer:")
    print("  Option A: Go to each worker and run:")
    print("    shell.run('/disk/cluster_worker_setup.lua')")
    print("  Option B: Workers with startup.lua already on root will auto-connect.")
    print("")

    -- Try to turn on workers anyway so they can start if already set up
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            rednet.open(name)
        end
    end

    for i, comp in ipairs(workerComputers) do
        print("  Turning on worker " .. comp.id .. "...")
        peripheral.call(comp.name, "turnOn")
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
print("Worker Roles (4 workers):")
print("  Worker 1 [NEURAL]:     neural_net, large_neural_net, neural_trainer,")
print("                         tokenization, embeddings, word_vectors, attention")
print("  Worker 2 [LEARNING]:   machine_learning, learning, autonomous_learning,")
print("                         auto_trainer, advanced_ai_trainer, exponential_trainer,")
print("                         easy_trainer, unified_trainer, training_diagnostic,")
print("                         rlhf, ai_vs_ai")
print("  Worker 3 [MEMORY]:     conversation_memory, memory_search, memory_loader,")
print("                         knowledge_graph, dictionary, context, user_data")
print("  Worker 4 [GENERATION]: response_generator, responses, markov, context_markov,")
print("                         sampling, personality, mood, advanced, code_generator")
print("")
print("WORKER SETUP REQUIRED (one-time per worker):")
print("  If workers are failing, go to each worker computer and run:")
print("  > shell.run('/disk/cluster_worker_setup.lua')")
print("  This installs startup.lua to the worker's root so it auto-starts.")
print("  After running once, workers will auto-connect on every reboot.")
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
