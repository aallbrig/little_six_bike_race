extends Node
class_name MatchmakingClient

const LOCAL_MATCHMAKING_URL = "ws://localhost:8080/match"

var _http_request: HTTPRequest

func _ready() -> void:
    _http_request = HTTPRequest.new()
    add_child(_http_request)
    _http_request.request_completed.connect(_on_matchmaking_response)

func find_match(match_type: String = "quick") -> void:
    print("Finding ", match_type, " match...")

    # For local testing, simulate successful matchmaking response
    # In production this would call AWS Lambda
    await get_tree().create_timer(1.5).timeout

    var simulated_response = {
        "server_url": "ws://localhost:8081/room/test123",
        "room_id": "test123",
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.simulatedtoken",
        "estimated_wait": 8
    }

    _on_matchmaking_response(200, 0, PackedStringArray(), JSON.stringify(simulated_response).to_utf8_buffer())

func _on_matchmaking_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code == 200:
        var response = JSON.parse_string(body.get_string_from_utf8())
        if response:
            print("Match found! Room: ", response.room_id)
            NetworkManager.connect_to_server(response.server_url, response.token)
    else:
        print("Matchmaking failed, using local simulation")
        # Fallback to local simulation
        NetworkManager.connect_to_server("ws://localhost:8081/room/test123", "local-token")

# Called from MainHub "RACE NOW" button
func quick_match() -> void:
    find_match("quick")