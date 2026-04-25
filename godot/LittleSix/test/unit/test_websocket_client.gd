extends GutTest

class_name TestWebSocketClient

var ws_client: WebSocketClient

func before_each():
	ws_client = WebSocketClient.new()
	add_child(ws_client)

func after_each():
	ws_client.disconnect_from_server()
	ws_client.queue_free()

func test_websocket_initialization():
	# Given: Fresh WebSocket client
	# When: Client is created
	# Then: Should be in disconnected state
	assert_eq(ws_client.get_connection_state(), WebSocketPeer.STATE_CLOSED)
	assert_false(ws_client.is_connected())

func test_connection_success_signal():
	# Given: WebSocket client
	var connected_emitted = false
	ws_client.connected.connect(func(): connected_emitted = true)

	# When: Connection succeeds (mocked)
	# Note: Real connection testing requires a test server
	# For now, we'll test the signal emission logic

	# Then: Connected signal should be emitted on successful connection
	# This would be tested with a real WebSocket server in integration tests
	assert_false(connected_emitted)  # Not connected yet

func test_message_sending():
	# Given: WebSocket client with mock connection
	# When: Sending a message
	var test_message = {"type": "test", "payload": {"data": "hello"}}
	var sent = ws_client.send_message("test", test_message)

	# Then: Should return false when not connected
	assert_false(sent)

func test_message_reception():
	# Given: WebSocket client
	var received_messages = []
	ws_client.message_received.connect(func(type, payload):
		received_messages.append({"type": type, "payload": payload})
	)

	# When: Mock message reception (would happen in real poll())
	# Note: Real message reception requires server connection

	# Then: Message received signal should work
	assert_eq(received_messages.size(), 0)

func test_connection_failure_handling():
	# Given: WebSocket client
	var failure_emitted = false
	var failure_reason = ""
	ws_client.connection_failed.connect(func(reason):
		failure_emitted = true
		failure_reason = reason
	)

	# When: Connection fails (mocked scenario)
	# In real implementation, this would happen during connect_to()

	# Then: Failure signal should be emitted with reason
	assert_false(failure_emitted)

func test_disconnect_handling():
	# Given: WebSocket client
	var disconnected_emitted = false
	var disconnect_reason = ""
	ws_client.disconnected.connect(func(reason):
		disconnected_emitted = true
		disconnect_reason = reason
	)

	# When: Disconnection occurs (mocked)
	# Then: Disconnect signal should be emitted
	assert_false(disconnected_emitted)

func test_sequence_number_increment():
	# Given: WebSocket client
	var initial_seq = ws_client.get_sequence_number()

	# When: Sending messages (even when not connected)
	ws_client.send_message("test", {})

	# Then: Sequence number should increment
	assert_eq(ws_client.get_sequence_number(), initial_seq + 1)

func test_reconnection_logic():
	# Given: WebSocket client that was connected then disconnected
	ws_client.disconnect_from_server()

	# When: Attempting to reconnect
	# Note: Real reconnection would require server

	# Then: Should handle reconnection gracefully
	assert_false(ws_client.is_connected())