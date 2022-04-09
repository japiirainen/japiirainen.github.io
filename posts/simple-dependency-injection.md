---
title: Functional Dependency Injection
author: Joona
date: April 8, 2022
tags: typescript, node, dependency-injection, reader, monad, fp, functional-programming
---

Let's talk about functions! We all love functions, right? Well at least I do, I write tens of them every day! I have been a TypeScript programmer in my day job for the last 1,5 years, and would like to share some practices I have seen work, and others that.. well.. suck.

Today I want to talk about the problem of global configuration in a backend application.

## Global configuration

Typically you see global configuration represented as an ordinary object. When I say global configuration this can mean constants like port, host and also system wide dependencies such as a database connection or even some state, such as the currently active user.

```ts
type Config = {
  // configuration constants
  port: number;
  host: string;
  // so called "dependencies"
  db: { getUserByUserName: (userName: string) => Promise<User> };
  logger: { info: (s: string) => void };
  // state variables
  currentUserName: Option<string>;
};

const config: Config = {
  port: process.env.PORT ?? 3000,
  host: process.env.HOST ?? "localhost",
  db: { getUserByUserName: () => Promise.resolve({ name: "some user" }) },
  logger: { info: console.log },
  currentUserName: O.some("some user"),
};
```

The most naive and unfortunately the most common way to consume global dependencies is something along the lines of the following code snippet.

```ts
const fetchUserNaive = (): Promise<Option<User>> => {
  const { db, logger, currentUserName } = config;
  return pipe(
    currentUserName,
    O.fold(
      () => Promise.resolve(O.none),
      (userName) => {
        logger.info(`fetching user with userName: ${userName}`);
        return db.getUserByUserName(userName).then(O.some);
      }
    )
  );
};

const hasAuthNaive = (): boolean => O.isSome(config.currentUserName);
```

Why is this so bad you might ask. Well:

- Function inpurity:

  Pure functions (functions that only depend on it's input parameters and have no side-effects) are a lot easier to reason about and compose. Functions that read/manipulate global state are inherently impure. Yuk.

- Makes program state unpredictable:

  If a global configuration object is being used all over the application in a language that is not pure, there's no guarantee that the object is not being mutated. This implies that the program's behaviour can change radically from the global configuration getting mutated.

- Mocking in tests becomes hard:

  Providing different mock implementations for different tests is hard / error-prone.

- Concurrency issues:

  Not a problem in a single-threaded environment such as NodeJs, but anywhere else sharing mutable global state requires some kind of locking, which adds considerably more complexity to your code.

- Code comprehension:

  Code behaviour that depends on a lot of mutable global variables is hard to understand.

Luckily improving from this is relatively simple. Let me introduce you to...

## Function parameters

So the idea is to not depend on any values outside of our functions parameters, this forces us to list all of the dependencies the function has. When adapted to this style the previous code becomes:

```ts
const fetchUserParams = (cfg: Config): Promise<Option<User>> => {
  const { db, logger, currentUserName } = cfg;
  return pipe(
    currentUserName,
    O.fold(
      () => Promise.resolve(O.none),
      (userName) => {
        logger.info(`fetching user with userName: ${userName}`);
        return db.getUserByUserName(userName).then(O.some);
      }
    )
  );
};

const hasAuthParams: (currentUserName: Option<string>) => boolean = O.isSome;
```

Ahh, this is so much better. But why..., well let's see what kind of improvements we get to the list of issues from before.

- Function inpurity:

  The purity of this function is now dependent on what `db.getUserByUserName` does. We can assume that it queries the database and thus is impure. But we have eliminated the impurities that were caused by depending on values outside of the functions paramers.

- Global shared state Makes program state unpredictable:

  We are no longer using global shared state.

- Mocking in tests becomes hard:

  It suddenly became easy.

- Concurrency issues:

  No longer a problem.

- Code comprehension:

  Readibility increases significantly, when you can see the dependencies of the functions from it's type signature (parameters in this case).

### Is this dependency injection?

Pretty much, it is a really basic application of dependency injection or inversion of control for backend development. Especially in a functional language or style we don't normally talk about dependency injection. But the idea is the same. In fact this kind of pattern in functional programming has been noticed a long time ago. We can abstract over passing configuration to our functions with the `Reader` data type.

```ts
const fetchUserReader: Reader<Config, Promise<Option<User>>> = pipe(
  R.ask<Config>(),
  R.map(({ currentUserName, db, logger }) =>
    pipe(
      currentUserName,
      O.fold(
        () => Promise.resolve(O.none),
        (userName) => {
          logger.info(`fetching user with userName: ${userName}`);
          return db.getUserByUserName(userName).then(O.some);
        }
      )
    )
  )
);

// This is a bit silly, I would probably leave this to the version without the reader
const hasAuthReader: Reader<Pick<Config, "currentUserName">, boolean> = pipe(
  R.ask<Pick<Config, "currentUserName">>(),
  R.map(({ currentUserName }) => O.isSome(currentUserName))
);
```

Without going to the detail you can think of the `Reader<Config, string>` as an abstraction for the following function `(config: Config) => string`. So it's just a function in disquise!

This is a bit silly in this context, since the example is so simple but in principle here's a couple of reasons you might consider the `Reader` data type.

- Abstracting over function parameters can be useful to avoid the issue of passing the configuration object to every function as a parameter.
- It can make code more readable. Goes kind of hand in hand with the previous point. (readibility is in the eye of the reader ;-))

Personally I propably wouldn't introduce the `Reader` monad in a client project, since it can scare some people off and doesn't bring enought benefits in the context of TypeScript to justify the costs (complexity, well again it's in the eye of the reader).

### Footnotes:

- The `Option` and `Reader` data types I used in this post are from [fp-ts](https://github.com/gcanti/fp-ts).

- If you want to see how `Reader` is used in haskell and other similar languages here is the blog post that introduced the [`ReaderT`](https://www.fpcomplete.com/blog/2017/06/readert-design-pattern/) pattern.
