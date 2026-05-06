// import 'package:workmanager/workmanager.dart';  // Temporariamente desabilitado
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/config/static.dart';

/// Serviço de tarefas em background
/// 
/// Permite atualizar posições de veículos mesmo quando o app está fechado
/// 
/// NOTA: Temporariamente desabilitado devido a problemas de compatibilidade
/// com workmanager 0.5.2 e Flutter/Android atual
class BackgroundService {
  static const String taskName = 'updateVehiclePositions';
  static const String periodicTaskName = 'periodicUpdate';

  /// Inicializar workmanager
  /// Temporariamente desabilitado
  static Future<void> initialize() async {
    print('⚠️ BackgroundService.initialize() desabilitado temporariamente');
    // await Workmanager().initialize(
    //   callbackDispatcher,
    //   isInDebugMode: false,
    // );
  }

  /// Registrar tarefa periódica para atualizar posições
  /// Temporariamente desabilitado
  static Future<void> registerPeriodicTask() async {
    print('⚠️ BackgroundService.registerPeriodicTask() desabilitado temporariamente');
    // await Workmanager().registerPeriodicTask(
    //   periodicTaskName,
    //   taskName,
    //   frequency: const Duration(minutes: 15),
    //   constraints: Constraints(
    //     networkType: NetworkType.connected,
    //     requiresBatteryNotLow: false,
    //     requiresCharging: false,
    //     requiresDeviceIdle: false,
    //     requiresStorageNotLow: false,
    //   ),
    // );
  }

  /// Cancelar tarefa periódica
  /// Temporariamente desabilitado
  static Future<void> cancelPeriodicTask() async {
    print('⚠️ BackgroundService.cancelPeriodicTask() desabilitado temporariamente');
    // await Workmanager().cancelByUniqueName(periodicTaskName);
  }

  /// Executar tarefa única (uma vez)
  /// Temporariamente desabilitado
  static Future<void> executeTaskOnce() async {
    print('⚠️ BackgroundService.executeTaskOnce() desabilitado temporariamente');
    // await Workmanager().registerOneOffTask(
    //   'updateOnce',
    //   taskName,
    //   initialDelay: const Duration(seconds: 5),
    // );
  }
}

/// Callback dispatcher para tarefas em background
/// Temporariamente desabilitado
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     try {
//       print('🔄 Executando tarefa em background: $task');
//       if (StaticVarMethod.user_api_hash == null || StaticVarMethod.user_api_hash!.isEmpty) {
//         print('⚠️ user_api_hash não disponível');
//         return Future.value(false);
//       }
//       final devices = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
//       if (devices != null && devices.isNotEmpty) {
//         print('✅ ${devices.length} veículos atualizados em background');
//         return Future.value(true);
//       }
//       return Future.value(false);
//     } catch (e) {
//       print('❌ Erro na tarefa em background: $e');
//       return Future.value(false);
//     }
//   });
// }

