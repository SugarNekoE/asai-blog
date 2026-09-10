{-# LANGUAGE OverloadedStrings #-}

module Site.Styles.Theme (token) where

import Clay (Color, other)
import Data.String (fromString)
import qualified Data.Text as T

token :: T.Text -> Color
token name = other $ fromString $ T.unpack $ "var(--" <> name <> ")"
