---
author: "Joona Piirainen"
desc: "TODO"
keywords: "agda, monoids, algebra, functional-programming, dependent-types, monoid-homomorphisms"
lang: "en"
title: "Monoid homomorphisms"
date: "2023-08-07T12:00:00Z"
---

```agda
{-# OPTIONS --safe --guardedness #-}
module MonoidHomomorphisms where

open import Level
open import Data.List as List
open import Relation.Binary.PropositionalEquality using (refl; _≡_)

open import Monoids

private variable
  ℓ : Level
  A : Set ℓ
```

This post is in a WIP state

#### Definition

A homomorphisms between two monoids $(F,★)$ and $(T,∙)$ is a function $f : F \rightarrow T$
such that the following properties hold:

$$
f(ε_{F}) = ε_{T}
$$
$$
∀ x y ∈ F. f(x ★ y) = f(x) ∙ f(y)
$$

where $ε_{F}$ and $ε_{T}$ are the identity elements of $T$ and $F$ respectively.

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

want: combined length of all lists.

[1,2,3] , [4,5,6] , [7,8,9]

2 choices:

1. combine lists and take length
2. take length of each and then combine results

2 is much faster sine list concatenation *++* runs in $O(n)$ time. We be sure that these choices are equivalent exactly
because length is a *monoid homomorphisms* between `[]-monoid` and `+-0`!

```agda
length-homo : Monoid-Hom ([]-monoid {A = A}) +-0 List.length
ε-homo length-homo = refl
★-homo length-homo [] y = refl
★-homo length-homo (x ∷ xs) y rewrite ★-homo length-homo xs y = refl
```
