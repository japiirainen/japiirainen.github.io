---
author: "Joona Piirainen"
desc: "Attempting to shed light on the confusion about 'dynamic' type systems."
keywords: "types, programming-lanugages, javascript, python, haskell"
lang: "en"
title: "There are no dynamic type systems"
date: "2024-07-26T14:37:00Z"
---

I'm writing this, since I see even the most senior developers confused about the distinction
between the so called "dynamic" and static programming languages.
I will argue that there are no such thing as a dynamic type system.
What people typically think of as programming languages with a "dynamic" type system,
such as [python](https://www.python.org/) and [javascript](https://nodejs.org)
are actually nothing but a very special case of a language with a static type system.
If you already understand this, the post you're reading will most likely not
provide you with any new information, but if the first paragraphs seem like nonsense
to you, let's see if I can get the point through!

## One type to rule them all

Advocates of dynamic languages will try to sell you on the idea that the dynamic nature
of the language will give you *freedom*, since you don't have to think about types,
and that the static languages slow you down and force you to "fight" with the compiler.

So what's actually going on when working in a "dynamic" language? Well, in a "dynamic"
language values can be of a variety of classes, and can be distinguished from each
other at run-time. This allows the programmer to handle the different classes of values
when writing business logic. When looking at the situation from the perspective of a type systems,
all values of the language are of a *single type*.

Instead of giving you *freedom*, the language *restricts* you to
program with a *single*, *massive* type. Every single value is of that type.
What this *restriction* entails, is that the programmer has no way to enforce invariants.
Even if one is sure that a variable is of type `int` at a point
of time in the programs execution, it is impossible to enforce this fact.
Of course these languages give you tools to check the "tag" of a given variable during runtime.

```python
if instanceof(x, int):
  ...

# or

if type(x) is int:
  ...
```

You can of course combine these checks with assertions, but this is not the same thing
since these checks happen at *run-time*.

## Why the confusion?

This is mostly speculation, but I think the general dislike towards type systems
and the huge popularity of languages like python and ruby might be due to the lack of
expressive power found in type systems of mainstream statically typed languages like
java, c#, c++ and others. I sympathise with this, but it's an argument against bad
languages, not statically typed ones.

Thanks for reading and happy hacking!
