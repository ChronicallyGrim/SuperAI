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
    local top_mount = getMountPath(config.top)
    
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
-- CHECK FOR MAIN_LOGIC
-- ============================================================================
if not fs.exists("main_logic.lua") and not fs.exists("main_logic") then
    print("ERROR: main_logic not found on computer root!")
    print("Run NewInstaller2 to install SuperAI.")
    return
end

-- ============================================================================
-- LAUNCH SUPERAI
-- ============================================================================
print("Starting SuperAI...")
print("")

-- main_logic is a MODULE that returns M with M.run()
-- We need to require it and call run(), not shell.run() it
local main_logic = require("main_logic")
main_logic.run()
