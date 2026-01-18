-- Module: memory_search.lua
-- Semantic search through conversation history using embeddings

local M = {}

-- ============================================================================
-- MEMORY INDEX
-- ============================================================================

M.memory_index = {
    messages = {},      -- List of {text, embedding, timestamp, user}
    embeddings = nil,   -- Embeddings module
    attention = nil,    -- Attention module
    max_memories = 10000
}

-- ============================================================================
-- INITIALIZE
-- ============================================================================

function M.initialize(embeddings_module, attention_module)
    M.memory_index.embeddings = embeddings_module
    M.memory_index.attention = attention_module
    
    -- Load existing index
    M.load()
end

-- ============================================================================
-- ADD TO MEMORY
-- ============================================================================

function M.addMemory(text, user, metadata)
    if not M.memory_index.embeddings then
        return false
    end
    
    -- Create embedding for this message
    local embedding = M.memory_index.embeddings.sentenceToEmbedding(text)
    
    local memory = {
        text = text,
        embedding = embedding,
        timestamp = os.time(),
        user = user or "unknown",
        metadata = metadata or {}
    }
    
    table.insert(M.memory_index.messages, memory)
    
    -- Keep only last N memories
    if #M.memory_index.messages > M.memory_index.max_memories then
        table.remove(M.memory_index.messages, 1)
    end
    
    -- Auto-save periodically
    if #M.memory_index.messages % 50 == 0 then
        M.save()
    end
    
    return true
end

-- ============================================================================
-- SEMANTIC SEARCH
-- ============================================================================

