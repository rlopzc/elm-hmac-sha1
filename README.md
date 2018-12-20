# elm-hmac-sha1

Compute HMAC message digests using SHA1 hash function. You provide a key and a
message and you get a digest. You can convert the digest into different representations
like Bytes, Base16 or Base64.

This provide the native Bytes ([elm/bytes](https://package.elm-lang.org/packages/elm/bytes/latest/)).
This is important as you can represent the data as you want.

More information of HMAC [here](https://en.wikipedia.org/wiki/HMAC).

## Examples

Some API's use the HMAC-SHA1 as Authentication, like Amazon or Twitter.

Fact: I created this package because we use this Authentication at the company I
currently work for.

```elm
import HmacSha1

canonicalString : String
canonicalString =
  ["application/json", "", "/account", "Wed, 02 Nov 2016 17:26:52 GMT"]
    |> String.join ","

HmacSha1.digest "verify-secret" canonicalString
  |> HmacSha1.toBase64
--> Ok "nLet/JEZG9CRXHScwaQ/na4vsKQ="
```
