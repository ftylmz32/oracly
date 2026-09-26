/// Phase 8A.2 — JSON-path evidence mutations for structure red-team.
library;

import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';

Map<String, dynamic> _evJson(BirthChart chart) =>
    Map<String, dynamic>.from(chart.toJson()['natalEvidence'] as Map);

BirthChart _fromEv(BirthChart chart, Map<String, dynamic> ev) {
  final json = Map<String, dynamic>.from(chart.toJson());
  json['natalEvidence'] = ev;
  return BirthChart.fromJson(json);
}

List<Map<String, dynamic>> _list(dynamic raw) =>
    List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );

BirthChart phase8aClearFactHouseSystem(
  BirthChart chart, {
  required String target,
  int index = 0,
}) {
  final ev = _evJson(chart);
  if (target == 'placement' || target == 'house' || target == 'aspect') {
    final key = '${target}s';
    final list = _list(ev[key]);
    final fact = list[index];
    final prov = Map<String, dynamic>.from(fact['provenance'] as Map)
      ..remove('houseSystem');
    fact['provenance'] = prov;
    list[index] = fact;
    ev[key] = list;
  } else if (target == 'ascendant' || target == 'midheaven') {
    final fact = Map<String, dynamic>.from(ev[target] as Map);
    final prov = Map<String, dynamic>.from(fact['provenance'] as Map)
      ..remove('houseSystem');
    fact['provenance'] = prov;
    ev[target] = fact;
  } else {
    throw ArgumentError(target);
  }
  return _fromEv(chart, ev);
}

BirthChart phase8aMutatePlacementField(
  BirthChart chart, {
  required String field,
  Object? value,
  bool remove = false,
  int index = 0,
}) {
  final ev = _evJson(chart);
  final list = _list(ev['placements']);
  final p = list[index];
  if (remove) {
    p.remove(field);
  } else {
    p[field] = value;
  }
  list[index] = p;
  ev['placements'] = list;
  return _fromEv(chart, ev);
}

BirthChart phase8aDuplicateBody(BirthChart chart) {
  final ev = _evJson(chart);
  final list = _list(ev['placements']);
  list[1]['body'] = list[0]['body'];
  ev['placements'] = list;
  return _fromEv(chart, ev);
}

BirthChart phase8aRemoveAscendant(BirthChart chart) {
  final ev = _evJson(chart)..remove('ascendant');
  return _fromEv(chart, ev);
}

BirthChart phase8aRemoveMidheaven(BirthChart chart) {
  final ev = _evJson(chart)..remove('midheaven');
  return _fromEv(chart, ev);
}

BirthChart phase8aMutateAngle(
  BirthChart chart, {
  required String target,
  required String field,
  Object? value,
}) {
  final ev = _evJson(chart);
  final fact = Map<String, dynamic>.from(ev[target] as Map);
  fact[field] = value;
  ev[target] = fact;
  return _fromEv(chart, ev);
}

BirthChart phase8aTrimHouses(BirthChart chart, int keep) {
  final ev = _evJson(chart);
  ev['houses'] = _list(ev['houses']).take(keep).toList();
  return _fromEv(chart, ev);
}

BirthChart phase8aDuplicateHouseNumber(BirthChart chart) {
  final ev = _evJson(chart);
  final list = _list(ev['houses']);
  list[1]['number'] = list[0]['number'];
  ev['houses'] = list;
  return _fromEv(chart, ev);
}

BirthChart phase8aMutateHouseField(
  BirthChart chart, {
  required String field,
  Object? value,
  int index = 0,
}) {
  final ev = _evJson(chart);
  final list = _list(ev['houses']);
  list[index][field] = value;
  ev['houses'] = list;
  return _fromEv(chart, ev);
}

BirthChart phase8aMutateAspectField(
  BirthChart chart, {
  required String field,
  Object? value,
  int index = 0,
}) {
  final ev = _evJson(chart);
  final list = _list(ev['aspects']);
  if (list.isEmpty) throw StateError('no aspects');
  list[index][field] = value;
  ev['aspects'] = list;
  return _fromEv(chart, ev);
}

BirthChart phase8aNegativeElement(BirthChart chart) {
  final ev = _evJson(chart);
  final bal = Map<String, dynamic>.from(ev['elementBalance'] as Map);
  bal['fire'] = -1;
  ev['elementBalance'] = bal;
  return _fromEv(chart, ev);
}
