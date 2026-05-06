import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/sent_command.dart';

/// Controller para histórico de comandos enviados
class SentCommandsController extends ChangeNotifier {
  SentCommandResponse? _sentCommands;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;

  // Getters
  SentCommandResponse? get sentCommands => _sentCommands;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMorePages => _sentCommands?.pagination.hasNextPage ?? false;

  List<SentCommand> get commands => _sentCommands?.data ?? [];

  /// Carregar histórico de comandos
  Future<void> loadSentCommands({bool forceRefresh = false, int? page}) async {
    if (_isLoading && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final targetPage = page ?? _currentPage;
      print('\n🔄 ========== CARREGANDO COMANDOS ENVIADOS ==========');
      print('📅 Data/Hora: ${DateTime.now()}');
      print('📄 Página: $targetPage');
      
      final response = await gpsapis.getSentCommands(page: targetPage);
      
      if (response != null) {
        if (forceRefresh || page != null) {
          _sentCommands = response;
          _currentPage = targetPage;
        } else {
          // Merge com lista existente para paginação
          final existingData = _sentCommands?.data ?? [];
          _sentCommands = SentCommandResponse(
            data: [...existingData, ...response.data],
            pagination: response.pagination,
          );
        }
        print('✅ Comandos carregados: ${response.data.length}');
      } else {
        _error = 'Nenhum dado retornado da API';
        print('⚠️ Nenhum dado retornado da API');
      }
    } catch (e, stackTrace) {
      _error = 'Erro ao carregar comandos: $e';
      print('\n❌ ========== ERRO AO CARREGAR COMANDOS ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
    } finally {
      _isLoading = false;
      notifyListeners();
      print('\n✅ Processo de carregamento finalizado');
      print('=' * 60 + '\n');
    }
  }

  /// Carregar próxima página
  Future<void> loadNextPage() async {
    if (hasMorePages && !_isLoading) {
      _currentPage++;
      await loadSentCommands(page: _currentPage);
    }
  }
}





































