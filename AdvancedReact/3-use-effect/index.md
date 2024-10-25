---

marp: true

theme: softwire
headingDivider: 3

---

# `useEffect`

## Why does `useEffect` have its own section?

Most of the time I see bad React code, it's due to bad usages of `useEffect`
- `useEffect` is an *escape hatch*; it allows you to break out of normal React code and perform a **side-effect that is caused by rendering**, rather than by a particular event

- They can be hard to reason with and follow, as you have to understand when their dependencies update to know when the effect runs

- They usually run *after* the browser has finished the commit phase
    - Improper use (e.g. setting state within the effect) can cause unnecessary re-renders!

The React website states that `useEffect` is for **synchronising with external systems**; if you're using them for another reason, consider if there's an alternative.

## How does `useEffect` work?

```JavaScript
useEffect(() => {
    // setup function
    return () => {
        // clean-up function (optional)
    }
}, [dependencies (optional)])
```
- When your component is mounted, React runs the setup function

- On every re-render, React first runs the clean-up function, then the setup function

- When your component is unmounted, React runs the clean-up function

- If the dependencies array is omitted, the effect runs on every render

- If the dependencies array is empty, the effect runs on first mount only

## How does `useEffect` work?

- You can run asynchronous JS in your effect:

    ```JavaScript
    useEffect(() => {
        async function myEffect() {
            await myAsyncCall();
            // ...
        };
        myEffect();
    })
    ```

- `useEffect` essentially replaces the lifecycle methods in class components
    - `componentDidMount()`
    - `componentDidUpdate()`
    - `componentWillUnmount()`

## How does `useEffect` work?

How would you emulate `componentDidMount()` with `useEffect` (called on first mount)?

## How does `useEffect` work?

How would you emulate `componentDidMount()` with `useEffect` (called on first mount)?

```JavaScript
useEffect(() => {
    // ... your code here
}, []);
```

## How does `useEffect` work?

How would you emulate `componentWillUnmount()` with `useEffect` (called on unmount)?

## How does `useEffect` work?

How would you emulate `componentWillUnmount()` with `useEffect` (called on unmount)?

```JavaScript
useEffect(() => {
    return () => {
        // ... your code here
    }
}, []);
```

## How does `useEffect` work?

How would you emulate `componentDidUpdate()` with `useEffect` (called on re-renders only, not inital render)?

## How does `useEffect` work?

How would you emulate `componentDidUpdate()` with `useEffect` (called on re-renders only, not inital render)?

```JavaScript
const hasRendered = useRef(false);

useEffect(() => {
    if (hasRendered.current) {
        // ... your code here
    } else {
        hasRendered.current = true;
    }
})
```

## How does `useEffect` work?

- As a general rule of thumb, effects run after the browser has painted the updated screen

- Effects run in the order that they are defined in your component

- If your effect does something visual (e.g. setting focus) AND the delay is noticeable, then use `useLayoutEffect` instead
    - `useLayoutEffect` is a synchronous form of `useEffect` that runs before the browser paints the updated screen
    - This incurs a performance penalty; only use if needed!

## How to write a good effect

Your effect should have single purpose: if it's doing several unrelated things:
- Thing A might trigger the effect to run, updating thing B when you don't want it to

- Your effect becomes harder to read, understand and debug

## How to write a good effect

Remove as much as possible from the dependencies list
- Declare non-reactive objects or functions outside the component

- Move dynamic objects or functions that aren't used elsewhere in your component *into* the effect 

- Memoise shared objects or functions that are causing the effect to fire too often

```JavaScript
const serverUrl = 'https://localhost:1234';        // Declared outside component so not a dependency

function ChatRoom({ roomId }) {
  const [message, setMessage] = useState('');

  useEffect(() => {
    const options = { serverUrl, roomId };         // Inside effect so doesn't need to be a dependency
    const connection = createConnection(options);
    connection.connect();
    return () => connection.disconnect();
  }, [roomId]);                                    // ✅ All dependencies declared
  // ...
```

