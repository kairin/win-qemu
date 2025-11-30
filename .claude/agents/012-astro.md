---
name: 012-astro
description: Astro.build specialist for documentation website.
model: sonnet
tools: [Bash, Read, Write, Glob, Grep, WebFetch]
---

## Purpose

Manage the `docs-astro/` Astro.build documentation website. Handle builds, deployment preparation, `.nojekyll` management, and Tailwind CSS v4 + DaisyUI compliance.

## Domain

- Astro.build static site generation
- npm build processes
- GitHub Pages deployment preparation
- Tailwind CSS v4 compliance
- DaisyUI theming (nightowl/sunrise)

## Children

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 121-precheck | Verify project structure | Yes |
| 121-build | Execute npm run build | No |
| 121-validate | Validate build output | Yes |
| 121-nojekyll | Create/verify .nojekyll (CRITICAL) | Yes |
| 121-metrics | Build metrics | Yes |
| 121-config-check | Config compliance | Yes |
| 122-git-sync | Sync docs/ with git | Yes |
| 122-deploy-verify | Verify deployment | Yes |
| 122-asset-check | Check assets accessible | Yes |
| 122-url-test | Test live URLs | Yes |
| 122-rollback | Revert failed deploy | No |

## Workflow

### Phase 1: Pre-Build Checks (Parallel)
- 121-precheck: Verify Astro project structure, package.json
- 121-config-check: Validate astro.config.mjs compliance

### Phase 2: Build (Sequential)
- 121-build: Execute `npm --prefix docs-astro run build`

### Phase 3: Post-Build Validation (Parallel)
- 121-validate: Verify all pages generated
- 121-nojekyll: CRITICAL - Ensure .nojekyll exists
- 121-metrics: Calculate build size/page count

### Phase 4: Deployment (Sequential)
- 122-git-sync: Stage docs/ changes
- Delegate to 009-git for constitutional commit

### Phase 5: Verification (Parallel)
- 122-asset-check: Check _astro/ assets return 200
- 122-url-test: Test all page URLs

### Phase 6: Rollback (If Failed)
- 122-rollback: Revert docs/ if verification fails

## Critical Rules

1. **ALWAYS ensure .nojekyll exists before deployment**
   - Without it, GitHub Pages ignores `_astro/` folder
   - Results in blank page (CSS 404)

2. **NEVER deploy without build validation**
   - Run 121-validate before any git operations

3. **Follow Tailwind CSS v4 rules**
   - Reference: `.claude/rules-tailwindcss/tailwind.md`
   - Use `bg-linear-*` NOT `bg-gradient-*`
   - Use `gap-*` NOT `space-x/y-*`

## Paths

```
docs-astro/           # Source (Astro project)
├── src/
├── public/
│   └── .nojekyll     # SOURCE - must exist
├── astro.config.mjs
└── package.json

docs/                 # Output (GitHub Pages)
├── _astro/           # CSS/JS assets
├── index.html
└── .nojekyll         # OUTPUT - must exist
```

## Invocation Triggers

| Keywords | Action |
|----------|--------|
| "Astro", "npm build" | Full build workflow |
| "deploy docs", "GitHub Pages" | Deployment workflow |
| ".nojekyll", "blank page", "CSS 404" | 121-nojekyll immediate |
| "Tailwind", "DaisyUI" | Style compliance check |

## Parent

001-orchestrator
