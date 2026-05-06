import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/services/internal_chat_service.dart';
import 'package:uconnect/data/model/internal_chat_contact.dart';
import 'package:uconnect/data/screens/chat/views/internal_chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final InternalChatService _chatService = InternalChatService();
  List<InternalChatContact> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final contacts = await _chatService.getContacts();
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationHelper.translateSync(
                context,
                'Erro ao carregar contatos: $e',
                'Error loading contacts: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorProvider = Provider.of<ColorProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Chat Interno', 'Internal Chat'),
        icon: Icons.chat,
        actions: [
          // Botão do UnnicaBot - OCULTO TEMPORARIAMENTE
          // IconButton(
          //   icon: Stack(
          //     children: [
          //       Icon(Icons.smart_toy, color: colorScheme.onPrimary),
          //       Positioned(
          //         right: 0,
          //         top: 0,
          //         child: Container(
          //           padding: EdgeInsets.all(2),
          //           decoration: BoxDecoration(
          //             color: Colors.blue,
          //             shape: BoxShape.circle,
          //           ),
          //           constraints: BoxConstraints(
          //             minWidth: 12,
          //             minHeight: 12,
          //           ),
          //           child: Text(
          //             'AI',
          //             style: TextStyle(
          //               fontSize: 6,
          //               color: Colors.white,
          //               fontWeight: FontWeight.bold,
          //             ),
          //             textAlign: TextAlign.center,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          //   tooltip: TranslationHelper.translateSync(context, 'UnnicaBot', 'UnnicaBot'),
          //   onPressed: () async {
          //     final token = StaticVarMethod.user_api_hash;
          //     if (token != null && token.isNotEmpty) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => UnnicaBotChatScreen(token: token),
          //         ),
          //       );
          //     } else {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text(
          //             TranslationHelper.translateSync(
          //               context,
          //               'Token de autenticação não encontrado',
          //               'Authentication token not found',
          //             ),
          //           ),
          //           backgroundColor: Colors.red,
          //         ),
          //       );
          //     }
          //   },
          // ),
          // Botão de refresh
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
            onPressed: _loadContacts,
            tooltip: TranslationHelper.translateSync(context, 'Atualizar', 'Refresh'),
          ),
        ],
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      SizedBox(height: 16),
                      Text(
                        TranslationHelper.translateSync(
                          context,
                          'Erro ao carregar contatos',
                          'Error loading contacts',
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadContacts,
                        child: Text(TranslationHelper.translateSync(
                          context,
                          'Tentar novamente',
                          'Try again',
                        )),
                      ),
                    ],
                  ),
                )
              : _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                          SizedBox(height: 16),
                          Text(
                            TranslationHelper.translateSync(
                              context,
                              'Nenhum contato disponível',
                              'No contacts available',
                            ),
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadContacts,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return _buildContactItem(contact, colorProvider);
                        },
                      ),
                    ),
    );
  }

  Widget _buildContactItem(InternalChatContact contact, ColorProvider colorProvider) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InternalChatScreen(receiverId: contact.id),
          ),
        ).then((_) {
          // Recarregar contatos quando voltar para atualizar contadores
          _loadContacts();
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                  backgroundImage: contact.avatar != null
                      ? CachedNetworkImageProvider(contact.avatar!)
                      : null,
                  child: contact.avatar == null
                      ? Text(
                          contact.name.isNotEmpty
                              ? contact.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorProvider.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Indicador online
                if (contact.online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            // Informações do contato
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.lastMessageTime != null)
                        Text(
                          contact.lastMessageTime!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.lastMessage ?? TranslationHelper.translateSync(
                            context,
                            'Sem mensagens',
                            'No messages',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.unread > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorProvider.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${contact.unread}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
