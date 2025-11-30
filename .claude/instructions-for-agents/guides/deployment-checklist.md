# GitHub Pages Deployment Checklist (15 items)

> Use this checklist before and after every documentation deployment.

---

## Pre-Deployment (5 items)

### Source Configuration

- [ ] **1. `.nojekyll` exists in `docs-astro/public/`**
  - Agent: 121-nojekyll
  - Why: Copied to output during build
  - Auto-fix: Yes

- [ ] **2. `astro.config.mjs` base path is `/win-qemu/`**
  - Agent: 121-config-check
  - Why: Assets won't load with wrong base path
  - Auto-fix: No

- [ ] **3. Build output directory is `../docs`**
  - Agent: 121-config-check
  - Why: GitHub Pages serves from /docs
  - Auto-fix: No

- [ ] **4. All dependencies installed**
  - Agent: 121-precheck
  - Command: `npm --prefix docs-astro install`
  - Auto-fix: Yes (run npm install)

- [ ] **5. No TypeScript errors**
  - Agent: 121-build
  - Command: `npm --prefix docs-astro run build`
  - Auto-fix: No

---

## Build Verification (5 items)

### Output Validation

- [ ] **6. `.nojekyll` exists in `docs/`**
  - Agent: 121-nojekyll
  - Why: CRITICAL - prevents blank page
  - Auto-fix: Yes

- [ ] **7. `index.html` exists at `docs/index.html`**
  - Agent: 121-validate
  - Why: Landing page must exist
  - Auto-fix: No (rebuild required)

- [ ] **8. `_astro/` directory exists with CSS/JS**
  - Agent: 121-validate
  - Why: All styles and scripts live here
  - Auto-fix: No (rebuild required)

- [ ] **9. All page directories exist**
  - Agent: 121-validate
  - Pages: overview/, installation/, performance/, security/, changelog/
  - Auto-fix: No (check src/pages/)

- [ ] **10. No broken asset references**
  - Agent: 121-validate
  - Check: Grep HTML for 404-prone paths
  - Auto-fix: No

---

## Post-Deployment (5 items)

### Live Site Verification

- [ ] **11. Site loads at https://kairin.github.io/win-qemu/**
  - Agent: 122-deploy-verify
  - Expected: HTTP 200
  - Wait: 30 seconds after push

- [ ] **12. CSS styles render correctly**
  - Agent: 122-asset-check
  - Test: `_astro/*.css` returns 200
  - Failure indicator: Blank page

- [ ] **13. All navigation links work**
  - Agent: 122-url-test
  - Test: All 6 pages return 200
  - Auto-fix: No

- [ ] **14. No 404 errors in browser console**
  - Manual check
  - Open DevTools → Network → filter 4xx
  - Common issues: Wrong base path, missing .nojekyll

- [ ] **15. OG image loads for social sharing**
  - Test URL: https://kairin.github.io/win-qemu/og-image.png
  - Why: Social media previews
  - Agent: 122-asset-check

---

## Quick Diagnosis

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Blank page | Missing .nojekyll | Run 121-nojekyll |
| CSS 404 | .nojekyll not deployed | Push .nojekyll, wait 30s |
| Wrong links | Wrong base path | Check astro.config.mjs |
| Page 404 | Page not built | Check src/pages/ |
| Images 404 | Wrong public/ path | Check asset paths |

---

## Agent Coverage

| Checklist Item | Agent | Auto-Fix |
|----------------|-------|----------|
| 1, 6 | 121-nojekyll | Yes |
| 2, 3 | 121-config-check | No |
| 4 | 121-precheck | Yes |
| 5, 7, 8, 9, 10 | 121-build, 121-validate | No |
| 11 | 122-deploy-verify | No |
| 12, 15 | 122-asset-check | No |
| 13 | 122-url-test | No |
| 14 | Manual | - |

---

## Related Commands

- `/guardian-deploy` - Full automated deployment workflow
- `/guardian-documentation` - Documentation integrity check
