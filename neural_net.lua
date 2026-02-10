-- Module: neural_net.lua
-- Complete neural network implementation for learning and predictions
-- Includes: LSTM, GRU, ensemble methods, advanced training, regularization

local M = {}

-- ============================================================================
-- NEURAL NETWORK CORE
-- ============================================================================

-- Create network with specified layer sizes
function M.create(layerSizes, config)
    config = config or {}
    local network = {
        layers = {},
        layerSizes = layerSizes,
        activationFunc = config.activationFunc or "relu",
        outputActivation = config.outputActivation or "sigmoid",
        dropout = config.dropout or 0.0,
        batchNorm = config.batchNorm or false,
        l2Regularization = config.l2Regularization or 0.0,

        -- Training history
        trainingHistory = {
            loss = {},
            accuracy = {},
            validationLoss = {},
            validationAccuracy = {}
        },

        -- Adaptive learning rate
        learningRateSchedule = config.learningRateSchedule or "constant",
        initialLearningRate = config.learningRate or 0.1,
        currentLearningRate = config.learningRate or 0.1,

        -- Momentum
        momentum = config.momentum or 0.9,
        velocities = {},

        -- Adam optimizer parameters
        adam = {
            beta1 = 0.9,
            beta2 = 0.999,
            epsilon = 1e-8,
            m = {}, -- First moment
            v = {}, -- Second moment
            t = 0   -- Time step
        }
    }

    for i = 1, #layerSizes - 1 do
        local layer = {
            weights = {},
            biases = {},
            inputSize = layerSizes[i],
            outputSize = layerSizes[i + 1],

            -- Batch normalization parameters
            gamma = {},
            beta = {},
            runningMean = {},
            runningVar = {},

            -- Layer type
            layerType = config.layerTypes and config.layerTypes[i] or "dense"
        }

        -- Initialize weights with He initialization for ReLU, Xavier for others
        local scale
        if network.activationFunc == "relu" then
            scale = math.sqrt(2.0 / layer.inputSize)
        else
            scale = math.sqrt(2.0 / (layer.inputSize + layer.outputSize))
        end

        for j = 1, layer.outputSize do
            layer.weights[j] = {}
            layer.gamma[j] = 1.0
            layer.beta[j] = 0.0
            layer.runningMean[j] = 0.0
            layer.runningVar[j] = 1.0

            for k = 1, layer.inputSize do
                layer.weights[j][k] = (math.random() - 0.5) * 2 * scale
            end
            layer.biases[j] = 0
        end

        -- Initialize velocities for momentum
        network.velocities[i] = {weights = {}, biases = {}}
        for j = 1, layer.outputSize do
            network.velocities[i].weights[j] = {}
            for k = 1, layer.inputSize do
                network.velocities[i].weights[j][k] = 0
            end
            network.velocities[i].biases[j] = 0
        end

        table.insert(network.layers, layer)
    end

    return network
end

-- ============================================================================
-- ACTIVATION FUNCTIONS
-- ============================================================================

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

function M.leakyRelu(x, alpha)
    alpha = alpha or 0.01
    return x > 0 and x or alpha * x
end

function M.leakyReluDerivative(x, alpha)
    alpha = alpha or 0.01
    return x > 0 and 1 or alpha
end

function M.tanh(x)
    return math.tanh(x)
end

function M.tanhDerivative(x)
    local t = math.tanh(x)
    return 1 - t * t
end

function M.softplus(x)
    if x > 20 then return x end
    return math.log(1 + math.exp(x))
end

function M.softplusDerivative(x)
    return M.sigmoid(x)
end

function M.swish(x)
    return x * M.sigmoid(x)
end

function M.swishDerivative(x)
    local sig = M.sigmoid(x)
    return sig + x * sig * (1 - sig)
end

function M.elu(x, alpha)
    alpha = alpha or 1.0
    return x > 0 and x or alpha * (math.exp(x) - 1)
end

function M.eluDerivative(x, alpha)
    alpha = alpha or 1.0
    return x > 0 and 1 or M.elu(x, alpha) + alpha
end

-- Softmax for multi-class classification
function M.softmax(x)
    local max_x = x[1]
    for i = 2, #x do
        if x[i] > max_x then max_x = x[i] end
    end

    local exp_x = {}
    local sum = 0
    for i = 1, #x do
        exp_x[i] = math.exp(x[i] - max_x)
        sum = sum + exp_x[i]
    end

    for i = 1, #exp_x do
        exp_x[i] = exp_x[i] / sum
    end

    return exp_x
end

-- Select activation function and its derivative
function M.getActivation(funcName)
    local activations = {
        sigmoid = {func = M.sigmoid, deriv = M.sigmoidDerivative},
        relu = {func = M.relu, deriv = M.reluDerivative},
        tanh = {func = M.tanh, deriv = M.tanhDerivative},
        leaky_relu = {func = M.leakyRelu, deriv = M.leakyReluDerivative},
        swish = {func = M.swish, deriv = M.swishDerivative},
        elu = {func = M.elu, deriv = M.eluDerivative},
        softplus = {func = M.softplus, deriv = M.softplusDerivative}
    }
    return activations[funcName] or activations.relu
