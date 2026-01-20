-- startup
-- Auto-starts SuperAI from computer root on boot

print("SuperAI Auto-Startup")
print("")

-- Load drive configuration from TOP drive (for RAM/RAID access)
-- First try to find which side the TOP drive is on
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
        if fs.exists(side .. "/drive_config.lua") then
            -- Temporarily add this drive to package path
            package.path = side .. "/?.lua;" .. package.path
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
    -- Check if TOP drive exists
    if not peripheral.isPresent(config.top) then
        print("WARNING: TOP drive '" .. config.top .. "' not found!")
        print("RAM/RAID features may not work properly.")
        print("")
    else
        print("TOP drive found: " .. config.top)
        -- Add TOP drive to package path so main_logic can require modules from it
        package.path = config.top .. "/?.lua;" .. package.path
    end
end

-- Check if main_logic exists on COMPUTER ROOT
if not fs.exists("main_logic.lua") and not fs.exists("main_logic") then
    print("ERROR: main_logic not found on computer root!")
    print("Run NewInstaller2 to install SuperAI.")
    return
end

-- Launch SuperAI from computer root
print("Starting SuperAI...")
print("")

shell.run("main_logic")
