-- cluster_worker.lua
-- Worker node for SuperAI Cluster
-- Each worker loads specific AI modules based on assigned role

local PROTOCOL = "SUPERAI_CLUSTER"
local role = nil
local modules = {}
local loadedModules = {}

-- ============================================================================
-- MODULE LOADING
-- ============================================================================

local function findDiskPath()
    -- Search all sides for a disk with modules
    local sides = {"back", "front", "left", "right", "top", "bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "drive" then
            local path = disk.getMountPath(side)
            if path then
                return path
            end
        end
    end
    return ""
end

local function loadModule(moduleName, diskPath)
    local paths = {
        diskPath .. "/" .. moduleName .. ".lua",
        moduleName .. ".lua",
        "/" .. moduleName .. ".lua"
    }

    for _, path in ipairs(paths) do
        if fs.exists(path) then
            local success, module = pcall(dofile, path)
            if success then
                return module
            else
                print("  Error loading " .. moduleName .. ": " .. tostring(module))
            end
        end
    end

    -- Try require as fallback
    local success, module = pcall(require, moduleName)
    if success then
        return module
    end

    return nil
end

local function initializeModules(moduleList, diskPath)
    loadedModules = {}

    for _, moduleName in ipairs(moduleList) do
        local module = loadModule(moduleName, diskPath)
        if module then
            loadedModules[moduleName] = module

            -- Call init if available
            if type(module.init) == "function" then
                pcall(module.init)
            end

            -- Load data if available
            if type(module.load) == "function" then
                pcall(module.load)
            end
        end
    end

    return loadedModules
end

-- ============================================================================
-- TASK HANDLERS BY ROLE
-- ============================================================================

local taskHandlers = {
    -- NEURAL ROLE
    neural = {
        train = function(data)
            local nn = loadedModules["neural_net"] or loadedModules["large_neural_net"]
            if nn and nn.train then
                return {ok = pcall(nn.train, data.input, data.feedback)}
            end
            return {error = "No neural module"}
        end,
        predict = function(data)
            local nn = loadedModules["neural_net"] or loadedModules["large_neural_net"]
            if nn and nn.predict then
                local success, result = pcall(nn.predict, data.input)
                return success and {prediction = result} or {error = tostring(result)}
            end
            return {error = "No neural module"}
        end
    },

    -- LANGUAGE ROLE
    language = {
        analyze = function(data)
            local result = {}

            -- Tokenization
            local tokenizer = loadedModules["tokenization"]
            if tokenizer and tokenizer.tokenize then
                local success, tokens = pcall(tokenizer.tokenize, data.text or "")
                if success then
                    result.tokens = tokens
                end
            end

            -- Embeddings
            local emb = loadedModules["embeddings"]
            if emb and emb.getEmbedding then
                local success, embedding = pcall(emb.getEmbedding, data.text or "")
                if success then
                    result.embedding = embedding
                end
            end

            -- Word vectors (sentiment)
            local wv = loadedModules["word_vectors"]
            if wv and wv.getSentiment then
                local success, sentiment = pcall(wv.getSentiment, data.text or "")
                if success then
                    result.sentiment = sentiment
                end
            end

            return result
        end
    },

    -- LEARNING ROLE
    learning = {
        update = function(data)
            local ml = loadedModules["machine_learning"]
            if ml and ml.train then
                return {ok = pcall(ml.train, data.data, data.feedback)}
            end
            return {ok = false}
        end,
        autonomous_learn = function(data)
            local al = loadedModules["autonomous_learning"]
            if al and al.learn then
                return {ok = pcall(al.learn, data)}
            end
            return {ok = false}
        end
    },

    -- MEMORY ROLE
    memory = {
        record = function(data)
            local mem = loadedModules["conversation_memory"]
            if mem and mem.recordUserInteraction then
                pcall(mem.recordUserInteraction, data.user, data.input, data.sentiment, {
                    intent = data.intent,
                    response = data.response
                })
                return {ok = true}
            end
            return {ok = false}
        end,
        getUser = function(data)
            local mem = loadedModules["conversation_memory"]
            if mem and mem.getUser then
                local success, user = pcall(mem.getUser, data.name or "User")
                return success and {user = user} or {user = {}}
            end
            return {user = {}}
        end,
        search = function(data)
            local ms = loadedModules["memory_search"]
            if ms and ms.search then
                local success, results = pcall(ms.search, data.query)
                return success and {results = results} or {results = {}}
            end
            return {results = {}}
        end
    },

    -- PERSONALITY ROLE
    personality = {
        update = function(data)
            local pers = loadedModules["personality"]
            if pers and pers.updateMood then
                pcall(pers.updateMood, data.sentiment or 0)
            end

            local mood = loadedModules["mood"]
            if mood and mood.update then
                pcall(mood.update, data.sentiment or 0, data.intent or "")
            end

            return {ok = true}
        end,
        getState = function(data)
            local pers = loadedModules["personality"]
            local mood = loadedModules["mood"]

            local state = {}
            if pers and pers.getPersonality then
                local success, p = pcall(pers.getPersonality)
                if success then state.personality = p end
            end
            if mood and mood.getCurrentMood then
                local success, m = pcall(mood.getCurrentMood)
                if success then state.mood = m end
            end

            return state
        end
    },

    -- GENERATION ROLE
    generation = {
        generateGreeting = function(data)
            local gen = loadedModules["response_generator"]
            if gen and gen.generateGreeting then
                local success, resp = pcall(gen.generateGreeting, data.context)
                return success and {response = resp} or {response = "Hello!"}
            end
            return {response = "Hello!"}
        end,
        generateFarewell = function(data)
            local gen = loadedModules["response_generator"]
            if gen and gen.generateFarewell then
                local success, resp = pcall(gen.generateFarewell)
                return success and {response = resp} or {response = "Goodbye!"}
            end
            return {response = "Goodbye!"}
        end,
        generateContextual = function(data)
            -- Try context-aware markov first
            local cm = loadedModules["context_markov"]
            if cm and cm.generate then
                local success, resp = pcall(cm.generate, data.input, data.context)
                if success and resp then
                    return {response = resp}
                end
            end

            -- Fall back to regular markov
            local markov = loadedModules["markov"]
            if markov and markov.generate then
                local success, resp = pcall(markov.generate, data.input)
                if success and resp then
                    return {response = resp}
                end
            end

            -- Fall back to response generator
            local gen = loadedModules["response_generator"]
            if gen and gen.generateContextual then
                local success, resp = pcall(gen.generateContextual, data.intent, data.context)
                return success and {response = resp} or {response = "Interesting!"}
            end

            return {response = "I understand."}
        end,
        generateJoke = function(data)
            local gen = loadedModules["response_generator"]
            if gen and gen.generateJoke then
                local success, resp = pcall(gen.generateJoke, data.category)
                return success and {response = resp} or {response = "Why did the AI cross the road? To optimize its path!"}
            end
            return {response = "Why did the AI cross the road? To optimize its path!"}
        end
    },

    -- KNOWLEDGE ROLE
    knowledge = {
        query = function(data)
            local kg = loadedModules["knowledge_graph"]
            if kg and kg.query then
                local success, result = pcall(kg.query, data.question)
                return success and {answer = result} or {answer = nil}
            end
            return {answer = nil}
        end,
        define = function(data)
            local dict = loadedModules["dictionary"]
            if dict and dict.getDefinition then
                local success, def = pcall(dict.getDefinition, data.word)
                return success and {definition = def} or {definition = nil}
            end
            return {definition = nil}
        end
    },

    -- CODE ROLE
    code = {
        generate = function(data)
            local cg = loadedModules["code_generator"]
            if cg and cg.generate then
                local success, code = pcall(cg.generate, data.request, data.context)
                return success and {code = code} or {code = "-- Unable to generate code"}
            end
            return {code = "-- Code generation not available"}
        end
    },

    -- CONTEXT ROLE
    context = {
        process = function(data)
            local ctx = loadedModules["context"]
            if ctx and ctx.analyze then
                local success, result = pcall(ctx.analyze, data.input, data.history)
                return success and result or {}
            end
            return {}
        end
    },

    -- ADVANCED ROLE
    advanced = {
        rlhf_feedback = function(data)
            local rlhf = loadedModules["rlhf"]
            if rlhf and rlhf.addFeedback then
                pcall(rlhf.addFeedback, data.input, data.feedback)
                return {ok = true}
            end
            return {ok = false}
        end,
        attention_score = function(data)
            local att = loadedModules["attention"]
            if att and att.compute then
                local success, scores = pcall(att.compute, data.query, data.keys)
                return success and {scores = scores} or {scores = {}}
            end
            return {scores = {}}
        end
    }
}

-- ============================================================================
-- WORKER MAIN LOOP
-- ============================================================================

local function main()
    -- Open all modems
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            rednet.open(name)
        end
    end

    -- Find disk
    local diskPath = findDiskPath()

    term.clear()
    term.setCursorPos(1, 1)
    print("SuperAI Cluster Worker")
    print("ID: " .. os.getComputerID())
    print("Disk: " .. (diskPath ~= "" and diskPath or "NONE"))
    print("Waiting for role assignment...")
    print("")

    -- Wait for role assignment
    while true do
        local senderID, message = rednet.receive(PROTOCOL, 2)

        if message and message.type == "assign_role" then
            role = message.role
            print("Assigned role: " .. role:upper())
            print("Loading modules...")

            -- Load modules for this role
            local moduleList = message.modules or {}
            initializeModules(moduleList, diskPath)

            local loadedNames = {}
            for name, _ in pairs(loadedModules) do
                table.insert(loadedNames, name)
            end

            print("Loaded " .. #loadedNames .. " modules:")
            for _, name in ipairs(loadedNames) do
                print("  - " .. name)
            end

            -- Send acknowledgment
            rednet.send(senderID, {
                type = "role_ack",
                role = role,
                ok = #loadedNames > 0,
                loaded_modules = loadedNames
            }, PROTOCOL)

            print("\nReady for tasks!")
            break
        end
    end

    -- Task processing loop
    while true do
        local senderID, message = rednet.receive(PROTOCOL, 1)

        if message then
            if message.type == "task" then
                local handlers = taskHandlers[role]
                local handler = handlers and handlers[message.task]

                local result
                if handler then
                    local success, res = pcall(handler, message.data or {})
                    result = success and res or {error = tostring(res)}
                else
                    result = {error = "Unknown task: " .. tostring(message.task)}
                end

                rednet.send(senderID, {
                    type = "result",
                    taskId = message.taskId,
                    result = result
                }, PROTOCOL)

            elseif message.type == "shutdown" then
                print("\nShutting down...")
                break
            end
        end
    end
end

-- Run worker
main()
