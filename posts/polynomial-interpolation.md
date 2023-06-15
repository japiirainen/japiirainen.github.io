---
author: "Joona Piirainen"
desc: "Existence & Uniqueness of polynomials"
keywords: "polynomials, math, haskell"
lang: "en"
title: "Polynomial interpolation"
date: "2023-06-11T12:00:00Z"
---

Hello you lovely people! :-) Today I woke up with a strange urge to play with polynomials. Specifically I wanted to represent polynomials in code, since I hadn't done that before.

## What is a *polynomial*?

I imagine most people have at least some vague memories of polynomials from high-school. At least I remember I hated them and
didn't understand what on earth would I ever do with them. I fear these kinds of memories from high-school math are quite common.
Despite these harsh memories in this episode I'll explore basic operations and theorems about polynomials.

**Definition**. A single variable *polynomial with a real coefficients* is a function $f$ that takes a real number as input, produces a real number as output and has the form

$$
f(x) = a_0 + a_1x + a_2x^2 + \cdot\cdot\cdot + a_nx^n,
$$

A good way to understand mathematical definitions is to write down plenty of examples. Here's a couple of examples.

$$ f(x) = 2 $$
$$ f(x) = 2 + 4x + x^2 $$
$$ f(x) = -8 + 3x + 9x^2 + 18x^3 $$

Syntactically a polynomial defines three things: a *polynomial with real coefficients* (the function *f*),
*coefficients* (the numbers $a_i$), and a polynomial's *degree* (the integer $n$).

### Polynomials as curves in the plane

For me the easiest way to understand the *meaning* of polynomials is via interpreting them
as curves in the plane. Polynomials (as any functions) can be represented as a set of pairs
called *points*. That is, if you take each input $t$ and pair it up with its output $f(x)$, you get a
set of tuples $(t, f(t))$, which can be plotted as a curve in space, so that the horizontal direction represents
the inputs and the vertical represents the output.

## Representation in code

We can represent a $polynomial$ in code as a list of numbers. I chose to also include the *indeterminate*,
which is just a fancy word for the $x$ in previous examples.

```hs
{-# LANGUAGE RecordWildCards #-}

module Polynomial where

import Data.List (intersperse, foldl')
import Data.Map (Map)
import Data.Bifunctor (bimap)
import Control.Monad (join)

import qualified Data.Map as Map
import qualified Data.Set as Set

data Polynomial = Polynomial
  { indeterminate :: Char
  , coefficients :: [Float]
  }

poly :: [Float] -> Polynomial
poly = Polynomial 'x'

zero :: Polynomial
zero = poly []

instance Show Polynomial where
  show Polynomial{..} = join $ intersperse " + " $
      map f (zip coefficients [0..])
    where
      f (coe, 0) = show coe
      f (coe, 1) = show coe <> pure indeterminate
      f (coe, idx) = show coe <> pure indeterminate <> "^" <> show idx
```

With this simple machinery we can construct and *"pretty print"* polynomials.

```hs
ghci> f = poly [1 2 3]
ghci> f
1.0 + 2x + 3x^3
```

## Addition and Multiplication of *polynomials*

I will walk throught these definitions in a very informal manner for brevity. Let's start by introducing two distinct polynomials.

$$
f(x) = 1 + 2x + 3x^2
$$

$$
g(x) = -8 + 17x + x^2 + 5x^3
$$

We can add these *polynomials* together. Addition of *polynomials* works basically as you would expect from
experience with adding numbers.

$$
f + x = -7 + 19x + 4x^2 + 5x^3
$$

