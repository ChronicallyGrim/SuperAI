-- cluster_installer.lua v8
-- Fixed: hardcode disk3 path in master startup

print("===== MODUS CLUSTER INSTALLER =====")
print("")

-- Find master disk
local myDrive = disk.getMountPath("back")
print("Master disk: " .. (myDrive or "NONE"))

-- Find worker drives and computers
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

print("Worker drives: " .. #workerDrives)
print("Worker computers: " .. #workerComputers)
print("")

-- Find data files
local dataFiles = {"word_vectors.lua", "knowledge_graph.lua", "conversation_memory.lua", "response_generator.lua"}
local dataLoc = {}

for _, df in ipairs(dataFiles) do
    if fs.exists(df) then
        dataLoc[df] = df
    elseif myDrive and fs.exists(myDrive.."/"..df) then
        dataLoc[df] = myDrive.."/"..df
    else
        print("WARNING: " .. df .. " not found!")
    end
end

-- ============ FILE CONTENTS ============

local WORKER_STARTUP = [[
local p = disk.getMountPath("back")
if p then shell.run(p.."/worker_main.lua") end
]]

local WORKER_MAIN = [[
local PROTOCOL = "MODUS_CLUSTER"
local p = disk.getMountPath("back")
local diskPath = p or ""

for _, n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n) == "modem" then rednet.open(n) end
end

term.clear()
term.setCursorPos(1,1)
print("Worker " .. os.getComputerID())
print("Disk: " .. diskPath)
print("Waiting for master...")

local ROLE, roleModule
while true do
    local sid, msg = rednet.receive(PROTOCOL, 2)
    if msg and msg.type == "assign_role" then
        ROLE = msg.role
        local modPath = diskPath.."/worker_"..ROLE..".lua"
        print("Loading: " .. modPath)
        if fs.exists(modPath) then
            local ok, m = pcall(dofile, modPath)
            roleModule = ok and m or nil
            if not ok then print("Error: "..tostring(m)) end
        else
            print("File not found!")
        end
        print("Role: " .. ROLE .. " = " .. (roleModule and "OK" or "FAIL"))
        rednet.send(sid, {type="role_ack", role=ROLE, ok=roleModule~=nil}, PROTOCOL)
    elseif msg and msg.type == "task" and roleModule then
        local fn = roleModule[msg.task]
        local ok, res = pcall(function() return fn and fn(msg.data) or {error="no func"} end)
        rednet.send(sid, {type="result", taskId=msg.taskId, result=ok and res or {error=tostring(res)}}, PROTOCOL)
    elseif msg and msg.type == "shutdown" then break end
end
]]

local WORKER_LANGUAGE = [[
local M = {}
local p = disk.getMountPath("back")
local path = p and p.."/word_vectors.lua" or nil
local v
if path and fs.exists(path) then
    local ok, m = pcall(dofile, path)
    if ok then v = m; if v.load then v.load() end; print("Vectors OK") 
    else print("Vec err: "..tostring(m)) end
else print("No vectors file: "..tostring(path)) end
function M.analyze(d) return {sentiment = v and v.getSentiment and v.getSentiment(d.text or "") or 0} end
return M
]]

local WORKER_KNOWLEDGE = [[
local M = {}
local p = disk.getMountPath("back")
local path = p and p.."/knowledge_graph.lua" or nil
local kg
if path and fs.exists(path) then
    local ok, m = pcall(dofile, path)
    if ok then kg = m; print("Knowledge OK") 
    else print("KG err: "..tostring(m)) end
else print("No knowledge file") end
function M.query(d) return {result = kg and kg.query and kg.query(d.question or "") or nil} end
function M.describe(d) return {description = kg and kg.describe and kg.describe(d.entity or "") or "?"} end
return M
]]

local WORKER_MEMORY = [[
local M = {}
local p = disk.getMountPath("back")
local path = p and p.."/conversation_memory.lua" or nil
local mem
if path and fs.exists(path) then
    local ok, m = pcall(dofile, path)
    if ok then mem = m; if mem.init then mem.init() end; print("Memory OK") 
    else print("Mem err: "..tostring(m)) end
else print("No memory file") end
function M.recordInteraction(d) if mem and mem.recordUserInteraction then pcall(mem.recordUserInteraction,d.name,d.message,d.sentiment,{}) end return {ok=true} end
function M.getUser(d) return {user = mem and mem.getUser and mem.getUser(d.name or "") or {}} end
return M
]]

local WORKER_RESPONSE = [[
local M = {}
local p = disk.getMountPath("back")
local path = p and p.."/response_generator.lua" or nil
local g
if path and fs.exists(path) then
    local ok, m = pcall(dofile, path)
    if ok then g = m; print("Response OK") 
    else print("Resp err: "..tostring(m)) end
else print("No response file") end
function M.generateGreeting(d) return {response = g and g.generateGreeting and g.generateGreeting(d.context or {}) or "Hello!"} end
function M.generateStatus(d) return {response = g and g.generateStatusResponse and g.generateStatusResponse(d.sentiment or 0) or "I see."} end
function M.generateJoke(d) return {response = g and g.generateJoke and g.generateJoke(d.category) or "Why do programmers prefer dark mode? Light attracts bugs!"} end
function M.generateFarewell(d) return {response = g and g.generateFarewell and g.generateFarewell() or "Goodbye!"} end
function M.generateThanks(d) return {response = g and g.generateThanks and g.generateThanks() or "You're welcome!"} end
function M.generateAboutSelf(d) return {response = g and g.generateAboutSelf and g.generateAboutSelf() or "I'm MODUS, a distributed AI!"} end
function M.generateContextual(d) return {response = g and g.generateContextual and g.generateContextual(d.intent or "statement", {}) or "Interesting!"} end
return M
]]

-- HARDCODED master startup - disk.getMountPath fails at boot
local MASTER_STARTUP = 'shell.run("' .. myDrive .. '/master_brain.lua")'

local MASTER_BRAIN = [[
local PROTOCOL, workers, roles = "MODUS_CLUSTER", {}, {"language","knowledge","memory","response"}
for _, n in ipairs(peripheral.getNames()) do if peripheral.getType(n)=="modem" then rednet.open(n) end end

print("=== MODUS v8 ===")
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
        sleep(0.5)
        rednet.send(c.id, {type="assign_role", role=role}, PROTOCOL)
        local deadline = os.clock() + 4
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

print("Installing master...")
local f = fs.open(myDrive.."/master_brain.lua", "w") f.write(MASTER_BRAIN) f.close()
f = fs.open("startup.lua", "w") f.write(MASTER_STARTUP) f.close()
f = fs.open(myDrive.."/startup.lua", "w") f.write(MASTER_STARTUP) f.close()
print("  + master_brain.lua")
print("  + startup.lua = " .. MASTER_STARTUP)

print("\nInstalling workers...")
for i, drv in ipairs(workerDrives) do
    print("  " .. drv.name .. " -> " .. drv.path)
    
    f = fs.open(drv.path.."/startup.lua", "w") f.write(WORKER_STARTUP) f.close()
    f = fs.open(drv.path.."/worker_main.lua", "w") f.write(WORKER_MAIN) f.close()
    f = fs.open(drv.path.."/worker_language.lua", "w") f.write(WORKER_LANGUAGE) f.close()
    f = fs.open(drv.path.."/worker_knowledge.lua", "w") f.write(WORKER_KNOWLEDGE) f.close()
    f = fs.open(drv.path.."/worker_memory.lua", "w") f.write(WORKER_MEMORY) f.close()
    f = fs.open(drv.path.."/worker_response.lua", "w") f.write(WORKER_RESPONSE) f.close()
    
    -- Copy data files
    for _, df in ipairs(dataFiles) do
        local src = dataLoc[df]
        if src then
            fs.copy(src, drv.path.."/"..df)
            print("    + " .. df)
        end
    end
end

print("\nRebooting workers...")
for _, c in ipairs(workerComputers) do
    peripheral.call(c.name, "reboot")
end

print("Rebooting master in 2s...")
sleep(2)
os.reboot()
