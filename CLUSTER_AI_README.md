# SuperAI Unified Cluster System

## Overview

The SuperAI Unified Cluster System integrates **all 40+ AI modules** from the SuperAI repository into one massive, fully modular, distributed AI system using cluster computing architecture.

## Key Features

- **Unified Orchestration**: Single master controller coordinates all AI functions
- **Fully Modular**: Each AI capability runs as an independent module on dedicated worker nodes
- **Cluster Computing**: Distributes processing across multiple computers for scalability
- **No RAID System**: Uses pure cluster architecture without the 11-drive RAID dependency
- **All Modules Included**: Every AI module in the repository is integrated and functional

## Architecture

### Master Node
- Runs `superai_cluster.lua` orchestrator
- Coordinates all AI operations
- Manages task distribution to workers
- Provides unified interface to users

### Worker Nodes
Each worker is assigned a specialized AI role:

1. **Neural** - Neural network processing
   - `neural_net.lua`
   - `large_neural_net.lua`
   - `neural_trainer.lua`

2. **Language** - Language understanding
   - `tokenization.lua`
   - `embeddings.lua`
   - `word_vectors.lua`
   - `attention.lua`

3. **Learning** - Machine learning and training
   - `machine_learning.lua`
   - `learning.lua`
   - `autonomous_learning.lua`
   - All trainer modules (advanced, exponential, easy, unified, etc.)

4. **Memory** - Conversation memory and search
   - `conversation_memory.lua`
   - `memory_search.lua`
   - `memory_loader.lua`

5. **Personality** - Personality and mood
   - `personality.lua`
   - `mood.lua`
   - `user_data.lua`

6. **Generation** - Response generation
   - `response_generator.lua`
   - `responses.lua`
   - `markov.lua`
   - `context_markov.lua`
   - `sampling.lua`

7. **Knowledge** - Knowledge graph and dictionary
   - `knowledge_graph.lua`
   - `dictionary.lua`

8. **Code** - Code generation
   - `code_generator.lua`

9. **Context** - Context-aware processing
   - `context.lua`

10. **Advanced** - Advanced features
    - `rlhf.lua`
    - `ai_vs_ai.lua`
    - `advanced.lua`

## Installation

### Requirements
- 1 Master computer (with disk on 'back' side)
- 1+ Worker computers (with disks on any side)
- Network connectivity between all computers (modems)

### Steps

1. **On the Master Computer**, run:
```lua
wget run https://raw.githubusercontent.com/ChronicallyGrim/SuperAI/main/cluster_installer_v2.lua
```

2. The installer will:
   - Download all necessary modules
   - Configure the master node
   - Set up all worker nodes
   - Distribute modules across the cluster
   - Automatically reboot the cluster

3. After reboot, the system starts automatically!

## Usage

### Interactive Mode
The cluster starts in interactive mode by default:

```
User> Hello!
SuperAI: Hi there! How can I help you today?
[greeting | sentiment: 0.85]

User> What is machine learning?
SuperAI: Machine learning is a type of artificial intelligence...
[question | sentiment: 0.00]

User> status
Cluster Status:
Master ID: 0
Total Modules: 40
  neural: READY (3 modules)
  language: READY (4 modules)
  learning: READY (9 modules)
  memory: READY (3 modules)
  personality: READY (3 modules)
  generation: READY (5 modules)
  knowledge: READY (2 modules)
  code: READY (1 modules)
  context: READY (1 modules)
  advanced: READY (3 modules)
```

### Commands
- `status` - Show cluster status
- `name <name>` - Set your username
- `quit` or `exit` - Shutdown cluster

## How It Works

### Input Processing
1. User input goes to master orchestrator
2. Master distributes tasks to appropriate workers:
   - Language worker analyzes text
   - Memory worker retrieves user context
   - Context worker processes conversation flow

### Response Generation
1. Master determines intent
2. Routes to specialized workers:
   - Knowledge worker for questions
   - Code worker for programming requests
   - Generation worker for conversational responses
3. Memory worker records interaction
4. Personality worker updates mood

### Learning
1. Feedback distributed across relevant workers
2. Neural worker updates neural networks
3. Learning worker updates ML models
4. Advanced worker applies RLHF

## API

### For Developers

```lua
local cluster = require("superai_cluster")

-- Initialize cluster
cluster.init()

-- Process input
local results = cluster.processInput("Hello!", "Alice")

-- Generate response
local response = cluster.generateResponse("Hello!", "Alice", results)

-- Learn from feedback
cluster.learn(input, feedback)

-- Get status
local status = cluster.getStatus()

-- Shutdown
cluster.shutdown()
```

## Advantages Over RAID System

1. **No Drive Dependencies**: Works with any number of computers
2. **Better Scalability**: Add workers to increase capacity
3. **Fault Tolerance**: Individual worker failure doesn't crash system
4. **Resource Efficiency**: Each module runs where needed, not duplicated
5. **Easier Setup**: No complex drive mapping required

## Comparison

| Feature | RAID System | Cluster System |
|---------|-------------|----------------|
| Drives Required | 11 | 1+ |
| Scalability | Limited | Unlimited |
| Fault Tolerance | Low | High |
| Module Distribution | Manual | Automatic |
| Setup Complexity | High | Low |
| Performance | Single computer | Distributed |

## Troubleshooting

### Worker Not Ready
- Check that worker computer is on
- Verify disk is attached to worker
- Ensure modem is present for networking
- Check that modules copied successfully

### Timeout Errors
- Increase timeout in `cluster.dispatch()` calls
- Check network connectivity between computers
- Verify worker is not overloaded

### Module Not Loading
- Ensure module exists on worker disk
- Check syntax errors in module
- Verify module dependencies are available

## Future Enhancements

- Dynamic worker reassignment
- Load balancing across workers
- Distributed training coordination
- Redundant workers for fault tolerance
- Web interface for monitoring

## Credits

Built on the SuperAI framework by ChronicallyGrim
Enhanced cluster architecture implements distributed AI computing

---

For questions or issues, visit: https://github.com/ChronicallyGrim/SuperAI
