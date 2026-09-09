---
title: "Types are a way to ask better questions"
description: "Before writing the implementation, make the possible states explicit. A small example of designing with algebraic data types."
date: 2026-09-05
tags: [haskell, systems]
status: published
---

The most useful part of a type often isn't what it lets you write. It's the question it forces you to answer.

## Name the states

Imagine a request represented by a Boolean and an optional value. What does `loading = True` with a result mean? Is it stale data, or a bug?

```haskell
data Remote a
    = NotAsked
    | Loading
    | Failed String
    | Loaded a
```

Now each state has a name. The rendering function has to decide what to do with each one.

## Design before implementation

This doesn't remove the need for judgment. A refreshing page might need to retain its previous value. If so, model that intentionally:

```haskell
data Refreshable a
    = Empty
    | Ready a
    | Refreshing a
    | RefreshFailed a String
```

The type becomes a compact design discussion. It is useful even before any code runs.

## Keep the boundary small

A type system cannot prove that your product is useful. It can help keep decisions consistent as the implementation grows. Start at the boundaries where ambiguity is expensive, then let the design follow the actual requirements.
