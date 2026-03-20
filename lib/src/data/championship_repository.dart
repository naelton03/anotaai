import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/championship_models.dart';
import 'database_service.dart';

class ChampionshipRepository extends ChangeNotifier {
  ChampionshipRepository(this._databaseService);

  final DatabaseService _databaseService;

  final List<Championship> _championships = [];
  final List<Team> _teams = [];
  final List<Player> _players = [];
  final List<Stage> _stages = [];
  final List<RoundData> _rounds = [];
  final List<MatchData> _matches = [];

  bool isLoading = true;
  int? selectedChampionshipId;
  String playerSearch = '';
  TeamStatus? teamStatusFilter;

  List<Championship> get championships => List.unmodifiable(_championships);

  Championship? get selectedChampionship {
    for (final championship in _championships) {
      if (championship.id == selectedChampionshipId) return championship;
    }
    return null;
  }

  List<Team> get championshipTeams {
    final filtered = _teams.where((team) => team.championshipId == selectedChampionshipId);
    return filtered
        .where((team) => teamStatusFilter == null || team.status == teamStatusFilter)
        .toList();
  }

  List<Player> get championshipPlayers {
    final visibleTeamIds = _teams
        .where((team) => team.championshipId == selectedChampionshipId)
        .map((team) => team.id)
        .toSet();
    return _players
        .where((player) => visibleTeamIds.contains(player.teamId))
        .where((player) => player.name.toLowerCase().contains(playerSearch.toLowerCase()))
        .toList();
  }

