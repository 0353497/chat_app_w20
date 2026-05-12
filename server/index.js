const WebSocket = require('ws');
const http = require('http');

const PORT = process.env.PORT || 8080;

const server = http.createServer();

// Simple HTTP health endpoint so container healthchecks can verify the server
server.on('request', (req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('WebSocket server running');
});
const wss = new WebSocket.Server({ server });

const clients = new Map();
const usernameMap = new Map();

wss.on('connection', (ws) => {
    console.log('Client connected');

    const clientId = Date.now() + Math.random();

    const clientData = {
        id: clientId,
        bounds: { width: 0, height: 0 },
        x: 0,
        y: 0,
        ws: ws
    };

    clients.set(clientId, clientData);

    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data);
            console.log('Received message:', message);

            // Handle bounds update (existing behavior)
            if (message.type === 'set_bounds') {
                clientData.bounds = message.data;
                console.log(`Client ${clientId} bounds set to:`, clientData.bounds);
                sendMoveEvent(clientData);
                return;
            }

            // Register a username for this client (allows routing)
            if (message.type === 'register') {
                const username = String(message.username || '').trim();
                if (!username) {
                    ws.send(JSON.stringify({ type: 'error', error: 'invalid_username' }));
                    return;
                }

                // Save username on clientData
                clientData.username = username;

                // Add clientId to usernameMap
                if (!usernameMap.has(username)) usernameMap.set(username, new Set());
                usernameMap.get(username).add(clientId);

                console.log(`Client ${clientId} registered as '${username}'`);

                // Acknowledge registration and send current online users
                ws.send(JSON.stringify({ type: 'registered', username }));
                broadcastUserList();
                return;
            }

            // Global chat message: { type: 'chat_message', text: '...' }
            if (message.type === 'chat_message') {
                const text = message.text;

                if (!clientData.username) {
                    ws.send(JSON.stringify({ type: 'error', error: 'not_registered' }));
                    return;
                }

                if (typeof text !== 'string' || !text.trim()) {
                    ws.send(JSON.stringify({ type: 'error', error: 'invalid_message' }));
                    return;
                }

                const payload = {
                    type: 'chat_message',
                    from: clientData.username,
                    text: text.trim(),
                    timestamp: Date.now(),
                };

                broadcastToAll(payload);

                // Acknowledge to sender
                ws.send(JSON.stringify({ type: 'message_status', status: 'delivered' }));
                return;
            }
        } catch (error) {
            console.error('Error processing message:', error);
        }
    });

    const moveInterval = setInterval(() => {
        if (clientData.bounds.width && clientData.bounds.height) {
            clientData.x = Math.random() * (clientData.bounds.width - 50);
            clientData.y = Math.random() * (clientData.bounds.height - 50);

            sendMoveEvent(clientData);
        }
    }, 500);

    ws.on('close', () => {
        console.log(`Client ${clientId} disconnected`);
        clearInterval(moveInterval);
        // Remove from clients map
        clients.delete(clientId);

        // Remove from usernameMap if registered
        if (clientData.username) {
            const set = usernameMap.get(clientData.username);
            if (set) {
                set.delete(clientId);
                if (set.size === 0) usernameMap.delete(clientData.username);
            }
            // Broadcast updated user list
            broadcastUserList();
        }
    });

    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
});

function sendMoveEvent(clientData) {
    const message = {
        type: 'move_event',
        x: clientData.x,
        y: clientData.y
    };

    try {
        clientData.ws.send(JSON.stringify(message));
    } catch (error) {
        console.error('Error sending message:', error);
    }
}

function broadcastUserList() {
    const users = Array.from(usernameMap.keys());
    const payload = JSON.stringify({ type: 'user_list', users });
    clients.forEach((c) => {
        try {
            if (c.ws && c.ws.readyState === c.ws.OPEN) c.ws.send(payload);
        } catch (err) {
            console.error('Error sending user_list:', err);
        }
    });
}

function broadcastToAll(message) {
    const payload = JSON.stringify(message);
    clients.forEach((c) => {
        try {
            if (c.ws && c.ws.readyState === c.ws.OPEN) c.ws.send(payload);
        } catch (err) {
            console.error('Error broadcasting message:', err);
        }
    });
}

server.listen(PORT, '0.0.0.0', () => {
    console.log(`WebSocket server listening on port ${PORT}`);
    console.log(`WebSocket URL: ws://0.0.0.0:${PORT}`);
});

process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');

    clients.forEach((clientData) => {
        clientData.ws.close();
    });

    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});
