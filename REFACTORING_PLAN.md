# Hålet Game Refactoring Plan

## Project Overview
This document outlines the refactoring plan for the "Hålet" hole-growing game. The goal is to improve code organization, maintainability, and reduce technical debt while avoiding over-engineering for a small commercial web game.

**Current Performance**: 3k FPS with 100k particles (excellent, no optimization needed)
**Target Platforms**: Armor Games, Crazy Games (web-focused)

---

## Refactoring Strategy: Phased Approach

### Phase 1: Foundation Cleanup (Week 1-2)
*High impact, low risk - immediate quality improvements*

#### ✅ 1.1 Extract Constants and Configuration
**Status**: ⏳ TODO  
**Files to Create**: `src/config/GameConfig.odin`  
**Files to Modify**: `game.odin`, `GameLoop.odin`, `Hole.odin`, `Objects.odin`, `Node.odin`, `SkillTree.odin`

**Tasks**:
- [ ] Create GameConfig struct with all magic numbers
- [ ] Extract CAP :: 10_000
- [ ] Extract spawn_rate = 0.5
- [ ] Extract evaporation_rate = 0.33
- [ ] Extract growth_rate = 0.25
- [ ] Extract reach_radius values
- [ ] Extract UI scaling factors (0.1, 0.05, 0.15, etc.)
- [ ] Extract rendering constants (0.2, 1.0, etc.)
- [ ] Update all files to use GameConfig constants
- [ ] Test game functionality after migration

**Constants to Extract**:
```odin
GameConfig :: struct {
    // Entity limits
    MAX_ENTITIES: int = 10_000,
    
    // Spawning
    DEFAULT_SPAWN_RATE: f32 = 0.5,
    OBJECT_INITIAL_AMOUNT_MULTIPLIER: f32 = 0.1,
    MID_SPAWN_SIZE_FACTOR: f32 = 0.15,
    
    // Hole properties
    HOLE_EVAPORATION_RATE: f32 = 0.33,
    HOLE_GROWTH_RATE: f64 = 0.25,
    HOLE_START_SIZE: f32 = 20.0,
    HOLE_MAX_SIZE: f32 = 1000.0,
    HOLE_REACH_RADIUS_MULTIPLIER: f32 = 2.0,
    HOLE_MIN_SIZE: f32 = 2.0,
    HOLE_VISUAL_RADIUS_MULTIPLIER: f32 = 0.2,
    
    // Physics
    DEFAULT_DAMPING: f32 = 100.0,
    HOLE_DAMPING: f32 = 1000.0,
    MAX_GROWTH_PER_FRAME_MULTIPLIER: f32 = 0.025,
    
    // UI
    BUTTON_WIDTH_PERCENT: f32 = 0.1,
    BUTTON_HEIGHT_PERCENT: f32 = 0.05,
    RESOURCE_FRAME_X_PERCENT: f32 = 0.90,
    FONT_SPACING: f32 = 1.0,
    TOOL_TIP_SIZE_MULTIPLIER: f32 = 1.15,
    
    // Rendering
    DEFAULT_ZOOM: f32 = 1.0,
    TEXTURE_SCALE_FACTOR: f32 = 2.0,
    DUAL_GLOW_INNER_RADIUS: f32 = 0.2,
    
    // Skill defaults
    DEFAULT_SKILL_FLOAT: f32 = 1.0,
    DEFAULT_SKILL_VALUE: f32 = 0.5,
}
```

#### ✅ 1.3 Extract Physics Utilities
**Status**: ⏳ TODO  
**Files to Create**: `src/physics/Physics.odin`  
**Files to Modify**: `Objects.odin`, `Hole.odin`

**Tasks**:
- [ ] Create physics utility functions
- [ ] Extract common physics integration code
- [ ] Extract force application patterns
- [ ] Extract boundary collision logic
- [ ] Update Objects and Hole systems to use physics utilities
- [ ] Test physics behavior remains identical

**Physics Functions to Extract**:
```odin
// src/physics/Physics.odin
physics_apply_forces :: proc(positions: []c.Position, physics: []c.Physics, dt: f32)
physics_integrate_entity :: proc(pos: ^c.Position, phys: ^c.Physics, dt: f32)
physics_apply_damping :: proc(phys: ^c.Physics, damping: f32, dt: f32)
physics_boundary_collision :: proc(pos: ^c.Position, phys: ^c.Physics, screen_width, screen_height: f32)
```

---

### Phase 2: System Separation (Week 3-4)
*Medium impact, medium risk - architectural improvements*

#### ✅ 2.2 System Functions (Data-Oriented)
**Status**: ⏳ TODO  
**Files to Create**: `src/systems/MovementSystem.odin`, `src/systems/CollisionSystem.odin`, `src/systems/SpawnSystem.odin`  
**Files to Modify**: `GameLoop.odin`

**Tasks**:
- [ ] Create MovementSystem with physics integration
- [ ] Create CollisionSystem with hole-object and hole-hole collision
- [ ] Create SpawnSystem with object spawning logic
- [ ] Extract gameloop_update logic into system functions
- [ ] Update GameLoop to call system functions
- [ ] Test game behavior remains identical

**System Functions to Create**:
```odin
// src/systems/MovementSystem.odin
movement_system_update :: proc(dt: f32)

// src/systems/CollisionSystem.odin  
collision_system_update :: proc(dt: f32)

// src/systems/SpawnSystem.odin
spawn_system_update :: proc(dt: f32)
```

