# Learning notes

The owner's review document. Each entry covers what it is, how we use it, and an interview one-liner.

## Halo engine concepts

### Tags
- **What:** every asset and setting in Halo CE is a *tag*: a typed binary file (`.vehicle`, `.physics`, `.damage_effect`,
  `.scenario`…) edited in Guerilla. A built `.map` is a packed cache of all the tags the scenario references.
- **Here:** we use stock tags as-is, for authentic physics, and author only our own scenario, BSP and scripts.
- **One-liner:** "Halo CE is data-driven; gameplay is tag configuration plus a scripting layer. So 'authentic physics'
  became a checkable property: hashes of unmodified stock tags."

### Scenario and BSP
- **What:** the BSP (`.scenario_structure_bsp`) is the static level geometry and collision, compiled from JMS. The *scenario* is
  everything placed in that world: spawns, vehicles, scenery, trigger volumes, cutscene flags and scripts.
- **Frontend analogy:** the BSP is the static layout; the scenario is a component tree of named instances.

### HaloScript
- **What:** a small Lisp-like language that the engine runs at 30 ticks per second. `continuous` scripts run every tick;
  `sleep_until` polls a condition. There are no events or callbacks.
- **Limits that shape our design:** no coordinate readout, no velocity setter, no file I/O. Objects can only be (re)created
  if they were pre-placed and named.
- **One-liner:** "I designed the challenge logic as polled state machines over trigger volumes, because the scripting layer
  has no event system."
