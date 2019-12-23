module HmacSha1.Key exposing (Key, fromString, fromBytes)

{-| Build an HMAC Key, either from a String or Bytes. Required to build an
HmacSha1.Digest

@docs Key, fromString, fromBytes

-}

import Bytes exposing (Bytes)
import Bytes.Encode as Encode
import Internals as I
import SHA1


{-| Opaque type representing a Key
-}
type alias Key =
    I.Key


{-| Builds a Key from a String
-}
fromString : String -> Key
fromString =
    fromBytes << Encode.encode << Encode.string


{-| Builds a Key from Bytes
-}
fromBytes : Bytes -> Key
fromBytes bytes =
    let
        ints =
            if Bytes.width bytes > blockSize then
                SHA1.fromBytes bytes
                    |> SHA1.toByteValues

            else
                I.bytesToInts bytes
    in
    I.Key (ints ++ List.repeat (blockSize - List.length ints) 0)


blockSize : Int
blockSize =
    64
