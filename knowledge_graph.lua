-- knowledge_graph.lua
-- Semantic knowledge graph with inference and reasoning
-- Stores facts as triples and can derive new knowledge

local M = {}

M.facts = {}      -- subject -> relation -> {objects}
M.reverse = {}    -- object -> relation -> {subjects}
M.entities = {}
M.relations = {}

-- Inference rules
M.rules = {
    {from={"is_a","is_a"}, to="is_a"},
    {from={"is_a","has_property"}, to="has_property"},
    {from={"is_a","can_do"}, to="can_do"},
    {from={"is_a","has_part"}, to="has_part"},
}

-- Built-in knowledge
local FACTS = {
    -- Taxonomy
    {"dog","is_a","animal"},{"cat","is_a","animal"},{"bird","is_a","animal"},
    {"fish","is_a","animal"},{"animal","is_a","living_thing"},
    {"human","is_a","animal"},{"person","is_a","human"},
    {"tree","is_a","plant"},{"plant","is_a","living_thing"},
    
    -- Properties
    {"dog","has_property","loyal"},{"dog","has_property","friendly"},
    {"cat","has_property","independent"},{"cat","has_property","curious"},
    {"animal","has_property","alive"},{"bird","has_property","can_fly"},
    {"fish","has_property","aquatic"},{"sun","has_property","hot"},
    {"water","has_property","wet"},{"fire","has_property","hot"},
    {"ice","has_property","cold"},{"diamond","has_property","valuable"},
    
    -- Capabilities
    {"dog","can_do","bark"},{"dog","can_do","run"},{"cat","can_do","meow"},
    {"bird","can_do","fly"},{"bird","can_do","sing"},{"fish","can_do","swim"},
    {"human","can_do","think"},{"human","can_do","speak"},{"human","can_do","create"},
    {"ai","can_do","learn"},{"ai","can_do","help"},{"ai","can_do","chat"},
    
    -- Parts
    {"dog","has_part","tail"},{"bird","has_part","wings"},{"tree","has_part","leaves"},
    {"human","has_part","brain"},{"computer","has_part","cpu"},
    
    -- Minecraft
    {"creeper","is_a","mob"},{"zombie","is_a","mob"},{"skeleton","is_a","mob"},
    {"mob","is_a","entity"},{"player","is_a","entity"},
    {"creeper","can_do","explode"},{"creeper","has_property","dangerous"},
    {"diamond","is_a","ore"},{"iron","is_a","ore"},{"gold","is_a","ore"},
    {"ore","is_a","block"},{"pickaxe","is_a","tool"},{"sword","is_a","weapon"},
    {"redstone","can_do","conduct_power"},{"nether","has_property","dangerous"},
    
    -- MODUS self-knowledge
    {"modus","is_a","ai"},{"ai","is_a","program"},
    {"modus","has_property","helpful"},{"modus","has_property","friendly"},
    {"modus","can_do","chat"},{"modus","can_do","remember"},{"modus","can_do","learn"},
    
    -- Emotions
    {"happiness","is_a","emotion"},{"sadness","is_a","emotion"},
    {"anger","is_a","emotion"},{"love","is_a","emotion"},
    {"friendship","is_a","relationship"},{"friendship","has_property","valuable"},
    
    -- Opposites & synonyms
    {"hot","opposite_of","cold"},{"big","opposite_of","small"},
    {"happy","opposite_of","sad"},{"good","opposite_of","bad"},
    {"happy","similar_to","glad"},{"happy","similar_to","joyful"},
    {"sad","similar_to","unhappy"},{"smart","similar_to","intelligent"},
}

function M.addFact(s, r, o)
    s, r, o = s:lower(), r:lower(), o:lower()
    M.facts[s] = M.facts[s] or {}
    M.facts[s][r] = M.facts[s][r] or {}
    M.facts[s][r][o] = true
    M.reverse[o] = M.reverse[o] or {}
    M.reverse[o][r] = M.reverse[o][r] or {}
    M.reverse[o][r][s] = true
    M.entities[s], M.entities[o], M.relations[r] = true, true, true
end

function M.hasFact(s, r, o)
    s, r, o = s:lower(), r:lower(), o:lower()
    return M.facts[s] and M.facts[s][r] and M.facts[s][r][o] == true
end

