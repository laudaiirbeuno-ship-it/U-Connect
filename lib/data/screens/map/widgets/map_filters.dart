import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';

class MapFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final mapController = context.watch<MapController>();

    // Usar chaves originais para comparação interna
    final filterKeys = ['Todos', 'Online', 'Offline', 'Em movimento', 'Parado', 'Bloqueado'];
    final filters = filterKeys.map((key) => TranslationHelper.translateSync(
      context, 
      key == 'Todos' ? 'Todos' : key == 'Online' ? 'Online' : key == 'Offline' ? 'Offline' : key == 'Em movimento' ? 'Em movimento' : key == 'Parado' ? 'Parado' : 'Bloqueado',
      key == 'Todos' ? 'All' : key == 'Online' ? 'Online' : key == 'Offline' ? 'Offline' : key == 'Em movimento' ? 'Moving' : key == 'Parado' ? 'Stopped' : 'Blocked',
    )).toList();

    return Container(
      height: 36, // Botões menores
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filterKey = filterKeys[index];
          final filter = filters[index];
          // Comparar usando a chave original
          final isSelected = mapController.selectedFilter == filterKey || mapController.selectedFilter == filter;
          
          // Ícones para cada filtro
          IconData? filterIcon;
          switch (filterKey) {
            case 'Todos':
              filterIcon = Icons.apps;
              break;
            case 'Online':
              filterIcon = Icons.check_circle;
              break;
            case 'Offline':
              filterIcon = Icons.cancel;
              break;
            case 'Em movimento':
              filterIcon = Icons.directions_run;
              break;
            case 'Parado':
              filterIcon = Icons.pause_circle;
              break;
            case 'Bloqueado':
              filterIcon = Icons.block;
              break;
          }

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.9 + (value * 0.1),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                mapController.setSelectedFilter(filterKey);
              },
              child: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5), // Menor padding
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorProvider.primaryColor // Cor principal
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20), // Arredondado (pill)
                  border: Border.all(
                    color: isSelected
                        ? colorProvider.primaryColor
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filterIcon != null) ...[
                      Icon(
                        filterIcon,
                        size: 13, // Ícone menor
                        color: isSelected
                            ? Colors.white
                            : colorProvider.primaryColor, // Cor principal
                      ),
                      SizedBox(width: 4),
                    ],
                    Text(
                      filter,
                      style: TextStyle(
                        fontSize: 10, // Texto menor
                        fontWeight: FontWeight.normal, // Sem negrito
                        color: isSelected
                            ? Colors.white // Branco quando ativo
                            : Color(0xFF1A1A1A), // Preto quando inativo
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


