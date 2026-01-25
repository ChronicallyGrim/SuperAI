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
        table.insert(context_tags, "casual")
    end
    
    -- Personal/casual questions (how are you, etc.)
    if msg_lower:find("how are you") or msg_lower:find("how're you") or
       msg_lower:find("how do you feel") or msg_lower:find("how's it going") or
       msg_lower:find("what's up") or msg_lower:find("whats up") or
       msg_lower:find("you doing") or msg_lower:find("you good") then
        table.insert(context_tags, "how_are_you")
        table.insert(context_tags, "personal")
        table.insert(context_tags, "casual")
    end
    
    -- Questions about the AI
    if msg_lower:find("who are you") or msg_lower:find("what are you") or
       msg_lower:find("your name") or msg_lower:find("about yourself") or
       msg_lower:find("are you real") or msg_lower:find("are you a") then
        table.insert(context_tags, "about_me")
        table.insert(context_tags, "personal")
    end
    
    -- Farewells
    if msg_lower:find("^bye") or msg_lower:find("goodbye") or msg_lower:find("see you") or
       msg_lower:find("gotta go") or msg_lower:find("talk later") or msg_lower:find("i'm leaving") then
        table.insert(context_tags, "goodbyes")
        table.insert(context_tags, "casual")
    end
    
    -- Gratitude
    if msg_lower:find("thank") or msg_lower:find("thx") or msg_lower:find("appreciate") then
        table.insert(context_tags, "gratitude")
        table.insert(context_tags, "thanks")
        table.insert(context_tags, "casual")
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

-- Maximum sequences per key (prevents unbounded growth)
local MAX_SEQUENCES_PER_KEY = 10  -- Reduced from 20
local MAX_CONTEXTS = 50           -- Reduced from 100
local MAX_TOTAL_PATTERNS = 50000  -- Hard limit on total patterns

