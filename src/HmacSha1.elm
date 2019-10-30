module HmacSha1 exposing
    ( Digest, digest
    , toBytes, toIntList, toHex, toBase64
    )

{-| Computes a Hash-based Message Authentication Code (HMAC) using the SHA-1 hash function

@docs Digest, digest


# Representation

@docs toBytes, toIntList, toHex, toBase64

-}

import Base16
import Base64
import Bitwise
import Bytes exposing (Bytes)
import Bytes.Encode as Encode exposing (Encoder)
import SHA1
import Word.Bytes as Bytes


{-| An HMAC-SHA1 digest.
-}
type Digest
    = Digest (List Int)


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
    let
        normalizedKey =
            keyToBytes key
                |> normalizeKey

        messageBytes =
            messageToBytes message
    in
    hmac normalizedKey messageBytes
        |> Digest


{-| Convert a Digest into [elm/bytes](https://package.elm-lang.org/packages/elm/bytes/latest/) Bytes.
You can use this to map it to your own representations. I use it to convert it to
Base16 and Base64 string representations.

    toBytes (digest "key" "message")
    --> <80 bytes>

-}
toBytes : Digest -> Bytes
toBytes (Digest data) =
    listToBytes data


{-| Convert a Digest into a List of Integers. Sometimes you will want to have the
Byte representation as a list of integers.

    toIntList (digest "key" "message")
        |> toIntList
    --> [32,136,223,116,213,242,20,107,72,20,108,175,73,101,55,126,157,11,227,164]

-}
toIntList : Digest -> List Int
toIntList (Digest data) =
    data


{-| Convert a Digest into a base64 String Result

    case toBase64 (digest "key" "message") of
        Ok base64String ->
            "Base64 string: " ++ base64String

        Err err ->
            "Failed to convert the digest"

    --> Base64 string: IIjfdNXyFGtIFGyvSWU3fp0L46Q=

-}
toBase64 : Digest -> Result String String
toBase64 (Digest data) =
    Base64.encode data


{-| Convert a Digest into a base16 String Result

    case toHex (digest "key" "message") of
        Ok base16String ->
            "Hex string: " ++ base16String

        Err err ->
            "Failed to convert the digest"

    --> Hex string: 2088DF74D5F2146B48146CAF4965377E9D0BE3A4

-}
toHex : Digest -> Result String String
toHex (Digest data) =
    Base16.encode data



-- HMAC-SHA1


hmac : KeyBytes -> MessageBytes -> List Int
hmac (KeyBytes key) (MessageBytes message) =
    let
        oKeyPad =
            List.map (Bitwise.xor 0x5C) key

        iKeyPad =
            List.map (Bitwise.xor 0x36) key
    in
    List.append iKeyPad message
        |> sha1
        |> List.append oKeyPad
        |> sha1



-- KEY


type KeyBytes
    = KeyBytes (List Int)


keyToBytes : String -> KeyBytes
keyToBytes key =
    KeyBytes (Bytes.fromUTF8 key)


normalizeKey : KeyBytes -> KeyBytes
normalizeKey (KeyBytes key) =
    case compare blockSize <| List.length key of
        EQ ->
            KeyBytes key

        GT ->
            padEnd key
                |> KeyBytes

        LT ->
            sha1 key
                |> padEnd
                |> KeyBytes


padEnd : List Int -> List Int
padEnd bytes =
    List.append bytes <|
        List.repeat (blockSize - List.length bytes) 0



-- MESSAGE


type MessageBytes
    = MessageBytes (List Int)


messageToBytes : String -> MessageBytes
messageToBytes message =
    MessageBytes (Bytes.fromUTF8 message)



-- SHA 1


blockSize : Int
blockSize =
    64


sha1 : List Int -> List Int
sha1 bytes =
    bytes
        |> SHA1.fromBytes
        |> SHA1.toBytes



-- elm/bytes
-- ENCODE


listToBytes : List Int -> Bytes
listToBytes byteList =
    Encode.sequence (List.map intEncoder byteList)
        |> Encode.encode


intEncoder : Int -> Encode.Encoder
intEncoder int =
    Encode.unsignedInt32 Bytes.BE int
