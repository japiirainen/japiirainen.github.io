---
author: "Joona Piirainen"
desc: "Verified definition of monoids in agda and exploration of some cool monoids."
keywords: "agda, monoids, algebra, functional-programming, dependent-types"
lang: "en"
title: "Monoids as a tool for writing composable and reusable programs"
date: "2023-08-05T12:00:00Z"
---

This time I'll ramble about `monoids`! The reason I like `monoids` is that they are
relatively simple mathemically, but immensly useful in programming. Every programmer has
used a number of `monoid` structures thruought their careers either knowingly or not. The goal
of this post is to show that using ideas from mathematics can be useful and even ***practical***.

I will use the `Agda` programming language / proof assistant to keep us honest. Mathematical
structures like `monoid` usually come equipped with a set of *properties* or *laws* that they
should obey, and the proof assistant capabilities of `Agda` let us precisely encode these *properties*.

This document is a typechecked literal `Agda` document. In fact all the definitions used in this module
are hyperlinks to their definitions. You can for example click the sumbol `Data.Nat.Properties` in the code block below to
see the *standard-library* module `Data.Nat.Properties`. It is common for an `Agda` module to begin with a bunch of module headers and imports,
this one is no exception :-).

```agda
{-# OPTIONS --safe --guardedness #-}
module Monoids where

open import Level renaming (suc to lsuc)
open import Function using (_∘_; id; flip; const)
open import Data.Nat using (_+_; _*_; _≤ᵇ_; ℕ)
open import Data.Nat.Properties using (+-assoc; +-identityˡ; +-identityʳ; *-assoc; *-identityˡ; *-identityʳ)
open import Data.Bool using (Bool; true; false; _∧_; _∨_)
open import Data.Bool.Properties using (∧-assoc; ∨-assoc; ∧-identityˡ; ∧-identityʳ; ∨-identityˡ; ∨-identityʳ)
open import Data.List using (List; _∷_; []; map; foldl; _++_; zip)
open import Data.List.Properties using (++-assoc; ++-identityˡ; ++-identityʳ)
open import Data.Product using (Σ; proj₁; proj₂; _,_; _×_)
open import Relation.Binary.PropositionalEquality using (refl; _≡_; sym)
```

One neat feature of `Agda` is it's `variable` blocks. They let you generalize over variables in types.
In practice a `variable` block let's you omit a bunch of detail from definitions since you can directly
use the variables defined in the `variable` block. I think this will make since once you see it in action.

```agda
private variable
  ℓ ℓ₂ : Level
  A : Set ℓ
  B : Set ℓ₂
```

If we look at the definition of a `monoid`, we will find that a `monoid` is a
`semigroup` with an *identity element*. From this it is reasonable to conclude that
we should first define what is a `semigroup`. Luckily `semigroups` are a relatively simple
structure.

### Semigroup definition

A semigroup is a *set* $S$ together with a *binary operation* $★$ that satisfies the
*associative property*.

$$
∀ x y z ∈ S. (x ★ y) ★ z = x ★ (y ★ z)
$$

To gain some intuition we should try to think of some examples. It can be difficult to gain insight to these often
quite abstract mathematical ideas without concrete examples. That is why I think it's a great idea to always try to
come up with some examples when you see one of these definitions. Some examples of `semigroups` from the top of my head
include the natural numbers with the addition ($+$) operation, or (ℕ,+). Natural numbers with multiplication ($*$) also
form a `semigroup`. You can veryfy in you head that the following equations hold.

$$
∀ x y z ∈ ℕ. (x + y) + z = x + (y + z)
$$
$$
∀ x y z ∈ ℕ. (x * y) * z = x * (y * z)
$$

Other examples include (String,++) where `++` is string concatenation, (List, ++) where `++` is list concatenation,
(Bool,∨) where `∨` means *or* and (Bool,∧) where `∧` means *and*.

Lets encode this in `agda`. The beautiful thing about `agda` is that the encoding is pretty much *1:1* to the math above.

