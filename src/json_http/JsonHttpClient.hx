package json_http;

import haxe.Exception;
import haxe.Json;
import haxe.io.BytesOutput;
import sys.net.Host;
import sys.net.Socket;

typedef JsonHttpResponse = {
	var protocol:String;
	var statusCode: Dynamic;
	var statusMessage: String;
	var headers:Map<String, String>;
	var body: Dynamic;
	var parseError: Bool; // Set to true by parser if there was *any* kind of error during parsing process.
}

class JsonHttpClient {
	private var port = 80;

	public function new() {}

	public function post(url: String, body: Dynamic, ?headers: Map<String, String>) {
		var parsedURL = this.parseURL(url);
		var hostname = parsedURL.host;
		var endpoint = parsedURL.endpoint;
		if (port != this.port) {
			throw new Exception('Invalid port: ${port}. ${this.port} was expected.');
		}
		return this.custom(hostname, endpoint, body, 'POST', headers); 
	}

	public function delete(url:String, body:Dynamic, ?headers:Map<String, String>) {
		var parsedURL = this.parseURL(url);
		var hostname = parsedURL.host;
		var endpoint = parsedURL.endpoint;
		if (port != this.port) {
			throw new Exception('Invalid port: ${port}. ${this.port} was expected.');
		}
		return this.custom(hostname, endpoint, body, 'DELETE', headers);
	}

	public function put(url:String, body:Dynamic, ?headers:Map<String, String>) {
		var parsedURL = this.parseURL(url);
		var hostname = parsedURL.host;
		var endpoint = parsedURL.endpoint;
		if (port != this.port) {
			throw new Exception('Invalid port: ${port}. ${this.port} was expected.');
		}
		return this.custom(hostname, endpoint, body, 'PUT', headers);
	}

	public function patch(url:String, body:Dynamic, ?headers:Map<String, String>) {
		var parsedURL = this.parseURL(url);
		var hostname = parsedURL.host;
		var endpoint = parsedURL.endpoint;
		if (port != this.port) {
			throw new Exception('Invalid port: ${port}. ${this.port} was expected.');
		}
		return this.custom(hostname, endpoint, body, 'PATCH', headers);
	}

	public function get(url:String, queryParams: Map<String, String>, ?body:Dynamic = null, ?headers:Map<String, String>) {
		var parsedURL = this.parseURL(url);
		var hostname = parsedURL.host;
		var endpoint = parsedURL.endpoint + buildQueryParams(queryParams);

		if (port != this.port) {
			throw new Exception('Invalid port: ${port}. ${this.port} was expected.');
		}
		if (body == null) {
			body = {}
		}
		return this.custom(hostname, endpoint, body, 'GET', headers);
	}

	public function custom(hostname: String, endpoint: String, body: Dynamic, method: String, ?headers: Map<String, String>): JsonHttpResponse {
		var host = new Host(hostname);
		var sock = new Socket();
		sock.connect(host, this.port);

		var req = new BytesOutput();

		req.writeString('${method} ${endpoint} HTTP/1.1\r\n');
		req.writeString('Host: ${hostname}\r\n');
		req.writeString('Connection: close\r\n');
		req.writeString('Content-Type: application/json\r\n');
		req.writeString('Content-Length: ${Json.stringify(body).length}\r\n');
		req.writeString('Accept: application/json\r\n');
		if (headers != null) {
			for (key in headers.keys()) {
				req.writeString('${key}: ${headers.get(key)}\r\n');
			}
		}
		req.writeString('\r\n');
		req.writeString(Json.stringify(body));
		req.writeString('\n\n\n');
		req.flush();
		var reqstr = req.getBytes().toString();

		sock.write(reqstr);
		var res = sock.read();
		sock.close();

		return parseResponse(res);
	}

	public function parseResponse(response: String): JsonHttpResponse {
		var parseError = false;
		var segments = response.split("\r\n\r\n");
		var statusLine = segments[0].split("\r\n")[0];
		var headers = segments[0].split("\r\n");
		headers.remove(statusLine);

		var body = "";
		try {
			body = segments[1];
		} catch (e) {
			parseError = true;
		}

		var statusSegments = statusLine.split(" ");
		var protocol = statusSegments[0];
		var statusCode = statusSegments[1];
		var statusMessage = statusSegments[2];

		var parsedHeaders: Map<String, String> = new Map();
		for (header in headers) {
			parsedHeaders.set(header.split(":")[0], header.split(":")[1]);
		}

		var parsedBody: String = body;
		var parsedStatusCode: Dynamic = statusCode;

		try {
			parsedBody = Json.parse(body);
		} catch (e) {
			parseError = true;
		}

		try {
			parsedStatusCode = Std.parseInt(statusCode);
		} catch (e) {
			parseError = true;
		}

		var parsed: JsonHttpResponse = {
			protocol: protocol,
			statusCode: parsedStatusCode,
			statusMessage: statusMessage,
			headers: parsedHeaders,
			body: parsedBody,
			parseError: parseError
		};

		return parsed;
	}

	public function buildQueryParams(data:Map<String, String>):String {
		var queryParams:Array<String> = [];
		for (key in data.keys()) {
			var value:String = data[key];
			queryParams.push(StringTools.urlEncode(key) + "=" + StringTools.urlEncode(value));
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
}
