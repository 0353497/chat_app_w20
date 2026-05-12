import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  WebSocketChannel? _channel;
  double x = 0;
  double y = 0;
  bool _boundsSent = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void setBounds(BoxConstraints contrainst) {
    _channel?.sink.add(
      jsonEncode({
        "type": "set_bounds",
        "data": {"width": contrainst.maxWidth, "height": contrainst.maxHeight},
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!_boundsSent) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _boundsSent = true;
                setBounds(constraints);
              });
            }

            return Stack(
              children: [
                AnimatedPositioned(
                  left: x,
                  top: y,
                  width: 50,
                  height: 50,
                  duration: Duration(milliseconds: 200),
                  child: Container(color: Colors.blue),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void init() {
    final host = _preferredHost();
    _channel = WebSocketChannel.connect(Uri.parse('ws://$host:8080'));

    _channel?.stream.listen((rawData) {
      print("get: $rawData");
      final data = jsonDecode(rawData);
      if (data["type"] == "move_event") {
        setState(() {
          x = data["x"] as double;
          y = data["y"] as double;
        });
      }
    });
  }

  String _preferredHost() {
    if (Platform.isAndroid) return '10.0.2.2';
    if (Platform.isIOS) return '127.0.0.1';
    return '127.0.0.1';
  }
}
