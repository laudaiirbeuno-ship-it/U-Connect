import 'package:flutter/material.dart';

/// Widget para exibir a logo "ONE NOVA ERA RASTREAMENTO VEICULAR"
/// Suporta dois estilos: padrão (colorido) e personalizado (preto com detalhes amarelos)
class OneNovaEraLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool useCustomStyle; // true = preto com detalhes amarelos, false = padrão colorido
  
  const OneNovaEraLogo({
    Key? key,
    this.width,
    this.height,
    this.useCustomStyle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoWidth = width ?? 280.0;
    final logoHeight = height ?? 120.0;
    
    // Cores baseadas no estilo
    final yellowColor = useCustomStyle ? Color(0xFFFFD700) : Color(0xFFFFEB3B); // Amarelo mais vibrante no custom
    final whiteColor = useCustomStyle ? Colors.black : Colors.white;
    final blackColor = useCustomStyle ? Colors.black : Colors.black;
    final greenColor = useCustomStyle ? yellowColor : Color(0xFF4CAF50); // Verde vira amarelo no custom
    
    return Container(
      width: logoWidth,
      height: logoHeight,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Fundo com borda branca e preta
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: whiteColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Conteúdo principal
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "ONE" com ícone de localização
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // O = Ícone de localização
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: yellowColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: blackColor,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Círculo interno
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: blackColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: whiteColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check,
                                color: greenColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // N
                    _buildLetter('N', yellowColor, blackColor, 42),
                    SizedBox(width: 4),
                    // E
                    _buildLetter('E', whiteColor, blackColor, 42),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // "NOVA ERA" em banner
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: blackColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border(
                      right: BorderSide(
                        color: yellowColor,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NOVA',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: blackColor,
                              offset: Offset(1, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ERA',
                        style: TextStyle(
                          color: yellowColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: blackColor,
                              offset: Offset(1, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 6),
                
                // "RASTREAMENTO VEICULAR"
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: blackColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RASTREAMENTO VEICULAR',
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Swoosh decorativo (opcional, apenas no estilo padrão)
          if (!useCustomStyle)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [whiteColor, yellowColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLetter(String letter, Color fillColor, Color borderColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: borderColor,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
