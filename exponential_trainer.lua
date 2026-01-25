-- exponential_trainer.lua
-- Advanced training system that grows smarter with each run
-- Uses bootstrapping, curriculum learning, and pattern combination

local M = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local TRAINING_VERSION = 2
local GENERATION_FILE = "training_generation.dat"

-- ============================================================================
-- TOPIC DATABASE (50+ diverse topics)
-- ============================================================================

local TOPICS = {
    -- Technology
    {name = "programming", keywords = {"code", "function", "variable", "loop", "algorithm", "debug", "compile", "syntax"}},
    {name = "computers", keywords = {"CPU", "memory", "storage", "processor", "hardware", "software", "operating system"}},
    {name = "internet", keywords = {"network", "website", "server", "browser", "download", "upload", "connection"}},
    {name = "gaming", keywords = {"game", "player", "level", "score", "graphics", "controller", "multiplayer"}},
    {name = "minecraft", keywords = {"block", "craft", "mine", "redstone", "mob", "biome", "enchant", "nether"}},
    {name = "robots", keywords = {"automation", "sensor", "motor", "AI", "machine", "android", "circuit"}},
    
    -- Science
    {name = "physics", keywords = {"gravity", "energy", "force", "motion", "light", "waves", "atoms", "quantum"}},
    {name = "chemistry", keywords = {"element", "molecule", "reaction", "compound", "acid", "base", "bond"}},
    {name = "biology", keywords = {"cell", "DNA", "evolution", "species", "organism", "ecosystem", "genetics"}},
    {name = "astronomy", keywords = {"star", "planet", "galaxy", "orbit", "telescope", "universe", "black hole"}},
    {name = "math", keywords = {"equation", "formula", "calculate", "geometry", "algebra", "number", "proof"}},
    
    -- Creative
    {name = "art", keywords = {"draw", "paint", "color", "design", "creative", "style", "canvas", "sketch"}},
    {name = "music", keywords = {"song", "melody", "rhythm", "instrument", "compose", "beat", "harmony"}},
    {name = "writing", keywords = {"story", "character", "plot", "poem", "author", "narrative", "chapter"}},
    {name = "building", keywords = {"construct", "design", "structure", "architecture", "foundation", "blueprint"}},
    
    -- Life Skills
    {name = "learning", keywords = {"study", "practice", "understand", "remember", "focus", "improve", "skill"}},
    {name = "problem_solving", keywords = {"solution", "think", "analyze", "approach", "strategy", "method"}},
    {name = "communication", keywords = {"talk", "listen", "explain", "express", "understand", "message"}},
    {name = "teamwork", keywords = {"collaborate", "together", "help", "share", "cooperate", "group"}},
    {name = "time_management", keywords = {"schedule", "plan", "organize", "prioritize", "deadline", "efficient"}},
    
    -- Philosophy
    {name = "thinking", keywords = {"idea", "concept", "logic", "reason", "believe", "opinion", "perspective"}},
    {name = "ethics", keywords = {"right", "wrong", "fair", "moral", "choice", "responsibility", "value"}},
    {name = "curiosity", keywords = {"wonder", "question", "explore", "discover", "investigate", "learn"}},
    {name = "creativity", keywords = {"imagine", "invent", "original", "innovative", "unique", "inspiration"}},
    
    -- Emotions
    {name = "happiness", keywords = {"joy", "fun", "excited", "glad", "pleased", "delighted", "cheerful"}},
    {name = "challenges", keywords = {"difficult", "hard", "struggle", "overcome", "persist", "effort"}},
    {name = "success", keywords = {"achieve", "accomplish", "win", "goal", "proud", "progress", "milestone"}},
    {name = "friendship", keywords = {"friend", "trust", "loyal", "support", "care", "bond", "companion"}},
}

-- ============================================================================
-- RESPONSE TEMPLATES BY COMPLEXITY LEVEL
-- ============================================================================

