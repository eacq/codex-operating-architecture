# Parent Skill Refinement Contract

Use parent-skill refinement when a broad owner is still correct but its
`SKILL.md` has become a dense controller document. The goal is to make the
parent skill a small routing surface while preserving every verified safety
boundary.

## When To Use

- The parent has multiple long modes, gates, recovery paths, or release
  commands.
- The modes share the same top-level trigger, artifacts, maintained knowledge,
  and safety boundary.
- A new top-level skill would duplicate discovery metadata or split ownership
  without evidence.
- The parent can point to internal subskills without weakening required
  validation.

## Parent Keeps

- YAML name and broad trigger description.
- Canonical ownership statement.
- Task routing order.
- Non-negotiable safety and confirmation boundaries.
- Acceptance criteria and required validation summary.

## Move Into Subskills

- Long procedural gates.
- Failure recovery flows.
- Release or synchronization command routing.
- Specialized mode contracts.
- Detailed handoffs, examples, and tests.

## Rules

1. The parent `SKILL.md` remains the only public discovery surface.
2. Subskills must not create a separate registry entry unless later evidence
   proves an independent owner boundary.
3. Every moved section must leave a direct parent link, so an agent can find the
   contract before acting.
4. Do not compress away safety checks, rollback conditions, credential
   boundaries, public/private release distinctions, or validation commands.
5. Split by invocation only when the new capability needs its own autonomous
   trigger or another skill must reach it. Otherwise keep it user-routed,
   internal, or reference-only to avoid extra context load.
6. Split by sequence when later steps cause premature completion of the current
   step. First sharpen the current step's completion criterion; split only when
   the remaining sequence still distracts from the required legwork.
7. Put material on the lowest reliable information tier: parent route,
   in-skill step, in-skill reference, linked reference, or subskill. Keep
   branch-specific detail behind a clear pointer, but keep required completion
   criteria inline with the step they govern.
8. During pruning, remove duplicate meaning, stale sediment, no-op guidance,
   and avoidable negation. Prefer a positive target behavior plus an observable
   check over a broad prohibition.
9. For an external skill, choose the least invasive compatible installation
   form: learn-only note, owner reference, owner-internal subskill,
   project-local skill, or global skill. The choice must state why the skill is
   necessary, what value it adds beyond existing owners, how it was adapted to
   local safety/profile/validation rules, and how to remove or revise it later.
10. Record the economy decision in `module-registry.json`, project workflows or
   experience, and linked knowledge when durable behavior changes.

## Verification

- Run quick validation on the parent skill.
- Run relevant subskill script tests.
- Run full repository validation twice for architecture changes.
- Run global-interface validation when canonical skill routing changed.
- Run the complete global experience iteration for self-hosting architecture
  changes.
