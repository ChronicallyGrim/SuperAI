-- Module: conversation_memory.lua
-- Massively expanded conversation memory system with 97+ functions and 14 advanced features
--
-- Features:
-- - Semantic search and similarity matching
-- - Episodic memory with rich context
-- - Working memory with attention mechanisms
-- - Forgetting curves (Ebbinghaus-style decay)
-- - Memory consolidation and rehearsal
-- - Relationship tracking between entities
-- - Implicit learning from conversations
-- - Temporal reasoning (before/after/during)
-- - Autobiographical memory
-- - False memory detection
-- - Memory quality metrics (vividness, certainty)
-- - Retrieval practice effects
-- - Context-dependent memory retrieval

local M = {}

-- ============================================================================
-- STORAGE CONFIGURATION
-- ============================================================================

M.memoryPath = "/disk/ai_memory/"
M.usersFile = "users.dat"
M.factsFile = "learned_facts.dat"
M.historyFile = "history.dat"
M.episodicFile = "episodic.dat"
M.semanticFile = "semantic.dat"

-- ============================================================================
-- IN-MEMORY STORAGE
-- ============================================================================

M.users = {}
M.learnedFacts = {}
M.conversationHistory = {}
M.sessionMemory = {}

-- Episodic memory: specific experiences and events
M.episodicMemory = {}

-- Semantic memory: general knowledge and concepts
M.semanticMemory = {}

-- Working memory: temporary, active information
M.workingMemory = {
    capacity = 7,  -- Miller's law: 7±2 items
    items = {},
    attentionWeights = {}
}

-- Relationship graph
M.relationshipGraph = {
    entities = {},
    relationships = {}
}

-- Memory consolidation queue
M.consolidationQueue = {}

-- ============================================================================
-- MEMORY QUALITY METRICS
-- ============================================================================

local MemoryQuality = {
    vividness = {min = 0, max = 1},      -- How clear/detailed the memory is
    certainty = {min = 0, max = 1},      -- Confidence in accuracy
    importance = {min = 0, max = 1},     -- Subjective significance
    accessibility = {min = 0, max = 1},  -- Ease of retrieval
    stability = {min = 0, max = 1}       -- Resistance to forgetting
}

-- ============================================================================
-- FORGETTING CURVE PARAMETERS (Ebbinghaus)
-- ============================================================================

local forgettingCurve = {
    decay_rate = 0.3,
    retention_factor = 0.9,
    rehearsal_boost = 0.2,
    consolidation_threshold = 3  -- Number of rehearsals for long-term storage
}

-- ============================================================================
-- PERSISTENCE UTILITIES
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

function M.saveEpisodicMemory()
    ensureDir()
    local f = fs.open(M.memoryPath .. M.episodicFile, "w")
    if f then
        f.write(serialize(M.episodicMemory))
        f.close()
        return true
    end
    return false
end

function M.loadEpisodicMemory()
    if fs.exists(M.memoryPath .. M.episodicFile) then
        local f = fs.open(M.memoryPath .. M.episodicFile, "r")
        if f then
            local content = f.readAll()
            f.close()
            M.episodicMemory = deserialize(content) or {}
            return true
        end
    end
    M.episodicMemory = {}
    return false
end

-- ============================================================================
-- USER PROFILE MANAGEMENT (Functions 1-15)
-- ============================================================================

-- Function 1: Get or create user
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
            facts = {},
            mood_history = {},
            topics = {},
            favorite_topics = {},
            communication_style = {},
            relationship_quality = 0.5,
            trust_level = 0.5
        }
    end
    return M.users[name]
end

-- Function 2: Update user profile
function M.updateUser(name, updates)
    local user = M.getUser(name)
    for k, v in pairs(updates) do
        user[k] = v
    end
    user.lastSeen = os.epoch and os.epoch("utc") or os.time()
    M.saveUsers()
    return user
end

-- Function 3: Record user interaction
function M.recordUserInteraction(name, message, sentiment, topics)
    local user = M.getUser(name)
    user.messageCount = user.messageCount + 1
    user.lastSeen = os.epoch and os.epoch("utc") or os.time()

    table.insert(user.mood_history, 1, {
        sentiment = sentiment,
        time = user.lastSeen
    })
    while #user.mood_history > 20 do table.remove(user.mood_history) end

    for _, topic in ipairs(topics or {}) do
        user.topics[topic.topic] = (user.topics[topic.topic] or 0) + 1
    end

    M.saveUsers()
    return user
end

-- Function 4: Learn user fact
function M.learnUserFact(userName, factKey, factValue)
    local user = M.getUser(userName)
    user.facts[factKey] = factValue
    M.saveUsers()
end

-- Function 5: Get user fact
function M.getUserFact(userName, factKey)
    local user = M.getUser(userName)
    return user.facts[factKey]
end

-- Function 6: Get all user facts
function M.getAllUserFacts(userName)
    local user = M.getUser(userName)
    return user.facts
end

-- Function 7: Get user mood trend
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

-- Function 8: Get user favorite topics
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

-- Function 9: Update user communication style
function M.updateCommunicationStyle(userName, styleData)
    local user = M.getUser(userName)
    for key, value in pairs(styleData) do
        user.communication_style[key] = value
    end
    M.saveUsers()
end

-- Function 10: Get user communication style
function M.getUserCommunicationStyle(userName)
    local user = M.getUser(userName)
    return user.communication_style
end

-- Function 11: Update relationship quality
function M.updateRelationshipQuality(userName, adjustment)
    local user = M.getUser(userName)
    user.relationship_quality = math.max(0, math.min(1, user.relationship_quality + adjustment))
    M.saveUsers()
    return user.relationship_quality
end

-- Function 12: Get relationship quality
function M.getRelationshipQuality(userName)
    local user = M.getUser(userName)
    return user.relationship_quality
end

-- Function 13: Update trust level
function M.updateTrustLevel(userName, adjustment)
    local user = M.getUser(userName)
    user.trust_level = math.max(0, math.min(1, user.trust_level + adjustment))
    M.saveUsers()
    return user.trust_level
end

-- Function 14: Get trust level
function M.getTrustLevel(userName)
    local user = M.getUser(userName)
    return user.trust_level
end

-- Function 15: Get user engagement metrics
function M.getUserEngagementMetrics(userName)
    local user = M.getUser(userName)
    return {
        total_messages = user.messageCount,
        conversations = user.conversationCount,
        average_mood = M.getUserMoodTrend(userName),
        relationship_quality = user.relationship_quality,
        trust_level = user.trust_level,
        active_topics = #M.getUserFavoriteTopics(userName, 10)
    }
