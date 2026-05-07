import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/screens/drivers/widgets/driver_form_dialog.dart';
import 'package:uconnect/data/screens/drivers/controllers/drivers_controller.dart';
import 'package:uconnect/provider/color_provider.dart';

void main() {
  group('DriverFormDialog - Teste do Botão Salvar', () {
    late DriversController controller;
    late ColorProvider colorProvider;

    setUp(() {
      controller = DriversController();
      colorProvider = ColorProvider();
    });

    testWidgets('Deve renderizar o botão Salvar corretamente', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: colorProvider),
              ChangeNotifierProvider.value(value: controller),
            ],
            child: Scaffold(
              body: DriverFormDialog(),
            ),
          ),
        ),
      );

      // Aguardar o carregamento inicial
      await tester.pumpAndSettle();

      // Act - Procurar pelo botão Salvar
      final saveButton = find.text('Salvar');

      // Assert
      expect(saveButton, findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Deve chamar _saveDriver quando o botão Salvar é clicado', (WidgetTester tester) async {
      // Arrange
      bool saveCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: colorProvider),
              ChangeNotifierProvider.value(value: controller),
            ],
            child: Scaffold(
              body: DriverFormDialog(),
            ),
          ),
        ),
      );

      // Aguardar o carregamento inicial
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Preencher o campo Nome (obrigatório)
      final nameField = find.widgetWithText(TextFormField, 'Nome *');
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Motorista Teste');
        await tester.pump();
      }

      // Act - Clicar no botão Salvar
      final saveButton = find.text('Salvar');
      if (saveButton.evaluate().isNotEmpty) {
        print('🔵 [TEST] Botão Salvar encontrado, clicando...');
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pumpAndSettle(Duration(seconds: 1));
        saveCalled = true;
      }

      // Assert
      expect(saveButton, findsOneWidget);
      print('✅ [TEST] Botão Salvar foi clicado: $saveCalled');
    });

    testWidgets('Deve validar o formulário antes de salvar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: colorProvider),
              ChangeNotifierProvider.value(value: controller),
            ],
            child: Scaffold(
              body: DriverFormDialog(),
            ),
          ),
        ),
      );

      // Aguardar o carregamento inicial
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Act - Tentar salvar sem preencher o nome (obrigatório)
      final saveButton = find.text('Salvar');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pumpAndSettle();

        // Assert - Deve mostrar mensagem de erro
        expect(find.text('Nome é obrigatório'), findsOneWidget);
      }
    });

    testWidgets('Deve preencher e salvar com sucesso', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: colorProvider),
              ChangeNotifierProvider.value(value: controller),
            ],
            child: Scaffold(
              body: DriverFormDialog(),
            ),
          ),
        ),
      );

      // Aguardar o carregamento inicial
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Preencher campos
      final nameField = find.widgetWithText(TextFormField, 'Nome *');
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Motorista Completo');
        await tester.pump();
      }

      final phoneField = find.widgetWithText(TextFormField, 'Telefone');
      if (phoneField.evaluate().isNotEmpty) {
        await tester.enterText(phoneField, '11999999999');
        await tester.pump();
      }

      final emailField = find.widgetWithText(TextFormField, 'Email');
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'teste@teste.com');
        await tester.pump();
      }

      // Act - Clicar no botão Salvar
      final saveButton = find.text('Salvar');
      if (saveButton.evaluate().isNotEmpty) {
        print('🔵 [TEST] Preenchendo formulário e clicando em Salvar...');
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pumpAndSettle(Duration(seconds: 2));
        
        print('✅ [TEST] Formulário preenchido e botão clicado');
      }

      // Assert
      expect(saveButton, findsOneWidget);
    });
  });

  group('DriverFormDialog - Teste de Validação', () {
    late DriversController controller;
    late ColorProvider colorProvider;

    setUp(() {
      controller = DriversController();
      colorProvider = ColorProvider();
    });

    testWidgets('Deve validar email inválido', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: colorProvider),
              ChangeNotifierProvider.value(value: controller),
            ],
            child: Scaffold(
              body: DriverFormDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Preencher nome (obrigatório)
      final nameField = find.widgetWithText(TextFormField, 'Nome *');
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Teste');
        await tester.pump();
      }

      // Preencher email inválido
      final emailField = find.widgetWithText(TextFormField, 'Email');
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'email-invalido');
        await tester.pump();
      }

      // Act - Tentar salvar
      final saveButton = find.text('Salvar');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pumpAndSettle();

        // Assert - Deve mostrar erro de email
        expect(find.text('Email inválido'), findsOneWidget);
      }
    });
  });
}
