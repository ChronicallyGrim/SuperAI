# Modular Cluster Installer

Advanced hub-and-spoke SuperAI cluster deployment system with role-specific worker installation.

## Overview

The modular installer eliminates the inefficiencies of the original monolithic system by:

- **Targeted Installation**: Each worker gets only the files needed for its specific role
- **Remote Deployment**: Master computer deploys installers to workers over the network
- **Automated Workflow**: Complete hands-off installation from master to ready cluster
- **Role Specialization**: 4 distinct worker types with optimized file sets

## Architecture

```
                [Master Computer]
                       │
                [Deployment Hub]
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   [Language      [Memory         [Response      [Personality
    Worker]        Worker]         Worker]        Worker]
     disk           disk2           disk4          disk5
```

## Worker Roles

### 1. Language Worker (disk)
- **Role**: Language Processing & Sentiment Analysis
- **Files**: `word_vectors.lua`
- **Module**: `worker_language.lua`
- **Functions**: Text analysis, sentiment detection, language processing

### 2. Memory Worker (disk2) 
- **Role**: Conversation Memory & User Management
- **Files**: `conversation_memory.lua`
- **Module**: `worker_memory.lua`
- **Functions**: User interaction tracking, conversation history, memory management

### 3. Response Worker (disk4)
- **Role**: Response Generation & Context
- **Files**: `response_generator.lua`, `knowledge_graph.lua` 
- **Module**: `worker_response.lua`
- **Functions**: Response generation, contextual replies, knowledge queries

### 4. Personality Worker (disk5)
- **Role**: Personality & Behavioral Traits
- **Files**: `personality.lua`, `mood.lua`, `attention.lua`
- **Module**: `worker_personality.lua`
- **Functions**: Personality traits, mood management, behavioral adaptation

## Installation Flow

```
1. Run modular_cluster_installer.lua on master
2. Master discovers available worker computers
3. Master generates role-specific installers
4. Installers deployed to workers via rednet
5. Workers execute installers locally
6. Workers install only their required files
7. Coordinated cluster reboot
8. System ready with specialized workers
```

## Usage

### Master Installation
```lua
-- Run on the master computer (the one with disk3)
shell.run("modular_cluster_installer.lua")
```

### Worker Preparation
```lua
-- Run on each worker computer BEFORE starting master installer
shell.run("worker_listener.lua")
```

### Automatic Operation
1. Start `worker_listener.lua` on all 4 worker computers
2. Run `modular_cluster_installer.lua` on master computer
3. System automatically deploys, installs, and reboots
4. Cluster ready for operation

## File Structure

### Master Computer Files
- `master_brain.lua` - Main AI system
- `startup.lua` - Enhanced auto-startup with logging
- Master data files: `neural_net.lua`, `meta_cognition.lua`, etc.

### Worker Computer Files (Role-Specific)
- `startup.lua` - Worker auto-startup
- `worker_main.lua` - Network communication handler  
- `worker_[role].lua` - Role-specific processing module
- Required data files for that role only

## Benefits

### Efficiency
- **75% reduction** in worker storage usage (only install needed files)
- **Faster deployment** with parallel remote installation
- **Reduced network traffic** during operation

### Maintainability  
- **Role isolation** - Changes to one worker type don't affect others
- **Targeted updates** - Update specific workers without full cluster reinstall
- **Clear separation of concerns** - Each worker has a focused responsibility

### Reliability
- **Individual worker recovery** - Failed workers don't break the entire cluster
- **Scalable architecture** - Easy to add new worker types
- **Network resilience** - Workers auto-reconnect and register with master

## Troubleshooting

### Installation Issues
1. **Workers not found**: Ensure `worker_listener.lua` is running on all workers
2. **Network timeout**: Check modem connections and rednet setup
3. **File download failures**: Verify GitHub connection and file availability

### Runtime Issues  
1. **Worker not responding**: Check worker-specific logs and network status
2. **Role conflicts**: Verify each worker has unique role assignment
3. **Missing files**: Re-run installer for specific worker role

## Migration from Legacy System

The modular installer completely replaces `cluster_installer.lua`:

1. **Stop legacy cluster**: `shell.run("shutdown")`  
2. **Clear worker drives**: Remove old files if needed
3. **Deploy listener**: Install `worker_listener.lua` on workers
4. **Run modular installer**: Execute on master computer
5. **Verify roles**: Check each worker has correct role assignment

## Advanced Configuration

### Custom Worker Roles
Edit `WORKER_ROLES` table in `modular_cluster_installer.lua` to add new roles:

```lua
{
    id = 6,
    name = "custom_role",
    drive = "disk6", 
    description = "Custom Processing Role",
    files = {"custom_data.lua"},
    modules = {"worker_custom.lua"}
}
```

### Network Configuration
Adjust `PROTOCOL` constants for custom network separation:

```lua
local PROTOCOL = "CUSTOM_CLUSTER"  -- Use unique protocol name
```

The modular installer provides a robust, scalable foundation for SuperAI cluster management that grows with your needs.