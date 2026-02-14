-- worker_listener.lua
-- Runs on worker computers to receive and execute remote installers
-- Part of the modular cluster installer system

local PROTOCOL = "MODUS_INSTALLER"

print("===== MODUS WORKER LISTENER =====")
print("Waiting for installer deployment...")
print("Worker ID: " .. os.getComputerID())
print("")

-- Initialize networking
for _, name in ipairs(peripheral.getNames()) do 
    if peripheral.getType(name) == "modem" then 
        rednet.open(name) 
        print("Network ready: " .. name)
    end 
end

-- Respond to discovery pings
local function handleDiscovery()
    while true do
        local senderID, message, protocol = rednet.receive(PROTOCOL, 1)
        if message and message.type == "discover" then
            rednet.send(senderID, {type = "worker_available", id = os.getComputerID()}, PROTOCOL)
            print("Responded to discovery from master " .. senderID)
        elseif message and message.type == "deploy_installer" then
            print("")
            print("Installer received for role: " .. message.role)
            print("From master: " .. message.master_id)
            
            -- Write installer to temporary file
            local tempFile = "temp_installer.lua"
            local f = fs.open(tempFile, "w")
            f.write(message.script)
            f.close()
            
            -- Execute installer
            print("Executing installer...")
            local success, error = pcall(function()
                shell.run(tempFile)
            end)
            
            -- Clean up temp file
            if fs.exists(tempFile) then
                fs.delete(tempFile)
            end
            
            if success then
                print("Installer completed successfully!")
                rednet.send(message.master_id, {
                    type = "install_complete", 
                    role = message.role, 
                    worker = os.getComputerID()
                }, PROTOCOL)
            else
                print("Installer failed: " .. tostring(error))
                rednet.send(message.master_id, {
                    type = "install_error",
                    role = message.role,
                    worker = os.getComputerID(),
                    error = tostring(error)
                }, PROTOCOL)
            end
            
            return -- Exit after handling installer
        end
    end
end

-- Main listener loop
print("Listening for deployment...")
handleDiscovery()