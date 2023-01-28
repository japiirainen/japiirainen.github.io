---
author: 'Joona piirainen'
desc: 'Testing Literate Agda'
keywords: 'agda, literate'
lang: 'en'
title: ', world!'
updated: '2023-01-23T12:00:00Z'
---

If you only care about how I did it, you can [click here to skip](#chosen-approach) all the rambling!

# Introduction

I've been playing around with [Agda](https://agda.readthedocs.io/en/v2.6.2/getting-started/what-is-agda.html) recently to get into dependent types and theorem proving. After making some progress, I wanted to capture my advances and document some concepts. I figured the best way to do this is by making some blog posts! A neat way of documenting code with prose is [literate programming](https://en.wikipedia.org/wiki/Literate_programming). Agda supports various forms of literate programming. I picked Markdown due to familiarity with the syntax.

This blog is statically generated with [Hakyll](https://jaspervdj.be/hakyll/). Under the hood, [Pandoc](https://hackage.haskell.org/package/pandoc) is used to transform the Markdown files into HTML. Markdown Literate Agda (`.lagda.md` files) mixes Agda code with Markdown and Pandoc is not able to convert the mix to HTML out of the box. So, I looked for a library that does the conversion and the integration into Hakyll.

# Existing Work

I'm obviously not the first person to try this, as both, Hakyll and Agda, are fairly old technologies.

## Library `hakyll-agda`

[`hakyll-agda`](https://hackage.haskell.org/package/hakyll-agda) looked promising. It is actively maintained and seemed to provide what I was looking for. However, the lack of documentation made it hard to explore and play around with. The reason I did not opt for this solution is because external Agda libaries, like the standard library, are not explorable in the generated code sections by clicking on them. Maybe I've made a mistake in my directory structure that causes this.

## Library `agda-snippets-hakyll`

[`agda-snippets-hakyll`](https://hackage.haskell.org/package/agda-snippets-hakyll) seemed to have the full functionality that I needed and also had a minimal example on how to use it. However, this library is deprecated in favor of the next approach listed. It also has the upper bound `hakyll (<4.10)`, which won't work with the latest Hakyll version.

## Agda Programmatically

[Agda is implemented in Haskell](https://hackage.haskell.org/package/Agda) and thus provides an interface to programmatically run actions. There is an API to generate HTML for a given Literate Agda file. Both of the aforementioned libraries use this API internally. [PLFA](https://plfa.github.io/), which has been ported to Hakyll, also seems to go this path. This seems to be the cleanest way to do it, but I was not ready to commit too much time to figure and iron out all the intricacies involved. That would mean less time to learn Agda! So, I also did not choose this approach, though, at some point, something [like this](https://github.com/plfa/plfa.github.io/blob/a9f85c9ab16c3a1dfe25c69e5d2cc883791c4bc9/hs/Hakyll/Web/Agda.hs#L59) is the end goal. In hindsight, the Agda Haskell API seems accessible enough to not have to spend too much time getting it to work.

# Chosen Approach

Continuing my search for a good enough, satisfactory solution, I stumbled upon [this blog post](https://jesper.sikanda.be/posts/literate-agda.html) by Jesper Cockx. In the last section of the post, he outlines his method to achieving what I set out to do. He also mentions a problem causing Hakyll's watch-mode to not work with his approach. The source code is included, which I liberally copy-pasted into my codebase.

To understand his approach and the rest of this blog post, I recommend reading his code. It pretty much calls the `agda` executable in Haskell as a process to transform `.lagda.md` directly into `.html` without calling Pandoc at all. Now there was only the problem of getting the watch-mode to work.

To fix it, I added this route match:

```haskell
match "agda-posts/*.lagda.md" $
  compile $ do
    ident <- getUnderlying
    unsafeCompiler $
      processAgdaPost $
        takeFileName $
          toFilePath ident
    makeItem (mempty :: String)
```

This creates a `Compiler a` in an "unsafe" way, meaning it performs an `IO` action circumventing the paradigm of mapping one input file to one output file, as described by Jesper Cockx in his blog post.

Upon editing a file matching the pattern, the underlying filename is passed to the `processAgdaPost` function, which comes from the aforementioned blog post. This action is executed immediately and an empty `Item` is returned. The purpose of this `Item` is usually to contruct the one to one correspondence between input and output file. In this case, it is simply a dummy `Item` and does nothing. This can be regarded as a bit of a hack, so I'm not fully happy with this solution.

Assembling all pieces gives this result, editable in watch-mode:

```agda
open import Agda.Builtin.Nat
open import Agda.Builtin.Equality

plus1 : (x : Nat) → x + 1 ≡ suc x
plus1 zero = refl
plus1 (suc x) rewrite plus1 x = refl
```

You can click on pretty much any non-keyword symbol and you will be taken to the definition. Try clicking on `Nat`!

## Caveat in the Chosen Approach

If you only add the code snippet above, there is still a problem with synchronization of your `agdaInputDir` and the actual site content. Let's say you remove files from `agdaOutputDir` manually and start Hakyll in watch-mode. Hakyll might first run the `copyFileCompiler` to copy your `.html` from `agdaOutputDir` to the site content before it runs `processAgdaPost` on all `.lagda.md` in `agdaInputDir`. In other words, it updates the site content with outdated stuff from `agdaOutputDir` and only afterwards is `agdaOutputDir` being synced up with `agdaInputDir`.

To fix this, I kept the initial `processAgdaPosts` call when Hakyll is started. This ensures that the site content is always up to date with `agdaInputDir`.

```haskell
hakyllMain :: IO ()
hakyllMain = do
  -- Initial Agda processing
  processAgdaPosts
  hakyllWith config $ do
  ...
```

The catch here is that, in some cases, the HTML generator is run twice in a row. This is very ugly and I plan on fixing it soon by switching to [this approach](#agda-programmatically).

There might be another solution, like making the route where the generated HTML is copied to the site content depend on the HTML generation step. This concept [seems to be a thing](https://hackage.haskell.org/package/hakyll-4.15.0.1/docs/Hakyll-Core-Dependencies.html) in Hakyll already, but I was not able to get it to work.

# Digging Myself a Hole

This section is not relevant to the solution, but I wanted to waffle a bit more about what I did. While the solution above is simple, I struggled quite a bit to find it and, instead, initially went down another path.

At first, I played around with `unsafeCompiler`. However, I could not get around the problem, that an `Item` had to be returned (the one to one mapping business). I just wanted to run an `IO` action.

After digging through the documentation, I found [`preprocess`](https://hackage.haskell.org/package/hakyll-4.15.0.1/docs/Hakyll-Core-Rules.html#v:preprocess). With this function, I could run the HTML generator as a preprocessing step. The problem was that, in watch-mode, this function would run if ANY file was edited. So, editing a file causes the `preprocess` step to run, which generates files in `agdaOutputDir`. Creating files, just like editing files, causes a rebuild in watch-mode. You might be able to guess what happens now: `preprocess` is being run AGAIN, causing an infinite loop. I was not able to avoid this infinite loop with the API that Hakyll provided at the time. So, I changed Hakyll's API.

I opened an [issue](https://github.com/jaspervdj/hakyll/issues/845) to allow certain directories to be ignored in watch-mode. This would allow me to ignore changes in `agdaOutputDir`, so `preprocess` could generate HTML freely into that directory without triggering a rebuild. After some back and forth, Minoru (a Hakyll maintainer, big thanks to them!) and I agreed on an API. I added a new field to the `Configuration` record taking a predicate. This predicate is called if a file is edited/created with the file path (relative to where Hakyll is being run). Something like this:

```haskell
config :: Configuration
config =
  defaultConfiguration
    { watchIgnore = ("_agda/**" ?==)
    }
```

If a file is now generated/edited in the `_agda` directory, this predicate will return `True`, making the watch-mode ignore it and not trigger a rebuild. `?==` comes from [`filepattern`](https://hackage.haskell.org/package/filepattern-0.1.2/docs/System-FilePattern.html#v:-63--61--61-).

This fixes the problem with `preprocess`, but it was a lot of effort for a solution I was not content with. Every file change still triggered the `agda` process, causing unnecessary rebuilds.

Then it dawned on me that I could make the `unsafeCompiler` version work by just returning an empty item. I did exactly that, was surprised it was so easy and realized my API change was not necessary to solve my problem. This open-source contribution to Hakyll was a nice little side effect of me digging a hole when I should've just taken a few steps back and re-evaluated my options. Oh well 🤷‍♂️.

### Update 12.10.2021

Fixed some typos, improved explanations.
