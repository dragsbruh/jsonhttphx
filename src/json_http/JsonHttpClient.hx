package json_http;

import haxe.Exception;
import haxe.Json;
import haxe.io.BytesOutput;
import sys.net.Host;
import sys.net.Socket;
import sys.ssl.Socket;

typedef JsonHttpResponse = {
	var protocol:String;
	var statusCode: Dynamic;
	var statusMessage: String;
	var headers:Map<String, String>;
	var body: Dynamic;

	// DEBUG STUFF
	var parseError: Bool; // Set to true by parser if there was *any* kind of error during parsing process.
	var parseErrorMessage:String; // What part was a parse error?
	var raw: String; // DEBUG: Only for debugging parser
}

class JsonHttpClient {
	public var port = 80;
	public var https = false;

	public function new(?https: Bool=true) {
		if (https == true) {
			this.port = 443;
			this.https = true;
		}
	}

	public function post(url: String, body: Dynamic, ?headers: Map<String, String>) {
		return this.custom(url, body, 'POST', headers); 
	}

	public function delete(url:String, body:Dynamic, ?headers:Map<String, String>) {
		return this.custom(url, body, 'DELETE', headers);
	}

	public function put(url:String, body:Dynamic, ?headers:Map<String, String>) {
		return this.custom(url, body, 'PUT', headers);
	}

	public function patch(url:String, body:Dynamic, ?headers:Map<String, String>) {
		return this.custom(url, body, 'PATCH', headers);
	}

	public function get(url:String, ?queryParams: Map<String, String>=null, ?body:Dynamic = null, ?headers:Map<String, String>) {
		if (queryParams != null) {
			url = url + buildQueryParams(queryParams);
		}
		return this.custom(url, body, 'GET', headers);
	}

	public function custom(url: String, body: Dynamic, method: String, ?headers: Map<String, String>): JsonHttpResponse {
		var requestData = this.buildRequest(method, url, body, headers);
		var host = new Host(this.parseURL(url).host);
		var sock: sys.net.Socket;

		if (this.https == true) {
			sock = new sys.ssl.Socket();
		} else {
			sock = new sys.net.Socket();
		}
		
		sock.connect(host, this.port);
		sock.write(requestData);

		var responseData = sock.read();
		sock.close();

		return parseResponse(responseData);
	}

	public function buildRequest(method: String, url: String, body: Dynamic, headers: Map<String, String>) {
		var parsedURL = this.parseURL(url);
		var hostname = parsedURL.host;
		var endpoint = parsedURL.endpoint;

		var length = 0;
		if (body != null) {
			length = Json.stringify(body).length;
		}

		var req = new BytesOutput();

		req.writeString('${method} ${endpoint} HTTP/1.1\r\n');
		req.writeString('Host: ${hostname}\r\n');
		req.writeString('Connection: close\r\n');
		req.writeString('Content-Type: application/json\r\n');
		req.writeString('Content-Length: ${length}\r\n');
		req.writeString('Accept: application/json\r\n');
		if (headers != null) {
			for (key in headers.keys()) {
				req.writeString('${key}: ${headers.get(key)}\r\n');
			}
		}
		req.writeString('\r\n\r\n\r\n');
		if (body != null) {
			req.writeString(Json.stringify(body));
		}

		var built = req.getBytes().toString();

		return built;
	}

	public function parseResponse(response: String): JsonHttpResponse {
		var parseError = false;
		var parseErrorMessage = null;
		var segments = response.split("\r\n\r\n");
		var statusLine = segments[0].split("\r\n")[0];
		var headers = segments[0].split("\r\n");
		headers.remove(statusLine);

		var statusSegments = statusLine.split(" ");
		var protocol = statusSegments[0];
		var statusCode = statusSegments[1];
		var statusMessage = statusSegments[2];

		var parsedHeaders: Map<String, String> = new Map();
		for (header in headers) {
			parsedHeaders.set(header.split(":")[0], header.split(":")[1]);
		}

		var body = "";
		try {
			body = segments[1];
		} catch (e) {
			parseError = true;
			parseErrorMessage = 'Response segment parse error : ${e.message}';
		}

		var parsedBody: String = body;
		var parsedStatusCode: Dynamic = statusCode;

		try {
			parsedBody = Json.parse(body);
		} catch (e) {
			try {
				parsedBody = Json.parse(this.cleanChunkedResponse(body));
			} catch (e2) {
				parseError = true;
				parseErrorMessage = 'Body JSON parse error : ${e.message}';
			}
		}

		try {
			parsedStatusCode = Std.parseInt(statusCode);
		} catch (e) {
			parseError = true;
			parseErrorMessage = 'Status code parse error : ${e.message}';
		}

		var parsed: JsonHttpResponse = {
			protocol: protocol,
			statusCode: parsedStatusCode,
			statusMessage: statusMessage,
			headers: parsedHeaders,
			body: parsedBody,
			parseError: parseError,
			parseErrorMessage: parseErrorMessage,
			raw: response
		};

		return parsed;
	}

	public function buildQueryParams(data:Map<String, String>):String {
		var queryParams:Array<String> = [];

		if (data != null) {
			for (key in data.keys()) {
				var value: String = data[key];
				queryParams.push(StringTools.urlEncode(key) + "=" + StringTools.urlEncode(value));
			}
		}
		return queryParams.join("&");	
	}

	public function parseURL(url: String) {
		// This code is "borrowed" from haxe Http. Don't complain.
		var url_regexp = ~/^(https?:\/\/)?([a-zA-Z\.0-9_-]+)(:[0-9]+)?(.*)$/;
		if (!url_regexp.match(url)) {
			throw new Exception('Invalid URL: ${url}');
		}
		var host = url_regexp.matched(2);
		var port: Dynamic = url_regexp.matched(3);
		var request = url_regexp.matched(4);

		if (request.charAt(0) != "/") {
			request = "/" + request;
		}

		if (port != null) {
			port = Std.parseInt(port.substr(1));
		}

		return {
			host:host,
			port:port,
			endpoint:request
		}
	}

	public function cleanChunkedResponse(input:String):Null<String> {
		// I sincerely thank ChatGPT I thought the code broke apart when random hexes appeared in the response, apparently its a thing called chunks
		var lines:Array<String> = input.split("\n");
		var jsonChunks:Array<String> = [];

		for (line in lines) {
			if (line.length > 0) {
				var startsWithHex:Bool = false;
				for (hexStarter in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]) {
					if (StringTools.startsWith(line, hexStarter)) {
						startsWithHex = true;
						break;
					}
				}

				if (!startsWithHex) {
					// Assuming that lines not starting with hex characters indicate the start of a JSON chunk
					jsonChunks.push(line);
				}
			}
		}

		if (jsonChunks.length > 0) {
			return jsonChunks.join("");
		} else {
			return null;
		}
	}
}
