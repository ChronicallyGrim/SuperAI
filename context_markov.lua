-- context_markov.lua
-- Advanced context-aware Markov chains that understand conversation flow
-- Features: Higher-order context chains, interpolation, quality scoring

local M = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

M.config = {
    max_order = 3,           -- Support up to 3-word chains (4 is too memory-heavy for context)
    default_order = 2,       -- Default generation order
    temperature = 1.0,       -- Sampling randomness
    interpolation = true,    -- Blend multiple contexts
    quality_threshold = 0.4, -- Min quality score
    max_length = 25,         -- Max words per response
}

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

-- ============================================================================
-- ADVANCED TOKENIZATION (imported from markov.lua)
-- ============================================================================

local function tokenize(text)
    local words = {}
    local current = ""

    for i = 1, #text do
        local char = text:sub(i, i)

        if char:match("%s") then
            if #current > 0 then
                table.insert(words, current)
                current = ""
            end
        elseif char:match("[.!?]") then
            if #current > 0 then
                table.insert(words, current .. char)
                current = ""
            else
                table.insert(words, char)
            end
        elseif char:match("[,;:]") then
            if #current > 0 then
                table.insert(words, current .. char)
                current = ""
            end
        else
            current = current .. char
        end
    end

    if #current > 0 then
        table.insert(words, current)
    end

    return words
end

local function isSentenceEnd(word)
    return word:match("[.!?]$") ~= nil
end

local function isSentenceStart(word)
    local first = word:sub(1, 1)
    return first == first:upper() and first ~= first:lower()
end

-- ============================================================================
-- QUALITY SCORING
-- ============================================================================

