{-# LANGUAGE OverloadedStrings #-}

module Util.Solidity where

import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as B
import Data.Text (Text, pack, unpack)
import Crypto.Hash (Digest, Keccak_256, hash)
import Shelly ((-|-))
import qualified Data.Text as T
import qualified Shelly as Sh

type Code = Text

compile :: Text -> Code -> IO Text
compile name code = 
  let
    heading = T.concat ["======= ", name, " ======="]
  in Sh.shelly . Sh.silently $ do
    out <- (return code) -|- Sh.run "solc" ["--bin-runtime"]
    return . (!! 2) . T.lines . snd $ T.breakOn heading out

run :: Text -> Text -> IO Text
run code input =
  Sh.shelly $ do
    Sh.run "evm" ["--code", code, "--input", input, "run"]

callDataWithBytes :: Text -> Text -> Text
callDataWithBytes name bs =
  let
    method = methodID name ["bytes"]
    loc    = padWordL "20"
    len    = padWordL . pack $ show ((T.length bs) `div` 2)
  in
    T.concat [method, loc, len, padWordR bs]

callDataNoArgs :: Text -> Text
callDataNoArgs name =
  methodID name []

methodID :: Text -> [Text] -> Text
methodID name args =
  let
    sig = T.concat [name, "(", T.intercalate "," args, ")"]
  in
    T.take 8 . keccak256 . B.pack $ unpack sig

keccak256 :: ByteString -> Text
keccak256 bs = pack $ show (hash bs :: Digest Keccak_256)

padWordL :: Text -> Text
padWordL x = 
  let
    sz  = T.length x
    n   = 64 - (sz `mod` 64)
    pad = pack . take n $ repeat '0'
  in
    T.append pad x

padWordR :: Text -> Text
padWordR x = 
  let
    sz  = T.length x
    n   = 64 - (sz `mod` 64)
    pad = pack . take n $ repeat '0'
  in
    T.append x pad
