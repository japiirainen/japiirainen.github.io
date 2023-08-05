---
author: "Joona Piirainen"
desc: "Verified definition of monoids in agda and exploration of some cool monoids."
keywords: "agda, monoids, algebra, functional-programming, dependent-types"
lang: "en"
title: "Monoids are cool"
date: "2023-08-05T12:00:00Z"
---

It is common for an `Agda` module to begin with a bunch of module headers and imports, this one is no exception :-).

```agda
{-# OPTIONS --safe --guardedness --cubical-compatible #-}
module Monoids where

open import Level
open import Data.Nat using (_+_)
open import Relation.Binary.PropositionalEquality using (refl; _≡_)
```

One neat feature of `Agda` is it's `variable` blocks. They let you generalize over variables in types.
In practice a `variable` block let's you omit a bunch of detail from definitions since you can directly
use the variables defined in the `variable` block. I think this will make since once you see it in action.

```agda
variable
  ℓ : Level
  A : Set ℓ
```

```agda
level-of : {ℓ : Level} → Set ℓ → Level
level-of {ℓ} _ = ℓ

record is-semigroup (_★_ : A → A → A) : Set (level-of A) where
  field
    assoc : ∀ x y z → x ★ (y ★ z) ≡ (x ★ y) ★ z

record Semigroup (A : Set ℓ) : Set ℓ where
  infixl 5 _★_
  field
    _★_ : A → A → A
    has-is-semigroup : is-semigroup _★_

  open is-semigroup has-is-semigroup

-- look ma, terms in types
_ : 1 + 1 ≡ 2
_ = refl
```
