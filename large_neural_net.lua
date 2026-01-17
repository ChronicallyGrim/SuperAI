-- Module: large_neural_net.lua
-- Large-scale neural network with 100,000+ parameters
-- Optimized for ComputerCraft storage and performance

local M = {}

-- ============================================================================
-- COMPRESSED STORAGE FORMAT
-- ============================================================================

-- Store weights more efficiently (5 chars instead of 8+ bytes)
function M.compressFloat(num)
    -- Round to 4 decimal places and store as string
    return string.format("%.4f", num)
end

function M.decompressFloat(str)
    return tonumber(str)
end

-- Store entire layer as compressed string
function M.compressLayer(layer)
    local parts = {}
    
    -- Store dimensions
    table.insert(parts, layer.input_size .. "x" .. layer.output_size)
    
    -- Store weights (compressed)
    local weights = {}
    for i = 1, layer.output_size do
        for j = 1, layer.input_size do
            table.insert(weights, M.compressFloat(layer.weights[i][j]))
        end
    end
    table.insert(parts, table.concat(weights, ","))
    
    -- Store biases
    local biases = {}
    for i = 1, layer.output_size do
        table.insert(biases, M.compressFloat(layer.biases[i]))
    end
    table.insert(parts, table.concat(biases, ","))
    
    return table.concat(parts, "|")
end

function M.decompressLayer(str)
    local parts = {}
    for part in str:gmatch("[^|]+") do
        table.insert(parts, part)
    end
    
    -- Parse dimensions
    local input_size, output_size = parts[1]:match("(%d+)x(%d+)")
    input_size = tonumber(input_size)
    output_size = tonumber(output_size)
    
    local layer = {
        weights = {},
        biases = {},
        input_size = input_size,
        output_size = output_size
    }
    
    -- Parse weights
    local weight_idx = 1
    local weights_str = parts[2]
    for w in weights_str:gmatch("[^,]+") do
        local i = math.floor((weight_idx - 1) / input_size) + 1
        local j = ((weight_idx - 1) % input_size) + 1
        
        if not layer.weights[i] then
            layer.weights[i] = {}
        end
        layer.weights[i][j] = M.decompressFloat(w)
        weight_idx = weight_idx + 1
    end
    
    -- Parse biases
    local bias_idx = 1
    for b in parts[3]:gmatch("[^,]+") do
        layer.biases[bias_idx] = M.decompressFloat(b)
        bias_idx = bias_idx + 1
    end
    
    return layer
end

-- ============================================================================
-- LARGE NETWORK CREATION
-- ============================================================================

function M.createLargeNetwork(architecture, storage_path)
    --[[
    architecture = "large" | "medium" | "massive"
    
    large: [1000, 500, 200, 50] = 610K params (~4MB)
    medium: [500, 200, 100, 10] = 121K params (~829KB)
    massive: [2000, 1000, 500, 100] = 2.5M params (needs multi-drive)
    ]]
    
    local architectures = {
        medium = {500, 200, 100, 10},
        large = {1000, 500, 200, 50},
        xlarge = {1500, 800, 400, 100},
        massive = {2000, 1000, 500, 100}
    }
    
    local layer_sizes = architectures[architecture] or architectures.large
    
    local network = {
        layers = {},
        layer_sizes = layer_sizes,
        learning_rate = 0.001,
        momentum = 0.9,
        architecture = architecture,
        storage_path = storage_path or "/neural_weights/",
        total_params = 0
    }
    
    -- Create storage directory
    if not fs.exists(network.storage_path) then
        fs.makeDir(network.storage_path)
    end
    
    -- Initialize layers
    for i = 1, #layer_sizes - 1 do
        local layer = {
            weights = {},
            biases = {},
            input_size = layer_sizes[i],
            output_size = layer_sizes[i + 1],
            layer_id = i
        }
        
        -- He initialization for ReLU
        local scale = math.sqrt(2.0 / layer.input_size)
        
        -- Initialize weights
        for j = 1, layer.output_size do
            layer.weights[j] = {}
            layer.biases[j] = 0
            
            for k = 1, layer.input_size do
                layer.weights[j][k] = (math.random() - 0.5) * 2 * scale
            end
        end
        
        -- Calculate parameter count
        local params = layer.input_size * layer.output_size + layer.output_size
        network.total_params = network.total_params + params
        
        table.insert(network.layers, layer)
    end
    
    print(string.format("Created %s network: %d parameters", 
        architecture, network.total_params))
    
    return network
end

