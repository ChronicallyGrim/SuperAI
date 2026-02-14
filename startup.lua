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
