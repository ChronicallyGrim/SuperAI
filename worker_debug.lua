-- worker_debug.lua
-- Put this on a worker disk to see what's happening
-- Run from master: copy to worker disk, then reboot worker

print("=== WORKER DEBUG ===")
print("Computer ID: " .. os.getComputerID())
print("")

print("=== ALL PERIPHERALS ===")
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    print("  " .. name .. " = " .. pType)
end
print("")

print("=== CHECKING SIDES ===")
local sides = {"top", "bottom", "left", "right", "front", "back"}
for _, side in ipairs(sides) do
    if peripheral.isPresent(side) then
        print("  " .. side .. " = " .. peripheral.getType(side))
    else
        print("  " .. side .. " = (empty)")
    end
end
print("")

print("=== LOOKING FOR DISK ===")
local diskPath = nil
for _, side in ipairs(sides) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "drive" then
        local path = disk.getMountPath(side)
        print("  Found drive on " .. side .. " -> " .. tostring(path))
        if path then
            diskPath = path
            print("  Files on disk:")
            for _, f in ipairs(fs.list(path)) do
                print("    " .. f)
            end
        end
    end
end
print("")

print("=== LOOKING FOR MODEM ===")
for _, side in ipairs(sides) do
    if peripheral.isPresent(side) then
        local pType = peripheral.getType(side)
        if pType == "modem" or pType:find("modem") then
            print("  Found modem on " .. side)
            rednet.open(side)
            print("  Opened rednet on " .. side)
        end
    end
end

-- Also check for modems in peripheral names (wired)
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "modem" or pType:find("modem") then
        print("  Found modem: " .. name)
        pcall(rednet.open, name)
    end
end
print("")

print("=== REDNET TEST ===")
print("Waiting for any message (10 sec)...")
local senderId, msg, protocol = rednet.receive(nil, 10)
if senderId then
    print("Got message from " .. senderId)
    print("Protocol: " .. tostring(protocol))
    print("Message: " .. tostring(msg))
else
    print("No message received (timeout)")
end

print("")
print("=== DEBUG COMPLETE ===")
print("Press any key...")
os.pullEvent("key")
