module Site.Styles (sheets) where

import Clay (Css, pretty, renderWith)
import qualified Data.Text.Lazy as TL
import qualified Site.Styles.Article as Article
import qualified Site.Styles.Base as Base
import qualified Site.Styles.Loading as Loading
import qualified Site.Styles.Print as Print

sheets :: [(FilePath, String)]
sheets =
  map
    renderSheet
    [ ("assets/base.css", Base.styles),
      ("assets/article.css", Article.styles),
      ("assets/loading.css", Loading.styles),
      ("assets/print.css", Print.styles)
    ]
  where
    renderSheet :: (FilePath, Css) -> (FilePath, String)
    renderSheet (path, styles) = (path, TL.unpack $ renderWith pretty [] styles)
