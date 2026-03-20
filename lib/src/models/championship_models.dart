enum ChampionshipFormat { league, leaguePlayoffs, knockout }

enum TeamStatus { active, suspended, disqualified }

enum MatchStatus { pending, live, finished }

String championshipFormatToDb(ChampionshipFormat value) => value.name;
ChampionshipFormat championshipFormatFromDb(String value) => ChampionshipFormat.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ChampionshipFormat.league,
    );

String teamStatusToDb(TeamStatus value) => value.name;
TeamStatus teamStatusFromDb(String value) => TeamStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => TeamStatus.active,
    );

String matchStatusToDb(MatchStatus value) => value.name;
MatchStatus matchStatusFromDb(String value) => MatchStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => MatchStatus.pending,
    );

class Championship {
  Championship({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.format,
    required this.startDate,
    required this.endDate,
    required this.theme,
    required this.sponsor,
    required this.privacy,
    required this.bannerUrl,
  });

  final int id;
  final String name;
  final String title;
  final String description;
  final ChampionshipFormat format;
  final DateTime startDate;
  final DateTime endDate;
  final String theme;
  final String sponsor;
  final String privacy;
  final String bannerUrl;

  Championship copyWith({
    int? id,
    String? name,
    String? title,
    String? description,
    ChampionshipFormat? format,
    DateTime? startDate,
    DateTime? endDate,
    String? theme,
    String? sponsor,
    String? privacy,
    String? bannerUrl,
  }) {
    return Championship(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      theme: theme ?? this.theme,
      sponsor: sponsor ?? this.sponsor,
      privacy: privacy ?? this.privacy,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'format': championshipFormatToDb(format),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'theme': theme,
      'sponsor': sponsor,
      'privacy': privacy,
      'banner_url': bannerUrl,
    };
  }

  factory Championship.fromMap(Map<String, Object?> map) {
    return Championship(
      id: map['id'] as int,
      name: map['name'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      format: championshipFormatFromDb(map['format'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      theme: map['theme'] as String,
      sponsor: map['sponsor'] as String,
      privacy: map['privacy'] as String,
      bannerUrl: map['banner_url'] as String,
    );
  }
}

class Team {
  Team({
    required this.id,
    required this.championshipId,
    required this.name,
    required this.logo,
    required this.status,
    required this.groupName,
  });

  final int id;
  final int championshipId;
  final String name;
  final String logo;
  final TeamStatus status;
  final String groupName;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'championship_id': championshipId,
      'name': name,
      'logo': logo,
      'status': teamStatusToDb(status),
      'group_name': groupName,
    };
  }

  factory Team.fromMap(Map<String, Object?> map) {
    return Team(
      id: map['id'] as int,
      championshipId: map['championship_id'] as int,
      name: map['name'] as String,
      logo: map['logo'] as String,
      status: teamStatusFromDb(map['status'] as String),
      groupName: map['group_name'] as String,
    );
  }
}

class Player {
  Player({
    required this.id,
    required this.teamId,
    required this.name,
    required this.position,
    required this.goals,
    required this.assists,
  });

  final int id;
  final int teamId;
  final String name;
  final String position;
  final int goals;
  final int assists;

  Player copyWith({
    int? id,
    int? teamId,
    String? name,
    String? position,
    int? goals,
    int? assists,
  }) {
    return Player(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      position: position ?? this.position,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'position': position,
      'goals': goals,
      'assists': assists,
    };
  }

  factory Player.fromMap(Map<String, Object?> map) {
    return Player(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      name: map['name'] as String,
      position: map['position'] as String,
      goals: map['goals'] as int,
      assists: map['assists'] as int,
    );
  }
}

class Stage {
  Stage({
    required this.id,
    required this.championshipId,
    required this.name,
    required this.type,
    required this.order,
  });

  final int id;
  final int championshipId;
  final String name;
  final String type;
  final int order;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'championship_id': championshipId,
      'name': name,
      'type': type,
      'display_order': order,
    };
  }

  factory Stage.fromMap(Map<String, Object?> map) {
    return Stage(
      id: map['id'] as int,
      championshipId: map['championship_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      order: map['display_order'] as int,
    );
  }
}

class RoundData {
  RoundData({
    required this.id,
    required this.stageId,
    required this.name,
    required this.order,
  });

  final int id;
  final int stageId;
  final String name;
  final int order;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'stage_id': stageId,
      'name': name,
      'display_order': order,
    };
  }

  factory RoundData.fromMap(Map<String, Object?> map) {
    return RoundData(
      id: map['id'] as int,
      stageId: map['stage_id'] as int,
      name: map['name'] as String,
      order: map['display_order'] as int,
    );
  }
}

class MatchData {
  MatchData({
    required this.id,
    required this.roundId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.scheduledAt,
  });

  final int id;
  final int roundId;
  final int homeTeamId;
  final int awayTeamId;
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final DateTime scheduledAt;

  MatchData copyWith({
    int? id,
    int? roundId,
    int? homeTeamId,
    int? awayTeamId,
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    DateTime? scheduledAt,
  }) {
    return MatchData(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'round_id': roundId,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'home_score': homeScore,
      'away_score': awayScore,
      'status': matchStatusToDb(status),
      'scheduled_at': scheduledAt.toIso8601String(),
    };
  }

  factory MatchData.fromMap(Map<String, Object?> map) {
    return MatchData(
      id: map['id'] as int,
      roundId: map['round_id'] as int,
      homeTeamId: map['home_team_id'] as int,
      awayTeamId: map['away_team_id'] as int,
      homeScore: map['home_score'] as int,
      awayScore: map['away_score'] as int,
      status: matchStatusFromDb(map['status'] as String),
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
    );
  }
}

class StandingRow {
  StandingRow({
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
  });

  final Team team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  int get goalDifference => goalsFor - goalsAgainst;
}
