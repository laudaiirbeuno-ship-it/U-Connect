import 'package:flutter/material.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/model/internal_chat_message.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ChatMessageBubble extends StatelessWidget {
  final InternalChatMessage message;
  final bool isSent;
  final ColorProvider colorProvider;
  final Color btnColor;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onEdit;
  final VoidCallback? onImageTap;
  final VoidCallback? onAudioTap;
  final VoidCallback? onFileDownload;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isSent,
    required this.colorProvider,
    required this.btnColor,
    this.onReply,
    this.onReact,
    this.onDelete,
    this.onPin,
    this.onEdit,
    this.onImageTap,
    this.onAudioTap,
    this.onFileDownload,
  }) : super(key: key);

  String _formatTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (message.isDeleted) {
      return Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            TranslationHelper.translateSync(
              context,
              'Mensagem excluída',
              'Message deleted',
            ),
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageMenu(context),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 8,
            left: isSent ? 50 : 8,
            right: isSent ? 8 : 50,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar do remetente (apenas para mensagens recebidas)
              if (!isSent)
                Padding(
                  padding: EdgeInsets.only(right: 8, bottom: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: message.senderAvatar != null
                        ? CachedNetworkImageProvider(message.senderAvatar!)
                        : null,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: message.senderAvatar == null
                        ? Text(
                            message.senderName != null && message.senderName!.isNotEmpty
                                ? message.senderName![0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSent ? btnColor : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isSent ? Radius.circular(4) : null,
                      bottomLeft: !isSent ? Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do remetente (apenas para mensagens recebidas)
                      if (!isSent && message.senderName != null && message.senderName!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            message.senderName!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSent
                                  ? colorScheme.onPrimary.withOpacity(0.8)
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
              // Mensagem respondida
              if (message.replyTo != null) _buildReplyPreview(context),
              
              // Fixado
              if (message.isPinned)
                Row(
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 14,
                      color: isSent
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      TranslationHelper.translateSync(context, 'Fixado', 'Pinned'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isSent
                            ? colorScheme.onPrimary.withOpacity(0.7)
                            : colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              
              // Solicitação
              if (message.isRequest)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        TranslationHelper.translateSync(context, 'Solicitação', 'Request'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Conteúdo da mensagem
              if (message.hasFile) _buildFileContent(context) else _buildTextContent(context),

              // Reações
              if (message.reactions != null && message.reactions!.isNotEmpty)
                _buildReactions(context),

                      // Rodapé (hora e status)
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSent
                                  ? colorScheme.onPrimary.withOpacity(0.7)
                                  : colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSent
                                  ? colorScheme.onPrimary.withOpacity(0.6)
                                  : colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          if (isSent) ...[
                            SizedBox(width: 4),
                            Icon(
                              message.isReadByReceiver ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isReadByReceiver
                                  ? Colors.blue[300]
                                  : colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSent ? Colors.white.withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isSent ? Colors.white : btnColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Respondendo a', 'Replying to'),
            style: TextStyle(
              fontSize: 11,
              color: isSent ? Colors.white70 : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            message.replyTo!.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isSent ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Text(
      message.message,
      style: TextStyle(
        color: isSent ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    if (message.isImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.message.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isSent ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          GestureDetector(
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.fileUrl ?? '',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: Icon(Icons.error),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (message.isAudio) {
      return InkWell(
        onTap: onAudioTap,
        child: Row(
          children: [
            Icon(Icons.audiotrack, color: isSent ? Colors.white : Colors.black87),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? TranslationHelper.translateSync(
                      context,
                      'Áudio',
                      'Audio',
                    ),
                    style: TextStyle(
                      color: isSent ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    TranslationHelper.translateSync(
                      context,
                      'Toque para reproduzir',
                      'Tap to play',
                    ),
                    style: TextStyle(
                      color: isSent ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: isSent ? Colors.white70 : Colors.grey[600],
            ),
          ],
        ),
      );
    } else if (message.fileType != null && message.fileType!.contains('pdf')) {
      // PDF - mostrar preview
      return InkWell(
        onTap: () {
          if (message.fileUrl != null) {
            // Abrir visualizador de PDF
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text(message.fileName ?? 'PDF'),
                  ),
                  body: message.fileUrl != null
                      ? SfPdfViewer.network(
                          message.fileUrl!,
                          onDocumentLoadFailed: (details) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao carregar PDF: ${details.error}')),
                            );
                          },
                        )
                      : Center(child: Text('URL do PDF não disponível')),
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: isSent ? Colors.white : Colors.red, size: 40),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? TranslationHelper.translateSync(
                      context,
                      'Documento PDF',
                      'PDF Document',
                    ),
                    style: TextStyle(
                      color: isSent ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    TranslationHelper.translateSync(
                      context,
                      'Toque para visualizar',
                      'Tap to view',
                    ),
                    style: TextStyle(
                      color: isSent ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.visibility, color: isSent ? Colors.white70 : Colors.grey[600]),
          ],
        ),
      );
    } else {
      // Documento genérico
      return InkWell(
        onTap: onFileDownload ?? () async {
          if (message.fileUrl != null) {
            final uri = Uri.parse(message.fileUrl!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        },
        child: Row(
          children: [
            Icon(Icons.insert_drive_file, color: isSent ? Colors.white : Colors.black87),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? TranslationHelper.translateSync(
                      context,
                      'Documento',
                      'Document',
                    ),
                    style: TextStyle(
                      color: isSent ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.message.isNotEmpty)
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isSent ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.download, color: isSent ? Colors.white70 : Colors.grey[600]),
          ],
        ),
      );
    }
  }

  Widget _buildReactions(BuildContext context) {
    if (message.reactions == null || message.reactions!.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions!.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value as List;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSent ? Colors.white.withOpacity(0.2) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: 14)),
                if (users.length > 1)
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      '${users.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSent ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: Icon(Icons.reply, color: colorScheme.onSurface),
                title: Text(
                  TranslationHelper.translateSync(
                    context,
                    'Responder',
                    'Reply',
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
            if (onReact != null)
              ListTile(
                leading: Icon(Icons.emoji_emotions, color: colorScheme.onSurface),
                title: Text(
                  TranslationHelper.translateSync(
                    context,
                    'Reagir',
                    'React',
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onReact?.call();
                },
              ),
            if (onPin != null)
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: colorScheme.onSurface,
                ),
                title: Text(
                  TranslationHelper.translateSync(
                    context,
                    message.isPinned ? 'Desfixar' : 'Fixar',
                    message.isPinned ? 'Unpin' : 'Pin',
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onPin?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete, color: colorScheme.error),
                title: Text(
                  TranslationHelper.translateSync(
                    context,
                    'Excluir',
                    'Delete',
                  ),
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}
