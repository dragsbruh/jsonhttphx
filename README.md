# JSONHTTP

## Why

This library was created because of the lack of proper HTTP libraries that allow flexible manipulation of headers, body that can be used to interact with APIs.
The code may be a mess but it works as of now. There might be some edge cases where the code (especially the HTTP response parser) breaks, so if you do notice one please consider submitting an issue.

## Technical Info

The library uses the `sys.net.Socket` class to communicate with servers, so expect it to work on all platforms that support it.
As of now (`0.1.0`) you have to pass in hostname, port, and endpoint separately. However `0.2.0` will allow you to pass in raw URL, even though this is a small change. `0.3.0` is planned to introduce SSL, allowing you to securely interact with your useless API server.

## Example

```haxe
class Main {
    static function main() {
        var client = new JsonHttpClient();
        var response = client.post("httpbin.org", "/post", {
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
