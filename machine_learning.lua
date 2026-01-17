-- Module: machine_learning.lua
-- Machine learning algorithms for pattern recognition and clustering

local M = {}

-- ============================================================================
-- K-MEANS CLUSTERING
-- ============================================================================

function M.kmeans(data, k, maxIterations)
    maxIterations = maxIterations or 100
    local centroids = {}
    local clusters = {}
    
    -- Initialize centroids randomly
    for i = 1, k do
        centroids[i] = data[math.random(#data)]
    end
    
    for iteration = 1, maxIterations do
        -- Assign points to nearest centroid
        clusters = {}
        for i = 1, k do
            clusters[i] = {}
        end
        
        for _, point in ipairs(data) do
            local minDist = math.huge
            local closestCluster = 1
            
            for i, centroid in ipairs(centroids) do
                local dist = M.euclideanDistance(point, centroid)
                if dist < minDist then
                    minDist = dist
                    closestCluster = i
                end
            end
            
            table.insert(clusters[closestCluster], point)
        end
        
        -- Update centroids
        local changed = false
        for i = 1, k do
            if #clusters[i] > 0 then
                local newCentroid = M.calculateCentroid(clusters[i])
                if not M.pointsEqual(centroids[i], newCentroid) then
                    centroids[i] = newCentroid
                    changed = true
                end
            end
        end
        
        if not changed then
            break
        end
    end
    
    return clusters, centroids
end

function M.euclideanDistance(point1, point2)
    local sum = 0
    for i = 1, #point1 do
        sum = sum + (point1[i] - point2[i])^2
    end
    return math.sqrt(sum)
end

function M.calculateCentroid(points)
    local centroid = {}
    local dim = #points[1]
    
    for d = 1, dim do
        local sum = 0
        for _, point in ipairs(points) do
            sum = sum + point[d]
        end
        centroid[d] = sum / #points
    end
    
    return centroid
end

function M.pointsEqual(p1, p2)
    for i = 1, #p1 do
        if math.abs(p1[i] - p2[i]) > 0.001 then
            return false
        end
    end
    return true
end

-- ============================================================================
-- DECISION TREE
-- ============================================================================

function M.buildDecisionTree(data, labels, maxDepth)
    maxDepth = maxDepth or 10
    
    local function entropy(labelSubset)
        local counts = {}
        for _, label in ipairs(labelSubset) do
            counts[label] = (counts[label] or 0) + 1
        end
        
        local ent = 0
        for _, count in pairs(counts) do
            local p = count / #labelSubset
            ent = ent - p * math.log(p)
        end
        return ent
    end
    
    local function findBestSplit(dataSubset, labelSubset)
        local bestGain = 0
        local bestFeature = nil
        local bestThreshold = nil
        
        local baseEntropy = entropy(labelSubset)
        
        for feature = 1, #dataSubset[1] do
            local values = {}
            for i = 1, #dataSubset do
                values[i] = dataSubset[i][feature]
            end
            table.sort(values)
            
            for i = 1, #values - 1 do
                local threshold = (values[i] + values[i+1]) / 2
                
                local leftLabels = {}
                local rightLabels = {}
                
                for j = 1, #dataSubset do
                    if dataSubset[j][feature] <= threshold then
                        table.insert(leftLabels, labelSubset[j])
                    else
                        table.insert(rightLabels, labelSubset[j])
                    end
                end
                
                if #leftLabels > 0 and #rightLabels > 0 then
                    local leftEnt = entropy(leftLabels)
                    local rightEnt = entropy(rightLabels)
                    local weightedEnt = (#leftLabels / #labelSubset) * leftEnt + 
                                       (#rightLabels / #labelSubset) * rightEnt
                    local gain = baseEntropy - weightedEnt
                    
                    if gain > bestGain then
                        bestGain = gain
                        bestFeature = feature
                        bestThreshold = threshold
                    end
                end
            end
        end
        
        return bestFeature, bestThreshold, bestGain
    end
    
    local function build(dataSubset, labelSubset, depth)
        -- Check stopping conditions
        if depth >= maxDepth or #dataSubset == 0 then
            return {prediction = M.mostCommon(labelSubset)}
        end
        
        -- Check if all same label
        local allSame = true
        for i = 2, #labelSubset do
            if labelSubset[i] ~= labelSubset[1] then
                allSame = false
                break
            end
        end
        if allSame then
            return {prediction = labelSubset[1]}
        end
        
        -- Find best split
        local feature, threshold, gain = findBestSplit(dataSubset, labelSubset)
        
        if not feature or gain < 0.01 then
            return {prediction = M.mostCommon(labelSubset)}
        end
        
        -- Split data
        local leftData, leftLabels = {}, {}
        local rightData, rightLabels = {}, {}
        
        for i = 1, #dataSubset do
            if dataSubset[i][feature] <= threshold then
                table.insert(leftData, dataSubset[i])
                table.insert(leftLabels, labelSubset[i])
            else
                table.insert(rightData, dataSubset[i])
                table.insert(rightLabels, labelSubset[i])
            end
        end
        
        return {
            feature = feature,
            threshold = threshold,
            left = build(leftData, leftLabels, depth + 1),
            right = build(rightData, rightLabels, depth + 1)
        }
    end
    
    return build(data, labels, 0)
end

function M.predictDecisionTree(tree, point)
    if tree.prediction then
        return tree.prediction
    end
    
    if point[tree.feature] <= tree.threshold then
        return M.predictDecisionTree(tree.left, point)
    else
        return M.predictDecisionTree(tree.right, point)
    end
end

-- ============================================================================
-- NAIVE BAYES CLASSIFIER
-- ============================================================================

function M.trainNaiveBayes(data, labels)
    local model = {
        classCounts = {},
        featureCounts = {},
        totalCount = #labels
    }
    
    -- Count classes
    for _, label in ipairs(labels) do
        model.classCounts[label] = (model.classCounts[label] or 0) + 1
    end
    
    -- Count features per class
    for i, point in ipairs(data) do
        local label = labels[i]
        if not model.featureCounts[label] then
            model.featureCounts[label] = {}
        end
        
        for feature = 1, #point do
            if not model.featureCounts[label][feature] then
                model.featureCounts[label][feature] = {}
            end
            
            local value = point[feature]
            model.featureCounts[label][feature][value] = 
                (model.featureCounts[label][feature][value] or 0) + 1
        end
    end
    
    return model
end

function M.predictNaiveBayes(model, point)
    local bestClass = nil
    local bestProb = -math.huge
    
    for class, classCount in pairs(model.classCounts) do
        local prob = math.log(classCount / model.totalCount)
        
        for feature = 1, #point do
            local value = point[feature]
            local featureCount = 0
            
            if model.featureCounts[class][feature] then
                featureCount = model.featureCounts[class][feature][value] or 0
            end
            
            -- Laplace smoothing
            prob = prob + math.log((featureCount + 1) / (classCount + 2))
        end
        
        if prob > bestProb then
            bestProb = prob
            bestClass = class
        end
    end
    
    return bestClass
end

-- ============================================================================
-- LINEAR REGRESSION
-- ============================================================================

function M.linearRegression(X, y, learningRate, iterations)
    learningRate = learningRate or 0.01
    iterations = iterations or 1000
    
    local m = #X -- number of samples
    local n = #X[1] -- number of features
    
    -- Initialize weights and bias
    local weights = {}
    for i = 1, n do
        weights[i] = 0
    end
    local bias = 0
    
    -- Gradient descent
    for iter = 1, iterations do
        local predictions = {}
        
        -- Forward pass
        for i = 1, m do
            local pred = bias
            for j = 1, n do
                pred = pred + weights[j] * X[i][j]
            end
            predictions[i] = pred
        end
        
        -- Calculate gradients
        local dw = {}
        for j = 1, n do
            dw[j] = 0
        end
        local db = 0
        
        for i = 1, m do
            local error = predictions[i] - y[i]
            db = db + error
            for j = 1, n do
                dw[j] = dw[j] + error * X[i][j]
            end
        end
        
        -- Update parameters
        bias = bias - learningRate * db / m
        for j = 1, n do
            weights[j] = weights[j] - learningRate * dw[j] / m
        end
    end
    
    return {weights = weights, bias = bias}
end

function M.predictLinear(model, x)
    local pred = model.bias
    for i = 1, #x do
        pred = pred + model.weights[i] * x[i]
    end
    return pred
end

-- ============================================================================
-- K-NEAREST NEIGHBORS
-- ============================================================================

function M.knn(trainData, trainLabels, testPoint, k)
    k = k or 3
    
    -- Calculate distances
    local distances = {}
    for i, point in ipairs(trainData) do
        local dist = M.euclideanDistance(point, testPoint)
        table.insert(distances, {dist = dist, label = trainLabels[i]})
    end
    
    -- Sort by distance
    table.sort(distances, function(a, b) return a.dist < b.dist end)
    
    -- Get k nearest neighbors
    local votes = {}
    for i = 1, math.min(k, #distances) do
        local label = distances[i].label
        votes[label] = (votes[label] or 0) + 1
    end
    
    -- Return most common label
    return M.mostCommon(votes)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function M.mostCommon(items)
    if type(items) == "table" and #items == 0 then
        -- It's a counts table, not array
        local maxCount = 0
        local mostCommon = nil
        for item, count in pairs(items) do
            if count > maxCount then
                maxCount = count
                mostCommon = item
            end
        end
        return mostCommon
    else
        -- It's an array
        local counts = {}
        for _, item in ipairs(items) do
            counts[item] = (counts[item] or 0) + 1
        end
        return M.mostCommon(counts)
    end
end

function M.normalize(data)
    local normalized = {}
    local mins = {}
    local maxs = {}
    
    -- Find min and max for each feature
    for feature = 1, #data[1] do
        mins[feature] = math.huge
        maxs[feature] = -math.huge
        
        for _, point in ipairs(data) do
            if point[feature] < mins[feature] then
                mins[feature] = point[feature]
            end
            if point[feature] > maxs[feature] then
                maxs[feature] = point[feature]
            end
        end
    end
    
    -- Normalize
    for i, point in ipairs(data) do
        normalized[i] = {}
        for feature = 1, #point do
            local range = maxs[feature] - mins[feature]
            if range > 0 then
                normalized[i][feature] = (point[feature] - mins[feature]) / range
            else
                normalized[i][feature] = 0
            end
        end
    end
    
    return normalized, mins, maxs
end

return M
