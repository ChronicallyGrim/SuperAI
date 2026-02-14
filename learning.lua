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

-- ============================================================================
-- MASTER_BRAIN.LUA INTERFACE FUNCTIONS
-- ============================================================================

-- Learn from conversation interaction (expected by master_brain.lua)
function M.learn(message, response, intent)
    if not message or not response then return end
    
    -- Learn from the interaction pattern
    local topic = intent or "general"
    
    -- Extract key concepts from the message
    local words = {}
    for word in message:lower():gmatch("%w+") do
        table.insert(words, word)
    end
    
    -- Learn concepts from the conversation
    for _, word in ipairs(words) do
        if #word > 3 then  -- Only learn meaningful words
            M.learnConcept(word, "word mentioned in conversation", topic)
        end
    end
    
    -- Learn the response pattern
    if intent then
        M.learnFact(intent, "typical_response", response)
        M.learnRelationship(intent, "generates", response:sub(1, 50))  -- First 50 chars as identifier
    end
    
    -- Learn from the interaction
    M.learnFact("conversation", "last_interaction", {
        message = message,
        response = response,
        intent = intent,
        timestamp = os.time()
    })
    
    return true
end

-- Auto-train the system (expected by master_brain.lua)
function M.autoTrain(numConversations)
    numConversations = numConversations or 100
    
    -- Generate training scenarios
    local scenarios = {
        {message = "hello", response = "Hi there! How are you?", intent = "greeting"},
        {message = "how are you", response = "I'm doing well, thank you for asking!", intent = "question"},
        {message = "thank you", response = "You're welcome!", intent = "gratitude"},
        {message = "goodbye", response = "See you later!", intent = "farewell"},
        {message = "what can you do", response = "I can chat, answer questions, and help with various tasks!", intent = "question"},
        {message = "tell me a joke", response = "Why don't scientists trust atoms? Because they make up everything!", intent = "request"},
        {message = "I'm feeling sad", response = "I'm sorry to hear that. Would you like to talk about it?", intent = "statement"},
        {message = "that's great", response = "I'm glad to hear that!", intent = "statement"},
        {message = "help me", response = "Of course! What do you need help with?", intent = "request"},
        {message = "I don't understand", response = "No problem! Let me try to explain it differently.", intent = "statement"},
    }
    
    -- Train on scenarios multiple times
    for i = 1, numConversations do
        local scenario = scenarios[math.random(#scenarios)]
        M.learn(scenario.message, scenario.response, scenario.intent)
    end
    
    -- Save learned knowledge
    M.save("/disk/learning_auto_train.dat")
    
    return true
end

return M
