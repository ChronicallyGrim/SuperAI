-- cluster_worker_setup.lua
-- Run this on a worker computer to install the startup script
-- This only needs to be run once per worker computer

print("=== SuperAI Worker Setup ===")
print("")

-- Find the disk with cluster modules
local diskPath = nil
local diskPeripheral = nil

local sides = {"back","front","left","right","top","bottom"}
for _, side in ipairs(sides) do
    if peripheral.getType(side) == "drive" then
        local p = disk.getMountPath(side)
        if p and fs.exists(p.."/cluster_worker.lua") then
            diskPath = p
            diskPeripheral = side
            break
        end
    end
end

if not diskPath then
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            local p = disk.getMountPath(name)
            if p and fs.exists(p.."/cluster_worker.lua") then
                diskPath = p
                diskPeripheral = name
                break
            end
        end
    end
end

if not diskPath then
    print("ERROR: No disk with cluster_worker.lua found!")
    print("Make sure the worker disk is attached.")
    return
end

print("Found disk: " .. diskPath .. " (via " .. diskPeripheral .. ")")
print("")

-- Write startup.lua to computer root
local STARTUP = [[
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

print("Installing startup.lua to computer root...")
local f = fs.open("startup.lua", "w")
f.write(STARTUP)
f.close()
print("Done!")
print("")
print("This computer will now boot as a cluster worker.")
print("Rebooting in 2 seconds...")
sleep(2)
os.reboot()
