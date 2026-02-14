-- Startup Debug Tool for SuperAI
-- Run this script to diagnose startup issues

print("=== SuperAI Startup Diagnostic Tool ===")
print("")

-- Check if startup.lua exists
if fs.exists("startup.lua") then
    print("✓ startup.lua exists")
else
    print("✗ startup.lua NOT FOUND - This is the problem!")
    print("  Run cluster_installer.lua to create startup.lua")
    return
end

-- Check if startup.log exists
if fs.exists("startup.log") then
    print("✓ startup.log exists - checking contents...")
    print("")
    print("=== Recent Startup Log ===")
    local file = fs.open("startup.log", "r")
    if file then
        local lines = {}
        local line = file.readLine()
        while line do
            table.insert(lines, line)
            line = file.readLine()
        end
        file.close()
        
        -- Show last 20 lines
        local start = math.max(1, #lines - 19)
        for i = start, #lines do
            print(lines[i])
        end
    end
    print("=== End of Log ===")
    print("")
else
    print("! startup.log not found - startup may never have run")
    print("")
end

-- Check for master_brain.lua
print("=== Checking for master_brain.lua ===")
if fs.exists("master_brain.lua") then
    print("✓ master_brain.lua found in current directory")
else
    print("! master_brain.lua not found in current directory")
    
    -- Check disk locations
    local p = disk.getMountPath("back")
    if p and fs.exists(p.."/master_brain.lua") then
        print("✓ master_brain.lua found on back disk: " .. p)
    else
        print("! master_brain.lua not found on back disk")
    end
    
    -- Check numbered disks
    local found = false
    for i = 1, 10 do
        local try = "disk" .. (i > 1 and i or "")
        if fs.exists(try.."/master_brain.lua") then
            print("✓ master_brain.lua found on " .. try)
            found = true
        end
    end
    
    if not found then
        print("✗ master_brain.lua not found anywhere!")
        print("  Run cluster_installer.lua to install the system")
    end
end

print("")
print("=== System Information ===")
print("Computer ID: " .. os.getComputerID())
print("Computer Label: " .. (os.getComputerLabel() or "UNLABELED"))

-- Check disk mounts
print("Available disks:")
local hasDisks = false
for _, side in ipairs({"back","front","left","right","top","bottom"}) do
    if peripheral.getType(side) == "drive" then
        local path = disk.getMountPath(side)
        print("  " .. side .. ": " .. (path or "UNMOUNTED"))
        hasDisks = true
    end
end

if not hasDisks then
    print("  No disks detected!")
end

print("")
print("=== Troubleshooting Tips ===")
print("1. If startup.lua doesn't exist, run: cluster_installer.lua")
print("2. If master_brain.lua is missing, run: cluster_installer.lua")
print("3. Check startup.log for detailed error messages")
print("4. Make sure disks are properly connected")
print("5. Try running startup.lua manually to see errors")
print("")
print("=== Manual Startup Test ===")
print("To test startup manually, run: startup")
print("To reinstall everything, run: cluster_installer")