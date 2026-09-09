{-# LANGUAGE OverloadedStrings #-}

import Control.Monad (filterM)
import Data.Aeson (Value, encode, object, (.=))
import qualified Data.ByteString.Lazy as BL
import Data.Maybe (fromMaybe, listToMaybe)
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Hakyll hiding (isExternal)
import System.FilePath (makeRelative, splitDirectories, takeBaseName, takeExtension, takeFileName)
import Text.Pandoc (Block (..), Extension (..), Inline (..), ReaderOptions (..), def, enableExtension, readMarkdown, runPure, writePlain)
import Text.Pandoc.Walk (query, walk, walkM)

main :: IO ()
main = hakyll $ do
  match "templates/*" $ compile templateBodyCompiler
  match "static/**" $ do
    route $ gsubRoute "static/" (const "")
    compile copyFileCompiler

  match "content/attachments/**" $ do
    route $ gsubRoute "content/" (const "")
    compile copyFileCompiler

  matchMetadata allPosts ((== Just "published") . lookupString "status") $ do
    route $ customRoute postRoute
    compile $ do
      _ <- postCategory =<< getUnderlying
      source <- getResourceBody
      parsed <- readPandocWith readerOptions source
      doc <- traverse (walkM resolveLink) parsed
      plain <- either (fail . show) (pure . T.unpack) $ runPure $ writePlain def $ itemBody doc
      _ <- makeItem plain >>= saveSnapshot "plain"
      pure (writePandocWith defaultHakyllWriterOptions $ fmap (walk codeBlockToolbar) doc)
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" (constField "page" "post" <> postCtx)

  create ["api/posts.json"] $ do
    route idRoute
    compile $ do
      posts <- loadPosts
      values <- mapM postJson posts
      makeItem $ T.unpack $ decodeUtf8 $ BL.toStrict $ encode $ object ["version" .= (2 :: Int), "posts" .= values]

  create ["index.html"] $ do
    route idRoute
    compile $ do
      posts <- loadPosts
      let ctx =
            listField "posts" postCtx (pure posts)
              <> constField "title" "Field notes"
              <> constField "description" "Notes on functional programming, small systems, and a quieter web."
              <> constField "page" "index"
              <> constField "category" ""
              <> constField "breadcrumb" "All Notes"
              <> defaultContext
      makeItem ("" :: String)
        >>= loadAndApplyTemplate "templates/index.html" ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx

  create ["404.html"] $ do
    route idRoute
    compile $
      makeItem ("" :: String)
        >>= loadAndApplyTemplate "templates/404.html" defaultContext
        >>= loadAndApplyTemplate
          "templates/default.html"
          ( constField "title" "Page not found"
              <> constField "description" "This path is unexplored."
              <> constField "page" "404"
              <> constField "category" ""
              <> constField "breadcrumb" "Page not found"
              <> defaultContext
          )

  create ["feed.xml"] $ do
    route idRoute
    compile $ do
      posts <- take 20 <$> loadPosts
      renderAtom feedConfig (bodyField "description" <> postCtx) posts

postRoute :: Identifier -> FilePath
postRoute ident = "posts/" ++ takeBaseName (toFilePath ident) ++ "/index.html"

postCategory :: Identifier -> Compiler String
postCategory ident =
  case splitDirectories (makeRelative "content/posts" (toFilePath ident)) of
    category : _ : _ -> pure category
    _ -> fail $ "Post must be inside a category folder: " ++ toFilePath ident

allPosts :: Pattern
allPosts = "content/posts/**.md"

publishedPosts :: Compiler [Identifier]
publishedPosts = filterM (\ident -> (== Just "published") <$> getMetadataField ident "status") =<< getMatches allPosts

loadPosts :: Compiler [Item String]
loadPosts = recentFirst =<< (mapM (\ident -> loadSnapshot ident "content") =<< publishedPosts)

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
        [ Div ("", ["code-toolbar"], []) [Plain [Span ("", ["code-language"], []) [Str language]]],
          block
        ]
codeBlockToolbar block = block

resolveLink :: Inline -> Compiler Inline
resolveLink (Link attr@(_, classes, _) label (target, linkTitle))
  | isExternal target = pure $ Link attr label (target, linkTitle)
  | "attachments/" `T.isPrefixOf` relativePath target = do
      url <- resolveAttachment target
      pure $ Link attr label (url, linkTitle)
  | "wikilink" `elem` classes && not (null extension) && extension /= ".md" = do
      url <- resolveAttachment target
      pure $ Link attr label (url, linkTitle)
  | "wikilink" `elem` classes || extension == ".md" = do
      url <- resolveNote target
      pure $ Link attr label (url, linkTitle)
  where
    extension = takeExtension $ T.unpack $ fst $ T.breakOn "#" target
resolveLink (Image attr@(_, classes, _) label (target, imageTitle))
  | not (isExternal target) && ("wikilink" `elem` classes || "attachments/" `T.isPrefixOf` relativePath target) = do
      url <- resolveAttachment target
      pure $ Image attr label (url, imageTitle)
resolveLink inline = pure inline

isExternal :: T.Text -> Bool
isExternal target = ":" `T.isInfixOf` target || "//" `T.isPrefixOf` target

relativePath :: T.Text -> T.Text
relativePath target = case T.stripPrefix "../" target of
  Just rest -> relativePath rest
  Nothing -> T.dropWhile (== '/') target

resolveAttachment :: T.Text -> Compiler T.Text
resolveAttachment target = do
  let (name, fragment) = T.breakOn "#" $ relativePath target
      matchesAttachment ident =
        if "attachments/" `T.isPrefixOf` name
          then toFilePath ident == "content/" ++ T.unpack name
          else takeFileName (toFilePath ident) == T.unpack name
  candidates <- filter matchesAttachment <$> getMatches "content/attachments/**"
  case candidates of
    [ident] -> do
      outputRoute <- getRoute ident
      maybe
        (fail $ "Attachment has no route: " ++ T.unpack target)
        (\url -> pure $ T.pack ('/' : url) <> fragment)
        outputRoute
    [] -> fail $ "Missing attachment (note transclusion is unsupported): " ++ T.unpack target
    _ -> fail $ "Ambiguous attachment; include its attachments/ path: " ++ T.unpack target

resolveNote :: T.Text -> Compiler T.Text
resolveNote target = do
  let (name, fragment) = T.breakOn "#" target
      base = takeBaseName $ T.unpack name
      anchor = if T.null fragment then "" else "#" <> headingId (T.drop 1 fragment)
  if T.null name
    then pure anchor
    else do
      ids <- publishedPosts
      case filter ((== base) . takeBaseName . toFilePath) ids of
        [ident] -> pure $ T.pack ("/" ++ postRoute ident) <> anchor
        [] -> fail $ "Wiki link targets a missing or unpublished note: " ++ T.unpack target
        _ -> fail $ "Ambiguous wiki link; use unique note filenames: " ++ T.unpack target

headingId :: T.Text -> T.Text
headingId heading = case runPure (readMarkdown readerOptions ("## " <> heading)) of
  Right doc -> case query (\block -> case block of Header _ (ident, _, _) _ -> [ident]; _ -> []) doc of
    ident : _ -> ident
    _ -> heading
  Left _ -> heading

postCtx :: Context String
postCtx =
  dateField "date" "%b %d, %Y"
    <> field "title" (escapedMetadata "title")
    <> field "description" (escapedMetadata "description")
    <> field "category" (fmap escapeHtml . postCategory . itemIdentifier)
    <> field "breadcrumb" (fmap escapeHtml . postCategory . itemIdentifier)
    <> defaultContext

escapedMetadata :: String -> Item a -> Compiler String
escapedMetadata key item = escapeHtml . fromMaybe "" <$> getMetadataField (itemIdentifier item) key

postJson :: Item String -> Compiler Value
postJson item = do
  let ident = itemIdentifier item
  title <- getMetadataField' ident "title"
  description <- getMetadataField' ident "description"
  tags <- getTags ident
  category <- postCategory ident
  date <- getItemUTC defaultTimeLocale ident
  plain <- loadSnapshotBody ident "plain" :: Compiler String
  url <- getRoute ident
  let minutes = max 1 ((length (words plain) + 219) `div` 220)
  pure $
    object
      [ "title" .= title,
        "description" .= description,
        "tags" .= tags,
        "category" .= category,
        "date" .= formatTime defaultTimeLocale "%Y-%m-%d" date,
        "url" .= ("/" ++ fromMaybe "" url),
        "readingMinutes" .= minutes,
        "searchText" .= plain
      ]

feedConfig :: FeedConfiguration
feedConfig =
  FeedConfiguration
    { feedTitle = "Asai Blog",
      feedDescription = "Notes on functional programming, small systems, and a quieter web.",
      feedAuthorName = "asai",
      feedAuthorEmail = "",
      feedRoot = "https://sne.moe"
    }