function M.getObjects(s, r)
    s, r = s:lower(), r:lower()
    local res = {}
    if M.facts[s] and M.facts[s][r] then
        for o in pairs(M.facts[s][r]) do res[#res+1] = o end
    end
    return res
end

function M.getSubjects(r, o)
    r, o = r:lower(), o:lower()
    local res = {}
    if M.reverse[o] and M.reverse[o][r] then
        for s in pairs(M.reverse[o][r]) do res[#res+1] = s end
    end
    return res
end

-- Inference with depth limit
function M.infer(subject, relation, depth)
    depth = depth or 3
    subject, relation = subject:lower(), relation:lower()
    local results, visited = {}, {}
    
    -- Direct facts
    for _, o in ipairs(M.getObjects(subject, relation)) do
        results[o] = {direct=true}
    end
    
    -- Inference
    local function inferStep(current, d)
        if d > depth or visited[current..d] then return end
        visited[current..d] = true
        
        for _, rule in ipairs(M.rules) do
            if rule.to == relation then
                local mids = M.getObjects(current, rule.from[1])
                for _, mid in ipairs(mids) do
                    local finals = M.getObjects(mid, rule.from[2])
                    for _, final in ipairs(finals) do
                        if not results[final] then
                            results[final] = {direct=false, via=mid, rule=rule.from[1].."->"..rule.from[2]}
                        end
                    end
                    inferStep(mid, d+1)
                end
            end
        end
    end
    
    inferStep(subject, 1)
    
    local list = {}
    for o, info in pairs(results) do
        list[#list+1] = {object=o, direct=info.direct, via=info.via}
    end
    return list
end

-- Natural language description
function M.describe(entity)
    entity = entity:lower()
    local parts = {}
    
    local types = M.getObjects(entity, "is_a")
    if #types > 0 then
        parts[#parts+1] = entity:gsub("^%l", string.upper) .. " is a " .. table.concat(types, " and ")
    end
    
    local props = M.getObjects(entity, "has_property")
    if #props > 0 then
        parts[#parts+1] = "It is " .. table.concat(props, ", ")
    end
    
    local caps = M.infer(entity, "can_do", 2)
    if #caps > 0 then
        local capList = {}
        for _, c in ipairs(caps) do capList[#capList+1] = c.object end
        parts[#parts+1] = "It can " .. table.concat(capList, ", ")
    end
    
    if #parts == 0 then
        return "I don't know much about " .. entity .. " yet."
    end
    return table.concat(parts, ". ") .. "."
end

-- Query parser
function M.query(q)
    q = q:lower()
    
    -- "what is X"
    local what = q:match("what is (%w+)") or q:match("who is (%w+)")
    if what then
        return {type="describe", entity=what, answer=M.describe(what)}
    end
    
    -- "is X a Y"
    local s, o = q:match("is (%w+) a (%w+)")
    if s and o then
        local inferred = M.infer(s, "is_a")
        for _, item in ipairs(inferred) do
            if item.object == o then
                return {type="is_a", answer=true, direct=item.direct, via=item.via}
            end
        end
        return {type="is_a", answer=false}
    end
    
    -- "can X Y"
    local cs, ca = q:match("can (%w+) (%w+)")
    if cs and ca then
        local inferred = M.infer(cs, "can_do")
        for _, item in ipairs(inferred) do
            if item.object == ca then
                return {type="can_do", answer=true, direct=item.direct}
            end
        end
        return {type="can_do", answer=false}
    end
    
    return nil
end

-- Find related entities
function M.findRelated(entity, max)
    entity = entity:lower()
    max = max or 5
    local scores = {}
    
    -- Same type
    for _, t in ipairs(M.getObjects(entity, "is_a")) do
        for _, sib in ipairs(M.getSubjects("is_a", t)) do
            if sib ~= entity then
                scores[sib] = (scores[sib] or 0) + 2
            end
        end
    end
    
    -- Similar/opposite
    for _, sim in ipairs(M.getObjects(entity, "similar_to")) do
        scores[sim] = (scores[sim] or 0) + 3
    end
    for _, opp in ipairs(M.getObjects(entity, "opposite_of")) do
        scores[opp] = (scores[opp] or 0) + 2
    end
    
    local list = {}
    for e, s in pairs(scores) do list[#list+1] = {entity=e, score=s} end
    table.sort(list, function(a,b) return a.score > b.score end)
    
    local res = {}
    for i = 1, math.min(max, #list) do res[i] = list[i] end
    return res
end

function M.loadBuiltIn()
    for _, f in ipairs(FACTS) do M.addFact(f[1], f[2], f[3]) end
    return #FACTS
end

function M.getStats()
    local fc, ec, rc = 0, 0, 0
    for s, rels in pairs(M.facts) do
        for r, objs in pairs(rels) do
            for _ in pairs(objs) do fc = fc + 1 end
        end
    end
    for _ in pairs(M.entities) do ec = ec + 1 end
    for _ in pairs(M.relations) do rc = rc + 1 end
    return {facts=fc, entities=ec, relations=rc, rules=#M.rules}
end

M.loadBuiltIn()
return M
