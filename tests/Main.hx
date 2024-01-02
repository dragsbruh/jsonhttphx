using json_http.JsonHttpClient;

class Main {
    static function main() {
        trace('Testing plain HTTP...');
		test(false);
        trace('Testing secure HTTPS...');
        test(true);
    }
    static function test(use_https: Bool) {
        var client = new JsonHttpClient(use_https);

        // TODO: Write tests
    }
}