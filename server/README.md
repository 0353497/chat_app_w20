# WebSocket Server

This Node.js WebSocket server provides two features used by the app in this repository:

- Real-time position feed for a demo moving box (`set_bounds` / `move_event`) used by the Flutter UI
- Global messaging to all connected users (`register` / `chat_message`)

The server listens on port `8080` by default.

Quick start
```bash
cd server
npm install
npm start
```

Docker
```bash
docker-compose up -d
```

WebSocket API

1) Register a username

Client → Server
```json
{ "type": "register", "username": "alice" }
```

Server → Client (ack)
```json
{ "type": "registered", "username": "alice" }
```

After registration the server broadcasts the current online user list to all clients:
```json
{ "type": "user_list", "users": ["alice","bob"] }
```

2) Global chat message

Client → Server
```json
{ "type": "chat_message", "text": "Hello everyone" }
```

Server → All connected clients
```json
{ "type": "chat_message", "from": "alice", "text": "Hello everyone", "timestamp": 1650000000000 }
```

Server → Sender (status)
```json
{ "type": "message_status", "status": "delivered" }
```

3) Demo position feed (used by the Flutter demo)

Client → Server
```json
{ "type": "set_bounds", "data": { "width": 400, "height": 800 } }
```

Server → Client (periodic)
```json
{ "type": "move_event", "x": 125.5, "y": 250.3 }
```

Notes & behavior
- A single username may have multiple connected devices.
- Chat messages are broadcast to all currently connected clients.
- No long-term persistence or offline message queue is implemented by default.
- The server will broadcast `user_list` on register and on disconnect.

Testing with `websocat` (or any WebSocket client)
```bash
# open two terminals and connect
websocat ws://127.0.0.1:8080
# register
{"type":"register","username":"alice"}

websocat ws://127.0.0.1:8080
{"type":"register","username":"bob"}

# send global message from alice
{"type":"chat_message","text":"Hi everyone"}
```

Integrating with the Flutter app
- The Flutter client should first connect to `ws://<host>:8080` then send a `register` message with a username.
- To show online users use messages of type `user_list`.

Extending the server
- Persist messages for offline delivery
- Add message IDs and delivery/read receipts
- Add authentication

If you want, I can update this README to include example Flutter client code snippets for registering and sending messages.