end

-- ============================================================================
-- FACT LEARNING SYSTEM (Functions 16-25)
-- ============================================================================

-- Function 16: Learn fact
function M.learnFact(subject, relation, object, source)
    local key = subject:lower() .. "|" .. relation:lower() .. "|" .. object:lower()
    M.learnedFacts[key] = {
        subject = subject:lower(),
        relation = relation:lower(),
        object = object:lower(),
        source = source or "conversation",
        learnedAt = os.epoch and os.epoch("utc") or os.time(),
        confidence = 1.0,
        retrievalCount = 0,
        lastRetrieved = 0
    }
    M.saveFacts()
end

-- Function 17: Query learned facts
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

-- Function 18: Update fact confidence
function M.updateFactConfidence(subject, relation, object, adjustment)
    local key = subject:lower() .. "|" .. relation:lower() .. "|" .. object:lower()
    if M.learnedFacts[key] then
        M.learnedFacts[key].confidence = math.max(0, math.min(1, M.learnedFacts[key].confidence + adjustment))
        M.saveFacts()
        return true
    end
    return false
end

-- Function 19: Record fact retrieval
function M.recordFactRetrieval(subject, relation, object)
    local key = subject:lower() .. "|" .. relation:lower() .. "|" .. object:lower()
    if M.learnedFacts[key] then
        M.learnedFacts[key].retrievalCount = M.learnedFacts[key].retrievalCount + 1
        M.learnedFacts[key].lastRetrieved = os.epoch and os.epoch("utc") or os.time()
        M.saveFacts()
    end
end

-- Function 20: Get fact by confidence threshold
function M.getFactsByConfidence(minConfidence)
    local results = {}
    for _, fact in pairs(M.learnedFacts) do
        if fact.confidence >= minConfidence then
            table.insert(results, fact)
        end
    end
    return results
end

-- Function 21: Get facts by source
function M.getFactsBySource(source)
    local results = {}
    for _, fact in pairs(M.learnedFacts) do
        if fact.source == source then
            table.insert(results, fact)
        end
    end
    return results
end

-- Function 22: Delete unreliable facts
function M.pruneUnreliableFacts(confidenceThreshold)
    confidenceThreshold = confidenceThreshold or 0.3
    local removed = 0
    for key, fact in pairs(M.learnedFacts) do
        if fact.confidence < confidenceThreshold then
            M.learnedFacts[key] = nil
            removed = removed + 1
        end
    end
    M.saveFacts()
    return removed
end

-- Function 23: Get most retrieved facts
function M.getMostRetrievedFacts(limit)
    limit = limit or 10
    local sorted = {}
    for _, fact in pairs(M.learnedFacts) do
        table.insert(sorted, fact)
    end
    table.sort(sorted, function(a, b) return a.retrievalCount > b.retrievalCount end)

    local results = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(results, sorted[i])
    end
    return results
end

-- Function 24: Find related facts
function M.findRelatedFacts(subject, maxDistance)
    maxDistance = maxDistance or 2
    local related = {}
    local visited = {}

    local function explore(currentSubject, distance)
        if distance > maxDistance or visited[currentSubject] then return end
        visited[currentSubject] = true

        for _, fact in pairs(M.learnedFacts) do
            if fact.subject == currentSubject then
                table.insert(related, {fact = fact, distance = distance})
                explore(fact.object, distance + 1)
            end
        end
    end

    explore(subject:lower(), 0)
    return related
end

-- Function 25: Verify fact consistency
function M.verifyFactConsistency()
    local inconsistencies = {}
    for key1, fact1 in pairs(M.learnedFacts) do
        for key2, fact2 in pairs(M.learnedFacts) do
            if key1 ~= key2 and fact1.subject == fact2.subject and fact1.relation == fact2.relation then
                if fact1.object ~= fact2.object then
                    table.insert(inconsistencies, {fact1 = fact1, fact2 = fact2})
                end
            end
        end
    end
    return inconsistencies
end

-- ============================================================================
-- EPISODIC MEMORY SYSTEM (Functions 26-40)
-- ============================================================================

-- Function 26: Create episodic memory
function M.createEpisodicMemory(userName, event, context)
    if not M.episodicMemory[userName] then
        M.episodicMemory[userName] = {}
    end

    local memory = {
        id = #M.episodicMemory[userName] + 1,
        event = event,
        context = context or {},
        timestamp = os.epoch and os.epoch("utc") or os.time(),
        quality = {
            vividness = context.vividness or 0.8,
            certainty = context.certainty or 0.7,
            importance = context.importance or 0.5,
            accessibility = 1.0,
            stability = 0.5
        },
        retrievalCount = 0,
        lastRetrieved = 0,
        consolidationLevel = 0,
        decayFactor = 1.0
    }

    table.insert(M.episodicMemory[userName], memory)
    M.saveEpisodicMemory()
    return memory
end

