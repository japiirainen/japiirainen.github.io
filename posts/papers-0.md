---
author: "Joona Piirainen"
desc: "John backus Turing Award Lecture 1978."
keywords: "functional-programming, pl, turing-award, John Backus, fp"
lang: "en"
title: "Influential papers #0"
date: "2023-01-30T12:00:00Z"
---

This is the first episode of a (hopefully) long and fruitful series of posts where I go through academic papers that have been influential for me. I speculate most of these will touch the field of computer science in some form. I guess we will see. The idea is not to repeat what is in the papers, but rather give a small taste of what they are about, and why I think they are worth reading. Without further ado, lets get started with episode #0.

## Can programming be liberated from the von Neumann style?: a functional style and its algebra of programs

[This](https://dl.acm.org/doi/10.1145/359138.359140) paper is a lecture given by John Backus at the 1978 ACM Turing Award ceremony. In case you're unfamiliar, the ACM Turing Award is an annual price given by the [Association for Computing Machinery (ACM)](https://en.wikipedia.org/wiki/Association_for_Computing_Machinery). It is generally recognized as the highest distinction in computer science, and can be referred to as the "Nobel Prize of Computing". Overall the paper is a very interesting read, and I highly recommend it to anyone interested in the history of programming languages and functional programming. The paper is not very long or too technical, so it should be accessible to most people. The impact this paper has had on the design of many modern programming languages, especially in the [ML](https://en.wikipedia.org/wiki/ML_(programming_language)) family like Haskell and OCaml is amazing.

## What is the paper about?

Backus basically describes an alternative way of programming, which he calls the "applicative style". This style is in many ways similar to what is nowadays called "pure functional programming", although Backus took the idea even further and made it impossible to name function arguments, which leads to a style more commonly known as "point-free" programming. The paper also contains a section on the "algebra of programs", which is an important topic in its own right. In my opinion the field of programming is still in it's infancy in terms of mathematical rigor, and the algebra of programs is a step in the direction of more correct and rigorously defined programs. This is a topic close to my heart, and I will probably write more on it in the future.

## Bashing the von Neumann style

Backus writes in a very direct and almost condescending way about the current state of programming languages. He writes:


> Conventional programming languages are growing ever more enormous, but not stronger. Inherent defects at the most basic level cause them to be both fat and weak: their primitive word-at-a-time style of programming inherited from their common ancestor–the von Neumann computer, their close coupling of semantics to state transitions, their division of programming into a world of expressions and a world of statements, their inability to effectively use powerful combining forms for building new programs from existing ones, and their lack of useful mathematical properties for reasoning about programs.

Remember that this is from *1978*, and yet it still feels very relevant today. Maybe even more relevant now, since most widely used languages today are *huge* and way bigger than the languages Backus was referring to.

## My implementation

After reading the paper I decided to implement the language described in it. It is fully open source, and can be found [here](https://github.com/japiirainen/fp). The GitHub repo contains a bunch of examples, many of which are from the paper itself. I will leave a small taste of the style described by Backus here in case it will inspire you to read the paper.

```haskell
{- Implementation of the Matrix Multiplication algorithm.
-}

Def ip ≡ /+∘α*∘⍉

Def mm ≡ α(α ip) ∘ α distl ∘ distr ∘ [~0, ⍉∘~1]

mm:< < <1,2>, <4,5> >,
     < <6,8>, <7,9> > >
```

Until next time!
