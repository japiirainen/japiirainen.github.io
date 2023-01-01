---
title: "My First Post"
date: 2023-01-01T16:38:27+02:00
tags:
  - hello
  - hugo
---

## Introduction

This is **bold** text, and this is *emphasized* text.

<tex>
$$
\begin{aligned}
&\mathbf{h}_{\mathcal{N}(v)}^k=\operatorname{\small{AGGREGATE}}_k(\big\{\mathbf{h}_u^{k-1},\ u\in\mathcal{N(v)}\big\})
\newline
&\mathbf{h}_v^k=\sigma(\mathbf{W}\cdot\operatorname{\small{CONCAT}}(\mathbf{h}_v^{k-1},\ \mathbf{h}_{\mathcal{N}(v)}^{k}))
\end{aligned}
$$
</tex>

```haskell
main :: IO ()
main = putStrLn "Hello, Hugo!"
```

```agda
data Nat : Set where
    zero : Set
    suc  : Set -> Set
```

Visit the [Hugo](https://gohugo.io) website!
