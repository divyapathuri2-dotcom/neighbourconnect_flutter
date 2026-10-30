import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/main.dart';
import 'package:portifolio/services/api_service.dart';

void main() {
  group('ApiService offline URL handling', () {
    test('preserves local relative image paths', () {
      expect(
        ApiService.resolveUrl('/uploads/posts/example.jpg'),
        '/uploads/posts/example.jpg',
      );
    });

    test('does not rewrite URLs in offline mode', () {
      expect(
        ApiService.resolveUrl('https://images.example.com/example.jpg'),
        'https://images.example.com/example.jpg',
      );
    });
  });

  testWidgets('NeighbourConnect app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const NeighbourConnectApp());

    expect(find.text('NeighbourConnect'), findsOneWidget);
  });
}
