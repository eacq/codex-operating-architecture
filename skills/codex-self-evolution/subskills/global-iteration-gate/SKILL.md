---
name: codex-self-evolution-global-iteration-gate
description: Owner-internal subskill for complete global experience iterations, rollback readiness, replacement validation, and lifecycle writeback.
---

# Global Iteration Gate

Use this subskill only through the parent `codex-self-evolution` owner.

## Trigger

Run for a complete verified global architecture iteration, a self-hosting
experience-system refresh, or any pre-publication proof that must validate the
active repository and global interfaces.

## Contract

Before starting the transaction, record the outcome-directed iteration contract:
the target collaboration result, measurable acceptance evidence, affected
roles/handoffs, resource and authority boundaries, and no-regression checks.
Do not run a complete replacement merely to create activity; if the contract
cannot show a concrete system-level improvement, retain the active architecture
and close as an evidence review.

A global iteration uses the isolated full-scope transaction:

1. Copy the architecture into an isolated sandbox.
2. Back up the sandbox baseline.
3. Organize eligible files and repair references.
4. Restore canonical Git layout.
5. Validate the sandbox.
6. Validate sandbox global interfaces.
7. Quarantine and delete only proven disposable sandbox artifacts.
8. Create an exact tracked/untracked rollback snapshot before replacement.
9. Replace only after all checks pass.
10. Quarantine and delete only proven disposable active artifacts.
11. Validate the replaced active system twice.
12. Remove validation-regenerated disposable artifacts.
13. Refresh and validate real global interfaces.
14. Write lifecycle state and iteration proof.
15. Generate the current candidate report through
    `codex-experience-capture/scripts/New-GlobalIterationCandidateReport.ps1`
    and present its decision-ready summary to the user.

When the request is a complete **global experience-system** pass or includes
authorized candidate processing, enter through
`scripts/Invoke-CompleteGlobalExperienceIteration.ps1 -Apply`. That outer
controller consumes the active candidate-processing authorization and records
the cross-owner evidence before invoking the isolated replacement transaction.
Use `Invoke-IsolatedGlobalExperienceIteration.ps1` directly only for the
replacement/rollback transaction itself or its focused diagnosis; it does not
consume candidate authorization.

For candidate-record processing with no tracked, staged, or untracked
repository changes, the outer controller may use
`Invoke-CompleteGlobalExperienceIteration.ps1 -CandidateOnly -Apply`. This fast
path archives authorized local candidates, regenerates the advisory report,
runs candidate-processing validation and global-interface validation, and
records timing telemetry without replacing the active tree. It never satisfies
the Git publication gate; any commit, release, owner change, skill/script/docs
change, or repository artifact change still requires the complete replacement
proof.

Rollback readiness is mandatory. A post-replacement failure must restore and
verify the exact pre-iteration state, record the error, repair the owning
workflow, and rerun from the beginning. Rollback failure blocks mutation and Git
work.

## Runtime Budget

The complete transaction can outlast an interactive command window. Run one
controller through a resumable wait path, keep all other writers out of its
working surface, and inspect lifecycle state plus proof before deciding that a
caller timeout is a workflow failure. Do not start a duplicate iteration merely
because its caller stopped waiting. If interruption occurs before an exact
snapshot completes, verify that replacement never started; if it occurs after
the snapshot, restore and hash-verify before a clean rerun.

## Continuous Diagnosis

When failures are being used to test or debug file organization or complete
global iteration behavior, enter `scripts/Invoke-ContinuousIterationDiagnosis.ps1`
or `Invoke-IsolatedGlobalExperienceIteration.ps1 -ContinuousDiagnosis`. The mode
repeats owner probe, evidence capture, explicit safe repair, and full owner
probe until success. `MaxRepairAttempts 0` removes an arbitrary count, not
safety boundaries.

Stop on rollback failure, unsafe authority boundary, failed explicit repair, or
out-of-owner failure. Never guess a code repair inside the controller or reuse a
partially successful iteration as the next probe.

## Verification

The proof must show rollback-ready, cleaned, replaced, twice-revalidated,
interface-validated, lifecycle-written success. Publication gates consume this
proof and must never reorganize or delete from the active repository.
Candidate-only proof is local lifecycle evidence only and is rejected by the
publication gate.

The candidate report is an advisory post-iteration artifact. It aggregates
project experience, ledger, linked-knowledge, workflow-learning, and candidate
error-feedback entries with source, evidence, suggested decision, and authority
boundary. It never auto-promotes, installs, updates, configures, publishes, or
deletes a candidate.
