-- disk_map.lua
-- Shows all disk drive peripheral names and their mount paths

print("=== DISK DRIVE MAP ===")
print("")

for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "drive" then
        local mount_path = disk.getMountPath(name)
        if mount_path then
            local free = fs.getFreeSpace(mount_path)
            local free_kb = math.floor(free / 1024)
            print(name .. " -> " .. mount_path .. " (" .. free_kb .. "KB free)")
        else
            print(name .. " -> NO DISK INSERTED")
        end
    end
end
