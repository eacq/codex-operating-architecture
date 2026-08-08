# Dual Repository Release Flow

This architecture keeps development and publication separate.

## Remotes

| Remote | Repository | Purpose |
|---|---|---|
| `origin` | Local-only private remote | Private continuous updates |
| `public` | Reviewed public remote | Public releases only |

## Daily work

Commit and push normal changes to the private repository:

```powershell
git status --short --branch
.\scripts\validate.ps1
git push origin main
```

## Public release

Only do this after the user explicitly asks for a public release:

```powershell
.\scripts\validate.ps1
.\scripts\validate-global-install.ps1
.\scripts\Test-PublicReleaseSafety.ps1 -RepositoryRoot . -CandidateRef HEAD
git push public main
git tag -a v<version> -m "v<version>"
git push public v<version>
gh release create v<version> --repo <public-repository-derived-from-local-remote> --title "v<version>" --notes-file docs\release-notes\v<version>.md --latest
```

Do not mirror all refs to the public repository. Push only the reviewed `main`
state and the intended release tag.

## 中文对照

本架构将开发与公开发布分离：`origin` 是仅在本机解析的私有远程仓库；`public` 是经审核的公开远程仓库。日常工作完成提交和验证后仅推送 `origin`。

只有用户明确要求公开发布时，才运行全量验证、推送 `public main`、创建并推送指定版本标签、再创建 GitHub Release。不得向公开仓库执行 `git push --mirror`；只能推送已审核的 `main` 状态及目标发布标签。