local COMPLEXITY_LEVELS = {
    -- Level 1: Simple (Generation 1-2)
    {
        student_questions = {
            "What is {keyword}?",
            "How does {keyword} work?",
            "Can you explain {keyword}?",
            "Why is {keyword} important?",
            "What's {keyword} used for?",
        },
        student_responses = {
            "Oh, I see!",
            "That makes sense!",
            "Got it, thanks!",
            "Interesting!",
            "I understand now!",
        },
        teacher_explanations = {
            "{keyword} is a fundamental concept. Let me explain.",
            "Great question about {keyword}! Here's the basic idea.",
            "Think of {keyword} as a building block.",
            "{keyword} is essential because it helps us understand how things work.",
            "The simple answer is that {keyword} connects different ideas together.",
        },
        teacher_followups = {
            "Does that help?",
            "Make sense so far?",
            "Want to know more?",
            "Questions?",
            "Should I elaborate?",
        },
    },
    
    -- Level 2: Intermediate (Generation 3-5)
    {
        student_questions = {
            "How does {keyword} relate to {keyword2}?",
            "What's the difference between {keyword} and {keyword2}?",
            "Can you give me an example of {keyword} in action?",
            "What happens when {keyword} doesn't work properly?",
            "How do experts use {keyword}?",
            "What are the main types of {keyword}?",
            "When should I use {keyword} vs {keyword2}?",
        },
        student_responses = {
            "That's a really interesting way to think about it!",
            "I never considered that connection before!",
            "So {keyword} and {keyword2} work together?",
            "That example really helped clarify things!",
            "Now I see how the pieces fit together!",
            "This is starting to make more sense now!",
        },
        teacher_explanations = {
            "The relationship between {keyword} and {keyword2} is fascinating. They complement each other.",
            "Here's a practical example: imagine {keyword} as the foundation, and {keyword2} as what you build on top.",
            "The key difference is that {keyword} focuses on the 'what' while {keyword2} focuses on the 'how'.",
            "Experts combine {keyword} with {keyword2} to achieve better results.",
            "Think of it as a spectrum - {keyword} on one end, {keyword2} on the other, with many variations between.",
            "When {keyword} fails, we often use {keyword2} as a backup or alternative approach.",
        },
        teacher_followups = {
            "Can you think of other examples?",
            "How might you apply this?",
            "What patterns do you notice?",
            "Does this connect to anything you already know?",
            "What would happen if we changed one variable?",
        },
    },
    
    -- Level 3: Advanced (Generation 6-10)
    {
        student_questions = {
            "What are the underlying principles that make {keyword} work with {keyword2}?",
            "How has our understanding of {keyword} evolved over time?",
            "What are the edge cases where {keyword} doesn't apply?",
            "How would you teach {keyword} to someone who's never heard of it?",
            "What misconceptions do people have about {keyword}?",
            "If {keyword} didn't exist, what would we use instead?",
            "How do {keyword}, {keyword2}, and {keyword3} interact in complex systems?",
            "What's the most elegant way to combine {keyword} with {keyword2}?",
        },
        student_responses = {
            "That's a profound insight! It changes how I think about the whole topic.",
            "I love how {keyword} creates emergent properties when combined with {keyword2}.",
            "The historical context really helps me appreciate why things are done this way.",
            "So the real power comes from understanding the interactions, not just the components!",
            "This recursive nature of {keyword} is beautiful once you see it.",
            "I'm starting to develop intuition for when to apply different approaches.",
        },
        teacher_explanations = {
            "The deep insight here is that {keyword} and {keyword2} share fundamental principles, even though they look different on the surface.",
            "Historically, {keyword} emerged from trying to solve problems that {keyword2} couldn't handle elegantly.",
            "The edge cases reveal important truths: {keyword} works best when certain assumptions hold.",
            "Teaching {keyword} effectively requires building from concrete examples to abstract principles.",
            "The most common misconception is that {keyword} is isolated - in reality, it's deeply connected to {keyword2} and {keyword3}.",
            "Without {keyword}, we'd need to reinvent many wheels - it's a cornerstone concept.",
            "The elegance comes from recognizing that {keyword} and {keyword2} are two perspectives on the same underlying truth.",
        },
        teacher_followups = {
            "How would you explain this to someone else?",
            "What new questions does this raise?",
            "Can you see how this applies to other domains?",
            "What would you explore next?",
            "How might future developments change this understanding?",
        },
    },
    
    -- Level 4: Expert (Generation 11+)
    {
        student_questions = {
            "What are the fundamental limits of {keyword} and how might we transcend them?",
            "How do different schools of thought approach {keyword} differently?",
            "What's the most counterintuitive aspect of {keyword} that experts still debate?",
            "If you could redesign {keyword} from scratch, what would you change?",
            "How does mastery of {keyword} change the way experts perceive related problems?",
            "What's the relationship between {keyword} at the micro and macro levels?",
            "How do we balance the tradeoffs between {keyword} and {keyword2} in practice?",
        },
        student_responses = {
            "This meta-level understanding transforms how I approach all related problems.",
            "I can now see {keyword} as part of a larger conceptual framework spanning multiple domains.",
            "The tradeoffs make sense when viewed through the lens of fundamental constraints.",
            "Mastery seems to be about knowing when rules apply and when to break them intentionally.",
            "The debates reveal that even experts are still discovering new aspects of {keyword}.",
            "I appreciate how humility and confidence both grow with deeper understanding.",
        },
        teacher_explanations = {
            "At the expert level, {keyword} becomes less about rules and more about principles that generate appropriate rules.",
            "Different schools emphasize different aspects: some prioritize {keyword2}, others focus on {keyword3}. Both perspectives have value.",
            "The counterintuitive part is that {keyword} sometimes works better when you don't try to optimize it directly.",
            "If redesigning from scratch, we'd probably integrate {keyword} and {keyword2} more seamlessly from the start.",
            "Expert perception shifts from seeing {keyword} as a tool to seeing it as a lens for understanding.",
            "The micro-macro relationship reveals that {keyword} exhibits similar patterns at different scales.",
            "Balancing tradeoffs requires developing judgment that can't be fully captured in rules.",
        },
        teacher_followups = {
            "What aspects would you research further?",
            "How has your mental model evolved through this conversation?",
            "What connections to other fields do you see now?",
            "Where do you think the field is heading?",
            "What would you teach others based on this understanding?",
        },
    },
}

