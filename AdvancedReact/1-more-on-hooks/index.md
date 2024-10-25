---

marp: true

theme: softwire
headingDivider: 3

---

# (Some) Advanced React

## Intro

- More on hooks
    - `useReducer`
    - `useRef`
    - `useMemo`, `useCallback`
    - `useContext`
    - Custom hooks

- The React rendering cycle
    - How it works
    - Easy optimisation tips

- `useEffect`
    - Writing a good `useEffect`
    - When not to use

# More on Hooks

## What is a Hook?

- Hooks give function components access to React features

- They're why class components are no-longer used

- Can be subdivided into:
    - State hooks: `useState`, `useReducer`
    - Context hooks: `useContext`
    - Ref hooks: `useRef`
    - Effect hooks: `useEffect`
    - Performance hooks: `useMemo`, `useCallback`
    - Custom hooks

- We'll briefly cover some of the core hooks and cover their performance later when talking about the rendering cycle

## State Hooks: `useState`

You've all seen `useState` before; here are some extra tips

- You can also initialise the state with a function:
    ```Javascript
    function TodoList() {
        const [todos, setTodos] = useState(createInitialTodos);
    ```
    - Note that we're passing a function in, not the result of calling the function
    - If we did `useState(createInitialTodos())` then `createInitialTodos` would be called on every re-render even though it's only used when the component first mounts

- If you're updating the state based on the previous state, use a callback function
    ```Javascript
    const [age, setAge] = useState(0);
    setAge(prevAge => prevAge + 1);
    ```
    - React batches state updates, so multiple consecutive calls to update state using `setAge(age + 1)` won't work

## State Hooks: `useReducer`

Like `useState` but moves your state update logic from event handlers to a single function outside your component

Useful when your state is very large and / or when a single event would update multiple state variables
```Javascript
const [state, dispatch] = useReducer(reducer, initialState);
```
- `state` is an object containing all your state variables
- `dispatch` is you call to update the state
- `reducer` is a function you define that describes how to update the state
- `initialState` is the start state 

## State Hooks: `useReducer` Typing

Create a state type
```Javascript
export type State = {
  initialStateLoadedFromSessionStorage: boolean;
  totalApprovable?: number;
  // ...
};
```
- This is what you would be putting into several `useState` hooks if you were not using a reducer

## State Hooks: `useReducer` Typing
Create an event type that describes the updates that can be performed
```Javascript
export type Event =
  | {
      type: 'SKIPPED_APPLICATION';
      payload: string;
    }
  | {
      type: 'BULK_UPDATE';
      payload: {
        approvedIds: string[];
        notApprovedIds: Record<NotApprovedErrorViewState, string[]>;
      };
    }
  | { type: 'GO_TO_MAIN_VIEW' }
  // ...
```
- Your events can be anything, but I find it easiest as an object that describes the update (`type`) and optionally includes values needed to update the state (`payload`)

## State Hooks: `useReducer` Reducer Function
Your reducer function takes the current state and an event and returns the updated state
```Javascript
const getNewState = (state: State, event: Event): State => {
  switch (event.type) {
    case 'GO_TO_MAIN_VIEW': {
      return {
        ...state,
        viewState: 'main',
        showNewApplicationsBanner: false,
        apiError: undefined,
      };
    }
    //...
```
- This is the part that extracts your state update logic from your component
- Typing your events makes this easier to read and allows Typescript to check that your switch block is exhaustive

## State Hooks: `useReducer` Making a State Update
Call the dispatch function within your component with one of your events
```Javascript
const [state, dispatch] = useReducer(getNewState, initialState);
dispatch({ type: 'SKIPPED_APPLICATION', payload: applicationId });
dispatch({ type: 'GO_TO_MAIN_VIEW' });
```
Further `useReducer` tips:
- You can also pass in an initialiser function and give the initialiser function arguments

- Use when your state is large and updates to it complex

## Context Hooks: `useContext`

Allows a parent component to make information available to any component below it in the tree without explicitly passing it through props

```Javascript
const theme = useContext(ThemeContext);
```
- `theme` is the context value for the `ThemeContext` context passed to `useContext`

- React finds the context value by searching the component tree for the closest context provider for the `ThemeContext` context

- React searches upwards starting with the parent component to the component calling `useContext`

```Javascript
<ThemeContext.Provider value="dark"> // If you omit the `value` prop, the provider returns undefined!
    <ChildComponents>
    // ...
</ThemeContext.Provider>
```

## Context Hooks: `useContext` Creating a Context

To create a context, call `createContext()` outside of any component

```Javascript
const ThemeContext = createContext('light');
```
- `createContext()` takes a single argument, the default value for the context

- The default value never changes and will be returned by `useContext(ThemeContext)` when React can't find a provider in the component tree

## Context Hooks: `useContext` Adding State

Often you'll want to store and update some state with `useContext`. The easiest way to do this is to abstract this into a component.

```Javascript
const LoadingContext = createContext({ loading: false, setLoading: () => null });

const LoadingScreen = ({ children }) => {
  const [loading, setLoading] = useState<boolean>(false);
  // ...

  return (
    <LoadingContext.Provider value={{ loading, setLoading }}>
      {children}
    </LoadingContext.Provider>
  );
};
```
```Javascript
<LoadingScreen>
    <ChildComponent>
    //...
</LoadingScreen>
```

