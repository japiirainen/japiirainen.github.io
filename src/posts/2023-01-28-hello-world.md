---
author: "Joona Piirainen"
desc: "I announce my blog to the world"
keywords: "hello, announcement"
lang: "en"
title: "Hello, world!"
updated: "2023-01-23T12:00:00Z"
---

Hello, world!

This is the start of my new blog.

See you when I actually publish some content!

```haskell
id :: forall a. a -> a
id = \x -> x
```

```agda
open import Agda.Builtin.Nat
open import Agda.Builtin.Equality

plus1 : (x : Nat) → x + 1 ≡ suc x
plus1 zero = refl
plus1 (suc x) rewrite plus1 x = refl
```