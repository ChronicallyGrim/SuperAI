-- Auto-startup for enhanced master_brain.lua
-- This runs automatically after reboot on the advanced computer

local function findMasterBrain()
    -- Try master_brain.lua in current directory first (primary location - same as startup)
    if fs.exists("master_brain.lua") then 
        return "master_brain.lua" 
    end
    
    -- Try disk locations (backup removed to save space)
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
    print("Auto-startup enabled - will run on every reboot")
    shell.run(masterPath)
else 
    print("ERROR: master_brain.lua not found!")
    print("Please run cluster_installer.lua to install the system.")
    print("Searched locations: master_brain.lua, disk locations")
end
