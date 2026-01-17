-- Module: learning.lua
-- System for learning new concepts from text input

local M = {}

-- Knowledge base
M.knowledge = {
    facts = {},
    concepts = {},
    procedures = {},
    examples = {},
    relationships = {},
}

-- ============================================================================
-- LEARNING FROM TEXT
-- ============================================================================

-- Learn a new fact
function M.learnFact(subject, predicate, object)
    if not M.knowledge.facts[subject] then
        M.knowledge.facts[subject] = {}
    end
    
    table.insert(M.knowledge.facts[subject], {
        predicate = predicate,
        object = object,
        timestamp = os.time(),
    })
    
    return true
end

-- Learn a concept
function M.learnConcept(name, description, category)
    M.knowledge.concepts[name] = {
        description = description,
        category = category or "general",
        examples = {},
        learned = os.time(),
    }
    
    return true
end

-- Learn a procedure (how to do something)
function M.learnProcedure(name, steps)
    M.knowledge.procedures[name] = {
        steps = steps,
        learned = os.time(),
    }
    
    return true
end

-- Add example to concept
function M.addExample(concept, example)
    if M.knowledge.concepts[concept] then
        table.insert(M.knowledge.concepts[concept].examples, example)
        return true
    end
    return false
end

-- Learn relationship between concepts
function M.learnRelationship(concept1, relationship, concept2)
    local key = concept1 .. ":" .. relationship
    
    if not M.knowledge.relationships[key] then
        M.knowledge.relationships[key] = {}
    end
    
    table.insert(M.knowledge.relationships[key], concept2)
    return true
end

-- ============================================================================
-- TEXT PARSING
-- ============================================================================

-- Parse text and extract learning
function M.parseAndLearn(text)
    local learned = {}
    
    -- Look for definitions (X is Y, X means Y)
    for subject, verb, definition in text:gmatch("([%w%s]+)%s+(is|means|refers to)%s+([^.]+)") do
        subject = subject:match("^%s*(.-)%s*$") -- trim
        definition = definition:match("^%s*(.-)%s*$")
        
        M.learnConcept(subject:lower(), definition, "definition")
        table.insert(learned, "Learned: " .. subject .. " = " .. definition)
    end
    
    -- Look for procedures (how to X: step 1, step 2)
    local procedureName = text:match("how to ([%w%s]+):")
    if procedureName then
        local steps = {}
        for step in text:gmatch("%d+[.)%s]+([^%d]+)") do
            step = step:match("^%s*(.-)%s*$")
            if step ~= "" then
                table.insert(steps, step)
            end
        end
        
        if #steps > 0 then
            M.learnProcedure(procedureName:lower(), steps)
            table.insert(learned, "Learned procedure: " .. procedureName)
        end
    end
    
    -- Look for examples (for example, such as, like)
    for concept, examples in text:gmatch("([%w%s]+)%s+(?:for example|such as|like)%s+([^.]+)") do
        concept = concept:match("^%s*(.-)%s*$"):lower()
        
        if M.knowledge.concepts[concept] then
            for example in examples:gmatch("([^,]+)") do
                example = example:match("^%s*(.-)%s*$")
                M.addExample(concept, example)
            end
            table.insert(learned, "Added examples to: " .. concept)
        end
    end
    
    return learned
end

-- ============================================================================
-- KNOWLEDGE RETRIEVAL
-- ============================================================================

-- Recall facts about subject
function M.recallFacts(subject)
    local lower = subject:lower()
    
    if M.knowledge.facts[lower] then
        return M.knowledge.facts[lower]
    end
    
    return {}
end

-- Get concept definition
function M.getConcept(name)
    local lower = name:lower()
    return M.knowledge.concepts[lower]
end

-- Get procedure
function M.getProcedure(name)
    local lower = name:lower()
    return M.knowledge.procedures[lower]
end

-- Find related concepts
function M.findRelated(concept, relationship)
    local key = concept:lower() .. ":" .. relationship:lower()
    return M.knowledge.relationships[key] or {}
end

-- Search knowledge base
function M.search(query)
    local results = {
        facts = {},
        concepts = {},
        procedures = {},
    }
    
    local lower = query:lower()
    
    -- Search facts
    for subject, facts in pairs(M.knowledge.facts) do
        if subject:find(lower) then
            results.facts[subject] = facts
        end
    end
    
    -- Search concepts
    for name, concept in pairs(M.knowledge.concepts) do
        if name:find(lower) or concept.description:lower():find(lower) then
            results.concepts[name] = concept
        end
    end
    
    -- Search procedures
    for name, procedure in pairs(M.knowledge.procedures) do
        if name:find(lower) then
            results.procedures[name] = procedure
        end
    end
    
    return results
end

-- ============================================================================
-- KNOWLEDGE STATS
-- ============================================================================

function M.getStats()
    local factCount = 0
    for _ in pairs(M.knowledge.facts) do
        factCount = factCount + 1
    end
    
    local conceptCount = 0
    for _ in pairs(M.knowledge.concepts) do
        conceptCount = conceptCount + 1
    end
    
    local procedureCount = 0
    for _ in pairs(M.knowledge.procedures) do
        procedureCount = procedureCount + 1
    end
    
    return {
        facts = factCount,
        concepts = conceptCount,
        procedures = procedureCount,
    }
end

-- ============================================================================
-- TEACHING MODE
-- ============================================================================

-- Teach the AI something new
function M.teach(topic, information)
    -- Try to parse and learn
    local learned = M.parseAndLearn(topic .. " " .. information)
    
    -- If no structured learning, store as general fact
    if #learned == 0 then
        M.learnFact(topic, "description", information)
        return "I've learned about " .. topic
    end
    
    return table.concat(learned, "\n")
end

-- ============================================================================
-- PERSISTENCE
-- ============================================================================

function M.save(filename)
    local serialized = textutils.serialize(M.knowledge)
    local file = fs.open(filename, "w")
    if not file then
        return false
    end
    file.write(serialized)
    file.close()
    return true
end

function M.load(filename)
    if not fs.exists(filename) then
        return false
    end
    
    local file = fs.open(filename, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local loaded = textutils.unserialize(content)
    if loaded then
        M.knowledge = loaded
        return true
    end
    
    return false
end

return M
