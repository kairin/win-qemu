# Tailwind CSS v4 Rules (MANDATORY)

> These rules MUST be followed for all CSS and component development in docs-astro/.

## Version Requirements

- Tailwind CSS: v4.1+ (currently 4.1.17)
- DaisyUI: v5.5+ (currently 5.5.5)
- @tailwindcss/vite plugin

---

## Spacing & Layout

### Use `gap-*` instead of `space-x-*` or `space-y-*`

```html
<!-- CORRECT -->
<div class="flex gap-4">

<!-- WRONG -->
<div class="flex space-x-4">
```

### Use `min-h-dvh` instead of `min-h-screen`

```html
<!-- CORRECT -->
<body class="min-h-dvh">

<!-- WRONG -->
<body class="min-h-screen">
```

### Use `size-*` for equal width/height

```html
<!-- CORRECT -->
<div class="size-10">

<!-- WRONG -->
<div class="w-10 h-10">
```

---

## Colors & Opacity

### Use opacity modifiers

```html
<!-- CORRECT -->
<div class="bg-black/50">
<div class="text-white/80">

<!-- WRONG -->
<div class="bg-black bg-opacity-50">
```

### Use `bg-linear-*` instead of `bg-gradient-*`

```html
<!-- CORRECT -->
<div class="bg-linear-to-r from-purple-500 to-blue-500">

<!-- WRONG -->
<div class="bg-gradient-to-r from-purple-500 to-blue-500">
```

---

## Typography

### Use line-height modifiers

```html
<!-- CORRECT -->
<p class="text-base/7">
<h1 class="text-4xl/tight">

<!-- WRONG -->
<p class="text-base leading-7">
```

### Use `text-wrap-balance` for headings

```html
<!-- CORRECT -->
<h1 class="text-wrap-balance">Long heading text</h1>
```

---

## Shadows & Borders

### Shadow naming changes in v4

| v3 (OLD) | v4 (NEW) |
|----------|----------|
| `shadow-sm` | `shadow-xs` |
| `shadow` | `shadow-sm` |
| `rounded` | `rounded-sm` |

```html
<!-- CORRECT (v4) -->
<div class="shadow-sm rounded-sm">

<!-- WRONG (v3 names) -->
<div class="shadow rounded">
```

---

## Prohibited Utilities

### NEVER use `@apply`

```css
/* WRONG */
.btn {
  @apply px-4 py-2 bg-blue-500;
}

/* CORRECT - use utility classes directly in HTML */
<button class="px-4 py-2 bg-blue-500">
```

### NEVER use these deprecated utilities

| Deprecated | Use Instead |
|------------|-------------|
| `space-x-*` | `gap-*` |
| `space-y-*` | `gap-*` |
| `bg-gradient-*` | `bg-linear-*` |
| `min-h-screen` | `min-h-dvh` |
| `bg-opacity-*` | `bg-color/opacity` |

---

## DaisyUI Integration

### Semantic Colors

Use DaisyUI semantic color names:

```html
<button class="btn btn-primary">Primary</button>
<div class="bg-base-100 text-base-content">Content</div>
<span class="text-accent">Accent text</span>
```

### Components

Use DaisyUI component classes:

```html
<button class="btn">Button</button>
<div class="card">Card</div>
<span class="badge">Badge</span>
<div class="alert">Alert</div>
<dialog class="modal">Modal</dialog>
```

### Themes

Use data-theme attribute:

```html
<!-- Dark theme -->
<html data-theme="nightowl">

<!-- Light theme -->
<html data-theme="sunrise">
```

---

## Win-QEMU Specific Themes

### nightowl (Dark - Default)

```css
[data-theme="nightowl"] {
  --p: oklch(0.75 0.18 280);   /* Primary: Vibrant purple */
  --s: oklch(0.70 0.15 200);   /* Secondary: Teal blue */
  --a: oklch(0.80 0.20 320);   /* Accent: Pink/magenta */
  --b1: oklch(0.15 0.05 280);  /* Base: Deep purple-black */
}
```

### sunrise (Light)

```css
[data-theme="sunrise"] {
  --p: oklch(0.60 0.20 30);    /* Primary: Warm orange */
  --s: oklch(0.55 0.15 150);   /* Secondary: Fresh green */
  --a: oklch(0.70 0.18 45);    /* Accent: Golden yellow */
  --b1: oklch(0.98 0.01 90);   /* Base: Cream white */
}
```

---

## Quick Reference Card

| Task | Use |
|------|-----|
| Flex/grid spacing | `gap-4` |
| Full viewport height | `min-h-dvh` |
| Square element | `size-10` |
| Semi-transparent | `bg-black/50` |
| Gradient | `bg-linear-to-r` |
| Line height | `text-base/7` |
| Heading wrap | `text-wrap-balance` |
| Small shadow | `shadow-xs` |
| Default shadow | `shadow-sm` |
| Small radius | `rounded-sm` |

---

## Enforcement

Agent **012-astro** and its children will validate Tailwind CSS compliance during builds. Non-compliant code should be flagged and corrected.
