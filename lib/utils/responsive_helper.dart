import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helper para responsividade automática em todas as páginas
/// Ajusta automaticamente tamanhos de fonte, padding, margins, etc.
/// baseado no tamanho da tela do dispositivo
class ResponsiveHelper {
  /// Inicializa o ScreenUtil com design base
  /// Design base: iPhone 14 Pro Max (428x926)
  /// NOTA: O ScreenUtil.init() deve ser chamado no builder do MaterialApp
  /// Este método retorna o widget configurado
  static Widget init(BuildContext context, Widget child) {
    return ScreenUtilInit(
      designSize: const Size(428, 926), // iPhone 14 Pro Max como referência
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) => child ?? const SizedBox(),
      child: child,
    );
  }

  /// Retorna tamanho de fonte responsivo
  /// Exemplo: ResponsiveHelper.fontSize(16) retorna 16.sp
  static double fontSize(double size) => size.sp;

  /// Retorna altura responsiva
  /// Exemplo: ResponsiveHelper.height(100) retorna 100.h
  static double height(double size) => size.h;

  /// Retorna largura responsiva
  /// Exemplo: ResponsiveHelper.width(100) retorna 100.w
  static double width(double size) => size.w;

  /// Retorna raio de borda responsivo
  /// Exemplo: ResponsiveHelper.radius(12) retorna 12.r
  static double radius(double size) => size.r;

  /// Retorna padding responsivo
  /// Exemplo: ResponsiveHelper.padding(all: 16) retorna EdgeInsets.all(16.w)
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(all.w);
    }
    return EdgeInsets.only(
      top: (top ?? vertical ?? 0).h,
      bottom: (bottom ?? vertical ?? 0).h,
      left: (left ?? horizontal ?? 0).w,
      right: (right ?? horizontal ?? 0).w,
    );
  }

  /// Retorna margin responsivo
  /// Exemplo: ResponsiveHelper.margin(all: 16) retorna EdgeInsets.all(16.w)
  static EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(all.w);
    }
    return EdgeInsets.only(
      top: (top ?? vertical ?? 0).h,
      bottom: (bottom ?? vertical ?? 0).h,
      left: (left ?? horizontal ?? 0).w,
      right: (right ?? horizontal ?? 0).w,
    );
  }

  /// Retorna SizedBox com altura responsiva
  static Widget verticalSpace(double height) => SizedBox(height: height.h);

  /// Retorna SizedBox com largura responsiva
  static Widget horizontalSpace(double width) => SizedBox(width: width.w);

  /// Verifica se é tela pequena (menor que 360px de largura)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Verifica se é tela média (entre 360px e 600px)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 600;
  }

  /// Verifica se é tela grande (maior que 600px)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// Retorna multiplicador de escala baseado no tamanho da tela
  /// Telas pequenas: 0.9, Telas médias: 1.0, Telas grandes: 1.1
  static double getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.9;
    if (width >= 600) return 1.1;
    return 1.0;
  }

  /// Retorna tamanho de ícone responsivo
  static double iconSize(double size) => size.sp;
}
