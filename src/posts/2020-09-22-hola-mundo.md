---
author: "Mi nombre"
authorTwitter: "@MiNombre"
desc: "Me anuncio al mundo"
image: "./images/waiheke-stony-batter.jpg"
keywords: "hola, anuncio"
lang: "es"
title: "¡Hola Mundo!"
updated: "2020-09-23T12:00:00Z"
---

¡Hola Mundo! ¡Estoy aquí!

<img
  alt="Grapevines among rolling hills leading to the sea"
  src="./images/waiheke-stony-batter.jpg"
  style="max-width:500px;"
/>

Haskell, por ejemplo:

```haskell
toSlug :: T.Text -> T.Text
toSlug =
  T.intercalate (T.singleton '-') . T.words . T.toLower . clean
```
