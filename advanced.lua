-- Module: advanced.lua
-- Advanced AI capabilities: reasoning, tools, research, and self-improvement
-- Combined module for Claude-like functionality

local M = {}

-- ============================================================================
-- REASONING CAPABILITIES
-- ============================================================================

M.reasoning = {}

-- Chain of thought reasoning
function M.reasoning.thinkStepByStep(problem)
    local steps = {}
    local reasoning = {
        problem = problem,
        steps = steps,
        conclusion = nil
    }
    
    local lower = problem:lower()
    
    if lower:find("how") or lower:find("why") or lower:find("explain") then
        reasoning.type = "explanatory"
        table.insert(steps, "This is an explanatory question requiring reasoning")
    elseif lower:find("should") or lower:find("better") or lower:find("choose") then
        reasoning.type = "decision"
        table.insert(steps, "This requires evaluating options and making a decision")
    else
        reasoning.type = "general"
        table.insert(steps, "Analyzing the question structure")
    end
    
    return reasoning
end

-- Analogical reasoning
function M.reasoning.findAnalogy(concept)
    local analogies = {
        computer = "A computer is like a brain - it processes information",
        learning = "Learning is like building - you construct knowledge brick by brick",
        memory = "Memory is like a filing cabinet - organized storage of information"
    }
    
    local key = concept:lower():match("(%w+)")
    return analogies[key] or "Let me break this down into simpler parts"
end

-- Express uncertainty appropriately
function M.reasoning.expressUncertainty(confidence)
    if confidence >= 0.9 then return "I'm quite confident that"
    elseif confidence >= 0.7 then return "I believe"
    elseif confidence >= 0.5 then return "It seems likely that"
    elseif confidence >= 0.3 then return "I'm not certain, but"
    else return "I'm unsure, but my best guess is"
    end
end

-- Problem decomposition
function M.reasoning.decompose(problem)
    local components = {
        main_problem = problem,
        sub_problems = {},
        approach = nil
    }
    
    local lower = problem:lower()
    
    if lower:find("calculate") or lower:find("compute") then
        components.approach = "mathematical"
    elseif lower:find("explain") or lower:find("describe") then
        components.approach = "explanatory"
    elseif lower:find("compare") then
        components.approach = "comparative"
    else
        components.approach = "analytical"
    end
    
    return components
end

-- Check if clarification needed
function M.reasoning.needsClarification(query)
    local ambiguous_terms = {"it", "that", "thing", "stuff"}
    for _, term in ipairs(ambiguous_terms) do
        if query:lower():find("%f[%w]" .. term .. "%f[%W]") then
            return true, "The term '" .. term .. "' is ambiguous. Can you be more specific?"
        end
    end
    return false, nil
end

-- ============================================================================
-- TOOL USE CAPABILITIES
-- ============================================================================

M.tools = {}

-- File operations
function M.tools.readFile(filepath)
    if not fs.exists(filepath) then
        return nil, "File does not exist"
    end
    local file = fs.open(filepath, "r")
    if not file then return nil, "Could not open file" end
    local content = file.readAll()
    file.close()
    return content
end

function M.tools.writeFile(filepath, content)
    local file = fs.open(filepath, "w")
    if not file then return false, "Could not open file" end
    file.write(content)
    file.close()
    return true
end

function M.tools.listFiles(directory)
    if not fs.exists(directory) then return {}, "Directory does not exist" end
    if not fs.isDir(directory) then return {}, "Not a directory" end
    return fs.list(directory)
end

-- Safe code execution
function M.tools.executeCode(code)
    local safe_env = {
        math = math, string = string, table = table,
        pairs = pairs, ipairs = ipairs, tonumber = tonumber,
        tostring = tostring, type = type, print = print
    }
    
    local func, err = load(code, "user_code", "t", safe_env)
    if not func then return nil, "Syntax error: " .. tostring(err) end
    
    local success, result = pcall(func)
    if not success then return nil, "Runtime error: " .. tostring(result) end
    
    return result
end

-- System information
function M.tools.getSystemInfo()
    return {
        os = "ComputerCraft",
        version = os.version(),
        id = os.getComputerID(),
        label = os.getComputerLabel() or "Unnamed"
    }
end

function M.tools.getDiskSpace(path)
    path = path or "/"
    return {
        free = fs.getFreeSpace(path),
        capacity = fs.getCapacity(path),
        used = fs.getCapacity(path) - fs.getFreeSpace(path)
    }
end

-- Text processing
function M.tools.splitWords(text)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