-- ============================================================================
-- TRAINING STATE (persists across runs)
-- ============================================================================

local state = {
    generation = 1,
    total_conversations = 0,
    student_intelligence = 1.0,
    teacher_intelligence = 1.0,
    learned_patterns = {},
    topic_mastery = {},
    vocabulary_size = 0,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function choose(list)
    if not list or #list == 0 then return "" end
    return list[math.random(#list)]
end

local function getKeywords(topic, count)
    count = count or 1
    local keywords = {}
    if topic and topic.keywords then
        local available = {}
        for _, k in ipairs(topic.keywords) do
            table.insert(available, k)
        end
        for i = 1, math.min(count, #available) do
            local idx = math.random(#available)
            table.insert(keywords, available[idx])
            table.remove(available, idx)
        end
    end
    return keywords
end

local function fillTemplate(template, keywords)
    local result = template
    if keywords[1] then result = result:gsub("{keyword}", keywords[1]) end
    if keywords[2] then result = result:gsub("{keyword2}", keywords[2]) end
    if keywords[3] then result = result:gsub("{keyword3}", keywords[3]) end
    return result
end

local function getComplexityLevel()
    if state.generation <= 2 then return 1
    elseif state.generation <= 5 then return 2
    elseif state.generation <= 10 then return 3
    else return 4
    end
end

-- ============================================================================
-- BOOTSTRAPPING: Learn from existing patterns
-- ============================================================================

local function bootstrapFromExisting()
    -- Try to load context_markov data
    local cm = nil
    pcall(function()
        cm = require("context_markov")
        cm.load("context_markov.dat")
    end)
    
    if cm and cm.chains and cm.chains.contexts then
        local pattern_count = 0
        for context, data in pairs(cm.chains.contexts) do
            if data.sequences then
                for key, options in pairs(data.sequences) do
                    for _, next_word in ipairs(options) do
                        local pattern = key .. " " .. next_word
                        state.learned_patterns[pattern] = (state.learned_patterns[pattern] or 0) + 1
                        pattern_count = pattern_count + 1
                    end
                end
            end
        end
        print("Bootstrapped " .. pattern_count .. " patterns from previous training")
        return pattern_count
    end
    return 0
end

local function generateFromLearnedPatterns(seed_word)
    -- Use existing patterns to create novel combinations
    local result = {seed_word}
    
    for i = 1, 10 do
        local last_two = result[#result - 1] and (result[#result - 1] .. " " .. result[#result]) or nil
        if last_two then
            -- Find patterns starting with these words
            local options = {}
            for pattern, count in pairs(state.learned_patterns) do
                if pattern:find("^" .. last_two:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")) then
                    local next_word = pattern:match(last_two:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%s+(%S+)")
                    if next_word then
                        for j = 1, count do
                            table.insert(options, next_word)
                        end
                    end
                end
            end
            if #options > 0 then
                table.insert(result, options[math.random(#options)])
            else
                break
            end
        else
            break
        end
    end
    
    if #result >= 3 then
        return table.concat(result, " ")
    end
    return nil
end

-- ============================================================================
-- INTELLIGENCE SCALING
-- ============================================================================

local function scaleByIntelligence(templates, intelligence)
    -- Higher intelligence = access to more sophisticated templates
    local accessible = {}
    local threshold = 1.0 / intelligence
    
    for i, template in ipairs(templates) do
        -- Earlier templates always accessible, later ones require intelligence
        local difficulty = i / #templates
        if difficulty <= intelligence or math.random() < (intelligence - difficulty + 0.5) then
            table.insert(accessible, template)
        end
    end
    
    if #accessible == 0 then
        return templates[1]  -- Fallback to simplest
    end
    
    return choose(accessible)
end

-- ============================================================================
-- CONVERSATION GENERATION
-- ============================================================================

local function generateConversation(topic, turns)
    local level = getComplexityLevel()
    local templates = COMPLEXITY_LEVELS[level]
    local conversation = {}
    local keywords = getKeywords(topic, 3)
    
    -- Opening
    local student_q = scaleByIntelligence(templates.student_questions, state.student_intelligence)
    student_q = fillTemplate(student_q, keywords)
    table.insert(conversation, {role = "student", message = student_q})
    
    -- Multi-turn conversation
    for turn = 1, turns do
        -- Teacher explains
        local teacher_exp = scaleByIntelligence(templates.teacher_explanations, state.teacher_intelligence)
        teacher_exp = fillTemplate(teacher_exp, keywords)
        
        -- Maybe add bootstrapped content (exponential growth!)
        if state.generation > 1 and math.random() < 0.3 then
            local seed = keywords[1] or "the"
            local bootstrapped = generateFromLearnedPatterns(seed)
            if bootstrapped and #bootstrapped > 10 then
                teacher_exp = teacher_exp .. " " .. bootstrapped
            end
        end
        
        -- Add followup
        if math.random() < 0.5 then
            teacher_exp = teacher_exp .. " " .. choose(templates.teacher_followups)
        end
        
        table.insert(conversation, {role = "teacher", message = teacher_exp})
        
        -- Student responds
        local student_resp
        if math.random() < 0.6 then
            student_resp = scaleByIntelligence(templates.student_responses, state.student_intelligence)
        else
            student_resp = scaleByIntelligence(templates.student_questions, state.student_intelligence)
        end
        student_resp = fillTemplate(student_resp, keywords)
        table.insert(conversation, {role = "student", message = student_resp})
    end
    
    return conversation
end

-- ============================================================================
-- MAIN TRAINING FUNCTION
-- ============================================================================

function M.train(num_conversations, turns_per_conversation)
    num_conversations = num_conversations or 10000
    turns_per_conversation = turns_per_conversation or 5
    
    print("=== EXPONENTIAL TRAINING SYSTEM v" .. TRAINING_VERSION .. " ===")
    print("")
    
    -- Load previous state
    M.loadState()
    print("Generation: " .. state.generation)
    print("Previous conversations: " .. state.total_conversations)
    print("Student intelligence: " .. string.format("%.2f", state.student_intelligence))
    print("Teacher intelligence: " .. string.format("%.2f", state.teacher_intelligence))
    print("")
    
    -- Bootstrap from existing training
    local bootstrapped = bootstrapFromExisting()
    print("Loaded " .. bootstrapped .. " existing patterns")
    print("")
    
    -- Initialize context_markov for saving
    local cm = nil
    pcall(function()
        cm = require("context_markov")
        cm.load("context_markov.dat")
    end)
    
    if not cm then
        print("ERROR: context_markov not found!")
        return
    end
    
    -- Initialize RAID for progress saving
    local raid = nil
    pcall(function()
        local r = require("raid_system")
        r.init()
        raid = r
    end)
    
    print("Training " .. num_conversations .. " conversations...")
    print("Complexity level: " .. getComplexityLevel())
    print("")
    
    local start_time = os.clock()
    local trained = 0
    local new_patterns = 0
    
    for i = 1, num_conversations do
        -- Pick random topic
        local topic = TOPICS[math.random(#TOPICS)]
        
        -- Generate conversation
        local conversation = generateConversation(topic, turns_per_conversation)
        
        -- Train context_markov on each exchange
        local history = {}
        for _, exchange in ipairs(conversation) do
            if exchange.role == "teacher" then
                local context_tags = cm.detectContext(history, exchange.message)
                table.insert(context_tags, topic.name)  -- Add topic as context
                cm.trainWithContext(history[#history] or "", exchange.message, context_tags)
                new_patterns = new_patterns + 1
            end
            table.insert(history, exchange.message)
        end
        
        trained = trained + 1
        
        -- Update topic mastery
        state.topic_mastery[topic.name] = (state.topic_mastery[topic.name] or 0) + 1
        
        -- Progress update (every 2000)
        if trained % 2000 == 0 then
            print(string.format("Progress: %d/%d (%.1f%%)", trained, num_conversations, (trained/num_conversations)*100))
            
            -- Save periodically (RAID handles large data now)
            local ok, err = pcall(function()
                cm.save("context_markov.dat")
            end)
            if not ok then
                print("Warning: Save failed - " .. tostring(err))
            end
        end
        
        -- Yield to prevent timeout
        if trained % 50 == 0 then
            os.sleep(0)
        end
    end
    
    -- Final save
    print("Saving final training data...")
    local ok, err = pcall(function()
        cm.save("context_markov.dat")
    end)
    if ok then
        print("Training data saved successfully!")
    else
        print("Warning: Final save had issues - " .. tostring(err))
    end
    
    local elapsed = os.clock() - start_time
    
    -- Update state for next generation
    state.total_conversations = state.total_conversations + trained
    state.generation = state.generation + 1
    
    -- Intelligence grows exponentially!
    local growth_factor = 1 + (0.1 * math.log(trained + 1) / math.log(1000))
    state.student_intelligence = state.student_intelligence * growth_factor
    state.teacher_intelligence = state.teacher_intelligence * growth_factor
    
    -- Cap at reasonable levels
    state.student_intelligence = math.min(state.student_intelligence, 10.0)
    state.teacher_intelligence = math.min(state.teacher_intelligence, 10.0)
    
    M.saveState()
    
    print("")
    print("=== TRAINING COMPLETE ===")
    print("")
    print("Conversations trained: " .. trained)
    print("New patterns learned: " .. new_patterns)
    print("Time: " .. string.format("%.1f", elapsed) .. " seconds")
    print("")
    print("=== GROWTH RESULTS ===")
    print("New generation: " .. state.generation)
    print("Total conversations ever: " .. state.total_conversations)
    print("Student intelligence: " .. string.format("%.2f", state.student_intelligence))
    print("Teacher intelligence: " .. string.format("%.2f", state.teacher_intelligence))
    print("Complexity level: " .. getComplexityLevel())
    print("")
    
    -- Show topic coverage
    local topics_covered = 0
    for _ in pairs(state.topic_mastery) do
        topics_covered = topics_covered + 1
    end
    print("Topics mastered: " .. topics_covered .. "/" .. #TOPICS)
    
    return trained, new_patterns
end

-- ============================================================================
-- STATE PERSISTENCE
-- ============================================================================

function M.saveState()
    local data = textutils.serialize(state)
    local f = fs.open(GENERATION_FILE, "w")
    if f then
        f.write(data)
        f.close()
    end
end

function M.loadState()
    if fs.exists(GENERATION_FILE) then
        local f = fs.open(GENERATION_FILE, "r")
        if f then
            local data = textutils.unserialize(f.readAll())
            f.close()
            if data then
                state = data
            end
        end
    end
end

function M.resetState()
    state = {
        generation = 1,
        total_conversations = 0,
        student_intelligence = 1.0,
        teacher_intelligence = 1.0,
        learned_patterns = {},
        topic_mastery = {},
        vocabulary_size = 0,
    }
    M.saveState()
    print("Training state reset to generation 1")
end

function M.getState()
    M.loadState()
    return state
end

-- ============================================================================
-- TRAINING MENU
-- ============================================================================

function M.menu()
    M.loadState()
    
    while true do
        print("")
        print("=== EXPONENTIAL TRAINER ===")
        print("Generation: " .. state.generation)
        print("Intelligence: S=" .. string.format("%.2f", state.student_intelligence) .. 
              " T=" .. string.format("%.2f", state.teacher_intelligence))
        print("")
        print("1. Quick train (1,000 conversations)")
        print("2. Standard train (10,000 conversations)")
        print("3. Deep train (50,000 conversations)")
        print("4. Massive train (100,000 conversations)")
        print("5. Custom train")
        print("6. View stats")
        print("7. Reset to generation 1")
        print("8. Exit")
        print("")
        write("Choice: ")
        
        local choice = read()
        
        if choice == "1" then
            M.train(1000, 4)
        elseif choice == "2" then
            M.train(10000, 5)
        elseif choice == "3" then
            M.train(50000, 6)
        elseif choice == "4" then
            M.train(100000, 7)
        elseif choice == "5" then
            write("Conversations: ")
            local num = tonumber(read()) or 5000
            write("Turns per conversation: ")
            local turns = tonumber(read()) or 5
            M.train(num, turns)
        elseif choice == "6" then
            M.showStats()
        elseif choice == "7" then
            write("Are you sure? (yes/no): ")
            if read() == "yes" then
                M.resetState()
            end
        elseif choice == "8" then
            break
        end
    end
end

function M.showStats()
    M.loadState()
    
    print("")
    print("=== TRAINING STATISTICS ===")
    print("")
    print("Generation: " .. state.generation)
    print("Total conversations: " .. state.total_conversations)
    print("Student intelligence: " .. string.format("%.2f", state.student_intelligence))
    print("Teacher intelligence: " .. string.format("%.2f", state.teacher_intelligence))
    print("Complexity level: " .. getComplexityLevel())
    print("")
    
    print("Topics mastered:")
    local sorted_topics = {}
    for topic, count in pairs(state.topic_mastery) do
        table.insert(sorted_topics, {name = topic, count = count})
    end
    table.sort(sorted_topics, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(10, #sorted_topics) do
        print("  " .. sorted_topics[i].name .. ": " .. sorted_topics[i].count)
    end
    
    print("")
    print("Learned patterns: " .. (function()
        local count = 0
        for _ in pairs(state.learned_patterns) do count = count + 1 end
        return count
    end)())
end

return M
