---
title: Immutable data structures in typescript
date: January 28, 2021
author: Joona
tags: haskell, lambda-calculus, combinatory logic, cartesian closed categories, bracket abstraction, graph reduction, Y-combinator, recursion, mutable references, ST-Monad, STRef
---


# Why would you want immutable data structures?

Immutable data structures are essential when you try to code in a functional way, and JavaScript by itself doesn't support these. Luckily we can leverage the type system provided by TypeScript to enforce these immutability rules on our frequently used data structures like arrays and objects.
I only recently found out about this feature and thought that other people might have also missed out so making this short blog post to hopefully provide useful information for at least a couple of you guys!

## Arrays

**_Regular way to initialize an array filled with some integers._**

```ts
const xs = [1, 2, 3, 4, 5]
```

The problem with this is that even though we are using **_const_** to prevent reassignments we are allowed to mutate the array as we please.

```ts
xs[1] = 100
console.log(xs) -> [1, 100, 3, 4, 5]
```

We can luckily fix this by just giving xs the type **_ReadOnlyArray_**.

```ts
const xs: ReadOnlyArray<number> = [1, 2, 3, 4, 5]
```

Now we are not allowed to mutate the array!

```ts
xs[1] = 100
console.log(xs) -> error TS2542: Index signature in type 'readonly number[]' only permits reading.
```

This is quite awesome. Enforcing immutable data structures makes our code both easier to understand and to maintain. If you are freaked out by this and thinking that what can you even do with these data structures that cannot be changed, stop worrying!. We can still use all the functional techniques that won't modify the values in place, but return new values instead.

**_examples_**

```ts
const biggerXs = xs.map(x => x * 100)
const largestInXs = xs.reduce((acc, x) => x > acc ? x : acc)
const evenOnly = xs.filter(x => x % == 0)
```

## Objects

We can do similar things with objects.

**_Regular way to initialize a user object._**

```ts
const user = {
    firstname: 'foo',
    lastname: 'bar',
    age: 69,
}
```

I didn't define a type or an interface because in these kinds of situations the compiler can infer the types for free. If you want to make this immutable you actually have to define an interface for the type.

**Immutable way to initialize a user object.\_**

```ts
interface Iuser {
    readonly firstname: string
    readonly lastname: string
    readonly age: number
}
const user: Iuser = {
    firstname: 'foo',
    lastname: 'bar',
    age: 69,
}
```

Not if we try to modify a field on our user we get a similar compiler error as before with arrays.

```ts
user.firstname = 'bar' -> error TS2540: Cannot assign to 'email' because it is a read-only property.
```

Now if we want to update the user we need some functional techniques again...

```ts
const incUserAge = (user: Iuser): Iuser => ({ ...user, age: user.age + 1 })

const birthdayBoy = incUserAge(user) -> { firstname: 'foo', lastname: 'var', age: 70 }
```

That's all I wanted to share in this blog post. Hope you found it useful. I will post more stuff related to FP in the future so consider giving me a follow if that sounds interesting ;-).