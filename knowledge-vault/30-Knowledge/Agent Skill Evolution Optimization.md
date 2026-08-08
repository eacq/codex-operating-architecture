---
id: concept-agent-skill-evolution-optimization
type: concept
status: active
source: user-provided private book shelf plus darwin-skill and SkillOpt method sources
verified: true
learning_audience: codex
codex_learning: Evolve one owner-internal skill candidate at a time through harvest, mine, compose, propose, score, gate, validate, adopt-or-revert, and consolidate; use book lenses as guarded review models rather than automatic authority.
---

# Agent Skill Evolution Optimization

## Source grounding

- Darwin Skill source: `https://github.com/alchaincyf/darwin-skill`, inspected at commit `7c7b7909b630dc3b5cbb91bd4bcb1b10bfb1f894`.
- SkillOpt source: `https://github.com/microsoft/SkillOpt`, inspected at commit `61735e3922efc2b90c6d6cab561e62e98452ca90`.
- Brian Arthur book source: user-provided local EPUB at `F:/codex/book/技术的本质：技术是什么，它是如何进化的（经典版） (［美］布莱恩•阿瑟曹东溟　王健译) (z-library.sk, 1lib.sk, z-lib.sk).epub`.
- Local adaptation: `skills/codex-experience-capture/subskills/skill-evolution-optimization/SKILL.md`.
- Book shelf scanner: `skills/codex-experience-capture/scripts/Invoke-ExperienceBookShelfLearning.ps1`.

## Local interpretation

The Global Experience Agent treats skill files as evolvable external memory,
but not as self-authorizing structure. A skill optimization pass may harvest
experience, propose a candidate, score current and candidate skill versions,
and adopt only strict improvements after safety and owner validation. The
Agent's entry, interface, permission, Git, release, installation, credential,
and architecture gates remain unchanged.

## Reusable pattern

- Darwin contributes the review loop: evaluate, improve, validate, human/owner
  checkpoint, keep or revert, and report.
- SkillOpt contributes the training loop: rollout, reflect, aggregate, select
  bounded update, validate, and keep current/best state by strict gate.
- SkillOpt-Sleep contributes offline consolidation: harvest memories, mine
  candidates, replay examples, consolidate proposals, and stage adoption for a
  later live gate.
- Brian Arthur's technology-evolution model contributes the Agent optimization
  lens: treat skills and runtime operations as reusable components; improve by
  recombining existing components before adding new ones; preserve recursive
  assembly boundaries; name the operational effect being captured; bind every
  candidate to a local domain and need; and record the new problems created by
  each solution.

## Arthur-to-Agent mapping

| Technology-evolution idea | Global Experience Agent adaptation |
| --- | --- |
| Technologies arise from combinations of prior technologies. | New Agent capability should first be composed from existing owners, subskills, scripts, policies, memory, and gates. |
| Technologies have recursive internal structure. | Every higher-level Agent assembly must expose its lower components and owner boundaries. |
| Technologies capture phenomena for purposes. | A skill change must name the operational effect it captures, such as strict improvement, stable retrieval, rollback, or trigger precision. |
| Domains provide shared grammar and components. | Each Agent capability must name its local domain, such as F-codex graph, Windows filesystem, Codex host, interface policy, or Git/release gate. |
| Solutions create new needs and problems. | Accepted Agent optimizations must record newly introduced validation, privacy, performance, routing, or rollback risks. |

## Boundaries

- Do not install upstream runtimes by default.
- Do not copy upstream account, provider, plugin, or platform assumptions.
- Do not optimize more than one primary `SKILL.md` per epoch unless a separate
  architecture-owner route authorizes a structural refactor.
- Do not call a candidate promoted until deterministic gate output and owner
  validation evidence both exist.
- Treat `F:/codex/book` as a local private source shelf for Agent reading. It is
  intentionally ignored by Git/release and should be cited by path plus parse
  statistics or derived notes, not copied into public artifacts.

## Book-shelf learning synthesis

The local shelf is treated as a set of complementary thinking models. The
current reusable Agent lenses are:

- technology evolution: compose from existing components, name captured effects,
  and expose recursive assemblies.
- complexity thinking: inspect feedback loops, emergent behavior, coordination
  cost, and second-order failures.
- fast and slow thinking: use fast intent heuristics only as routing; require
  slow validation before mutation.
- model thinking: compare multiple models before selecting an action or owner
  route.
- six thinking hats: separate fact, risk, value, alternative, process, and
  synthesis review roles for candidate evaluation.
- pyramid principle: deliver conclusions top-down while keeping evidence,
  caveats, and authority boundary inspectable.
- analogy and abstraction: use analogies to generate candidates, then validate
  their local Agent-domain fit.

PDF sources that cannot be text-parsed by the current runtime remain
metadata-only evidence. They can still contribute title-level lenses, but they
do not count as fully learned until a parser owner provides validated text
extraction.

## 2026-08-06 full shelf relearning

The private shelf was rescanned after the reverse-skill fusion. All 10 books
parsed successfully with 0 degraded books and 4,471,465 readable characters.
The derived evidence is stored at
`.runtime/evidence/experience-book-shelf-learning-20260806.json`; the
per-book lens table and guarded synthesis are stored in
`knowledge-vault/30-Knowledge/2026-08-06 全书架重新学习记录.md`.

This refresh confirms the cross-book combination: fast routing plus slow
deliberation, multi-model selection, separated review roles, evidence and
counterexample probes, analogy boundary checks, feedback/emergence review,
recursive capability recombination, and top-down delivery. These are review
lenses rather than automatic promotions; each future skill change still needs
local evidence, negative-trigger tests, transfer evidence, rollback, and the
responsible owner gate.

## Functional unit links

- Parent owner: `skills/codex-experience-capture/SKILL.md`
- Evolution contract: `skills/codex-experience-capture/subskills/skill-evolution-optimization/SKILL.md`
- Shelf reader: `skills/codex-experience-capture/scripts/Invoke-ExperienceBookShelfLearning.ps1` and `skills/codex-experience-capture/scripts/Invoke-ExperienceBookShelfLearning.py`
- Candidate gate: `skills/codex-experience-capture/scripts/Invoke-SkillEvolutionOptimizationGate.ps1`
- Tests: `skills/codex-experience-capture/scripts/Test-SkillEvolutionOptimization.ps1` and `skills/codex-experience-capture/scripts/Test-ExperienceBookShelfLearning.ps1`
- Structural review: `skills/codex-architecture-iteration/scripts/Invoke-UnitTopologyReview.ps1`
- Deep structural audit: `skills/codex-architecture-iteration/scripts/Invoke-DeepArchitectureAudit.ps1` and `skills/codex-architecture-iteration/scripts/Test-DeepArchitectureAudit.ps1`
- Speed-preserving execution versions: `config/loopx-resource-policy.json`, `skills/codex-self-evolution/subskills/resource-economy/SKILL.md`, and `skills/codex-self-evolution/subskills/resource-economy/Test-ResourceModePolicy.ps1`
- Related information units: [[2026-08-06 全书架重新学习记录]], [[Global Experience System]], [[Agent Memory System]], [[Information and Functional Unit Principle]], [[Learning Governance]]