end

-- ============================================================================
-- BATCH NORMALIZATION
-- ============================================================================

function M.batchNormForward(layer, z, training)
    if not training then
        -- Use running statistics during inference
        local normalized = {}
        for i = 1, #z do
            normalized[i] = layer.gamma[i] * ((z[i] - layer.runningMean[i]) /
                           math.sqrt(layer.runningVar[i] + 1e-8)) + layer.beta[i]
        end
        return normalized
    end

    -- Calculate mean
    local mean = 0
    for i = 1, #z do
        mean = mean + z[i]
    end
    mean = mean / #z

    -- Calculate variance
    local variance = 0
    for i = 1, #z do
        variance = variance + (z[i] - mean)^2
    end
    variance = variance / #z

    -- Update running statistics
    local momentum = 0.9
    for i = 1, #z do
        layer.runningMean[i] = momentum * layer.runningMean[i] + (1 - momentum) * mean
        layer.runningVar[i] = momentum * layer.runningVar[i] + (1 - momentum) * variance
    end

    -- Normalize
    local normalized = {}
    for i = 1, #z do
        normalized[i] = layer.gamma[i] * ((z[i] - mean) / math.sqrt(variance + 1e-8)) + layer.beta[i]
    end

    return normalized
end

-- ============================================================================
-- DROPOUT
-- ============================================================================

function M.applyDropout(activations, dropoutRate, training)
    if not training or dropoutRate == 0 then
        return activations
    end

    local dropped = {}
    local scale = 1.0 / (1.0 - dropoutRate)

    for i = 1, #activations do
        if math.random() > dropoutRate then
            dropped[i] = activations[i] * scale
        else
            dropped[i] = 0
        end
    end

    return dropped
end

-- ============================================================================
-- FORWARD PASS
-- ============================================================================

