-- startup
-- Auto-starts SuperAI from TOP drive on boot

print("SuperAI Auto-Startup")
print("")

-- Load drive configuration
local config = require("drive_config")

if not config.top then
    print("ERROR: No TOP drive configured!")
    print("SuperAI cannot start without TOP drive.")
    return
end

-- Check if TOP drive exists
if not peripheral.isPresent(config.top) then
    print("ERROR: TOP drive '" .. config.top .. "' not found!")
    print("Check your drive configuration.")
    return
end

-- Check if main_logic exists on TOP drive
local main_logic_path = config.top .. "/main_logic"
if not fs.exists(main_logic_path) then
    print("ERROR: main_logic not found on TOP drive!")
    print("Run NewInstaller2 to install SuperAI.")
    return
end

-- Launch SuperAI
print("Starting SuperAI from " .. config.top .. "...")
print("")

shell.run(main_logic_path)
