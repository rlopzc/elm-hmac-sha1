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
                        |> Expect.equal (Ok "+9sdGxiqbAgyS31ktx+3Y3BpDh0=")
            , test "key: key, message: message" <|
                \_ ->
                    digest "key" "message"
                        |> toBase64
                        |> Expect.equal (Ok "IIjfdNXyFGtIFGyvSWU3fp0L46Q=")
            ]
        , describe "HmacSha1.toHex"
            [ test "empty key and message" <|
                \_ ->
                    digest "" ""
                        |> toHex
                        |> Expect.equal (Ok "FBDB1D1B18AA6C08324B7D64B71FB76370690E1D")
            , test "key: key, message: message" <|
                \_ ->
                    digest "key" "message"
                        |> toHex
                        |> Expect.equal (Ok "2088DF74D5F2146B48146CAF4965377E9D0BE3A4")
            ]
        ]