function M.tools.countWords(text)
    local count = 0
    for _ in text:gmatch("%S+") do count = count + 1 end
    return count
end

function M.tools.extractNumbers(text)
    local numbers = {}
    for num in text:gmatch("-?%d+%.?%d*") do
        table.insert(numbers, tonumber(num))
    end
    return numbers
end

-- Time utilities
function M.tools.formatTime(time)
    time = time or os.time()
    local hours = math.floor(time)
    local minutes = math.floor((time - hours) * 60)
    local period = hours >= 12 and "PM" or "AM"
    if hours > 12 then hours = hours - 12 end
    if hours == 0 then hours = 12 end
    return string.format("%d:%02d %s", hours, minutes, period)
end

function M.tools.formatUptime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- ============================================================================
-- RESEARCH CAPABILITIES
-- ============================================================================

M.research = {}

-- Knowledge base
M.research.knowledge = {
    programming = {
        lua = "Lua is a lightweight scripting language with simple syntax",
        python = "Python is a high-level language known for readability"
    },
    science = {
        physics = "Physics studies matter, energy, and their interactions",
        biology = "Biology is the study of living organisms"
    }
}

-- Search knowledge base
function M.research.search(query)
    local results = {}
    local query_lower = query:lower()
    
    for category, items in pairs(M.research.knowledge) do
        for term, info in pairs(items) do
            if query_lower:find(term) or term:find(query_lower) then
                table.insert(results, {
                    category = category,
                    term = term,
                    info = info
                })
            end
        end
    end
    
    return results
end

-- Add to knowledge base
function M.research.addKnowledge(category, term, information)
    if not M.research.knowledge[category] then
        M.research.knowledge[category] = {}
    end
    M.research.knowledge[category][term] = information
    return true
end

-- Fact checking
function M.research.checkFact(claim)
    local results = M.research.search(claim)
    
    if #results > 0 then
        return {
            claim = claim,
            verdict = "partially supported",
            confidence = 0.7,
            evidence = results
        }
    else
        return {
            claim = claim,
            verdict = "unverified",
            confidence = 0.5,
            evidence = {}
        }
    end
end

