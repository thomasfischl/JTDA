library jtda_test;

import 'package:unittest/unittest.dart';
import '../web/jtda.dart';
import 'dart:io';

main() {
  group("Parser Test :: ", () {
    test('Test empty dump file', () {
      JtdaParser parser = new JtdaParser("");
      var list = parser.parse();
      expect(list.isEmpty, isTrue);
    });

    test('Test dump file with sinlge thread', () {
      JtdaParser parser = new JtdaParser(new File("singleTD.tdump").readAsStringSync());
      var list = parser.parse();
      expect(list.length == 1, isTrue);
      expect(list.first.name, equals('Inactive RequestProcessor thread [Was:Default RequestProcessor/null]'));
      expect(list.first.state, equals('TIMED_WAITING'));
      expect(list.first.locks.length, equals(1));
      expect(list.first.locks.first, equals("0x00000000fbbf8538"));
    });

    test('Test JVisual VM dump file', () {
      JtdaParser parser = new JtdaParser(new File("JVisualVM.tdump").readAsStringSync());
      var list = parser.parse();
      expect(list.length , equals(35));

      expect(list.first.name, equals('Inactive RequestProcessor thread [Was:Default RequestProcessor/null]'));
      expect(list.first.state, equals('TIMED_WAITING'));
      expect(list.first.locks.length, equals(1));
      expect(list.first.locks.first, equals("0x00000000fbbf8538"));
      expect(list.first.waitingToLocks.length, equals(0));

      expect(list[3].name, equals('pool-4-thread-1'));
      expect(list[3].state, equals('WAITING'));
      expect(list[3].locks.length, equals(0));
      expect(list[3].waitingToLocks.length, equals(0));

    });

    test('Test Tomcat dump file', () {
      JtdaParser parser = new JtdaParser(new File("tomcat.tdump").readAsStringSync());
      var list = parser.parse();
      expect(list.length , equals(30));

      expect(list.first.name, equals('SnakeWebSocketServlet Timer'));
      expect(list.first.state, equals('TIMED_WAITING'));
      expect(list.first.locks.length, equals(0));
      expect(list.first.waitingToLocks.length, equals(0));
    });


  });
}
