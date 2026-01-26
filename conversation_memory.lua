-- conversation_memory.lua
-- Deep conversation memory with persistence
-- Remembers users, preferences, conversation history, and learned facts

local M = {}

-- Storage paths
M.memoryPath = "/disk/ai_memory/"
M.usersFile = "users.dat"
M.factsFile = "learned_facts.dat"
M.historyFile = "history.dat"

-- In-memory caches
M.users = {}           -- user_name -> {profile}
M.learnedFacts = {}    -- Facts learned from conversations
M.conversationHistory = {}  -- Recent conversation history
M.sessionMemory = {}   -- Current session memory

-- ============================================================================
-- PERSISTENCE
-- ============================================================================

local function ensureDir()
    if not fs.exists(M.memoryPath) then
        fs.makeDir(M.memoryPath)
    end
end

local function serialize(tbl, indent)
    indent = indent or ""
    local result = "{\n"
    local nextIndent = indent .. "  "
    for k, v in pairs(tbl) do
        local keyStr = type(k) == "number" and "[" .. k .. "]" or '["' .. tostring(k) .. '"]'
        local valStr
        if type(v) == "table" then
            valStr = serialize(v, nextIndent)
        elseif type(v) == "string" then
            valStr = '"' .. v:gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
        elseif type(v) == "boolean" then
            valStr = v and "true" or "false"
        else
            valStr = tostring(v)
        end
        result = result .. nextIndent .. keyStr .. " = " .. valStr .. ",\n"
    end
    return result .. indent .. "}"
end

local function deserialize(str)
    local fn, err = load("return " .. str)
    if fn then
        local ok, result = pcall(fn)
        if ok then return result end
    end
    return {}
end

function M.saveUsers()
    ensureDir()
    local f = fs.open(M.memoryPath .. M.usersFile, "w")
    if f then
        f.write(serialize(M.users))
        f.close()
        return true
    end
    return false
end

function M.loadUsers()
    if fs.exists(M.memoryPath .. M.usersFile) then
        local f = fs.open(M.memoryPath .. M.usersFile, "r")
        if f then
            local content = f.readAll()
            f.close()
            M.users = deserialize(content) or {}
            return true
        end
    end
    M.users = {}
    return false
end

function M.saveFacts()
    ensureDir()
    local f = fs.open(M.memoryPath .. M.factsFile, "w")
    if f then
        f.write(serialize(M.learnedFacts))
        f.close()
        return true
    end
    return false
end

function M.loadFacts()
    if fs.exists(M.memoryPath .. M.factsFile) then
        local f = fs.open(M.memoryPath .. M.factsFile, "r")
        if f then
            local content = f.readAll()
            f.close()
            M.learnedFacts = deserialize(content) or {}
            return true
        end
    end
    M.learnedFacts = {}
    return false
end

-- ============================================================================
-- USER PROFILE MANAGEMENT
-- ============================================================================

function M.getUser(name)
    name = name:lower()
    if not M.users[name] then
        M.users[name] = {
            name = name,
            firstSeen = os.epoch and os.epoch("utc") or os.time(),
            lastSeen = os.epoch and os.epoch("utc") or os.time(),
            conversationCount = 0,
            messageCount = 0,
            preferences = {},
            facts = {},         -- Things we learned about them
            mood_history = {},  -- Track their moods
            topics = {},        -- Topics they're interested in
            favorite_topics = {},
        }
    end
    return M.users[name]
end

function M.updateUser(name, updates)
    local user = M.getUser(name)
    for k, v in pairs(updates) do
        user[k] = v
    end
    user.lastSeen = os.epoch and os.epoch("utc") or os.time()
    M.saveUsers()
    return user
end

function M.recordUserInteraction(name, message, sentiment, topics)
    local user = M.getUser(name)
    user.messageCount = user.messageCount + 1
    user.lastSeen = os.epoch and os.epoch("utc") or os.time()
    
    -- Track mood
    table.insert(user.mood_history, 1, {
        sentiment = sentiment,
        time = user.lastSeen
    })
    while #user.mood_history > 20 do table.remove(user.mood_history) end
    
    -- Track topics
    for _, topic in ipairs(topics or {}) do
        user.topics[topic.topic] = (user.topics[topic.topic] or 0) + 1
    end
    
    M.saveUsers()
    return user
