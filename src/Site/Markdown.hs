{-# LANGUAGE OverloadedStrings #-}

module Site.Markdown (articleHeadings, codeBlockToolbar, headingId, readerOptions) where

import Data.Maybe (fromMaybe, listToMaybe)
import qualified Data.Text as T
import Hakyll (defaultHakyllReaderOptions)
import Site.Bootstrap (Heading (..))
import Site.Views (copyButton)
import Text.Blaze.Html.Renderer.String (renderHtml)
import Text.Pandoc (Block (..), Extension (..), Format (..), Inline (..), Pandoc, ReaderOptions (..), enableExtension, readMarkdown, runPure)
import Text.Pandoc.Shared (stringify)
import Text.Pandoc.Walk (query)

readerOptions :: ReaderOptions
readerOptions =
  defaultHakyllReaderOptions
    { readerExtensions = enableExtension Ext_wikilinks_title_after_pipe (readerExtensions defaultHakyllReaderOptions)
    }

codeBlockToolbar :: Block -> Block
codeBlockToolbar block@(CodeBlock (_, classes, _) _) =
  let language = fromMaybe "text" $ listToMaybe $ filter (`notElem` ["numberLines", "lineAnchors", "sourceCode", "literate"]) classes
   in Div
        ("", ["code-block"], [])
        [ Div
            ("", ["code-toolbar"], [])
            [ Plain
                [ Span ("", ["code-language"], []) [Str language],
                  RawInline (Format "html") (T.pack $ renderHtml copyButton)
                ]
            ],
          block
        ]
codeBlockToolbar block = block

headingId :: T.Text -> T.Text
headingId heading = case runPure (readMarkdown readerOptions ("## " <> heading)) of
  Right doc -> case query (\block -> case block of Header _ (ident, _, _) _ -> [ident]; _ -> []) doc of
    ident : _ -> ident
    _ -> heading
  Left _ -> heading

articleHeadings :: Pandoc -> [Heading]
articleHeadings = query heading
  where
    heading :: Block -> [Heading]
    heading (Header level (ident, _, _) inlines)
      | level `elem` [2, 3] && not (T.null ident) = [Heading ident (stringify inlines)]
    heading _ = []