## Context Hooks: `useContext` When to Use

Contexts are very powerful which means they're easy to over-use! Before you use a context:
- Start by passing props: props make it very clear what is being passed, even if you have to pass a lot of them

- Extract components: if you're passing props through components that don't use them, you might be able to extract the component

    ```Javascript
    <Layout posts={posts} />

    // Replace the above with this:
    <Layout>                     
        <Posts posts={posts} />
    </Layout>
    ```
If you're still doing lots of "prop drilling" (passing props through multiple intermediate components to a deeply-nested component) then consider using a context

## Context Hooks: `useContext` When to Use

Example usages:
- Theming e.g. dark mode

- Storing info on the current user

- Routing (if you build your own router)

- Managing state at the top of your app: using a context with a `useReducer` can help manage a large and complex state in big apps

## Ref Hooks: `useRef`
Used to hold information that isn't used for rendering. Updating the ref does not re-render the component
```Javascript
const ref = useRef(initialValue)
```

The object `ref` has a single property `current`
- Initially it's set to `initialValue`

- You can mutate it `ref.current = newValue`

- If you are passing it as a `ref` attribute to a JSX node, React will set its `current` property, so initialise it to `null`

## Ref Hooks: `useRef` When to Use

Don't write or read `ref.current` during rendering! If you need to do this, use `useState` instead

React expects the body of your component to behave like a pure function:
- If the inputs (props, state, and context) are the same, it should return exactly the same JSX.
- Calling it in a different order or with different arguments should not affect the results of other calls.

Reading or writing a ref during rendering breaks these expectations.
```Javascript
function MyComponent() {
  // 🚩 Don't write a ref during rendering
  myRef.current = 123;
  // 🚩 Don't read a ref during rendering
  return <h1>{myOtherRef.current}</h1>;
}
```

## Ref Hooks: `useRef` When to Use
Ref hooks are for use in event handlers or effects
```Javascript
function MyComponent() {
  useEffect(() => {
    // ✅ You can read or write refs in effects
    myRef.current = 123;
  });
  function handleClick() {
    // ✅ You can read or write refs in event handlers
    doSomething(myOtherRef.current);
  }
  // ...
}
```

Think of refs as an escape hatch and use them sparingly!

## Ref Hooks: `useRef` Focusing for Accessibility
The most common use case I've found is for focusing elements for accessibility purposes
- Focus form element when it has an error
- Focus heading element when component is first rendered (e.g. below)

```Javascript
function Component() {
  const headingRef: RefObject<HTMLHeadingElement> = useRef(null);

  useEffect(() => {
    headingRef?.current?.focus();
  }, []);

  return (
    <>
      <h2 _ref={headingRef}>My heading</h2>
      //...
```

## Performance Hooks: `useMemo` and `useCallback`

Used to cache a value or a function between renders

```Javascript
const cachedFn = useCallback(fn, dependencies);
const cachedValue = useMemo(calculateValue, dependencies);
```
- `useMemo` caches a value
- `useCallback` caches a function
- `dependencies` is a list, used in the same way is used in `useEffect`

Use these hooks to:
- Cache expensive values
- Prevent a `useEffect` from firing too often by memoising a dependency
- Memoise child components to skip re-rendering them if their props are the same

There is a small overhead to using them so don't use them if you don't need to!

We'll cover these a bit more when talking about re-rendering

## Custom Hooks

Custom hooks allow you to extract logic from your components. They're useful for:
- Sharing logic between components
- Making your component logic clearer by separating concerns

Custom hooks are just functions

```Javascript
const useCustomHook = (arguments) => {    // You can pass in whatever you want
    const [state, setState] = useState(); // You can include other hooks
    const otherHook = useOtherHook();     // Including other custom hooks
    useEffect(() => { ... }, []);         // All React features can be used

    return {                              // You can return whatever you want
        state,
        setState,
        // ...
    };
};

const myComponent = () => {
    const { state, setState } = useCustomHook(arguments);
    // ...
};
```

## Custom Hooks

- Names must begin with 'use' followed by a capital letter e.g. `useLoading`

- If a custom hook is used by multiple components, the state within the hook is not shared
    - Each call to a hook is completely independent of all other calls to it
    - Custom hooks allow you to share stateful *logic* not the state itself

- The code within your hook will re-run on every re-render of your component!
    - This allows you to pass state from your component into your custom hook

**TL;DR** the best way to think of how React treats custom hooks is that the code within the hook is pasted into the component that uses it

*Try out the exercise in further reading to refactor a component to use a custom hook*

## Further Reading / Exercises

- [Creating a reducer with an initialiser function](https://react.dev/reference/react/useReducer#avoiding-recreating-the-initial-state)

- [Accessing another component's DOM nodes with `useRef` and `forwardRef`](https://react.dev/reference/react/forwardRef#exposing-a-dom-node-to-the-parent-component)

- [Try out an exercise to extract state logic into a reducer](https://react.dev/learn/extracting-state-logic-into-a-reducer#challenges)

- [Try out a custom hook exercise from React](https://react.dev/learn/reusing-logic-with-custom-hooks#challenges)

- There are more built-in hooks for niche scenarios that you can [read about on the React website](https://react.dev/reference/react/hooks)