module HmacSha1Test exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import HmacSha1 exposing (..)
import Test exposing (..)


suite : Test
suite =
    describe "The HmacSha1 module"
        [ describe "HmacSha1.toBase64"
            [ test "empty key and message" <|
                \_ ->
                    digest "" ""
                        |> toBase64
                        |> Expect.equal "+9sdGxiqbAgyS31ktx+3Y3BpDh0="
            , test "key: key, message: message" <|
                \_ ->
                    digest "key" "message"
                        |> toBase64
                        |> Expect.equal "IIjfdNXyFGtIFGyvSWU3fp0L46Q="
            ]
        , describe "HmacSha1.toHex"
            [ test "empty key and message" <|
                \_ ->
                    digest "" ""
                        |> toHex
                        |> Expect.equal "fbdb1d1b18aa6c08324b7d64b71fb76370690e1d"
            , test "key: key, message: message" <|
                \_ ->
                    digest "key" "message"
                        |> toHex
                        |> Expect.equal "2088df74d5f2146b48146caf4965377e9d0be3a4"
            ]
        ]
