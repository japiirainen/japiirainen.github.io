---
title: Typesafe express routes
date: June 8, 2021
author: Joona
tags: haskell, lambda-calculus, combinatory logic, cartesian closed categories, bracket abstraction, graph reduction, Y-combinator, recursion, mutable references, ST-Monad, STRef
---

Recently I've spent a lot of time writing Haskell. In Haskell-land there's a lot of bleeding-edge research stuff, which is cool, but most likely not very applicable for my day-to-day work. If there's one thing that all haskellers love, it must be type-safety. That's what this post is about, bringing some type-safety to our node.js apps, more specifically express or koa apps. I'll try to point to some flaws I see in the typical way of writing express/koa apps with typescript and propose a "better" way.

## Motivating example

Let's start by defining routes we would like to implement. Suppose you are writing some CRUD operations for some "users" resource. We will use the following endpoint schema as an example.


```
GET /users     => Ok<[User]>
GET /users/:id => Ok<User> | NotFound
POST /users    => Ok | BadRequest
PUT /users/:id => Ok<User> | BadRequest | NotFound
```

The example endpoints will be using this interface for querying a "database". Implementation details of this interface are not relevant for this post. (There is a link at the end to a gist containing all the code in these examples.)

```ts
interface UsersRepo {
  all: () => Promise<User[]>
  findById: (id: number) => Promise<Option<User>>
  create: (name: string) => Promise<Id>
  update: (id: Id, update: { name: string }) => Promise<Option<User>>
}
```

### Let's write some express endpoints

Let's start with the "GET all users" and "GET user by id" endpoints.

```ts
app.get('/users', async (_req, res) => {
  const users = await usersRepo.all()
  return res.json(users).status(200)
})

app.get('/users/:id', async (req, res) => {
  const user = await usersRepo.findById(+req.params.id)
  if (isNone(user)) return res.status(404)
  return res.json(user.value).status(200)
})
```

The "GET all users" endpoint is not so bad. There's no risk for anything blowing up because of some type-error. The second endpoint is already starting to show some problems. By default request parameters captured by express is of type "string", which is bad for us since our database interface requires the user's id as a number. Nothing is validating that ***req.params.id*** is a number, so the conversion to number might throw. Also, nothing is checking that the id is even present in "req.params".

Next, we'll look at our POST and PUT endpoints. These start to show the issues I'm trying to highlight.

```ts
app.post('/users', async (req, res) => {
  const { name } = req.body // req bodys type is any. This line also throws if name is not present in req.body
  const id = await usersRepo.create(name)

  const user = await usersRepo.findById(id)
  if (isNone(user)) return res.status(404)
  return res.json(user.value).status(200)
})

app.put('/users/:id', async (req, res) => {
  const { id } = req.params // req.params is of type any. Also throws in case id is missing in req.params.
  const user = await usersRepo.update(+id, req.body) // same problem again with req.body
  if (isNone(user)) return res.status(404)
  return res.status(200).json(user.value)
})
```

I documented some of the problems with code comments. There are also some more nuanced issues I see here. Nothing is checking what status codes we are returning or validating checking that the JSON we are sending is of type User. We could return an elephant instead of a user and the type-system wouldn't notice a thing. These are not very big problems in this contrived example but I hope you get the point.

Let's consider the following change in our UsersRepo interface.


```ts
Interface UsersRepo {
  all: () => Promise<User[]>
  ...
}
// changes to  ⬇️

Interface UsersRepo {
  all: () => Promise<Option<User[]>>
  ...
}
```

So now for whatever reason, our all users action returns Option of User. What kind of type errors do we get? Is our code going to compile?

Unfortunately yes. Typescript says everything is fine. Hopefully, our test coverage catches these kinds of mistakes, but in my opinion, this should never get through the compilation step.

## How can we improve from this?

Luckily we are not doomed. There are better ways to do this. I will be using this awesome open-source library called typera. You can use it on top of either express or koa. I'm going to use it with express so I'll add "typera-express" to my package.json and add the following imports.

```ts
import { Route, Response, Parser, route, router } from 'typera-express'
```

Here is the "GET all users" endpoint rewritten with typera.

```ts
const users: Route<Response.Ok<User[]>> = route
  .get('/users')
  .handler(async () => Response.ok(await usersRepo.all()))
```

Compare it to the previous implementation. Do you see any improvements?

```ts
app.get('/users', async (_req, res) => {
  const users = await usersRepo.all()
  return res.json(users).status(200)
})
```

In this simple endpoint, the benefits are not huge, but there are some improvements. First of all, you can see what the endpoint is capable of returning, in this case, ***Response.Ok User***. Also, note the usage of ***Response.ok()*** instead of ***res.json().status(200)***. This makes our job easier since we don't need to think about the status codes we're returning, thus reducing the chance of us writing bugs.

Here's the "update user" endpoint rewritten with typera.

```ts
const updateUser: Route<
  Response.Ok<User> | Response.NotFound | Response.BadRequest<string>
> = route
  .put('/users/:id(int)')
  .use(Parser.body(t.type({ name: t.string })))
  .handler(async ({ body, routeParams: { id } }) => {
    const updatedM = await usersRepo.update(id, body)
    if (O.isNone(updatedM)) return Response.notFound()
    return Response.ok(updatedM.value)
  })
```

There's a lot going on, so let's break it down.
  
```ts
Route<Response.Ok User | Response.NotFound | Response.BadRequest string>
``` 
We list the possible return values of our endpoint.

```ts
put('/users/:id(int)')
```
This line is interesting. Typera calls these param conversions. Typera will validate that the "id" in query parameter is of type int and return BadRequest in the case this requirement is not met.
```ts
use(Parser.body(t.type({ name: t.string })))
```
This line takes care of request body validation. You can use any valid io-ts validation schemas with typera. If you are unfamiliar with io-ts, I highly recommend checking it out!

Now the handler function we get the validated and correctly typed request body and query parameters.
  
That's a huge improvement compared to the initial version. After embracing the power type-safety gives you, just looking at the initial version is giving me headaches. I know this toy example is not the perfect way to motivate you to introduce this complexity to your codebase since you start seeing the benefits when your application gets bigger and you need to start making changes. The point I'm trying to make is that I think static types and type-safety make your code better, cleaner, and most importantly more maintainable.
  
Hope you learned something from this post. Cheers!
  
#### Links
- [typera](https://github.com/akheron/typera)
- [example source of the typera version](https://gist.github.com/japiirainen/5061fd58d5a7d52f535fb053f99d3bc9)
- [my github](https://github.com/japiirainen)