-- context_markov.lua
-- Context-aware Markov chains that understand conversation flow

local M = {}

-- ============================================================================
-- CONTEXT-TAGGED MARKOV CHAINS
-- ============================================================================

M.chains = {
    -- Context: What happened before this response
    contexts = {},
    
    -- Responses tagged by context
    responses = {}
}

M.stats = {
    total_patterns = 0,
    contexts_learned = 0,
    successful_generations = 0
}

-- ============================================================================
-- CONTEXT DETECTION
-- ============================================================================

function M.detectContext(previous_messages, current_message)
    local context_tags = {}
    
    if #previous_messages == 0 then
        table.insert(context_tags, "conversation_start")
        return context_tags
    end
    
    local last_msg = previous_messages[#previous_messages]
    local msg_lower = (current_message or ""):lower()
    local last_lower = (last_msg or ""):lower()
    
    -- Was a question asked?
    if last_lower:find("?") then
        table.insert(context_tags, "answering_question")
        
        -- What kind of question?
        if last_lower:find("how are you") or last_lower:find("how's it") or last_lower:find("how about you") then
            table.insert(context_tags, "status_question")
        elseif last_lower:find("what") then
            table.insert(context_tags, "what_question")
        elseif last_lower:find("why") then
            table.insert(context_tags, "why_question")
        elseif last_lower:find("how") then
            table.insert(context_tags, "how_question")
        end
    end
    
    -- Is this a question being asked?
    if msg_lower:find("?") then
        table.insert(context_tags, "asking_question")
    end
    
    -- Response to statement
    if not last_lower:find("?") and #previous_messages > 0 then
        table.insert(context_tags, "responding_to_statement")
        
        -- What kind of statement?
        if last_lower:find("i'?m ") or last_lower:find("im ") then
            if last_lower:find("good") or last_lower:find("fine") or last_lower:find("okay") then
                table.insert(context_tags, "status_positive")
            elseif last_lower:find("bad") or last_lower:find("not great") then
                table.insert(context_tags, "status_negative")
            else
                table.insert(context_tags, "status_neutral")
            end
        end
    end
    
    -- Short responses
    if #msg_lower < 10 then
        table.insert(context_tags, "short_response")
        
        if msg_lower:find("^yeah") or msg_lower:find("^yes") or msg_lower:find("^yup") then
            table.insert(context_tags, "agreement")
        elseif msg_lower:find("^nah") or msg_lower:find("^no") or msg_lower:find("^nope") then
            table.insert(context_tags, "disagreement")
        elseif msg_lower:find("^cool") or msg_lower:find("^nice") or msg_lower:find("^sweet") then
            table.insert(context_tags, "acknowledgment")
        end
    end
    
    -- Greeting
    if msg_lower:find("^hi") or msg_lower:find("^hey") or msg_lower:find("^hello") or msg_lower:find("^yo") then
        table.insert(context_tags, "greeting")
    end
    
    -- Gratitude
    if msg_lower:find("thank") or msg_lower:find("thx") or msg_lower:find("appreciate") then
        table.insert(context_tags, "gratitude")
    end
    
    -- Emotional tone
    local positive_words = {"awesome", "great", "amazing", "love", "perfect", "excellent"}
    local negative_words = {"bad", "terrible", "awful", "hate", "annoying", "frustrating"}
    
    for _, word in ipairs(positive_words) do
        if msg_lower:find(word) then
            table.insert(context_tags, "positive_emotion")
            break
        end
    end
    
    for _, word in ipairs(negative_words) do
        if msg_lower:find(word) then
            table.insert(context_tags, "negative_emotion")
            break
        end
    end
    
    -- Conversation flow
    if #previous_messages >= 3 then
        table.insert(context_tags, "deep_conversation")
    elseif #previous_messages >= 1 then
        table.insert(context_tags, "mid_conversation")
    end
    
    return context_tags
end

-- ============================================================================
-- CONTEXT-AWARE TRAINING
-- ============================================================================

function M.trainWithContext(message, response, context_tags)
    if not message or not response or #message == 0 or #response == 0 then
        return
    end
    
    -- Create context key
    local context_key = table.concat(context_tags, "|")
    if context_key == "" then
        context_key = "general"
    end
    
    -- Initialize context if new
    if not M.chains.contexts[context_key] then
        M.chains.contexts[context_key] = {
            starters = {},
            sequences = {},
            count = 0
        }
        M.stats.contexts_learned = M.stats.contexts_learned + 1
    end
    
    local context = M.chains.contexts[context_key]
    
    -- Add response as starter
    local first_word = response:match("^%S+")
    if first_word then
        context.starters[first_word] = (context.starters[first_word] or 0) + 1
    end
    
    -- Build word chains (order-2 Markov)
    local words = {}
    for word in response:gmatch("%S+") do
        table.insert(words, word)
    end
    
    for i = 1, #words - 2 do
        local key = words[i] .. " " .. words[i+1]
        local next_word = words[i+2]
        
        if not context.sequences[key] then
            context.sequences[key] = {}
        end
        
        table.insert(context.sequences[key], next_word)
        M.stats.total_patterns = M.stats.total_patterns + 1
    end
    
    context.count = context.count + 1
end

-- ============================================================================
-- SMART GENERATION WITH CONTEXT
-- ============================================================================

function M.generateWithContext(previous_messages, current_message, max_words)
    max_words = max_words or 20
    
    -- Detect context from conversation
    local context_tags = M.detectContext(previous_messages, current_message)
    
    -- Try to find matching context
    local best_context = nil
    local best_score = 0
    
    for context_key, context_data in pairs(M.chains.contexts) do
        local score = 0
        local key_tags = {}
        for tag in context_key:gmatch("[^|]+") do
            table.insert(key_tags, tag)
        end
        
        -- Score based on matching tags
        for _, tag in ipairs(context_tags) do
            for _, key_tag in ipairs(key_tags) do
                if tag == key_tag then
                    score = score + 1
                end
            end
        end
        
        if score > best_score then
            best_score = score
            best_context = context_data
        end
    end
    
    -- Fallback to general context if no good match
    if not best_context or best_score == 0 then
        best_context = M.chains.contexts["general"]
    end
    
    if not best_context or not next(best_context.starters) then
        return nil
    end
    
    -- Generate response
    local response_words = {}
    
    -- Pick starter word weighted by frequency
    local starters = {}
    for word, count in pairs(best_context.starters) do
        for i = 1, count do
            table.insert(starters, word)
        end
    end
    
    if #starters == 0 then return nil end
    
    local current = starters[math.random(#starters)]
    table.insert(response_words, current)
    
    -- Generate next words
    for i = 2, max_words do
        if #response_words < 2 then break end
        
        local key = response_words[#response_words - 1] .. " " .. response_words[#response_words]
        local options = best_context.sequences[key]
        
        if not options or #options == 0 then break end
        
        local next_word = options[math.random(#options)]
        table.insert(response_words, next_word)
        
        -- Stop at natural sentence endings
        if next_word:match("[.!?]$") then
            break
        end
    end
    
    if #response_words >= 3 then
        M.stats.successful_generations = M.stats.successful_generations + 1
        return table.concat(response_words, " ")
    end
    
    return nil
end

-- ============================================================================
-- IMPORT FROM TRAINING DATA
-- ============================================================================

function M.importFromTrainingLog(filepath)
    if not fs.exists(filepath) then
        print("Training log not found: " .. filepath)
        return 0
    end
    
    -- Check if it's CSV format (comma or pipe delimited)
    local is_csv = filepath:find("%.csv$") ~= nil
    local is_pipe_delimited = false
    
    print("Importing training data" .. (is_csv and " (CSV format)" or "") .. "...")
    local file = fs.open(filepath, "r")
    local imported = 0
    local line_num = 0
    
    if is_csv then
        -- Check if first line is pipe-delimited
        local first_line = file.readLine()
        if first_line and first_line:find("|") then
            is_pipe_delimited = true
        end
        line_num = 1
    end
    
    while true do
        local line = file.readLine()
        if not line then break end
        
        line_num = line_num + 1
        
        if is_csv then
            local fields
            
            if is_pipe_delimited then
                -- Simple split on pipe
                fields = {}
                for field in line:gmatch("[^|]+") do
                    table.insert(fields, field)
                end
            else
                -- Parse complex CSV with quotes
                local function csvParse(csvLine)
                local fields = {}
                local field = ""
                local in_quotes = false
                
                for i = 1, #csvLine do
                    local char = csvLine:sub(i, i)
                    if char == '"' then
                        in_quotes = not in_quotes
                    elseif char == ',' and not in_quotes then
                        table.insert(fields, field)
                        field = ""
                    else
                        field = field .. char
                    end
                end
                table.insert(fields, field)
                return fields
            end
            
                fields = csvParse(line)
            end
            if #fields >= 5 then
                local tags = {fields[5]}  -- topic
                if fields[6] then
                    local turn = tonumber(fields[6])
                    if turn and turn == 1 then
                        table.insert(tags, "conversation_start")
                    elseif turn and turn > 5 then
                        table.insert(tags, "deep_conversation")
                    end
                end
                
                M.trainWithContext(fields[2], fields[4], tags)  -- message_a, message_b
                imported = imported + 1
            end
        else
            -- Original serialize format
            local success, exchange = pcall(textutils.unserialize, line)
            if success and exchange then
                local context_tags = exchange.context or {}
                local tags = {}
                if type(context_tags) == "table" then
                    if context_tags.topic then
                        table.insert(tags, "topic:" .. context_tags.topic)
                    end
                    if context_tags.emotional_state then
                        table.insert(tags, "emotion:" .. context_tags.emotional_state)
                    end
                    if context_tags.turn then
                        if context_tags.turn == 1 then
                            table.insert(tags, "conversation_start")
                        elseif context_tags.turn > 5 then
                            table.insert(tags, "deep_conversation")
                        else
                            table.insert(tags, "mid_conversation")
                        end
                    end
                end
                
                if exchange.message_a and exchange.message_b then
                    M.trainWithContext(exchange.message_a, exchange.message_b, tags)
                    imported = imported + 1
                end
            end
        end
        
        if line_num % 1000 == 0 then
            print(string.format("  Processed: %d lines, imported: %d patterns", line_num, imported))
        end
    end
    
    file.close()
    
    print(string.format("Import complete! %d conversation patterns learned", imported))
    print(string.format("Total contexts: %d", M.stats.contexts_learned))
    
    return imported
end

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function M.save(filepath)
    filepath = filepath or "context_markov.dat"
    
    local data = {
        chains = M.chains,
        stats = M.stats
    }
    
    local file = fs.open(filepath, "w")
    file.write(textutils.serialize(data))
    file.close()
    
    return true
end

function M.load(filepath)
    filepath = filepath or "context_markov.dat"
    
    if not fs.exists(filepath) then
        return false
    end
    
    local file = fs.open(filepath, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    
    if data then
        M.chains = data.chains or M.chains
        M.stats = data.stats or M.stats
        return true
    end
    
    return false
end

function M.getStats()
    local context_count = 0
    for _ in pairs(M.chains.contexts) do
        context_count = context_count + 1
    end
    
    return {
        total_patterns = M.stats.total_patterns,
        contexts = context_count,
        successful_generations = M.stats.successful_generations
    }
end

return M
