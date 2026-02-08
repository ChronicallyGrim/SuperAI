-- superai_cluster.lua
-- Unified AI Orchestrator - Cluster Edition
-- Integrates ALL SuperAI modules into one massive, fully modular cluster AI system

local M = {}

-- ============================================================================
-- CLUSTER CONFIGURATION
-- ============================================================================

M.PROTOCOL = "SUPERAI_CLUSTER"
M.workers = {}
M.masterID = os.getComputerID()

-- Define all AI roles (one per worker node, 4 workers)
M.ROLES = {
    "neural",       -- Worker 1: neural networks + language representation
    "learning",     -- Worker 2: training + reinforcement learning
    "memory",       -- Worker 3: memory + knowledge + context
    "generation"    -- Worker 4: response generation + personality + mood
}

-- ============================================================================
-- MODULE REGISTRY - ALL 40+ MODULES ORGANIZED BY ROLE
-- ============================================================================

M.MODULE_MAP = {
    -- Worker 1: Neural networks + language representation
    neural = {
        "neural_net",
        "large_neural_net",
        "neural_trainer",
        "tokenization",
        "embeddings",
        "word_vectors",
        "attention"
    },
    -- Worker 2: Training + reinforcement learning
    learning = {
        "machine_learning",
        "learning",
        "autonomous_learning",
        "auto_trainer",
        "advanced_ai_trainer",
        "exponential_trainer",
        "easy_trainer",
        "unified_trainer",
        "training_diagnostic",
        "rlhf",
        "ai_vs_ai"
    },
    -- Worker 3: Memory + knowledge + context
    memory = {
        "conversation_memory",
        "memory_search",
        "memory_loader",
        "knowledge_graph",
        "dictionary",
        "context",
        "user_data"
    },
    -- Worker 4: Response generation + personality + mood
    generation = {
        "response_generator",
        "responses",
        "markov",
        "context_markov",
        "sampling",
        "personality",
        "mood",
        "advanced",
        "code_generator"
    }
}

-- ============================================================================
-- CLUSTER INITIALIZATION
-- ============================================================================

