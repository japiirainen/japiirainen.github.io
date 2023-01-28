---
author: "Joona Piirainen"
desc: "I announce myself to the world"
keywords: "hello, announcement"
lang: "en"
title: "Hello, world!"
updated: "2020-09-22T12:00:00Z"
---

Hello, world! I am here!

Haskell, for example:

```haskell
toSlug :: T.Text -> T.Text
toSlug =
  T.intercalate (T.singleton '-') . T.words . T.toLower . clean
```
