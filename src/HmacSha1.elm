module HmacSha1 exposing
    ( Digest, fromString, fromBytes
    , toBytes, toByteValues, toHex, toBase64
    )

{-| Computes a Hash-based Message Authentication Code (HMAC) using the SHA-1 hash function

@docs Digest, fromString, fromBytes


# Representation

@docs toBytes, toByteValues, toHex, toBase64

-}

import Bitwise
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as Decode exposing (Decoder)
import Bytes.Encode as Encode exposing (Encoder)
import Internals exposing (Key(..), bytesToInts, stringToInts)
import SHA1


{-| An HMAC-SHA1 digest.
-}
type Digest
    = Digest SHA1.Digest


{-| Pass a Key and your message as a String to compute a Digest

    import HmacSha1.Key as Key

    "The quick brown fox jumps over the lazy dog"
        |> fromString (Key.fromString "key")
        |> toHex
    --> "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9"

    "The quick brown fox jumps over the lazy dog"
        |> fromString (Key.fromString "key")
        |> toBase64
    --> "3nybhbi3iqa8ino29wqQcBydtNk="

-}
fromString : Key -> String -> Digest
fromString =
    usingEncoder Encode.string


{-| Pass a Key and your message in Bytes to compute a Digest

    import HmacSha1.Key as Key
    import Bytes.Encode

    Bytes.Encode.sequence []
        |> Bytes.Encode.encode
        |> fromBytes (Key.fromString "")
        |> toBase64
    --> "+9sdGxiqbAgyS31ktx+3Y3BpDh0="

-}
fromBytes : Key -> Bytes -> Digest
fromBytes =
    usingEncoder Encode.bytes


usingEncoder : (message -> Encoder) -> Key -> message -> Digest
usingEncoder encoder (Key key) message =
    let
        oKeyPad =
            List.map (Encode.unsignedInt8 << Bitwise.xor 0x5C) key

        iKeyPad =
            List.map (Encode.unsignedInt8 << Bitwise.xor 0x36) key
    in
    [ Encode.sequence iKeyPad, encoder message ]
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
        |> Digest


{-| Convert a Digest into [elm/bytes](https://package.elm-lang.org/packages/elm/bytes/latest/) Bytes.
You can use this to map it to your own representations. I use it to convert it to
Base16 and Base64 string representations.

    import Bytes
    import HmacSha1.Key as Key

    fromString (Key.fromString "key") "message"
        |> toBytes
        |> Bytes.width
    --> 20

-}
toBytes : Digest -> Bytes
toBytes (Digest data) =
    SHA1.toBytes data


{-| Convert a Digest into a List of Integers. Each Integer is in the range
0-255, and represents one byte. Can be useful for passing digest on to other
packages that make use of this convention.

    import HmacSha1.Key as Key

    fromString (Key.fromString "key") "message"
        |> toByteValues
    --> [32, 136, 223, 116, 213, 242, 20, 107, 72, 20, 108, 175, 73, 101, 55, 126, 157, 11, 227, 164]

-}
toByteValues : Digest -> List Int
toByteValues (Digest data) =
    SHA1.toByteValues data


{-| Convert a Digest into a base64 String

    import HmacSha1.Key as Key

    fromString (Key.fromString "key") "message"
        |> toBase64
    --> "IIjfdNXyFGtIFGyvSWU3fp0L46Q="

-}
toBase64 : Digest -> String
toBase64 (Digest data) =
    SHA1.toBase64 data


{-| Convert a Digest into a base16 String

    import HmacSha1.Key as Key

    fromString (Key.fromString "key") "message"
        |> toHex
    --> "2088df74d5f2146b48146caf4965377e9d0be3a4"

-}
toHex : Digest -> String
toHex (Digest data) =
    SHA1.toHex data
