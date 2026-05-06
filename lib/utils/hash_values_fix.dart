// Fix para hashValues e hashList que foram removidos do Flutter
// Este arquivo adiciona essas funções de volta para compatibilidade

import 'dart:collection';

/// Função hashValues - substituída por Object.hash no Flutter moderno
/// Mantida para compatibilidade com pacotes antigos
int hashValues(Object? arg01, Object? arg02, [Object? arg03, Object? arg04, Object? arg05, Object? arg06, Object? arg07, Object? arg08, Object? arg09, Object? arg10, Object? arg11, Object? arg12, Object? arg13, Object? arg14, Object? arg15, Object? arg16, Object? arg17, Object? arg18, Object? arg19, Object? arg20]) {
  int result = 0;
  result = Object.hash(result, arg01);
  result = Object.hash(result, arg02);
  if (arg03 != null) result = Object.hash(result, arg03);
  if (arg04 != null) result = Object.hash(result, arg04);
  if (arg05 != null) result = Object.hash(result, arg05);
  if (arg06 != null) result = Object.hash(result, arg06);
  if (arg07 != null) result = Object.hash(result, arg07);
  if (arg08 != null) result = Object.hash(result, arg08);
  if (arg09 != null) result = Object.hash(result, arg09);
  if (arg10 != null) result = Object.hash(result, arg10);
  if (arg11 != null) result = Object.hash(result, arg11);
  if (arg12 != null) result = Object.hash(result, arg12);
  if (arg13 != null) result = Object.hash(result, arg13);
  if (arg14 != null) result = Object.hash(result, arg14);
  if (arg15 != null) result = Object.hash(result, arg15);
  if (arg16 != null) result = Object.hash(result, arg16);
  if (arg17 != null) result = Object.hash(result, arg17);
  if (arg18 != null) result = Object.hash(result, arg18);
  if (arg19 != null) result = Object.hash(result, arg19);
  if (arg20 != null) result = Object.hash(result, arg20);
  return result;
}

/// Função hashList - substituída por Object.hashAll no Flutter moderno
/// Mantida para compatibilidade com pacotes antigos
int hashList(Iterable<Object?>? arguments) {
  if (arguments == null) return 0;
  return Object.hashAll(arguments);
}





































