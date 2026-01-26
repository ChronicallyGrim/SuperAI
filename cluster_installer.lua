-- cluster_installer.lua
-- Single installer: writes to all drives, reboots everything

local PROTOCOL = "MODUS_CLUSTER"

print("===== MODUS CLUSTER INSTALLER =====")
print("")

-- Find all drives and computers
local myDrive = disk.getMountPath("back")
local workerDrives = {}
local workerComputers = {}

for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= "back" then
        local path = disk.getMountPath(name)
        if path then
            table.insert(workerDrives, {name = name, path = path})
        end
    elseif pType == "computer" then
        table.insert(workerComputers, {name = name, id = peripheral.call(name, "getID")})
    end
end

print("Master disk: " .. (myDrive or "NONE"))
print("Worker drives: " .. #workerDrives)
print("Worker computers: " .. #workerComputers)
print("")

-- ============ FILE CONTENTS ============

local WORKER_STARTUP = [[shell.run(disk.getMountPath("back").."/worker_main.lua")]]

local WORKER_MAIN = [[
local PROTOCOL = "MODUS_CLUSTER"
local diskPath = disk.getMountPath("back")
for _, n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n) == "modem" then rednet.open(n) end
end
print("Worker " .. os.getComputerID() .. " ready")

local ROLE, roleModule
while true do
    local sid, msg = rednet.receive(PROTOCOL, 2)
    if msg and msg.type == "assign_role" then
        ROLE = msg.role
        local ok, m = pcall(dofile, diskPath.."/worker_"..ROLE..".lua")
        roleModule = ok and m or nil
        print("Role: " .. ROLE .. (roleModule and " OK" or " FAIL"))
        rednet.send(sid, {type="role_ack", role=ROLE, ok=roleModule~=nil}, PROTOCOL)
    elseif msg and msg.type == "task" and roleModule then
        local fn = roleModule[msg.task]
        local res = fn and fn(msg.data) or {error="unknown"}
        rednet.send(sid, {type="result", taskId=msg.taskId, result=res}, PROTOCOL)
    elseif msg and msg.type == "shutdown" then break end
end
]]

local WORKER_LANGUAGE = [[
local M = {}
local v = dofile(disk.getMountPath("back").."/word_vectors.lua")
if v and v.load then v.load() end
function M.analyze(d) return {sentiment = v and v.getSentiment(d.text or "") or 0} end
return M
]]

local WORKER_KNOWLEDGE = [[
local M = {}
local kg = dofile(disk.getMountPath("back").."/knowledge_graph.lua")
function M.query(d) return {result = kg and kg.query(d.question or "") or nil} end
function M.describe(d) return {description = kg and kg.describe(d.entity or "") or "?"} end
return M
]]

local WORKER_MEMORY = [[
local M = {}
local mem = dofile(disk.getMountPath("back").."/conversation_memory.lua")
if mem and mem.init then mem.init() end
function M.recordInteraction(d) if mem then pcall(mem.recordUserInteraction,d.name,d.message,d.sentiment,{}) end return {ok=true} end
function M.getUser(d) return {user = mem and mem.getUser(d.name or "") or {}} end
return M
]]

local WORKER_RESPONSE = [[
local M = {}
local g = dofile(disk.getMountPath("back").."/response_generator.lua")
function M.generateGreeting(d) return {response = g and g.generateGreeting(d.context or {}) or "Hello!"} end
function M.generateStatus(d) return {response = g and g.generateStatusResponse(d.sentiment or 0) or "I see."} end
function M.generateJoke(d) return {response = g and g.generateJoke(d.category) or "Why do programmers prefer dark mode? Light attracts bugs!"} end
function M.generateFarewell(d) return {response = g and g.generateFarewell() or "Goodbye!"} end
function M.generateThanks(d) return {response = g and g.generateThanks() or "You're welcome!"} end
function M.generateAboutSelf(d) return {response = g and g.generateAboutSelf() or "I'm MODUS, a distributed AI!"} end
function M.generateContextual(d) return {response = g and g.generateContextual(d.intent or "statement", {}) or "Interesting!"} end
return M
]]

local MASTER_STARTUP = [[shell.run(disk.getMountPath("back").."/master_brain.lua")]]

local MASTER_BRAIN = [[
local PROTOCOL, workers, roles = "MODUS_CLUSTER", {}, {"language","knowledge","memory","response"}
for _, n in ipairs(peripheral.getNames()) do if peripheral.getType(n)=="modem" then rednet.open(n) end end

print("=== MODUS v3 ===")
local comps = {}
for _, n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n) == "computer" then
        table.insert(comps, {name=n, id=peripheral.call(n,"getID")})
    end
end

print("Assigning roles...")
for i, c in ipairs(comps) do
    local role = roles[i]
    if role then
        peripheral.call(c.name, "turnOn")
        sleep(0.3)
        rednet.send(c.id, {type="assign_role", role=role}, PROTOCOL)
        local deadline = os.clock() + 3
        while os.clock() < deadline do
            local sid, msg = rednet.receive(PROTOCOL, 0.5)
            if sid == c.id and msg and msg.type == "role_ack" then
                workers[role] = {id=c.id, ready=msg.ok}
                print("  "..role:upper()..": "..(msg.ok and "OK" or "ERR"))
                break
            end
        end
        if not workers[role] then workers[role] = {id=c.id, ready=false}; print("  "..role:upper()..": TIMEOUT") end
    end
end

local ready = 0
for _,w in pairs(workers) do if w.ready then ready = ready + 1 end end
print("\nReady: "..ready.."/4\n")

local tid = 0
local function task(role, t, d)
    local w = workers[role]
    if not w or not w.ready then return nil end
    tid = tid + 1
    rednet.send(w.id, {type="task", task=t, taskId=tid, data=d or {}}, PROTOCOL)
    local dl = os.clock() + 2
    while os.clock() < dl do
        local _, msg = rednet.receive(PROTOCOL, 0.3)
        if msg and msg.taskId == tid then return msg.result end
    end
end

local function intent(t)
    local l = t:lower()
    if l:match("^h[ie]") or l:match("^hey") then return "greeting" end
    if l:match("bye") then return "farewell" end
    if l:match("how are") then return "how_are_you" end
    if l:match("thank") then return "thanks" end
    if l:match("who are") or l:match("what are you") then return "about_ai" end
    if l:match("joke") then return "joke" end
    if l:match("%?$") then return "question" end
    return "statement"
end

local user = "User"
while true do
    write(user.."> ")
    local inp = read()
    if inp == "quit" then break
    elseif inp == "status" then for r,w in pairs(workers) do print(r..": "..(w.ready and "OK" or "DOWN")) end
    elseif inp:match("^name ") then user = inp:sub(6); print("Hi "..user.."!")
    elseif inp ~= "" then
        local int = intent(inp)
        local sent = (task("language","analyze",{text=inp}) or {}).sentiment or 0
        local resp
        if int == "greeting" then resp = (task("response","generateGreeting",{}) or {}).response
        elseif int == "farewell" then resp = (task("response","generateFarewell",{}) or {}).response
        elseif int == "how_are_you" then resp = "Great! "..ready.."/4 nodes active. You?"
        elseif int == "thanks" then resp = (task("response","generateThanks",{}) or {}).response
        elseif int == "about_ai" then resp = (task("response","generateAboutSelf",{}) or {}).response
        elseif int == "joke" then resp = (task("response","generateJoke",{}) or {}).response
        elseif int == "question" then
            local r = task("knowledge","query",{question=inp})
            resp = r and r.result and r.result.answer or (task("response","generateContextual",{intent="question"}) or {}).response
        else resp = (task("response","generateContextual",{intent="statement"}) or {}).response end
        task("memory","recordInteraction",{name=user,message=inp,sentiment=sent})
        print("\nMODUS: "..(resp or "..."))
        print("["..int.." | "..string.format("%.1f",sent).."]\n")
    end
end
for _,w in pairs(workers) do rednet.send(w.id,{type="shutdown"},PROTOCOL) end
]]

