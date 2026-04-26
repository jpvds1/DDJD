extends Node

const BASE_URL = "https://rebnsbkzdhygmydmswgr.supabase.co"
const REST_URL = BASE_URL + "/rest/v1"
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlYm5zYmt6ZGh5Z215ZG1zd2dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMDE5MzQsImV4cCI6MjA5Mjc3NzkzNH0.l41xYd60oPRE2e8IjMVWxZ9uj7IXzc14wYyYKTJ5w6k"

var access_token := ""
var current_user = null

signal auth_changed(user)

func _ready():
	var saved = _load_session()
	if saved:
		access_token = saved.access_token
		current_user = saved.user
		auth_changed.emit(current_user)

func is_logged_in() -> bool:
	return access_token != ""

# ---------------------------------------------------------
# Auth
# ---------------------------------------------------------

func sign_out() -> void:
	await _post(BASE_URL + "/auth/v1/logout", {}, true)
	access_token = ""
	current_user = null
	_clear_session()
	auth_changed.emit(null)

# ---------------------------------------------------------
# Google OAuth
# ---------------------------------------------------------

var _oauth_server: TCPServer = null

func sign_in_with_google() -> void:
	if _oauth_server != null:
		_oauth_server.stop()

	_oauth_server = TCPServer.new()
	var err = _oauth_server.listen(9876)
	if err != OK:
		print("Failed to open server: ", err)
		return

	OS.shell_open(BASE_URL + "/auth/v1/authorize?provider=google&redirect_to=http://localhost:9876")

	var token = await _wait_for_oauth_callback()

	if token != "":
		access_token = token
		await _fetch_user()
		_save_session({"access_token": token, "user": current_user})
		print("Google login OK: ", current_user.get("email", ""))
	else:
		print("Google login failed — empty token")

func _wait_for_oauth_callback() -> String:
	var html_page = """HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n
<!DOCTYPE html><html><head>
<script>
window.onload = function() {
	var hash = window.location.hash.substring(1);
	var params = new URLSearchParams(hash);
	var token = params.get('access_token');
	if (token) {
		var img = new Image();
		img.src = 'http://localhost:9876/token?' + hash;
		document.getElementById('msg').innerText = 'Login successful! You can close this tab.';
	} else {
		document.getElementById('msg').innerText = 'Login failed.';
	}
};
</script>
</head><body>
<h2 id="msg">Processing login...</h2>
</body></html>"""

	var timeout := 60.0
	var elapsed := 0.0
	var token := ""

	while elapsed < timeout:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

		if not _oauth_server or not _oauth_server.is_connection_available():
			continue

		var conn = _oauth_server.take_connection()
		var request := ""

		for i in range(200):
			await get_tree().process_frame
			if conn.get_available_bytes() > 0:
				request = conn.get_string(conn.get_available_bytes())
				break

		if "/token?" in request:
			token = _extract_token(request)
			conn.put_data((
				"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" +
				"<html><body><h2>Done! You can close this tab.</h2></body></html>"
			).to_utf8_buffer())
			conn.disconnect_from_host()
			break
		else:
			conn.put_data(html_page.to_utf8_buffer())
			conn.disconnect_from_host()

	if _oauth_server:
		_oauth_server.stop()
		_oauth_server = null

	return token

func _extract_token(request: String) -> String:
	var regex = RegEx.new()
	regex.compile("access_token=([^&\\s]+)")
	var result = regex.search(request)
	if result:
		return result.get_string(1)
	return ""

func _fetch_user() -> void:
	var res = await _http_get(BASE_URL + "/auth/v1/user")
	if res is Dictionary:
		current_user = res
		auth_changed.emit(current_user)

# ---------------------------------------------------------
# Leaderboard
# ---------------------------------------------------------

func submit_score(level_id: String, time_ms: int) -> Dictionary:
	if not is_logged_in():
		return { "error": "Not logged in" }

	var user_id = current_user.get("id", "")
	if user_id == "":
		return { "error": "No user id" }

	var meta = current_user.get("user_metadata", {})
	var username = meta.get("username", meta.get("full_name", meta.get("name", "Unknown")))

	var best = await _get_best_score(user_id, level_id)
	if best != -1 and time_ms >= best:
		print("Not a new best (", time_ms, "ms vs ", best, "ms)")
		return { "skipped": true }

	# Apaga o score anterior antes de inserir o novo
	await _delete_score(user_id, level_id)

	print("Submitting new best: ", username, " | ", level_id, " | ", time_ms, "ms")
	var result = await _post(REST_URL + "/leaderboard", {
		"user_id": user_id,
		"username": username,
		"level_id": level_id,
		"time_ms": time_ms
	}, true)

	print("Submit result: ", result)
	return result

func _delete_score(user_id: String, level_id: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)

	var headers = [
		"apikey: " + ANON_KEY,
		"Authorization: Bearer " + access_token
	]

	http.request(
		REST_URL + "/leaderboard?user_id=eq.%s&level_id=eq.%s" % [user_id, level_id],
		headers,
		HTTPClient.METHOD_DELETE
	)
	await http.request_completed
	http.queue_free()

func _get_best_score(user_id: String, level_id: String) -> int:
	var res = await _http_get(
		REST_URL + "/leaderboard?user_id=eq.%s&level_id=eq.%s&order=time_ms.asc&limit=1" % [user_id, level_id]
	)
	if res is Array and res.size() > 0:
		return res[0].get("time_ms", -1)
	return -1

func get_scores(level_id: String, limit: int = 10) -> Array:
	var res = await _http_get(
		REST_URL + "/leaderboard?level_id=eq.%s&order=time_ms.asc&limit=%d" % [level_id, limit]
	)
	if res is Array:
		return res
	return []

func get_my_score(level_id: String) -> Dictionary:
	if not is_logged_in():
		return {}
	var user_id = current_user.get("id", "")
	var res = await _http_get(
		REST_URL + "/leaderboard?user_id=eq.%s&level_id=eq.%s&order=time_ms.asc&limit=1" % [user_id, level_id]
	)
	if res is Array and res.size() > 0:
		return res[0]
	return {}

# ---------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------

func _post(full_url: String, body: Dictionary, auth: bool) -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)

	var headers = [
		"Content-Type: application/json",
		"apikey: " + ANON_KEY
	]
	if auth and access_token != "":
		headers.append("Authorization: Bearer " + access_token)

	http.request(full_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	var result = await http.request_completed
	http.queue_free()

	var response_body = result[3].get_string_from_utf8()
	return JSON.parse_string(response_body) if response_body else {}

func _http_get(full_url: String) -> Variant:
	var http = HTTPRequest.new()
	add_child(http)

	var headers = [
		"apikey: " + ANON_KEY,
		"Authorization: Bearer " + (access_token if access_token != "" else ANON_KEY)
	]

	http.request(full_url, headers, HTTPClient.METHOD_GET)
	var result = await http.request_completed
	http.queue_free()

	var response_body = result[3].get_string_from_utf8()
	return JSON.parse_string(response_body) if response_body else []

# ---------------------------------------------------------
# Session
# ---------------------------------------------------------

func _save_session(data: Dictionary) -> void:
	access_token = data.get("access_token", "")
	current_user = data.get("user", null)

	var file = FileAccess.open("user://session.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"access_token": access_token,
		"user": current_user
	}))
	file.close()
	auth_changed.emit(current_user)

func _load_session() -> Variant:
	if not FileAccess.file_exists("user://session.json"):
		return null
	var file = FileAccess.open("user://session.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func _clear_session() -> void:
	if FileAccess.file_exists("user://session.json"):
		DirAccess.remove_absolute("user://session.json")