function M.trainWithContext(message, response, context_tags)
    if not message or not response or #message == 0 or #response == 0 then
        return
    end
    
    -- Check total patterns limit
    if M.stats.total_patterns >= MAX_TOTAL_PATTERNS then
        return  -- Stop learning when limit reached
    end
    
    -- Create context key
    local context_key = table.concat(context_tags, "|")
    if context_key == "" then
        context_key = "general"
    end
    
    -- Limit total contexts
    local context_count = 0
    for _ in pairs(M.chains.contexts) do
        context_count = context_count + 1
    end
    
    -- Initialize context if new (but respect limit)
    if not M.chains.contexts[context_key] then
        if context_count >= MAX_CONTEXTS then
            -- Use "general" instead of creating new context
            context_key = "general"
            if not M.chains.contexts[context_key] then
                M.chains.contexts[context_key] = {
                    starters = {},
                    sequences = {},
                    count = 0
                }
            end
        else
            M.chains.contexts[context_key] = {
                starters = {},
                sequences = {},
                count = 0
            }
            M.stats.contexts_learned = M.stats.contexts_learned + 1
        end
    end
    
    local context = M.chains.contexts[context_key]
    
    -- Add response as starter (use counts, not arrays)
    local first_word = response:match("^%S+")
    if first_word then
        context.starters[first_word] = (context.starters[first_word] or 0) + 1
        -- Limit starters
        if context.starters[first_word] > 50 then
            context.starters[first_word] = 50
        end
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
        
        -- Limit sequence array size
        if #context.sequences[key] < MAX_SEQUENCES_PER_KEY then
            table.insert(context.sequences[key], next_word)
            M.stats.total_patterns = M.stats.total_patterns + 1
        else
            -- Replace random entry to keep variety
            local idx = math.random(MAX_SEQUENCES_PER_KEY)
            context.sequences[key][idx] = next_word
        end
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
    
    if not best_context then
        return nil
    end
    
    -- Check if we have any starters
    if not best_context.starters or not next(best_context.starters) then
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
    
    local first_word = starters[math.random(#starters)]
    table.insert(response_words, first_word)
    
    -- Find a sequence key that starts with our first word to get second word
    local found_second = false
    for key, options in pairs(best_context.sequences or {}) do
        local key_first = key:match("^(%S+)")
        if key_first == first_word and options and #options > 0 then
            -- Extract second word from key and add continuation
            local key_second = key:match("^%S+%s+(%S+)")
            if key_second then
                table.insert(response_words, key_second)
                local next_word = options[math.random(#options)]
                table.insert(response_words, next_word)
                found_second = true
                break
            end
        end
    end
    
    -- If couldn't find matching sequence, try any sequence
    if not found_second and best_context.sequences then
        for key, options in pairs(best_context.sequences) do
            if options and #options > 0 then
                -- Use this key's words as start
                local w1, w2 = key:match("^(%S+)%s+(%S+)")
                if w1 and w2 then
                    response_words = {w1, w2}
                    local next_word = options[math.random(#options)]
                    table.insert(response_words, next_word)
                    found_second = true
                    break
                end
            end
        end
    end
    
    if not found_second then
        return nil
    end
    
    -- Continue generating with 2-word keys
    for i = 4, max_words do
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
        M.stats.successful_generations = (M.stats.successful_generations or 0) + 1
        return table.concat(response_words, " ")
    end
    
    return nil
end

-- ============================================================================
-- IMPORT FROM TRAINING DATA
-- ============================================================================

function M.importFromTrainingLog(filepath)
    -- Try loading RAID system
    local raid = nil
    local success_raid, raid_module = pcall(require, "raid_system")
    if success_raid then
        raid = raid_module
        raid.init()
    end
    
    -- Read file content (from RAID or local)
    local content = nil
    local raid_path = filepath:gsub("^/", "")  -- Remove leading slash for RAID
    
    if raid and raid.exists(raid_path) then
        print("Reading from RAID: " .. raid_path)
        content = raid.read(raid_path)
    elseif fs.exists(filepath) then
        print("Reading from local: " .. filepath)
        local file = fs.open(filepath, "r")
        content = file.readAll()
        file.close()
    else
        print("Training log not found: " .. filepath)
        return 0
    end
    
    if not content or content == "" then
        print("Empty training log")
        return 0
    end
    
    -- Check if it's CSV format (comma or pipe delimited)
    local is_csv = filepath:find("%.csv$") ~= nil
    local is_pipe_delimited = false
    
    print("Importing training data" .. (is_csv and " (CSV format)" or "") .. "...")
    local imported = 0
    local line_num = 0
    
    -- Split content into lines
    local lines = {}
    for line in content:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    if is_csv and #lines > 0 then
        -- Check if first line is pipe-delimited
        if lines[1]:find("|") then
            is_pipe_delimited = true
        end
        line_num = 1
        table.remove(lines, 1)  -- Remove header
    end
    
    for _, line in ipairs(lines) do
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
    
    print(string.format("Import complete! %d conversation patterns learned", imported))
    print(string.format("Total contexts: %d", M.stats.contexts_learned))
    
    return imported
end

-- ============================================================================
-- SAVE/LOAD (Uses RAID for large data!)
-- ============================================================================

local raid = nil
local function initRAID()
    if not raid then
        local ok, r = pcall(require, "raid_system")
        if ok then
            pcall(function() r.init() end)
            raid = r
        end
    end
    return raid ~= nil
end

function M.save(filepath)
    filepath = filepath or "context_markov.dat"
    
    local data = {
        chains = M.chains,
        stats = M.stats
    }
    
    local serialized = textutils.serialize(data)
    
    -- Try RAID first for large data (>100KB)
    if #serialized > 100000 and initRAID() then
        local raid_path = "markov/" .. filepath:gsub("^/", "")
        local ok, err = pcall(function()
            raid.write(raid_path, serialized)
        end)
        if ok then
            print("Saved to RAID: " .. #serialized .. " bytes")
            -- Leave a marker file locally
            local marker = fs.open(filepath .. ".raid", "w")
            if marker then
                marker.write("RAID:" .. raid_path)
                marker.close()
            end
            return true
        else
            print("RAID save failed, trying local: " .. tostring(err))
        end
    end
    
    -- Fallback to local file
    local dir = filepath:match("(.*/)")
    if dir and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local file = fs.open(filepath, "w")
    if not file then
        return false, "Could not open file for writing: " .. filepath
    end
    
    -- Try to write, catch out of space
    local ok, err = pcall(function()
        file.write(serialized)
    end)
    file.close()
    
    if not ok then
        -- Out of space - try RAID as backup
        if initRAID() then
            local raid_path = "markov/" .. filepath:gsub("^/", "")
            local raid_ok = pcall(function()
                raid.write(raid_path, serialized)
            end)
            if raid_ok then
                -- Leave marker
                local marker = fs.open(filepath .. ".raid", "w")
                if marker then
                    marker.write("RAID:" .. raid_path)
                    marker.close()
                end
                print("Saved to RAID (local was full)")
                return true
            end
        end
        return false, "Out of space: " .. tostring(err)
    end
    
    return true
end

function M.load(filepath)
    filepath = filepath or "context_markov.dat"
    
    -- Check for RAID marker first
    if fs.exists(filepath .. ".raid") then
        local marker = fs.open(filepath .. ".raid", "r")
        if marker then
            local content = marker.readAll()
            marker.close()
            local raid_path = content:match("RAID:(.+)")
            if raid_path and initRAID() then
                local ok, data_str = pcall(function()
                    return raid.read(raid_path)
                end)
                if ok and data_str then
                    local data = textutils.unserialize(data_str)
                    if data then
                        M.chains = data.chains or M.chains
                        M.stats = data.stats or M.stats
                        print("Loaded from RAID: " .. #data_str .. " bytes")
                        return true
                    end
                end
            end
        end
    end
    
    -- Try local file
    if not fs.exists(filepath) then
        -- Also try RAID directly
        if initRAID() then
            local raid_path = "markov/" .. filepath:gsub("^/", "")
            local ok, data_str = pcall(function()
                if raid.exists(raid_path) then
                    return raid.read(raid_path)
                end
                return nil
            end)
            if ok and data_str then
                local data = textutils.unserialize(data_str)
                if data then
                    M.chains = data.chains or M.chains
                    M.stats = data.stats or M.stats
                    return true
                end
            end
        end
        return false
    end
    
    local file = fs.open(filepath, "r")
    if not file then
        return false
    end
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
        contexts_learned = context_count,
        successful_generations = M.stats.successful_generations,
        max_patterns = MAX_TOTAL_PATTERNS,
        at_capacity = M.stats.total_patterns >= MAX_TOTAL_PATTERNS
    }
end

-- Check if training has reached capacity
function M.atCapacity()
    return M.stats.total_patterns >= MAX_TOTAL_PATTERNS
end

-- Reset all training data
function M.reset()
    M.chains = {
        contexts = {},
        word_chains = {},
        response_starters = {}
    }
    M.stats = {
        total_patterns = 0,
        contexts_learned = 0,
        successful_generations = 0
    }
    
    -- Delete saved files
    pcall(function() fs.delete("context_markov.dat") end)
    pcall(function() fs.delete("context_markov.dat.raid") end)
    
    print("Training data reset!")
    return true
end

return M
