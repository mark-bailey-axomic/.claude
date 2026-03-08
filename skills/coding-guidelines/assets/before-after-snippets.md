# Before / After Snippets

Common anti-patterns and their corrected forms. Reference during code review to show concrete examples.

---

## Tailwind — Extract Utilities to CSS Modules

**Bad** — inline utilities in JSX:
```tsx
<div className="flex items-center gap-4 rounded-lg bg-white p-6 shadow-md">
  <h2 className="text-lg font-semibold text-gray-900">Title</h2>
</div>
```

**Good** — extracted to CSS Module:
```tsx
// Card.tsx
import styles from './Card.module.css';
<div className={styles.card}><h2 className={styles.title}>Title</h2></div>
```
```css
/* Card.module.css */
.card { display: flex; align-items: center; gap: 1rem; border-radius: 0.5rem; background: white; padding: 1.5rem; box-shadow: 0 4px 6px rgb(0 0 0 / 0.1); }
.title { font-size: 1.125rem; font-weight: 600; color: var(--color-gray-900); }
```

---

## React — Class Component to Functional

**Bad** — class component:
```tsx
class Greeting extends React.Component<{ name: string }> {
  render() { return <h1>Hello, {this.props.name}</h1>; }
}
```

**Good** — functional component:
```tsx
function Greeting({ name }: { name: string }) {
  return <h1>Hello, {name}</h1>;
}
```

## React — Missing useEffect Deps

**Bad** — stale closure:
```tsx
useEffect(() => {
  fetchUser(userId);
}, []); // missing userId dep
```

**Good** — correct deps:
```tsx
useEffect(() => {
  fetchUser(userId);
}, [userId]);
```

## React — Inline Styles to CSS Modules

**Bad** — inline style object:
```tsx
<button style={{ backgroundColor: '#3b82f6', padding: '8px 16px', borderRadius: 4 }}>Save</button>
```

**Good** — CSS Module:
```tsx
<button className={styles.saveButton}>Save</button>
```
```css
.saveButton { background-color: var(--color-primary); padding: 0.5rem 1rem; border-radius: 0.25rem; }
```

---

## TypeScript — Eliminate `any`

**Bad** — `any` escape hatch:
```ts
function parse(data: any) { return data.items.map((i: any) => i.name); }
```

**Good** — proper typing:
```ts
interface Item { name: string; }
interface ApiResponse { items: Item[]; }
function parse(data: ApiResponse): string[] { return data.items.map((i) => i.name); }
```

## TypeScript — Explicit Return Types on Exports

**Bad** — inferred return on public API:
```ts
export function getUser(id: string) { return db.users.findOne({ id }); }
```

**Good** — explicit return type:
```ts
export function getUser(id: string): Promise<User | null> { return db.users.findOne({ id }); }
```

---

## CSS — Remove `!important`

**Bad** — brute-force specificity:
```css
.nav .link { color: blue !important; }
```

**Good** — fix specificity at source:
```css
.navLink { color: blue; } /* single class, applied directly */
```

## CSS — Magic Numbers to Tokens

**Bad** — magic values:
```css
.card { padding: 17px; margin-top: 53px; font-size: 13px; }
```

**Good** — design tokens:
```css
.card { padding: var(--space-4); margin-top: var(--space-12); font-size: var(--font-size-sm); }
```

## CSS — Flatten Deep Nesting

**Bad** — deeply nested selectors:
```scss
.page { .content { .sidebar { .nav { .link { color: blue; } } } } }
```

**Good** — flat, scoped classes:
```css
.sidebarLink { color: blue; }
```

---

## Testing — Behavior Over Implementation

**Bad** — testing implementation details:
```ts
it('calls setState with count + 1', () => {
  const spy = jest.spyOn(component, 'setState');
  component.increment();
  expect(spy).toHaveBeenCalledWith({ count: 1 });
});
```

**Good** — testing behavior:
```ts
it('displays incremented count after click', async () => {
  render(<Counter />);
  await userEvent.click(screen.getByRole('button', { name: /increment/i }));
  expect(screen.getByText('1')).toBeInTheDocument();
});
```

## Testing — Proper AAA Structure

**Bad** — no clear structure:
```ts
it('works', () => {
  const user = createUser('Alice'); user.activate(); expect(user.isActive).toBe(true); expect(user.name).toBe('Alice');
});
```

**Good** — Arrange / Act / Assert:
```ts
it('activates user and preserves name', () => {
  // Arrange
  const user = createUser('Alice');

  // Act
  user.activate();

  // Assert
  expect(user.isActive).toBe(true);
  expect(user.name).toBe('Alice');
});
```

---

## JavaScript — `var` to `const`

**Bad**:
```js
var items = getItems();
var count = items.length;
```

**Good**:
```js
const items = getItems();
const count = items.length;
```

## JavaScript — Nested Ternary to Guard Clause

**Bad** — nested ternary:
```js
function getLabel(status) {
  return status === 'active' ? 'Active' : status === 'pending' ? 'Pending' : status === 'disabled' ? 'Disabled' : 'Unknown';
}
```

**Good** — guard clauses / map:
```js
const STATUS_LABELS = { active: 'Active', pending: 'Pending', disabled: 'Disabled' } as const;
function getLabel(status: string): string { return STATUS_LABELS[status] ?? 'Unknown'; }
```

## JavaScript — Callback Hell to Async/Await

**Bad** — nested callbacks:
```js
getUser(id, (err, user) => {
  getOrders(user.id, (err, orders) => {
    getItems(orders[0].id, (err, items) => { console.log(items); });
  });
});
```

**Good** — async/await:
```js
const user = await getUser(id);
const orders = await getOrders(user.id);
const items = await getItems(orders[0].id);
```
