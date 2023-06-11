---
author: "Joona Piirainen"
desc: "This is a test literate agda file."
keywords: "collaborative-text-editing ot operational-transformations agda"
lang: "en"
title: "Operational Transformations (OT)"
date: "2023-03-26T12:00:00Z"
---

This is a test literal agda file.

```
module OT where

open import Data.Nat using (ℕ; suc; _≤ᵇ_)
open import Data.Char using (Char)
open import Data.Bool using (Bool; true; false; _∧_; _∨_; if_then_else_)
open import Relation.Binary.PropositionalEquality
```

```
data Op : Set where
  ins : Char → ℕ → Op
  del : ℕ → Op
```

```
𝐓 : Op → Op → Op
𝐓 (ins c₀ i₀) (ins c₁ i₁) = if i₀ ≤ᵇ i₁ then ins c₁ (suc i₁) else ins c₁ i₁
𝐓 (ins c₀ i₀) (del i₁) = {! !}
𝐓 (del i₀) (ins c₁ i₁) = {! !}
𝐓 (del i₀) (del i₁) = {! !}
```

Let's image we have the following initial state of a text document: `bc`. At that point we want to apply two concurrent operations to this document.

```
_ : 𝐓 (ins 'a' 0) (ins 'd' 2) ≡ ins 'd' 3
_ = refl
```
