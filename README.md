# json_http for haxe

> Perform JSON-oriented HTTP tasks on all native (sys) platforms I guess. \
> v0.2.2

## Why

This library was created because of the lack of proper HTTP libraries that allow flexible manipulation of headers, body that can be used to interact with APIs.
The code may be a mess but it works as of now. There might be some edge cases where the code (especially the HTTP response parser) breaks, so if you do notice one please consider submitting an issue.
*Written in pure Haxe ig*

## Technical Info

The library uses the `sys.net.Socket` class to communicate with servers, so expect it to work on all platforms that support it.
`0.3.0` is planned to introduce SSL, allowing you to securely interact with your useless API server.
All https urls passed to `JsonHttpClient` are redirected to http as of now.

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

## Docs (highly useless)

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
    var parseError: Bool;               // Set to true by the response parser if there was *any* kind of error during parsing process, like JSON body parsing error, etc. If yours is a perfect API server then dont worry about this.
}
```

> ***BEWARE OF RANDOM EXCEPTIONS, HIGHLY UNSTABLE POORLY TESTED (but works)***
