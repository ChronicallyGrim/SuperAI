-- startup.lua
-- Auto-starts SuperAI from computer root on boot

print("SuperAI Auto-Startup")
print("")

-- ============================================================================
-- HELPER: Convert peripheral name to mount path
-- ============================================================================
local function getMountPath(peripheral_name)
    if not peripheral_name then return nil end
    if not peripheral.isPresent(peripheral_name) then return nil end
    return disk.getMountPath(peripheral_name)
end

-- ============================================================================
-- LOAD DRIVE CONFIGURATION
-- ============================================================================
local config = nil
local config_found = false
local top_mount = nil  -- Will hold the mount path for TOP drive

-- Try to load from computer root first (installer puts it there)
if fs.exists("drive_config.lua") then
    config = require("drive_config")
    config_found = true
else
    -- Try to find it on a peripheral drive
    local sides = {"top", "bottom", "left", "right", "front", "back"}
    for _, side in ipairs(sides) do
        local mount_path = getMountPath(side)
        if mount_path and fs.exists(mount_path .. "/drive_config.lua") then
            package.path = mount_path .. "/?.lua;" .. package.path
            config = require("drive_config")
            config_found = true
            break
        end
    end
end

if not config_found or not config or not config.top then
    print("WARNING: Could not load drive configuration!")
    print("SuperAI will run with limited functionality.")
    print("")
else
    -- Get the MOUNT PATH for the TOP drive (not peripheral name!)
    top_mount = getMountPath(config.top)
    
    if not top_mount then
        print("WARNING: TOP drive '" .. config.top .. "' not found!")
        print("RAM/RAID features may not work properly.")
        print("")
    else
        print("TOP drive found: " .. config.top .. " -> " .. top_mount)
        -- Add TOP drive's MOUNT PATH to package path
        package.path = top_mount .. "/?.lua;" .. package.path
    end
end

-- ============================================================================
-- CHECK FOR MASTER_BRAIN
-- ============================================================================

-- master_brain.lua should be on the TOP drive, not computer root
local master_brain_path = nil

-- First check TOP drive
if top_mount and fs.exists(top_mount .. "/master_brain.lua") then
    master_brain_path = top_mount .. "/master_brain.lua"
    print("Loading master_brain from: " .. master_brain_path)
-- Fallback: check computer root
elseif fs.exists("master_brain.lua") then
    master_brain_path = "master_brain.lua"
    print("Loading master_brain from computer root")
-- Fallback to main_logic for backwards compatibility
elseif fs.exists("main_logic.lua") then
    master_brain_path = "main_logic.lua"
    print("Loading main_logic from computer root (fallback)")
else
    print("ERROR: master_brain.lua not found!")
    if top_mount then
        print("Checked: " .. top_mount .. "/master_brain.lua")
    end
    print("Checked: computer root for master_brain.lua and main_logic.lua")
    print("Run NewInstaller2 to install SuperAI.")
    return
end

-- ============================================================================
-- LAUNCH SUPERAI
-- ============================================================================
print("Starting SuperAI...")
print("")

-- Load the AI system with error handling
local success, ai_system = pcall(function()
    if master_brain_path == "main_logic.lua" then
        local main_logic = require("main_logic")
        return main_logic
    else
        -- master_brain.lua runs automatically when loaded, so we just need to require it
        require("master_brain")
        return nil -- master_brain runs immediately
    end
end)

if not success then
    print("ERROR loading AI system: " .. tostring(ai_system))
    print("This usually means missing dependencies.")
    print("Try running the installer or check that all AI modules are present.")
    return
end

-- Only run if we got a module back (main_logic case)
if ai_system and ai_system.run then
    ai_system.run()
end
