module Internals exposing (Key(..), bytesToInts, stringToInts)

import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Bytes.Encode as Encode


type Key
    = Key (List Int)


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


stringToInts : String -> List Int
stringToInts =
    Encode.string >> Encode.encode >> bytesToInts
