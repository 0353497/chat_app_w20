import 'dart:async';
import 'dart:convert';

import 'package:chat_app/services/chat_service.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  TextEditingController controller = TextEditingController();

  final List<Map<String, dynamic>> messages = [];
  final List<String> users = [];
  late final StreamSubscription _sub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sub = ChatService.instance().stream.listen((data) {
      dynamic decoded;
      try {
        if (data is String) {
          decoded = jsonDecode(data);
        } else {
          decoded = data;
        }
      } catch (_) {
        decoded = null;
      }

      if (decoded is Map) {
        final type = decoded['type'];

        if (type == 'chat_message') {
          final from = decoded['from']?.toString() ?? 'anonymous';
          final text = decoded['text']?.toString() ?? '';
          setState(() {
            messages.add({'from': from, 'text': text});
          });
        } else if (type == 'user_list') {
          final list = decoded['users'];
          if (list is List) {
            setState(() {
              users.clear();
              users.addAll(list.map((e) => e.toString()));
            });
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _scrollController.dispose();
    ChatService.instance().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (users.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    final name = users[i];
                    return Column(
                      children: [
                        CircleAvatar(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(fontSize: 12)),
                      ],
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: users.length,
                ),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final from = msg['from']?.toString() ?? 'anonymous';
                  final text = msg['text']?.toString() ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        from.isNotEmpty ? from[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(
                      from,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(text),
                  );
                },
              ),
            ),
            SizedBox(
              height: 120,
              child: Form(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        validator: (value) {
                          if (value == null) return "value can not be null";
                          if (value.trim().isEmpty) {
                            return "value can not be null";
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        ChatService.instance().sendMessage(text);
                        controller.clear();
                      },
                      icon: Icon(Icons.check),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
