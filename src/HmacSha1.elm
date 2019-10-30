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


{-| Pass a Key and a Message to compute a Digest

    digest "key" "The quick brown fox jumps over the lazy dog"
        |> toHex
    --> Ok "DE7C9B85B8B78AA6BC8A7A36F70A90701C9DB4D9"

    digest "key" "The quick brown fox jumps over the lazy dog"
        |> toBase64
    --> Ok "3nybhbi3iqa8ino29wqQcBydtNk="

-}
digest : String -> String -> Digest
digest key message =
    Digest <| hmac (normalizeKey key) (messageToBytes message)


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


{-| Convert a Digest into a base64 String Result

    toBase64 (digest "key" "message")
    --> Ok "IIjfdNXyFGtIFGyvSWU3fp0L46Q="

-}
toBase64 : Digest -> Result String String
toBase64 (Digest data) =
    Ok (SHA1.toBase64 data)


{-| Convert a Digest into a base16 String Result

    toHex (digest "key" "message")
    --> Ok "2088DF74D5F2146B48146CAF4965377E9D0BE3A4"

-}
toHex : Digest -> Result String String
toHex (Digest data) =
    Ok (String.toUpper (SHA1.toHex data))



-- HMAC-SHA1


hmac : KeyBytes -> MessageBytes -> SHA1.Digest
hmac (KeyBytes key) (MessageBytes message) =
    let
        oKeyPad =
            List.map (Encode.unsignedInt8 << Bitwise.xor 0x5C) key

        iKeyPad =
            List.map (Encode.unsignedInt8 << Bitwise.xor 0x36) key
    in
    [ Encode.sequence iKeyPad, message ]
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


type KeyBytes
    = KeyBytes (List Int)


blockSize : Int
blockSize =
    64


normalizeKey : String -> KeyBytes
normalizeKey string =
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
    KeyBytes (ints ++ List.repeat (blockSize - List.length ints) 0)



-- MESSAGE


type MessageBytes
    = MessageBytes Encoder


messageToBytes : String -> MessageBytes
messageToBytes message =
    MessageBytes (Encode.string message)



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
