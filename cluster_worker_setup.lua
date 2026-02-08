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

-- Write universal startup to computer root (same logic as master uses)
local STARTUP = [[
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
