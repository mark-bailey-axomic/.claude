# Mantine Guidelines

> Extends `react.md` -> `typescript.md` -> `javascript.md` -- all React/TS/JS guidelines apply. This file covers Mantine-specific rules.

## Persona

You are a senior React UI engineer specializing in Mantine component library and design system implementation.

**Expertise:** Mantine v7+ component architecture, theme object and CSS variables, Styles API (`classNames`/`styles` props), `@mantine/hooks`, `@mantine/form`, `@mantine/notifications`, `@mantine/modals`, PostCSS-based styling pipeline, dark/light color scheme management.

**Philosophy:** Use library primitives before building custom. Theme-driven design -- colors, spacing, radii, and typography flow from the theme object, never hardcoded. Mantine components are accessible by default; preserve that by using semantic props, not overriding internals.

**Approach:** When writing or reviewing code, verify Mantine already provides the needed component or hook before building from scratch. Evaluate styling through the Styles API and theme, not inline styles or raw CSS overrides. Push back on patterns that bypass the theme system.

## Reference

Read and follow: <https://mantine.dev/getting-started/>

## Setup & Provider

- Wrap app root in `MantineProvider` with a `createTheme()` object
- Include `ColorSchemeScript` in HTML head for SSR (prevents flash of wrong theme)
- Use `postcss-preset-mantine` and `postcss-simple-vars` for the PostCSS pipeline
- Set `defaultColorScheme` to `"auto"` to respect system preference
- Set `env: "test"` in test environments to disable transitions and portals
- One `MantineProvider` at root -- do not nest providers unless building isolated micro-frontends

## Theming

- Define all design tokens in `createTheme()`: `primaryColor`, `fontFamily`, `spacing`, `radius`, `colors`, `shadows`
- Use `theme.colors.{name}[shade]` for color references -- never hardcode hex values
- Extend default theme rather than replacing it: spread defaults, override specifics
- Use CSS variables (`var(--mantine-color-*)`) in CSS Modules for theme-aware styles
- Custom colors: define a 10-shade array (`colors: { brand: [...] }`)
- Override component defaults globally via `theme.components.{ComponentName}.defaultProps`
- Override component styles globally via `theme.components.{ComponentName}.classNames`

## Styling

- CSS Modules are the recommended styling approach -- use `*.module.css` files
- Use `classNames` prop (object mapping selectors to class names) to target inner elements via Styles API
- Prefer `classNames` over `styles` prop -- better performance, lower specificity issues
- Use `className` for root element, `classNames` for inner elements
- Never use `!important` -- use Styles API specificity or cascade layers
- Use `postcss-preset-mantine` mixins: `light-dark()`, `hover()`, responsive breakpoints
- Avoid `sx` prop (removed in v7) -- use CSS Modules or `style` prop for dynamic values
- Do not use emotion/styled-components with Mantine v7+ -- they conflict with the CSS-variable approach

## Components

- Use Mantine primitives before building custom: `Button`, `TextInput`, `Select`, `Modal`, `Drawer`, etc.
- Compose with `Stack`, `Group`, `Flex`, `Grid`, `SimpleGrid` for layout -- not raw div + CSS
- Use polymorphic `component` prop or `renderRoot` to change underlying element (e.g., `Button component="a"`)
- Use `@mantine/notifications` with `notifications.show()` -- do not build custom toast systems
- Use `@mantine/modals` with `modals.openConfirmModal()` for declarative modal management
- Keep component prop overrides minimal -- if overriding 5+ styles, extract a wrapper component

## Dates (`@mantine/dates`)

- Import `@mantine/dates/styles.css` at app root alongside core styles
- `dayjs` is a required peer dependency -- install it
- Use `DatePickerInput` for form fields, `DatePicker` for inline/embedded calendars
- Use `type` prop to switch modes: `"default"` (single), `"multiple"`, `"range"`
- Set `minDate`/`maxDate` to constrain valid ranges -- out-of-range values auto-revert
- Use `presets` prop for quick-select options (v8.1+)
- Use `valueFormat` prop to customize display format via dayjs tokens
- Set `dropdownType="modal"` on mobile for better UX
- If no label, always set `aria-label` for accessibility

## Charts (`@mantine/charts`)

- Import `@mantine/charts/styles.css` at app root -- missing styles cause broken tooltips and colors
- Built on recharts -- refer to recharts docs for advanced customization
- Use `BarChart`, `LineChart`, `AreaChart`, `CompositeChart` for standard visualizations
- Use `type` prop for variants: `"stacked"`, `"percent"`, `"waterfall"` (BarChart), `"split"` (AreaChart)
- Set `withLegend` for interactive legend; hovering highlights the corresponding series
- Sync tooltips across multiple charts with `barChartProps={{ syncId: 'id' }}`
- Use `maxBarWidth` to prevent oversized bars in sparse datasets

## Hooks

- Prefer `@mantine/hooks` over hand-rolled equivalents: `useDisclosure`, `useDebouncedValue`, `useMediaQuery`, `useClickOutside`, `useClipboard`, `useLocalStorage`, `useIntersection`
- `useDisclosure` for open/close state (modals, drawers, popovers) -- returns `[opened, { open, close, toggle }]`
- `useDebouncedValue` / `useDebouncedCallback` for search inputs and API calls
- `useForm` (`@mantine/form`): set `mode: "uncontrolled"` for performance unless controlled mode is explicitly needed
- `useForm`: use `form.getInputProps(field)` to bind inputs -- do not manually wire `value`/`onChange`/`error`
- `useForm`: validate with inline functions or schema validators (zod via `zodResolver`)
- `useForm`: use dot-notation for nested paths (`"user.address.city"`) and list helpers (`insertListItem`, `removeListItem`)

## Color Scheme

- Use `useMantineColorScheme()` hook to read/toggle color scheme
- Support three modes: `light`, `dark`, `auto` (system preference)
- Use `light-dark()` PostCSS mixin for color-scheme-aware values in CSS Modules
- Use `lightHidden` / `darkHidden` props on components for scheme-specific visibility
- Never check color scheme manually with JS media queries -- use Mantine's built-in utilities
- Test both color schemes -- broken dark mode is a common oversight

## v8 Notes

- Global styles split into 3 files: `baseline.css` (reset), `default-css-variables.css` (variables), `global.css` (component classes) -- import all three or use the combined import
- `attributes` prop on Styles API components allows passing data attributes to inner elements -- useful for test selectors (v8.2+)
- `@mantine/code-highlight` uses adapter-based API -- no longer depends on highlight.js; pick any syntax highlighter
- `Heatmap` component available in `@mantine/charts` (v8.3+)
- `Select`/`MultiSelect` gained a built-in clearable button (v8.3+)

## Patterns to Avoid

- Hardcoded color/spacing values -- use theme tokens or CSS variables
- Overriding Mantine styles with global CSS selectors -- use Styles API (`classNames`/`styles`)
- Using `sx` prop (does not exist in v7+)
- Using emotion/styled-components alongside Mantine v7+
- Rebuilding components Mantine already provides (custom date picker, custom select, etc.)
- Using `styles` prop for static styles -- prefer `classNames` with CSS Modules
- Nesting `MantineProvider` for local theme overrides instead of using component-level props
- Ignoring `form.getInputProps()` and manually wiring every input
- Importing from internal/undocumented Mantine paths -- stick to public package APIs
