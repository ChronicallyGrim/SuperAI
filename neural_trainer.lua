-- neural_trainer.lua
-- Program to train the neural network from your conversations

local neural = require("large_neural_net")

print("=== Neural Network Training System ===")
print("")

-- Check if network exists
local net = neural.loadNetwork("/neural/")
if not net then
    print("No trained network found. Creating new network...")
    print("Architecture: Large (610K parameters)")
    print("")
    
    net = neural.createLargeNetwork("large", "/neural/")
    print("Network created!")
    print("")
end

print(string.format("Network loaded: %d parameters", net.total_params))
print("Architecture: " .. table.concat(net.layer_sizes, " -> "))
print("")

-- Training menu
while true do
    print("=== Training Options ===")
    print("1. Train on sample conversations")
    print("2. Add single training example")
    print("3. Test network")
    print("4. View network stats")
    print("5. Save network")
    print("6. Exit")
    print("")
    write("Choice: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        print("Training on sample conversations...")
        print("This will take a few minutes...")
        print("")
        
        -- Create sample training data
        local training_data = {}
        
        -- Sentiment examples (positive/neutral/negative)
        local examples = {
            -- Positive
            {"I love this!", {1, 0, 0}},
            {"This is awesome!", {1, 0, 0}},
            {"Great job!", {1, 0, 0}},
            {"Thank you so much!", {1, 0, 0}},
            {"Perfect!", {1, 0, 0}},
            
            -- Neutral
            {"What time is it?", {0, 1, 0}},
            {"Hello there", {0, 1, 0}},
            {"I need help", {0, 1, 0}},
            {"Can you explain?", {0, 1, 0}},
            {"Tell me more", {0, 1, 0}},
            
            -- Negative
            {"I don't like this", {0, 0, 1}},
            {"This is wrong", {0, 0, 1}},
            {"Stop it", {0, 0, 1}},
            {"Not good", {0, 0, 1}},
            {"I'm confused", {0, 0, 1}}
        }
        
        -- Convert text to simple vectors
        for _, example in ipairs(examples) do
            local text = example[1]
            local label = example[2]
            
            -- Simple encoding: character-based
            local input = {}
            for i = 1, net.layer_sizes[1] do
                if i <= #text then
                    input[i] = string.byte(text, i) / 255
                else
                    input[i] = 0
                end
            end
            
            table.insert(training_data, {input = input, target = label})
        end
        
        -- Train
        neural.train(net, training_data, 50, 5, true)
        
        print("")
        print("Training complete!")
        
    elseif choice == "2" then
        print("Enter message to train on:")
        local message = read()
        
        print("Sentiment? (1=Positive, 2=Neutral, 3=Negative):")
        local sentiment = tonumber(read())
        
        if sentiment and sentiment >= 1 and sentiment <= 3 then
            local target = {0, 0, 0}
            target[sentiment] = 1
            
            -- Encode message
            local input = {}
            for i = 1, net.layer_sizes[1] do
                if i <= #message then
                    input[i] = string.byte(message, i) / 255
                else
                    input[i] = 0
                end
            end
            
            -- Train on single example (multiple times)
            local training_data = {{input = input, target = target}}
            neural.train(net, training_data, 10, 1, false)
            
            print("Learned!")
        else
            print("Invalid sentiment")
        end
        
    elseif choice == "3" then
        print("Enter message to test:")
        local message = read()
        
        -- Encode
        local input = {}
        for i = 1, net.layer_sizes[1] do
            if i <= #message then
                input[i] = string.byte(message, i) / 255
            else
                input[i] = 0
            end
        end
        
        -- Predict
        local output = neural.forward(net, input)
        
        print("")
        print("Network predictions:")
        print(string.format("  Positive: %.1f%%", output[1] * 100))
        print(string.format("  Neutral:  %.1f%%", output[2] * 100))
        print(string.format("  Negative: %.1f%%", output[3] * 100))
        
        local max_idx = 1
        for i = 2, #output do
            if output[i] > output[max_idx] then
                max_idx = i
            end
        end
        
        local labels = {"Positive", "Neutral", "Negative"}
        print("")
        print("Classification: " .. labels[max_idx])
        
    elseif choice == "4" then
        print("Network Statistics:")
        print(string.format("  Total parameters: %d", net.total_params))
        print(string.format("  Architecture: %s", table.concat(net.layer_sizes, " -> ")))
        print(string.format("  Learning rate: %.4f", net.learning_rate))
        print(string.format("  Storage: %s", net.storage_path))
        
    elseif choice == "5" then
        print("Saving network...")
        neural.saveNetwork(net)
        print("Saved!")
        
    elseif choice == "6" then
        print("Saving and exiting...")
        neural.saveNetwork(net)
        break
    end
    
    print("")
end

print("Goodbye!")
