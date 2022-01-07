---
title: Thoughts on Clojure λ
date: January 8, 2022
author: Joona
tags: clojure, aoc, adventofcode, functional-programming
---

2021 was the first year I participated in [**AdventOfCode**](https://adventofcode.com/), which is the worlds largest programming contest. I solved the 2021 puzzles in Haskell and Python. Doing AOC puzzles became a habit I enjoyed, so I couldn't stop on the 25th of december, and started solving the year 2015. I do AOC puzzles to improve my general problem solving skills, but they are also a convenient place to learn new programming languages! So obviously (if you read the title) I chose Clojure for the year 2015. In this post I'd like to summarize my thoughts on the language after solving all 25 problems using it.

## The Good

### Surprisingly easy to pick up
This was the first time writing in any of the lisp-family programming languages. Surprisingly, the learning curve wasn't too bad. After a couple of days I felt quite comfortable writing clojure code. Being able to pick up a language quickly is a positive thing for sure!

### Standard library
Clojure standard library was great and felt polished. Especially enjoyed the data-structures provided.

### Threading macros
I'm talking about these guys.

Thread-last. This was the variant I used 90% of the time. Don't know if this is idiomatic, but I guess this is the way I think about the data flowing in programs.
```clojure
(->> [1 2 3] (map inc) (reduce +)) ;; => 8
```

Thread-first. Didn't use this variant too much, but useful for chaining functions that take data as the first argument. (Personally don't know why everything is not data last??)
```clojure
(map #(-> % (str/split #": ") (nth 1) read-string) "foo: 123") ;; => 123
```

### REPL
Being able to develop API's using the REPL was nice.

### Docs
[***clojuredocs***](https://clojuredocs.org/) were nice and had comprehensive and easy to follow examples.

## The bad

### Error messages
When you got an exception the top most call site would be reported, not where the actual exception occurred. How is that a thing?

### Getting my development environment setup
This was a pain. I tried using vscode with [***calva***](https://calva.io/), but gave up pretty soon after starting. Ended up using emacs with [***cider***](https://cider.mx/), which was pretty nice, but had a huge learning curve for me since I'm not an emacs user. (Maybe I am after this...)

### Dynamic nature of lisps
I'm a believer of strong static types, and using clojure made me have even stronger opinions on the matter. Dynamic typing combined with the error messages was honestly terrible at times. This is probably the biggest reason I will likely not return to writing in clojure (at least if I don't have to).

## Summary
Overall Clojure was an OK language despite the gripes I have with it. Initially I was steered to trying it since it seems to be kind of popular here in Finland and I wanted to see if I would like to write it professionally at some point (I don't.. At least for now). I honestly have no idea if the code I wrote was idiomatic Clojure code or not (probably not). I will link the repo below and please tell me if it was the way I was using the language that made me not enjoy it more than I did.

[***Code on Github***](https://github.com/japiirainen/aoc-2015)
