import 'package:flutter_test/flutter_test.dart';

import 'package:anotaai_mvp/src/models/championship_models.dart';

void main() {
  test('championship map serialization keeps core fields', () {
    final championship = Championship(
      id: 7,
      name: 'Liga Escolar',
      title: 'Temporada 2026',
      description: 'Teste',
      format: ChampionshipFormat.leaguePlayoffs,
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 4, 10),
      theme: 'Azul',
      sponsor: 'Parceiro',
      privacy: 'Convidados',
      bannerUrl: 'banner',
    );

    final restored = Championship.fromMap(championship.toMap());

    expect(restored.id, championship.id);
    expect(restored.name, championship.name);
    expect(restored.format, championship.format);
    expect(restored.privacy, championship.privacy);
  });

  test('enum helpers serialize and deserialize values', () {
    expect(championshipFormatFromDb(championshipFormatToDb(ChampionshipFormat.knockout)), ChampionshipFormat.knockout);
    expect(teamStatusFromDb(teamStatusToDb(TeamStatus.disqualified)), TeamStatus.disqualified);
    expect(matchStatusFromDb(matchStatusToDb(MatchStatus.live)), MatchStatus.live);
  });
}