```agda
level-of : {ℓ : Level} → Set ℓ → Level
level-of {ℓ} _ = ℓ

record is-semigroup (_★_ : A → A → A) : Set (level-of A) where
  field
    assoc : ∀ x y z → (x ★ y) ★ z ≡ x ★ (y ★ z)

record Semigroup (A : Set ℓ) : Set ℓ where
  infixl 5 _★_
  field
    _★_ : A → A → A
    has-is-semigroup : is-semigroup _★_

  open is-semigroup has-is-semigroup public
```

A couple of familiar `semigroups` to programmers are the `∧` and `∨` operators
from *boolean algebra*. We can show that they conform to our definition of a `semigroup`

```agda
∧-semigroup : Semigroup Bool
∧-semigroup = record { _★_ = λ x y → x ∧ y 
                     ; has-is-semigroup = record { assoc = ∧-assoc } }

∨-semigroup : Semigroup Bool
∨-semigroup = record { _★_ = λ x y → x ∨ y 
                     ; has-is-semigroup = record { assoc = ∨-assoc } }
```

Now that we have defined what it means to be a `semigroup`, we can graduate to
`monoids`. Lets recall the definition first.

### Monoid definition 

A monoid is a *set* $S$ together with a *binary operation* $★$ that satisfies the
following properties.

#### Associativity

$$
∀ x y z ∈ S. (x ★ y) ★ z = x ★ (y ★ z)
$$

#### Identity element

$$
∃ e ∈ S. ∀ x. e ★ a = a ★ e = a
$$

I again encourage you to think of examples, like we did after the `semigrou` definition.
Do you think the examples I gave of `semigroups` are also `monoids`?

Again, it is straight forward to translate this to `agda`.

```agda
record is-monoid (_★_ : A → A → A) (ε : A) : Set (level-of A) where
  field
    has-is-semigroup : is-semigroup _★_

  open is-semigroup has-is-semigroup public

  field
    identityˡ : ∀ x → ε ★ x ≡ x
    identityʳ : ∀ x → x ★ ε ≡ x

record Monoid (A : Set ℓ) : Set ℓ where
  infixl 5 _★_
  field
    ε : A
    _★_ : A → A → A
    has-is-monoid : is-monoid _★_ ε

  open is-monoid has-is-monoid public
```

We can show that `∧` and `∨` are `monoids`!

```agda
∧-monoid : Monoid Bool
∧-monoid = record { ε = true 
                  ; _★_ = _∧_ 
                  ; has-is-monoid = 
                    record { has-is-semigroup = Semigroup.has-is-semigroup ∧-semigroup
                           ; identityˡ = ∧-identityˡ
                           ; identityʳ = ∧-identityʳ } }

∨-monoid : Monoid Bool
Monoid.ε ∨-monoid = false
Monoid._★_ ∨-monoid = _∨_
is-monoid.has-is-semigroup (Monoid.has-is-monoid ∨-monoid) =
  Semigroup.has-is-semigroup ∨-semigroup
is-monoid.identityˡ (Monoid.has-is-monoid ∨-monoid) = ∨-identityˡ
is-monoid.identityʳ (Monoid.has-is-monoid ∨-monoid) = ∨-identityʳ
```

I'm using proofs such as `∨-identityʳ` from the `standard-library` to keep the length of
this post reasonable. Note that you can construct `records` in agda in two ways, which
are presented above. `∧-monoid` is defined using the `record` constructor syntax. `∨-monoid`
uses something called `copatterns`, which let's us define the fields of a record as separate
declarations in a similar way that we would give different cases for a function.

At this point you might not be convinced on the usefulness of all this. Let me try to change
that by showcasing a bunch of commonly used monoids and operations that can be built up from those.

A very common pattern when coding in a functional style is `mapping` followed by `folding`.
This pattern is also known as `MapReduce` in the distributed computing community. Let's see an example.

```
numbers : List ℕ
numbers = 1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ []

all≤5? : List ℕ → Bool
all≤5? = foldl _∧_ true ∘ map (_≤ᵇ 5)

any>10? : List ℕ → Bool
any>10? = foldl _∨_ false ∘ map (11 ≤ᵇ_)

_ : all≤5? numbers ≡ false
_ = refl

_ : any>10? (11 ∷ numbers) ≡ true
_ = refl
```

We can easily generalize this notion of `mapping` and then `folding` by a clever use
of the structure provided by a `monoid`.

