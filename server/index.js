const WebSocket = require('ws');
const http = require('http');

const PORT = process.env.PORT || 8080;

const server = http.createServer();
const wss = new WebSocket.Server({ server });

const clients = new Map();

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

            if (message.type === 'set_bounds') {
                // Update client bounds
                clientData.bounds = message.data;
                console.log(`Client ${clientId} bounds set to:`, clientData.bounds);

                sendMoveEvent(clientData);
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
        clients.delete(clientId);
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
