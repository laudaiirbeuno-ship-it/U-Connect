import 'package:flutter/material.dart';
import 'package:uconnect/data/screens/chat/views/contacts_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // Redirecionar para a tela de contatos do chat interno
    return ContactsScreen();
  }
}
