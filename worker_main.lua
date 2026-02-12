-- worker_main.lua
-- Worker main controller for MODUS cluster
-- Searches all sides for disk and handles role assignment

local PROTOCOL = "MODUS_CLUSTER"
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p then return p end
        end
    end
    return ""
end
local diskPath = findMyDisk()

for _, n in ipairs(peripheral.getNames()) do if peripheral.getType(n) == "modem" then rednet.open(n) end end
term.clear() term.setCursorPos(1,1)
print("Worker " .. os.getComputerID()) print("Disk: " .. diskPath) print("Waiting...")

local ROLE, mod
while true do
    local sid, msg = rednet.receive(PROTOCOL, 2)
    if msg and msg.type == "assign_role" then
        ROLE = msg.role
        local ok, m = pcall(dofile, diskPath.."/worker_"..ROLE..".lua")
        mod = ok and m or nil
        print("Role: " .. ROLE .. " = " .. (mod and "OK" or "FAIL"))
        if not ok then print(tostring(m)) end
        rednet.send(sid, {type="role_ack", role=ROLE, ok=mod~=nil}, PROTOCOL)
    elseif msg and msg.type == "task" and mod then
        local fn = mod[msg.task]
        local ok, res = pcall(function() return fn and fn(msg.data) or {error="?"} end)
        rednet.send(sid, {type="result", taskId=msg.taskId, result=ok and res or {error=tostring(res)}}, PROTOCOL)
    elseif msg and msg.type == "shutdown" then break end
end
