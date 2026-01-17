-- Module: neural_net.lua
-- Complete neural network implementation for learning and predictions

local M = {}

-- ============================================================================
-- NEURAL NETWORK CORE
-- ============================================================================

-- Create network with specified layer sizes
function M.create(layerSizes)
    local network = {
        layers = {},
        layerSizes = layerSizes
    }
    
    for i = 1, #layerSizes - 1 do
        local layer = {
            weights = {},
            biases = {},
            inputSize = layerSizes[i],
            outputSize = layerSizes[i + 1]
        }
        
        -- Initialize weights with Xavier initialization
        local scale = math.sqrt(2.0 / (layer.inputSize + layer.outputSize))
        for j = 1, layer.outputSize do
            layer.weights[j] = {}
            for k = 1, layer.inputSize do
                layer.weights[j][k] = (math.random() - 0.5) * 2 * scale
            end
            layer.biases[j] = 0
        end
        
        table.insert(network.layers, layer)
    end
    
    return network
end

-- Activation functions
function M.sigmoid(x)
    if x < -45 then return 0 end
    if x > 45 then return 1 end
    return 1 / (1 + math.exp(-x))
end

function M.sigmoidDerivative(x)
    local s = M.sigmoid(x)
    return s * (1 - s)
end

function M.relu(x)
    return math.max(0, x)
end

function M.reluDerivative(x)
    return x > 0 and 1 or 0
end

function M.tanh(x)
    return math.tanh(x)
end

function M.tanhDerivative(x)
    local t = math.tanh(x)
    return 1 - t * t
end

