// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfSealedClassTest);
  });
}

@reflectiveTest
class SubtypeOfSealedClassTest extends DriverResolutionTest with PackageMixin {
  test_extendingSealedClass() async {
    addMetaPackage();
    _addPackage('foo', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:foo/foo.dart';
class Bar extends Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertTestErrorsWithCodes([HintCode.SUBTYPE_OF_SEALED_CLASS]);
  }

  test_implementingSealedClass() async {
    addMetaPackage();
    _addPackage('foo', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:foo/foo.dart';
class Bar implements Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertTestErrorsWithCodes([HintCode.SUBTYPE_OF_SEALED_CLASS]);
  }

  test_mixinApplicationOfSealedClass() async {
    addMetaPackage();
    _addPackage('foo', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:foo/foo.dart';
class Bar1 {}
class Bar2 = Bar1 with Foo;
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertTestErrorsWithCodes([HintCode.SUBTYPE_OF_SEALED_CLASS]);
  }

  test_mixinApplicationOfSealedMixin() async {
    addMetaPackage();
    _addPackage('foo', r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
''');

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:foo/foo.dart';
class Bar1 {}
class Bar2 = Bar1 with Foo;
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertTestErrorsWithCodes([HintCode.SUBTYPE_OF_SEALED_CLASS]);
  }

  test_mixingInWithSealedMixin() async {
    addMetaPackage();
    _addPackage('foo', r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
''');

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:foo/foo.dart';
class Bar extends Object with Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertTestErrorsWithCodes([HintCode.SUBTYPE_OF_SEALED_CLASS]);
  }

  test_mixinImplementsSealedClass() async {
    addMetaPackage();
    _addPackage('foo', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:foo/foo.dart';
mixin Bar implements Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertTestErrorsWithCodes([HintCode.SUBTYPE_OF_SEALED_CLASS]);
  }

  test_withinLibrary_OK() async {
    addMetaPackage();

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:meta/meta.dart';
@sealed class Foo {}

class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertNoTestErrors();
  }

  test_withinPackageLibDirectory_OK() async {
    addMetaPackage();

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');
    newFile('/pkg1/lib/src/lib2.dart', content: r'''
import '../lib1.dart';
class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    await _resolveTestFile('/pkg1/lib/src/lib2.dart');
    assertNoTestErrors();
  }

  test_withinPackageTestDirectory_OK() async {
    addMetaPackage();

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');
    newFile('/pkg1/test/test.dart', content: r'''
import '../lib/lib1.dart';
class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    await _resolveTestFile('/pkg1/test/test.dart');
    assertNoTestErrors();
  }

  test_withinPart_OK() async {
    addMetaPackage();

    _newPubPackageRoot('/pkg1');
    newFile('/pkg1/lib/lib1.dart', content: r'''
import 'package:meta/meta.dart';
part 'part1.dart';
@sealed class Foo {}
''');
    newFile('/pkg1/lib/part1.dart', content: r'''
part of 'lib1.dart';
class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
    await _resolveTestFile('/pkg1/lib/lib1.dart');
    assertNoTestErrors();
  }

  /// Add a package named [name], and one library file, with content
  /// [libraryContent].
  void _addPackage(String name, String libraryContent) {
    Folder lib = addPubPackage(name);
    newFile(join(lib.path, '$name.dart'), content: libraryContent);
  }

  /// Write a pubspec file at [root], so that BestPracticesVerifier can see
  /// that [root] is the root of a PubWorkspace, and a PubWorkspacePackage.
  void _newPubPackageRoot(String root) {
    newFile('$root/pubspec.yaml');
  }

  /// Resolve the test file at [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveTestFile(String path) async {
    result = await resolveFile(convertPath(path));
  }
}