-- ============ INSTALL ============

print("Installing to master disk...")
local f = fs.open(myDrive.."/master_brain.lua", "w") f.write(MASTER_BRAIN) f.close()
f = fs.open("/startup.lua", "w") f.write(MASTER_STARTUP) f.close()
print("  + master_brain.lua")

print("\nInstalling to worker drives...")
for i, drv in ipairs(workerDrives) do
    print("  " .. drv.name .. " (" .. drv.path .. ")")
    f = fs.open(drv.path.."/startup.lua", "w") f.write(WORKER_STARTUP) f.close()
    f = fs.open(drv.path.."/worker_main.lua", "w") f.write(WORKER_MAIN) f.close()
    f = fs.open(drv.path.."/worker_language.lua", "w") f.write(WORKER_LANGUAGE) f.close()
    f = fs.open(drv.path.."/worker_knowledge.lua", "w") f.write(WORKER_KNOWLEDGE) f.close()
    f = fs.open(drv.path.."/worker_memory.lua", "w") f.write(WORKER_MEMORY) f.close()
    f = fs.open(drv.path.."/worker_response.lua", "w") f.write(WORKER_RESPONSE) f.close()
    
    -- Copy data files
    for _, df in ipairs({"word_vectors.lua","knowledge_graph.lua","conversation_memory.lua","response_generator.lua"}) do
        if fs.exists(df) then fs.copy(df, drv.path.."/"..df) end
    end
end

print("\nRebooting workers...")
for _, c in ipairs(workerComputers) do
    peripheral.call(c.name, "reboot")
end

print("Rebooting master in 2s...")
sleep(2)
os.reboot()