function M.search(query, top_k, filters)
    --[[
    Search memories semantically
    query: text to search for
    top_k: number of results
    filters: optional {user="Player", after_time=123456}
    
    Returns: list of relevant memories
    ]]
    
    top_k = top_k or 5
    filters = filters or {}
    
    if not M.memory_index.embeddings then
        return {}
    end
    
    -- Get query embedding
    local query_embedding = M.memory_index.embeddings.sentenceToEmbedding(query)
    
    -- Compute similarities
    local scored_memories = {}
    
    for i, memory in ipairs(M.memory_index.messages) do
        -- Apply filters
        local passes_filter = true
        
        if filters.user and memory.user ~= filters.user then
            passes_filter = false
        end
        
        if filters.after_time and memory.timestamp < filters.after_time then
            passes_filter = false
        end
        
        if filters.before_time and memory.timestamp > filters.before_time then
            passes_filter = false
        end
        
        if passes_filter then
            local similarity = M.cosineSimilarity(query_embedding, memory.embedding)
            
            -- Boost recent memories slightly
            local recency_boost = 1.0
            local age = os.time() - memory.timestamp
            if age < 300 then  -- Last 5 minutes
                recency_boost = 1.2
            elseif age < 1800 then  -- Last 30 minutes
                recency_boost = 1.1
            end
            
            table.insert(scored_memories, {
                memory = memory,
                score = similarity * recency_boost,
                index = i
            })
        end
    end
    
    -- Sort by score
    table.sort(scored_memories, function(a, b) return a.score > b.score end)
    
    -- Return top K
    local results = {}
    for i = 1, math.min(top_k, #scored_memories) do
        table.insert(results, scored_memories[i])
    end
    
    return results
end

-- ============================================================================
-- ATTENTION-BASED SEARCH
-- ============================================================================

function M.attentionSearch(query, top_k)
    --[[
    Use attention mechanism to find relevant memories
    More sophisticated than simple similarity
    ]]
    
    top_k = top_k or 5
    
    if not M.memory_index.attention or not M.memory_index.embeddings then
        return M.search(query, top_k)  -- Fallback to regular search
    end
    
    local query_embedding = M.memory_index.embeddings.sentenceToEmbedding(query)
    
    -- Extract all embeddings
    local memory_embeddings = {}
    for _, memory in ipairs(M.memory_index.messages) do
        table.insert(memory_embeddings, memory.embedding)
    end
    
    if #memory_embeddings == 0 then
        return {}
    end
    
    -- Use attention to find relevant indices
    local relevant_indices = M.memory_index.attention.contextualAttention(
        query_embedding,
        memory_embeddings,
        top_k
    )
    
    -- Get the actual memories
    local results = {}
    for _, idx in ipairs(relevant_indices) do
        local memory = M.memory_index.messages[idx]
        local similarity = M.cosineSimilarity(query_embedding, memory.embedding)
        
        table.insert(results, {
            memory = memory,
            score = similarity,
            index = idx
        })
    end
    
    return results
end

-- ============================================================================
-- CLUSTER MEMORIES (find patterns)
-- ============================================================================

function M.clusterMemories(num_clusters)
    --[[
    Group similar memories together
    Helps find conversation patterns
    ]]
    
    num_clusters = num_clusters or 5
    
    if #M.memory_index.messages < num_clusters then
        return {}
    end
    
    -- Simple K-means clustering
    local embeddings = {}
    for _, memory in ipairs(M.memory_index.messages) do
        table.insert(embeddings, memory.embedding)
    end
    
    -- Initialize centroids randomly
    local centroids = {}
    for i = 1, num_clusters do
        local idx = math.random(#embeddings)
        centroids[i] = M.copyVector(embeddings[idx])
    end
    
    -- K-means iterations
    for iteration = 1, 10 do
        -- Assign to clusters
        local clusters = {}
        for i = 1, num_clusters do
            clusters[i] = {}
        end
        
        for idx, emb in ipairs(embeddings) do
            local best_cluster = 1
            local best_dist = M.distance(emb, centroids[1])
            
            for c = 2, num_clusters do
                local dist = M.distance(emb, centroids[c])
                if dist < best_dist then
                    best_dist = dist
                    best_cluster = c
                end
            end
            
            table.insert(clusters[best_cluster], idx)
        end
        
        -- Update centroids
        for c = 1, num_clusters do
            if #clusters[c] > 0 then
                centroids[c] = M.computeCentroid(embeddings, clusters[c])
            end
        end
    end
    
    -- Build cluster results
    local results = {}
    for c = 1, num_clusters do
        local cluster_memories = {}
        for _, idx in ipairs(clusters[c]) do
            table.insert(cluster_memories, M.memory_index.messages[idx])
        end
        
        table.insert(results, {
            id = c,
            size = #cluster_memories,
            memories = cluster_memories
        })
    end
    
    return results
end

-- ============================================================================
-- SUMMARIZE CONVERSATION HISTORY
-- ============================================================================

function M.summarizeHistory(user, max_tokens)
    --[[
    Create a summary of conversation history for context
    ]]
    
    max_tokens = max_tokens or 200
    
    -- Get recent memories for user
    local recent = {}
    for i = #M.memory_index.messages, 1, -1 do
        local memory = M.memory_index.messages[i]
        if memory.user == user then
            table.insert(recent, memory)
            if #recent >= 20 then
                break
            end
        end
    end
    
    if #recent == 0 then
        return "No conversation history."
    end
    
    -- Extract key topics using clustering
    local summary = "Recent conversation topics: "
    
    -- Simple frequency-based summary
    local word_freq = {}
    for _, memory in ipairs(recent) do
        for word in memory.text:gmatch("%S+") do
            word = word:gsub("[%p]+", ""):lower()
            if #word > 4 then
                word_freq[word] = (word_freq[word] or 0) + 1
            end
        end
    end
    
    -- Get top words
    local sorted = {}
    for word, count in pairs(word_freq) do
        table.insert(sorted, {word = word, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    local topics = {}
    for i = 1, math.min(5, #sorted) do
        table.insert(topics, sorted[i].word)
    end
    
    return summary .. table.concat(topics, ", ")
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function M.cosineSimilarity(vec1, vec2)
    local dot = 0
    local norm1 = 0
    local norm2 = 0
    
    for i = 1, #vec1 do
        dot = dot + vec1[i] * vec2[i]
        norm1 = norm1 + vec1[i] * vec1[i]
        norm2 = norm2 + vec2[i] * vec2[i]
    end
    
    norm1 = math.sqrt(norm1)
    norm2 = math.sqrt(norm2)
    
    if norm1 == 0 or norm2 == 0 then return 0 end
    
    return dot / (norm1 * norm2)
end

function M.distance(vec1, vec2)
    local sum = 0
    for i = 1, #vec1 do
        local diff = vec1[i] - vec2[i]
        sum = sum + diff * diff
    end
    return math.sqrt(sum)
end

function M.copyVector(vec)
    local copy = {}
    for i = 1, #vec do
        copy[i] = vec[i]
    end
    return copy
end

function M.computeCentroid(embeddings, indices)
    if #indices == 0 then return embeddings[1] end
    
    local dim = #embeddings[1]
    local centroid = {}
    
    for i = 1, dim do
        centroid[i] = 0
    end
    
    for _, idx in ipairs(indices) do
        for i = 1, dim do
            centroid[i] = centroid[i] + embeddings[idx][i]
        end
    end
    
    for i = 1, dim do
        centroid[i] = centroid[i] / #indices
    end
    
    return centroid
end

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function M.save(filename)
    filename = filename or "memory_index.dat"
    
    -- Don't save embeddings, just text and metadata
    local save_data = {
        messages = {},
        max_memories = M.memory_index.max_memories
    }
    
    for _, memory in ipairs(M.memory_index.messages) do
        table.insert(save_data.messages, {
            text = memory.text,
            timestamp = memory.timestamp,
            user = memory.user,
            metadata = memory.metadata
        })
    end
    
    local serialized = textutils.serialize(save_data)
    local file = fs.open(filename, "w")
    if file then
        file.write(serialized)
        file.close()
        return true
    end
    return false
end

function M.load(filename)
    filename = filename or "memory_index.dat"
    
    if not fs.exists(filename) then
        return false
    end
    
    local file = fs.open(filename, "r")
    if file then
        local data = textutils.unserialize(file.readAll())
        file.close()
        
        if data and M.memory_index.embeddings then
            -- Rebuild embeddings
            for _, memory_data in ipairs(data.messages) do
                local embedding = M.memory_index.embeddings.sentenceToEmbedding(memory_data.text)
                
                table.insert(M.memory_index.messages, {
                    text = memory_data.text,
                    embedding = embedding,
                    timestamp = memory_data.timestamp,
                    user = memory_data.user,
                    metadata = memory_data.metadata or {}
                })
            end
            
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- STATS
-- ============================================================================

function M.getStats()
    return {
        total_memories = #M.memory_index.messages,
        max_capacity = M.memory_index.max_memories,
        usage_percent = (#M.memory_index.messages / M.memory_index.max_memories) * 100
    }
end

return M