function M.init()
    print("=== SuperAI Unified Cluster Orchestrator ===")
    print("Initializing cluster network...")

    -- Open all modems
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            rednet.open(name)
            print("Opened modem: " .. name)
        end
    end

    -- Discover worker computers (exclude master itself)
    local computers = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "computer" then
            local id = peripheral.call(name, "getID")
            if id ~= M.masterID then
                table.insert(computers, {name = name, id = id})
            end
        end
    end

    print("Found " .. #computers .. " worker computers")

    -- Turn on ALL workers first, then wait for them to boot
    print("\nStarting all worker computers...")
    for i, comp in ipairs(computers) do
        peripheral.call(comp.name, "turnOn")
        print("  Turned on worker " .. comp.id)
    end

    -- Wait for workers to boot and start their startup scripts
    print("Waiting for workers to boot (15 seconds)...")
    sleep(15)

    -- Assign roles to workers with retry logic
    print("\nAssigning AI roles to workers...")
    for i, comp in ipairs(computers) do
        local role = M.ROLES[i]
        if role then
            print("  " .. role:upper() .. " -> worker " .. comp.id .. "...")

            -- Retry role assignment up to 6 times (30 second total window)
            local assigned = false
            for attempt = 1, 6 do
                -- Send role assignment
                rednet.send(comp.id, {
                    type = "assign_role",
                    role = role,
                    modules = M.MODULE_MAP[role]
                }, M.PROTOCOL)

                -- Wait for acknowledgment (5 seconds per attempt)
                local deadline = os.clock() + 5
                while os.clock() < deadline do
                    local senderID, message = rednet.receive(M.PROTOCOL, 0.5)
                    if senderID == comp.id and message and message.type == "role_ack" then
                        M.workers[role] = {
                            id = comp.id,
                            name = comp.name,
                            ready = message.ok,
                            modules = message.loaded_modules or {}
                        }
                        print("  " .. role:upper() .. ": " .. (message.ok and "READY" or "ERROR") ..
                              " (" .. #(message.loaded_modules or {}) .. " modules)")
                        assigned = true
                        break
                    end
                end

                if assigned then break end
                if attempt < 6 then
                    print("    Attempt " .. attempt .. " timed out, retrying...")
                end
            end

            if not assigned then
                M.workers[role] = {id = comp.id, name = comp.name, ready = false}
                print("  " .. role:upper() .. ": FAILED (worker " .. comp.id ..
                      " not responding - run cluster_worker_setup.lua on that computer)")
            end
        end
    end

    -- Count ready workers
    local ready_count = 0
    for _, worker in pairs(M.workers) do
        if worker.ready then
            ready_count = ready_count + 1
        end
    end

    print("\nCluster Status: " .. ready_count .. "/" .. #computers .. " workers ready")
    print("Total AI modules distributed across cluster\n")

    return ready_count > 0
end

-- ============================================================================
-- TASK DISTRIBUTION
-- ============================================================================

M.taskID = 0

function M.dispatch(role, task, data, timeout)
    local worker = M.workers[role]
    if not worker or not worker.ready then
        return {error = "Worker not ready: " .. role}
    end

    M.taskID = M.taskID + 1
    local currentTaskID = M.taskID

    -- Send task to worker
    rednet.send(worker.id, {
        type = "task",
        task = task,
        taskId = currentTaskID,
        data = data or {}
    }, M.PROTOCOL)

    -- Wait for result
    local deadline = os.clock() + (timeout or 3)
    while os.clock() < deadline do
        local senderID, message = rednet.receive(M.PROTOCOL, 0.3)
        if message and message.type == "result" and message.taskId == currentTaskID then
            return message.result
        end
    end

    return {error = "Task timeout"}
end

-- ============================================================================
-- HIGH-LEVEL AI FUNCTIONS
-- ============================================================================

function M.processInput(input, userName)
    local results = {}

    -- Language processing (via neural worker - has tokenization, embeddings, etc.)
    local languageResult = M.dispatch("neural", "analyze", {text = input})
    results.language = languageResult

    -- Get user context from memory worker (has conversation_memory, context, user_data)
    local userContext = M.dispatch("memory", "getUser", {name = userName})
    results.userContext = userContext

    -- Determine intent and sentiment
    local sentiment = (languageResult and languageResult.sentiment) or 0
    local intent = M.detectIntent(input)
    results.intent = intent
    results.sentiment = sentiment

    -- Context processing (via memory worker - has context module)
    local contextData = M.dispatch("memory", "process", {
        input = input,
        intent = intent,
        user = userName,
        history = (userContext and userContext.history) or {}
    })
    results.context = contextData

    return results
end

function M.generateResponse(input, userName, processingResults)
    local intent = processingResults.intent or "statement"
    local sentiment = processingResults.sentiment or 0
    local context = processingResults.context or {}

    local response = nil

    -- Route to appropriate generation module based on intent
    if intent == "greeting" then
        local result = M.dispatch("generation", "generateGreeting", {context = context})
        response = result and result.response
    elseif intent == "farewell" then
        local result = M.dispatch("generation", "generateFarewell", {})
        response = result and result.response
    elseif intent == "question" then
        -- Try knowledge/memory worker first (has knowledge_graph)
        local knowledgeResult = M.dispatch("memory", "query", {question = input})
        if knowledgeResult and knowledgeResult.answer then
            response = knowledgeResult.answer
        else
            -- Fall back to generation worker
            local result = M.dispatch("generation", "generateContextual", {
                intent = "question",
                context = context,
                input = input
            })
            response = result and result.response
        end
    elseif intent == "code_request" then
        -- code_generator is in generation worker
        local result = M.dispatch("generation", "generate_code", {
            request = input,
            context = context
        })
        response = result and result.code
    elseif intent == "joke" then
        local result = M.dispatch("generation", "generateJoke", {})
        response = result and result.response
    else
        -- Default contextual response via generation worker
        local result = M.dispatch("generation", "generateContextual", {
            intent = intent,
            context = context,
            input = input,
            sentiment = sentiment
        })
        response = result and result.response
    end

    -- Record interaction in memory worker (has conversation_memory)
    M.dispatch("memory", "record", {
        user = userName,
        input = input,
        response = response,
        sentiment = sentiment,
        intent = intent
    })

    -- Update personality via generation worker (has personality, mood)
    M.dispatch("generation", "update_personality", {
        sentiment = sentiment,
        intent = intent
    })

    return response or "I'm thinking..."
end

function M.learn(input, feedback)
    -- Distribute learning across relevant workers

    -- Neural learning (worker 1)
    M.dispatch("neural", "train", {
        input = input,
        feedback = feedback
    })

    -- Machine learning + RLHF (worker 2 has both)
    M.dispatch("learning", "update", {
        data = input,
        feedback = feedback
    })
    M.dispatch("learning", "rlhf_feedback", {
        input = input,
        feedback = feedback
    })

    return true
end

function M.getStatus()
    local status = {
        master = M.masterID,
        workers = {},
        total_modules = 0
    }

    for role, worker in pairs(M.workers) do
        status.workers[role] = {
            id = worker.id,
            ready = worker.ready,
            modules = #(worker.modules or {})
        }
        status.total_modules = status.total_modules + #(worker.modules or {})
    end

    return status
end

-- ============================================================================
-- INTENT DETECTION
-- ============================================================================

function M.detectIntent(text)
    local lower = text:lower()

    if lower:match("^h[ie]") or lower:match("^hey") or lower:match("^hello") then
        return "greeting"
    elseif lower:match("bye") or lower:match("goodbye") or lower:match("see you") then
        return "farewell"
    elseif lower:match("how are") or lower:match("what's up") then
        return "how_are_you"
    elseif lower:match("thank") then
        return "thanks"
    elseif lower:match("who are") or lower:match("what are you") then
        return "about_ai"
    elseif lower:match("joke") or lower:match("funny") then
        return "joke"
    elseif lower:match("code") or lower:match("program") or lower:match("function") then
        return "code_request"
    elseif lower:match("%?$") then
        return "question"
    else
        return "statement"
    end
end

-- ============================================================================
-- SHUTDOWN
-- ============================================================================

function M.shutdown()
    print("\nShutting down cluster...")
    for role, worker in pairs(M.workers) do
        rednet.send(worker.id, {type = "shutdown"}, M.PROTOCOL)
    end
    print("Cluster shutdown complete")
end

-- ============================================================================
-- INTERACTIVE MODE
-- ============================================================================

function M.run()
    if not M.init() then
        print("ERROR: Failed to initialize cluster")
        return
    end

    print("SuperAI Cluster is ready!")
    print("Type 'quit' to exit, 'status' for cluster status")
    print("")

    local userName = "User"

    while true do
        write(userName .. "> ")
        local input = read()

        if not input or input == "" then
            -- Skip empty input
        elseif input == "quit" or input == "exit" then
            M.shutdown()
            break
        elseif input == "status" then
            local status = M.getStatus()
            print("\nCluster Status:")
            print("Master ID: " .. status.master)
            print("Total Modules: " .. status.total_modules)
            for role, info in pairs(status.workers) do
                print("  " .. role .. ": " .. (info.ready and "READY" or "DOWN") ..
                      " (" .. info.modules .. " modules)")
            end
            print("")
        elseif input:match("^name ") then
            userName = input:sub(6)
            print("Hello " .. userName .. "!")
        else
            -- Process input through cluster
            local processingResults = M.processInput(input, userName)
            local response = M.generateResponse(input, userName, processingResults)

            print("\nSuperAI: " .. response)
            if processingResults.intent then
                print("[" .. processingResults.intent .. " | sentiment: " ..
                      string.format("%.2f", processingResults.sentiment or 0) .. "]")
            end
            print("")
        end
    end
end

return M