local function scoreResponse(text)
    local score = 0.5
    local words = tokenize(text)

    if #words == 0 then
        return 0.0
    end

    -- Proper length
    if #words >= 8 and #words <= 25 then
        score = score + 0.2
    elseif #words >= 5 and #words <= 30 then
        score = score + 0.1
    end

    -- Ending punctuation
    if isSentenceEnd(words[#words]) then
        score = score + 0.15
    end

    -- Starting capital
    if isSentenceStart(words[1]) then
        score = score + 0.1
    end

    -- Penalty for very short
    if #words < 3 then
        score = score - 0.3
    end

    -- Variety bonus
    local unique = {}
    for _, word in ipairs(words) do
        unique[word:lower()] = true
    end
    local uniqueness = 0
    for _ in pairs(unique) do uniqueness = uniqueness + 1 end
    local variety = uniqueness / #words
    score = score + (variety * 0.15)

    return math.max(0.0, math.min(1.0, score))
end

-- ============================================================================
-- CONTEXT-AWARE TRAINING (with higher-order chains)
-- ============================================================================

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
    
    -- Build word chains for multiple orders (1-3)
    local words = tokenize(response)

    for order = 1, math.min(M.config.max_order, #words - 1) do
        for i = 1, #words - order do
            -- Build state key
            local state_words = {}
            for j = 0, order - 1 do
                table.insert(state_words, words[i + j])
            end
            local key = table.concat(state_words, " ")
            local next_word = words[i + order]

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
    end

    context.count = context.count + 1
end

-- ============================================================================
-- ADVANCED GENERATION WITH BACKOFF, INTERPOLATION, AND QUALITY FILTERING
-- ============================================================================

local function selectNextWord(options, temperature)
    temperature = temperature or M.config.temperature

    if not options or #options == 0 then
        return nil
    end

    -- Count frequencies
    local freq = {}
    for _, word in ipairs(options) do
        freq[word] = (freq[word] or 0) + 1
    end

    -- Apply temperature
    local weights = {}
    local total_weight = 0

    for word, count in pairs(freq) do
        local weight = math.pow(count, 1.0 / temperature)
        weights[word] = weight
        total_weight = total_weight + weight
    end

    if total_weight == 0 then
        return options[math.random(#options)]
    end

    -- Weighted random selection
    local random_value = math.random() * total_weight
    local cumulative = 0

    for word, weight in pairs(weights) do
        cumulative = cumulative + weight
        if random_value <= cumulative then
            return word
        end
    end

    return options[math.random(#options)]
end

local function generateFromContext(context_data, max_words, temperature)
    if not context_data or not context_data.starters or not next(context_data.starters) then
        return nil
    end

    local response_words = {}

    -- Pick starter word weighted by frequency
    local starters = {}
    for word, count in pairs(context_data.starters) do
        for i = 1, count do
            table.insert(starters, word)
        end
    end

    if #starters == 0 then return nil end

    local first_word = starters[math.random(#starters)]
    table.insert(response_words, first_word)

    -- Generate with backoff smoothing
    for i = 2, max_words do
        local next_word = nil

        -- Try orders from high to low (backoff)
        for order = math.min(M.config.max_order, #response_words), 1, -1 do
            local state_words = {}
            local start_idx = math.max(1, #response_words - order + 1)
            for j = start_idx, #response_words do
                table.insert(state_words, response_words[j])
            end
            local key = table.concat(state_words, " ")

            local options = context_data.sequences[key]
            if options and #options > 0 then
                next_word = selectNextWord(options, temperature)
                if next_word then
                    break
                end
            end
        end

        if not next_word then
            break
        end

        table.insert(response_words, next_word)

        -- Stop at sentence boundary
        if isSentenceEnd(next_word) then
            break
        end
    end

    if #response_words >= 3 then
        return table.concat(response_words, " ")
    end

    return nil
end

function M.generateWithContext(previous_messages, current_message, max_words, num_attempts)
    max_words = max_words or M.config.max_length
    num_attempts = num_attempts or 3

    -- Detect context from conversation
    local context_tags = M.detectContext(previous_messages, current_message)

    -- Find matching contexts (can be multiple for interpolation)
    local matching_contexts = {}

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

        if score > 0 then
            table.insert(matching_contexts, {context = context_data, score = score})
        end
    end

    -- Sort by score (best first)
    table.sort(matching_contexts, function(a, b) return a.score > b.score end)

    -- Fallback to general if no matches
    if #matching_contexts == 0 and M.chains.contexts["general"] then
        table.insert(matching_contexts, {context = M.chains.contexts["general"], score = 0})
    end

    if #matching_contexts == 0 then
        return nil
    end

    -- Try generating from best contexts with quality filtering
    local best_response = nil
    local best_quality = 0

    for attempt = 1, num_attempts do
        -- Pick from top contexts (interpolation effect)
        local context_idx = math.min(attempt, #matching_contexts)
        local context_data = matching_contexts[context_idx].context

        local response = generateFromContext(context_data, max_words, M.config.temperature)

        if response then
            local quality = scoreResponse(response)

            if quality > best_quality then
                best_quality = quality
                best_response = response
            end

            -- Stop if good enough
            if quality >= 0.7 then
                break
            end
        end
    end

    if best_response and best_quality >= M.config.quality_threshold then
        M.stats.successful_generations = (M.stats.successful_generations or 0) + 1
        return best_response
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
        stats = M.stats,
        config = M.config
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

                        -- Merge config
                        if data.config then
                            for k, v in pairs(data.config) do
                                M.config[k] = v
                            end
                        end

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

                    -- Merge config
                    if data.config then
                        for k, v in pairs(data.config) do
                            M.config[k] = v
                        end
                    end

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

        -- Merge config
        if data.config then
            for k, v in pairs(data.config) do
                M.config[k] = v
            end
        end

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
        at_capacity = M.stats.total_patterns >= MAX_TOTAL_PATTERNS,
        config = M.config
    }
end

-- ============================================================================
-- CONFIGURATION HELPERS
-- ============================================================================

function M.setTemperature(temp)
    M.config.temperature = math.max(0.1, math.min(3.0, temp))
end

function M.setQualityThreshold(threshold)
    M.config.quality_threshold = math.max(0.0, math.min(1.0, threshold))
end

function M.setMaxOrder(order)
    M.config.max_order = math.max(1, math.min(3, order))
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

-- ============================================================================
-- INIT (called automatically by cluster_worker on module load)
-- ============================================================================

function M.init()
    -- Try to load saved training data first
    if M.load() then
        return
    end
    -- No saved data, seed with defaults
    M.initializeWithDefaults()
end

function M.initializeWithDefaults()
    local pairs_data = {
        -- greeting context
        {"Hello!", "Hey there! Great to chat with you.", {"greeting", "conversation_start"}},
        {"Hi there!", "Hi! How's it going?", {"greeting"}},
        {"Hey, how are you?", "I'm doing well, thanks for asking! How about you?", {"greeting", "status_question"}},
        {"Good morning!", "Good morning! Hope you're having a nice day.", {"greeting"}},
        -- status responses
        {"I'm doing great!", "That's wonderful to hear!", {"responding_to_statement", "status_positive"}},
        {"I'm not feeling well.", "I'm sorry to hear that. Hope you feel better soon.", {"responding_to_statement", "status_negative"}},
        {"I'm okay I guess.", "I understand. Is there anything I can do to help?", {"responding_to_statement", "status_neutral"}},
        -- questions
        {"What can you do?", "I can chat, answer questions, and help you think through problems.", {"asking_question", "what_question"}},
        {"How does that work?", "Let me try to explain it as clearly as I can.", {"asking_question", "how_question"}},
        {"Why is that?", "Good question. There are a few reasons for that.", {"asking_question", "why_question"}},
        -- agreements and acknowledgements
        {"Yeah exactly!", "Glad we're on the same page about that.", {"agreement", "short_response"}},
        {"Cool.", "Awesome! Let me know if you want to dig deeper.", {"acknowledgment", "short_response"}},
        {"No that's wrong.", "Fair enough, I might be mistaken. What do you think?", {"disagreement", "short_response"}},
    }

    for _, pair in ipairs(pairs_data) do
        M.trainWithContext(pair[1], pair[2], pair[3])
    end

    M.save()
end

return M
