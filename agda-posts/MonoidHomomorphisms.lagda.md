---
author: "Joona Piirainen"
desc: "Exploring structure-preserving maps between monoids."
keywords: "agda, monoids, algebra, functional-programming, dependent-types, monoid-homomorphisms"
lang: "en"
title: "Monoid Homomorphisms"
date: "2023-08-07T12:00:00Z"
---

In the [previous](./Monoids.html) had a brief exploration in the land of `monoids`. Today I would like to continue from where we left off.

Previously we defined the meaning of a `monoid` and saw a bunch of examples. Now we will consider how monoids interact with each other,
or weather they do at all? In particular we are interested in finding these things mathematicians like to call *homomorphisms* or
*structure-preserving maps*. Basically these are just *maps* between some algebraic structure such as a `monoid` or a `vector space`
that behave *nicely*. We will soon see what exactly *nicely* means in the context of `monoid homomorphisms`.

Let's get the usual `Agda` boilerplate out of our way.

```agda
{-# OPTIONS --safe --guardedness #-}
module MonoidHomomorphisms where

open import Level
open import Data.List as List
open import Relation.Binary.PropositionalEquality using (refl; _≡_)

-- from previous post
open import Monoids

private variable
  ℓ : Level
  A : Set ℓ
```

Now we must define what exactly it means for a *map* between two `monoids` to behave *nicely*.

### Definition

A homomorphisms between two monoids $(F,★)$ and $(T,∙)$ is a function $f : F \rightarrow T$
such that the following properties hold:

$$
f(ε_{F}) = ε_{T}
$$

$$
\forall x y ∈ F. f(x ★ y) = f(x) ∙ f(y)
$$

where $ε_{F}$ and $ε_{T}$ are the identity elements of $T$ and $F$ respectively.

The first property says that the function $f$ should *preserve* identities. The second one says that
it doesn't matter in which order you apply the function $f$ related to the *multiplication* of the `monoids`.

Now we can encode this structure in `Agda`.

```agda
record Monoid-Hom 
       {ℓ₁ ℓ₂ : Level} {F : Set ℓ₁} {T : Set ℓ₂}
       (a : Monoid F) (b : Monoid T) (f : F → T) : Set (ℓ₁ ⊔ ℓ₂) where
  private
    module From = Monoid a
    module To = Monoid b

  field
    ε-homo : f From.ε ≡ To.ε
    ★-homo : ∀ (x y : F) → f (x From.★ y) ≡ f x To.★ f y

open Monoid-Hom
```

### Example

Suppose you need to write a program to find the total `count` of elements from a large collection of `lists`.

E.g. find the total count of elements from the following lists.

```python
[1,2,3] , [4,5,6] , [7,8,9] , [10,11,12] , ...
```

I can think of two different approaches to this problem:

1. Combine all lists to a single list and take count of this list.
2. Take the count of each list and the sum these counts together.

These approaches *should* lead to the same result, but are computationally quite different.
One of these approaches starts to sound a lot nicer once you realize that list concatenation runs
in *linear* $O(n)$ time. This would lead to a *quadratic* algorithm since we would be concatenating
a linear number of lists! After this realization we conclude we should first find the counts of all
the lists and the add these counts together. But how can we be sure we will end up with the same result?
After all these two algorithms are very dirrefent computationally. Well it turns out that we can be sure
that these algorithm choices are equivalent because `length` is a `monoid homomorphisms` between `[]-monoid` and `+-0`!

```agda
length-homo : Monoid-Hom ([]-monoid {A = A}) +-0 List.length
ε-homo length-homo = refl
★-homo length-homo [] y = refl
★-homo length-homo (x ∷ xs) y rewrite ★-homo length-homo xs y = refl
```

This example showed how one can use `monoid homomorphisms` as a way to find equivalent ways to
perform a computation. This is important because in many cases these different ways can drastically
differ in their *time and space complexities*.

This is all I had in mind for today, I hope you found `monoid homomorphisms` interesting or even ***useful***.

Thanks for reading and see you next time!
