---
title: Implementing parser combinators pt. 1
author: Joona
date: January 9, 2022
tags: haskell, parser-combinators, parsec, microparsec
---

One of the many strengts of haskell is the ability to easily embed other small languages (sometimes called EDSL, short for embedded domain specific language) inside it. One famous example of this is the family of libraries known as parser combinators. They aim to solve the task of parsing structured text into well-typed data-structures, and succeed in it quite beautifully. In this short series of blog posts I will show you how to implement a simple and usable parser combinator library. For real world use-cases you should propably just use [***megaparsec***](https://hackage.haskell.org/package/megaparsec).

# MicroParser

So now let's build own own toy parser combinator library! We will call it ***MicroParser***.

```haskell
{-# LANGUAGE DeriveFunctor #-}
module MicroParser where

import Control.Applicative (Alternative (..))
import Control.Monad (void)
import qualified Data.Char as Char
import Data.List (intercalate)
```

Let's start by thinking what the type of a parser should be? Structurally a parser is a function which takes an input stream of characters and yields a parse tree by applying the parsing logic over the input stream of characters to build up a composite data structure.

```haskell
data ParseResult
    = ParseSuccess !a !Int String
    | ParseFailure [(Int, String)]
    deriving (Functor, Show)

newtype Parser a 
    = Parser {unParser 
              :: Int
              -- ^ offset
              -> String
              -- ^ input stream of characters
              -> ParseResult a
              }
```

Our parser is polymorphic over the thing our parser should produce when successful. Internally our parser function takes an `Int` as it's first argument, which represents the position of the character we are currently parsing. This is useful for reporting errors. Other than that the type is relatively straight forward. Let's define a function for running a parser. 

```haskell
runParser :: Parser a -> String -> Either String a
runParser (Parser p) ts = case p 0 ts of
  ParseSuccess x _ _ -> Right x
  ParseError es ->
    Left $
      "Expecting "
        <> intercalate
          " OR "
          [ e <> " at position " <> show i
            | (i, e) <- es
          ]
```

Running a parser yields either a parse result when successful and an error message in the case of an error, which we represent here as a (somewhat) formatted string. In proper parser combinator libraries error handling is handled in more elegant and structured ways.

Now we have defined the basic structure of our library, but it is not very usable at this point. We have no convenient way of constructing parsers nor do we have any way of combining them. So clearly we need to do some more work. The power of parser combinators mostly come from the typeclass instances we define for our `Parser` type. Especially `Applicative` and `Alternative` in our case. Some parser combinator libraries encourage the usage of the syntactic sugar haskell provides for monads. We are not going to define a monad instance for our parser since we can do plenty without it.

To define `Applicative` and `Alternative` instances we need to first define `Functor` for out `Parser` type. Here is the `Functor` instance definition for our `Parser` type.

```haskell
instance Functor Parser where
    fmap f (Parser p) = Parser (\i ts -> fmap f (p i ts))
```

Now we can move on to the more interesting instances. Let's start with Applicative.

```haskell
instance Applicative Parser where
    pure x = Parser (ParseSuccess x)
    Parser a <*> Parser b =
        Parser
            ( \i ts ->
                case f i ts of
                  ParseError es -> ParseError es
                  ParseSuccess x i' ts' -> case g i' ts' of
                    ParseError es' -> ParseError es'
                    ParseSuccess x' i'' ts'' -> ParseSuccess (x x') i'' ts''
            )
```

This might be a bit intimidating if you are unfamiliar with `Applicative`. I'll not go through explaining `Applicatives` in detail here, since it's out of the scope of this blog post, but I highly suggest learning what they are and to start building an intuition on when you should use them. [Here](https://wiki.haskell.org/Typeclassopedia#Applicative) is a good starting point.

### Alternatives

Next we will define `Alternative`. Alternative is not as well known as typeclasses such as `Functor`, `Applicative` and `Monad` but are super useful for our use-case, so I think it's worth looking at them in a bit more detail.
The `Alternative` typeclass has four members including `empty`, `some`, `many` and most importantly for us `<|>`. Let's explore what `<|>` does. The `Maybe` data type is well known so I will use it for demostration purposes since most people know what it represents. For me the mental model for `<|>` is the following. "Try executing the left hand side function and if successful, return the result, otherwise return the result of calling the right hand side function". (This mental model happens to work for `Maybe`, but is not always correct since the operator can have different effects on other data types.)

```shell
ghci> Just 4 <|> Just 5
Just 4
ghci> Just 4 <|> Nothing
Just 4
ghci> Nothing <|> Just 4
Just 4
ghci> Nothing <|> Nothing
Nothing
```

But we are implementing parsers... how can we use this? Well we can express ***choice*** with it. Particulally we can think of it as saying "try parse this, then try parse this, then try parse this, and so on". This might sound a bit abstract at this point. But will become clear when we are finished!

```haskell
instance Alternative Parser where
  empty = Parser (\_ _ -> ParseError [])
  Parser f <|> Parser g =
    Parser
      ( \i ts ->
          case f i ts of
            success@ParseSuccess {} -> success
            ParseError errs0 -> case g i ts of
              success@ParseSuccess {} -> success
              ParseError errs1 -> ParseError (errs0 <> errs1)
      )
```

This instance definition actually follows the mental model quite clearly. "Run the first parser, if successful, return the results, otherwise run the second parser".

We are getting closer. Almost all the hard work is now done and we can move on to the fun part.

### Combinators

To wrap up the first part of this series of posts, we will define a fundamental combinator found in almost all of the parser combinator libraries, `satisfy`, and show a couple of use-cases for it. We will write `satisfy` in terms of a more general function called `satisfyMaybe`, which takes a description (used for error messages), a function from `Char` to a `Maybe` value indicating weather the character ***satisfies*** some condition or not.

```haskell
satisfyMaybe :: String -> (Char -> Maybe a) -> Parser a
satisfyMaybe descr p =
  Parser
    ( \i ts -> case ts of
        (t : ts') | Just x <- p t -> ParseSuccess x (i + 1) ts'
        _ -> ParseError [(i, descr)]
    )

satisfy :: String -> (Char -> Bool) -> Parser Char
satisfy descr p = satisfyMaybe descr (\t -> if p t then Just t else Nothing)
```

Once we have `satisfy` we can define various combinators based on it. We will start with one that parses any character, one that parses a ***specific*** character, one for parsing whitespace and finally one that parses a specific sequence of characters.

```haskell
anyChar :: Parser Char
anyChar = satisfy "any character" (const True)

char :: Char -> Parser ()
char c = void $ satisfy (show c) (== c)

spaces :: Parser ()
spaces = void $ many (satisfy "whitespace" Char.isSpace)

string :: String -> Parser ()
string [] = pure ()
string (x : xs) = char x *> string xs
```

Here's an example of how one might use these. Suppose we want to parse a key value pair into a `KV` data type.

```haskell
-- | example kaye value pair
text :: String
text = "key: value"

-- | Data type we would like parse the text into
newtype KV = KV (String, String) deriving (Show)
```

We can do this via the following parser. Here we leverage some of the combinators we defined previously. 

```haskell
pKv :: Parser KV
pKv = KV <$> parseKv
  where
    parseKv = (,) <$> many alpha <* char ':' <* spaces <*> many alpha
```

Admittedly this example is not the best one and doesn't show the full power of parser combinators. We need some additional combinators to gain more ***power*** to see what they are really capable of. But that is a challenge we will tackle in part 2 of this series of posts.

Thank you for reading, hope you enjoyed. Have a nice day, and until next time!
- Joona
