// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapValueTypeNotAssignableTest);
    defineReflectiveTests(
        MapValueTypeNotAssignableWithUIAsCodeAndConstantsTest);
    defineReflectiveTests(MapValueTypeNotAssignableWithUIAsCodeTest);
  });
}

@reflectiveTest
class MapValueTypeNotAssignableTest extends DriverResolutionTest {
  test_const_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <bool, int>{true: a};
''');
  }

  test_const_intString_dynamic() async {
    await assertErrorCodesInCode('''
const dynamic a = 'a';
var v = const <bool, int>{true: a};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_intString_value() async {
    await assertErrorCodesInCode('''
var v = const <bool, int>{true: 'a'};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <bool, int>{true: a};
''');
  }

  test_nonConst_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <bool, int>{true: a};
''');
  }

  test_nonConst_intString_value() async {
    await assertErrorCodesInCode('''
var v = <bool, int>{true: 'a'};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }
}

@reflectiveTest
class MapValueTypeNotAssignableWithUIAsCodeAndConstantsTest
    extends MapValueTypeNotAssignableWithUIAsCodeTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];
}

@reflectiveTest
class MapValueTypeNotAssignableWithUIAsCodeTest
    extends MapValueTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  test_const_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
const dynamic b = 0;
var v = const <bool, int>{if (1 < 0) true: a else false: b};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_intString_dynamic() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <bool, int>{if (1 < 0) true: a else false: b};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 'a';
var v = const <bool, int>{if (1 < 0) true: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenFalse_intString_value() async {
    await assertErrorCodesInCode(
        '''
var v = const <bool, int>{if (1 < 0) true: 'a'};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]
            : [
                StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
                CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT
              ]);
  }

  test_const_ifElement_thenTrue_intInt_dynamic() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const <bool, int>{if (true) true: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenTrue_intString_dynamic() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 'a';
var v = const <bool, int>{if (true) true: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenTrue_notConst() async {
    await assertErrorCodesInCode(
        '''
final a = 0;
var v = const <bool, int>{if (1 < 2) true: a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_spread_intInt() async {
    await assertErrorCodesInCode(
        '''
var v = const <bool, int>{...{true: 1}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_spread_intString_dynamic() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 'a';
var v = const <bool, int>{...{true: a}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]
            : [
                StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
                CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT
              ]);
  }

  test_nonConst_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_nonConst_ifElement_thenFalse_intString_value() async {
    await assertErrorCodesInCode('''
var v = <bool, int>{if (1 < 0) true: 'a'};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenTrue_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <bool, int>{if (true) true: a};
''');
  }

  test_nonConst_ifElement_thenTrue_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <bool, int>{if (true) true: a};
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <bool, int>{...{true: 1}};
''');
  }

  test_nonConst_spread_intNum() async {
    await assertNoErrorsInCode('''
var v = <int, int>{...<num, num>{1: 1}};
''');
  }

  test_nonConst_spread_intString() async {
    await assertErrorCodesInCode('''
var v = <bool, int>{...{true: 'a'}};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_spread_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <bool, int>{...{true: a}};
''');
  }
}
