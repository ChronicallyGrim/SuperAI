-- cluster_installer_v2.lua
-- Enhanced installer for SuperAI Unified Cluster
-- Distributes ALL AI modules across worker nodes

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"

print("=== SuperAI Unified Cluster Installer ===")
print("")

-- ============================================================================
-- DISCOVER CLUSTER HARDWARE
-- ============================================================================

-- Find master disk (back side)
local masterDisk = disk.getMountPath("back")
print("Master disk: " .. (masterDisk or "NONE"))

if not masterDisk then
    print("ERROR: No master disk found on 'back' side!")
    print("Please attach a disk to the back of the master computer.")
    return
end

-- Find worker drives and computers
local workerDrives = {}
local workerComputers = {}

local masterID = os.getComputerID()
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= "back" then
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

local MASTER_STARTUP = [[
-- Master startup
local function findDisk()
    local p = disk.getMountPath("back")
    if p and fs.exists(p.."/superai_cluster.lua") then return p end
    for i = 1, 10 do
        local try = "disk" .. (i > 1 and i or "")
        if fs.exists(try.."/superai_cluster.lua") then return try end
    end
end

local diskPath = findDisk()
if diskPath then
    -- Add disk to package path
    if package and package.path then
        package.path = package.path .. ";" .. diskPath .. "/?.lua"
    end

    -- Load and run cluster orchestrator
    local cluster = dofile(diskPath .. "/superai_cluster.lua")
    if cluster and cluster.run then
        cluster.run()
    else
        print("ERROR: Could not load superai_cluster.lua")
    end
else
    print("ERROR: superai_cluster.lua not found!")
end
]]

local WORKER_STARTUP = [[
-- Worker startup
local function findDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p and fs.exists(p.."/cluster_worker.lua") then return p end
        end
    end
end

local diskPath = findDisk()
if diskPath then
    -- Add disk to package path
    if package and package.path then
        package.path = package.path .. ";" .. diskPath .. "/?.lua"
    end

    -- Run worker
    shell.run(diskPath .. "/cluster_worker.lua")
else
    print("ERROR: cluster_worker.lua not found!")
end
]]

-- ============================================================================
-- INSTALL TO MASTER
-- ============================================================================

print("Installing master computer...")

-- Create master startup
local file = fs.open("startup.lua", "w")
file.write(MASTER_STARTUP)
file.close()

-- Copy to disk too
file = fs.open(masterDisk .. "/startup.lua", "w")
file.write(MASTER_STARTUP)
file.close()

print("  + startup.lua")
print("  + Master computer ready")
print("")

-- ============================================================================
-- INSTALL TO WORKERS
-- ============================================================================

print("Installing worker computers...")

for i, drive in ipairs(workerDrives) do
    write("  Worker " .. i .. " (" .. drive.path .. "): ")

    -- Create worker startup
    local file = fs.open(drive.path .. "/startup.lua", "w")
    file.write(WORKER_STARTUP)
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

print("")
print("Installation complete!")
print("")

-- ============================================================================
-- CLUSTER CONFIGURATION SUMMARY
-- ============================================================================

print("=== Cluster Configuration ===")
print("Master Computer: " .. os.getComputerID())
print("Worker Nodes: " .. #workerComputers)
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
