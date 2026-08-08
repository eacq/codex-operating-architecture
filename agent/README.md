# Global Experience Agent filesystem

`agent/` is the physical topology of the Global Experience Agent. The numbered zones follow the Agent lifecycle from identity and access, through delegated agents and resources, to runtime, evidence, exits, presentation, and maintenance.

The directory does not duplicate the 23 canonical Owner Skills. Generated specialist manifests under `20-agents/specialists/` point to their `skills/<owner>/SKILL.md` implementations. Behavior contracts remain authoritative in `config/`; the filesystem projection makes those contracts discoverable and mechanically verifiable.

Canonical execution starts at `40-runtime/Invoke-GlobalExperienceAgent.ps1`. The three same-named files under `scripts/` are forward-only compatibility adapters until the next major release.

Run `80-maintenance/Sync-AgentFilesystem.ps1 -Apply` after an authorized change to an Agent registry, interface, owner, resource, or exit. Run `80-maintenance/Test-AgentFilesystem.ps1` to reject projection drift. Use `80-maintenance/Resolve-AgentFilesystemPath.ps1 -List` or `-Id <typed-id>` instead of guessing paths. Human and LLM callers can obtain the same read-only projection through the root Agent operations `DescribeFilesystem` and `ResolveAgentPath`; neither operation grants structural write authority.

Private session state, credentials, caches, and raw history never belong in this tree. `90-local/` documents pointers to ignored local state; it does not contain that state.