#### ✅ 2.3 Refactor GameLoop into Systems
**Status**: ⏳ TODO  
**Files to Modify**: `GameLoop.odin`

**Tasks**:
- [ ] Split gameloop_update into focused system calls
- [ ] Move hole physics to MovementSystem
- [ ] Move collision detection to CollisionSystem
- [ ] Move object spawning to SpawnSystem
- [ ] Clean up gameloop_update to orchestrate systems
- [ ] Test all game mechanics work correctly

#### ✅ 2.4 Event System
**Status**: ⏳ TODO  
**Files to Create**: `src/events/EventBus.odin`, `src/events/Events.odin`  
**Files to Modify**: `GameLoop.odin`, `Hole.odin`, `Objects.odin`

**Tasks**:
- [ ] Create Event union types
- [ ] Create EventBus with dispatch/listen functionality
- [ ] Replace direct function calls with events where appropriate
- [ ] Add CollisionEvent for hole-object collisions
- [ ] Add ResourceEvent for resource collection
- [ ] Add HoleEvent for hole-hole interactions
- [ ] Update systems to use event communication
- [ ] Test event-driven behavior

**Event System Structure**:
```odin
// src/events/Events.odin
Event :: union {
    CollisionEvent,
    ResourceEvent,
    HoleEvent,
}

CollisionEvent :: struct {
    hole_index: int,
    object_index: int,
    position: c.Position,
}

ResourceEvent :: struct {
    resource_type: ResourceType,
    amount: int,
    hole_index: int,
}

HoleEvent :: struct {
    predator_index: int,
    prey_index: int,
    position: c.Position,
}

// src/events/EventBus.odin
EventType :: enum { COLLISION, RESOURCE, HOLE }

EventBus :: struct {
    listeners: map[EventType][]proc(Event),
}

event_bus_dispatch :: proc(event: Event)
event_bus_listen :: proc(event_type: EventType, callback: proc(Event))
```

---

### Phase 3: Selective Architecture (Week 5-6)
*Low priority, future-proofing*

#### ⏸️ 3.3 Input Management System
**Status**: ⏳ TODO (Future Need)  
**Files to Create**: `src/input/InputManager.odin`  
**Notes**: Approved but not needed yet. Implement when input complexity increases.

**Future Tasks**:
- [ ] Create input mapping system
- [ ] Add action-based input handling
- [ ] Support for key rebinding
- [ ] Integrate with existing input code

---

## Rejected Features (Documented for Future Reference)

### ❌ ECS Framework
- **Reason**: Current SOA approach is sufficient for small game
- **Alternative**: Keep manual SOA with system functions

### ❌ Screen Management System  
- **Reason**: Raylib provides adequate screen utilities
- **Alternative**: Continue using rl.GetRenderWidth/Height()

### ❌ Asset Management System
- **Reason**: Current texture array is simple and effective
- **Alternative**: Keep Textures.odin approach

### ❌ Rendering Pipeline
- **Reason**: Game is too simple for complex rendering
- **Alternative**: Keep current direct rendering approach

### ❌ Performance Optimizations
- **Reason**: Already achieving 3k FPS with 100k particles
- **Alternative**: Optimize only if performance issues arise

### ❌ Scene Management Overhaul
- **Reason**: Current scene system is adequate
- **Alternative**: Keep existing Scene struct approach

---

## Migration Strategy

### Step-by-Step Approach:
1. **Create new packages alongside existing code**
2. **Implement one feature at a time**
3. **Maintain backward compatibility during transition**
4. **Test each implementation thoroughly**
5. **Remove old code only after verification**

### Risk Mitigation:
- **Incremental changes** to avoid breaking the game
- **Comprehensive testing** after each phase
- **Rollback capability** by keeping old code until verification

---

## Progress Tracking

### Phase 1 Progress: [0/2] completed
- [ ] 1.1 Extract Constants and Configuration
- [ ] 1.3 Extract Physics Utilities

### Phase 2 Progress: [0/3] completed  
- [ ] 2.2 System Functions
- [ ] 2.3 Refactor GameLoop
- [ ] 2.4 Event System

### Phase 3 Progress: [0/1] completed
- [ ] 3.3 Input Management (Future)

### Overall Progress: [0/6] completed

---

## Testing Strategy

### After Each Phase:
- [ ] Verify game launches correctly
- [ ] Test hole movement and growth
- [ ] Test object spawning and collection
- [ ] Test hole-hole collisions
- [ ] Test skill tree functionality
- [ ] Verify performance remains acceptable
- [ ] Test hot reload functionality

### Acceptance Criteria:
- Game behavior identical to before refactoring
- Code organization improved
- No performance regressions
- Hot reload still works correctly

---

## Notes

### Current Architecture Strengths:
- Good data-oriented design with SOA arrays
- Excellent performance (3k FPS)
- Simple, focused scope
- Working hot reload system

### Key Pain Points to Address:
- Global state coupling (`g` pointer)
- Magic numbers scattered throughout code
- Mixed responsibilities in GameLoop
- Code duplication in physics
- Hardcoded values

### Success Metrics:
- Reduced code duplication
- Centralized configuration
- Cleaner system separation
- Maintained performance
- Easier maintenance and debugging