-- Forward pass through network
function M.forward(network, input)
    local activations = {input}
    local zValues = {}
    
    for layerIdx, layer in ipairs(network.layers) do
        local z = {}
        local a = {}
        
        for i = 1, layer.outputSize do
            z[i] = layer.biases[i]
            for j = 1, layer.inputSize do
                z[i] = z[i] + layer.weights[i][j] * activations[#activations][j]
            end
            a[i] = M.sigmoid(z[i])
        end
        
        table.insert(zValues, z)
        table.insert(activations, a)
    end
    
    return activations[#activations], activations, zValues
end

-- Backward pass (backpropagation)
function M.backward(network, input, target, learningRate)
    local output, activations, zValues = M.forward(network, input)
    
    -- Calculate output layer error
    local delta = {}
    for i = 1, #output do
        delta[i] = (output[i] - target[i]) * M.sigmoidDerivative(zValues[#zValues][i])
    end
    
    -- Backpropagate through layers
    for l = #network.layers, 1, -1 do
        local layer = network.layers[l]
        local prevActivation = activations[l]
        
        -- Update weights and biases
        for i = 1, layer.outputSize do
            layer.biases[i] = layer.biases[i] - learningRate * delta[i]
            for j = 1, layer.inputSize do
                layer.weights[i][j] = layer.weights[i][j] - learningRate * delta[i] * prevActivation[j]
            end
        end
        
        -- Calculate delta for previous layer
        if l > 1 then
            local newDelta = {}
            for j = 1, layer.inputSize do
                newDelta[j] = 0
                for i = 1, layer.outputSize do
                    newDelta[j] = newDelta[j] + delta[i] * layer.weights[i][j]
                end
                newDelta[j] = newDelta[j] * M.sigmoidDerivative(zValues[l-1][j])
            end
            delta = newDelta
        end
    end
    
    return output
end

-- Train network on dataset
function M.train(network, trainingData, epochs, learningRate, verbose)
    learningRate = learningRate or 0.1
    verbose = verbose or false
    
    for epoch = 1, epochs do
        local totalError = 0
        local correct = 0
        
        -- Shuffle training data
        local shuffled = {}
        for i, v in ipairs(trainingData) do
            shuffled[i] = v
        end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        
        for _, example in ipairs(shuffled) do
            local output = M.backward(network, example.input, example.target, learningRate)
            
            -- Calculate error
            for i = 1, #output do
                totalError = totalError + (output[i] - example.target[i])^2
            end
            
            -- Check if prediction is correct (for classification)
            if #output == 1 then
                local predicted = output[1] > 0.5 and 1 or 0
                if predicted == example.target[1] then
                    correct = correct + 1
                end
            end
        end
        
        if verbose and epoch % 100 == 0 then
            local avgError = totalError / #trainingData
            local accuracy = correct / #trainingData
            print(string.format("Epoch %d: Error=%.4f, Accuracy=%.2f%%", 
                epoch, avgError, accuracy * 100))
        end
    end
end

-- Predict using trained network
function M.predict(network, input)
    local output = M.forward(network, input)
    return output
end

-- ============================================================================
-- SAVE/LOAD NETWORK
-- ============================================================================

function M.save(network, filename)
    local serialized = textutils.serialize(network)
    local file = fs.open(filename, "w")
    if not file then
        return false, "Could not open file for writing"
    end
    file.write(serialized)
    file.close()
    return true
end

function M.load(filename)
    if not fs.exists(filename) then
        return nil, "File does not exist"
    end
    
    local file = fs.open(filename, "r")
    if not file then
        return nil, "Could not open file for reading"
    end
    
    local content = file.readAll()
    file.close()
    
    local network = textutils.unserialize(content)
    return network
end

-- ============================================================================
-- SENTIMENT CLASSIFIER
-- ============================================================================

M.sentimentClassifier = nil

function M.createSentimentClassifier()
    -- Create network: 10 inputs (features) -> 5 hidden -> 1 output
    M.sentimentClassifier = M.create({10, 5, 1})
    
    -- Training data for sentiment
    local trainingData = {
        {input = {1,1,1,0,0,0,0,0,0,0}, target = {1}}, -- positive
        {input = {1,1,0,1,0,0,0,0,0,0}, target = {1}}, -- positive
        {input = {0,0,0,0,1,1,1,0,0,0}, target = {0}}, -- negative
        {input = {0,0,0,0,1,1,0,1,0,0}, target = {0}}, -- negative
        {input = {1,0,1,0,0,1,0,0,0,0}, target = {0.5}}, -- neutral
    }
    
    M.train(M.sentimentClassifier, trainingData, 500, 0.5, false)
    return M.sentimentClassifier
end

function M.classifySentiment(message)
    if not M.sentimentClassifier then
        M.createSentimentClassifier()
    end
    
    -- Extract features from message
    local features = M.extractSentimentFeatures(message)
    local sentiment = M.predict(M.sentimentClassifier, features)
    
    if sentiment > 0.6 then
        return "positive"
    elseif sentiment < 0.4 then
        return "negative"
    else
        return "neutral"
    end
end

function M.extractSentimentFeatures(message)
    local lower = message:lower()
    local features = {}
    
    -- Positive words
    features[1] = (lower:find("good") or lower:find("great") or lower:find("love")) and 1 or 0
    features[2] = (lower:find("happy") or lower:find("awesome") or lower:find("excellent")) and 1 or 0
    features[3] = (lower:find("thank") or lower:find("appreciate")) and 1 or 0
    
    -- Negative words
    features[4] = (lower:find("bad") or lower:find("hate") or lower:find("terrible")) and 1 or 0
    features[5] = (lower:find("sad") or lower:find("angry") or lower:find("awful")) and 1 or 0
    features[6] = (lower:find("not") or lower:find("never")) and 1 or 0
    
    -- Neutral indicators
    features[7] = lower:find("?") and 1 or 0
    features[8] = #message / 100
    features[9] = (lower:find("maybe") or lower:find("perhaps")) and 1 or 0
    features[10] = (lower:find("!") ~= nil) and 1 or 0
    
    return features
end

-- ============================================================================
-- RESPONSE QUALITY PREDICTOR
-- ============================================================================

M.qualityPredictor = nil

function M.createQualityPredictor()
    -- Predict if a response will be good (user satisfaction)
    M.qualityPredictor = M.create({15, 8, 1})
    return M.qualityPredictor
end

function M.trainOnFeedback(userMessage, botResponse, wasGood)
    if not M.qualityPredictor then
        M.createQualityPredictor()
    end
    
    local features = M.extractResponseFeatures(userMessage, botResponse)
    local target = {wasGood and 1 or 0}
    
    M.backward(M.qualityPredictor, features, target, 0.1)
end

function M.predictQuality(userMessage, botResponse)
    if not M.qualityPredictor then
        return 0.5 -- Unknown
    end
    
    local features = M.extractResponseFeatures(userMessage, botResponse)
    local quality = M.predict(M.qualityPredictor, features)
    return quality
end

function M.extractResponseFeatures(userMessage, botResponse)
    local features = {}
    local userLower = userMessage:lower()
    local botLower = botResponse:lower()
    
    -- Length features
    features[1] = #userMessage / 100
    features[2] = #botResponse / 100
    features[3] = #botResponse / math.max(#userMessage, 1)
    
    -- Content features
    features[4] = userLower:find("?") and 1 or 0
    features[5] = botLower:find("?") and 1 or 0
    features[6] = (botLower:find("i ") ~= nil) and 1 or 0
    features[7] = (botLower:find("you ") ~= nil) and 1 or 0
    
    -- Sentiment alignment
    features[8] = (userLower:find("happy") and botLower:find("happy")) and 1 or 0
    features[9] = (userLower:find("sad") and botLower:find("sad")) and 1 or 0
    
    -- Response type
    features[10] = (botLower:find("sorry") ~= nil) and 1 or 0
    features[11] = (botLower:find("!") ~= nil) and 1 or 0
    features[12] = (botLower:find("think") or botLower:find("believe")) and 1 or 0
    
    -- Complexity
    features[13] = select(2, botResponse:gsub("%s+", "")) / 10 -- word count
    features[14] = (userLower:find("explain") or userLower:find("how")) and 1 or 0
    features[15] = math.random() -- randomness factor
    
    return features
end

return M
