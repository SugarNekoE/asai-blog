{-# LANGUAGE OverloadedStrings #-}

module Site.Page (index, notFound, post, render) where

import Control.Monad (forM_)
import qualified Site.Bootstrap as Bootstrap
import Text.Blaze.Html.Renderer.String (renderHtml)
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

data Metadata = Metadata
  { title :: String,
    description :: String,
    kind :: String,
    category :: String,
    breadcrumb :: String
  }

index :: Metadata
index = Metadata "Asai Blog" "Asai's FP designed SSG blog page" "index" "" "All Notes"

notFound :: Metadata
notFound = Metadata "Page not found" "This path is unexplored." "404" "" "Page not found"

post :: String -> String -> String -> Metadata
post name summary folder = Metadata name summary "post" folder folder

render :: Metadata -> [Bootstrap.Heading] -> H.Html -> String
render metadata headings content = renderHtml $
  H.docTypeHtml ! A.lang "en" ! H.customAttribute "data-theme" "dark" $ do
    H.head $ do
      H.meta ! A.charset "utf-8"
      H.meta ! A.name "viewport" ! A.content "width=device-width, initial-scale=1"
      H.meta ! A.name "color-scheme" ! A.content "dark light"
      H.title $ H.toHtml $ if kind metadata == "index" then title metadata else title metadata ++ " · Asai Blog"
      H.meta ! A.name "description" ! A.content (H.toValue $ description metadata)
      H.link ! A.rel "icon" ! A.href "/assets/favicon.svg" ! A.type_ "image/svg+xml"
      H.link ! A.rel "alternate" ! A.type_ "application/atom+xml" ! A.title "Asai Blog" ! A.href "/feed.xml"
      forM_ ["noto.css", "fonts.css", "colors.css", "base.css", "loading.css", "article.css"] $ \file ->
        H.link ! A.rel "stylesheet" ! A.href (H.toValue $ "/assets/" ++ file)
      H.link ! A.rel "stylesheet" ! A.href "/assets/print.css" ! A.media "print"
      H.script ! A.src "/assets/theme.js" $ mempty
      H.script ! A.src "/assets/loading.js" $ mempty
      H.script ! A.defer "" ! A.src "/assets/elm.js" $ mempty
      H.script ! A.type_ "module" ! A.src "/assets/boot.js" $ mempty
    H.body ! H.customAttribute "data-page" (H.toValue $ kind metadata) ! H.customAttribute "data-category" (H.toValue $ category metadata) $ do
      H.script ! A.id "site-bootstrap" ! A.type_ "application/json" $ H.preEscapedToHtml $ Bootstrap.render (kind metadata) (category metadata) headings
      loadingScreen
      H.div ! A.id "app" $
        H.div ! A.class_ "fallback" $ do
          H.nav ! H.customAttribute "aria-label" "Main" $ do
            H.a ! A.class_ "brand" ! A.href "/" $ "λ Asai Blog"
            H.span ! A.class_ "muted" $ H.toHtml $ "/ " ++ breadcrumb metadata
            H.a ! A.href "/feed.xml" $ "RSS ↗"
          H.main ! A.id "static-content" $ content
          H.footer "Written in Markdown. Built with Hakyll & Elm."

loadingScreen :: H.Html
loadingScreen =
  H.section ! A.id "loading-screen" ! A.class_ "loading-screen" ! H.customAttribute "aria-labelledby" "loading-title" ! A.hidden "" $
    H.div ! A.class_ "loading-content" $ do
      H.div ! A.id "loading-title" ! A.class_ "loading-title" ! H.customAttribute "role" "heading" ! H.customAttribute "aria-level" "1" $ "Please Be Patient"
      H.p ! A.id "loading-status" ! H.customAttribute "role" "status" ! H.customAttribute "aria-live" "polite" $ "loading assets..."
      H.div ! A.class_ "loading-progress" ! H.customAttribute "aria-hidden" "true" $ mempty