end

function M.learnUserFact(userName, factKey, factValue)
    local user = M.getUser(userName)
    user.facts[factKey] = factValue
    M.saveUsers()
end

function M.getUserFact(userName, factKey)
    local user = M.getUser(userName)
    return user.facts[factKey]
end

function M.getAllUserFacts(userName)
    local user = M.getUser(userName)
    return user.facts
end

function M.getUserMoodTrend(userName)
    local user = M.getUser(userName)
    if #user.mood_history == 0 then return 0 end
    
    local sum = 0
    local count = math.min(5, #user.mood_history)
    for i = 1, count do
        sum = sum + (user.mood_history[i].sentiment or 0)
    end
    return sum / count
end

function M.getUserFavoriteTopics(userName, limit)
    limit = limit or 3
    local user = M.getUser(userName)
    
    local sorted = {}
    for topic, count in pairs(user.topics) do
        sorted[#sorted+1] = {topic = topic, count = count}
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    local result = {}
    for i = 1, math.min(limit, #sorted) do
        result[i] = sorted[i].topic
    end
    return result
end

-- ============================================================================
-- FACT LEARNING (from conversations)
-- ============================================================================

function M.learnFact(subject, relation, object, source)
    local key = subject:lower() .. "|" .. relation:lower() .. "|" .. object:lower()
    M.learnedFacts[key] = {
        subject = subject:lower(),
        relation = relation:lower(),
        object = object:lower(),
        source = source or "conversation",
        learnedAt = os.epoch and os.epoch("utc") or os.time(),
        confidence = 1.0,
    }
    M.saveFacts()
end

function M.queryLearnedFacts(subject, relation)
    local results = {}
    subject = subject and subject:lower()
    relation = relation and relation:lower()
    
    for key, fact in pairs(M.learnedFacts) do
        local match = true
        if subject and fact.subject ~= subject then match = false end
        if relation and fact.relation ~= relation then match = false end
        if match then
            results[#results+1] = fact
        end
    end
    return results
end

-- ============================================================================
-- SESSION MEMORY
-- ============================================================================

function M.startSession(userName)
    M.sessionMemory = {
        user = userName,
        startTime = os.epoch and os.epoch("utc") or os.time(),
        turns = {},
        currentTopic = nil,
        topicStack = {},
        emotionalArc = {},
        contextFlags = {},
    }
    
    if userName then
        local user = M.getUser(userName)
        user.conversationCount = user.conversationCount + 1
        M.saveUsers()
    end
    
    return M.sessionMemory
end

function M.addTurn(speaker, text, metadata)
    metadata = metadata or {}
    local turn = {
        speaker = speaker,
        text = text,
        time = os.epoch and os.epoch("utc") or os.time(),
        intent = metadata.intent,
        sentiment = metadata.sentiment,
        topics = metadata.topics,
    }
    
    table.insert(M.sessionMemory.turns, turn)
    
    -- Update topic stack
    if metadata.topics and #metadata.topics > 0 then
        local newTopic = metadata.topics[1].topic
        if newTopic ~= M.sessionMemory.currentTopic then
            if M.sessionMemory.currentTopic then
                table.insert(M.sessionMemory.topicStack, 1, M.sessionMemory.currentTopic)
                if #M.sessionMemory.topicStack > 5 then
                    table.remove(M.sessionMemory.topicStack)
                end
            end
            M.sessionMemory.currentTopic = newTopic
        end
    end
    
    -- Track emotional arc
    if metadata.sentiment then
        table.insert(M.sessionMemory.emotionalArc, metadata.sentiment)
    end
    
    return turn
end

function M.getRecentContext(turns)
    turns = turns or 5
    local result = {}
    local total = #M.sessionMemory.turns
    for i = math.max(1, total - turns + 1), total do
        result[#result+1] = M.sessionMemory.turns[i]
    end
    return result
end

function M.getSessionSummary()
    local sess = M.sessionMemory
    
    -- Calculate average sentiment
    local avgSentiment = 0
    if #sess.emotionalArc > 0 then
        for _, s in ipairs(sess.emotionalArc) do
            avgSentiment = avgSentiment + s
        end
        avgSentiment = avgSentiment / #sess.emotionalArc
    end
    
    return {
        user = sess.user,
        turnCount = #sess.turns,
        duration = (os.epoch and os.epoch("utc") or os.time()) - (sess.startTime or 0),
        currentTopic = sess.currentTopic,
        previousTopics = sess.topicStack,
        averageSentiment = avgSentiment,
    }
end

-- ============================================================================
-- CONTEXT-AWARE RETRIEVAL
-- ============================================================================

function M.getContextForResponse(userName)
    local context = {
        session = M.getSessionSummary(),
        recentTurns = M.getRecentContext(5),
    }
    
    if userName then
        local user = M.getUser(userName)
        context.user = {
            name = user.name,
            messageCount = user.messageCount,
            conversationCount = user.conversationCount,
            moodTrend = M.getUserMoodTrend(userName),
            favoriteTopics = M.getUserFavoriteTopics(userName),
            facts = user.facts,
        }
        context.isReturning = user.conversationCount > 1
        context.isNewToday = user.conversationCount == 1 and #M.sessionMemory.turns <= 1
    end
    
    return context
end

-- ============================================================================
-- PATTERN DETECTION (for learning)
-- ============================================================================

-- Detect "I am X" / "I'm X" patterns to learn about user
function M.detectSelfStatement(text)
    local lower = text:lower()
    
    -- "I am a/an [noun]" - identity
    local identity = lower:match("i'm a (%w+)") or lower:match("i am a (%w+)")
    if identity then
        return {type = "identity", value = identity}
    end
    
    -- "I am [adjective]" - state
    local state = lower:match("i'm (%w+)") or lower:match("i am (%w+)")
    if state then
        return {type = "state", value = state}
    end
    
    -- "I like [thing]"
    local likes = lower:match("i like (%w+)") or lower:match("i love (%w+)")
    if likes then
        return {type = "likes", value = likes}
    end
    
    -- "I don't like [thing]"
    local dislikes = lower:match("i don't like (%w+)") or lower:match("i hate (%w+)")
    if dislikes then
        return {type = "dislikes", value = dislikes}
    end
    
    -- "My name is [name]"
    local name = lower:match("my name is (%w+)") or lower:match("i'm called (%w+)") or lower:match("call me (%w+)")
    if name then
        return {type = "name", value = name}
    end
    
    -- "My favorite [thing] is [value]"
    local favType, favVal = lower:match("my favorite (%w+) is (%w+)")
    if favType and favVal then
        return {type = "favorite", category = favType, value = favVal}
    end
    
    return nil
end

function M.processAndLearn(userName, text)
    local statement = M.detectSelfStatement(text)
    if statement and userName then
        if statement.type == "name" then
            M.learnUserFact(userName, "preferred_name", statement.value)
        elseif statement.type == "likes" then
            M.learnUserFact(userName, "likes_" .. statement.value, true)
        elseif statement.type == "dislikes" then
            M.learnUserFact(userName, "dislikes_" .. statement.value, true)
        elseif statement.type == "favorite" then
            M.learnUserFact(userName, "favorite_" .. statement.category, statement.value)
        elseif statement.type == "identity" then
            M.learnUserFact(userName, "is_a", statement.value)
        end
        return statement
    end
    return nil
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function M.init()
    M.loadUsers()
    M.loadFacts()
    return true
end

function M.getStats()
    local userCount = 0
    for _ in pairs(M.users) do userCount = userCount + 1 end
    
    local factCount = 0
    for _ in pairs(M.learnedFacts) do factCount = factCount + 1 end
    
    return {
        users = userCount,
        learnedFacts = factCount,
        sessionTurns = #M.sessionMemory.turns,
    }
end

return M
