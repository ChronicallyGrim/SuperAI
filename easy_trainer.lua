-- easy_trainer.lua
-- Simple interface to teach your AI

local markov = require("markov")

print("=== AI Training System ===")
print("")

-- Load existing knowledge
markov.load("markov_data.dat")
local stats = markov.getStats()

if stats.total_sequences == 0 then
    print("No training data found. Initializing with defaults...")
    markov.initializeWithDefaults()
    stats = markov.getStats()
end

print(string.format("Current knowledge: %d sequences learned", stats.total_sequences))
print("")

while true do
    print("=== Training Options ===")
    print("1. Teach by example conversation")
    print("2. Feed text to learn from")
    print("3. Test the AI")
    print("4. View stats")
    print("5. Train from file")
    print("6. Save and exit")
    print("")
    write("Choice: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        print("Teach by conversation (type 'done' when finished)")
        print("")
        
        local conversation = {}
        local turn = 1
        
        while true do
            if turn % 2 == 1 then
                write("You: ")
            else
                write("AI should say: ")
            end
            
            local line = read()
            
            if line:lower() == "done" then
                break
            end
            
            if #line > 0 then
                table.insert(conversation, line)
                markov.train(line, 1)
                markov.train(line, 2)
            end
            
            turn = turn + 1
        end
        
        markov.save()
        print("")
        print(string.format("Learned %d new lines!", #conversation))
        
    elseif choice == "2" then
        print("Enter text to learn from (type 'done' on empty line):")
        print("")
        
        local lines = 0
        while true do
            local line = read()
            
            if line == "done" or #line == 0 then
                break
            end
            
            markov.train(line, 1)
            markov.train(line, 2)
            lines = lines + 1
        end
        
        markov.save()
        print("")
        print(string.format("Learned %d lines!", lines))
        
    elseif choice == "3" then
        print("Test the AI (type 'back' to return)")
        print("")
        
        while true do
            write("You: ")
            local input = read()
            
            if input:lower() == "back" then
                break
            end
            
            if #input > 0 then
                local response = markov.generateResponse(input, 2)
                print("AI: " .. response)
                print("")
                
                -- Learn from this interaction
                markov.learnFromConversation(input, response)
            end
        end
        
    elseif choice == "4" then
        stats = markov.getStats()
        print("=== AI Knowledge Stats ===")
        print(string.format("Total sequences: %d", stats.total_sequences))
        print(string.format("Unique starters: %d", stats.unique_starters))
        print("")
        print("Chains by order:")
        for order, count in pairs(stats.chains_by_order) do
            print(string.format("  Order %d: %d states", order, count))
        end
        
    elseif choice == "5" then
        print("Enter filename to train from:")
        local filename = read()
        
        if fs.exists(filename) then
            local file = fs.open(filename, "r")
            if file then
                local lines = 0
                while true do
                    local line = file.readLine()
                    if not line then break end
                    
                    if #line > 0 then
                        markov.train(line, 1)
                        markov.train(line, 2)
                        lines = lines + 1
                    end
                end
                file.close()
                
                markov.save()
                print(string.format("Learned %d lines from file!", lines))
            else
                print("Could not open file")
            end
        else
            print("File not found")
        end
        
    elseif choice == "6" then
        print("Saving...")
        markov.save()
        break
    end
    
    print("")
end

print("Training complete!")
print("")
print("The AI now has " .. markov.getStats().total_sequences .. " sequences in memory.")
print("It will use this knowledge in conversations!")
