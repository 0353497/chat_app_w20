import 'package:chat_app/pages/homepage.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:flutter/material.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: textEditingController,
                  validator: (value) {
                    if (value == null) return "value can not be empty";
                    if (value.isEmpty) return "value can not be empty";
                    return null;
                  },
                ),
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        ChatService.instance().register(
                          textEditingController.value.text,
                        );
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => Homepage()));
                      }
                    },
                    child: Text("Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
