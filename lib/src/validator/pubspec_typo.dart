// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../entrypoint.dart';
import '../levenshtein.dart';
import '../validator.dart';

/// Validates that a package's pubspec does not contain any typos in its keys.
class PubspecTypoValidator extends Validator {
  PubspecTypoValidator(Entrypoint entrypoint) : super(entrypoint);

  @override
  Future validate() async {
    final fields = entrypoint.root.pubspec.fields;

    if (fields == null) return;

    for (final key in fields.keys) {
      var bestLevenshteinRatio = 100.0;
      var closestKey = '';

      for (final validKey in _validPubspecKeys) {
        /// Use a ratio to account allow more more typos in strings with
        /// longer lengths.
        final ratio =
            levenshteinDistance(key, validKey) / (validKey.length + key.length);
        if (ratio < bestLevenshteinRatio) {
          bestLevenshteinRatio = ratio;
          closestKey = validKey;
        }
      }

      /// 0.21 is a magic value determined by looking at the most common typos
      /// in all the pubspecs on pub.dev.
      if (bestLevenshteinRatio > 0 && bestLevenshteinRatio < 0.21) {
        warnings.add('"$key" is not a key recognized by pub - '
            'did you mean "$closestKey"?');
      }

      /// Differs from the above because we allow exact matches here too.
      if (bestLevenshteinRatio < 0.21 &&
          (closestKey == 'author' || closestKey == 'authors')) {
        warnings.add('The "$closestKey" key is deprecated - Use a verified '
            'publisher (https://dart.dev/tools/pub/verified-publishers) '
            'instead.');
      }
    }
  }
}

/// List of keys in `pubspec.yaml` that will be recognized by pub, as well as
/// the depreciated `author` key.
///
/// Retrieved from https://dart.dev/tools/pub/pubspec
const _validPubspecKeys = [
  'author',
  'authors',
  'name',
  'version',
  'description',
  'homepage',
  'repository',
  'issue_tracker',
  'documentation',
  'dependencies',
  'dev_dependencies',
  'dependency_overrides',
  'environment',
  'executables',
  'publish_to',
  'flutter'
];
