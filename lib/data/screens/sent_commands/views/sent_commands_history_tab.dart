import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/data/screens/sent_commands/controllers/sent_commands_controller.dart';
import 'package:uconnect/data/model/sent_command.dart';
import 'package:intl/intl.dart';

class SentCommandsHistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);

    return ChangeNotifierProvider(
      create: (_) => SentCommandsController(),
      child: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<SentCommandsController>(
            builder: (context, controller, child) {
              if (controller.isLoading && controller.commands.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                  ),
                );
              }

              if (controller.error != null && controller.commands.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Erro ao carregar histórico',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        controller.error!,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => controller.loadSentCommands(forceRefresh: true),
                        icon: Icon(Icons.refresh),
                        label: Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorProvider.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.commands.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum comando enviado',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadSentCommands(forceRefresh: true),
                color: colorProvider.primaryColor,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: controller.commands.length + (controller.hasMorePages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.commands.length) {
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: controller.isLoading ? null : () => controller.loadNextPage(),
                            child: controller.isLoading
                                ? CircularProgressIndicator()
                                : Text('Carregar mais'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorProvider.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }

                    final command = controller.commands[index];
                    return _buildCommandCard(command, colorProvider);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommandCard(SentCommand command, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    DateTime? createdAt;
    if (command.createdAt != null && command.createdAt!.isNotEmpty) {
      try {
        createdAt = DateTime.parse(command.createdAt!);
      } catch (e) {
        // Ignore parse errors
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        command.commandTitle ?? 'Comando',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (command.device != null)
                        Row(
                          children: [
                            Icon(Icons.devices, size: 16, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              command.device!.name ?? 'Dispositivo',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: command.status ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: command.status ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        command.status ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: command.status ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        command.statusText,
                        style: TextStyle(
                          color: command.status ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (command.connection != null)
              Row(
                children: [
                  Icon(Icons.signal_cellular_alt, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    'Conexão: ${command.connection}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            if (command.imei != null && command.imei!.isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_android, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    'IMEI: ${command.imei}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (createdAt != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    dateFormat.format(createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (command.response != null && command.response!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resposta:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      command.response!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}





