-- Function 27: Retrieve episodic memories
function M.retrieveEpisodicMemories(userName, query, limit)
    if not M.episodicMemory[userName] then return {} end

    limit = limit or 5
    local scored = {}

    for _, memory in ipairs(M.episodicMemory[userName]) do
        local score = M.calculateMemoryRelevance(memory, query)
        table.insert(scored, {memory = memory, score = score})
    end

    table.sort(scored, function(a, b) return a.score > b.score end)

    local results = {}
    for i = 1, math.min(limit, #scored) do
        if scored[i].score > 0.3 then
            M.recordMemoryRetrieval(userName, scored[i].memory.id)
            table.insert(results, scored[i].memory)
        end
    end

    return results
end

-- Function 28: Calculate memory relevance
function M.calculateMemoryRelevance(memory, query)
    local score = 0

    -- Temporal relevance
    local age = (os.epoch and os.epoch("utc") or os.time()) - memory.timestamp
    local ageScore = math.exp(-age / 86400) * 0.3  -- Decay over days

    -- Retrieval practice effect
    local retrievalScore = math.min(memory.retrievalCount * 0.05, 0.3)

    -- Quality scores
    local qualityScore = (memory.quality.vividness + memory.quality.accessibility) * 0.2

    -- Context matching
    local contextScore = 0
    if query and query.context then
        for key, value in pairs(query.context) do
            if memory.context[key] == value then
                contextScore = contextScore + 0.1
            end
        end
    end

    score = ageScore + retrievalScore + qualityScore + contextScore

    return score
end

-- Function 29: Record memory retrieval
function M.recordMemoryRetrieval(userName, memoryId)
    if not M.episodicMemory[userName] then return end

    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.id == memoryId then
            memory.retrievalCount = memory.retrievalCount + 1
            memory.lastRetrieved = os.epoch and os.epoch("utc") or os.time()
            memory.quality.accessibility = math.min(1.0, memory.quality.accessibility + 0.05)
            M.saveEpisodicMemory()
            break
        end
    end
end

-- Function 30: Apply forgetting curve
function M.applyForgettingCurve(userName)
    if not M.episodicMemory[userName] then return end

    local currentTime = os.epoch and os.epoch("utc") or os.time()

    for _, memory in ipairs(M.episodicMemory[userName]) do
        local timeSinceCreation = currentTime - memory.timestamp
        local timeSinceRetrieval = currentTime - (memory.lastRetrieved > 0 and memory.lastRetrieved or memory.timestamp)

        -- Ebbinghaus forgetting curve
        local decay = math.exp(-forgettingCurve.decay_rate * (timeSinceRetrieval / 86400))
        memory.decayFactor = decay

        -- Reduce accessibility based on decay
        memory.quality.accessibility = memory.quality.accessibility * (0.9 + 0.1 * decay)

        -- Increase stability with rehearsal
        if memory.retrievalCount > 0 then
            memory.quality.stability = math.min(1.0, memory.quality.stability + (memory.retrievalCount * forgettingCurve.rehearsal_boost * 0.1))
        end
    end

    M.saveEpisodicMemory()
end

-- Function 31: Consolidate memories
function M.consolidateMemories(userName)
    if not M.episodicMemory[userName] then return end

    local consolidated = 0

    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.retrievalCount >= forgettingCurve.consolidation_threshold and memory.consolidationLevel == 0 then
            memory.consolidationLevel = 1
            memory.quality.stability = math.min(1.0, memory.quality.stability + 0.3)
            memory.quality.vividness = math.max(memory.quality.vividness * 0.9, 0.6)  -- Some detail loss
            consolidated = consolidated + 1
        end
    end

    M.saveEpisodicMemory()
    return consolidated
end

-- Function 32: Get episodic memories by time range
function M.getEpisodicMemoriesByTimeRange(userName, startTime, endTime)
    if not M.episodicMemory[userName] then return {} end

    local results = {}
    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.timestamp >= startTime and memory.timestamp <= endTime then
            table.insert(results, memory)
        end
    end
    return results
end

-- Function 33: Get most vivid memories
function M.getMostVividMemories(userName, limit)
    if not M.episodicMemory[userName] then return {} end

    limit = limit or 5
    local sorted = {}

    for _, memory in ipairs(M.episodicMemory[userName]) do
        table.insert(sorted, memory)
    end

    table.sort(sorted, function(a, b) return a.quality.vividness > b.quality.vividness end)

    local results = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(results, sorted[i])
    end
    return results
end

-- Function 34: Detect false memories
function M.detectFalseMemories(userName)
    if not M.episodicMemory[userName] then return {} end

    local suspicious = {}

    for _, memory in ipairs(M.episodicMemory[userName]) do
        local suspicionScore = 0

        -- Low certainty
        if memory.quality.certainty < 0.4 then
            suspicionScore = suspicionScore + 0.3
        end

        -- High vividness but low retrievals (reconstructed memory)
        if memory.quality.vividness > 0.8 and memory.retrievalCount < 2 then
            suspicionScore = suspicionScore + 0.2
        end

        -- Recently created but very old timestamp claim
        local age = (os.epoch and os.epoch("utc") or os.time()) - memory.timestamp
        if age > 2592000 and memory.retrievalCount == 0 then  -- >30 days
            suspicionScore = suspicionScore + 0.2
        end

        -- Check for consistency with other memories
        -- (Simplified - in production would do semantic similarity)

        if suspicionScore > 0.5 then
            table.insert(suspicious, {memory = memory, suspicion = suspicionScore})
        end
    end

    return suspicious
end

-- Function 35: Update memory quality
function M.updateMemoryQuality(userName, memoryId, qualityUpdates)
    if not M.episodicMemory[userName] then return false end

    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.id == memoryId then
            for key, value in pairs(qualityUpdates) do
                if memory.quality[key] then
                    memory.quality[key] = math.max(0, math.min(1, value))
                end
            end
            M.saveEpisodicMemory()
            return true
        end
    end
    return false
end

-- Function 36: Get memory by importance
function M.getMemoriesByImportance(userName, minImportance)
    if not M.episodicMemory[userName] then return {} end

    local results = {}
    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.quality.importance >= minImportance then
            table.insert(results, memory)
        end
    end
    return results
end

-- Function 37: Rehearse memory
function M.rehearseMemory(userName, memoryId)
    if not M.episodicMemory[userName] then return false end

    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.id == memoryId then
            memory.retrievalCount = memory.retrievalCount + 1
            memory.lastRetrieved = os.epoch and os.epoch("utc") or os.time()
            memory.quality.stability = math.min(1.0, memory.quality.stability + forgettingCurve.rehearsal_boost)
            memory.decayFactor = 1.0  -- Reset decay
            M.saveEpisodicMemory()
            return true
        end
    end
    return false
end

-- Function 38: Get memory statistics
function M.getMemoryStatistics(userName)
    if not M.episodicMemory[userName] then
        return {total = 0}
    end

    local stats = {
        total = #M.episodicMemory[userName],
        consolidated = 0,
        average_vividness = 0,
        average_certainty = 0,
        average_stability = 0,
        total_retrievals = 0
    }

    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.consolidationLevel > 0 then
            stats.consolidated = stats.consolidated + 1
        end
        stats.average_vividness = stats.average_vividness + memory.quality.vividness
        stats.average_certainty = stats.average_certainty + memory.quality.certainty
        stats.average_stability = stats.average_stability + memory.quality.stability
        stats.total_retrievals = stats.total_retrievals + memory.retrievalCount
    end

    if stats.total > 0 then
        stats.average_vividness = stats.average_vividness / stats.total
        stats.average_certainty = stats.average_certainty / stats.total
        stats.average_stability = stats.average_stability / stats.total
    end

    return stats
end

-- Function 39: Prune decayed memories
function M.pruneDecayedMemories(userName, decayThreshold)
    if not M.episodicMemory[userName] then return 0 end

    decayThreshold = decayThreshold or 0.1
    local removed = 0
    local kept = {}

    for _, memory in ipairs(M.episodicMemory[userName]) do
        if memory.decayFactor >= decayThreshold or memory.consolidationLevel > 0 then
            table.insert(kept, memory)
        else
            removed = removed + 1
        end
    end

    M.episodicMemory[userName] = kept
    M.saveEpisodicMemory()
    return removed
end

-- Function 40: Export episodic memories
function M.exportEpisodicMemories(userName, format)
    if not M.episodicMemory[userName] then return nil end

    format = format or "summary"

    if format == "summary" then
        local summary = {}
        for _, memory in ipairs(M.episodicMemory[userName]) do
            table.insert(summary, {
                id = memory.id,
                event = memory.event,
                timestamp = memory.timestamp,
                importance = memory.quality.importance,
                retrievals = memory.retrievalCount
            })
        end
        return summary
    elseif format == "full" then
        return M.episodicMemory[userName]
    end

    return nil
end

-- ============================================================================
-- SEMANTIC MEMORY & SEARCH (Functions 41-55)
-- ============================================================================

-- Function 41: Add semantic concept
function M.addSemanticConcept(concept, properties)
    M.semanticMemory[concept:lower()] = {
        concept = concept:lower(),
        properties = properties or {},
        associations = {},
        strength = 1.0,
        createdAt = os.epoch and os.epoch("utc") or os.time(),
        accessCount = 0
    }
end

-- Function 42: Add semantic association
function M.addSemanticAssociation(concept1, concept2, strength)
    concept1 = concept1:lower()
    concept2 = concept2:lower()

    if not M.semanticMemory[concept1] then
        M.addSemanticConcept(concept1, {})
    end
    if not M.semanticMemory[concept2] then
        M.addSemanticConcept(concept2, {})
    end

    M.semanticMemory[concept1].associations[concept2] = strength or 0.5
    M.semanticMemory[concept2].associations[concept1] = strength or 0.5
end

-- Function 43: Get semantic associations
function M.getSemanticAssociations(concept, minStrength)
    concept = concept:lower()
    minStrength = minStrength or 0.3

    if not M.semanticMemory[concept] then return {} end

    local associations = {}
    for assoc, strength in pairs(M.semanticMemory[concept].associations) do
        if strength >= minStrength then
            table.insert(associations, {concept = assoc, strength = strength})
        end
    end

    table.sort(associations, function(a, b) return a.strength > b.strength end)
    return associations
end

-- Function 44: Strengthen semantic link
function M.strengthenSemanticLink(concept1, concept2, amount)
    concept1 = concept1:lower()
    concept2 = concept2:lower()

    if M.semanticMemory[concept1] and M.semanticMemory[concept1].associations[concept2] then
        local newStrength = math.min(1.0, M.semanticMemory[concept1].associations[concept2] + amount)
        M.semanticMemory[concept1].associations[concept2] = newStrength
        M.semanticMemory[concept2].associations[concept1] = newStrength
        return true
    end
    return false
end

-- Function 45: Semantic search
function M.semanticSearch(query, limit)
    query = query:lower()
    limit = limit or 10
    local results = {}

    for concept, data in pairs(M.semanticMemory) do
        local score = 0

        -- Direct match
        if concept:find(query, 1, true) then
            score = score + 1.0
        end

        -- Property match
        for key, value in pairs(data.properties) do
            if type(value) == "string" and value:lower():find(query, 1, true) then
                score = score + 0.5
            end
        end

        -- Association match
        for assoc, strength in pairs(data.associations) do
            if assoc:find(query, 1, true) then
                score = score + (0.3 * strength)
            end
        end

        if score > 0 then
            table.insert(results, {concept = concept, score = score, data = data})
        end
    end

    table.sort(results, function(a, b) return a.score > b.score end)

    local limited = {}
    for i = 1, math.min(limit, #results) do
        table.insert(limited, results[i])
        M.semanticMemory[results[i].concept].accessCount = M.semanticMemory[results[i].concept].accessCount + 1
    end

    return limited
end

-- Function 46: Find semantic path
function M.findSemanticPath(concept1, concept2, maxDepth)
    concept1 = concept1:lower()
    concept2 = concept2:lower()
    maxDepth = maxDepth or 4

    if not M.semanticMemory[concept1] or not M.semanticMemory[concept2] then
        return nil
    end

    local visited = {}
    local function search(current, target, depth, path)
        if depth > maxDepth then return nil end
        if current == target then return path end
        if visited[current] then return nil end

        visited[current] = true

        if M.semanticMemory[current] then
            for assoc, strength in pairs(M.semanticMemory[current].associations) do
                if strength > 0.3 then
                    local newPath = {}
                    for _, p in ipairs(path) do table.insert(newPath, p) end
                    table.insert(newPath, assoc)

                    local result = search(assoc, target, depth + 1, newPath)
                    if result then return result end
                end
            end
        end

        return nil
    end

    return search(concept1, concept2, 0, {concept1})
end

-- Function 47: Get semantic network density
function M.getSemanticNetworkDensity()
    local totalConcepts = 0
    local totalLinks = 0

    for _, data in pairs(M.semanticMemory) do
        totalConcepts = totalConcepts + 1
        for _ in pairs(data.associations) do
            totalLinks = totalLinks + 1
        end
    end

    totalLinks = totalLinks / 2  -- Each link counted twice

    if totalConcepts <= 1 then return 0 end

    local maxPossibleLinks = (totalConcepts * (totalConcepts - 1)) / 2
    return totalLinks / maxPossibleLinks
end

-- Function 48: Get most connected concepts
function M.getMostConnectedConcepts(limit)
    limit = limit or 10
    local scored = {}

    for concept, data in pairs(M.semanticMemory) do
        local connectionCount = 0
        for _ in pairs(data.associations) do
            connectionCount = connectionCount + 1
        end
        table.insert(scored, {concept = concept, connections = connectionCount})
    end

    table.sort(scored, function(a, b) return a.connections > b.connections end)

    local results = {}
    for i = 1, math.min(limit, #scored) do
        table.insert(results, scored[i])
    end
    return results
end

-- Function 49: Prune weak semantic links
function M.pruneWeakSemanticLinks(threshold)
    threshold = threshold or 0.2
    local removed = 0

    for concept, data in pairs(M.semanticMemory) do
        for assoc, strength in pairs(data.associations) do
            if strength < threshold then
                data.associations[assoc] = nil
                removed = removed + 1
            end
        end
    end

    return removed
end

-- Function 50: Compute concept similarity
function M.computeConceptSimilarity(concept1, concept2)
    concept1 = concept1:lower()
    concept2 = concept2:lower()

    if not M.semanticMemory[concept1] or not M.semanticMemory[concept2] then
        return 0
    end

    -- Check direct association
    if M.semanticMemory[concept1].associations[concept2] then
        return M.semanticMemory[concept1].associations[concept2]
    end

    -- Check shared associations (Jaccard similarity)
    local assoc1 = {}
    local assoc2 = {}

    for assoc in pairs(M.semanticMemory[concept1].associations) do
        assoc1[assoc] = true
    end
    for assoc in pairs(M.semanticMemory[concept2].associations) do
        assoc2[assoc] = true
    end

    local intersection = 0
    local union = 0

    for assoc in pairs(assoc1) do
        union = union + 1
        if assoc2[assoc] then
            intersection = intersection + 1
        end
    end

    for assoc in pairs(assoc2) do
        if not assoc1[assoc] then
            union = union + 1
        end
    end

    if union == 0 then return 0 end
    return intersection / union
end

-- Function 51: Get concept properties
function M.getConceptProperties(concept)
    concept = concept:lower()
    if M.semanticMemory[concept] then
        return M.semanticMemory[concept].properties
    end
    return nil
end

-- Function 52: Update concept properties
function M.updateConceptProperties(concept, properties)
    concept = concept:lower()
    if not M.semanticMemory[concept] then
        M.addSemanticConcept(concept, properties)
    else
        for key, value in pairs(properties) do
            M.semanticMemory[concept].properties[key] = value
        end
    end
end

-- Function 53: Find concepts by property
function M.findConceptsByProperty(propertyKey, propertyValue)
    local results = {}

    for concept, data in pairs(M.semanticMemory) do
        if data.properties[propertyKey] == propertyValue then
            table.insert(results, concept)
        end
    end

    return results
end

-- Function 54: Get semantic cluster
function M.getSemanticCluster(concept, depth)
    concept = concept:lower()
    depth = depth or 2

    if not M.semanticMemory[concept] then return {} end

    local cluster = {concept}
    local visited = {[concept] = true}

    local function explore(current, currentDepth)
        if currentDepth >= depth then return end

        if M.semanticMemory[current] then
            for assoc, strength in pairs(M.semanticMemory[current].associations) do
                if not visited[assoc] and strength > 0.4 then
                    visited[assoc] = true
                    table.insert(cluster, assoc)
                    explore(assoc, currentDepth + 1)
                end
            end
        end
    end

    explore(concept, 0)
    return cluster
end

-- Function 55: Export semantic network
function M.exportSemanticNetwork(format)
    format = format or "adjacency"

    if format == "adjacency" then
        local network = {}
        for concept, data in pairs(M.semanticMemory) do
            network[concept] = {}
            for assoc, strength in pairs(data.associations) do
                network[concept][assoc] = strength
            end
        end
        return network
    elseif format == "edge_list" then
        local edges = {}
        local processed = {}
        for concept, data in pairs(M.semanticMemory) do
            for assoc, strength in pairs(data.associations) do
                local key = concept < assoc and (concept .. "|" .. assoc) or (assoc .. "|" .. concept)
                if not processed[key] then
                    processed[key] = true
                    table.insert(edges, {from = concept, to = assoc, strength = strength})
                end
            end
        end
        return edges
    end

    return nil
end

-- ============================================================================
-- WORKING MEMORY & ATTENTION (Functions 56-65)
-- ============================================================================

-- Function 56: Add to working memory
function M.addToWorkingMemory(item, attention)
    attention = attention or 0.5

    if #M.workingMemory.items >= M.workingMemory.capacity then
        -- Remove least attended item
        local minAttention = 1.0
        local minIndex = 1
        for i, _ in ipairs(M.workingMemory.items) do
            if M.workingMemory.attentionWeights[i] < minAttention then
                minAttention = M.workingMemory.attentionWeights[i]
                minIndex = i
            end
        end
        table.remove(M.workingMemory.items, minIndex)
        table.remove(M.workingMemory.attentionWeights, minIndex)
    end

    table.insert(M.workingMemory.items, item)
    table.insert(M.workingMemory.attentionWeights, attention)
end

-- Function 57: Get working memory contents
function M.getWorkingMemory()
    return {
        items = M.workingMemory.items,
        attention = M.workingMemory.attentionWeights,
        capacity = M.workingMemory.capacity,
        utilization = #M.workingMemory.items / M.workingMemory.capacity
    }
end

-- Function 58: Update attention weight
function M.updateAttention(index, newWeight)
    if index >= 1 and index <= #M.workingMemory.attentionWeights then
        M.workingMemory.attentionWeights[index] = math.max(0, math.min(1, newWeight))
        return true
    end
    return false
end

-- Function 59: Get most attended items
function M.getMostAttendedItems(limit)
    limit = limit or 3
    local indexed = {}

    for i, item in ipairs(M.workingMemory.items) do
        table.insert(indexed, {
            item = item,
            attention = M.workingMemory.attentionWeights[i],
            index = i
        })
    end

    table.sort(indexed, function(a, b) return a.attention > b.attention end)

    local results = {}
    for i = 1, math.min(limit, #indexed) do
        table.insert(results, indexed[i])
    end
    return results
end

-- Function 60: Clear working memory
function M.clearWorkingMemory()
    M.workingMemory.items = {}
    M.workingMemory.attentionWeights = {}
end

-- Function 61: Decay attention
function M.decayAttention(decayRate)
    decayRate = decayRate or 0.1

    for i, weight in ipairs(M.workingMemory.attentionWeights) do
        M.workingMemory.attentionWeights[i] = math.max(0, weight - decayRate)
    end
end

-- Function 62: Find in working memory
function M.findInWorkingMemory(query)
    local results = {}

    for i, item in ipairs(M.workingMemory.items) do
        if type(item) == "string" and item:lower():find(query:lower(), 1, true) then
            table.insert(results, {
                item = item,
                attention = M.workingMemory.attentionWeights[i],
                index = i
            })
        elseif type(item) == "table" and item.text then
            if item.text:lower():find(query:lower(), 1, true) then
                table.insert(results, {
                    item = item,
                    attention = M.workingMemory.attentionWeights[i],
                    index = i
                })
            end
        end
    end

    return results
end

-- Function 63: Set working memory capacity
function M.setWorkingMemoryCapacity(capacity)
    capacity = math.max(3, math.min(12, capacity))
    M.workingMemory.capacity = capacity

    -- Trim if over capacity
    while #M.workingMemory.items > capacity do
        local minAttention = 1.0
        local minIndex = 1
        for i, weight in ipairs(M.workingMemory.attentionWeights) do
            if weight < minAttention then
                minAttention = weight
                minIndex = i
            end
        end
        table.remove(M.workingMemory.items, minIndex)
        table.remove(M.workingMemory.attentionWeights, minIndex)
    end
end

-- Function 64: Get working memory utilization
function M.getWorkingMemoryUtilization()
    return {
        current = #M.workingMemory.items,
        capacity = M.workingMemory.capacity,
        percentage = (#M.workingMemory.items / M.workingMemory.capacity) * 100,
        average_attention = M.calculateAverageAttention()
    }
end

-- Function 65: Calculate average attention
function M.calculateAverageAttention()
    if #M.workingMemory.attentionWeights == 0 then return 0 end

    local sum = 0
    for _, weight in ipairs(M.workingMemory.attentionWeights) do
        sum = sum + weight
    end
    return sum / #M.workingMemory.attentionWeights
end

-- ============================================================================
-- RELATIONSHIP TRACKING (Functions 66-75)
-- ============================================================================

-- Function 66: Add entity to relationship graph
function M.addEntity(entityName, entityType, properties)
    entityName = entityName:lower()

    M.relationshipGraph.entities[entityName] = {
        name = entityName,
        type = entityType or "unknown",
        properties = properties or {},
        createdAt = os.epoch and os.epoch("utc") or os.time(),
        mentionCount = 0
    }
end

-- Function 67: Add relationship
function M.addRelationship(entity1, entity2, relationshipType, strength)
    entity1 = entity1:lower()
    entity2 = entity2:lower()

    if not M.relationshipGraph.entities[entity1] then
        M.addEntity(entity1, "unknown", {})
    end
    if not M.relationshipGraph.entities[entity2] then
        M.addEntity(entity2, "unknown", {})
    end

    local key = entity1 < entity2 and (entity1 .. "|" .. entity2) or (entity2 .. "|" .. entity1)

    M.relationshipGraph.relationships[key] = {
        entity1 = entity1,
        entity2 = entity2,
        type = relationshipType or "related",
        strength = strength or 0.5,
        createdAt = os.epoch and os.epoch("utc") or os.time(),
        interactions = 0
    }
end

-- Function 68: Get entity relationships
function M.getEntityRelationships(entityName)
    entityName = entityName:lower()
    local relationships = {}

    for _, rel in pairs(M.relationshipGraph.relationships) do
        if rel.entity1 == entityName or rel.entity2 == entityName then
            table.insert(relationships, rel)
        end
    end

    return relationships
end

-- Function 69: Strengthen relationship
function M.strengthenRelationship(entity1, entity2, amount)
    entity1 = entity1:lower()
    entity2 = entity2:lower()
    local key = entity1 < entity2 and (entity1 .. "|" .. entity2) or (entity2 .. "|" .. entity1)

    if M.relationshipGraph.relationships[key] then
        M.relationshipGraph.relationships[key].strength = math.min(1.0, M.relationshipGraph.relationships[key].strength + amount)
        M.relationshipGraph.relationships[key].interactions = M.relationshipGraph.relationships[key].interactions + 1
        return true
    end
    return false
end

-- Function 70: Find related entities
function M.findRelatedEntities(entityName, minStrength)
    entityName = entityName:lower()
    minStrength = minStrength or 0.3
    local related = {}

    for _, rel in pairs(M.relationshipGraph.relationships) do
        if rel.strength >= minStrength then
            if rel.entity1 == entityName then
                table.insert(related, {entity = rel.entity2, strength = rel.strength, type = rel.type})
            elseif rel.entity2 == entityName then
                table.insert(related, {entity = rel.entity1, strength = rel.strength, type = rel.type})
            end
        end
    end

    table.sort(related, function(a, b) return a.strength > b.strength end)
    return related
end

-- Function 71: Record entity mention
function M.recordEntityMention(entityName)
    entityName = entityName:lower()
    if M.relationshipGraph.entities[entityName] then
        M.relationshipGraph.entities[entityName].mentionCount = M.relationshipGraph.entities[entityName].mentionCount + 1
    end
end

-- Function 72: Get most mentioned entities
function M.getMostMentionedEntities(limit)
    limit = limit or 10
    local sorted = {}

    for name, entity in pairs(M.relationshipGraph.entities) do
        table.insert(sorted, {name = name, mentions = entity.mentionCount})
    end

    table.sort(sorted, function(a, b) return a.mentions > b.mentions end)

    local results = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(results, sorted[i])
    end
    return results
end

-- Function 73: Find entity by type
function M.findEntitiesByType(entityType)
    local results = {}

    for name, entity in pairs(M.relationshipGraph.entities) do
        if entity.type == entityType then
            table.insert(results, name)
        end
    end

    return results
end

-- Function 74: Get relationship strength
function M.getRelationshipStrength(entity1, entity2)
    entity1 = entity1:lower()
    entity2 = entity2:lower()
    local key = entity1 < entity2 and (entity1 .. "|" .. entity2) or (entity2 .. "|" .. entity1)

    if M.relationshipGraph.relationships[key] then
        return M.relationshipGraph.relationships[key].strength
    end
    return 0
end

-- Function 75: Get relationship graph summary
function M.getRelationshipGraphSummary()
    local entityCount = 0
    local relationshipCount = 0
    local totalStrength = 0

    for _ in pairs(M.relationshipGraph.entities) do
        entityCount = entityCount + 1
    end

    for _, rel in pairs(M.relationshipGraph.relationships) do
        relationshipCount = relationshipCount + 1
        totalStrength = totalStrength + rel.strength
    end

    return {
        entities = entityCount,
        relationships = relationshipCount,
        average_strength = relationshipCount > 0 and (totalStrength / relationshipCount) or 0,
        density = M.calculateGraphDensity()
    }
end

function M.calculateGraphDensity()
    local entityCount = 0
    for _ in pairs(M.relationshipGraph.entities) do
        entityCount = entityCount + 1
    end

    if entityCount <= 1 then return 0 end

    local relationshipCount = 0
    for _ in pairs(M.relationshipGraph.relationships) do
        relationshipCount = relationshipCount + 1
    end

    local maxPossible = (entityCount * (entityCount - 1)) / 2
    return relationshipCount / maxPossible
end

-- ============================================================================
-- TEMPORAL REASONING (Functions 76-85)
-- ============================================================================

-- Function 76: Record temporal event
function M.recordTemporalEvent(eventName, timestamp, duration, context)
    if not M.temporalEvents then
        M.temporalEvents = {}
    end

    table.insert(M.temporalEvents, {
        event = eventName,
        timestamp = timestamp or (os.epoch and os.epoch("utc") or os.time()),
        duration = duration or 0,
        context = context or {},
        relations = {}
    })
end

-- Function 77: Find events before
function M.findEventsBefore(referenceTime, limit)
    if not M.temporalEvents then return {} end

    limit = limit or 10
    local results = {}

    for _, event in ipairs(M.temporalEvents) do
        if event.timestamp < referenceTime then
            table.insert(results, event)
        end
    end

    table.sort(results, function(a, b) return a.timestamp > b.timestamp end)

    local limited = {}
    for i = 1, math.min(limit, #results) do
        table.insert(limited, results[i])
    end
    return limited
end

-- Function 78: Find events after
function M.findEventsAfter(referenceTime, limit)
    if not M.temporalEvents then return {} end

    limit = limit or 10
    local results = {}

    for _, event in ipairs(M.temporalEvents) do
        if event.timestamp > referenceTime then
            table.insert(results, event)
        end
    end

    table.sort(results, function(a, b) return a.timestamp < b.timestamp end)

    local limited = {}
    for i = 1, math.min(limit, #results) do
        table.insert(limited, results[i])
    end
    return limited
end

-- Function 79: Find events during range
function M.findEventsDuring(startTime, endTime)
    if not M.temporalEvents then return {} end

    local results = {}

    for _, event in ipairs(M.temporalEvents) do
        if event.timestamp >= startTime and event.timestamp <= endTime then
            table.insert(results, event)
        end
    end

    return results
end

-- Function 80: Get event timeline
function M.getEventTimeline()
    if not M.temporalEvents then return {} end

    local timeline = {}
    for _, event in ipairs(M.temporalEvents) do
        table.insert(timeline, event)
    end

    table.sort(timeline, function(a, b) return a.timestamp < b.timestamp end)
    return timeline
end

-- Function 81: Calculate time between events
function M.calculateTimeBetween(event1, event2)
    if not M.temporalEvents then return 0 end

    local e1, e2

    for _, event in ipairs(M.temporalEvents) do
        if event.event == event1 then e1 = event end
        if event.event == event2 then e2 = event end
    end

    if e1 and e2 then
        return math.abs(e2.timestamp - e1.timestamp)
    end

    return 0
end

-- Function 82: Find overlapping events
function M.findOverlappingEvents(referenceEvent)
    if not M.temporalEvents then return {} end

    local ref
    for _, event in ipairs(M.temporalEvents) do
        if event.event == referenceEvent then
            ref = event
            break
        end
    end

    if not ref then return {} end

    local overlapping = {}
    local refStart = ref.timestamp
    local refEnd = ref.timestamp + (ref.duration or 0)

    for _, event in ipairs(M.temporalEvents) do
        if event.event ~= referenceEvent then
            local eventStart = event.timestamp
            local eventEnd = event.timestamp + (event.duration or 0)

            if (eventStart <= refEnd and eventEnd >= refStart) then
                table.insert(overlapping, event)
            end
        end
    end

    return overlapping
end

-- Function 83: Get temporal clusters
function M.getTemporalClusters(timeWindow)
    if not M.temporalEvents then return {} end

    timeWindow = timeWindow or 3600  -- 1 hour default

    local sorted = {}
    for _, event in ipairs(M.temporalEvents) do
        table.insert(sorted, event)
    end
    table.sort(sorted, function(a, b) return a.timestamp < b.timestamp end)

    local clusters = {}
    local currentCluster = {}

    for _, event in ipairs(sorted) do
        if #currentCluster == 0 then
            table.insert(currentCluster, event)
        else
            local lastEvent = currentCluster[#currentCluster]
            if event.timestamp - lastEvent.timestamp <= timeWindow then
                table.insert(currentCluster, event)
            else
                table.insert(clusters, currentCluster)
                currentCluster = {event}
            end
        end
    end

    if #currentCluster > 0 then
        table.insert(clusters, currentCluster)
    end

    return clusters
end

-- Function 84: Get temporal statistics
function M.getTemporalStatistics()
    if not M.temporalEvents or #M.temporalEvents == 0 then
        return {total = 0}
    end

    local earliest = M.temporalEvents[1].timestamp
    local latest = M.temporalEvents[1].timestamp

    for _, event in ipairs(M.temporalEvents) do
        if event.timestamp < earliest then earliest = event.timestamp end
        if event.timestamp > latest then latest = event.timestamp end
    end

    return {
        total = #M.temporalEvents,
        earliest = earliest,
        latest = latest,
        span = latest - earliest,
        average_duration = M.calculateAverageEventDuration()
    }
end

function M.calculateAverageEventDuration()
    if not M.temporalEvents or #M.temporalEvents == 0 then return 0 end

    local total = 0
    local count = 0

    for _, event in ipairs(M.temporalEvents) do
        if event.duration and event.duration > 0 then
            total = total + event.duration
            count = count + 1
        end
    end

    return count > 0 and (total / count) or 0
end

-- Function 85: Clear old temporal events
function M.clearOldTemporalEvents(cutoffTime)
    if not M.temporalEvents then return 0 end

    local kept = {}
    local removed = 0

    for _, event in ipairs(M.temporalEvents) do
        if event.timestamp >= cutoffTime then
            table.insert(kept, event)
        else
            removed = removed + 1
        end
    end

    M.temporalEvents = kept
    return removed
end

-- ============================================================================
-- SESSION MEMORY (Functions 86-97+)
-- ============================================================================

-- Function 86: Start session
function M.startSession(userName)
    M.sessionMemory = {
        user = userName,
        startTime = os.epoch and os.epoch("utc") or os.time(),
        turns = {},
        currentTopic = nil,
        topicStack = {},
        emotionalArc = {},
        contextFlags = {},
        pendingQuestions = {},
        sharedReferences = {},
        conversationFlow = "normal",
        callbacks = {}
    }

    if userName then
        local user = M.getUser(userName)
        user.conversationCount = user.conversationCount + 1
        M.saveUsers()
    end

    return M.sessionMemory
end

-- Function 87: Add turn
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

    if metadata.sentiment then
        table.insert(M.sessionMemory.emotionalArc, metadata.sentiment)
    end

    return turn
end

-- Function 88: Get recent context
function M.getRecentContext(turns)
    turns = turns or 5
    local result = {}
    local total = #M.sessionMemory.turns
    for i = math.max(1, total - turns + 1), total do
        result[#result+1] = M.sessionMemory.turns[i]
    end
    return result
end

-- Function 89: Get session summary
function M.getSessionSummary()
    local sess = M.sessionMemory

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

-- Function 90: Get context for response
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

-- Function 91: Track question
function M.trackQuestion(question, askedBy)
    table.insert(M.sessionMemory.pendingQuestions, {
        question = question,
        askedBy = askedBy,
        time = os.epoch and os.epoch("utc") or os.time()
    })
end

-- Function 92: Mark question answered
function M.questionAnswered(questionText)
    for i, q in ipairs(M.sessionMemory.pendingQuestions) do
        if q.question:lower():find(questionText:lower(), 1, true) then
            table.remove(M.sessionMemory.pendingQuestions, i)
            return true
        end
    end
    return false
end

-- Function 93: Get unanswered questions
function M.getUnansweredQuestions()
    return M.sessionMemory.pendingQuestions
end

-- Function 94: Add shared reference
function M.addSharedReference(reference, context)
    M.sessionMemory.sharedReferences[reference:lower()] = {
        reference = reference,
        context = context,
        mentions = 1,
        lastMentioned = os.epoch and os.epoch("utc") or os.time()
    }
end

-- Function 95: Mention reference
function M.mentionReference(reference)
    local ref = M.sessionMemory.sharedReferences[reference:lower()]
    if ref then
        ref.mentions = ref.mentions + 1
        ref.lastMentioned = os.epoch and os.epoch("utc") or os.time()
    end
end

-- Function 96: Get shared references
function M.getSharedReferences()
    local refs = {}
    for _, ref in pairs(M.sessionMemory.sharedReferences) do
        table.insert(refs, ref)
    end
    table.sort(refs, function(a, b) return a.mentions > b.mentions end)
    return refs
end

-- Function 97: Get continuity suggestions
function M.getContinuitySuggestions()
    local suggestions = {}

    if #M.sessionMemory.pendingQuestions > 0 then
        local oldest = M.sessionMemory.pendingQuestions[1]
        if oldest.askedBy == "user" then
            suggestions.unansweredQuestion = oldest.question
        end
    end

    if M.sessionMemory.currentTopic and #M.sessionMemory.turns > 3 then
        suggestions.previousTopic = M.sessionMemory.currentTopic
    end

    local refs = M.getSharedReferences()
    if #refs > 0 then
        suggestions.sharedReference = refs[1].reference
    end

    return suggestions
end

-- ============================================================================
-- ADDITIONAL ADVANCED FUNCTIONS (Functions 98+)
-- ============================================================================

-- Function 98: Add callback/promise
function M.addCallback(promise, relatedTo)
    if not M.sessionMemory.callbacks then
        M.sessionMemory.callbacks = {}
    end

    table.insert(M.sessionMemory.callbacks, {
        promise = promise,
        relatedTo = relatedTo,
        time = os.epoch and os.epoch("utc") or os.time()
    })
end

-- Function 99: Get callbacks
function M.getCallbacks()
    return M.sessionMemory.callbacks or {}
end

-- Function 100: Detect self-statement
function M.detectSelfStatement(text)
    local lower = text:lower()

    local identity = lower:match("i'm a (%w+)") or lower:match("i am a (%w+)")
    if identity then
        return {type = "identity", value = identity}
    end

    local state = lower:match("i'm (%w+)") or lower:match("i am (%w+)")
    if state then
        return {type = "state", value = state}
    end

    local likes = lower:match("i like (%w+)") or lower:match("i love (%w+)")
    if likes then
        return {type = "likes", value = likes}
    end

    local dislikes = lower:match("i don't like (%w+)") or lower:match("i hate (%w+)")
    if dislikes then
        return {type = "dislikes", value = dislikes}
    end

    local name = lower:match("my name is (%w+)") or lower:match("i'm called (%w+)") or lower:match("call me (%w+)")
    if name then
        return {type = "name", value = name}
    end

    local favType, favVal = lower:match("my favorite (%w+) is (%w+)")
    if favType and favVal then
        return {type = "favorite", category = favType, value = favVal}
    end

    return nil
end

-- Function 101: Process and learn from text
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

-- Function 102: Initialize system
function M.init()
    M.loadUsers()
    M.loadFacts()
    M.loadEpisodicMemory()
    return true
end

-- Function 103: Get comprehensive statistics
function M.getStats()
    local userCount = 0
    for _ in pairs(M.users) do userCount = userCount + 1 end

    local factCount = 0
    for _ in pairs(M.learnedFacts) do factCount = factCount + 1 end

    return {
        users = userCount,
        learnedFacts = factCount,
        sessionTurns = #M.sessionMemory.turns,
        episodicMemories = M.getTotalEpisodicMemories(),
        semanticConcepts = M.getTotalSemanticConcepts(),
        workingMemoryLoad = #M.workingMemory.items,
        entities = M.getTotalEntities(),
        relationships = M.getTotalRelationships()
    }
end

function M.getTotalEpisodicMemories()
    local count = 0
    for _, memories in pairs(M.episodicMemory) do
        count = count + #memories
    end
    return count
end

function M.getTotalSemanticConcepts()
    local count = 0
    for _ in pairs(M.semanticMemory) do
        count = count + 1
    end
    return count
end

function M.getTotalEntities()
    local count = 0
    for _ in pairs(M.relationshipGraph.entities) do
        count = count + 1
    end
    return count
end

function M.getTotalRelationships()
    local count = 0
    for _ in pairs(M.relationshipGraph.relationships) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- MASTER_BRAIN.LUA INTERFACE FUNCTIONS
-- ============================================================================

-- Get recent context for a user (expected by master_brain.lua)
function M.getRecentContext(user)
    if not user then return {} end
    
    local context = {}
    local userMem = M.getUser(user)
    
    if userMem then
        -- Get recent interactions
        local recentInteractions = M.getRecentInteractions(user, 5)
        if recentInteractions then
            context.recent_interactions = recentInteractions
        end
        
        -- Get user facts
        local facts = M.getAllUserFacts(user)
        if facts then
            context.user_facts = facts
        end
        
        -- Get mood trend
        local mood = M.getUserMoodTrend(user)
        if mood then
            context.mood_trend = mood
        end
        
        -- Get favorite topics
        local topics = M.getUserFavoriteTopics(user, 3)
        if topics then
            context.favorite_topics = topics
        end
        
        -- Get communication style
        local style = M.getUserCommunicationStyle(user)
        if style then
            context.communication_style = style
        end
        
        -- Get relationship quality
        local relationship = M.getRelationshipQuality(user)
        if relationship then
            context.relationship_quality = relationship
        end
    end
    
    return context
end

return M
