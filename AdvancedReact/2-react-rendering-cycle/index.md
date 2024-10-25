---

marp: true

theme: softwire
headingDivider: 3

---

# The React Rendering Cycle

## Rendering and Re-rendering

- React has to transform your components into JS objects that can be applied to the DOM

- This is done in two phases:
    1. *Render phase*: The node tree is traversed and JSX objects turned into JS objects
    2. *Commit phase*: Elements are applied to the DOM

- The commit phase is very fast so can be ignored

- We consider two cases of the render phase:
    - *Initial render*: occurs when a component is first mounted (appears on screen)
    - *Re-render*: any render of an already mounted component

## Initial Render

Render phase
- Traverse node tree from root
- Convert JSX elements to JS objects (the virtual DOM)

Commit phase
- Apply elements to the DOM

## Re-Render

Render phase
- Traverse node tree from root, finding all elements that are flagged for update
- Convert flagged JSX elements to JS objects
- Compare new elements to previous render
- Elements that don’t result in a change to the DOM are discarded
- Changes to DOM are batched

Commit phase
- Changes applied to DOM

This is where we can optimise our components to reduce the number of re-renders that occur, and reduce the number of flagged elements when they do

## Why Bother?

React is fast so re-renders don't usually result in bad UX

You can probably get away with not knowing how re-rendering works so why bother?

Knowing how re-rendering works will help you:

- Debug your components, as you'll be able to trace through how they're executed

- Optimise components
    - This isn't usually an issue, but occasionally you'll notice that your app is laggy due to re-renders happening frequently or on heavy components

    - You'll be able to identify what's causing the re-rendering or know how to optimise your heavy components

## What Flags a Component For Re-rendering?
There are 3 reasons:

1. `useState` and `useReducer`

    - Setter / dispatch functions cause the component they reside in to re-render, unless updating to same value as current state *(with some caveats)*
    - React compares objects by reference only

2. Ancestor component re-renders

    - React recursively re-renders all children created by a component that is flagged for re-rendering

3. Context value updated

    - React re-renders all components that listen to a context when that context’s value changes

## What Flags a Component For Re-rendering?

Custom hooks changing *do* cause a re-render
- Everything inside a hook belongs to the component that uses it
- The code inside your hook might as well be in your component for the purposes of re-rendering so the previous three rules apply
- If a hook's state changes, it's the same as if the component's state changes

Props changing *do not* cause a re-render
- This is a common myth
- For props to change, the parent component must update them; this means the parent must have re-rendered and so the child will also re-render due to rule 2
- Caveat: if you memoise a child component, then a re-render of the parent won't cause a re-render of the child if the props are the same

## Optimisation: Starting Simple

The easiest optimisation has nothing to do with React!

If your component defines variables or functions that don't rely on the component's state in any way, define them outside the component.
- Every time your component re-renders, the variables and functions defined within them are recreated
- Extracting them from the component means the same variable / function is used on every render
- If your function does use component state, consider if it can be passed into the function as an argument

This is often good practice anyway, as it makes your components easier to read.

## Optimisation: Starting Simple

```Javascript
const myComponent = ({ users }) => {
    const componentTitle = "Middle names of users";

    const getAllUniqueMiddleNames = () => {
        const middleNames = users
            .filter((user) => !!user.middleName)
            .map((user) => user.middleName)
        return new Set(middleNames);
    }

    return (
        <>
            <h1>{componentTitle}</h1>
            {getAllUniqueMiddleNames(users).map((middleName) => {
                <p>{middleName}</p>
            })}
            //...
```

## Optimisation: Starting Simple

```Javascript
// myComponent.constants.ts
const componentTitle = "Middle names of users";

// myComponent.functions.ts
const getAllUniqueMiddleNames = (users) => {
    const middleNames = users
        .filter((user) => !!user.middleName)
        .map((user) => user.middleName)
    return new Set(middleNames);
}

// myComponent.tsx
const myComponent = ({ users }) => (
    <>
        <h1>{componentTitle}</h1>
        {getAllUniqueMiddleNames(users).map((middleName) => {
            <p>{middleName}</p>
        })}
        //...
    )
}
```

