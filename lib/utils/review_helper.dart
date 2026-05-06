import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/utils/user_permissions.dart';
import 'package:uconnect/ui/reusable/review_modal.dart';

class ReviewHelper {
  /// Verifica se deve mostrar o modal de avaliação
  /// Retorna true se:
  /// - O usuário não é admin
  /// - O usuário ainda não avaliou
  /// - Já se passaram pelo menos 3 dias desde o último login (ou configuração personalizada)
  static Future<bool> shouldShowReviewModal() async {
    try {
      // Verificar se é admin
      final isAdmin = await UserPermissions.isAdmin();
      if (isAdmin) {
        return false; // Admins não veem o modal
      }

      // Verificar se já avaliou
      final prefs = await SharedPreferences.getInstance();
      final hasReviewed = prefs.getBool('has_reviewed') ?? false;
      if (hasReviewed) {
        return false; // Já avaliou, não mostrar novamente
      }

      // Verificar se já passou o tempo mínimo desde o primeiro uso
      final firstUseDate = prefs.getString('first_use_date');
      if (firstUseDate == null) {
        // Primeira vez usando o app, marcar data
        await prefs.setString('first_use_date', DateTime.now().toIso8601String());
        return false; // Não mostrar imediatamente na primeira vez
      }

      final firstUse = DateTime.parse(firstUseDate);
      final daysSinceFirstUse = DateTime.now().difference(firstUse).inDays;
      
      // Mostrar após 3 dias de uso (pode ser configurado)
      const minDaysBeforeReview = 3;
      if (daysSinceFirstUse < minDaysBeforeReview) {
        return false; // Ainda não passou tempo suficiente
      }

      // Verificar se já tentou mostrar recentemente (evitar spam)
      final lastShownDate = prefs.getString('review_modal_last_shown');
      if (lastShownDate != null) {
        final lastShown = DateTime.parse(lastShownDate);
        final daysSinceLastShown = DateTime.now().difference(lastShown).inDays;
        if (daysSinceLastShown < 7) {
          return false; // Já mostrou recentemente, aguardar 7 dias
        }
      }

      return true; // Pode mostrar o modal
    } catch (e) {
      print('❌ Erro ao verificar se deve mostrar modal de avaliação: $e');
      return false;
    }
  }

  /// Mostra o modal de avaliação se necessário
  static Future<void> showReviewModalIfNeeded(BuildContext context) async {
    try {
      final shouldShow = await shouldShowReviewModal();
      if (shouldShow) {
        // Marcar que tentou mostrar
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('review_modal_last_shown', DateTime.now().toIso8601String());

        // Mostrar o modal
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false, // Não permitir fechar clicando fora
            builder: (context) => ReviewModal(),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao mostrar modal de avaliação: $e');
    }
  }

  /// Reseta o estado de avaliação (útil para testes)
  static Future<void> resetReviewState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_reviewed');
    await prefs.remove('review_date');
    await prefs.remove('review_modal_last_shown');
    await prefs.remove('first_use_date');
  }
}

































