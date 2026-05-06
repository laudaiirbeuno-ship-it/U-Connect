import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackButtonPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onBackButtonPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(60.0); // Diminuído de 70.0 para 60.0 (mais compacto)

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: colorProvider.secondaryColor, // Cor secundária no fundo do cabeçalho
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back, 
                  color: colorProvider.primaryColor, // Cor primária nos ícones
                  size: 24
                ),
                onPressed: onBackButtonPressed ??
                    () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        // Lidar com a situação em que não há rota para voltar
                        // Por exemplo, navegar para a tela inicial
                        print(
                            "Não há rota para voltar. Implementar navegação para home se necessário.");
                      }
                    },
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700, // Fonte mais grossa
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



