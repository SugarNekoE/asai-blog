{-# LANGUAGE OverloadedStrings #-}

module Site.Markdown (codeBlockToolbar, headingId, headingsJson, readerOptions) where

import Data.Aeson (Value, encode, object, (.=))
import qualified Data.ByteString.Lazy as BL
import Data.Maybe (fromMaybe, listToMaybe)
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8)
import Hakyll (defaultHakyllReaderOptions)
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

headingsJson :: Pandoc -> String
headingsJson = T.unpack . T.replace "<" "\\u003c" . decodeUtf8 . BL.toStrict . encode . query heading
  where
    heading :: Block -> [Value]
    heading (Header level (ident, _, _) label)
      | level `elem` [2, 3] && not (T.null ident) = [object ["id" .= ident, "label" .= stringify label]]
    heading _ = []
