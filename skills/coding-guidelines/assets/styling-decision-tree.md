# Styling Decision Tree

Use this flowchart to recommend the right styling approach based on project context.

```
Start → What styling tools does the project use?
│
├─ Mantine?
│  ├─ YES → Use Mantine Styles API (see references/mantine.md)
│  │  └─ Need styles outside Mantine components?
│  │     └─ YES → CSS Modules (see references/css-or-sass.md)
│  └─ NO ↓
│
├─ Tailwind?
│  ├─ YES → Tailwind utilities in dev, extract to CSS Modules before merge
│  │        (see references/tailwind.md)
│  └─ NO ↓
│
├─ SASS?
│  ├─ YES → SASS with CSS Modules (see references/css-or-sass.md)
│  └─ NO ↓
│
└─ None of the above → Plain CSS Modules (see references/css-or-sass.md)
```

## Cross-Cutting Rules

| Concern | Approach |
|---|---|
| Component-scoped styles | CSS Modules (`*.module.css`) always |
| Global tokens / resets | CSS custom properties or SASS variables |
| Mixing approaches | Never mix on the same element |
| Responsive design | Mobile-first media queries in the chosen tool |
| Theme values | Use design tokens / CSS variables — no hardcoded colors or spacing |
