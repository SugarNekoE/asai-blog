{-# LANGUAGE OverloadedStrings #-}

module Site.Bootstrap (Heading (..), render) where

import Data.Aeson (encode, object, (.=))
import qualified Data.ByteString.Lazy as BL
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8)

data Heading = Heading
  { identifier :: T.Text,
    label :: T.Text
  }

render :: String -> String -> [Heading] -> String
render page category headings =
  T.unpack $
    T.replace "<" "\\u003c" $
      decodeUtf8 $
        BL.toStrict $
          encode $
            object
              [ "page" .= page,
                "category" .= category,
                "indexUrl" .= ("/api/posts.json" :: String),
                "headings" .= map (\heading -> object ["id" .= identifier heading, "label" .= label heading]) headings
              ]
