---
title: "From plain text to a small, personal web"
description: "A notebook, a compiler, and a little Elm. Building a home for ideas without losing the simplicity of a text file."
date: 2026-09-08
tags: [haskell, elm, web]
status: published
---

A personal website can be a quiet piece of software. A directory of notes goes in; a directory of pages comes out. Everything else should earn its place.

This is a starter note for the notebook you're reading. It also describes the system underneath it.

## One source, two outputs

Markdown is the source of truth. Hakyll reads a note, Pandoc turns it into a document, and the build produces both a complete HTML page and a searchable JSON record.

```haskell
compile $ do
    source <- getResourceBody
    document <- readPandocWith readerOptions source
    pure (writePandocWith defaultHakyllWriterOptions document)
        >>= saveSnapshot "content"
```

The HTML is already readable when it arrives. The JSON contains metadata and plain text for the notebook's search. There is no Markdown parser running in the browser.

## A small interactive layer

Elm handles the explorer, topic filters, search, ordering, and theme preference. Its model is deliberately ordinary:

```elm
type alias Model =
    { query : String
    , tag : String
    , oldest : Bool
    }
```

Article navigation follows real links to real pages. That means refresh, bookmarks, browser history, and opening a note in another tab work naturally.

> A good tool makes the simple path feel complete.

## Keep the build disposable

The generated directory can be deleted and rebuilt at any time. The notes remain useful outside the site: in Obsidian, in a terminal, or in a different publishing system years from now.

![[attachments/pipeline.svg]]

The writing workflow is described in [[a-notebook-that-stays-yours|A notebook that stays yours]]. The design follows the same rule as the content: use [[a-quieter-interface|a quieter interface]] to make room for the work.
