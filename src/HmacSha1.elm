module HmacSha1 exposing
    ( Digest, digest
    , toBytes, toIntList, toHex, toBase64
    )

{-| Computes a Hash-based Message Authentication Code (HMAC) using the SHA-1 hash function

@docs Digest, digest


# Representation

@docs toBytes, toIntList, toHex, toBase64

-}

import Bitwise
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as Decode exposing (Decoder)
import Bytes.Encode as Encode exposing (Encoder)
import SHA1


{-| An HMAC-SHA1 digest.
-}
type Digest
    = Digest SHA1.Digest


type Key
    = Key (List Int)


{-| Pass a Key and a Message to compute a Digest

    digest "key" "The quick brown fox jumps over the lazy dog"
        |> toHex
    --> "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9"

    digest "key" "The quick brown fox jumps over the lazy dog"
        |> toBase64
    --> "3nybhbi3iqa8ino29wqQcBydtNk="

-}
digest : String -> String -> Digest
digest key =
    Digest << hmac (makeKey key)


{-| Convert a Digest into [elm/bytes](https://package.elm-lang.org/packages/elm/bytes/latest/) Bytes.
You can use this to map it to your own representations. I use it to convert it to
Base16 and Base64 string representations.

    import Bytes

    digest "key" "message"
        |> toBytes
        |> Bytes.width
    --> 20

-}
toBytes : Digest -> Bytes
toBytes (Digest data) =
    SHA1.toBytes data


{-| Convert a Digest into a List of Integers. Sometimes you will want to have the
Byte representation as a list of integers.

    toIntList (digest "key" "message")
    --> [32, 136, 223, 116, 213, 242, 20, 107, 72, 20, 108, 175, 73, 101, 55, 126, 157, 11, 227, 164]

-}
toIntList : Digest -> List Int
toIntList (Digest data) =
    SHA1.toByteValues data


{-| Convert a Digest into a base64 String

    toBase64 (digest "key" "message")
    --> "IIjfdNXyFGtIFGyvSWU3fp0L46Q="

-}
toBase64 : Digest -> String
toBase64 (Digest data) =
    SHA1.toBase64 data


{-| Convert a Digest into a base16 String

    toHex (digest "key" "message")
    --> "2088df74d5f2146b48146caf4965377e9d0be3a4"

-}
toHex : Digest -> String
toHex (Digest data) =
    SHA1.toHex data



-- HMAC-SHA1


hmac : Key -> String -> SHA1.Digest
hmac (Key key) message =
    let
        oKeyPad =
            List.map (Encode.unsignedInt8 << Bitwise.xor 0x5C) key

        iKeyPad =
            List.map (Encode.unsignedInt8 << Bitwise.xor 0x36) key
    in
    [ Encode.sequence iKeyPad, Encode.string message ]
        |> Encode.sequence
        |> Encode.encode
        |> SHA1.fromBytes
        |> SHA1.toBytes
        |> Encode.bytes
        |> List.singleton
        |> (::) (Encode.sequence oKeyPad)
        |> Encode.sequence
        |> Encode.encode
        |> SHA1.fromBytes



-- KEY


blockSize : Int
blockSize =
    64


makeKey : String -> Key
makeKey string =
    let
        bytes =
            Encode.encode (Encode.string string)

        ints =
            if Bytes.width bytes > blockSize then
                SHA1.fromBytes bytes
                    |> SHA1.toByteValues

            else
                bytesToInts bytes
    in
    Key (ints ++ List.repeat (blockSize - List.length ints) 0)



-- HELPERS


bytesToInts : Bytes -> List Int
bytesToInts bytes =
    let
        decoder acc width =
            if width == 0 then
                Decode.succeed (List.reverse acc)

            else
                Decode.unsignedInt8
                    |> Decode.andThen (\int -> decoder (int :: acc) (width - 1))
    in
    bytes
        |> Decode.decode (decoder [] (Bytes.width bytes))
        |> Maybe.withDefault []
