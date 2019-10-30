# elm-hmac-sha1

Compute HMAC message digests using SHA-1 hash function. You provide a key and a
message and you get a digest. You can convert the digest into different representations
like Bytes, Base16 or Base64.

This provide the native Bytes ([elm/bytes](https://package.elm-lang.org/packages/elm/bytes/latest/)).
This is important as you can represent the data as you want.

More information of HMAC [here](https://en.wikipedia.org/wiki/HMAC).

## IMPORTANT: Incorrect calculation in older versions

Please note that [there was an issue][issue-2] regarding input data
in versions 2.0.0 and previous of this library. If you are using either of these
versions, it is highly recommended that you upgrade as soon as possible.

[issue-2]: https://github.com/romariolopezc/elm-hmac-sha1/issues/2

## Examples

Some API's use the HMAC SHA-1 as Authentication, like Amazon or Twitter.

```elm
import HmacSha1

canonicalString : String
canonicalString =
    String.join ","
        [ "application/json"
        , ""
        , "/account"
        , "Wed, 02 Nov 2016 17:26:52 GMT"
        ]

HmacSha1.digest "verify-secret" canonicalString
    |> HmacSha1.toBase64
--> Ok "nLet/JEZG9CRXHScwaQ/na4vsKQ="
```

## Notes

This package doesn't implement the SHA-1 hash function. It internally uses [this](https://github.com/TSFoster/elm-sha1) implementation.

HMAC strength depends on the hashing algorithm and SHA-1 is not considered
cryptographically strong. Use this package to interoperate with systems that
already uses HMAC SHA-1 and not for implementing new systems.

There are stronger cryptographic algorithms like HMAC SHA-2, and [this](https://github.com/ktonon/elm-crypto) Elm package implements it.

## Testing

This package uses doc tests, which can be tested using [elm-verify-examples].
To run all tests (assuming `elm-test` and `elm-verify-examples` are installed):

```bash
cd elm-hmac-sha1
elm-verify-examples --fail-on-warn && elm-test
```

[elm-verify-examples]: https://github.com/stoeffel/elm-verify-examples