## Optimisation: Creating components in the render function

In a similar vein, this is an antipattern to avoid!

```Javascript
const Component = () => {
  const SlowComponent = () => <.../>;

  return (
    <SlowComponent />
  )
}
```
Why?

## Optimisation: Creating components in the render function

In a similar vein, this is an antipattern to avoid!

```Javascript
const Component = () => {
  const SlowComponent = () => <.../>;

  return (
    <SlowComponent />
  )
}
```
Why? ...because `SlowComponent` is a different function on every re-render so React will re-mount it instead of just re-rendering it on every render of `Component`
- Re-mount: React destroys everything created by `SlowComponent` and re-creates it
- Re-render: React updates anything created by `SlowComponent` that has changed

## Optimisation: Keep State Local
- State updates cause a re-render of their component and their component's ancestors

- Putting your state as deep as possible in the node tree will reduce the number of components that need re-rendering

- You may need to create a new component and "move state down" to achieve this

`SlowComponent` re-renders every time the modal is opened / closed:
```JavaScript
const Component = () => {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button onClick={() => setOpen(true)} />
      {isOpen && <Modal />}
      <SlowComponent />
    </>
  );
}
```

## Optimisation: Keep State Local

`SlowComponent` unaffected by the modal:
```JavaScript
const ButtonWithModal = () => {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button onClick={() => setOpen(true)} />
      {isOpen && <Modal />}
    </>
  );
};

const Component = () => (
  <>
    <ButtonWithModal />
    <SlowComponent />
  </>
);
```

## Optimisation: Children as Props

- Sometimes you can't "move state down", but have identified a slow child component that doesn't rely on the parent's state to render

- In this case, you can "wrap state around the children" by passing the child component to the parent as props

`SlowComponent` re-rendered on scroll:
```Javascript
const Component = () => {
  const [value, setValue] = useState({});

  return (
    <div onScroll = {(e) => setValue(e)}>
      <SlowComponent />
    </div>
  );
};
```

## Optimisation: Children as Props

`SlowComponent` is a prop, so not affected by on scroll re-render:
```Javascript
const ScrollComponent = ({ children }) => {
  const [value, setValue] = useState({});

  return (
    <div onScroll = {(e) => setValue(e)}>
      {children}
    </div>
  )
};

const Component = () => (
  <ScrollComponent>
    <SlowComponent />
  </ScrollComponent>
);
```

Take a moment to understand why re-render rule 2 — React recursively re-renders all children created by a component that is flagged for re-rendering — doesn't apply here!

## Optimisation: Children as Props

If you need your components in a particular place, you can still do this!

```JavaScript
const ScrollComponent = ({ first, second }) => {
  const [value, setValue] = useState({});

  return (
    <div onScroll = {(e) => setValue(e)}>
      {first}
      <Something />
      {second}
    </div>
  )
};

const Component = () => (
  <ScrollComponent
    first={<SlowComponent1 />}
    second={<SlowComponent2 />}
  />
);
```

## Optimisation: Memoising Components

- We can prevent a child component re-rendering when its parent re-renders by wrapping it in `React.memo()`

- In this case, the component will only re-render if its props change

- Useful when rendering a heavy component that doesn't depend on the re-render source

```JavaScript
const HeavyComponentMemo = React.memo(HeavyComponent);

const Component = () => {
  return (
    <>
      // ...
      <HeavyComponentMemo />
    </>
  );
};
```

## Optimisation: Memoising Components

Remember that objects (including components) are compared by reference!

```JavaScript
const HeavyComponentMemo = React.memo(HeavyComponent);
const HeavyComponentChildMemo = React.memo(HeavyComponentChild); // memoise child components passed as props

const Component = () => {
  const someObject = useMemo(() => ({ ... }), []);               // memoise objects passed as props
  const someFunction = useCallback(() => { ... }, []);           // memoise functions passed as props

  return (
    <>
      // ...
      <HeavyComponentMemo someObject={someObject} someFunction={someFunction}>
        <HeavyComponentChildMemo />
      </HeavyComponentMemo>
    </>
  );
};
```