  List<Stage> get championshipStages => _stages
      .where((stage) => stage.championshipId == selectedChampionshipId)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  List<RoundData> roundsForStage(int stageId) => _rounds
      .where((round) => round.stageId == stageId)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  List<MatchData> matchesForRound(int roundId) => _matches
      .where((match) => match.roundId == roundId)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<StandingRow> get standings {
    final rows = <StandingRow>[];
    final teams = _teams.where((team) => team.championshipId == selectedChampionshipId);
    for (final team in teams) {
      var played = 0;
      var wins = 0;
      var draws = 0;
      var losses = 0;
      var goalsFor = 0;
      var goalsAgainst = 0;
      for (final match in _matches.where((item) =>
          item.status == MatchStatus.finished &&
          (item.homeTeamId == team.id || item.awayTeamId == team.id))) {
        played += 1;
        final isHome = match.homeTeamId == team.id;
        final goalsMade = isHome ? match.homeScore : match.awayScore;
        final goalsTaken = isHome ? match.awayScore : match.homeScore;
        goalsFor += goalsMade;
        goalsAgainst += goalsTaken;
        if (goalsMade > goalsTaken) {
          wins += 1;
        } else if (goalsMade == goalsTaken) {
          draws += 1;
        } else {
          losses += 1;
        }
      }
      rows.add(
        StandingRow(
          team: team,
          played: played,
          wins: wins,
          draws: draws,
          losses: losses,
          goalsFor: goalsFor,
          goalsAgainst: goalsAgainst,
          points: wins * 3 + draws,
        ),
      );
    }

    rows.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byDifference = b.goalDifference.compareTo(a.goalDifference);
      if (byDifference != 0) return byDifference;
      final byGoalsFor = b.goalsFor.compareTo(a.goalsFor);
      if (byGoalsFor != 0) return byGoalsFor;
      return a.team.name.compareTo(b.team.name);
    });
    return rows;
  }

  List<Player> get topScorers {
    final players = [...championshipPlayers];
    players.sort((a, b) => b.goals.compareTo(a.goals));
    return players.take(5).toList();
  }

  List<Player> get topAssists {
    final players = [...championshipPlayers];
    players.sort((a, b) => b.assists.compareTo(a.assists));
    return players.take(5).toList();
  }

  List<MatchData> get nextMatches {
    final teamIds = _teams
        .where((team) => team.championshipId == selectedChampionshipId)
        .map((team) => team.id)
        .toSet();
    final matches = _matches
        .where((match) =>
            match.status != MatchStatus.finished &&
            teamIds.contains(match.homeTeamId) &&
            teamIds.contains(match.awayTeamId))
        .toList();
    matches.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return matches.take(5).toList();
  }

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();

    await _loadAll();
    if (_championships.isEmpty) {
      await _seedInitialData();
      await _loadAll();
    }

    selectedChampionshipId ??= _championships.isEmpty ? null : _championships.first.id;
    isLoading = false;
    notifyListeners();
  }

  void selectChampionship(int id) {
    selectedChampionshipId = id;
    notifyListeners();
  }

  void updatePlayerSearch(String value) {
    playerSearch = value;
    notifyListeners();
  }

  void updateTeamStatusFilter(TeamStatus? status) {
    teamStatusFilter = status;
    notifyListeners();
  }

  Future<void> addChampionship({
    required String name,
    required String title,
    required String description,
    required ChampionshipFormat format,
    required DateTime startDate,
    required DateTime endDate,
    required String theme,
    required String sponsor,
    required String privacy,
  }) async {
    final championshipId = await _databaseService.db.insert(
      'championships',
      Championship(
        id: 0,
        name: name,
        title: title,
        description: description,
        format: format,
        startDate: startDate,
        endDate: endDate,
        theme: theme,
        sponsor: sponsor,
        privacy: privacy,
        bannerUrl: 'Banner de $name',
      ).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    selectedChampionshipId = championshipId;
    await _loadAll();
    notifyListeners();
  }

  Future<void> addTeam({
    required String name,
    required String logo,
    required TeamStatus status,
    required String groupName,
  }) async {
    final championshipId = selectedChampionshipId;
    if (championshipId == null) return;

    await _databaseService.db.insert(
      'teams',
      Team(
        id: 0,
        championshipId: championshipId,
        name: name,
        logo: logo,
        status: status,
        groupName: groupName,
      ).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _loadAll();
    notifyListeners();
  }

  Future<void> addPlayer({
    required int teamId,
    required String name,
    required String position,
  }) async {
    await _databaseService.db.insert(
      'players',
      Player(
        id: 0,
        teamId: teamId,
        name: name,
        position: position,
        goals: 0,
        assists: 0,
      ).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _loadAll();
    notifyListeners();
  }

  Future<void> importPlayersFromCsv(int teamId, String csv) async {
    final batch = _databaseService.db.batch();
    for (final rawLine in csv.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 2) continue;
      batch.insert(
        'players',
        Player(
          id: 0,
          teamId: teamId,
          name: parts[0].trim(),
          position: parts[1].trim(),
          goals: 0,
          assists: 0,
        ).toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    await _loadAll();
    notifyListeners();
  }

  Future<void> addStage({required String name, required String type}) async {
    final championshipId = selectedChampionshipId;
    if (championshipId == null) return;

    await _databaseService.db.insert(
      'stages',
      Stage(
        id: 0,
        championshipId: championshipId,
        name: name,
        type: type,
        order: championshipStages.length + 1,
      ).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _loadAll();
    notifyListeners();
  }

  Future<void> addRound(int stageId, String name) async {
    await _databaseService.db.insert(
      'rounds',
      RoundData(
        id: 0,
        stageId: stageId,
        name: name,
        order: roundsForStage(stageId).length + 1,
      ).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _loadAll();
    notifyListeners();
  }

  Future<void> generateSequentialRound(int stageId) async {
    final rounds = roundsForStage(stageId);
    await addRound(stageId, '${rounds.length + 1}ª Rodada');
  }

  Future<void> addMatch({
    required int roundId,
    required int homeTeamId,
    required int awayTeamId,
    required DateTime scheduledAt,
  }) async {
    await _databaseService.db.insert(
      'matches',
      MatchData(
        id: 0,
        roundId: roundId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.pending,
        scheduledAt: scheduledAt,
      ).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _loadAll();
    notifyListeners();
  }

  Future<void> updateMatchResult({
    required int matchId,
    required int homeScore,
    required int awayScore,
    required MatchStatus status,
  }) async {
    final current = _matches.firstWhere((match) => match.id == matchId);
    final updatedMatch = current.copyWith(
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
    );

    await _databaseService.db.update(
      'matches',
      updatedMatch.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [matchId],
    );

    await _loadAll();
    await _recalculatePlayerMetrics(_matches.firstWhere((match) => match.id == matchId));
    await _loadAll();
    notifyListeners();
  }

  Team findTeam(int id) => _teams.firstWhere((team) => team.id == id);

  Future<void> _loadAll() async {
    _championships
      ..clear()
      ..addAll((await _databaseService.db.query('championships', orderBy: 'id DESC')).map(Championship.fromMap));

    _teams
      ..clear()
      ..addAll((await _databaseService.db.query('teams', orderBy: 'name')).map(Team.fromMap));

    _players
      ..clear()
      ..addAll((await _databaseService.db.query('players', orderBy: 'name')).map(Player.fromMap));

    _stages
      ..clear()
      ..addAll((await _databaseService.db.query('stages', orderBy: 'display_order')).map(Stage.fromMap));

    _rounds
      ..clear()
      ..addAll((await _databaseService.db.query('rounds', orderBy: 'display_order')).map(RoundData.fromMap));

    _matches
      ..clear()
      ..addAll((await _databaseService.db.query('matches', orderBy: 'scheduled_at')).map(MatchData.fromMap));
  }

  Future<void> _seedInitialData() async {
    final database = _databaseService.db;
    final championshipId = await database.insert(
      'championships',
      Championship(
        id: 0,
        name: 'Copa Integração',
        title: 'Temporada 2026',
        description: 'Plataforma para gestão de ligas amadoras, escolas, universidades e clubes.',
        format: ChampionshipFormat.leaguePlayoffs,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 6, 30),
        theme: 'Azul elétrico',
        sponsor: 'Patrocinador local',
        privacy: 'Convidados',
        bannerUrl: 'Banner principal',
      ).toMap()..remove('id'),
    );

    final teamA = await database.insert(
      'teams',
      Team(
        id: 0,
        championshipId: championshipId,
        name: 'Time A',
        logo: 'A',
        status: TeamStatus.active,
        groupName: 'Grupo A',
      ).toMap()..remove('id'),
    );
    final teamB = await database.insert(
      'teams',
      Team(
        id: 0,
        championshipId: championshipId,
        name: 'Time B',
        logo: 'B',
        status: TeamStatus.active,
        groupName: 'Grupo A',
      ).toMap()..remove('id'),
    );
    final teamC = await database.insert(
      'teams',
      Team(
        id: 0,
        championshipId: championshipId,
        name: 'Time C',
        logo: 'C',
        status: TeamStatus.active,
        groupName: 'Grupo B',
      ).toMap()..remove('id'),
    );
    final teamD = await database.insert(
      'teams',
      Team(
        id: 0,
        championshipId: championshipId,
        name: 'Time D',
        logo: 'D',
        status: TeamStatus.suspended,
        groupName: 'Grupo B',
      ).toMap()..remove('id'),
    );

    await database.insert(
      'players',
      Player(id: 0, teamId: teamA, name: 'Gabriel Lima', position: 'Atacante', goals: 4, assists: 2).toMap()..remove('id'),
    );
    await database.insert(
      'players',
      Player(id: 0, teamId: teamA, name: 'Rafael Alves', position: 'Meio-campo', goals: 1, assists: 3).toMap()..remove('id'),
    );
    await database.insert(
      'players',
      Player(id: 0, teamId: teamB, name: 'Lucas Pereira', position: 'Ponta', goals: 3, assists: 1).toMap()..remove('id'),
    );
    await database.insert(
      'players',
      Player(id: 0, teamId: teamC, name: 'Ana Souza', position: 'Atacante', goals: 2, assists: 4).toMap()..remove('id'),
    );

    final stage1 = await database.insert(
      'stages',
      Stage(id: 0, championshipId: championshipId, name: '1ª Fase', type: 'Pontos corridos', order: 1).toMap()..remove('id'),
    );
    final stage2 = await database.insert(
      'stages',
      Stage(id: 0, championshipId: championshipId, name: 'Semifinal', type: 'Eliminatória', order: 2).toMap()..remove('id'),
    );

    final round1 = await database.insert(
      'rounds',
      RoundData(id: 0, stageId: stage1, name: '1ª Rodada', order: 1).toMap()..remove('id'),
    );
    final round2 = await database.insert(
      'rounds',
      RoundData(id: 0, stageId: stage1, name: '2ª Rodada', order: 2).toMap()..remove('id'),
    );
    await database.insert(
      'rounds',
      RoundData(id: 0, stageId: stage2, name: 'Chave 1', order: 1).toMap()..remove('id'),
    );

    await database.insert(
      'matches',
      MatchData(
        id: 0,
        roundId: round1,
        homeTeamId: teamA,
        awayTeamId: teamB,
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
      ).toMap()..remove('id'),
    );
    await database.insert(
      'matches',
      MatchData(
        id: 0,
        roundId: round1,
        homeTeamId: teamC,
        awayTeamId: teamD,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.live,
        scheduledAt: DateTime.now(),
      ).toMap()..remove('id'),
    );
    await database.insert(
      'matches',
      MatchData(
        id: 0,
        roundId: round2,
        homeTeamId: teamA,
        awayTeamId: teamC,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.pending,
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
      ).toMap()..remove('id'),
    );
  }

  Future<void> _recalculatePlayerMetrics(MatchData updatedMatch) async {
    final teamIds = {updatedMatch.homeTeamId, updatedMatch.awayTeamId};
    final affectedPlayers = _players.where((player) => teamIds.contains(player.teamId)).toList();
    final scoreBoard = <int, ({int goals, int assists})>{
      for (final player in affectedPlayers) player.id: (goals: 0, assists: 0),
    };

    final relevantMatches = _matches.where((match) =>
        match.status == MatchStatus.finished &&
        teamIds.contains(match.homeTeamId) &&
        teamIds.contains(match.awayTeamId));

    for (final match in relevantMatches) {
      _distributeStats(
        players: affectedPlayers.where((player) => player.teamId == match.homeTeamId).toList(),
        goals: match.homeScore,
        scoreBoard: scoreBoard,
      );
      _distributeStats(
        players: affectedPlayers.where((player) => player.teamId == match.awayTeamId).toList(),
        goals: match.awayScore,
        scoreBoard: scoreBoard,
      );
    }

    for (final player in affectedPlayers) {
      final stats = scoreBoard[player.id]!;
      await _databaseService.db.update(
        'players',
        player.copyWith(goals: stats.goals, assists: stats.assists).toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [player.id],
      );
    }
  }

  void _distributeStats({
    required List<Player> players,
    required int goals,
    required Map<int, ({int goals, int assists})> scoreBoard,
  }) {
    if (players.isEmpty || goals <= 0) return;

    for (var index = 0; index < goals; index += 1) {
      final scorer = players[index % players.length];
      final scorerStats = scoreBoard[scorer.id]!;
      scoreBoard[scorer.id] = (
        goals: scorerStats.goals + 1,
        assists: scorerStats.assists,
      );

      if (players.length > 1) {
        final assister = players[(index + 1) % players.length];
        final assisterStats = scoreBoard[assister.id]!;
        scoreBoard[assister.id] = (
          goals: assisterStats.goals,
          assists: assisterStats.assists + 1,
        );
      }
    }
  }
}