-- ============================================================================
-- DISTRIBUTED STORAGE (Multi-Drive)
-- ============================================================================

function M.saveLayerToDrive(layer, filepath)
    local compressed = M.compressLayer(layer)
    local file = fs.open(filepath, "w")
    if file then
        file.write(compressed)
        file.close()
        return true
    end
    return false
end

function M.loadLayerFromDrive(filepath)
    if not fs.exists(filepath) then
        return nil
    end
    
    local file = fs.open(filepath, "r")
    if file then
        local compressed = file.readAll()
        file.close()
        return M.decompressLayer(compressed)
    end
    return nil
end

function M.saveNetwork(network)
    -- Save metadata
    local meta = {
        architecture = network.architecture,
        layer_sizes = network.layer_sizes,
        total_params = network.total_params,
        learning_rate = network.learning_rate
    }
    
    local meta_file = fs.open(network.storage_path .. "meta.dat", "w")
    if meta_file then
        meta_file.write(textutils.serialize(meta))
        meta_file.close()
    end
    
    -- Save each layer to separate file
    for i, layer in ipairs(network.layers) do
        local filepath = network.storage_path .. "layer_" .. i .. ".dat"
        M.saveLayerToDrive(layer, filepath)
    end
    
    return true
end

function M.loadNetwork(storage_path)
    storage_path = storage_path or "/neural_weights/"
    
    -- Load metadata
    local meta_file = fs.open(storage_path .. "meta.dat", "r")
    if not meta_file then
        return nil, "Network not found"
    end
    
    local meta = textutils.unserialize(meta_file.readAll())
    meta_file.close()
    
    -- Create network structure
    local network = {
        layers = {},
        layer_sizes = meta.layer_sizes,
        learning_rate = meta.learning_rate or 0.001,
        momentum = 0.9,
        architecture = meta.architecture,
        storage_path = storage_path,
        total_params = meta.total_params
    }
    
    -- Load each layer
    for i = 1, #meta.layer_sizes - 1 do
        local filepath = storage_path .. "layer_" .. i .. ".dat"
        local layer = M.loadLayerFromDrive(filepath)
        if layer then
            table.insert(network.layers, layer)
        else
            return nil, "Failed to load layer " .. i
        end
    end
    
    return network
end

-- ============================================================================
-- EFFICIENT FORWARD PASS
-- ============================================================================

function M.forward(network, input)
    local activation = input
    
    for layer_idx, layer in ipairs(network.layers) do
        local output = {}
        
        -- Matrix multiplication: output = weights * input + bias
        for i = 1, layer.output_size do
            local sum = layer.biases[i]
            for j = 1, layer.input_size do
                sum = sum + layer.weights[i][j] * activation[j]
            end
            
            -- ReLU activation for hidden layers, sigmoid for output
            if layer_idx == #network.layers then
                output[i] = 1 / (1 + math.exp(-sum))  -- Sigmoid
            else
                output[i] = sum > 0 and sum or 0.01 * sum  -- Leaky ReLU
            end
        end
        
        activation = output
    end
    
    return activation
end

-- ============================================================================
-- MINI-BATCH GRADIENT DESCENT
-- ============================================================================

function M.trainMiniBatch(network, batch, learning_rate)
    learning_rate = learning_rate or network.learning_rate
    
    -- Accumulate gradients across batch
    local grad_weights = {}
    local grad_biases = {}
    
    -- Initialize gradient accumulators
    for l = 1, #network.layers do
        grad_weights[l] = {}
        grad_biases[l] = {}
        for i = 1, network.layers[l].output_size do
            grad_weights[l][i] = {}
            grad_biases[l][i] = 0
            for j = 1, network.layers[l].input_size do
                grad_weights[l][i][j] = 0
            end
        end
    end
    
    local total_loss = 0
    
    -- Process each example in batch
    for _, example in ipairs(batch) do
        local loss, grads = M.computeGradients(network, example.input, example.target)
        total_loss = total_loss + loss
        
        -- Accumulate gradients
        for l = 1, #network.layers do
            for i = 1, network.layers[l].output_size do
                grad_biases[l][i] = grad_biases[l][i] + grads.biases[l][i]
                for j = 1, network.layers[l].input_size do
                    grad_weights[l][i][j] = grad_weights[l][i][j] + grads.weights[l][i][j]
                end
            end
        end
    end
    
    -- Update weights (average gradients)
    local batch_size = #batch
    for l = 1, #network.layers do
        for i = 1, network.layers[l].output_size do
            network.layers[l].biases[i] = network.layers[l].biases[i] - 
                learning_rate * (grad_biases[l][i] / batch_size)
            
            for j = 1, network.layers[l].input_size do
                network.layers[l].weights[i][j] = network.layers[l].weights[i][j] - 
                    learning_rate * (grad_weights[l][i][j] / batch_size)
            end
        end
    end
    
    return total_loss / batch_size