function M.forward(network, input, training)
    training = training or false
    local activations = {input}
    local zValues = {}
    local activation = M.getActivation(network.activationFunc)

    for layerIdx, layer in ipairs(network.layers) do
        local z = {}
        local a = {}

        -- Compute weighted sum
        for i = 1, layer.outputSize do
            z[i] = layer.biases[i]
            for j = 1, layer.inputSize do
                z[i] = z[i] + layer.weights[i][j] * activations[#activations][j]
            end
        end

        -- Batch normalization
        if network.batchNorm then
            z = M.batchNormForward(layer, z, training)
        end

        -- Apply activation function
        local isOutputLayer = (layerIdx == #network.layers)
        if isOutputLayer and network.outputActivation == "softmax" then
            a = M.softmax(z)
        else
            local activFunc = isOutputLayer and
                             M.getActivation(network.outputActivation) or activation
            for i = 1, #z do
                a[i] = activFunc.func(z[i])
            end
        end

        -- Apply dropout (not on output layer)
        if not isOutputLayer and training then
            a = M.applyDropout(a, network.dropout, training)
        end

        table.insert(zValues, z)
        table.insert(activations, a)
    end

    return activations[#activations], activations, zValues
end

-- ============================================================================
-- LOSS FUNCTIONS
-- ============================================================================

function M.meanSquaredError(predicted, target)
    local sum = 0
    for i = 1, #predicted do
        sum = sum + (predicted[i] - target[i])^2
    end
    return sum / #predicted
end

function M.crossEntropyLoss(predicted, target)
    local sum = 0
    for i = 1, #predicted do
        sum = sum + target[i] * math.log(math.max(predicted[i], 1e-10))
    end
    return -sum
end

function M.binaryCrossEntropy(predicted, target)
    local sum = 0
    for i = 1, #predicted do
        local p = math.max(math.min(predicted[i], 1 - 1e-7), 1e-7)
        sum = sum + target[i] * math.log(p) + (1 - target[i]) * math.log(1 - p)
    end
    return -sum / #predicted
end

-- ============================================================================
-- BACKWARD PASS (BACKPROPAGATION)
-- ============================================================================

function M.backward(network, input, target, learningRate, optimizer)
    optimizer = optimizer or "sgd"
    local output, activations, zValues = M.forward(network, input, true)
    local activation = M.getActivation(network.activationFunc)

    -- Calculate output layer error
    local delta = {}
    if network.outputActivation == "softmax" then
        -- Softmax + cross-entropy derivative
        for i = 1, #output do
            delta[i] = output[i] - target[i]
        end
    else
        local outputActivation = M.getActivation(network.outputActivation)
        for i = 1, #output do
            delta[i] = (output[i] - target[i]) * outputActivation.deriv(zValues[#zValues][i])
        end
    end

    -- Backpropagate through layers
    for l = #network.layers, 1, -1 do
        local layer = network.layers[l]
        local prevActivation = activations[l]

        -- Update weights and biases based on optimizer
        if optimizer == "adam" then
            M.updateWithAdam(network, layer, l, delta, prevActivation)
        elseif optimizer == "momentum" then
            M.updateWithMomentum(network, layer, l, delta, prevActivation, learningRate)
        else
            M.updateWithSGD(network, layer, delta, prevActivation, learningRate)
        end

        -- Calculate delta for previous layer
        if l > 1 then
            local newDelta = {}
            for j = 1, layer.inputSize do
                newDelta[j] = 0
                for i = 1, layer.outputSize do
                    newDelta[j] = newDelta[j] + delta[i] * layer.weights[i][j]
                end
                newDelta[j] = newDelta[j] * activation.deriv(zValues[l-1][j])
            end
            delta = newDelta
        end
    end

    return output
end

-- ============================================================================
-- OPTIMIZERS
-- ============================================================================

function M.updateWithSGD(network, layer, delta, prevActivation, learningRate)
    for i = 1, layer.outputSize do
        layer.biases[i] = layer.biases[i] - learningRate * delta[i]
        for j = 1, layer.inputSize do
            -- L2 regularization
            local regularization = network.l2Regularization * layer.weights[i][j]
            layer.weights[i][j] = layer.weights[i][j] - learningRate * (delta[i] * prevActivation[j] + regularization)
        end
    end
end

function M.updateWithMomentum(network, layer, layerIdx, delta, prevActivation, learningRate)
    local velocity = network.velocities[layerIdx]
    local momentum = network.momentum

    for i = 1, layer.outputSize do
        -- Bias update with momentum
        velocity.biases[i] = momentum * velocity.biases[i] - learningRate * delta[i]
        layer.biases[i] = layer.biases[i] + velocity.biases[i]

        -- Weight updates with momentum
        for j = 1, layer.inputSize do
            local regularization = network.l2Regularization * layer.weights[i][j]
            velocity.weights[i][j] = momentum * velocity.weights[i][j] -
                                    learningRate * (delta[i] * prevActivation[j] + regularization)
            layer.weights[i][j] = layer.weights[i][j] + velocity.weights[i][j]
        end
    end
end

function M.updateWithAdam(network, layer, layerIdx, delta, prevActivation)
    local adam = network.adam
    adam.t = adam.t + 1

    if not adam.m[layerIdx] then
        adam.m[layerIdx] = {weights = {}, biases = {}}
        adam.v[layerIdx] = {weights = {}, biases = {}}

        for i = 1, layer.outputSize do
            adam.m[layerIdx].weights[i] = {}
            adam.v[layerIdx].weights[i] = {}
            for j = 1, layer.inputSize do
                adam.m[layerIdx].weights[i][j] = 0
                adam.v[layerIdx].weights[i][j] = 0
            end
            adam.m[layerIdx].biases[i] = 0
            adam.v[layerIdx].biases[i] = 0
        end
    end

    local m = adam.m[layerIdx]
    local v = adam.v[layerIdx]
    local learningRate = network.currentLearningRate

    for i = 1, layer.outputSize do
        -- Bias updates
        m.biases[i] = adam.beta1 * m.biases[i] + (1 - adam.beta1) * delta[i]
        v.biases[i] = adam.beta2 * v.biases[i] + (1 - adam.beta2) * delta[i]^2

        local m_hat = m.biases[i] / (1 - adam.beta1^adam.t)
        local v_hat = v.biases[i] / (1 - adam.beta2^adam.t)

        layer.biases[i] = layer.biases[i] - learningRate * m_hat / (math.sqrt(v_hat) + adam.epsilon)

        -- Weight updates
        for j = 1, layer.inputSize do
            local gradient = delta[i] * prevActivation[j] + network.l2Regularization * layer.weights[i][j]

            m.weights[i][j] = adam.beta1 * m.weights[i][j] + (1 - adam.beta1) * gradient
            v.weights[i][j] = adam.beta2 * v.weights[i][j] + (1 - adam.beta2) * gradient^2

            m_hat = m.weights[i][j] / (1 - adam.beta1^adam.t)
            v_hat = v.weights[i][j] / (1 - adam.beta2^adam.t)

            layer.weights[i][j] = layer.weights[i][j] - learningRate * m_hat / (math.sqrt(v_hat) + adam.epsilon)
        end
    end
end

-- ============================================================================
-- LEARNING RATE SCHEDULES
-- ============================================================================

function M.updateLearningRate(network, epoch)
    if network.learningRateSchedule == "step" then
        -- Reduce by half every 10 epochs
        if epoch % 10 == 0 then
            network.currentLearningRate = network.currentLearningRate * 0.5
        end
    elseif network.learningRateSchedule == "exponential" then
        -- Exponential decay
        network.currentLearningRate = network.initialLearningRate * math.exp(-0.01 * epoch)
    elseif network.learningRateSchedule == "cosine" then
        -- Cosine annealing
        network.currentLearningRate = network.initialLearningRate *
            (1 + math.cos(math.pi * epoch / 100)) / 2
    end
    -- "constant" does nothing
end

-- ============================================================================
-- TRAINING
-- ============================================================================

function M.train(network, trainingData, epochs, learningRate, config)
    config = config or {}
    local optimizer = config.optimizer or "sgd"
    local verbose = config.verbose or false
    local validationData = config.validationData
    local earlyStoppingPatience = config.earlyStoppingPatience or 0
    local batchSize = config.batchSize or #trainingData

    network.currentLearningRate = learningRate or network.currentLearningRate
    network.initialLearningRate = network.currentLearningRate

    local bestValidationLoss = math.huge
    local patienceCounter = 0

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

        -- Mini-batch training
        for batchStart = 1, #shuffled, batchSize do
            local batchEnd = math.min(batchStart + batchSize - 1, #shuffled)

            for i = batchStart, batchEnd do
                local example = shuffled[i]
                local output = M.backward(network, example.input, example.target,
                                        network.currentLearningRate, optimizer)

                -- Calculate error
                for j = 1, #output do
                    totalError = totalError + (output[j] - example.target[j])^2
                end

                -- Check if prediction is correct (for classification)
                if #output == 1 then
                    local predicted = output[1] > 0.5 and 1 or 0
                    if predicted == example.target[1] then
                        correct = correct + 1
                    end
                else
                    -- Multi-class classification
                    local maxIdx, maxVal = 1, output[1]
                    local targetMaxIdx, targetMaxVal = 1, example.target[1]
                    for j = 2, #output do
                        if output[j] > maxVal then
                            maxIdx, maxVal = j, output[j]
                        end
                        if example.target[j] > targetMaxVal then
                            targetMaxIdx, targetMaxVal = j, example.target[j]
                        end
                    end
                    if maxIdx == targetMaxIdx then
                        correct = correct + 1
                    end
                end
            end
        end

        -- Update learning rate
        M.updateLearningRate(network, epoch)

        -- Calculate metrics
        local avgError = totalError / #trainingData
        local accuracy = correct / #trainingData

        table.insert(network.trainingHistory.loss, avgError)
        table.insert(network.trainingHistory.accuracy, accuracy)

        -- Validation
        if validationData then
            local valLoss, valAccuracy = M.validate(network, validationData)
            table.insert(network.trainingHistory.validationLoss, valLoss)
            table.insert(network.trainingHistory.validationAccuracy, valAccuracy)

            -- Early stopping
            if earlyStoppingPatience > 0 then
                if valLoss < bestValidationLoss then
                    bestValidationLoss = valLoss
                    patienceCounter = 0
                else
                    patienceCounter = patienceCounter + 1
                    if patienceCounter >= earlyStoppingPatience then
                        if verbose then
                            print(string.format("Early stopping at epoch %d", epoch))
                        end
                        break
                    end
                end
            end
        end

        if verbose and epoch % 10 == 0 then
            local msg = string.format("Epoch %d: Loss=%.4f, Accuracy=%.2f%%, LR=%.6f",
                epoch, avgError, accuracy * 100, network.currentLearningRate)
            if validationData then
                msg = msg .. string.format(", Val Loss=%.4f, Val Acc=%.2f%%",
                    network.trainingHistory.validationLoss[#network.trainingHistory.validationLoss],
                    network.trainingHistory.validationAccuracy[#network.trainingHistory.validationAccuracy] * 100)
            end
            print(msg)
        end
    end
end

function M.validate(network, validationData)
    local totalError = 0
    local correct = 0

    for _, example in ipairs(validationData) do
        local output = M.forward(network, example.input, false)

        -- Calculate error
        for i = 1, #output do
            totalError = totalError + (output[i] - example.target[i])^2
        end

        -- Check correctness
        if #output == 1 then
            local predicted = output > 0.5 and 1 or 0
            if predicted == example.target[1] then
                correct = correct + 1
            end
        else
            local maxIdx, maxVal = 1, output[1]
            local targetMaxIdx, targetMaxVal = 1, example.target[1]
            for i = 2, #output do
                if output[i] > maxVal then
                    maxIdx, maxVal = i, output[i]
                end
                if example.target[i] > targetMaxVal then
                    targetMaxIdx, targetMaxVal = i, example.target[i]
                end
            end
            if maxIdx == targetMaxIdx then
                correct = correct + 1
            end
        end
    end

    return totalError / #validationData, correct / #validationData
end

-- Predict using trained network
function M.predict(network, input)
    local output = M.forward(network, input, false)
    return output
end

-- ============================================================================
-- RECURRENT NEURAL NETWORKS - LSTM
-- ============================================================================

function M.createLSTM(inputSize, hiddenSize, outputSize)
    local lstm = {
        type = "LSTM",
        inputSize = inputSize,
        hiddenSize = hiddenSize,
        outputSize = outputSize,

        -- LSTM gates: forget, input, cell, output
        Wf = {}, Wi = {}, Wc = {}, Wo = {},
        Uf = {}, Ui = {}, Uc = {}, Uo = {},
        bf = {}, bi = {}, bc = {}, bo = {},

        -- Output layer
        Wy = {},
        by = {},

        -- Hidden state and cell state
        h = {},
        c = {}
    }

    -- Initialize weights
    local scale = math.sqrt(2.0 / (inputSize + hiddenSize))

    -- Initialize all gate weights
    for i = 1, hiddenSize do
        lstm.Wf[i] = {}
        lstm.Wi[i] = {}
        lstm.Wc[i] = {}
        lstm.Wo[i] = {}
        lstm.Uf[i] = {}
        lstm.Ui[i] = {}
        lstm.Uc[i] = {}
        lstm.Uo[i] = {}

        for j = 1, inputSize do
            lstm.Wf[i][j] = (math.random() - 0.5) * 2 * scale
            lstm.Wi[i][j] = (math.random() - 0.5) * 2 * scale
            lstm.Wc[i][j] = (math.random() - 0.5) * 2 * scale
            lstm.Wo[i][j] = (math.random() - 0.5) * 2 * scale
        end

        for j = 1, hiddenSize do
            lstm.Uf[i][j] = (math.random() - 0.5) * 2 * scale
            lstm.Ui[i][j] = (math.random() - 0.5) * 2 * scale
            lstm.Uc[i][j] = (math.random() - 0.5) * 2 * scale
            lstm.Uo[i][j] = (math.random() - 0.5) * 2 * scale
        end

        lstm.bf[i] = 1.0  -- Forget gate bias initialized to 1
        lstm.bi[i] = 0.0
        lstm.bc[i] = 0.0
        lstm.bo[i] = 0.0

        lstm.h[i] = 0.0
        lstm.c[i] = 0.0
    end

    -- Output layer weights
    for i = 1, outputSize do
        lstm.Wy[i] = {}
        for j = 1, hiddenSize do
            lstm.Wy[i][j] = (math.random() - 0.5) * 2 * scale
        end
        lstm.by[i] = 0.0
    end

    return lstm
end

function M.lstmForward(lstm, input)
    local h_prev = {}
    local c_prev = {}
    for i = 1, lstm.hiddenSize do
        h_prev[i] = lstm.h[i]
        c_prev[i] = lstm.c[i]
    end

    -- Compute gates
    local f = {}  -- Forget gate
    local i_gate = {}  -- Input gate
    local c_tilde = {}  -- Cell candidate
    local o = {}  -- Output gate

    for i = 1, lstm.hiddenSize do
        -- Forget gate
        local f_sum = lstm.bf[i]
        for j = 1, lstm.inputSize do
            f_sum = f_sum + lstm.Wf[i][j] * input[j]
        end
        for j = 1, lstm.hiddenSize do
            f_sum = f_sum + lstm.Uf[i][j] * h_prev[j]
        end
        f[i] = M.sigmoid(f_sum)

        -- Input gate
        local i_sum = lstm.bi[i]
        for j = 1, lstm.inputSize do
            i_sum = i_sum + lstm.Wi[i][j] * input[j]
        end
        for j = 1, lstm.hiddenSize do
            i_sum = i_sum + lstm.Ui[i][j] * h_prev[j]
        end
        i_gate[i] = M.sigmoid(i_sum)

        -- Cell candidate
        local c_sum = lstm.bc[i]
        for j = 1, lstm.inputSize do
            c_sum = c_sum + lstm.Wc[i][j] * input[j]
        end
        for j = 1, lstm.hiddenSize do
            c_sum = c_sum + lstm.Uc[i][j] * h_prev[j]
        end
        c_tilde[i] = M.tanh(c_sum)

        -- Output gate
        local o_sum = lstm.bo[i]
        for j = 1, lstm.inputSize do
            o_sum = o_sum + lstm.Wo[i][j] * input[j]
        end
        for j = 1, lstm.hiddenSize do
            o_sum = o_sum + lstm.Uo[i][j] * h_prev[j]
        end
        o[i] = M.sigmoid(o_sum)

        -- Update cell state and hidden state
        lstm.c[i] = f[i] * c_prev[i] + i_gate[i] * c_tilde[i]
        lstm.h[i] = o[i] * M.tanh(lstm.c[i])
    end

    -- Compute output
    local output = {}
    for i = 1, lstm.outputSize do
        local sum = lstm.by[i]
        for j = 1, lstm.hiddenSize do
            sum = sum + lstm.Wy[i][j] * lstm.h[j]
        end
        output[i] = sum
    end

    return output
end

function M.lstmReset(lstm)
    for i = 1, lstm.hiddenSize do
        lstm.h[i] = 0.0
        lstm.c[i] = 0.0
    end
end

-- ============================================================================
-- RECURRENT NEURAL NETWORKS - GRU
-- ============================================================================

function M.createGRU(inputSize, hiddenSize, outputSize)
    local gru = {
        type = "GRU",
        inputSize = inputSize,
        hiddenSize = hiddenSize,
        outputSize = outputSize,

        -- GRU gates: reset, update, candidate
        Wr = {}, Wz = {}, Wh = {},
        Ur = {}, Uz = {}, Uh = {},
        br = {}, bz = {}, bh = {},

        -- Output layer
        Wy = {},
        by = {},

        -- Hidden state
        h = {}
    }

    -- Initialize weights
    local scale = math.sqrt(2.0 / (inputSize + hiddenSize))

    for i = 1, hiddenSize do
        gru.Wr[i] = {}
        gru.Wz[i] = {}
        gru.Wh[i] = {}
        gru.Ur[i] = {}
        gru.Uz[i] = {}
        gru.Uh[i] = {}

        for j = 1, inputSize do
            gru.Wr[i][j] = (math.random() - 0.5) * 2 * scale
            gru.Wz[i][j] = (math.random() - 0.5) * 2 * scale
            gru.Wh[i][j] = (math.random() - 0.5) * 2 * scale
        end

        for j = 1, hiddenSize do
            gru.Ur[i][j] = (math.random() - 0.5) * 2 * scale
            gru.Uz[i][j] = (math.random() - 0.5) * 2 * scale
            gru.Uh[i][j] = (math.random() - 0.5) * 2 * scale
        end

        gru.br[i] = 0.0
        gru.bz[i] = 0.0
        gru.bh[i] = 0.0
        gru.h[i] = 0.0
    end

    -- Output layer
    for i = 1, outputSize do
        gru.Wy[i] = {}
        for j = 1, hiddenSize do
            gru.Wy[i][j] = (math.random() - 0.5) * 2 * scale
        end
        gru.by[i] = 0.0
    end

    return gru
end

function M.gruForward(gru, input)
    local h_prev = {}
    for i = 1, gru.hiddenSize do
        h_prev[i] = gru.h[i]
    end

    -- Reset gate
    local r = {}
    for i = 1, gru.hiddenSize do
        local r_sum = gru.br[i]
        for j = 1, gru.inputSize do
            r_sum = r_sum + gru.Wr[i][j] * input[j]
        end
        for j = 1, gru.hiddenSize do
            r_sum = r_sum + gru.Ur[i][j] * h_prev[j]
        end
        r[i] = M.sigmoid(r_sum)
    end

    -- Update gate
    local z = {}
    for i = 1, gru.hiddenSize do
        local z_sum = gru.bz[i]
        for j = 1, gru.inputSize do
            z_sum = z_sum + gru.Wz[i][j] * input[j]
        end
        for j = 1, gru.hiddenSize do
            z_sum = z_sum + gru.Uz[i][j] * h_prev[j]
        end
        z[i] = M.sigmoid(z_sum)
    end

    -- Candidate hidden state
    local h_tilde = {}
    for i = 1, gru.hiddenSize do
        local h_sum = gru.bh[i]
        for j = 1, gru.inputSize do
            h_sum = h_sum + gru.Wh[i][j] * input[j]
        end
        for j = 1, gru.hiddenSize do
            h_sum = h_sum + gru.Uh[i][j] * (r[j] * h_prev[j])
        end
        h_tilde[i] = M.tanh(h_sum)
    end

    -- Update hidden state
    for i = 1, gru.hiddenSize do
        gru.h[i] = (1 - z[i]) * h_prev[i] + z[i] * h_tilde[i]
    end

    -- Compute output
    local output = {}
    for i = 1, gru.outputSize do
        local sum = gru.by[i]
        for j = 1, gru.hiddenSize do
            sum = sum + gru.Wy[i][j] * gru.h[j]
        end
        output[i] = sum
    end

    return output
end

function M.gruReset(gru)
    for i = 1, gru.hiddenSize do
        gru.h[i] = 0.0
    end
end

-- ============================================================================
-- ENSEMBLE METHODS
-- ============================================================================

function M.createEnsemble(numModels, layerSizes, config)
    local ensemble = {
        models = {},
        numModels = numModels,
        votingMethod = config and config.votingMethod or "average"
    }

    for i = 1, numModels do
        -- Add slight randomization to each model's config
        local modelConfig = config or {}
        modelConfig.dropout = (modelConfig.dropout or 0.0) + math.random() * 0.1

        ensemble.models[i] = M.create(layerSizes, modelConfig)
    end

    return ensemble
end

function M.trainEnsemble(ensemble, trainingData, epochs, learningRate, config)
    config = config or {}

    -- Train each model independently
    for i, model in ipairs(ensemble.models) do
        if config.verbose then
            print(string.format("Training model %d/%d", i, ensemble.numModels))
        end

        -- Bootstrap sampling for each model
        local bootstrapData = {}
        for j = 1, #trainingData do
            bootstrapData[j] = trainingData[math.random(#trainingData)]
        end

        M.train(model, bootstrapData, epochs, learningRate, config)
    end
end

function M.predictEnsemble(ensemble, input)
    local predictions = {}

    -- Get prediction from each model
    for i, model in ipairs(ensemble.models) do
        predictions[i] = M.predict(model, input)
    end

    -- Combine predictions
    if ensemble.votingMethod == "average" then
        local output = {}
        for i = 1, #predictions[1] do
            local sum = 0
            for j = 1, #predictions do
                sum = sum + predictions[j][i]
            end
            output[i] = sum / #predictions
        end
        return output
    elseif ensemble.votingMethod == "majority" then
        -- For classification: majority vote
        local votes = {}
        for _, pred in ipairs(predictions) do
            local maxIdx = 1
            for i = 2, #pred do
                if pred[i] > pred[maxIdx] then
                    maxIdx = i
                end
            end
            votes[maxIdx] = (votes[maxIdx] or 0) + 1
        end

        local output = {}
        for i = 1, #predictions[1] do
            output[i] = 0
        end

        local maxVotes, maxIdx = 0, 1
        for idx, count in pairs(votes) do
            if count > maxVotes then
                maxVotes = count
                maxIdx = idx
            end
        end
        output[maxIdx] = 1

        return output
    end
end

-- ============================================================================
-- TRANSFER LEARNING
-- ============================================================================

function M.freezeLayers(network, numLayersToFreeze)
    network.frozenLayers = numLayersToFreeze
    return network
end

function M.unfreezeLayers(network)
    network.frozenLayers = 0
    return network
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
-- ADVANCED FEATURES
-- ============================================================================

-- K-fold cross validation
function M.crossValidate(layerSizes, data, k, epochs, learningRate, config)
    k = k or 5
    local foldSize = math.floor(#data / k)
    local results = {accuracy = {}, loss = {}}

    for fold = 1, k do
        local validationStart = (fold - 1) * foldSize + 1
        local validationEnd = fold * foldSize

        local trainData = {}
        local valData = {}

        for i = 1, #data do
            if i >= validationStart and i <= validationEnd then
                table.insert(valData, data[i])
            else
                table.insert(trainData, data[i])
            end
        end

        -- Create and train model
        local network = M.create(layerSizes, config)
        M.train(network, trainData, epochs, learningRate, config)

        -- Evaluate
        local loss, accuracy = M.validate(network, valData)
        table.insert(results.loss, loss)
        table.insert(results.accuracy, accuracy)
    end

    -- Calculate average
    local avgLoss, avgAccuracy = 0, 0
    for i = 1, k do
        avgLoss = avgLoss + results.loss[i]
        avgAccuracy = avgAccuracy + results.accuracy[i]
    end

    return {
        avgLoss = avgLoss / k,
        avgAccuracy = avgAccuracy / k,
        foldResults = results
    }
end

-- Neural architecture search (simple version)
function M.searchArchitecture(inputSize, outputSize, data, maxLayers, maxHiddenSize)
    maxLayers = maxLayers or 3
    maxHiddenSize = maxHiddenSize or 128

    local bestArchitecture = nil
    local bestScore = 0

    -- Try different architectures
    for numLayers = 1, maxLayers do
        for hiddenSize = 16, maxHiddenSize, 16 do
            local layerSizes = {inputSize}
            for i = 1, numLayers do
                table.insert(layerSizes, hiddenSize)
            end
            table.insert(layerSizes, outputSize)

            -- Quick evaluation
            local results = M.crossValidate(layerSizes, data, 3, 50, 0.01, {verbose = false})

            if results.avgAccuracy > bestScore then
                bestScore = results.avgAccuracy
                bestArchitecture = layerSizes
            end
        end
    end

    return bestArchitecture, bestScore
end

-- ============================================================================
-- SENTIMENT CLASSIFIER
-- ============================================================================

M.sentimentClassifier = nil

function M.createSentimentClassifier()
    -- Create network: 20 inputs (features) -> 10 hidden -> 5 hidden -> 3 output (negative/neutral/positive)
    M.sentimentClassifier = M.create({20, 10, 5, 3}, {
        activationFunc = "relu",
        outputActivation = "softmax",
        dropout = 0.2,
        l2Regularization = 0.001
    })

    -- Enhanced training data for sentiment
    local trainingData = {
        -- Positive
        {input = {1,1,1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0}, target = {0,0,1}},
        {input = {1,1,0,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0}, target = {0,0,1}},
        {input = {1,0,1,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0}, target = {0,0,1}},
        {input = {1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0}, target = {0,0,1}},

        -- Negative
        {input = {0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,0,0,0,0,0}, target = {1,0,0}},
        {input = {0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,1,0,0,0,0}, target = {1,0,0}},
        {input = {0,0,0,0,1,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0}, target = {1,0,0}},
        {input = {0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0}, target = {1,0,0}},

        -- Neutral
        {input = {0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0}, target = {0,1,0}},
        {input = {0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,1,0}, target = {0,1,0}},
        {input = {0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,1,0}, target = {0,1,0}},
    }

    M.train(M.sentimentClassifier, trainingData, 200, 0.1, {
        optimizer = "adam",
        verbose = false
    })

    return M.sentimentClassifier
end

function M.classifySentiment(message)
    if not M.sentimentClassifier then
        M.createSentimentClassifier()
    end

    -- Extract features from message
    local features = M.extractSentimentFeatures(message)
    local sentiment = M.predict(M.sentimentClassifier, features)

    -- Find max
    local maxIdx, maxVal = 1, sentiment[1]
    for i = 2, #sentiment do
        if sentiment[i] > maxVal then
            maxIdx, maxVal = i, sentiment[i]
        end
    end

    local labels = {"negative", "neutral", "positive"}
    return labels[maxIdx], maxVal
end

function M.extractSentimentFeatures(message)
    local lower = message:lower()
    local features = {}

    -- Positive words
    features[1] = (lower:find("good") or lower:find("great") or lower:find("love")) and 1 or 0
    features[2] = (lower:find("happy") or lower:find("awesome") or lower:find("excellent")) and 1 or 0
    features[3] = (lower:find("thank") or lower:find("appreciate")) and 1 or 0
    features[4] = (lower:find("wonderful") or lower:find("amazing") or lower:find("perfect")) and 1 or 0

    -- Negative words
    features[5] = (lower:find("bad") or lower:find("hate") or lower:find("terrible")) and 1 or 0
    features[6] = (lower:find("sad") or lower:find("angry") or lower:find("awful")) and 1 or 0
    features[7] = (lower:find("not") or lower:find("never")) and 1 or 0
    features[8] = (lower:find("horrible") or lower:find("worst") or lower:find("sucks")) and 1 or 0

    -- Neutral indicators
    features[9] = lower:find("?") and 1 or 0
    features[10] = #message / 100
    features[11] = (lower:find("maybe") or lower:find("perhaps")) and 1 or 0
    features[12] = (lower:find("!") ~= nil) and 1 or 0

    -- Advanced features
    features[13] = select(2, lower:gsub("%s+", "")) / 10  -- Word count
    features[14] = (lower:find("very") or lower:find("really")) and 1 or 0
    features[15] = (lower:find("but") or lower:find("however")) and 1 or 0
    features[16] = lower:find("!!!") and 1 or 0
    features[17] = (lower:find("okay") or lower:find("ok") or lower:find("fine")) and 1 or 0
    features[18] = (lower:find("think") or lower:find("feel")) and 1 or 0
    features[19] = (lower:find("just") or lower:find("only")) and 1 or 0
    features[20] = math.random() * 0.1  -- Small randomness

    return features
end

-- ============================================================================
-- RESPONSE QUALITY PREDICTOR
-- ============================================================================

M.qualityPredictor = nil

function M.createQualityPredictor()
    -- Predict if a response will be good (user satisfaction)
    M.qualityPredictor = M.create({25, 16, 8, 1}, {
        activationFunc = "relu",
        dropout = 0.3,
        l2Regularization = 0.01
    })
    return M.qualityPredictor
end

function M.trainOnFeedback(userMessage, botResponse, wasGood)
    if not M.qualityPredictor then
        M.createQualityPredictor()
    end

    local features = M.extractResponseFeatures(userMessage, botResponse)
    local target = {wasGood and 1 or 0}

    M.backward(M.qualityPredictor, features, target, 0.01, "adam")
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
    features[15] = select(2, botLower:gsub(",", "")) / 5 -- comma count

    -- Advanced features
    features[16] = (botLower:find("because") or botLower:find("since")) and 1 or 0
    features[17] = (botLower:find("however") or botLower:find("but")) and 1 or 0
    features[18] = (userLower:find("help") and botLower:find("help")) and 1 or 0
    features[19] = select(2, botLower:gsub("%.", "")) / 5 -- sentence count
    features[20] = (botLower:find("would") or botLower:find("could") or botLower:find("should")) and 1 or 0
    features[21] = (botLower:find("definitely") or botLower:find("certainly")) and 1 or 0
    features[22] = (botLower:find("maybe") or botLower:find("perhaps")) and 1 or 0
    features[23] = (userLower:find("thank") and botLower:find("welcome")) and 1 or 0
    features[24] = (botLower:find("understand") or botLower:find("know")) and 1 or 0
    features[25] = math.random() * 0.1 -- randomness factor

    return features
end

return M
