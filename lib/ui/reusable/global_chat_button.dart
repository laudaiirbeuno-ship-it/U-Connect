import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/chat/views/chat_screen.dart';
import 'package:uconnect/utils/translation_helper.dart';

/// Botão de chat global flutuante que aparece em todas as páginas
/// Pode ser usado dentro de um Stack com Positioned ou como FloatingActionButton
class GlobalChatButton extends StatelessWidget {
  /// Se true, retorna um Positioned widget (para usar em Stack)
  /// Se false, retorna um FloatingActionButton simples
  final bool usePositioned;
  final double? bottomOffset;
  final double? rightOffset;
  final double? leftOffset;
  /// Se true, posiciona o botão à esquerda (útil quando há FloatingActionButton na direita)
  final bool alignLeft;

  const GlobalChatButton({
    Key? key,
    this.usePositioned = true,
    this.bottomOffset,
    this.rightOffset,
    this.leftOffset,
    this.alignLeft = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        final button = FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(),
              ),
            );
          },
          backgroundColor: colorProvider.primaryColor,
          child: Icon(
            Icons.chat,
            color: Colors.white,
            size: 28,
          ),
          tooltip: TranslationHelper.translateSync(
            context,
            'Chat',
            'Chat',
          ),
          elevation: 6,
          heroTag: 'global_chat_button', // Tag única para evitar conflitos
        );

        if (usePositioned) {
          if (alignLeft) {
            return Positioned(
              bottom: bottomOffset ?? 100, // Posição acima do bottom navigation
              left: leftOffset ?? 16,
              child: button,
            );
          } else {
            return Positioned(
              bottom: bottomOffset ?? 100, // Posição acima do bottom navigation
              right: rightOffset ?? 16,
              child: button,
            );
          }
        }

        return button;
      },
    );
  }
}
