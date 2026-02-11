-- cluster_installer.lua v11
-- Workers search all sides for their disk

local GITHUB = "https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/refs/heads/main/"

print("===== MODUS CLUSTER INSTALLER =====")
print("")

-- Find master disk
local myDrive = disk.getMountPath("back")
print("Master disk: " .. (myDrive or "NONE"))

-- Find worker drives and computers
local workerDrives = {}
local workerComputers = {}

local myID = os.getComputerID()
for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)
    if pType == "drive" and name ~= "back" then
        local path = disk.getMountPath(name)
        if path then
            table.insert(workerDrives, {name = name, path = path})
        end
    elseif pType == "computer" then
        local cid = peripheral.call(name, "getID")
        if cid ~= myID then
            table.insert(workerComputers, {name = name, id = cid})
        end
    end
end

print("Worker drives: " .. #workerDrives)
print("Worker computers: " .. #workerComputers)
print("")

-- Data files - download if missing
local dataFiles = {
    "word_vectors.lua",
    "knowledge_graph.lua",
    "conversation_memory.lua",
    "response_generator.lua",
    "personality.lua",
    "mood.lua",
    "attention.lua",
    "neural_net.lua",
    "meta_cognition.lua",
    "introspection.lua",
    "philosophical_reasoning.lua",
    "natural_conversation.lua"
}

print("Checking data files...")
for _, df in ipairs(dataFiles) do
    local found = false
    if fs.exists(df) then
        found = true
    elseif myDrive and fs.exists(myDrive.."/"..df) then
        found = true
    end
    
    if not found then
        write("  Downloading " .. df .. "... ")
        local r = http.get(GITHUB .. df)
        if r then
            local f = fs.open(myDrive.."/"..df, "w")
            f.write(r.readAll())
            f.close()
            r.close()
            print("OK")
        else
            print("FAILED")
        end
    else
        print("  " .. df .. " OK")
    end
end
print("")

-- Rebuild dataLoc after downloads
local dataLoc = {}
for _, df in ipairs(dataFiles) do
    if fs.exists(df) then
        dataLoc[df] = df
    elseif myDrive and fs.exists(myDrive.."/"..df) then
        dataLoc[df] = myDrive.."/"..df
    end
end

-- ============ FILE CONTENTS ============

local MASTER_STARTUP = [[
local function findDisk()
    local p = disk.getMountPath("back")
    if p and fs.exists(p.."/master_brain.lua") then return p end
    for i = 1, 10 do
        local try = "disk" .. (i > 1 and i or "")
        if fs.exists(try.."/master_brain.lua") then return try end
    end
end
local d = findDisk()
if d then shell.run(d.."/master_brain.lua") else print("master_brain.lua not found!") end
]]

-- Worker startup: search ALL sides for a disk with worker_main.lua
local WORKER_STARTUP = [[
local function findMyDisk()
    local sides = {"back","front","left","right","top","bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local p = disk.getMountPath(side)
            if p and fs.exists(p.."/worker_main.lua") then return p end
        end
    end
end
local d = findMyDisk()
if d then shell.run(d.."/worker_main.lua") else print("worker_main.lua not found!") end
]]

-- Worker main: search all sides for disk
local WORKER_MAIN = [[
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
]]

-- Worker modules: search all sides for disk
local WORKER_LANGUAGE = [[
local M = {}
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
local p = findMyDisk()
local v
local ok, m = pcall(dofile, p.."/word_vectors.lua")
if ok then v = m; if v.load then v.load() end; print("Vectors OK") else print("Vec: "..tostring(m)) end
function M.analyze(d) return {sentiment = v and v.getSentiment and v.getSentiment(d.text or "") or 0} end
return M
]]

local WORKER_KNOWLEDGE = [[
local M = {}
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
local p = findMyDisk()
local kg
local ok, m = pcall(dofile, p.."/knowledge_graph.lua")
if ok then kg = m; print("Knowledge OK") else print("KG: "..tostring(m)) end
function M.query(d) return {result = kg and kg.query and kg.query(d.question or "") or nil} end
function M.describe(d) return {description = kg and kg.describe and kg.describe(d.entity or "") or "?"} end
return M
]]

local WORKER_MEMORY = [[
local M = {}
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
local p = findMyDisk()
local mem
local ok, m = pcall(dofile, p.."/conversation_memory.lua")
if ok then mem = m; if mem.init then mem.init() end; print("Memory OK") else print("Mem: "..tostring(m)) end
function M.recordInteraction(d) if mem then pcall(mem.recordUserInteraction,d.name,d.message,d.sentiment,{}) end return {ok=true} end
function M.getUser(d) return {user = mem and mem.getUser and mem.getUser(d.name or "") or {}} end
return M
]]

local WORKER_RESPONSE = [[
local M = {}
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
local p = findMyDisk()
local g
local ok, m = pcall(dofile, p.."/response_generator.lua")
if ok then g = m; print("Response OK") else print("Resp: "..tostring(m)) end
function M.generateGreeting(d) return {response = g and g.generateGreeting and g.generateGreeting(d.context or {}) or "Hello!"} end
function M.generateStatus(d) return {response = g and g.generateStatusResponse and g.generateStatusResponse(d.sentiment or 0) or "I see."} end
function M.generateJoke(d) return {response = g and g.generateJoke and g.generateJoke(d.category) or "Why do programmers prefer dark mode? Light attracts bugs!"} end
function M.generateFarewell(d) return {response = g and g.generateFarewell and g.generateFarewell() or "Goodbye!"} end
function M.generateThanks(d) return {response = g and g.generateThanks and g.generateThanks() or "You're welcome!"} end
function M.generateAboutSelf(d) return {response = g and g.generateAboutSelf and g.generateAboutSelf() or "I'm MODUS!"} end
function M.generateContextual(d) return {response = g and g.generateContextual and g.generateContextual(d.intent or "statement", {}) or "Interesting!"} end
return M
]]

local WORKER_PERSONALITY = [[
local M = {}
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
local p = findMyDisk()
local pers
local ok, m = pcall(dofile, p.."/personality.lua")
if ok then pers = m; if pers.init then pers.init() end; print("Personality OK") else print("Pers: "..tostring(m)) end
function M.getTrait(d) return {value = pers and pers.getTrait and pers.getTrait(d.trait or "") or 0.5} end
function M.updateTrait(d) if pers and pers.updateTrait then pers.updateTrait(d.trait, d.change) end return {ok=true} end
function M.getPersonality(d) return {personality = pers and pers.getPersonalityState and pers.getPersonalityState() or {}} end
return M
]]

local WORKER_MOOD = [[
local M = {}
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
local p = findMyDisk()
local mood
local ok, m = pcall(dofile, p.."/mood.lua")
if ok then mood = m; if mood.init then mood.init() end; print("Mood OK") else print("Mood: "..tostring(m)) end
function M.getCurrentMood(d) return {mood = mood and mood.getCurrentMood and mood.getCurrentMood() or "neutral"} end
function M.updateMood(d) if mood and mood.updateMood then mood.updateMood(d.sentiment) end return {ok=true} end
function M.predictEmotion(d) return {prediction = mood and mood.predictEmotion and mood.predictEmotion(d.context) or "neutral"} end
return M
]]

local WORKER_ATTENTION = [[
local M = {}
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
local p = findMyDisk()
local att
local ok, m = pcall(dofile, p.."/attention.lua")
if ok then att = m; print("Attention OK") else print("Att: "..tostring(m)) end
function M.computeAttention(d) return {weights = att and att.computeAttention and att.computeAttention(d.query, d.keys, d.values) or {}} end
function M.multiHeadAttention(d) return {output = att and att.multiHeadAttention and att.multiHeadAttention(d.input, d.numHeads) or {}} end
return M
]]

local WORKER_NEURAL = [[
local M = {}
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
local p = findMyDisk()
local nn
local ok, m = pcall(dofile, p.."/neural_net.lua")
if ok then nn = m; print("Neural Net OK") else print("NN: "..tostring(m)) end
function M.predict(d) return {output = nn and nn.predict and nn.predict(d.network, d.input) or {}} end
function M.train(d) if nn and nn.train then nn.train(d.network, d.data, d.epochs) end return {ok=true} end
return M
]]

local WORKER_METACOG = [[
local M = {}
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
local p = findMyDisk()
local mc
local ok, m = pcall(dofile, p.."/meta_cognition.lua")
if ok then mc = m; if mc.init then mc.init() end; print("Meta-Cognition OK") else print("MC: "..tostring(m)) end
function M.assessConfidence(d) return {confidence = mc and mc.assessConfidence and mc.assessConfidence(d.prediction) or 0.5} end
function M.estimateUncertainty(d) return {uncertainty = mc and mc.estimateUncertainty and mc.estimateUncertainty(d.context) or {}} end
function M.getCognitiveState(d) return {state = mc and mc.getCognitiveState and mc.getCognitiveState() or {}} end
return M
]]

local WORKER_INTROSPECT = [[
local M = {}
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
local p = findMyDisk()
local intro
local ok, m = pcall(dofile, p.."/introspection.lua")
if ok then intro = m; if intro.init then intro.init() end; print("Introspection OK") else print("Intro: "..tostring(m)) end
function M.assessCapability(d) return {assessment = intro and intro.assessCapability and intro.assessCapability(d.capability) or {}} end
function M.recognizeLimitation(d) return {limitations = intro and intro.recognizeLimitation and intro.recognizeLimitation(d.task) or {}} end
function M.getSelfModel(d) return {model = intro and intro.getSelfModel and intro.getSelfModel() or {}} end
return M
]]

local WORKER_PHILOSOPHY = [[
local M = {}
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
local p = findMyDisk()
local phil
local ok, m = pcall(dofile, p.."/philosophical_reasoning.lua")
if ok then phil = m; print("Philosophy OK") else print("Phil: "..tostring(m)) end
function M.reasonEthically(d) return {reasoning = phil and phil.reasonEthically and phil.reasonEthically(d.scenario) or {}} end
function M.logicalInference(d) return {conclusion = phil and phil.logicalInference and phil.logicalInference(d.premises) or nil} end
function M.thinkAbstractly(d) return {abstraction = phil and phil.thinkAbstractly and phil.thinkAbstractly(d.concept) or {}} end
return M
]]

local WORKER_CONVERSATION = [[
local M = {}
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
local p = findMyDisk()
local conv
local ok, m = pcall(dofile, p.."/natural_conversation.lua")
if ok then conv = m; if conv.init then conv.init() end; print("Conversation OK") else print("Conv: "..tostring(m)) end
function M.planResponse(d) return {plan = conv and conv.planResponse and conv.planResponse(d.context) or {}} end
function M.adaptStyle(d) return {style = conv and conv.adaptStyle and conv.adaptStyle(d.userStyle) or {}} end
function M.repairConversation(d) return {repair = conv and conv.repairConversation and conv.repairConversation(d.issue) or {}} end
return M
]]

local MASTER_BRAIN = [[
local PROTOCOL, workers, roles = "MODUS_CLUSTER", {}, {"language","knowledge","memory","response","personality","mood","attention","neural","metacog","introspect","philosophy","conversation"}
for _, n in ipairs(peripheral.getNames()) do if peripheral.getType(n)=="modem" then rednet.open(n) end end

print("=== MODUS v11 ===")
local myMasterID = os.getComputerID()
local comps = {}
for _, n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n) == "computer" then
        local cid = peripheral.call(n,"getID")
        if cid ~= myMasterID then table.insert(comps, {name=n, id=cid}) end
    end
end

print("Assigning roles...")
for i, c in ipairs(comps) do
    local role = roles[i]
    if role then
        peripheral.call(c.name, "turnOn")
        sleep(0.5)
        rednet.send(c.id, {type="assign_role", role=role}, PROTOCOL)
        local dl = os.clock() + 4
        while os.clock() < dl do
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
print("\nReady: "..ready.."/12\n")

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
        elseif int == "how_are_you" then resp = "Great! "..ready.."/12 nodes active. You?"
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
print("  + master_brain.lua + startup.lua")

print("\nInstalling workers...")
for i, drv in ipairs(workerDrives) do
    write("  " .. drv.path .. ": ")
    f = fs.open(drv.path.."/startup.lua", "w") f.write(WORKER_STARTUP) f.close()
    f = fs.open(drv.path.."/worker_main.lua", "w") f.write(WORKER_MAIN) f.close()
    f = fs.open(drv.path.."/worker_language.lua", "w") f.write(WORKER_LANGUAGE) f.close()
    f = fs.open(drv.path.."/worker_knowledge.lua", "w") f.write(WORKER_KNOWLEDGE) f.close()
    f = fs.open(drv.path.."/worker_memory.lua", "w") f.write(WORKER_MEMORY) f.close()
    f = fs.open(drv.path.."/worker_response.lua", "w") f.write(WORKER_RESPONSE) f.close()
    f = fs.open(drv.path.."/worker_personality.lua", "w") f.write(WORKER_PERSONALITY) f.close()
    f = fs.open(drv.path.."/worker_mood.lua", "w") f.write(WORKER_MOOD) f.close()
    f = fs.open(drv.path.."/worker_attention.lua", "w") f.write(WORKER_ATTENTION) f.close()
    f = fs.open(drv.path.."/worker_neural.lua", "w") f.write(WORKER_NEURAL) f.close()
    f = fs.open(drv.path.."/worker_metacog.lua", "w") f.write(WORKER_METACOG) f.close()
    f = fs.open(drv.path.."/worker_introspect.lua", "w") f.write(WORKER_INTROSPECT) f.close()
    f = fs.open(drv.path.."/worker_philosophy.lua", "w") f.write(WORKER_PHILOSOPHY) f.close()
    f = fs.open(drv.path.."/worker_conversation.lua", "w") f.write(WORKER_CONVERSATION) f.close()
    local c = 0
    for _, df in ipairs(dataFiles) do
        local src = dataLoc[df]
        if src then
            if fs.exists(drv.path.."/"..df) then fs.delete(drv.path.."/"..df) end
            fs.copy(src, drv.path.."/"..df)
            c = c + 1
        end
    end
    print(c .. " data files")
end

print("\nRebooting...")
for _, c in ipairs(workerComputers) do peripheral.call(c.name, "reboot") end
sleep(2)
os.reboot()
