---
description: Complete Astro build and GitHub Pages deployment workflow - FULLY AUTOMATIC
---

## Purpose

Build the docs-astro/ Astro site and deploy to GitHub Pages with full validation.

**Prevents:** Blank page incidents (missing .nojekyll), broken deployments, asset 404s.

---

## Workflow

### Phase 1: Pre-Build Checks (Parallel)

**Agents:** 121-precheck, 121-config-check

Tasks:
1. Verify Astro project structure exists
2. Check package.json has required dependencies
3. Validate astro.config.mjs:
   - base: '/win-qemu/'
   - outDir: '../docs'
4. Ensure node_modules/ exists

**Failure Action:** Stop and report missing prerequisites.

---

### Phase 2: Build (Sequential)

**Agent:** 121-build

Tasks:
1. Execute `npm --prefix docs-astro run build`
2. Capture build output
3. Report any TypeScript or compilation errors

**Command:**
```bash
npm --prefix /home/kkk/Apps/win-qemu/docs-astro run build
```

**Failure Action:** Stop and report build errors.

---

### Phase 3: Post-Build Validation (Parallel)

**Agents:** 121-validate, 121-nojekyll, 121-metrics

Tasks:
1. **121-validate:** Verify all pages generated
   - index.html exists
   - _astro/ directory exists
   - All page directories exist

2. **121-nojekyll:** CRITICAL - Ensure .nojekyll exists
   - Check docs-astro/public/.nojekyll
   - Check docs/.nojekyll
   - Auto-create if missing

3. **121-metrics:** Calculate build metrics
   - Total size
   - File counts
   - Largest assets

**Failure Action:** If .nojekyll missing, create it. If validation fails, stop.

---

### Phase 4: Git Commit (Sequential)

**Agent:** 009-git (existing)

Tasks:
1. Create timestamped branch: `YYYYMMDD-HHMMSS-deploy-docs-astro`
2. Stage docs/ directory
3. Commit with message:
   ```
   deploy: Update documentation site

   - Built with Astro v5
   - [page count] pages generated
   - [size] total build size

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```
4. Push branch to origin
5. Merge to main with --no-ff
6. Push main

**Constitutional Compliance:** Branch preserved, never deleted.

---

### Phase 5: Deployment Verification (Parallel)

**Agents:** 122-asset-check, 122-url-test

Tasks:
1. Wait 30 seconds for GitHub Pages rebuild
2. **122-asset-check:** Test CSS file returns HTTP 200
   - URL: `https://kairin.github.io/win-qemu/_astro/*.css`
3. **122-url-test:** Test all page URLs return HTTP 200
   - Index, overview, installation, performance, security, changelog

**Success Criteria:** All tests return HTTP 200.

---

### Phase 6: Rollback (If Failed)

**Agent:** 122-rollback

Triggers:
- 122-deploy-verify fails
- 122-asset-check fails (CSS 404)
- 122-url-test fails (pages missing)

Actions:
1. Revert docs/ to previous commit
2. Alert user with failure reason
3. Suggest remediation steps

---

## Success Output

```json
{
  "status": "success",
  "build": {
    "pages": 6,
    "size_kb": 450,
    "time_ms": 2500
  },
  "deployment": {
    "branch": "20251130-140000-deploy-docs-astro",
    "commit": "abc123",
    "url": "https://kairin.github.io/win-qemu/"
  },
  "verification": {
    "css_status": 200,
    "pages_passed": 6,
    "nojekyll": true
  }
}
```

---

## Failure Recovery

| Failure Point | Recovery Action |
|---------------|-----------------|
| Pre-build | Run `npm install` |
| Build | Fix TypeScript errors |
| Validation | Check src/pages/ |
| .nojekyll | Auto-created |
| Git | Check branch conflicts |
| Deployment | Wait and retry |
| Asset 404 | Verify .nojekyll pushed |

---

## Related

- **Parent Agent:** 012-astro
- **Checklist:** deployment-checklist.md
- **Rules:** rules-tailwindcss/tailwind.md
