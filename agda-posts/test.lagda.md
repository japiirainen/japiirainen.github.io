---
author: 'Joona piirainen'
desc: 'Testing Literate Agda'
keywords: 'agda, literate'
lang: 'en'
title: 'Hello, Agda!'
date: '2023-01-23T12:00:00Z'
---

```agda
open import Agda.Builtin.Nat
open import Agda.Builtin.Equality

plus1 : (x : Nat) → x + 1 ≡ suc x
plus1 zero = refl
plus1 (suc x) rewrite plus1 x = refl
```
