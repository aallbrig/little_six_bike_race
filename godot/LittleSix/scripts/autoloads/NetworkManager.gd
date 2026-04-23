extends Node

enum ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    IN_ROOM,
    IN_RACE
}

var state: ConnectionState = ConnectionState.DISCONNECTED
var ping_ms: int = 0
var _websocket: WebSocketPeer = null
var _heartbeat_timer: Timer = null

func _ready() -> void:
    # Skip WebSocket initialization if running headless (server) or not on web
    if DisplayServer.get_name() == "headless" or not OS.has_feature("web"):
        return

    _heartbeat_timer = Timer.new()
    _heartbeat_timer.wait_time = 1.0
    _heartbeat_timer.timeout.connect(_send_heartbeat)
    add_child(_heartbeat_timer)

func connect_to_server(url: String, token: String) -> void:
    if state != ConnectionState.DISCONNECTED:
        return

    state = ConnectionState.CONNECTING
    _websocket = WebSocketPeer.new()
    _websocket.connect_to_url(url)

    # TODO: Send token in handshake

func send_message(msg_type: String, payload: Dictionary) -> void:
    if state == ConnectionState.DISCONNECTED:
        return

    var message = {
        "type": msg_type,
        "payload": payload,
        "ts": Time.get_unix_time_from_system()
    }

    var json_string = JSON.stringify(message)
    _websocket.send_text(json_string)

func disconnect_gracefully() -> void:
    if _websocket:
        _websocket.close()
    state = ConnectionState.DISCONNECTED
    EventBus.disconnected_from_server.emit("user_disconnect")

func _process(delta: float) -> void:
    if not _websocket:
        return

    _websocket.poll()

    var state_changed = false
    match _websocket.get_ready_state():
        WebSocketPeer.STATE_OPEN:
            if state == ConnectionState.CONNECTING:
                state = ConnectionState.CONNECTED
                EventBus.connected_to_server.emit()
                _heartbeat_timer.start()
                state_changed = true
        WebSocketPeer.STATE_CLOSED:
            if state != ConnectionState.DISCONNECTED:
                disconnect_gracefully()
                state_changed = true

    # Process incoming messages
    while _websocket.get_available_packet_count() > 0:
        var packet = _websocket.get_packet()
        var json_string = packet.get_string_from_utf8()
        var message = JSON.parse_string(json_string)

        if message and message.has("type"):
            _handle_network_message(message.type, message.get("payload", {}))

func _handle_network_message(msg_type: String, payload: Dictionary) -> void:
    match msg_type:
        "HEARTBEAT_ACK":
            # Update ping
            ping_ms = int(Time.get_unix_time_from_system() * 1000) % 1000  # Simplified
            EventBus.latency_updated.emit(ping_ms)
        "RACE_START":
            EventBus.race_started.emit()
            state = ConnectionState.IN_RACE
        "WORLD_STATE":
            # Handle race synchronization from server
            EventBus.network_message_received.emit(msg_type, payload)
        "RACE_FINISHED":
            EventBus.race_finished.emit(payload.get("results", []))
            state = ConnectionState.IN_ROOM
        _:
            EventBus.network_message_received.emit(msg_type, payload)

func _send_heartbeat() -> void:
    if state in [ConnectionState.IN_ROOM, ConnectionState.IN_RACE]:
        send_message("HEARTBEAT", {})
        # TODO: Start ping timer and measure latency on HEARTBEAT_ACK