```agda
foldMapList : ⦃ Monoid B ⦄ → (A → B) → List A → B
foldMapList ⦃ mon ⦄ f [] = ε
  where open Monoid mon
foldMapList ⦃ mon ⦄ f (x ∷ xs) = f x ★ foldMapList f xs
  where open Monoid mon

module _ where
  instance _ = ∧-monoid

  all? : (A → Bool) → List A → Bool
  all? = foldMapList

module _ where
  instance _ = ∨-monoid

  any? : (A → Bool) → List A → Bool
  any? = foldMapList

_ : all? (_≤ᵇ 5) numbers ≡ false
_ = refl

_ : any? (11 ≤ᵇ_) (11 ∷ numbers) ≡ true
_ = refl
```

Pretty neat? I think so! We can do other cool things too, we can for example
flatten nested lists.

```agda
[]-semigroup : Semigroup (List A)
Semigroup._★_ []-semigroup = _++_
is-semigroup.assoc (Semigroup.has-is-semigroup []-semigroup) = ++-assoc

[]-monoid : Monoid (List A)
Monoid.ε []-monoid = []
Monoid._★_ []-monoid = _++_
is-monoid.has-is-semigroup (Monoid.has-is-monoid []-monoid) =
  Semigroup.has-is-semigroup []-semigroup
is-monoid.identityˡ (Monoid.has-is-monoid []-monoid) = ++-identityˡ
is-monoid.identityʳ (Monoid.has-is-monoid []-monoid) = ++-identityʳ

module _ where
  instance _ = []-monoid

  flatten : List (List A) → List A
  flatten = foldMapList id

_ : flatten ((1 ∷ 2 ∷ []) ∷ (3 ∷ 4 ∷ []) ∷ []) ≡ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []
_ = refl
```

Or take sums and products. Excuse the mostly boring `semigroup` and `monoid` instance declarations.

```agda
+-semi : Semigroup ℕ
Semigroup._★_ +-semi = _+_
is-semigroup.assoc (Semigroup.has-is-semigroup +-semi) = +-assoc

+-0 : Monoid ℕ
Monoid.ε +-0 = 0
Monoid._★_ +-0 = _+_
is-monoid.has-is-semigroup (Monoid.has-is-monoid +-0) = Semigroup.has-is-semigroup +-semi
is-monoid.identityˡ (Monoid.has-is-monoid +-0) = +-identityˡ
is-monoid.identityʳ (Monoid.has-is-monoid +-0) = +-identityʳ

*-semi : Semigroup ℕ
Semigroup._★_ *-semi = _*_
is-semigroup.assoc (Semigroup.has-is-semigroup *-semi) = *-assoc

*-1 : Monoid ℕ
Monoid.ε *-1 = 1
Monoid._★_ *-1 = _*_
is-monoid.has-is-semigroup (Monoid.has-is-monoid *-1) = Semigroup.has-is-semigroup *-semi
is-monoid.identityˡ (Monoid.has-is-monoid *-1) = *-identityˡ
is-monoid.identityʳ (Monoid.has-is-monoid *-1) = *-identityʳ

module _ where
  instance _ = +-0

  sum : List ℕ → ℕ
  sum = foldMapList id

_ : sum numbers ≡ 21
_ = refl

module _ where
  instance _ = *-1

  product = foldMapList id

_ : product numbers ≡ 720
_ = refl
```

An interesting `monoid` is the `dual` of some other `monoid`.

```agda
module _ (mon : Monoid A) where
  open Monoid mon

  dual : Monoid A
  Monoid.ε dual = ε
  Monoid._★_ dual = flip _★_
  is-semigroup.assoc (is-monoid.has-is-semigroup (Monoid.has-is-monoid dual))
    x y z = sym (assoc z y x)
  is-monoid.identityˡ (Monoid.has-is-monoid dual) = identityʳ
  is-monoid.identityʳ (Monoid.has-is-monoid dual) = identityˡ

reverse : List A → List A
reverse = foldMapList ⦃ dual ([]-monoid) ⦄ (_∷ [])

_ : reverse numbers ≡ (6 ∷ 5 ∷ 4 ∷ 3 ∷ 2 ∷ 1 ∷ [])
_ = refl
```

Another example of a `monoid` built of other `monoids` is the *cartetesian product* or `_×_`.

