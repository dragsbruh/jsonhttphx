# json_http for haxe

> Perform JSON-oriented HTTP tasks on all native (sys) platforms I guess. \
> v0.3.0

## Why

This library was created because of the lack of proper HTTP libraries that allow flexible manipulation of headers, body that can be used to interact with APIs.
The code may be a mess but it works as of now. There might be some edge cases where the code (especially the HTTP response parser) breaks, so if you do notice one please consider submitting an issue.
*Written in pure Haxe ig*

**WARNING:** This library expects that all responses from API are in JSON format. However, this response parser does not throw any exceptions and in case of JSON parse errors it just does not parse the response body.

## Technical Info

The library uses the `sys.net.Socket` class (`sys.ssl.Socket` if you want secure stuff) to communicate with servers, so expect it to work on all platforms that support it.

## Example

```haxe
class Main {
    static function main() {
        var client = new JsonHttpClient();
        var response = client.post("http://httpbin.org/post", {
            foo: 100,
            bar: "Hm chocolate bar",
            baz: true
        }, [
            "Authorization" => "Your mom gave me consent... to take cookies"
        ]);
        trace('\n', Json.stringify(response, null, "    "));
    }
}
```

## Docs (highly useless) (TODO: Validate docs)

Built-in methods are: `get`, `put`, `post`, `delete`, `patch`
However, you can quite easily use a custom method (not really). For example:

```haxe
client.custom(hostname, endpoint, body, method, headers);
```

In fact, the built-in methods just wrap to this method, and `get` does some additional work because reasons.

**Syntax to built-in methods:**

```haxe
client.method(url, body, headers);
```

**Syntax for `get`:**

```haxe
client.get(url, queryParams, body, headers);
```

**Response:**

```haxe
typedef JsonHttpResponse = {
    var protocol:String;                // Ex: "HTTP/1.1"
    var statusCode: Dynamic;            // Ex: 200
    var statusMessage: String;          // Ex: "OK"
    var headers:Map<String, String>;    // Ex: ["Content-Type" => "application/json"]
    var body: Dynamic;                  // Ex: { "foo": 100 }
}
```

> ***BEWARE OF RANDOM EXCEPTIONS, HIGHLY UNSTABLE POORLY TESTED (but works)***

## Development

### TODO

- [ ] Write tests.
- [ ] Verify functionality of all HTTP methods.
- [ ] Make this library fool-proof.
- [x] Implement HTTPS

### Notes

- Support for non-sys platforms is not planned. However, in Liyue...