## Optimisation: `useMemo` for Expensive Calculations

- In rare cases, you may want to avoid re-calculating a value on every render

- `useMemo` has a small memory cost and makes the initial render slightly slower, so only use if you can measure a performance benefit

```JavaScript
const Component = () => {
  const usersRows = useMemo(() => 
    users.map((user) => <SlowComponent user={user} key={user.id} />), 
    [users]
  );

  return (
    <>
      {usersRows}
    </>
  );
};
```

## Optimisation: `useMemo` for Expensive Calculations

- Generally only worth doing if creating / looping over thousands of objects

- You can measure how long the calculation takes with `console.time()`
    ```Javascript
    console.time('expensive function');
    expensiveFunction();
    console.timeEnd('expensive function');
    ```

- If it takes a significant amount of time (1ms+ is what they recommend in the React docs), then consider memoising

## Optimisation: Lists and the `key` Attribute
- When we create a list of components, we have to provide a `key` attribute

- The `key` is used by React to identify an element of the same type from its siblings during re-renders

- Improper use can cause bugs / degrade performance!

```JavaScript
const Component = (users) => (
  <>
    {users.map((user) => {
      return <UserRow user={user} key={user.id} />;
    })}
  </>
);
```

## Optimisation: Lists and the `key` Attribute

- DON'T use a random value — React will re-mount the list items on every re-render!

- DON'T use the list index on dynamic lists — if you can add, remove or re-order elements in the list, this will lead to bugs! *(It's OK to use the list index on static lists)*

- N.B. Wrapping the list item component in `React.memo` and using a consistent `key` attribute can prevent the items from re-rendering

## Optimisation: Preventing Context Re-renders

- If your context provider isn't at the root of your app, it might re-render due to change in its ancestors

- If this happens, its value will change and every component listening to it will re-render!

- To prevent this, memoise the context value

```Javascript
const ContextComponent = ({ children }) => {
    const memoisedValue = useMemo(() => ({ value }), []);

    return (
        <Context.Provider value={memoisedValue}>
            {children}
        </Context.Provider>
    );
};
```

## Optimisation: Getter and Setter Contexts
- If your context value contains a getter and a setter, then consider making them separate contexts

- That way listeners to the getter won't re-render when the setter changes and vice-versa

- A similar optimisation can be made if your context value is an object with several independent parts that can be split up

```Javascript
const ContextComponent = ({ children }) => {
    const [state, setState] = useState();

    return (
        <Getter.Provider value={state}>
            <Setter.Provider value={setState}>
                {children}
            </Setter.Provider>
        </Getter.Provider>
    );
};
```

## Further Reading

- [A deeper dive into React reconciliation (how it decides which elements have changed in a re-render)](https://www.developerway.com/posts/reconciliation-in-react#part10)

- [A deeper dive into the key attribute](https://www.developerway.com/posts/react-key-attribute)

- [An old blog post about the DevTools React profiler](https://legacy.reactjs.org/blog/2018/09/10/introducing-the-react-profiler.html)

## Exercise

Create a simple React app that interacts with an API [(suggestions here)](https://softwiretech.atlassian.net/wiki/spaces/Academy/pages/19904528403/3+-+Further+React#Exercise---BusBoard-3.0)
- Choose a framework. The reading notes suggest "Vite"; you can also [look here for others](https://react.dev/learn/start-a-new-react-project)

- At a minimum, your app should take some user input, call your API and display something. You might want to try using `react-query` for making API calls; can you handle errors gracefully too?

- Try bundling all the logic to interact with the API into a custom hook

- Try validating a form with `yup`; this allows you to validate the form values conform to some type, so you have more confidence passing them around your app

- Try creating a loading screen context that shows a spinner while an API call is in-progress

- Try creating a multi-page form with a reducer

- Try making your app accessible by focusing titles on screen changes and focusing error messages