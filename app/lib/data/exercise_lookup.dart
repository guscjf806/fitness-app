import 'exercise_models.dart';
import 'exercises.dart';

final _byId = {for (final e in exercises) e.id: e};
final _byName = {for (final e in exercises) e.name: e};

ExerciseInfo? exerciseById(String id) => _byId[id];

/// 루틴·일지에 적힌 이름(별칭 포함)으로 종목을 찾는다. 선생님이 직접 입력한 종목이면 null.
ExerciseInfo? exerciseByName(String name) =>
    _byName[name] ?? (exerciseAliases[name] == null ? null : _byId[exerciseAliases[name]]);