-- Summarization
function M.research.summarize(text, max_length)
    max_length = max_length or 100
    
    local sentences = {}
    for sentence in text:gmatch("[^.!?]+[.!?]") do
        table.insert(sentences, sentence:match("^%s*(.-)%s*$"))
    end
    
    if #sentences == 0 then return text:sub(1, max_length) end
    
    -- Take first sentence and last if there's room
    local summary = sentences[1]
    if #sentences > 1 and #summary < max_length then
        summary = summary .. " " .. sentences[#sentences]
    end
    
    return summary
end

-- Identify topics
function M.research.identifyTopics(text)
    local topics = {}
    local text_lower = text:lower()
    
    for category, items in pairs(M.research.knowledge) do
        local relevance = 0
        for term, _ in pairs(items) do
            if text_lower:find(term) then
                relevance = relevance + 1
            end
        end
        if relevance > 0 then
            table.insert(topics, {category = category, relevance = relevance})
        end
    end
    
    table.sort(topics, function(a, b) return a.relevance > b.relevance end)
    return topics
end

-- ============================================================================
-- SELF-IMPROVEMENT CAPABILITIES
-- ============================================================================

M.improvement = {}

-- Performance tracking
M.improvement.stats = {
    successful = 0,
    failed = 0,
    corrections = 0,
    feedback = {}
}

function M.improvement.recordSuccess()
    M.improvement.stats.successful = M.improvement.stats.successful + 1
end

function M.improvement.recordFailure()
    M.improvement.stats.failed = M.improvement.stats.failed + 1
end

function M.improvement.recordFeedback(rating, comment)
    table.insert(M.improvement.stats.feedback, {
        rating = rating,
        comment = comment,
        time = os.time()
    })
end

function M.improvement.getStats()
    local total = M.improvement.stats.successful + M.improvement.stats.failed
    local success_rate = total > 0 and (M.improvement.stats.successful / total) or 0
    
    local avg_rating = 0
    if #M.improvement.stats.feedback > 0 then
        local sum = 0
        for _, fb in ipairs(M.improvement.stats.feedback) do
            sum = sum + fb.rating
        end
        avg_rating = sum / #M.improvement.stats.feedback
    end
    
    return {
        total = total,
        success_rate = success_rate,
        corrections = M.improvement.stats.corrections,
        avg_rating = avg_rating
    }
end

-- Error detection
function M.improvement.detectErrors(response)
    local errors = {}
    
    -- Check for overconfidence
    if response:find("definitely") or response:find("always") or response:find("never") then
        table.insert(errors, {
            type = "overconfidence",
            suggestion = "Use hedging: 'likely', 'usually', 'rarely'"
        })
    end
    
    return errors
end

-- Self-correction
function M.improvement.correctResponse(response)
    local corrected = response
    
    corrected = corrected:gsub("definitely", "likely")
    corrected = corrected:gsub("always", "usually")
    corrected = corrected:gsub("never", "rarely")
    corrected = corrected:gsub("certainly", "probably")
    
    if corrected ~= response then
        M.improvement.stats.corrections = M.improvement.stats.corrections + 1
    end
    
    return corrected
end

-- Confidence calibration
function M.improvement.calibrateConfidence(statement)
    local confidence = 0.5
    
    if statement:find("is defined as") or statement:find("according to") then
        confidence = confidence + 0.3
    end
    
    if statement:find("might") or statement:find("could") or statement:find("possibly") then
        confidence = confidence - 0.2
    end
    
    local stats = M.improvement.getStats()
    confidence = confidence * stats.success_rate
    
    return math.max(0, math.min(1, confidence))
end

-- Response quality assessment
function M.improvement.assessQuality(response, query)
    local score = 0
    local factors = {}
    
    if #response > 20 then
        score = score + 0.2
        table.insert(factors, "Adequate length")
    end
    
    -- Check relevance
    local query_words = {}
    for word in query:gmatch("%w+") do
        query_words[word:lower()] = true
    end
    
    local relevant = 0
    for word in response:gmatch("%w+") do
        if query_words[word:lower()] then
            relevant = relevant + 1
        end
    end
    
    if relevant >= 2 then
        score = score + 0.3
        table.insert(factors, "Relevant")
    end
    
    if response:find("likely") or response:find("probably") then
        score = score + 0.1
        table.insert(factors, "Appropriate hedging")
    end
    
    return {score = math.min(1, score), factors = factors}
end

-- Meta-cognition questions
function M.improvement.reflectOnThinking()
    return {
        "Am I being clear and precise?",
        "Have I considered alternatives?",
        "Am I overconfident?",
        "Could I explain this better?",
        "Have I checked for biases?"
    }
end

-- Save/load progress
function M.improvement.saveProgress(filename)
    filename = filename or "progress.dat"
    local data = textutils.serialize(M.improvement.stats)
    local file = fs.open(filename, "w")
    if file then
        file.write(data)
        file.close()
        return true
    end
    return false
end

function M.improvement.loadProgress(filename)
    filename = filename or "progress.dat"
    if not fs.exists(filename) then return false end
    
    local file = fs.open(filename, "r")
    if file then
        local data = textutils.unserialize(file.readAll())
        file.close()
        if data then
            M.improvement.stats = data
            return true
        end
    end
    return false
end

-- ============================================================================
-- INTEGRATED FUNCTIONS
-- ============================================================================

-- Comprehensive response generation
function M.generateResponse(query, context)
    -- 1. Check if clarification needed
    local needs_clarify, clarify_msg = M.reasoning.needsClarification(query)
    if needs_clarify then
        return clarify_msg
    end
    
    -- 2. Decompose problem
    local decomp = M.reasoning.decompose(query)
    
    -- 3. Search knowledge
    local research = M.research.search(query)
    
    -- 4. Generate response based on findings
    local response = ""
    if #research > 0 then
        response = research[1].info
    else
        response = "I don't have specific information about that, but let me think through it."
    end
    
    -- 5. Check and correct errors
    local errors = M.improvement.detectErrors(response)
    if #errors > 0 then
        response = M.improvement.correctResponse(response)
    end
    
    -- 6. Assess quality
    local quality = M.improvement.assessQuality(response, query)
    
    -- 7. Add appropriate uncertainty
    local confidence = M.improvement.calibrateConfidence(response)
    local hedge = M.reasoning.expressUncertainty(confidence)
    
    return hedge .. " " .. response
end

-- Get all capabilities
function M.listCapabilities()
    return {
        reasoning = {"thinkStepByStep", "findAnalogy", "decompose", "expressUncertainty"},
        tools = {"readFile", "writeFile", "executeCode", "getSystemInfo", "getDiskSpace"},
        research = {"search", "addKnowledge", "checkFact", "summarize", "identifyTopics"},
        improvement = {"recordSuccess", "getStats", "assessQuality", "correctResponse"}
    }
end

return M