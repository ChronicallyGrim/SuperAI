-- simple_worker_installer.lua
-- Basic installer that deploys worker_listener.lua to all connected peripherals except "back"
-- Simple solution to cluster installation problems

print("===== SIMPLE WORKER INSTALLER =====")
print("Installing worker_listener.lua to all peripherals except 'back'")
print("")

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"

-- Get worker_listener.lua content
local workerListenerContent = nil
if fs.exists("worker_listener.lua") then
    print("Reading local worker_listener.lua...")
    local f = fs.open("worker_listener.lua", "r")
    workerListenerContent = f.readAll()
    f.close()
else
    print("Downloading worker_listener.lua from GitHub...")
    local r = http.get(GITHUB .. "worker_listener.lua")
    if r then
        workerListenerContent = r.readAll()
        r.close()
        -- Save local copy
        local f = fs.open("worker_listener.lua", "w")
        f.write(workerListenerContent)
        f.close()
        print("  worker_listener.lua cached locally")
    else
        print("ERROR: Could not download worker_listener.lua!")
        return
    end
end

-- Find all connected peripherals except "back"
local targetPeripherals = {}
for _, name in ipairs(peripheral.getNames()) do
    if name ~= "back" then
        local pType = peripheral.getType(name)
        print("Found peripheral: " .. name .. " (type: " .. pType .. ")")
        
        -- Check if it's a computer or drive we can install to
        if pType == "computer" or pType == "drive" then
            table.insert(targetPeripherals, {name = name, type = pType})
        end
    end
end

print("")
print("Target peripherals for installation: " .. #targetPeripherals)

if #targetPeripherals == 0 then
    print("ERROR: No suitable peripherals found!")
    print("Make sure you have computers or drives connected (not on 'back' side)")
    return
end

-- Install worker_listener.lua to each target peripheral
local installed = 0
for _, peripheral in ipairs(targetPeripherals) do
    print("Installing to " .. peripheral.name .. " (" .. peripheral.type .. ")...")
    
    local success = false
    
    if peripheral.type == "computer" then
        -- Install directly to computer filesystem
        local ok = pcall(function()
            local handle = peripheral.call(peripheral.name, "fs", "open", "worker_listener.lua", "w")
            if handle then
                peripheral.call(peripheral.name, "fs", "write", handle, workerListenerContent)
                peripheral.call(peripheral.name, "fs", "close", handle)
                success = true
                print("  SUCCESS: Installed to computer " .. peripheral.name)
            else
                print("  ERROR: Could not create file on computer " .. peripheral.name)
            end
        end)
        if not ok then
            print("  ERROR: Failed to access computer " .. peripheral.name)
        end
        
    elseif peripheral.type == "drive" then
        -- Install to drive filesystem
        local diskPath = disk.getMountPath(peripheral.name)
        if diskPath then
            local filePath = fs.combine(diskPath, "worker_listener.lua")
            if not fs.isReadOnly(diskPath) then
                local f = fs.open(filePath, "w")
                if f then
                    f.write(workerListenerContent)
                    f.close()
                    success = true
                    print("  SUCCESS: Installed to drive " .. diskPath)
                else
                    print("  ERROR: Could not write to drive " .. diskPath)
                end
            else
                print("  ERROR: Drive " .. diskPath .. " is read-only")
            end
        else
            print("  ERROR: Drive " .. peripheral.name .. " not mounted")
        end
    end
    
    if success then
        installed = installed + 1
    end
end

print("")
print("Installation Summary:")
print("  Total peripherals: " .. #targetPeripherals)
print("  Successfully installed: " .. installed)
print("  Failed: " .. (#targetPeripherals - installed))

if installed > 0 then
    print("")
    print("Installation complete!")
    print("worker_listener.lua has been deployed to " .. installed .. " peripheral(s)")
    print("Workers should now be ready to receive further deployment commands")
else
    print("")
    print("ERROR: No installations succeeded!")
    print("Check peripheral connections and permissions")
end