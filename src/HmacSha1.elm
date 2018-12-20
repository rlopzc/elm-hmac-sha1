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
import Bytes.Decode as Decode exposing (Decoder)
import Bytes.Encode as Encode exposing (Encoder)
import SHA1
import Word.Bytes as Bytes


{-| A HMAC-SHA1 digest.
-}
type Digest
    = Digest Bytes


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
        |> listToBytes
        |> Digest


{-| Convert a Digest into [elm/bytes](https://package.elm-lang.org/packages/elm/bytes/latest/) Bytes.
You can use this to map it to your own representations. I use it to convert it to
Base16 and Base64 string representations.

    toBytes (digest "key" "message")
    --> Ok (<80 bytes>)

-}
toBytes : Digest -> Result String Bytes
toBytes (Digest bytes) =
    Ok bytes


{-| Convert a Digest into a List of Integers. Sometimes you will want to have the
Byte representation as a list of integers.

    toIntList (digest "key" "message")
        |> toIntList
    --> Ok [32,136,223,116,213,242,20,107,72,20,108,175,73,101,55,126,157,11,227,164]

-}
toIntList : Digest -> Result String (List Int)
toIntList (Digest bytes) =
    bytesToMaybeList bytes
        |> Result.fromMaybe "error converting Digest"


{-| Convert a Digest into a base64 String Result

    case toBase64 (digest "key" "message") of
        Ok base64String ->
            "Base64 string: " ++ base64String

        Err err ->
            "Failed to convert the digest"

    --> Base64 string: IIjfdNXyFGtIFGyvSWU3fp0L46Q=

-}
toBase64 : Digest -> Result String String
toBase64 (Digest bytes) =
    bytesToMaybeList bytes
        |> Maybe.map Base64.encode
        |> Maybe.withDefault (Err "error converting Digest")


{-| Convert a Digest into a base16 String Result

    case toHex (digest "key" "message") of
        Ok base16String ->
            "Hex string: " ++ base16String

        Err err ->
            "Failed to convert the digest"

    --> Hex string: 2088DF74D5F2146B48146CAF4965377E9D0BE3A4

-}
toHex : Digest -> Result String String
toHex (Digest bytes) =
    bytesToMaybeList bytes
        |> Maybe.map Base16.encode
        |> Maybe.withDefault (Err "error converting Digest")



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


byteSize : Int
byteSize =
    20


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



-- DECODE


bytesToMaybeList : Bytes -> Maybe (List Int)
bytesToMaybeList bytes =
    Decode.decode listDecoder bytes
        -- Reverse the List because we Decode from Left to Right
        |> Maybe.map List.reverse


{-| The SHA-1 produces 160-bit (20-byte) hash value. That is the reason why we use
20 as the times we loop and decode the Byte sequence
-}
listDecoder : Decoder (List Int)
listDecoder =
    Decode.loop ( byteSize, [] )
        (listStep (Decode.unsignedInt32 Bytes.BE))


listStep : Decoder a -> ( Int, List a ) -> Decoder (Decode.Step ( Int, List a ) (List a))
listStep decoder ( n, xs ) =
    if n <= 0 then
        Decode.succeed (Decode.Done xs)

    else
        Decode.map (\x -> Decode.Loop ( n - 1, x :: xs )) decoder