end

function M.computeGradients(network, input, target)
    -- Forward pass with activation caching
    local activations = {input}
    local z_values = {}
    
    for layer_idx, layer in ipairs(network.layers) do
        local z = {}
        local a = {}
        
        for i = 1, layer.output_size do
            z[i] = layer.biases[i]
            for j = 1, layer.input_size do
                z[i] = z[i] + layer.weights[i][j] * activations[#activations][j]
            end
            
            -- Activation
            if layer_idx == #network.layers then
                a[i] = 1 / (1 + math.exp(-z[i]))  -- Sigmoid
            else
                a[i] = z[i] > 0 and z[i] or 0.01 * z[i]  -- Leaky ReLU
            end
        end
        
        table.insert(z_values, z)
        table.insert(activations, a)
    end
    
    -- Calculate loss
    local output = activations[#activations]
    local loss = 0
    for i = 1, #output do
        loss = loss + (output[i] - target[i])^2
    end
    loss = loss / #output
    
    -- Backward pass
    local deltas = {}
    local grads = {weights = {}, biases = {}}
    
    -- Output layer delta
    local output_delta = {}
    for i = 1, #output do
        local error = output[i] - target[i]
        local sigmoid_grad = output[i] * (1 - output[i])
        output_delta[i] = error * sigmoid_grad
    end
    table.insert(deltas, 1, output_delta)
    
    -- Hidden layer deltas
    for l = #network.layers - 1, 1, -1 do
        local delta = {}
        for j = 1, network.layers[l].output_size do
            local error = 0
            for k = 1, network.layers[l + 1].output_size do
                error = error + deltas[1][k] * network.layers[l + 1].weights[k][j]
            end
            
            -- Leaky ReLU derivative
            local z = z_values[l][j]
            local relu_grad = z > 0 and 1 or 0.01
            delta[j] = error * relu_grad
        end
        table.insert(deltas, 1, delta)
    end
    
    -- Compute gradients
    for l = 1, #network.layers do
        grads.weights[l] = {}
        grads.biases[l] = {}
        
        for i = 1, network.layers[l].output_size do
            grads.biases[l][i] = deltas[l][i]
            grads.weights[l][i] = {}
            
            for j = 1, network.layers[l].input_size do
                grads.weights[l][i][j] = deltas[l][i] * activations[l][j]
            end
        end
    end
    
    return loss, grads
end

-- ============================================================================
-- HIGH-LEVEL TRAINING API
-- ============================================================================

function M.train(network, training_data, epochs, batch_size, verbose)
    epochs = epochs or 50
    batch_size = batch_size or 32
    verbose = verbose or true
    
    for epoch = 1, epochs do
        -- Shuffle data
        local shuffled = {}
        for i, v in ipairs(training_data) do
            shuffled[i] = v
        end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        
        local total_loss = 0
        local num_batches = 0
        
        -- Process in mini-batches
        for i = 1, #shuffled, batch_size do
            local batch = {}
            for j = i, math.min(i + batch_size - 1, #shuffled) do
                table.insert(batch, shuffled[j])
            end
            
            local loss = M.trainMiniBatch(network, batch, network.learning_rate)
            total_loss = total_loss + loss
            num_batches = num_batches + 1
        end
        
        if verbose and epoch % 5 == 0 then
            print(string.format("Epoch %d/%d: Loss = %.4f", 
                epoch, epochs, total_loss / num_batches))
            
            -- Save checkpoint
            if epoch % 20 == 0 then
                M.saveNetwork(network)
                print("  [Checkpoint saved]")
            end
        end
        
        -- Learning rate decay
        if epoch % 10 == 0 then
            network.learning_rate = network.learning_rate * 0.9
        end
    end
    
    -- Final save
    M.saveNetwork(network)
    return network
end

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

--[[
-- Create a large network (610K parameters)
local net = M.createLargeNetwork("large", "/disk2/neural/")

-- Prepare training data
local training_data = {
    {input = {0.1, 0.2, ...}, target = {1, 0, 0}},
    ...
}

-- Train
M.train(net, training_data, 100, 32, true)

-- Use
local output = M.forward(net, input_vector)

-- Load later
local loaded_net = M.loadNetwork("/disk2/neural/")
]]

return M
