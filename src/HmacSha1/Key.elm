module HmacSha1.Key exposing (Key, fromBytes, fromString)

import Bytes exposing (Bytes)
import Bytes.Encode as Encode
import Internals as I
import SHA1


type alias Key =
    I.Key


fromString : String -> Key
fromString =
    fromBytes << Encode.encode << Encode.string


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