```agda
module _ (ma : Monoid A) (mb : Monoid B) where

  open Monoid ⦃ ... ⦄

  instance
    _ = ma
    _ = mb

  ×-semigroup : Semigroup (A × B)
  (×-semigroup Semigroup.★ (a , b)) (a₁ , b₁) = a ★ a₁ , b ★ b₁
  is-semigroup.assoc (Semigroup.has-is-semigroup ×-semigroup) 
    (a₁ , b₁) (a₂ , b₂) (a₃ , b₃) rewrite assoc a₁ a₂ a₃ rewrite assoc b₁ b₂ b₃ = refl

  ×-monoid : Monoid (A × B)
  Monoid.ε ×-monoid = ε , ε
  (×-monoid Monoid.★ (a , b)) (a₁ , b₁) = a ★ a₁ , b ★ b₁
  is-monoid.has-is-semigroup (Monoid.has-is-monoid ×-monoid) =
    Semigroup.has-is-semigroup ×-semigroup
  is-monoid.identityˡ (Monoid.has-is-monoid ×-monoid) (a , b) 
    rewrite identityˡ a rewrite identityˡ b = refl
  is-monoid.identityʳ (Monoid.has-is-monoid ×-monoid) (a , b)
    rewrite identityʳ a rewrite identityʳ b = refl

module _ where
  instance _ = ×-monoid +-0 *-1

  sum×prod : List (ℕ × ℕ) → (ℕ × ℕ)
  sum×prod = foldMapList id

_ : sum×prod (zip numbers numbers) ≡ (21 , 720)
_ = refl
```

Up until now we have only worked on the `List` type. This is getting a bit boring and
redundant... On top of it being boring it might make you second guess the generality of
this approach. Can we only work on lists? As you might guess this is not the case!
We can define a more general structure `Foldable` and generalize this notion to arbitrary
data structures.

```agda
Foldable : {ℓ₁ ℓ₂ : Level} → (ℓᶠ : Level) → (Set ℓ₁ → Set ℓᶠ) → Set (lsuc ℓ₁ ⊔ lsuc ℓ₂ ⊔ ℓᶠ)
Foldable {ℓ₂ = ℓ₂} _ F = ∀ {A} {B : Set ℓ₂} → ⦃ Monoid B ⦄ → (A → B) → F A → B


foldableList : Foldable {ℓ} {ℓ₂} _ List
foldableList = foldMapList

module _ where
  instance _ = +-0

  length : List A → ℕ
  length = foldableList (const 1)

_ : length numbers ≡ 6
_ = refl
```

### Foldable binary trees

I claimed that we can `foldMap` over other structures than `List`. Let's define
a simple *binary tree* data structure and show that we can use the same machinery
on *binary trees* as we have been using on *lists*.

```agda
data BT (A : Set ℓ) : Set ℓ where
  empty : BT A
  branch : BT A → A → BT A → BT A

pattern leaf a = branch empty a empty

foldableBT : Foldable {0ℓ} {ℓ} 0ℓ BT
foldableBT ⦃ mon ⦄ f empty = ε
  where open Monoid mon
foldableBT ⦃ mon ⦄ f (branch l x r) =
  foldableBT f l ★ f x ★ foldableBT f r
  where open Monoid mon

tree : BT ℕ
tree = branch (branch (leaf 20) 30 (leaf 40)) 10 (leaf 50)

module _ where
  instance _ = +-0

  t-sum : BT ℕ → ℕ
  t-sum = foldableBT id

  size : BT ℕ → ℕ
  size = foldableBT (const 1)

_ : t-sum tree ≡ 150
_ = refl

_ : size tree ≡ 5
_ = refl
```

In fact at this point we have gained enough generality to turn any `Foldable` to a `List`!

```agda
toList : ∀ {ℓ F} → Foldable ℓ F → F A → List A
toList f = f ⦃ []-monoid ⦄ (_∷ [])

_ : toList foldableBT tree ≡ 20 ∷ 30 ∷ 40 ∷ 10 ∷ 50 ∷ []
_ = refl
```

I hope this write up convined you that `monoid` is a useful part of any programmers
toolkit. There's so much more to talk about `monoids`, but I think this is enough for now.

Thanks for reading and see you next time!
