extends Node

const SOURCE := "little-six-game"
const VERSION := 1

func _ready() -> void:
    # Emit ready event once the first frame has rendered
    await get_tree().process_frame
    emit_to_host("ready", {})

func emit_to_host(type: String, payload: Dictionary = {}) -> void:
    # Skip if not running on web or in headless mode
    if not OS.has_feature("web") or DisplayServer.get_name() == "headless":
        # For local development observability, emit locally
        EventBus.host_event_sent.emit(type, payload)
        return

    var envelope = {
        "source": SOURCE,
        "version": VERSION,
        "type": type,
        "payload": payload
    }

    var origin = JavaScriptBridge.get_interface("window").location.origin
    JavaScriptBridge.get_interface("window").postMessage(envelope, origin)

    EventBus.host_event_sent.emit(type, payload)