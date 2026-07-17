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

Rollback readiness is mandatory. A post-replacement failure must restore and
verify the exact pre-iteration state, record the error, repair the owning
workflow, and rerun from the beginning. Rollback failure blocks mutation and Git
work.

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
