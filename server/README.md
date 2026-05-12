# WebSocket Chat Server

A Node.js WebSocket server for the Flutter chat app that handles real-time position updates.

## Local Development

### Prerequisites
- Node.js 16+ installed

### Installation
```bash
cd server
npm install
```

### Run
```bash
npm start
```

The server will listen on `ws://localhost:8080`

### Development with auto-reload
```bash
npm run dev
```

## Docker Deployment

### Build Docker Image
```bash
docker build -t chat-app-websocket .
```

### Run with Docker
```bash
docker run -p 8080:8080 chat-app-websocket
```

### Run with Docker Compose
```bash
docker-compose up -d
```

### Stop and Remove
```bash
docker-compose down
```

## Communication Protocol

### Client → Server
```json
{
  "type": "set_bounds",
  "data": {
    "width": 400,
    "height": 800
  }
}
```

### Server → Client
```json
{
  "type": "move_event",
  "x": 125.5,
  "y": 250.3
}
```

## Features
- Real-time position updates
- Multiple concurrent clients support
- Automatic position generation within screen bounds
- Graceful shutdown handling