## How to write a good effect

Don't suppress the linter!
- If your effect doesn't work unless you omit some of its dependencies, you need to work out how to 'prove' to the linter it doesn't need to be a dependency (see last slide)

- Suppressing the linter can lead to unexpected bugs

- *Very occasionally*, you will need to do this (when you want to read a value without reacting to its changes). [The React devs are working on a solution so you don't need to suppress the linter...](https://react.dev/learn/removing-effect-dependencies#do-you-want-to-read-a-value-without-reacting-to-its-changes)

## Common (Valid) Uses

- Fetching data (e.g. fetching data to display on mount)

- Subscribing to events (e.g. scroll events)

- Sending analytics (e.g. logging a page visit on mount)

- Setting focus for accessibility

- Triggering animations 

## Common Misuses

There are lots of ways to misuse effects!

As a general rule-of-thumb, whenever you write an effect you should first consider if what you're doing can be done without one.

I've picked out a few common misuses that also highlight good React code practices.

There are many more examples in the "You might not need a React" page linked in further reading — a must read!

## Common Misuses: Event Handling

An event handler is a function that runs in response to a user's action e.g. clicking a button

```Javascript
<button onClick={eventHandler} />
```

I've often seen people only partially handle events with the event handler and use `useEffect` to handle the rest.

This is bad because:
- The code to handle the event becomes harder to follow: the handling of the event is not in one place in the code
- It's more bug-prone: when an effect runs is harder to understand than a callback function, as you need to understand when its dependencies change
- It's could be causing unnecessary re-renders: setting state in a `useEffect` should be avoided if possible!

## Common Misuses: Event Handling (The Bad and Ugly)

A generalised example I see all over my project. The code to handle the button click event is in three different places! It gets worse with multiple API calls, or chained calls...

```JavaScript
const MyComponent = () => {
    const { setLoading } = useLoading();                 // Custom hook to show a loading screen
    const { data, refetch, isLoading } = useMyApiCall(); // Custom hook wrapping useQuery
    const [myProcessedData, setMyProcessedData] = 
        useState(undefined);

    useEffect(() => {
        const processedData = processData(data);
        setMyProcessedData(processedData);
    }, [data, processData]);                             // Need to ensure`processData` is the same
                                                         // function on every render!

    useEffect(() => {
        setLoading(true);
    }, [isLoading]);

    return (
        <>
            <button onClick={refetch}>
            // ...
```

## Common Misuses: Event Handling (The Good)

```JavaScript
const MyComponent = () => {
    const { setLoading } = useLoading();          // Custom hook to show a loading screen
    const { refetch } = useMyApiCall();           // Custom hook wrapping useQuery
    const [myProcessedData, setMyProcessedData] = 
        useState(undefined);

    const fetchAndProcessData = async () => {     // All the code to handle the event is in one place.
        setLoading(true);                         // This is much less bug-prone, as useEffect 
        const data = await refetch();             // dependencies can be a bit fiddly!
        const processedData = processData(data);
        setMyProcessedData(processedData);
        setLoading(false);
    };

    useEffect(() => {                             // There is a single useEffect to synchronise with
        fetchAndProcessData();                    // the API that runs on mount only. This is much
    }, []);                                       // easier to understand!

    return (
        <>
            <button onClick={fetchAndProcessData}>
            // ...
```

## Common Misuses: Resetting State (The Bad)

Sometimes you want to 'reset' a component's state in response to a change

E.g. when changing user profile pages, clear out comments so they don't persist between different users' pages

```JavaScript
export default function ProfilePage({ userId }) {
  const [comment, setComment] = useState('');

  // 🔴 Avoid: Resetting state on prop change in an Effect
  useEffect(() => {
    setComment('');
  }, [userId]);
  // ...
}
```

## Common Misuses: Resetting State (The Good)

This is what the `key` prop is for! If React sees a component of the same type, but with a different `key` prop, it knows to re-mount the component which will reset the state.

```JavaScript
export default function ProfilePage({ userId }) {
  return (
    <Profile
      userId={userId}
      key={userId}
    />
  );
}

function Profile({ userId }) {
  // ✅ This and any other state below will reset on key change automatically
  const [comment, setComment] = useState('');
  // ...
}
```

## Common Misuses: Adjusting State (The Bad)

Sometimes you want to reset / adjust some, but not all state when props change, so you can't use the `key` prop.

E.g. This List component receives a list of items as a prop, and maintains the selected item in `selection`. You want to reset `selection` to `null` whenever the `items` prop changes:

```JavaScript
function List({ items }) {
  const [selection, setSelection] = useState(null);

  // 🔴 Avoid: Adjusting state on prop change in an Effect
  useEffect(() => {
    setSelection(null);
  }, [items]);
  // ...
}
```

Why is this bad? What happens when `items` changes?

## Common Misuses: Adjusting State (The OK)

`setSelection` is called directly during a render. React will re-render the List immediately after it exits with a return statement. React has not rendered the `List` children or updated the DOM yet, so this lets the `List` children skip rendering the stale `selection` value.

```JavaScript
function List({ items }) {
  const [selection, setSelection] = useState(null);

  // Better: Adjust the state while rendering
  const [prevItems, setPrevItems] = useState(items);
  if (items !== prevItems) {
    setPrevItems(items);
    setSelection(null);
  }
  // ...
}
```

## Common Misuses: Adjusting State (The Good)

**Prefer calculating during rendering** — this is good general guidance to follow when writing components!

- There's no need to adjust the state here!

- The behaviour below is *slightly* different (the selection is kept if `items` changes but the selected item is still in this list) but is arguably better

- This is easier to understand and debug (no need to understand how React short-circuits the rendering)

```JavaScript
function List({ items }) {
  const [selectedId, setSelectedId] = useState(null);
  // ✅ Best: Calculate everything during rendering
  const selection = items.find(item => item.id === selectedId) ?? null;
  // ...
}
```

## Common Misuses: Passing Data Upwards (The Bad)

Consider a case where a Child component fetches some data and then passes it to the Parent component in an Effect:

```JavaScript
function Parent() {
  const [data, setData] = useState(null);
  // ...
  return <Child onFetched={setData} />;
}

function Child({ onFetched }) {
  const data = useSomeAPI();
  // 🔴 Avoid: Passing data to the parent in an Effect
  useEffect(() => {
    if (data) {
      onFetched(data);
    }
  }, [onFetched, data]);
  // ...
}
```

## Common Misuses: Passing Data Upwards (The Good)

In React, data flows from parents to children
- This makes it easier to debug components

- If the parent and child components both need the data, fetch it in the parent component

- If the child needs to control refetching, then pass it a function to do so as props

```JavaScript
function Parent() {
  const { data, refetch } = useSomeAPI();
  // ...
  // ✅ Good: Passing data down to the child
  return <Child data={data} refetch={refetch} />;
}

function Child({ data, refetch }) {
  // ...
}
```

## Common Misuses: Passing Data Upwards (The Good)

Similarly, if there is some state in the child component that the parent needs to know about, consider "lifting state up" by putting the state in the parent and passing it as props to the child.

```JavaScript
// ✅ Good: Keeping state in the child and performing all updates in the event handler
function Toggle({ onChange }) {
  const [isOn, setIsOn] = useState(false);

  function handleClick() {
    onChange(!isOn);
    setIsOn(!isOn);
  }
```

```JavaScript
// ✅ Good: "lifting state up" so the component is fully controlled by its parent
function Toggle({ isOn, onChange }) {
  function handleClick() {
    onChange(!isOn);
  }
```

## Further Reading

- [A comprehensive guide to situations where you don't need an effect](https://react.dev/learn/you-might-not-need-an-effect)

- [A guide to `useEffect` from the React website](https://react.dev/learn/synchronizing-with-effects)

- [Removing dependencies from effects](https://react.dev/learn/removing-effect-dependencies)