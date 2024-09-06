---
author: "Joona Piirainen"
desc: "General tips to help you thrive when working with Python and TypeScript"
keywords: "types, programming-languages, typescript, python, haskell, agda, lean4"
lang: "en"
title: "Tips for excelling with Python and TypeScript"
date: "2024-07-27T11:50:00Z"
---

In this article I'll share my personal tips for getting the most out of python and
typescript. These tips stem from me trying to incorporate the most valuable features
from languages such as [haskell](https://www.haskell.org/), [agda](https://github.com/agda/agda) and [lean4](https://github.com/leanprover/lean4)
to more mundane but widely used languages.

## Python

### 1. Use pyright, mypy or some static type checker

See my [post](https://japiirainen.xyz/posts/there-are-no-dynamic-type-systems.html) on "dynamic" languages.

### 2. Avoid dictionaries

Avoid dictionaries at all cost and use `dataclass` or `pydantic` instead.
In general, the only place dictionaries are actually needed are as implementation details of library functions/algorithms. They should
almost never be passed in or out of your libraries public API. The reason for avoiding
dictionaries is that they are so weakly typed that the type system won't be able to
help you nearly as much as when using stricter types. You will notice the benefits
especially when performing large scale refactorings.

Don't write functions like this:

```python
type State = dict[str, Any]
type Event = dict[str, Any]

def transition(state: State, event: Event) -> State:
  ....
```

And do something like this instead:

```python
from dataclasses import dataclass


@dataclass
class State:
    a: int
    b: str

@dataclass
class EventA:
    ...

@dataclass
class EventB:
    ...

type Event = EventA | EventB

def transition(state: State, event: Event) -> SystemState:
  ....
```

### 3. When to use classes

I use classes almost exclusively for creating generic "interfaces" for "things"
that can have multiple implementations. These "interfaces" don't have any mutable state,
only `abstractmethod`s. This can be achieved with abstract base classes in python,
I'm not a huge fan of these, so I'd be happy to learn that there's a better way to do this!

```python
from abc import ABC, abstractmethod


class Cache(ABC):
    @abstractmethod
    def set(self, key: str, value: str) -> None:
        pass

    @abstractmethod
    def get(self, key: str) -> str | None:
        pass

    @abstractmethod
    def keys(self, prefix: str) -> list[str]:
        pass


class InMemoryCache(Cache):
    def set(self, key: str, value: str) -> None: ...

    def get(self, key: str) -> str | None: ...

    def keys(self, prefix: str) -> list[str]: ...


class RedisCache(Cache):
    def __init__(self, client: RedisClient):
        self.client = client

    def set(self, key: str, value: str) -> None: ...

    def get(self, key: str) -> str | None: ...

    def keys(self, prefix: str) -> list[str]: ...
```

### 4. Use sum and product types for everything

Algebraic data types are one of the most basic programming concepts and using
them effectively is surprisingly rare. Product types can simply be dataclasses or
pydantic models:

```python
from dataclasses import dataclass


@dataclass
class Stuff:
    a: int
    b: int
    c: int
```

Sum types can be represented by a combination of dataclasses or pydantic models, and
union types. Python recently introduced [structural pattern matching](https://peps.python.org/pep-0636/),
which can be used to make working with union types both type safe and pleasant.

```python
from dataclasses import dataclass


@dataclass
class A:
    a: int


@dataclass
class B:
    b: str


type C = A | B


def f(c: C):
    match c:
        case A(a):
            return a + 1
        case B(b):
            return f"{b}!!"
```

### 4. `itertools` and `functools` are your friends

Itertools provides many functions for working with `Iterable`s. These are a nice
addition to standard library functions like `map`, `filter` and `sum`.

One gripe I have is that python standard library lacks basic tools like
`flatMap` (or `bind`, `chain`, etc...). Instead I end up with this unreadable mess:

```python
from itertools import chain


def duplicate[A](xs: list[A]) -> list[A]:
    return list(chain.from_iterable([[x, x] for x in xs]))
```

I'm aware that this could be simplified by using generators, but you get the point,
`flatMap` is extremely useful, and I miss it daily when working with python.

### 5. Get familiar with list, set and dict comprehensions.

These might be a bit unfamiliar when first coming from other languages, but are 
extremely useful, so one should get used to working with them.

## TypeScript

Overall, typescript is quite a pleasant system to work with. Nowadays the type system
is actually extremely expressive even when comparing to the state of the art.
With that said, there are still a couple pain points.

### 1. Simulating algebraic data types

I often see code like this:

```ts
type Thing = {
  state: "a" | "b"| "c";
  a?: string;
  b?: number;
  c?: Date;
}
```

and I die inside... The intention is to encode three distinct states, one where
`A.state === "a"` and `A.a` is populated and rest of the fields are missing, and the same
thing for states `b` and `c`. This is terrible, and is a great way to effectively
turn off the type checker.

This is clearly a place for using a sum type! Unfortunately typescript doesn't really support
algebraic data types out of the box. Luckily, it's easy to simulate them:

```ts
type A = { state: "a"; data: string; }
type B = { state: "b"; data: number; }
type C = { state: "c"; data: Date; }

type Thing = A | B | C
```

Another thing you need when working with these sum types is exhaustivity checking.

"Pattern matching" with `switch`, the `default:` case is the magic providing exhaustivity
checking:

```ts
const doStuff: (thing: Thing) => string = (thing) => {
  switch (thing.state) {
    case "a":
      return "thing was a";
    case "b":
      return "thing was b";
    case "c":
      return "thing was c";
    default:
      const _: never = thing;
      throw new Error(_);
  }
}
```

Or if you're willing to use a 3rd party library, you can get the same thing but with a
somewhat nicer syntax, here we're using [ts-pattern](https://github.com/gvergnaud/ts-pattern):

```ts
import { match } from "ts-pattern"

const doStuff: (thing: Thing) => string = (thing) =>
  match (thing)
    .with({ state: "a" }, ({ data }) => "thing was a")
    .with({ state: "b" }, ({ data }) => "thing was b")
    .with({ state: "c" }, ({ data }) => "thing was c")
    .exhaustive()
```

### 2. Avoid array indexing notation

By default typescript will lie to your face about the type when accessing elements
of an array with the standard indexing notation, e.g. `xs[3]`:

```ts
const xs = [1, 2, 3]

const y: number = xs[10]
```

TypeScript will have no complaints here. We can clearly see that `y`
is actually undefined. TypeScript version `4.1` introduced a compiler option
called `noUncheckedIndexedAccess`, which will change the behaviour to what
we would expect.

My new preferred way to do this is with the somewhat new `Array.at()`
method, which works well with typescript out of the box, without any additional
compiler options. With `Array.at()`, the following code won't compile, as desired.

```ts
const xs = [1, 2, 3]

const y: number = xs.at(10)
```

Thanks for reading and happy hacking!