Multiplication is a bit more complicated. [Here](https://www.mathsisfun.com/algebra/polynomials-multiplying.html)'s a nice exlanation on how one might think about polynomial multiplication.


$$
f \cdot x = -8 + 1x + 11x^2 + 58x^3 + 13x^4 + 15x^5
$$

Some basic properties of *polynomial* addition and multiplication.

$$
f + zero = f
$$

$$
zero + f = f
$$

$$
f + g = g + f
$$

$$
f \cdot 1 = f
$$

$$
1 \cdot f = f
$$

$$
f \cdot g = g \cdot f
$$

### *Polynomial* addition and multiplication in code

We can define addition of polynomials by recursively adding the matching $coefficients$.

```hs
polyadd :: Num a => [a] -> [a] -> [a]
polyadd [] ys = ys
polyadd xs [] = xs
polyadd (x:xs) (y:ys) = (x+y) : polyadd xs ys
```

Multiplication can be defined mostly by delegating work to previously defined `polyadd`.

```hs
polymult :: Num a => [a] -> [a] -> [a]
polymult ys = foldr (\x acc -> polyadd (map (x*) ys) (0 : acc)) []
```

Next we can define a `Num` instance for *polynomials* so we can use familiar notation. ($f + g$, $f * g$, ...)

```hs
(...) :: (c -> d) -> (a -> b -> c) -> a -> b -> d
(...) f g a b = f $ g a b
infixl 8 ...

coes :: (Polynomial, Polynomial) -> ([Float], [Float])
coes = (bimap coefficients coefficients)

instance Num Polynomial where
  (+) = poly . uncurry polyadd . coes ... (,)
  (*) = poly . uncurry polymult . coes ... (,)
  negate = poly . (map negate) . coefficients
  abs = poly . (map abs) . coefficients
  signum = poly . (map signum) . coefficients
  fromInteger x = poly (pure (fromInteger x))
```

Now we can imitate the math in Haskell!

```hs
ghci> f = poly [1, 2, 3]
ghci> g = poly [-8, 17, 1, 5]
ghci> f + g
-7 + 19x + 4x^2 + 5x^3
ghci> f * c
-8 + 1x + 11x^2 + 58x^3 + 13x^4 + 15x^5
```

## *Existence & Uniqueness*

Finally onto the main focus of this post, *existence & uniqueness* of *polynomials*.

**Theorem**. *For any integer $n \geq 0$ and any list of $n - 1$ points
$(x_1,y_1),(x_2,y_2),...,(x_{n+1},y_{n+1})$ in $\mathbb{R}^2$* with
$x_1 < x_2 < \cdot \cdot \cdot < x_{n+1}$ there exists polynomial $p(x)$ of
degree at most $n$ such that $p(x_i) = y_i$ for all $i$.

A more informal way to state the theorem: there is a unique degree $n$ polynomial
passing through a choice of $n + 1$ points. Let's start with examples (as one should). The simplest
example is $n = 0$, such that $n + 1 = 1$ and we are working with a single point. I'll pick
$(2, 3)$ as a random point. The theorem asserts that there is a unique degree zero polynomial passing through this point.
What function would yield $f(2) = 3$? Well there's no other choice but $f(x) = 3$. As a
slightly more complicated example we set $n = 1$ and thus $n + 1 = 2$ points, say $(2,3), (7,4)$.
Here the theorem claims a unique degree 1 polynomial $f$ with $f(2) = 3$ and $f(7) = 4$.

Let's recall what a degree 1 polynomial looks like.

$$
f(x) = a_0 + a_1x
$$

Write down the matching equations for our points $(2,3), (7,4)$.

$$
a_0 + a_1 \cdot 2 = 3
$$

$$
a_0 + a_1 \cdot 7 = 4
$$

If we solve for $a_0$ in the first equation, we get $a_0 = 3 - 2a$. Substituting
that into the second equation yields $(3 - 2a_1) + a_1 \cdot 7 = 4$, which solves
for $a = 1/5$. Substituting this back into the first equation gives $a_0 = 3 - 2/5$.
This forces the polynomial to be exactly

$$
f(x) = (3 - \frac{2}{5}) + \frac{1}{5}x = \frac{13}{5} + \frac{1}{5}x
$$

Thinking geometrically, a degree 1 polynomial is a line. The example above reinforces the fact
that there is a unique line between any two points.

### Working our way up to a proof.

If we want to prove these kinds of theorems we can't really pick specific points as we
did above. Instead we need to be more generic. Let's start from scratch and
start with a single point $(x_1, y_1)$ and set $n = 0$. This case is trivially $f(x) = y_1$.
Next up two points $(x_1, y_1), (x_2, y_2)$. We can write down the polynomial in this
rather strange way.

$$
f(x) = y_1\frac{x-x_2}{x_1-x_2} + y_2\frac{x-x_1}{x_2-x_1}
$$

If I evaluate $f$ at $x_1$, the second term gets $x_1 - x_1 = 0$ in the numerator
and so the second term is zero. The first term, however becomes $y_1\frac{x_1-x_2}{x_1+x_2}=y_1\cdot 1$
, which is what we wanted. Notice that we don't need to wory about $0/0$ since we have
explicitly disallowed $x_1 = x_2$. Likewise, if you evaluate $f(x_2)$ the first term is zero
and the second term evaluates to $y_2$. Thus we have both $f(x_1) = y_1$ and $f(x_2) = y_2$
and the expression is a degree 1 polynomial! The reason we wrote the polynomial in this
strange way is that each constraint (e.g. $f(x_1) = y_1$) could be isolated in its own term.
For three points we just have to maintain that same property.

$$
f(x) = y_1\frac{(x-x_2)(x-x_3)}{(x_1-x_2)(x_1-x_3)} +
       y_2\frac{(x-x_1)(x-x_3)}{(x_2-x_1)(x_2-x_3)} +
       y_3\frac{(x-x_1)(x-x_2)}{(x_3-x_1)(x_3-x_2)}
$$

The general formula for $n$ points should follow the same pattern. Add up
a bunch of terms, and for the $i$-th term you multiply $y_i$ by a fraction you
construct according to the rule: the numerator is the product of $x - x_j$ for every
$j$ except $i$, and the denominator is a product of all the $(x_i,x_j)$ for the same
$j$'s as the numerator.

$$
f(x) = \sum_{i=1}^{n} y_i \cdot \left( \prod_{j\neq i} \frac{x-x_j}{x_i-x_j} \right)
$$

Now we can proceed with our proof.

**Proof**. *Let $(x_1, y_1),...,(x_{n+1}, y_{n+1})$ be a list of $n + 1$ points with
no two $x_i$ the same. To show existence, construct $f(x)$ as*

$$
f(x) = \sum_{i=1}^{n+1} y_i \prod_{j\neq i} \frac{x-x_j}{x_i-x_j}
$$

Cleary the constructed polynomial $f(x)$ has degree at most $n$ because each term
has degree $n$. For each $i$, plugging in $x_i$ causes all but the $i$-th term in the
sum to vanish, and the $i$-th term evaluates to $y_i$ as desired.
To show uniqueness, let $g(x)$ be another polynomial that passes through the same
set of points given in the theorem. We will show that $f = g$. Examine $f - g$.
It is a polynomial with degree at most $n$ which has all of the $n - 1$ values $x_i$
as roots. We conclude that $f - g$ is the zero polynomial, or equivalently that $f = g$.
$\square$

Phew, math is hard...

### Now the same in code

```hs
type Point = (Float, Float)

singleTerm :: [Point] -> Int -> Polynomial
singleTerm points i = theTerm * poly [yi]
  where
    (xi, yi) = points !! i
    f acc (p, j) = if j == i then acc else
      let xj = (fst p) in acc * poly [-xj / (xi - xj), 1 / (xi - xj)]
    theTerm = foldl' f (poly (pure 1)) (zip points [0..])

-- | Return the unique polynomial of degree at most n passing through the given n+1 points.
interpolate :: [Point] -> Polynomial
interpolate [] = error "Must provide at least one point."
interpolate xs
  | length (map fst xs) > Set.size (Set.fromList (map fst xs)) = error "Not all x values are distinct."
  | otherwise = foldl' (+) zero terms
    where
      terms = map (singleTerm xs) [0..(length xs)-1]

```

The code basically mirrors the math described earlier, except for one place.
We had to break up the degree-1 polynomial $\frac{x-x_j}{x_i-x_j}$ into its
coefficients, which are $a_0 = \frac{-x_j}{x_1-x_j}$ and $a_1 = \frac{1}{x_i-x_j}$.

Some examples:


```hs
main :: IO ()
main = do
  let f = poly [1, 2, 3]
  -- ^ f(x) = 1 + 2x + 3x^2
  let g = poly [-8, 17, 1, 5]
  -- ^ g(x) = -8 + 17x + x^2 + 5x^3
  print $ interpolate [(1, 1), (2, 0)]
  -- ^ 2.0 + -1.0x
  print $ interpolate [(1, 1), (2, 4), (7, 9)]
  -- ^ -2.66665 + 4.0x + -0.3333333333333334x^2
```

Excuse the rounding errors :-)

Thanks for reading and see you next time!

The full code for this episode can be found [here](https://github.com/japiirainen/gists/blob/main/Polynomial.hs).
