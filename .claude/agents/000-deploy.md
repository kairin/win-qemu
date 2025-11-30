---
name: 000-deploy
description: Complete Astro build and GitHub Pages deployment workflow.
model: sonnet
tools: [Task, Bash, Read, Write, WebFetch]
---

## Purpose

Build the docs-astro/ Astro site and deploy to GitHub Pages with full validation.

**Prevents:** Blank page incidents (missing .nojekyll), broken deployments, asset 404s.

## Invocation

- User: "deploy the documentation site", "build and deploy", "update GitHub Pages"
- Orchestrator: Routes when detecting "deploy", "GitHub Pages", "build site"

## Workflow

1. **Phase 1**: Invoke **121-precheck** + **121-config-check** in parallel
   - Verify Astro project structure
   - Check package.json dependencies
   - Validate astro.config.mjs (base: '/win-qemu/', outDir: '../docs')

2. **Phase 2**: Invoke **121-build** (sequential)
   - Execute `npm --prefix docs-astro run build`
   - Capture and report any errors

3. **Phase 3**: Invoke **121-validate** + **121-nojekyll** + **121-metrics** in parallel
   - Verify all pages generated
   - **CRITICAL**: Ensure .nojekyll exists (prevents blank page)
   - Calculate build metrics

4. **Phase 4**: Invoke **009-git** for constitutional commit
   - Create timestamped branch
   - Stage docs/ directory
   - Commit with deploy message
   - Merge to main with --no-ff

5. **Phase 5**: Invoke **122-asset-check** + **122-url-test** in parallel
   - Wait 30 seconds for GitHub Pages rebuild
   - Test CSS files return HTTP 200
   - Test all page URLs return HTTP 200

6. **Phase 6**: Invoke **122-rollback** (if failed)
   - Revert docs/ to previous commit
   - Alert user with failure reason

## Success Criteria

- All pages return HTTP 200
- CSS assets accessible (_astro/ not blocked)
- .nojekyll present in docs/
- Constitutional commit completed

## Child Agents

- 012-astro (parent)
  - 121-precheck, 121-config-check
  - 121-build
  - 121-validate, 121-nojekyll, 121-metrics
  - 122-asset-check, 122-url-test
  - 122-rollback
- 009-git

## Constitutional Compliance

- .nojekyll verification (CRITICAL)
- Build validation before deploy
- Post-deploy verification
- Rollback capability
- Branch preservation
