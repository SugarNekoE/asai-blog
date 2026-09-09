{-# LANGUAGE OverloadedStrings #-}

module Site.Views (PostInfo (..), article, copyButton, index, notFound) where

import Control.Monad (forM_)
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

data PostInfo = PostInfo
  { postTitle :: String,
    postDescription :: String,
    postDate :: String,
    postCategory :: String,
    postUrl :: String
  }

copyButton :: H.Html
copyButton = H.button ! A.type_ "button" ! A.class_ "code-copy" ! H.customAttribute "aria-label" "Copy code" ! H.customAttribute "aria-live" "polite" $ "Copy"

article :: PostInfo -> String -> H.Html
article info body =
  H.article ! A.class_ "prose" $ do
    H.a ! A.class_ "back" ! A.href "/" $ "← All notes"
    H.header ! A.class_ "article-header" $ do
      H.p ! A.class_ "eyebrow" $ H.toHtml $ "FIELD NOTE · " ++ postDate info
      H.h1 $ H.toHtml $ postTitle info
      H.p ! A.class_ "dek" $ H.toHtml $ postDescription info
    H.preEscapedToHtml body
    H.hr ! A.class_ "article-end-divider"
    H.p ! A.class_ "end-note" $ "End of file. Keep exploring."

index :: [PostInfo] -> H.Html
index posts = do
  H.header ! A.class_ "intro" $ do
    H.p ! A.class_ "eyebrow" $ "A PERSONAL KNOWLEDGE BASE"
    H.h1 $ do
      "Thinking in "
      H.em "systems."
      H.br
      "Writing in plain text."
    H.p $ do
      "Field notes on code, tools, and the things in between."
      H.br
      "A little less noise. A little more understanding."
  H.h2 "Latest notes"
  H.div ! A.class_ "post-list" $
    forM_ posts $ \info ->
      H.article ! A.class_ "post-row" $ do
        H.p ! A.class_ "post-date" $ H.toHtml $ postDate info
        H.div $ do
          H.h2 $ H.a ! A.href (H.toValue $ postUrl info) $ H.toHtml $ postTitle info
          H.p $ H.toHtml $ postDescription info

notFound :: H.Html
notFound =
  H.article ! A.class_ "prose" $ do
    H.p ! A.class_ "eyebrow" $ "ERROR 404"
    H.h1 "This path is unexplored."
    H.p $ do
      "The note may have moved. "
      H.a ! A.href "/" $ "Return to the index →"
