// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GamesTable extends Games with TableInfo<$GamesTable, GameRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerCountMeta = const VerificationMeta(
    'playerCount',
  );
  @override
  late final GeneratedColumn<int> playerCount = GeneratedColumn<int>(
    'player_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _winnerMeta = const VerificationMeta('winner');
  @override
  late final GeneratedColumn<String> winner = GeneratedColumn<String>(
    'winner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pausedFromMeta = const VerificationMeta(
    'pausedFrom',
  );
  @override
  late final GeneratedColumn<String> pausedFrom = GeneratedColumn<String>(
    'paused_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaderSeatMeta = const VerificationMeta(
    'leaderSeat',
  );
  @override
  late final GeneratedColumn<int> leaderSeat = GeneratedColumn<int>(
    'leader_seat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questNumberMeta = const VerificationMeta(
    'questNumber',
  );
  @override
  late final GeneratedColumn<int> questNumber = GeneratedColumn<int>(
    'quest_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectionCountMeta = const VerificationMeta(
    'rejectionCount',
  );
  @override
  late final GeneratedColumn<int> rejectionCount = GeneratedColumn<int>(
    'rejection_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentTeamMeta = const VerificationMeta(
    'currentTeam',
  );
  @override
  late final GeneratedColumn<String> currentTeam = GeneratedColumn<String>(
    'current_team',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _questResultsMeta = const VerificationMeta(
    'questResults',
  );
  @override
  late final GeneratedColumn<String> questResults = GeneratedColumn<String>(
    'quest_results',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questTeamsMeta = const VerificationMeta(
    'questTeams',
  );
  @override
  late final GeneratedColumn<String> questTeams = GeneratedColumn<String>(
    'quest_teams',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _compositionMeta = const VerificationMeta(
    'composition',
  );
  @override
  late final GeneratedColumn<String> composition = GeneratedColumn<String>(
    'composition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _winReasonMeta = const VerificationMeta(
    'winReason',
  );
  @override
  late final GeneratedColumn<String> winReason = GeneratedColumn<String>(
    'win_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assassinationOutcomeMeta =
      const VerificationMeta('assassinationOutcome');
  @override
  late final GeneratedColumn<String> assassinationOutcome =
      GeneratedColumn<String>(
        'assassination_outcome',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    playerCount,
    status,
    winner,
    durationSeconds,
    phase,
    pausedFrom,
    leaderSeat,
    questNumber,
    rejectionCount,
    currentTeam,
    questResults,
    questTeams,
    composition,
    winReason,
    assassinationOutcome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('player_count')) {
      context.handle(
        _playerCountMeta,
        playerCount.isAcceptableOrUnknown(
          data['player_count']!,
          _playerCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerCountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('winner')) {
      context.handle(
        _winnerMeta,
        winner.isAcceptableOrUnknown(data['winner']!, _winnerMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('paused_from')) {
      context.handle(
        _pausedFromMeta,
        pausedFrom.isAcceptableOrUnknown(data['paused_from']!, _pausedFromMeta),
      );
    }
    if (data.containsKey('leader_seat')) {
      context.handle(
        _leaderSeatMeta,
        leaderSeat.isAcceptableOrUnknown(data['leader_seat']!, _leaderSeatMeta),
      );
    } else if (isInserting) {
      context.missing(_leaderSeatMeta);
    }
    if (data.containsKey('quest_number')) {
      context.handle(
        _questNumberMeta,
        questNumber.isAcceptableOrUnknown(
          data['quest_number']!,
          _questNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questNumberMeta);
    }
    if (data.containsKey('rejection_count')) {
      context.handle(
        _rejectionCountMeta,
        rejectionCount.isAcceptableOrUnknown(
          data['rejection_count']!,
          _rejectionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rejectionCountMeta);
    }
    if (data.containsKey('current_team')) {
      context.handle(
        _currentTeamMeta,
        currentTeam.isAcceptableOrUnknown(
          data['current_team']!,
          _currentTeamMeta,
        ),
      );
    }
    if (data.containsKey('quest_results')) {
      context.handle(
        _questResultsMeta,
        questResults.isAcceptableOrUnknown(
          data['quest_results']!,
          _questResultsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questResultsMeta);
    }
    if (data.containsKey('quest_teams')) {
      context.handle(
        _questTeamsMeta,
        questTeams.isAcceptableOrUnknown(data['quest_teams']!, _questTeamsMeta),
      );
    }
    if (data.containsKey('composition')) {
      context.handle(
        _compositionMeta,
        composition.isAcceptableOrUnknown(
          data['composition']!,
          _compositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_compositionMeta);
    }
    if (data.containsKey('win_reason')) {
      context.handle(
        _winReasonMeta,
        winReason.isAcceptableOrUnknown(data['win_reason']!, _winReasonMeta),
      );
    }
    if (data.containsKey('assassination_outcome')) {
      context.handle(
        _assassinationOutcomeMeta,
        assassinationOutcome.isAcceptableOrUnknown(
          data['assassination_outcome']!,
          _assassinationOutcomeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      playerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      winner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      pausedFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paused_from'],
      ),
      leaderSeat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}leader_seat'],
      )!,
      questNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quest_number'],
      )!,
      rejectionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rejection_count'],
      )!,
      currentTeam: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_team'],
      )!,
      questResults: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_results'],
      )!,
      questTeams: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_teams'],
      )!,
      composition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composition'],
      )!,
      winReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}win_reason'],
      ),
      assassinationOutcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assassination_outcome'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class GameRecord extends DataClass implements Insertable<GameRecord> {
  final int id;

  /// UTC milliseconds since epoch.
  final int createdAt;
  final int updatedAt;
  final int playerCount;

  /// `inProgress`, `finished` or `abandoned`.
  final String status;

  /// `good`, `evil`, or null while the match runs.
  final String? winner;
  final int? durationSeconds;

  /// Current phase code, so an interrupted match resumes where it stopped.
  final String phase;

  /// Phase to return to after a pause; null when not paused.
  final String? pausedFrom;
  final int leaderSeat;
  final int questNumber;
  final int rejectionCount;

  /// Seats on the current proposal, comma joined and ascending. Empty outside a
  /// proposal. Keeping it lets an interrupted vote resume with the team shown.
  final String currentTeam;

  /// Quest outcomes in order, comma joined: `success,fail`.
  final String questResults;

  /// The seats that went on each resolved quest, in the same order as
  /// [questResults]: quests joined by `;`, seats by `,` — `1,3;2,4,5`.
  ///
  /// This is public state: it is what the table saw when each team was
  /// approved. It never says who was loyal and who was a minion.
  final String questTeams;

  /// Characters in play, as a JSON object of character code to count. The list
  /// is public configuration and is never attached to a player.
  final String composition;

  /// `threeQuests`, `fiveRejections`, `assassination`, or null.
  final String? winReason;

  /// `identified` or `notIdentified` — never a named player.
  final String? assassinationOutcome;
  const GameRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.playerCount,
    required this.status,
    this.winner,
    this.durationSeconds,
    required this.phase,
    this.pausedFrom,
    required this.leaderSeat,
    required this.questNumber,
    required this.rejectionCount,
    required this.currentTeam,
    required this.questResults,
    required this.questTeams,
    required this.composition,
    this.winReason,
    this.assassinationOutcome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['player_count'] = Variable<int>(playerCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || winner != null) {
      map['winner'] = Variable<String>(winner);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['phase'] = Variable<String>(phase);
    if (!nullToAbsent || pausedFrom != null) {
      map['paused_from'] = Variable<String>(pausedFrom);
    }
    map['leader_seat'] = Variable<int>(leaderSeat);
    map['quest_number'] = Variable<int>(questNumber);
    map['rejection_count'] = Variable<int>(rejectionCount);
    map['current_team'] = Variable<String>(currentTeam);
    map['quest_results'] = Variable<String>(questResults);
    map['quest_teams'] = Variable<String>(questTeams);
    map['composition'] = Variable<String>(composition);
    if (!nullToAbsent || winReason != null) {
      map['win_reason'] = Variable<String>(winReason);
    }
    if (!nullToAbsent || assassinationOutcome != null) {
      map['assassination_outcome'] = Variable<String>(assassinationOutcome);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      playerCount: Value(playerCount),
      status: Value(status),
      winner: winner == null && nullToAbsent
          ? const Value.absent()
          : Value(winner),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      phase: Value(phase),
      pausedFrom: pausedFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedFrom),
      leaderSeat: Value(leaderSeat),
      questNumber: Value(questNumber),
      rejectionCount: Value(rejectionCount),
      currentTeam: Value(currentTeam),
      questResults: Value(questResults),
      questTeams: Value(questTeams),
      composition: Value(composition),
      winReason: winReason == null && nullToAbsent
          ? const Value.absent()
          : Value(winReason),
      assassinationOutcome: assassinationOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(assassinationOutcome),
    );
  }

  factory GameRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameRecord(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      playerCount: serializer.fromJson<int>(json['playerCount']),
      status: serializer.fromJson<String>(json['status']),
      winner: serializer.fromJson<String?>(json['winner']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      phase: serializer.fromJson<String>(json['phase']),
      pausedFrom: serializer.fromJson<String?>(json['pausedFrom']),
      leaderSeat: serializer.fromJson<int>(json['leaderSeat']),
      questNumber: serializer.fromJson<int>(json['questNumber']),
      rejectionCount: serializer.fromJson<int>(json['rejectionCount']),
      currentTeam: serializer.fromJson<String>(json['currentTeam']),
      questResults: serializer.fromJson<String>(json['questResults']),
      questTeams: serializer.fromJson<String>(json['questTeams']),
      composition: serializer.fromJson<String>(json['composition']),
      winReason: serializer.fromJson<String?>(json['winReason']),
      assassinationOutcome: serializer.fromJson<String?>(
        json['assassinationOutcome'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'playerCount': serializer.toJson<int>(playerCount),
      'status': serializer.toJson<String>(status),
      'winner': serializer.toJson<String?>(winner),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'phase': serializer.toJson<String>(phase),
      'pausedFrom': serializer.toJson<String?>(pausedFrom),
      'leaderSeat': serializer.toJson<int>(leaderSeat),
      'questNumber': serializer.toJson<int>(questNumber),
      'rejectionCount': serializer.toJson<int>(rejectionCount),
      'currentTeam': serializer.toJson<String>(currentTeam),
      'questResults': serializer.toJson<String>(questResults),
      'questTeams': serializer.toJson<String>(questTeams),
      'composition': serializer.toJson<String>(composition),
      'winReason': serializer.toJson<String?>(winReason),
      'assassinationOutcome': serializer.toJson<String?>(assassinationOutcome),
    };
  }

  GameRecord copyWith({
    int? id,
    int? createdAt,
    int? updatedAt,
    int? playerCount,
    String? status,
    Value<String?> winner = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    String? phase,
    Value<String?> pausedFrom = const Value.absent(),
    int? leaderSeat,
    int? questNumber,
    int? rejectionCount,
    String? currentTeam,
    String? questResults,
    String? questTeams,
    String? composition,
    Value<String?> winReason = const Value.absent(),
    Value<String?> assassinationOutcome = const Value.absent(),
  }) => GameRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    playerCount: playerCount ?? this.playerCount,
    status: status ?? this.status,
    winner: winner.present ? winner.value : this.winner,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    phase: phase ?? this.phase,
    pausedFrom: pausedFrom.present ? pausedFrom.value : this.pausedFrom,
    leaderSeat: leaderSeat ?? this.leaderSeat,
    questNumber: questNumber ?? this.questNumber,
    rejectionCount: rejectionCount ?? this.rejectionCount,
    currentTeam: currentTeam ?? this.currentTeam,
    questResults: questResults ?? this.questResults,
    questTeams: questTeams ?? this.questTeams,
    composition: composition ?? this.composition,
    winReason: winReason.present ? winReason.value : this.winReason,
    assassinationOutcome: assassinationOutcome.present
        ? assassinationOutcome.value
        : this.assassinationOutcome,
  );
  GameRecord copyWithCompanion(GamesCompanion data) {
    return GameRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      playerCount: data.playerCount.present
          ? data.playerCount.value
          : this.playerCount,
      status: data.status.present ? data.status.value : this.status,
      winner: data.winner.present ? data.winner.value : this.winner,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      phase: data.phase.present ? data.phase.value : this.phase,
      pausedFrom: data.pausedFrom.present
          ? data.pausedFrom.value
          : this.pausedFrom,
      leaderSeat: data.leaderSeat.present
          ? data.leaderSeat.value
          : this.leaderSeat,
      questNumber: data.questNumber.present
          ? data.questNumber.value
          : this.questNumber,
      rejectionCount: data.rejectionCount.present
          ? data.rejectionCount.value
          : this.rejectionCount,
      currentTeam: data.currentTeam.present
          ? data.currentTeam.value
          : this.currentTeam,
      questResults: data.questResults.present
          ? data.questResults.value
          : this.questResults,
      questTeams: data.questTeams.present
          ? data.questTeams.value
          : this.questTeams,
      composition: data.composition.present
          ? data.composition.value
          : this.composition,
      winReason: data.winReason.present ? data.winReason.value : this.winReason,
      assassinationOutcome: data.assassinationOutcome.present
          ? data.assassinationOutcome.value
          : this.assassinationOutcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('playerCount: $playerCount, ')
          ..write('status: $status, ')
          ..write('winner: $winner, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('phase: $phase, ')
          ..write('pausedFrom: $pausedFrom, ')
          ..write('leaderSeat: $leaderSeat, ')
          ..write('questNumber: $questNumber, ')
          ..write('rejectionCount: $rejectionCount, ')
          ..write('currentTeam: $currentTeam, ')
          ..write('questResults: $questResults, ')
          ..write('questTeams: $questTeams, ')
          ..write('composition: $composition, ')
          ..write('winReason: $winReason, ')
          ..write('assassinationOutcome: $assassinationOutcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    playerCount,
    status,
    winner,
    durationSeconds,
    phase,
    pausedFrom,
    leaderSeat,
    questNumber,
    rejectionCount,
    currentTeam,
    questResults,
    questTeams,
    composition,
    winReason,
    assassinationOutcome,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.playerCount == this.playerCount &&
          other.status == this.status &&
          other.winner == this.winner &&
          other.durationSeconds == this.durationSeconds &&
          other.phase == this.phase &&
          other.pausedFrom == this.pausedFrom &&
          other.leaderSeat == this.leaderSeat &&
          other.questNumber == this.questNumber &&
          other.rejectionCount == this.rejectionCount &&
          other.currentTeam == this.currentTeam &&
          other.questResults == this.questResults &&
          other.questTeams == this.questTeams &&
          other.composition == this.composition &&
          other.winReason == this.winReason &&
          other.assassinationOutcome == this.assassinationOutcome);
}

class GamesCompanion extends UpdateCompanion<GameRecord> {
  final Value<int> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> playerCount;
  final Value<String> status;
  final Value<String?> winner;
  final Value<int?> durationSeconds;
  final Value<String> phase;
  final Value<String?> pausedFrom;
  final Value<int> leaderSeat;
  final Value<int> questNumber;
  final Value<int> rejectionCount;
  final Value<String> currentTeam;
  final Value<String> questResults;
  final Value<String> questTeams;
  final Value<String> composition;
  final Value<String?> winReason;
  final Value<String?> assassinationOutcome;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.playerCount = const Value.absent(),
    this.status = const Value.absent(),
    this.winner = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.phase = const Value.absent(),
    this.pausedFrom = const Value.absent(),
    this.leaderSeat = const Value.absent(),
    this.questNumber = const Value.absent(),
    this.rejectionCount = const Value.absent(),
    this.currentTeam = const Value.absent(),
    this.questResults = const Value.absent(),
    this.questTeams = const Value.absent(),
    this.composition = const Value.absent(),
    this.winReason = const Value.absent(),
    this.assassinationOutcome = const Value.absent(),
  });
  GamesCompanion.insert({
    this.id = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required int playerCount,
    required String status,
    this.winner = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required String phase,
    this.pausedFrom = const Value.absent(),
    required int leaderSeat,
    required int questNumber,
    required int rejectionCount,
    this.currentTeam = const Value.absent(),
    required String questResults,
    this.questTeams = const Value.absent(),
    required String composition,
    this.winReason = const Value.absent(),
    this.assassinationOutcome = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       playerCount = Value(playerCount),
       status = Value(status),
       phase = Value(phase),
       leaderSeat = Value(leaderSeat),
       questNumber = Value(questNumber),
       rejectionCount = Value(rejectionCount),
       questResults = Value(questResults),
       composition = Value(composition);
  static Insertable<GameRecord> custom({
    Expression<int>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? playerCount,
    Expression<String>? status,
    Expression<String>? winner,
    Expression<int>? durationSeconds,
    Expression<String>? phase,
    Expression<String>? pausedFrom,
    Expression<int>? leaderSeat,
    Expression<int>? questNumber,
    Expression<int>? rejectionCount,
    Expression<String>? currentTeam,
    Expression<String>? questResults,
    Expression<String>? questTeams,
    Expression<String>? composition,
    Expression<String>? winReason,
    Expression<String>? assassinationOutcome,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (playerCount != null) 'player_count': playerCount,
      if (status != null) 'status': status,
      if (winner != null) 'winner': winner,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (phase != null) 'phase': phase,
      if (pausedFrom != null) 'paused_from': pausedFrom,
      if (leaderSeat != null) 'leader_seat': leaderSeat,
      if (questNumber != null) 'quest_number': questNumber,
      if (rejectionCount != null) 'rejection_count': rejectionCount,
      if (currentTeam != null) 'current_team': currentTeam,
      if (questResults != null) 'quest_results': questResults,
      if (questTeams != null) 'quest_teams': questTeams,
      if (composition != null) 'composition': composition,
      if (winReason != null) 'win_reason': winReason,
      if (assassinationOutcome != null)
        'assassination_outcome': assassinationOutcome,
    });
  }

  GamesCompanion copyWith({
    Value<int>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? playerCount,
    Value<String>? status,
    Value<String?>? winner,
    Value<int?>? durationSeconds,
    Value<String>? phase,
    Value<String?>? pausedFrom,
    Value<int>? leaderSeat,
    Value<int>? questNumber,
    Value<int>? rejectionCount,
    Value<String>? currentTeam,
    Value<String>? questResults,
    Value<String>? questTeams,
    Value<String>? composition,
    Value<String?>? winReason,
    Value<String?>? assassinationOutcome,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playerCount: playerCount ?? this.playerCount,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      phase: phase ?? this.phase,
      pausedFrom: pausedFrom ?? this.pausedFrom,
      leaderSeat: leaderSeat ?? this.leaderSeat,
      questNumber: questNumber ?? this.questNumber,
      rejectionCount: rejectionCount ?? this.rejectionCount,
      currentTeam: currentTeam ?? this.currentTeam,
      questResults: questResults ?? this.questResults,
      questTeams: questTeams ?? this.questTeams,
      composition: composition ?? this.composition,
      winReason: winReason ?? this.winReason,
      assassinationOutcome: assassinationOutcome ?? this.assassinationOutcome,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (playerCount.present) {
      map['player_count'] = Variable<int>(playerCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (winner.present) {
      map['winner'] = Variable<String>(winner.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (pausedFrom.present) {
      map['paused_from'] = Variable<String>(pausedFrom.value);
    }
    if (leaderSeat.present) {
      map['leader_seat'] = Variable<int>(leaderSeat.value);
    }
    if (questNumber.present) {
      map['quest_number'] = Variable<int>(questNumber.value);
    }
    if (rejectionCount.present) {
      map['rejection_count'] = Variable<int>(rejectionCount.value);
    }
    if (currentTeam.present) {
      map['current_team'] = Variable<String>(currentTeam.value);
    }
    if (questResults.present) {
      map['quest_results'] = Variable<String>(questResults.value);
    }
    if (questTeams.present) {
      map['quest_teams'] = Variable<String>(questTeams.value);
    }
    if (composition.present) {
      map['composition'] = Variable<String>(composition.value);
    }
    if (winReason.present) {
      map['win_reason'] = Variable<String>(winReason.value);
    }
    if (assassinationOutcome.present) {
      map['assassination_outcome'] = Variable<String>(
        assassinationOutcome.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('playerCount: $playerCount, ')
          ..write('status: $status, ')
          ..write('winner: $winner, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('phase: $phase, ')
          ..write('pausedFrom: $pausedFrom, ')
          ..write('leaderSeat: $leaderSeat, ')
          ..write('questNumber: $questNumber, ')
          ..write('rejectionCount: $rejectionCount, ')
          ..write('currentTeam: $currentTeam, ')
          ..write('questResults: $questResults, ')
          ..write('questTeams: $questTeams, ')
          ..write('composition: $composition, ')
          ..write('winReason: $winReason, ')
          ..write('assassinationOutcome: $assassinationOutcome')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players
    with TableInfo<$PlayersTable, PlayerRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seatNumberMeta = const VerificationMeta(
    'seatNumber',
  );
  @override
  late final GeneratedColumn<int> seatNumber = GeneratedColumn<int>(
    'seat_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, gameId, displayName, seatNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('seat_number')) {
      context.handle(
        _seatNumberMeta,
        seatNumber.isAcceptableOrUnknown(data['seat_number']!, _seatNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_seatNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      seatNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seat_number'],
      )!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class PlayerRecord extends DataClass implements Insertable<PlayerRecord> {
  final int id;
  final int gameId;
  final String displayName;
  final int seatNumber;
  const PlayerRecord({
    required this.id,
    required this.gameId,
    required this.displayName,
    required this.seatNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['display_name'] = Variable<String>(displayName);
    map['seat_number'] = Variable<int>(seatNumber);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      gameId: Value(gameId),
      displayName: Value(displayName),
      seatNumber: Value(seatNumber),
    );
  }

  factory PlayerRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerRecord(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      seatNumber: serializer.fromJson<int>(json['seatNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'displayName': serializer.toJson<String>(displayName),
      'seatNumber': serializer.toJson<int>(seatNumber),
    };
  }

  PlayerRecord copyWith({
    int? id,
    int? gameId,
    String? displayName,
    int? seatNumber,
  }) => PlayerRecord(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    displayName: displayName ?? this.displayName,
    seatNumber: seatNumber ?? this.seatNumber,
  );
  PlayerRecord copyWithCompanion(PlayersCompanion data) {
    return PlayerRecord(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      seatNumber: data.seatNumber.present
          ? data.seatNumber.value
          : this.seatNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerRecord(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('displayName: $displayName, ')
          ..write('seatNumber: $seatNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gameId, displayName, seatNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerRecord &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.displayName == this.displayName &&
          other.seatNumber == this.seatNumber);
}

class PlayersCompanion extends UpdateCompanion<PlayerRecord> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<String> displayName;
  final Value<int> seatNumber;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.seatNumber = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required String displayName,
    required int seatNumber,
  }) : gameId = Value(gameId),
       displayName = Value(displayName),
       seatNumber = Value(seatNumber);
  static Insertable<PlayerRecord> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<String>? displayName,
    Expression<int>? seatNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (displayName != null) 'display_name': displayName,
      if (seatNumber != null) 'seat_number': seatNumber,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<String>? displayName,
    Value<int>? seatNumber,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      displayName: displayName ?? this.displayName,
      seatNumber: seatNumber ?? this.seatNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (seatNumber.present) {
      map['seat_number'] = Variable<int>(seatNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('displayName: $displayName, ')
          ..write('seatNumber: $seatNumber')
          ..write(')'))
        .toString();
  }
}

class $QuestsTable extends Quests with TableInfo<$QuestsTable, QuestRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _questNumberMeta = const VerificationMeta(
    'questNumber',
  );
  @override
  late final GeneratedColumn<int> questNumber = GeneratedColumn<int>(
    'quest_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredPlayersMeta = const VerificationMeta(
    'requiredPlayers',
  );
  @override
  late final GeneratedColumn<int> requiredPlayers = GeneratedColumn<int>(
    'required_players',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _successCountMeta = const VerificationMeta(
    'successCount',
  );
  @override
  late final GeneratedColumn<int> successCount = GeneratedColumn<int>(
    'success_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failCountMeta = const VerificationMeta(
    'failCount',
  );
  @override
  late final GeneratedColumn<int> failCount = GeneratedColumn<int>(
    'fail_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    questNumber,
    requiredPlayers,
    successCount,
    failCount,
    result,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quests';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('quest_number')) {
      context.handle(
        _questNumberMeta,
        questNumber.isAcceptableOrUnknown(
          data['quest_number']!,
          _questNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questNumberMeta);
    }
    if (data.containsKey('required_players')) {
      context.handle(
        _requiredPlayersMeta,
        requiredPlayers.isAcceptableOrUnknown(
          data['required_players']!,
          _requiredPlayersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requiredPlayersMeta);
    }
    if (data.containsKey('success_count')) {
      context.handle(
        _successCountMeta,
        successCount.isAcceptableOrUnknown(
          data['success_count']!,
          _successCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_successCountMeta);
    }
    if (data.containsKey('fail_count')) {
      context.handle(
        _failCountMeta,
        failCount.isAcceptableOrUnknown(data['fail_count']!, _failCountMeta),
      );
    } else if (isInserting) {
      context.missing(_failCountMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      questNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quest_number'],
      )!,
      requiredPlayers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}required_players'],
      )!,
      successCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}success_count'],
      )!,
      failCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fail_count'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
    );
  }

  @override
  $QuestsTable createAlias(String alias) {
    return $QuestsTable(attachedDatabase, alias);
  }
}

class QuestRecord extends DataClass implements Insertable<QuestRecord> {
  final int id;
  final int gameId;
  final int questNumber;
  final int requiredPlayers;
  final int successCount;
  final int failCount;

  /// `success` or `fail`.
  final String result;
  const QuestRecord({
    required this.id,
    required this.gameId,
    required this.questNumber,
    required this.requiredPlayers,
    required this.successCount,
    required this.failCount,
    required this.result,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['quest_number'] = Variable<int>(questNumber);
    map['required_players'] = Variable<int>(requiredPlayers);
    map['success_count'] = Variable<int>(successCount);
    map['fail_count'] = Variable<int>(failCount);
    map['result'] = Variable<String>(result);
    return map;
  }

  QuestsCompanion toCompanion(bool nullToAbsent) {
    return QuestsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      questNumber: Value(questNumber),
      requiredPlayers: Value(requiredPlayers),
      successCount: Value(successCount),
      failCount: Value(failCount),
      result: Value(result),
    );
  }

  factory QuestRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestRecord(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      questNumber: serializer.fromJson<int>(json['questNumber']),
      requiredPlayers: serializer.fromJson<int>(json['requiredPlayers']),
      successCount: serializer.fromJson<int>(json['successCount']),
      failCount: serializer.fromJson<int>(json['failCount']),
      result: serializer.fromJson<String>(json['result']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'questNumber': serializer.toJson<int>(questNumber),
      'requiredPlayers': serializer.toJson<int>(requiredPlayers),
      'successCount': serializer.toJson<int>(successCount),
      'failCount': serializer.toJson<int>(failCount),
      'result': serializer.toJson<String>(result),
    };
  }

  QuestRecord copyWith({
    int? id,
    int? gameId,
    int? questNumber,
    int? requiredPlayers,
    int? successCount,
    int? failCount,
    String? result,
  }) => QuestRecord(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    questNumber: questNumber ?? this.questNumber,
    requiredPlayers: requiredPlayers ?? this.requiredPlayers,
    successCount: successCount ?? this.successCount,
    failCount: failCount ?? this.failCount,
    result: result ?? this.result,
  );
  QuestRecord copyWithCompanion(QuestsCompanion data) {
    return QuestRecord(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      questNumber: data.questNumber.present
          ? data.questNumber.value
          : this.questNumber,
      requiredPlayers: data.requiredPlayers.present
          ? data.requiredPlayers.value
          : this.requiredPlayers,
      successCount: data.successCount.present
          ? data.successCount.value
          : this.successCount,
      failCount: data.failCount.present ? data.failCount.value : this.failCount,
      result: data.result.present ? data.result.value : this.result,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestRecord(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('questNumber: $questNumber, ')
          ..write('requiredPlayers: $requiredPlayers, ')
          ..write('successCount: $successCount, ')
          ..write('failCount: $failCount, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    questNumber,
    requiredPlayers,
    successCount,
    failCount,
    result,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestRecord &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.questNumber == this.questNumber &&
          other.requiredPlayers == this.requiredPlayers &&
          other.successCount == this.successCount &&
          other.failCount == this.failCount &&
          other.result == this.result);
}

class QuestsCompanion extends UpdateCompanion<QuestRecord> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> questNumber;
  final Value<int> requiredPlayers;
  final Value<int> successCount;
  final Value<int> failCount;
  final Value<String> result;
  const QuestsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.questNumber = const Value.absent(),
    this.requiredPlayers = const Value.absent(),
    this.successCount = const Value.absent(),
    this.failCount = const Value.absent(),
    this.result = const Value.absent(),
  });
  QuestsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int questNumber,
    required int requiredPlayers,
    required int successCount,
    required int failCount,
    required String result,
  }) : gameId = Value(gameId),
       questNumber = Value(questNumber),
       requiredPlayers = Value(requiredPlayers),
       successCount = Value(successCount),
       failCount = Value(failCount),
       result = Value(result);
  static Insertable<QuestRecord> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? questNumber,
    Expression<int>? requiredPlayers,
    Expression<int>? successCount,
    Expression<int>? failCount,
    Expression<String>? result,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (questNumber != null) 'quest_number': questNumber,
      if (requiredPlayers != null) 'required_players': requiredPlayers,
      if (successCount != null) 'success_count': successCount,
      if (failCount != null) 'fail_count': failCount,
      if (result != null) 'result': result,
    });
  }

  QuestsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? questNumber,
    Value<int>? requiredPlayers,
    Value<int>? successCount,
    Value<int>? failCount,
    Value<String>? result,
  }) {
    return QuestsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      questNumber: questNumber ?? this.questNumber,
      requiredPlayers: requiredPlayers ?? this.requiredPlayers,
      successCount: successCount ?? this.successCount,
      failCount: failCount ?? this.failCount,
      result: result ?? this.result,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (questNumber.present) {
      map['quest_number'] = Variable<int>(questNumber.value);
    }
    if (requiredPlayers.present) {
      map['required_players'] = Variable<int>(requiredPlayers.value);
    }
    if (successCount.present) {
      map['success_count'] = Variable<int>(successCount.value);
    }
    if (failCount.present) {
      map['fail_count'] = Variable<int>(failCount.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('questNumber: $questNumber, ')
          ..write('requiredPlayers: $requiredPlayers, ')
          ..write('successCount: $successCount, ')
          ..write('failCount: $failCount, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }
}

class $TeamProposalsTable extends TeamProposals
    with TableInfo<$TeamProposalsTable, ProposalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamProposalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _questNumberMeta = const VerificationMeta(
    'questNumber',
  );
  @override
  late final GeneratedColumn<int> questNumber = GeneratedColumn<int>(
    'quest_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leaderSeatMeta = const VerificationMeta(
    'leaderSeat',
  );
  @override
  late final GeneratedColumn<int> leaderSeat = GeneratedColumn<int>(
    'leader_seat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedSeatsMeta = const VerificationMeta(
    'selectedSeats',
  );
  @override
  late final GeneratedColumn<String> selectedSeats = GeneratedColumn<String>(
    'selected_seats',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approveCountMeta = const VerificationMeta(
    'approveCount',
  );
  @override
  late final GeneratedColumn<int> approveCount = GeneratedColumn<int>(
    'approve_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectCountMeta = const VerificationMeta(
    'rejectCount',
  );
  @override
  late final GeneratedColumn<int> rejectCount = GeneratedColumn<int>(
    'reject_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    questNumber,
    leaderSeat,
    selectedSeats,
    approveCount,
    rejectCount,
    result,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_proposals';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProposalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('quest_number')) {
      context.handle(
        _questNumberMeta,
        questNumber.isAcceptableOrUnknown(
          data['quest_number']!,
          _questNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questNumberMeta);
    }
    if (data.containsKey('leader_seat')) {
      context.handle(
        _leaderSeatMeta,
        leaderSeat.isAcceptableOrUnknown(data['leader_seat']!, _leaderSeatMeta),
      );
    } else if (isInserting) {
      context.missing(_leaderSeatMeta);
    }
    if (data.containsKey('selected_seats')) {
      context.handle(
        _selectedSeatsMeta,
        selectedSeats.isAcceptableOrUnknown(
          data['selected_seats']!,
          _selectedSeatsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedSeatsMeta);
    }
    if (data.containsKey('approve_count')) {
      context.handle(
        _approveCountMeta,
        approveCount.isAcceptableOrUnknown(
          data['approve_count']!,
          _approveCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_approveCountMeta);
    }
    if (data.containsKey('reject_count')) {
      context.handle(
        _rejectCountMeta,
        rejectCount.isAcceptableOrUnknown(
          data['reject_count']!,
          _rejectCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rejectCountMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProposalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProposalRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      questNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quest_number'],
      )!,
      leaderSeat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}leader_seat'],
      )!,
      selectedSeats: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_seats'],
      )!,
      approveCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}approve_count'],
      )!,
      rejectCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reject_count'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
    );
  }

  @override
  $TeamProposalsTable createAlias(String alias) {
    return $TeamProposalsTable(attachedDatabase, alias);
  }
}

class ProposalRecord extends DataClass implements Insertable<ProposalRecord> {
  final int id;
  final int gameId;
  final int questNumber;
  final int leaderSeat;

  /// Seats on the proposed team, comma joined and ascending.
  final String selectedSeats;
  final int approveCount;
  final int rejectCount;

  /// `approved` or `rejected`.
  final String result;
  const ProposalRecord({
    required this.id,
    required this.gameId,
    required this.questNumber,
    required this.leaderSeat,
    required this.selectedSeats,
    required this.approveCount,
    required this.rejectCount,
    required this.result,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['quest_number'] = Variable<int>(questNumber);
    map['leader_seat'] = Variable<int>(leaderSeat);
    map['selected_seats'] = Variable<String>(selectedSeats);
    map['approve_count'] = Variable<int>(approveCount);
    map['reject_count'] = Variable<int>(rejectCount);
    map['result'] = Variable<String>(result);
    return map;
  }

  TeamProposalsCompanion toCompanion(bool nullToAbsent) {
    return TeamProposalsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      questNumber: Value(questNumber),
      leaderSeat: Value(leaderSeat),
      selectedSeats: Value(selectedSeats),
      approveCount: Value(approveCount),
      rejectCount: Value(rejectCount),
      result: Value(result),
    );
  }

  factory ProposalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProposalRecord(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      questNumber: serializer.fromJson<int>(json['questNumber']),
      leaderSeat: serializer.fromJson<int>(json['leaderSeat']),
      selectedSeats: serializer.fromJson<String>(json['selectedSeats']),
      approveCount: serializer.fromJson<int>(json['approveCount']),
      rejectCount: serializer.fromJson<int>(json['rejectCount']),
      result: serializer.fromJson<String>(json['result']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'questNumber': serializer.toJson<int>(questNumber),
      'leaderSeat': serializer.toJson<int>(leaderSeat),
      'selectedSeats': serializer.toJson<String>(selectedSeats),
      'approveCount': serializer.toJson<int>(approveCount),
      'rejectCount': serializer.toJson<int>(rejectCount),
      'result': serializer.toJson<String>(result),
    };
  }

  ProposalRecord copyWith({
    int? id,
    int? gameId,
    int? questNumber,
    int? leaderSeat,
    String? selectedSeats,
    int? approveCount,
    int? rejectCount,
    String? result,
  }) => ProposalRecord(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    questNumber: questNumber ?? this.questNumber,
    leaderSeat: leaderSeat ?? this.leaderSeat,
    selectedSeats: selectedSeats ?? this.selectedSeats,
    approveCount: approveCount ?? this.approveCount,
    rejectCount: rejectCount ?? this.rejectCount,
    result: result ?? this.result,
  );
  ProposalRecord copyWithCompanion(TeamProposalsCompanion data) {
    return ProposalRecord(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      questNumber: data.questNumber.present
          ? data.questNumber.value
          : this.questNumber,
      leaderSeat: data.leaderSeat.present
          ? data.leaderSeat.value
          : this.leaderSeat,
      selectedSeats: data.selectedSeats.present
          ? data.selectedSeats.value
          : this.selectedSeats,
      approveCount: data.approveCount.present
          ? data.approveCount.value
          : this.approveCount,
      rejectCount: data.rejectCount.present
          ? data.rejectCount.value
          : this.rejectCount,
      result: data.result.present ? data.result.value : this.result,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProposalRecord(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('questNumber: $questNumber, ')
          ..write('leaderSeat: $leaderSeat, ')
          ..write('selectedSeats: $selectedSeats, ')
          ..write('approveCount: $approveCount, ')
          ..write('rejectCount: $rejectCount, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    questNumber,
    leaderSeat,
    selectedSeats,
    approveCount,
    rejectCount,
    result,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProposalRecord &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.questNumber == this.questNumber &&
          other.leaderSeat == this.leaderSeat &&
          other.selectedSeats == this.selectedSeats &&
          other.approveCount == this.approveCount &&
          other.rejectCount == this.rejectCount &&
          other.result == this.result);
}

class TeamProposalsCompanion extends UpdateCompanion<ProposalRecord> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> questNumber;
  final Value<int> leaderSeat;
  final Value<String> selectedSeats;
  final Value<int> approveCount;
  final Value<int> rejectCount;
  final Value<String> result;
  const TeamProposalsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.questNumber = const Value.absent(),
    this.leaderSeat = const Value.absent(),
    this.selectedSeats = const Value.absent(),
    this.approveCount = const Value.absent(),
    this.rejectCount = const Value.absent(),
    this.result = const Value.absent(),
  });
  TeamProposalsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int questNumber,
    required int leaderSeat,
    required String selectedSeats,
    required int approveCount,
    required int rejectCount,
    required String result,
  }) : gameId = Value(gameId),
       questNumber = Value(questNumber),
       leaderSeat = Value(leaderSeat),
       selectedSeats = Value(selectedSeats),
       approveCount = Value(approveCount),
       rejectCount = Value(rejectCount),
       result = Value(result);
  static Insertable<ProposalRecord> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? questNumber,
    Expression<int>? leaderSeat,
    Expression<String>? selectedSeats,
    Expression<int>? approveCount,
    Expression<int>? rejectCount,
    Expression<String>? result,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (questNumber != null) 'quest_number': questNumber,
      if (leaderSeat != null) 'leader_seat': leaderSeat,
      if (selectedSeats != null) 'selected_seats': selectedSeats,
      if (approveCount != null) 'approve_count': approveCount,
      if (rejectCount != null) 'reject_count': rejectCount,
      if (result != null) 'result': result,
    });
  }

  TeamProposalsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? questNumber,
    Value<int>? leaderSeat,
    Value<String>? selectedSeats,
    Value<int>? approveCount,
    Value<int>? rejectCount,
    Value<String>? result,
  }) {
    return TeamProposalsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      questNumber: questNumber ?? this.questNumber,
      leaderSeat: leaderSeat ?? this.leaderSeat,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      approveCount: approveCount ?? this.approveCount,
      rejectCount: rejectCount ?? this.rejectCount,
      result: result ?? this.result,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (questNumber.present) {
      map['quest_number'] = Variable<int>(questNumber.value);
    }
    if (leaderSeat.present) {
      map['leader_seat'] = Variable<int>(leaderSeat.value);
    }
    if (selectedSeats.present) {
      map['selected_seats'] = Variable<String>(selectedSeats.value);
    }
    if (approveCount.present) {
      map['approve_count'] = Variable<int>(approveCount.value);
    }
    if (rejectCount.present) {
      map['reject_count'] = Variable<int>(rejectCount.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamProposalsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('questNumber: $questNumber, ')
          ..write('leaderSeat: $leaderSeat, ')
          ..write('selectedSeats: $selectedSeats, ')
          ..write('approveCount: $approveCount, ')
          ..write('rejectCount: $rejectCount, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }
}

class $GameEventsTable extends GameEvents
    with TableInfo<$GameEventsTable, EventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventDescriptionMeta = const VerificationMeta(
    'eventDescription',
  );
  @override
  late final GeneratedColumn<String> eventDescription = GeneratedColumn<String>(
    'event_description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    eventType,
    eventDescription,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('event_description')) {
      context.handle(
        _eventDescriptionMeta,
        eventDescription.isAcceptableOrUnknown(
          data['event_description']!,
          _eventDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventDescriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      eventDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GameEventsTable createAlias(String alias) {
    return $GameEventsTable(attachedDatabase, alias);
  }
}

class EventRecord extends DataClass implements Insertable<EventRecord> {
  final int id;
  final int gameId;
  final String eventType;
  final String eventDescription;

  /// UTC milliseconds since epoch.
  final int createdAt;
  const EventRecord({
    required this.id,
    required this.gameId,
    required this.eventType,
    required this.eventDescription,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['event_type'] = Variable<String>(eventType);
    map['event_description'] = Variable<String>(eventDescription);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  GameEventsCompanion toCompanion(bool nullToAbsent) {
    return GameEventsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      eventType: Value(eventType),
      eventDescription: Value(eventDescription),
      createdAt: Value(createdAt),
    );
  }

  factory EventRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRecord(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      eventDescription: serializer.fromJson<String>(json['eventDescription']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'eventType': serializer.toJson<String>(eventType),
      'eventDescription': serializer.toJson<String>(eventDescription),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  EventRecord copyWith({
    int? id,
    int? gameId,
    String? eventType,
    String? eventDescription,
    int? createdAt,
  }) => EventRecord(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    eventType: eventType ?? this.eventType,
    eventDescription: eventDescription ?? this.eventDescription,
    createdAt: createdAt ?? this.createdAt,
  );
  EventRecord copyWithCompanion(GameEventsCompanion data) {
    return EventRecord(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      eventDescription: data.eventDescription.present
          ? data.eventDescription.value
          : this.eventDescription,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRecord(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('eventType: $eventType, ')
          ..write('eventDescription: $eventDescription, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, eventType, eventDescription, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRecord &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.eventType == this.eventType &&
          other.eventDescription == this.eventDescription &&
          other.createdAt == this.createdAt);
}

class GameEventsCompanion extends UpdateCompanion<EventRecord> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<String> eventType;
  final Value<String> eventDescription;
  final Value<int> createdAt;
  const GameEventsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.eventDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GameEventsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required String eventType,
    required String eventDescription,
    required int createdAt,
  }) : gameId = Value(gameId),
       eventType = Value(eventType),
       eventDescription = Value(eventDescription),
       createdAt = Value(createdAt);
  static Insertable<EventRecord> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<String>? eventType,
    Expression<String>? eventDescription,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (eventType != null) 'event_type': eventType,
      if (eventDescription != null) 'event_description': eventDescription,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GameEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<String>? eventType,
    Value<String>? eventDescription,
    Value<int>? createdAt,
  }) {
    return GameEventsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      eventType: eventType ?? this.eventType,
      eventDescription: eventDescription ?? this.eventDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (eventDescription.present) {
      map['event_description'] = Variable<String>(eventDescription.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameEventsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('eventType: $eventType, ')
          ..write('eventDescription: $eventDescription, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingsRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _narrationLanguageMeta = const VerificationMeta(
    'narrationLanguage',
  );
  @override
  late final GeneratedColumn<String> narrationLanguage =
      GeneratedColumn<String>(
        'narration_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('english'),
      );
  static const VerificationMeta _narrationSpeedMeta = const VerificationMeta(
    'narrationSpeed',
  );
  @override
  late final GeneratedColumn<double> narrationSpeed = GeneratedColumn<double>(
    'narration_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.9),
  );
  static const VerificationMeta _narrationPitchMeta = const VerificationMeta(
    'narrationPitch',
  );
  @override
  late final GeneratedColumn<double> narrationPitch = GeneratedColumn<double>(
    'narration_pitch',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.92),
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.8),
  );
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ambientAudioEnabledMeta =
      const VerificationMeta('ambientAudioEnabled');
  @override
  late final GeneratedColumn<bool> ambientAudioEnabled = GeneratedColumn<bool>(
    'ambient_audio_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ambient_audio_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _autoAdvanceMeta = const VerificationMeta(
    'autoAdvance',
  );
  @override
  late final GeneratedColumn<bool> autoAdvance = GeneratedColumn<bool>(
    'auto_advance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_advance" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _keepScreenAwakeMeta = const VerificationMeta(
    'keepScreenAwake',
  );
  @override
  late final GeneratedColumn<bool> keepScreenAwake = GeneratedColumn<bool>(
    'keep_screen_awake',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("keep_screen_awake" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _confirmationsMeta = const VerificationMeta(
    'confirmations',
  );
  @override
  late final GeneratedColumn<bool> confirmations = GeneratedColumn<bool>(
    'confirmations',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmations" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hapticsMeta = const VerificationMeta(
    'haptics',
  );
  @override
  late final GeneratedColumn<bool> haptics = GeneratedColumn<bool>(
    'haptics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("haptics" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _soundEffectsMeta = const VerificationMeta(
    'soundEffects',
  );
  @override
  late final GeneratedColumn<bool> soundEffects = GeneratedColumn<bool>(
    'sound_effects',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sound_effects" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _discussionSecondsMeta = const VerificationMeta(
    'discussionSeconds',
  );
  @override
  late final GeneratedColumn<int> discussionSeconds = GeneratedColumn<int>(
    'discussion_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(300),
  );
  static const VerificationMeta _defaultPlayerCountMeta =
      const VerificationMeta('defaultPlayerCount');
  @override
  late final GeneratedColumn<int> defaultPlayerCount = GeneratedColumn<int>(
    'default_player_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _mcPinEnabledMeta = const VerificationMeta(
    'mcPinEnabled',
  );
  @override
  late final GeneratedColumn<bool> mcPinEnabled = GeneratedColumn<bool>(
    'mc_pin_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mc_pin_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mcPinHashMeta = const VerificationMeta(
    'mcPinHash',
  );
  @override
  late final GeneratedColumn<String> mcPinHash = GeneratedColumn<String>(
    'mc_pin_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kingSelectionMeta = const VerificationMeta(
    'kingSelection',
  );
  @override
  late final GeneratedColumn<String> kingSelection = GeneratedColumn<String>(
    'king_selection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _narratorExtraDelayMsMeta =
      const VerificationMeta('narratorExtraDelayMs');
  @override
  late final GeneratedColumn<int> narratorExtraDelayMs = GeneratedColumn<int>(
    'narrator_extra_delay_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamVoteEnabledMeta = const VerificationMeta(
    'teamVoteEnabled',
  );
  @override
  late final GeneratedColumn<bool> teamVoteEnabled = GeneratedColumn<bool>(
    'team_vote_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("team_vote_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _voicePackIdMeta = const VerificationMeta(
    'voicePackId',
  );
  @override
  late final GeneratedColumn<String> voicePackId = GeneratedColumn<String>(
    'voice_pack_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    narrationLanguage,
    narrationSpeed,
    narrationPitch,
    volume,
    voiceId,
    ambientAudioEnabled,
    autoAdvance,
    keepScreenAwake,
    confirmations,
    haptics,
    soundEffects,
    discussionSeconds,
    defaultPlayerCount,
    mcPinEnabled,
    mcPinHash,
    kingSelection,
    narratorExtraDelayMs,
    teamVoteEnabled,
    voicePackId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('narration_language')) {
      context.handle(
        _narrationLanguageMeta,
        narrationLanguage.isAcceptableOrUnknown(
          data['narration_language']!,
          _narrationLanguageMeta,
        ),
      );
    }
    if (data.containsKey('narration_speed')) {
      context.handle(
        _narrationSpeedMeta,
        narrationSpeed.isAcceptableOrUnknown(
          data['narration_speed']!,
          _narrationSpeedMeta,
        ),
      );
    }
    if (data.containsKey('narration_pitch')) {
      context.handle(
        _narrationPitchMeta,
        narrationPitch.isAcceptableOrUnknown(
          data['narration_pitch']!,
          _narrationPitchMeta,
        ),
      );
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
      );
    }
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    }
    if (data.containsKey('ambient_audio_enabled')) {
      context.handle(
        _ambientAudioEnabledMeta,
        ambientAudioEnabled.isAcceptableOrUnknown(
          data['ambient_audio_enabled']!,
          _ambientAudioEnabledMeta,
        ),
      );
    }
    if (data.containsKey('auto_advance')) {
      context.handle(
        _autoAdvanceMeta,
        autoAdvance.isAcceptableOrUnknown(
          data['auto_advance']!,
          _autoAdvanceMeta,
        ),
      );
    }
    if (data.containsKey('keep_screen_awake')) {
      context.handle(
        _keepScreenAwakeMeta,
        keepScreenAwake.isAcceptableOrUnknown(
          data['keep_screen_awake']!,
          _keepScreenAwakeMeta,
        ),
      );
    }
    if (data.containsKey('confirmations')) {
      context.handle(
        _confirmationsMeta,
        confirmations.isAcceptableOrUnknown(
          data['confirmations']!,
          _confirmationsMeta,
        ),
      );
    }
    if (data.containsKey('haptics')) {
      context.handle(
        _hapticsMeta,
        haptics.isAcceptableOrUnknown(data['haptics']!, _hapticsMeta),
      );
    }
    if (data.containsKey('sound_effects')) {
      context.handle(
        _soundEffectsMeta,
        soundEffects.isAcceptableOrUnknown(
          data['sound_effects']!,
          _soundEffectsMeta,
        ),
      );
    }
    if (data.containsKey('discussion_seconds')) {
      context.handle(
        _discussionSecondsMeta,
        discussionSeconds.isAcceptableOrUnknown(
          data['discussion_seconds']!,
          _discussionSecondsMeta,
        ),
      );
    }
    if (data.containsKey('default_player_count')) {
      context.handle(
        _defaultPlayerCountMeta,
        defaultPlayerCount.isAcceptableOrUnknown(
          data['default_player_count']!,
          _defaultPlayerCountMeta,
        ),
      );
    }
    if (data.containsKey('mc_pin_enabled')) {
      context.handle(
        _mcPinEnabledMeta,
        mcPinEnabled.isAcceptableOrUnknown(
          data['mc_pin_enabled']!,
          _mcPinEnabledMeta,
        ),
      );
    }
    if (data.containsKey('mc_pin_hash')) {
      context.handle(
        _mcPinHashMeta,
        mcPinHash.isAcceptableOrUnknown(data['mc_pin_hash']!, _mcPinHashMeta),
      );
    }
    if (data.containsKey('king_selection')) {
      context.handle(
        _kingSelectionMeta,
        kingSelection.isAcceptableOrUnknown(
          data['king_selection']!,
          _kingSelectionMeta,
        ),
      );
    }
    if (data.containsKey('narrator_extra_delay_ms')) {
      context.handle(
        _narratorExtraDelayMsMeta,
        narratorExtraDelayMs.isAcceptableOrUnknown(
          data['narrator_extra_delay_ms']!,
          _narratorExtraDelayMsMeta,
        ),
      );
    }
    if (data.containsKey('team_vote_enabled')) {
      context.handle(
        _teamVoteEnabledMeta,
        teamVoteEnabled.isAcceptableOrUnknown(
          data['team_vote_enabled']!,
          _teamVoteEnabledMeta,
        ),
      );
    }
    if (data.containsKey('voice_pack_id')) {
      context.handle(
        _voicePackIdMeta,
        voicePackId.isAcceptableOrUnknown(
          data['voice_pack_id']!,
          _voicePackIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SettingsRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      narrationLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narration_language'],
      )!,
      narrationSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}narration_speed'],
      )!,
      narrationPitch: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}narration_pitch'],
      )!,
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      ),
      ambientAudioEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ambient_audio_enabled'],
      )!,
      autoAdvance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_advance'],
      )!,
      keepScreenAwake: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_screen_awake'],
      )!,
      confirmations: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmations'],
      )!,
      haptics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}haptics'],
      )!,
      soundEffects: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sound_effects'],
      )!,
      discussionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discussion_seconds'],
      )!,
      defaultPlayerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_player_count'],
      )!,
      mcPinEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mc_pin_enabled'],
      )!,
      mcPinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mc_pin_hash'],
      ),
      kingSelection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}king_selection'],
      )!,
      narratorExtraDelayMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}narrator_extra_delay_ms'],
      )!,
      teamVoteEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}team_vote_enabled'],
      )!,
      voicePackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_pack_id'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingsRecord extends DataClass implements Insertable<SettingsRecord> {
  final int id;
  final String narrationLanguage;
  final double narrationSpeed;
  final double narrationPitch;
  final double volume;
  final String? voiceId;
  final bool ambientAudioEnabled;
  final bool autoAdvance;
  final bool keepScreenAwake;
  final bool confirmations;
  final bool haptics;
  final bool soundEffects;
  final int discussionSeconds;
  final int defaultPlayerCount;
  final bool mcPinEnabled;

  /// Salted SHA-256 of the MC PIN as `salt:hash`; null when no PIN is set.
  ///
  /// A four-digit PIN is a lock on the table, not a password vault: this keeps
  /// it out of plain sight in the file and off every screen. See
  /// `PinRepository`.
  final String? mcPinHash;

  /// `automatic` or `manual` — whether the wheel draws a King every round.
  final String kingSelection;

  /// Extra silence after each spoken narration line, in milliseconds.
  final int narratorExtraDelayMs;

  /// Whether the table votes on every proposed team. Off is a house rule: the
  /// chosen team goes straight to the quest and rejections never count.
  final bool teamVoteEnabled;

  /// The narrator voice the MC chose. Null means the recordings that ship with
  /// the app, so an untouched install needs no row value.
  final String? voicePackId;
  const SettingsRecord({
    required this.id,
    required this.narrationLanguage,
    required this.narrationSpeed,
    required this.narrationPitch,
    required this.volume,
    this.voiceId,
    required this.ambientAudioEnabled,
    required this.autoAdvance,
    required this.keepScreenAwake,
    required this.confirmations,
    required this.haptics,
    required this.soundEffects,
    required this.discussionSeconds,
    required this.defaultPlayerCount,
    required this.mcPinEnabled,
    this.mcPinHash,
    required this.kingSelection,
    required this.narratorExtraDelayMs,
    required this.teamVoteEnabled,
    this.voicePackId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['narration_language'] = Variable<String>(narrationLanguage);
    map['narration_speed'] = Variable<double>(narrationSpeed);
    map['narration_pitch'] = Variable<double>(narrationPitch);
    map['volume'] = Variable<double>(volume);
    if (!nullToAbsent || voiceId != null) {
      map['voice_id'] = Variable<String>(voiceId);
    }
    map['ambient_audio_enabled'] = Variable<bool>(ambientAudioEnabled);
    map['auto_advance'] = Variable<bool>(autoAdvance);
    map['keep_screen_awake'] = Variable<bool>(keepScreenAwake);
    map['confirmations'] = Variable<bool>(confirmations);
    map['haptics'] = Variable<bool>(haptics);
    map['sound_effects'] = Variable<bool>(soundEffects);
    map['discussion_seconds'] = Variable<int>(discussionSeconds);
    map['default_player_count'] = Variable<int>(defaultPlayerCount);
    map['mc_pin_enabled'] = Variable<bool>(mcPinEnabled);
    if (!nullToAbsent || mcPinHash != null) {
      map['mc_pin_hash'] = Variable<String>(mcPinHash);
    }
    map['king_selection'] = Variable<String>(kingSelection);
    map['narrator_extra_delay_ms'] = Variable<int>(narratorExtraDelayMs);
    map['team_vote_enabled'] = Variable<bool>(teamVoteEnabled);
    if (!nullToAbsent || voicePackId != null) {
      map['voice_pack_id'] = Variable<String>(voicePackId);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      narrationLanguage: Value(narrationLanguage),
      narrationSpeed: Value(narrationSpeed),
      narrationPitch: Value(narrationPitch),
      volume: Value(volume),
      voiceId: voiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceId),
      ambientAudioEnabled: Value(ambientAudioEnabled),
      autoAdvance: Value(autoAdvance),
      keepScreenAwake: Value(keepScreenAwake),
      confirmations: Value(confirmations),
      haptics: Value(haptics),
      soundEffects: Value(soundEffects),
      discussionSeconds: Value(discussionSeconds),
      defaultPlayerCount: Value(defaultPlayerCount),
      mcPinEnabled: Value(mcPinEnabled),
      mcPinHash: mcPinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(mcPinHash),
      kingSelection: Value(kingSelection),
      narratorExtraDelayMs: Value(narratorExtraDelayMs),
      teamVoteEnabled: Value(teamVoteEnabled),
      voicePackId: voicePackId == null && nullToAbsent
          ? const Value.absent()
          : Value(voicePackId),
    );
  }

  factory SettingsRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRecord(
      id: serializer.fromJson<int>(json['id']),
      narrationLanguage: serializer.fromJson<String>(json['narrationLanguage']),
      narrationSpeed: serializer.fromJson<double>(json['narrationSpeed']),
      narrationPitch: serializer.fromJson<double>(json['narrationPitch']),
      volume: serializer.fromJson<double>(json['volume']),
      voiceId: serializer.fromJson<String?>(json['voiceId']),
      ambientAudioEnabled: serializer.fromJson<bool>(
        json['ambientAudioEnabled'],
      ),
      autoAdvance: serializer.fromJson<bool>(json['autoAdvance']),
      keepScreenAwake: serializer.fromJson<bool>(json['keepScreenAwake']),
      confirmations: serializer.fromJson<bool>(json['confirmations']),
      haptics: serializer.fromJson<bool>(json['haptics']),
      soundEffects: serializer.fromJson<bool>(json['soundEffects']),
      discussionSeconds: serializer.fromJson<int>(json['discussionSeconds']),
      defaultPlayerCount: serializer.fromJson<int>(json['defaultPlayerCount']),
      mcPinEnabled: serializer.fromJson<bool>(json['mcPinEnabled']),
      mcPinHash: serializer.fromJson<String?>(json['mcPinHash']),
      kingSelection: serializer.fromJson<String>(json['kingSelection']),
      narratorExtraDelayMs: serializer.fromJson<int>(
        json['narratorExtraDelayMs'],
      ),
      teamVoteEnabled: serializer.fromJson<bool>(json['teamVoteEnabled']),
      voicePackId: serializer.fromJson<String?>(json['voicePackId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'narrationLanguage': serializer.toJson<String>(narrationLanguage),
      'narrationSpeed': serializer.toJson<double>(narrationSpeed),
      'narrationPitch': serializer.toJson<double>(narrationPitch),
      'volume': serializer.toJson<double>(volume),
      'voiceId': serializer.toJson<String?>(voiceId),
      'ambientAudioEnabled': serializer.toJson<bool>(ambientAudioEnabled),
      'autoAdvance': serializer.toJson<bool>(autoAdvance),
      'keepScreenAwake': serializer.toJson<bool>(keepScreenAwake),
      'confirmations': serializer.toJson<bool>(confirmations),
      'haptics': serializer.toJson<bool>(haptics),
      'soundEffects': serializer.toJson<bool>(soundEffects),
      'discussionSeconds': serializer.toJson<int>(discussionSeconds),
      'defaultPlayerCount': serializer.toJson<int>(defaultPlayerCount),
      'mcPinEnabled': serializer.toJson<bool>(mcPinEnabled),
      'mcPinHash': serializer.toJson<String?>(mcPinHash),
      'kingSelection': serializer.toJson<String>(kingSelection),
      'narratorExtraDelayMs': serializer.toJson<int>(narratorExtraDelayMs),
      'teamVoteEnabled': serializer.toJson<bool>(teamVoteEnabled),
      'voicePackId': serializer.toJson<String?>(voicePackId),
    };
  }

  SettingsRecord copyWith({
    int? id,
    String? narrationLanguage,
    double? narrationSpeed,
    double? narrationPitch,
    double? volume,
    Value<String?> voiceId = const Value.absent(),
    bool? ambientAudioEnabled,
    bool? autoAdvance,
    bool? keepScreenAwake,
    bool? confirmations,
    bool? haptics,
    bool? soundEffects,
    int? discussionSeconds,
    int? defaultPlayerCount,
    bool? mcPinEnabled,
    Value<String?> mcPinHash = const Value.absent(),
    String? kingSelection,
    int? narratorExtraDelayMs,
    bool? teamVoteEnabled,
    Value<String?> voicePackId = const Value.absent(),
  }) => SettingsRecord(
    id: id ?? this.id,
    narrationLanguage: narrationLanguage ?? this.narrationLanguage,
    narrationSpeed: narrationSpeed ?? this.narrationSpeed,
    narrationPitch: narrationPitch ?? this.narrationPitch,
    volume: volume ?? this.volume,
    voiceId: voiceId.present ? voiceId.value : this.voiceId,
    ambientAudioEnabled: ambientAudioEnabled ?? this.ambientAudioEnabled,
    autoAdvance: autoAdvance ?? this.autoAdvance,
    keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    confirmations: confirmations ?? this.confirmations,
    haptics: haptics ?? this.haptics,
    soundEffects: soundEffects ?? this.soundEffects,
    discussionSeconds: discussionSeconds ?? this.discussionSeconds,
    defaultPlayerCount: defaultPlayerCount ?? this.defaultPlayerCount,
    mcPinEnabled: mcPinEnabled ?? this.mcPinEnabled,
    mcPinHash: mcPinHash.present ? mcPinHash.value : this.mcPinHash,
    kingSelection: kingSelection ?? this.kingSelection,
    narratorExtraDelayMs: narratorExtraDelayMs ?? this.narratorExtraDelayMs,
    teamVoteEnabled: teamVoteEnabled ?? this.teamVoteEnabled,
    voicePackId: voicePackId.present ? voicePackId.value : this.voicePackId,
  );
  SettingsRecord copyWithCompanion(SettingsCompanion data) {
    return SettingsRecord(
      id: data.id.present ? data.id.value : this.id,
      narrationLanguage: data.narrationLanguage.present
          ? data.narrationLanguage.value
          : this.narrationLanguage,
      narrationSpeed: data.narrationSpeed.present
          ? data.narrationSpeed.value
          : this.narrationSpeed,
      narrationPitch: data.narrationPitch.present
          ? data.narrationPitch.value
          : this.narrationPitch,
      volume: data.volume.present ? data.volume.value : this.volume,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      ambientAudioEnabled: data.ambientAudioEnabled.present
          ? data.ambientAudioEnabled.value
          : this.ambientAudioEnabled,
      autoAdvance: data.autoAdvance.present
          ? data.autoAdvance.value
          : this.autoAdvance,
      keepScreenAwake: data.keepScreenAwake.present
          ? data.keepScreenAwake.value
          : this.keepScreenAwake,
      confirmations: data.confirmations.present
          ? data.confirmations.value
          : this.confirmations,
      haptics: data.haptics.present ? data.haptics.value : this.haptics,
      soundEffects: data.soundEffects.present
          ? data.soundEffects.value
          : this.soundEffects,
      discussionSeconds: data.discussionSeconds.present
          ? data.discussionSeconds.value
          : this.discussionSeconds,
      defaultPlayerCount: data.defaultPlayerCount.present
          ? data.defaultPlayerCount.value
          : this.defaultPlayerCount,
      mcPinEnabled: data.mcPinEnabled.present
          ? data.mcPinEnabled.value
          : this.mcPinEnabled,
      mcPinHash: data.mcPinHash.present ? data.mcPinHash.value : this.mcPinHash,
      kingSelection: data.kingSelection.present
          ? data.kingSelection.value
          : this.kingSelection,
      narratorExtraDelayMs: data.narratorExtraDelayMs.present
          ? data.narratorExtraDelayMs.value
          : this.narratorExtraDelayMs,
      teamVoteEnabled: data.teamVoteEnabled.present
          ? data.teamVoteEnabled.value
          : this.teamVoteEnabled,
      voicePackId: data.voicePackId.present
          ? data.voicePackId.value
          : this.voicePackId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRecord(')
          ..write('id: $id, ')
          ..write('narrationLanguage: $narrationLanguage, ')
          ..write('narrationSpeed: $narrationSpeed, ')
          ..write('narrationPitch: $narrationPitch, ')
          ..write('volume: $volume, ')
          ..write('voiceId: $voiceId, ')
          ..write('ambientAudioEnabled: $ambientAudioEnabled, ')
          ..write('autoAdvance: $autoAdvance, ')
          ..write('keepScreenAwake: $keepScreenAwake, ')
          ..write('confirmations: $confirmations, ')
          ..write('haptics: $haptics, ')
          ..write('soundEffects: $soundEffects, ')
          ..write('discussionSeconds: $discussionSeconds, ')
          ..write('defaultPlayerCount: $defaultPlayerCount, ')
          ..write('mcPinEnabled: $mcPinEnabled, ')
          ..write('mcPinHash: $mcPinHash, ')
          ..write('kingSelection: $kingSelection, ')
          ..write('narratorExtraDelayMs: $narratorExtraDelayMs, ')
          ..write('teamVoteEnabled: $teamVoteEnabled, ')
          ..write('voicePackId: $voicePackId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    narrationLanguage,
    narrationSpeed,
    narrationPitch,
    volume,
    voiceId,
    ambientAudioEnabled,
    autoAdvance,
    keepScreenAwake,
    confirmations,
    haptics,
    soundEffects,
    discussionSeconds,
    defaultPlayerCount,
    mcPinEnabled,
    mcPinHash,
    kingSelection,
    narratorExtraDelayMs,
    teamVoteEnabled,
    voicePackId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRecord &&
          other.id == this.id &&
          other.narrationLanguage == this.narrationLanguage &&
          other.narrationSpeed == this.narrationSpeed &&
          other.narrationPitch == this.narrationPitch &&
          other.volume == this.volume &&
          other.voiceId == this.voiceId &&
          other.ambientAudioEnabled == this.ambientAudioEnabled &&
          other.autoAdvance == this.autoAdvance &&
          other.keepScreenAwake == this.keepScreenAwake &&
          other.confirmations == this.confirmations &&
          other.haptics == this.haptics &&
          other.soundEffects == this.soundEffects &&
          other.discussionSeconds == this.discussionSeconds &&
          other.defaultPlayerCount == this.defaultPlayerCount &&
          other.mcPinEnabled == this.mcPinEnabled &&
          other.mcPinHash == this.mcPinHash &&
          other.kingSelection == this.kingSelection &&
          other.narratorExtraDelayMs == this.narratorExtraDelayMs &&
          other.teamVoteEnabled == this.teamVoteEnabled &&
          other.voicePackId == this.voicePackId);
}

class SettingsCompanion extends UpdateCompanion<SettingsRecord> {
  final Value<int> id;
  final Value<String> narrationLanguage;
  final Value<double> narrationSpeed;
  final Value<double> narrationPitch;
  final Value<double> volume;
  final Value<String?> voiceId;
  final Value<bool> ambientAudioEnabled;
  final Value<bool> autoAdvance;
  final Value<bool> keepScreenAwake;
  final Value<bool> confirmations;
  final Value<bool> haptics;
  final Value<bool> soundEffects;
  final Value<int> discussionSeconds;
  final Value<int> defaultPlayerCount;
  final Value<bool> mcPinEnabled;
  final Value<String?> mcPinHash;
  final Value<String> kingSelection;
  final Value<int> narratorExtraDelayMs;
  final Value<bool> teamVoteEnabled;
  final Value<String?> voicePackId;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.narrationLanguage = const Value.absent(),
    this.narrationSpeed = const Value.absent(),
    this.narrationPitch = const Value.absent(),
    this.volume = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.ambientAudioEnabled = const Value.absent(),
    this.autoAdvance = const Value.absent(),
    this.keepScreenAwake = const Value.absent(),
    this.confirmations = const Value.absent(),
    this.haptics = const Value.absent(),
    this.soundEffects = const Value.absent(),
    this.discussionSeconds = const Value.absent(),
    this.defaultPlayerCount = const Value.absent(),
    this.mcPinEnabled = const Value.absent(),
    this.mcPinHash = const Value.absent(),
    this.kingSelection = const Value.absent(),
    this.narratorExtraDelayMs = const Value.absent(),
    this.teamVoteEnabled = const Value.absent(),
    this.voicePackId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required int id,
    this.narrationLanguage = const Value.absent(),
    this.narrationSpeed = const Value.absent(),
    this.narrationPitch = const Value.absent(),
    this.volume = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.ambientAudioEnabled = const Value.absent(),
    this.autoAdvance = const Value.absent(),
    this.keepScreenAwake = const Value.absent(),
    this.confirmations = const Value.absent(),
    this.haptics = const Value.absent(),
    this.soundEffects = const Value.absent(),
    this.discussionSeconds = const Value.absent(),
    this.defaultPlayerCount = const Value.absent(),
    this.mcPinEnabled = const Value.absent(),
    this.mcPinHash = const Value.absent(),
    this.kingSelection = const Value.absent(),
    this.narratorExtraDelayMs = const Value.absent(),
    this.teamVoteEnabled = const Value.absent(),
    this.voicePackId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<SettingsRecord> custom({
    Expression<int>? id,
    Expression<String>? narrationLanguage,
    Expression<double>? narrationSpeed,
    Expression<double>? narrationPitch,
    Expression<double>? volume,
    Expression<String>? voiceId,
    Expression<bool>? ambientAudioEnabled,
    Expression<bool>? autoAdvance,
    Expression<bool>? keepScreenAwake,
    Expression<bool>? confirmations,
    Expression<bool>? haptics,
    Expression<bool>? soundEffects,
    Expression<int>? discussionSeconds,
    Expression<int>? defaultPlayerCount,
    Expression<bool>? mcPinEnabled,
    Expression<String>? mcPinHash,
    Expression<String>? kingSelection,
    Expression<int>? narratorExtraDelayMs,
    Expression<bool>? teamVoteEnabled,
    Expression<String>? voicePackId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (narrationLanguage != null) 'narration_language': narrationLanguage,
      if (narrationSpeed != null) 'narration_speed': narrationSpeed,
      if (narrationPitch != null) 'narration_pitch': narrationPitch,
      if (volume != null) 'volume': volume,
      if (voiceId != null) 'voice_id': voiceId,
      if (ambientAudioEnabled != null)
        'ambient_audio_enabled': ambientAudioEnabled,
      if (autoAdvance != null) 'auto_advance': autoAdvance,
      if (keepScreenAwake != null) 'keep_screen_awake': keepScreenAwake,
      if (confirmations != null) 'confirmations': confirmations,
      if (haptics != null) 'haptics': haptics,
      if (soundEffects != null) 'sound_effects': soundEffects,
      if (discussionSeconds != null) 'discussion_seconds': discussionSeconds,
      if (defaultPlayerCount != null)
        'default_player_count': defaultPlayerCount,
      if (mcPinEnabled != null) 'mc_pin_enabled': mcPinEnabled,
      if (mcPinHash != null) 'mc_pin_hash': mcPinHash,
      if (kingSelection != null) 'king_selection': kingSelection,
      if (narratorExtraDelayMs != null)
        'narrator_extra_delay_ms': narratorExtraDelayMs,
      if (teamVoteEnabled != null) 'team_vote_enabled': teamVoteEnabled,
      if (voicePackId != null) 'voice_pack_id': voicePackId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? narrationLanguage,
    Value<double>? narrationSpeed,
    Value<double>? narrationPitch,
    Value<double>? volume,
    Value<String?>? voiceId,
    Value<bool>? ambientAudioEnabled,
    Value<bool>? autoAdvance,
    Value<bool>? keepScreenAwake,
    Value<bool>? confirmations,
    Value<bool>? haptics,
    Value<bool>? soundEffects,
    Value<int>? discussionSeconds,
    Value<int>? defaultPlayerCount,
    Value<bool>? mcPinEnabled,
    Value<String?>? mcPinHash,
    Value<String>? kingSelection,
    Value<int>? narratorExtraDelayMs,
    Value<bool>? teamVoteEnabled,
    Value<String?>? voicePackId,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      narrationLanguage: narrationLanguage ?? this.narrationLanguage,
      narrationSpeed: narrationSpeed ?? this.narrationSpeed,
      narrationPitch: narrationPitch ?? this.narrationPitch,
      volume: volume ?? this.volume,
      voiceId: voiceId ?? this.voiceId,
      ambientAudioEnabled: ambientAudioEnabled ?? this.ambientAudioEnabled,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      confirmations: confirmations ?? this.confirmations,
      haptics: haptics ?? this.haptics,
      soundEffects: soundEffects ?? this.soundEffects,
      discussionSeconds: discussionSeconds ?? this.discussionSeconds,
      defaultPlayerCount: defaultPlayerCount ?? this.defaultPlayerCount,
      mcPinEnabled: mcPinEnabled ?? this.mcPinEnabled,
      mcPinHash: mcPinHash ?? this.mcPinHash,
      kingSelection: kingSelection ?? this.kingSelection,
      narratorExtraDelayMs: narratorExtraDelayMs ?? this.narratorExtraDelayMs,
      teamVoteEnabled: teamVoteEnabled ?? this.teamVoteEnabled,
      voicePackId: voicePackId ?? this.voicePackId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (narrationLanguage.present) {
      map['narration_language'] = Variable<String>(narrationLanguage.value);
    }
    if (narrationSpeed.present) {
      map['narration_speed'] = Variable<double>(narrationSpeed.value);
    }
    if (narrationPitch.present) {
      map['narration_pitch'] = Variable<double>(narrationPitch.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    if (ambientAudioEnabled.present) {
      map['ambient_audio_enabled'] = Variable<bool>(ambientAudioEnabled.value);
    }
    if (autoAdvance.present) {
      map['auto_advance'] = Variable<bool>(autoAdvance.value);
    }
    if (keepScreenAwake.present) {
      map['keep_screen_awake'] = Variable<bool>(keepScreenAwake.value);
    }
    if (confirmations.present) {
      map['confirmations'] = Variable<bool>(confirmations.value);
    }
    if (haptics.present) {
      map['haptics'] = Variable<bool>(haptics.value);
    }
    if (soundEffects.present) {
      map['sound_effects'] = Variable<bool>(soundEffects.value);
    }
    if (discussionSeconds.present) {
      map['discussion_seconds'] = Variable<int>(discussionSeconds.value);
    }
    if (defaultPlayerCount.present) {
      map['default_player_count'] = Variable<int>(defaultPlayerCount.value);
    }
    if (mcPinEnabled.present) {
      map['mc_pin_enabled'] = Variable<bool>(mcPinEnabled.value);
    }
    if (mcPinHash.present) {
      map['mc_pin_hash'] = Variable<String>(mcPinHash.value);
    }
    if (kingSelection.present) {
      map['king_selection'] = Variable<String>(kingSelection.value);
    }
    if (narratorExtraDelayMs.present) {
      map['narrator_extra_delay_ms'] = Variable<int>(
        narratorExtraDelayMs.value,
      );
    }
    if (teamVoteEnabled.present) {
      map['team_vote_enabled'] = Variable<bool>(teamVoteEnabled.value);
    }
    if (voicePackId.present) {
      map['voice_pack_id'] = Variable<String>(voicePackId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('narrationLanguage: $narrationLanguage, ')
          ..write('narrationSpeed: $narrationSpeed, ')
          ..write('narrationPitch: $narrationPitch, ')
          ..write('volume: $volume, ')
          ..write('voiceId: $voiceId, ')
          ..write('ambientAudioEnabled: $ambientAudioEnabled, ')
          ..write('autoAdvance: $autoAdvance, ')
          ..write('keepScreenAwake: $keepScreenAwake, ')
          ..write('confirmations: $confirmations, ')
          ..write('haptics: $haptics, ')
          ..write('soundEffects: $soundEffects, ')
          ..write('discussionSeconds: $discussionSeconds, ')
          ..write('defaultPlayerCount: $defaultPlayerCount, ')
          ..write('mcPinEnabled: $mcPinEnabled, ')
          ..write('mcPinHash: $mcPinHash, ')
          ..write('kingSelection: $kingSelection, ')
          ..write('narratorExtraDelayMs: $narratorExtraDelayMs, ')
          ..write('teamVoteEnabled: $teamVoteEnabled, ')
          ..write('voicePackId: $voicePackId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoicePacksTable extends VoicePacks
    with TableInfo<$VoicePacksTable, VoicePackRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoicePacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clipsMeta = const VerificationMeta('clips');
  @override
  late final GeneratedColumn<String> clips = GeneratedColumn<String>(
    'clips',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rootMeta = const VerificationMeta('root');
  @override
  late final GeneratedColumn<String> root = GeneratedColumn<String>(
    'root',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    clips,
    builtIn,
    hidden,
    root,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoicePackRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('clips')) {
      context.handle(
        _clipsMeta,
        clips.isAcceptableOrUnknown(data['clips']!, _clipsMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('root')) {
      context.handle(
        _rootMeta,
        root.isAcceptableOrUnknown(data['root']!, _rootMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoicePackRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoicePackRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      clips: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clips'],
      )!,
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      root: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VoicePacksTable createAlias(String alias) {
    return $VoicePacksTable(attachedDatabase, alias);
  }
}

class VoicePackRecord extends DataClass implements Insertable<VoicePackRecord> {
  final String id;

  /// Display name. The folder stays [id] whatever this says.
  final String name;

  /// Recorded line ids per language folder, as JSON: `{"en":[…],"fil":[…]}`.
  final String clips;

  /// True for the recordings inside the APK: they can be hidden, not deleted.
  final bool builtIn;

  /// Hidden voices stay playable for a match in progress but leave the list.
  final bool hidden;

  /// Asset folder for a bundled voice, absolute directory for an imported one.
  final String root;

  /// UTC milliseconds since epoch; orders imported voices in the list.
  final int createdAt;
  const VoicePackRecord({
    required this.id,
    required this.name,
    required this.clips,
    required this.builtIn,
    required this.hidden,
    required this.root,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['clips'] = Variable<String>(clips);
    map['built_in'] = Variable<bool>(builtIn);
    map['hidden'] = Variable<bool>(hidden);
    map['root'] = Variable<String>(root);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  VoicePacksCompanion toCompanion(bool nullToAbsent) {
    return VoicePacksCompanion(
      id: Value(id),
      name: Value(name),
      clips: Value(clips),
      builtIn: Value(builtIn),
      hidden: Value(hidden),
      root: Value(root),
      createdAt: Value(createdAt),
    );
  }

  factory VoicePackRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoicePackRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      clips: serializer.fromJson<String>(json['clips']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      root: serializer.fromJson<String>(json['root']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'clips': serializer.toJson<String>(clips),
      'builtIn': serializer.toJson<bool>(builtIn),
      'hidden': serializer.toJson<bool>(hidden),
      'root': serializer.toJson<String>(root),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  VoicePackRecord copyWith({
    String? id,
    String? name,
    String? clips,
    bool? builtIn,
    bool? hidden,
    String? root,
    int? createdAt,
  }) => VoicePackRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    clips: clips ?? this.clips,
    builtIn: builtIn ?? this.builtIn,
    hidden: hidden ?? this.hidden,
    root: root ?? this.root,
    createdAt: createdAt ?? this.createdAt,
  );
  VoicePackRecord copyWithCompanion(VoicePacksCompanion data) {
    return VoicePackRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      clips: data.clips.present ? data.clips.value : this.clips,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      root: data.root.present ? data.root.value : this.root,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoicePackRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('clips: $clips, ')
          ..write('builtIn: $builtIn, ')
          ..write('hidden: $hidden, ')
          ..write('root: $root, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, clips, builtIn, hidden, root, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoicePackRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.clips == this.clips &&
          other.builtIn == this.builtIn &&
          other.hidden == this.hidden &&
          other.root == this.root &&
          other.createdAt == this.createdAt);
}

class VoicePacksCompanion extends UpdateCompanion<VoicePackRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> clips;
  final Value<bool> builtIn;
  final Value<bool> hidden;
  final Value<String> root;
  final Value<int> createdAt;
  final Value<int> rowid;
  const VoicePacksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.clips = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.hidden = const Value.absent(),
    this.root = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoicePacksCompanion.insert({
    required String id,
    required String name,
    this.clips = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.hidden = const Value.absent(),
    this.root = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<VoicePackRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? clips,
    Expression<bool>? builtIn,
    Expression<bool>? hidden,
    Expression<String>? root,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (clips != null) 'clips': clips,
      if (builtIn != null) 'built_in': builtIn,
      if (hidden != null) 'hidden': hidden,
      if (root != null) 'root': root,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoicePacksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? clips,
    Value<bool>? builtIn,
    Value<bool>? hidden,
    Value<String>? root,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return VoicePacksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      clips: clips ?? this.clips,
      builtIn: builtIn ?? this.builtIn,
      hidden: hidden ?? this.hidden,
      root: root ?? this.root,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (clips.present) {
      map['clips'] = Variable<String>(clips.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (root.present) {
      map['root'] = Variable<String>(root.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoicePacksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('clips: $clips, ')
          ..write('builtIn: $builtIn, ')
          ..write('hidden: $hidden, ')
          ..write('root: $root, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GamesTable games = $GamesTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $QuestsTable quests = $QuestsTable(this);
  late final $TeamProposalsTable teamProposals = $TeamProposalsTable(this);
  late final $GameEventsTable gameEvents = $GameEventsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $VoicePacksTable voicePacks = $VoicePacksTable(this);
  late final Index playersGameId = Index(
    'players_game_id',
    'CREATE INDEX players_game_id ON players (game_id)',
  );
  late final Index playersSeat = Index(
    'players_seat',
    'CREATE INDEX players_seat ON players (seat_number)',
  );
  late final Index questsGameId = Index(
    'quests_game_id',
    'CREATE INDEX quests_game_id ON quests (game_id)',
  );
  late final Index questsNumber = Index(
    'quests_number',
    'CREATE INDEX quests_number ON quests (quest_number)',
  );
  late final Index proposalsGameId = Index(
    'proposals_game_id',
    'CREATE INDEX proposals_game_id ON team_proposals (game_id)',
  );
  late final Index proposalsNumber = Index(
    'proposals_number',
    'CREATE INDEX proposals_number ON team_proposals (quest_number)',
  );
  late final Index eventsGameId = Index(
    'events_game_id',
    'CREATE INDEX events_game_id ON game_events (game_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    players,
    quests,
    teamProposals,
    gameEvents,
    settings,
    voicePacks,
    playersGameId,
    playersSeat,
    questsGameId,
    questsNumber,
    proposalsGameId,
    proposalsNumber,
    eventsGameId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('players', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('quests', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('team_proposals', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('game_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$GamesTableCreateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  required int createdAt,
  required int updatedAt,
  required int playerCount,
  required String status,
  Value<String?> winner,
  Value<int?> durationSeconds,
  required String phase,
  Value<String?> pausedFrom,
  required int leaderSeat,
  required int questNumber,
  required int rejectionCount,
  Value<String> currentTeam,
  required String questResults,
  Value<String> questTeams,
  required String composition,
  Value<String?> winReason,
  Value<String?> assassinationOutcome,
});
typedef $$GamesTableUpdateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> playerCount,
  Value<String> status,
  Value<String?> winner,
  Value<int?> durationSeconds,
  Value<String> phase,
  Value<String?> pausedFrom,
  Value<int> leaderSeat,
  Value<int> questNumber,
  Value<int> rejectionCount,
  Value<String> currentTeam,
  Value<String> questResults,
  Value<String> questTeams,
  Value<String> composition,
  Value<String?> winReason,
  Value<String?> assassinationOutcome,
});

final class $$GamesTableReferences
    extends BaseReferences<_$AppDatabase, $GamesTable, GameRecord> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlayersTable, List<PlayerRecord>>
  _playersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.players,
    aliasName: 'games__id__players__game_id',
  );

  $$PlayersTableProcessedTableManager get playersRefs {
    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuestsTable, List<QuestRecord>> _questsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.quests,
    aliasName: 'games__id__quests__game_id',
  );

  $$QuestsTableProcessedTableManager get questsRefs {
    final manager = $$QuestsTableTableManager(
      $_db,
      $_db.quests,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_questsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TeamProposalsTable, List<ProposalRecord>>
  _teamProposalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.teamProposals,
    aliasName: 'games__id__team_proposals__game_id',
  );

  $$TeamProposalsTableProcessedTableManager get teamProposalsRefs {
    final manager = $$TeamProposalsTableTableManager(
      $_db,
      $_db.teamProposals,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_teamProposalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GameEventsTable, List<EventRecord>>
  _gameEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gameEvents,
    aliasName: 'games__id__game_events__game_id',
  );

  $$GameEventsTableProcessedTableManager get gameEventsRefs {
    final manager = $$GameEventsTableTableManager(
      $_db,
      $_db.gameEvents,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gameEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winner => $composableBuilder(
    column: $table.winner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pausedFrom => $composableBuilder(
    column: $table.pausedFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaderSeat => $composableBuilder(
    column: $table.leaderSeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rejectionCount => $composableBuilder(
    column: $table.rejectionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentTeam => $composableBuilder(
    column: $table.currentTeam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questResults => $composableBuilder(
    column: $table.questResults,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questTeams => $composableBuilder(
    column: $table.questTeams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winReason => $composableBuilder(
    column: $table.winReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assassinationOutcome => $composableBuilder(
    column: $table.assassinationOutcome,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playersRefs(
    Expression<bool> Function($$PlayersTableFilterComposer f) f,
  ) {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> questsRefs(
    Expression<bool> Function($$QuestsTableFilterComposer f) f,
  ) {
    final $$QuestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableFilterComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> teamProposalsRefs(
    Expression<bool> Function($$TeamProposalsTableFilterComposer f) f,
  ) {
    final $$TeamProposalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamProposals,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamProposalsTableFilterComposer(
            $db: $db,
            $table: $db.teamProposals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gameEventsRefs(
    Expression<bool> Function($$GameEventsTableFilterComposer f) f,
  ) {
    final $$GameEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameEvents,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameEventsTableFilterComposer(
            $db: $db,
            $table: $db.gameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winner => $composableBuilder(
    column: $table.winner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pausedFrom => $composableBuilder(
    column: $table.pausedFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaderSeat => $composableBuilder(
    column: $table.leaderSeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rejectionCount => $composableBuilder(
    column: $table.rejectionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentTeam => $composableBuilder(
    column: $table.currentTeam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questResults => $composableBuilder(
    column: $table.questResults,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questTeams => $composableBuilder(
    column: $table.questTeams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winReason => $composableBuilder(
    column: $table.winReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assassinationOutcome => $composableBuilder(
    column: $table.assassinationOutcome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get winner =>
      $composableBuilder(column: $table.winner, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get pausedFrom => $composableBuilder(
    column: $table.pausedFrom,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leaderSeat => $composableBuilder(
    column: $table.leaderSeat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rejectionCount => $composableBuilder(
    column: $table.rejectionCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentTeam => $composableBuilder(
    column: $table.currentTeam,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questResults => $composableBuilder(
    column: $table.questResults,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questTeams => $composableBuilder(
    column: $table.questTeams,
    builder: (column) => column,
  );

  GeneratedColumn<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get winReason =>
      $composableBuilder(column: $table.winReason, builder: (column) => column);

  GeneratedColumn<String> get assassinationOutcome => $composableBuilder(
    column: $table.assassinationOutcome,
    builder: (column) => column,
  );

  Expression<T> playersRefs<T extends Object>(
    Expression<T> Function($$PlayersTableAnnotationComposer a) f,
  ) {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> questsRefs<T extends Object>(
    Expression<T> Function($$QuestsTableAnnotationComposer a) f,
  ) {
    final $$QuestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quests,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestsTableAnnotationComposer(
            $db: $db,
            $table: $db.quests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> teamProposalsRefs<T extends Object>(
    Expression<T> Function($$TeamProposalsTableAnnotationComposer a) f,
  ) {
    final $$TeamProposalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamProposals,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamProposalsTableAnnotationComposer(
            $db: $db,
            $table: $db.teamProposals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gameEventsRefs<T extends Object>(
    Expression<T> Function($$GameEventsTableAnnotationComposer a) f,
  ) {
    final $$GameEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameEvents,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.gameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          GameRecord,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (GameRecord, $$GamesTableReferences),
          GameRecord,
          PrefetchHooks Function({
            bool playersRefs,
            bool questsRefs,
            bool teamProposalsRefs,
            bool gameEventsRefs,
          })
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> playerCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> winner = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<String?> pausedFrom = const Value.absent(),
                Value<int> leaderSeat = const Value.absent(),
                Value<int> questNumber = const Value.absent(),
                Value<int> rejectionCount = const Value.absent(),
                Value<String> currentTeam = const Value.absent(),
                Value<String> questResults = const Value.absent(),
                Value<String> questTeams = const Value.absent(),
                Value<String> composition = const Value.absent(),
                Value<String?> winReason = const Value.absent(),
                Value<String?> assassinationOutcome = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                playerCount: playerCount,
                status: status,
                winner: winner,
                durationSeconds: durationSeconds,
                phase: phase,
                pausedFrom: pausedFrom,
                leaderSeat: leaderSeat,
                questNumber: questNumber,
                rejectionCount: rejectionCount,
                currentTeam: currentTeam,
                questResults: questResults,
                questTeams: questTeams,
                composition: composition,
                winReason: winReason,
                assassinationOutcome: assassinationOutcome,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required int playerCount,
                required String status,
                Value<String?> winner = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                required String phase,
                Value<String?> pausedFrom = const Value.absent(),
                required int leaderSeat,
                required int questNumber,
                required int rejectionCount,
                Value<String> currentTeam = const Value.absent(),
                required String questResults,
                Value<String> questTeams = const Value.absent(),
                required String composition,
                Value<String?> winReason = const Value.absent(),
                Value<String?> assassinationOutcome = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                playerCount: playerCount,
                status: status,
                winner: winner,
                durationSeconds: durationSeconds,
                phase: phase,
                pausedFrom: pausedFrom,
                leaderSeat: leaderSeat,
                questNumber: questNumber,
                rejectionCount: rejectionCount,
                currentTeam: currentTeam,
                questResults: questResults,
                questTeams: questTeams,
                composition: composition,
                winReason: winReason,
                assassinationOutcome: assassinationOutcome,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GamesTable, GameRecord>(table),
                  $$GamesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                playersRefs = false,
                questsRefs = false,
                teamProposalsRefs = false,
                gameEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playersRefs) db.players,
                    if (questsRefs) db.quests,
                    if (teamProposalsRefs) db.teamProposals,
                    if (gameEventsRefs) db.gameEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playersRefs)
                        await $_getPrefetchedDataByColumns<
                          GameRecord,
                          $GamesTable,
                          PlayerRecord,
                          $PlayersTable
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._playersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(db, table, p0).playersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'game_id',
                          typedResults: items,
                        ),
                      if (questsRefs)
                        await $_getPrefetchedDataByColumns<
                          GameRecord,
                          $GamesTable,
                          QuestRecord,
                          $QuestsTable
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._questsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(db, table, p0).questsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'game_id',
                          typedResults: items,
                        ),
                      if (teamProposalsRefs)
                        await $_getPrefetchedDataByColumns<
                          GameRecord,
                          $GamesTable,
                          ProposalRecord,
                          $TeamProposalsTable
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._teamProposalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).teamProposalsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'game_id',
                          typedResults: items,
                        ),
                      if (gameEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          GameRecord,
                          $GamesTable,
                          EventRecord,
                          $GameEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._gameEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).gameEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'game_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      GameRecord,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (GameRecord, $$GamesTableReferences),
      GameRecord,
      PrefetchHooks Function({
        bool playersRefs,
        bool questsRefs,
        bool teamProposalsRefs,
        bool gameEventsRefs,
      })
    >;
typedef $$PlayersTableCreateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  required int gameId,
  required String displayName,
  required int seatNumber,
});
typedef $$PlayersTableUpdateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  Value<int> gameId,
  Value<String> displayName,
  Value<int> seatNumber,
});

final class $$PlayersTableReferences
    extends BaseReferences<_$AppDatabase, $PlayersTable, PlayerRecord> {
  $$PlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('players__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seatNumber => $composableBuilder(
    column: $table.seatNumber,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seatNumber => $composableBuilder(
    column: $table.seatNumber,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seatNumber => $composableBuilder(
    column: $table.seatNumber,
    builder: (column) => column,
  );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          PlayerRecord,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (PlayerRecord, $$PlayersTableReferences),
          PlayerRecord,
          PrefetchHooks Function({bool gameId})
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> seatNumber = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                gameId: gameId,
                displayName: displayName,
                seatNumber: seatNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required String displayName,
                required int seatNumber,
              }) => PlayersCompanion.insert(
                id: id,
                gameId: gameId,
                displayName: displayName,
                seatNumber: seatNumber,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayersTable, PlayerRecord>(table),
                  $$PlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$PlayersTableReferences._gameIdTable(
                          db,
                        ),
                        referencedColumn: $$PlayersTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      PlayerRecord,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (PlayerRecord, $$PlayersTableReferences),
      PlayerRecord,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$QuestsTableCreateCompanionBuilder = QuestsCompanion Function({
  Value<int> id,
  required int gameId,
  required int questNumber,
  required int requiredPlayers,
  required int successCount,
  required int failCount,
  required String result,
});
typedef $$QuestsTableUpdateCompanionBuilder = QuestsCompanion Function({
  Value<int> id,
  Value<int> gameId,
  Value<int> questNumber,
  Value<int> requiredPlayers,
  Value<int> successCount,
  Value<int> failCount,
  Value<String> result,
});

final class $$QuestsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestsTable, QuestRecord> {
  $$QuestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('quests__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredPlayers => $composableBuilder(
    column: $table.requiredPlayers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get successCount => $composableBuilder(
    column: $table.successCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failCount => $composableBuilder(
    column: $table.failCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredPlayers => $composableBuilder(
    column: $table.requiredPlayers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get successCount => $composableBuilder(
    column: $table.successCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failCount => $composableBuilder(
    column: $table.failCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestsTable> {
  $$QuestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requiredPlayers => $composableBuilder(
    column: $table.requiredPlayers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get successCount => $composableBuilder(
    column: $table.successCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failCount =>
      $composableBuilder(column: $table.failCount, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestsTable,
          QuestRecord,
          $$QuestsTableFilterComposer,
          $$QuestsTableOrderingComposer,
          $$QuestsTableAnnotationComposer,
          $$QuestsTableCreateCompanionBuilder,
          $$QuestsTableUpdateCompanionBuilder,
          (QuestRecord, $$QuestsTableReferences),
          QuestRecord,
          PrefetchHooks Function({bool gameId})
        > {
  $$QuestsTableTableManager(_$AppDatabase db, $QuestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> questNumber = const Value.absent(),
                Value<int> requiredPlayers = const Value.absent(),
                Value<int> successCount = const Value.absent(),
                Value<int> failCount = const Value.absent(),
                Value<String> result = const Value.absent(),
              }) => QuestsCompanion(
                id: id,
                gameId: gameId,
                questNumber: questNumber,
                requiredPlayers: requiredPlayers,
                successCount: successCount,
                failCount: failCount,
                result: result,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int questNumber,
                required int requiredPlayers,
                required int successCount,
                required int failCount,
                required String result,
              }) => QuestsCompanion.insert(
                id: id,
                gameId: gameId,
                questNumber: questNumber,
                requiredPlayers: requiredPlayers,
                successCount: successCount,
                failCount: failCount,
                result: result,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestsTable, QuestRecord>(table),
                  $$QuestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$QuestsTableReferences._gameIdTable(
                          db,
                        ),
                        referencedColumn: $$QuestsTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestsTable,
      QuestRecord,
      $$QuestsTableFilterComposer,
      $$QuestsTableOrderingComposer,
      $$QuestsTableAnnotationComposer,
      $$QuestsTableCreateCompanionBuilder,
      $$QuestsTableUpdateCompanionBuilder,
      (QuestRecord, $$QuestsTableReferences),
      QuestRecord,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$TeamProposalsTableCreateCompanionBuilder =
    TeamProposalsCompanion Function({
      Value<int> id,
      required int gameId,
      required int questNumber,
      required int leaderSeat,
      required String selectedSeats,
      required int approveCount,
      required int rejectCount,
      required String result,
    });
typedef $$TeamProposalsTableUpdateCompanionBuilder =
    TeamProposalsCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> questNumber,
      Value<int> leaderSeat,
      Value<String> selectedSeats,
      Value<int> approveCount,
      Value<int> rejectCount,
      Value<String> result,
    });

final class $$TeamProposalsTableReferences
    extends BaseReferences<_$AppDatabase, $TeamProposalsTable, ProposalRecord> {
  $$TeamProposalsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('team_proposals__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TeamProposalsTableFilterComposer
    extends Composer<_$AppDatabase, $TeamProposalsTable> {
  $$TeamProposalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaderSeat => $composableBuilder(
    column: $table.leaderSeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedSeats => $composableBuilder(
    column: $table.selectedSeats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get approveCount => $composableBuilder(
    column: $table.approveCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rejectCount => $composableBuilder(
    column: $table.rejectCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamProposalsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamProposalsTable> {
  $$TeamProposalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaderSeat => $composableBuilder(
    column: $table.leaderSeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedSeats => $composableBuilder(
    column: $table.selectedSeats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get approveCount => $composableBuilder(
    column: $table.approveCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rejectCount => $composableBuilder(
    column: $table.rejectCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamProposalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamProposalsTable> {
  $$TeamProposalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get questNumber => $composableBuilder(
    column: $table.questNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leaderSeat => $composableBuilder(
    column: $table.leaderSeat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedSeats => $composableBuilder(
    column: $table.selectedSeats,
    builder: (column) => column,
  );

  GeneratedColumn<int> get approveCount => $composableBuilder(
    column: $table.approveCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rejectCount => $composableBuilder(
    column: $table.rejectCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamProposalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamProposalsTable,
          ProposalRecord,
          $$TeamProposalsTableFilterComposer,
          $$TeamProposalsTableOrderingComposer,
          $$TeamProposalsTableAnnotationComposer,
          $$TeamProposalsTableCreateCompanionBuilder,
          $$TeamProposalsTableUpdateCompanionBuilder,
          (ProposalRecord, $$TeamProposalsTableReferences),
          ProposalRecord,
          PrefetchHooks Function({bool gameId})
        > {
  $$TeamProposalsTableTableManager(_$AppDatabase db, $TeamProposalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamProposalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamProposalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamProposalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> questNumber = const Value.absent(),
                Value<int> leaderSeat = const Value.absent(),
                Value<String> selectedSeats = const Value.absent(),
                Value<int> approveCount = const Value.absent(),
                Value<int> rejectCount = const Value.absent(),
                Value<String> result = const Value.absent(),
              }) => TeamProposalsCompanion(
                id: id,
                gameId: gameId,
                questNumber: questNumber,
                leaderSeat: leaderSeat,
                selectedSeats: selectedSeats,
                approveCount: approveCount,
                rejectCount: rejectCount,
                result: result,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int questNumber,
                required int leaderSeat,
                required String selectedSeats,
                required int approveCount,
                required int rejectCount,
                required String result,
              }) => TeamProposalsCompanion.insert(
                id: id,
                gameId: gameId,
                questNumber: questNumber,
                leaderSeat: leaderSeat,
                selectedSeats: selectedSeats,
                approveCount: approveCount,
                rejectCount: rejectCount,
                result: result,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeamProposalsTable, ProposalRecord>(table),
                  $$TeamProposalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$TeamProposalsTableReferences
                            ._gameIdTable(db),
                        referencedColumn: $$TeamProposalsTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TeamProposalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamProposalsTable,
      ProposalRecord,
      $$TeamProposalsTableFilterComposer,
      $$TeamProposalsTableOrderingComposer,
      $$TeamProposalsTableAnnotationComposer,
      $$TeamProposalsTableCreateCompanionBuilder,
      $$TeamProposalsTableUpdateCompanionBuilder,
      (ProposalRecord, $$TeamProposalsTableReferences),
      ProposalRecord,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$GameEventsTableCreateCompanionBuilder = GameEventsCompanion Function({
  Value<int> id,
  required int gameId,
  required String eventType,
  required String eventDescription,
  required int createdAt,
});
typedef $$GameEventsTableUpdateCompanionBuilder = GameEventsCompanion Function({
  Value<int> id,
  Value<int> gameId,
  Value<String> eventType,
  Value<String> eventDescription,
  Value<int> createdAt,
});

final class $$GameEventsTableReferences
    extends BaseReferences<_$AppDatabase, $GameEventsTable, EventRecord> {
  $$GameEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('game_events__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GameEventsTableFilterComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventDescription => $composableBuilder(
    column: $table.eventDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventDescription => $composableBuilder(
    column: $table.eventDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get eventDescription => $composableBuilder(
    column: $table.eventDescription,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameEventsTable,
          EventRecord,
          $$GameEventsTableFilterComposer,
          $$GameEventsTableOrderingComposer,
          $$GameEventsTableAnnotationComposer,
          $$GameEventsTableCreateCompanionBuilder,
          $$GameEventsTableUpdateCompanionBuilder,
          (EventRecord, $$GameEventsTableReferences),
          EventRecord,
          PrefetchHooks Function({bool gameId})
        > {
  $$GameEventsTableTableManager(_$AppDatabase db, $GameEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> eventDescription = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => GameEventsCompanion(
                id: id,
                gameId: gameId,
                eventType: eventType,
                eventDescription: eventDescription,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required String eventType,
                required String eventDescription,
                required int createdAt,
              }) => GameEventsCompanion.insert(
                id: id,
                gameId: gameId,
                eventType: eventType,
                eventDescription: eventDescription,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GameEventsTable, EventRecord>(table),
                  $$GameEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$GameEventsTableReferences
                            ._gameIdTable(db),
                        referencedColumn: $$GameEventsTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GameEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameEventsTable,
      EventRecord,
      $$GameEventsTableFilterComposer,
      $$GameEventsTableOrderingComposer,
      $$GameEventsTableAnnotationComposer,
      $$GameEventsTableCreateCompanionBuilder,
      $$GameEventsTableUpdateCompanionBuilder,
      (EventRecord, $$GameEventsTableReferences),
      EventRecord,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required int id,
  Value<String> narrationLanguage,
  Value<double> narrationSpeed,
  Value<double> narrationPitch,
  Value<double> volume,
  Value<String?> voiceId,
  Value<bool> ambientAudioEnabled,
  Value<bool> autoAdvance,
  Value<bool> keepScreenAwake,
  Value<bool> confirmations,
  Value<bool> haptics,
  Value<bool> soundEffects,
  Value<int> discussionSeconds,
  Value<int> defaultPlayerCount,
  Value<bool> mcPinEnabled,
  Value<String?> mcPinHash,
  Value<String> kingSelection,
  Value<int> narratorExtraDelayMs,
  Value<bool> teamVoteEnabled,
  Value<String?> voicePackId,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String> narrationLanguage,
  Value<double> narrationSpeed,
  Value<double> narrationPitch,
  Value<double> volume,
  Value<String?> voiceId,
  Value<bool> ambientAudioEnabled,
  Value<bool> autoAdvance,
  Value<bool> keepScreenAwake,
  Value<bool> confirmations,
  Value<bool> haptics,
  Value<bool> soundEffects,
  Value<int> discussionSeconds,
  Value<int> defaultPlayerCount,
  Value<bool> mcPinEnabled,
  Value<String?> mcPinHash,
  Value<String> kingSelection,
  Value<int> narratorExtraDelayMs,
  Value<bool> teamVoteEnabled,
  Value<String?> voicePackId,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narrationLanguage => $composableBuilder(
    column: $table.narrationLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get narrationSpeed => $composableBuilder(
    column: $table.narrationSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get narrationPitch => $composableBuilder(
    column: $table.narrationPitch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ambientAudioEnabled => $composableBuilder(
    column: $table.ambientAudioEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoAdvance => $composableBuilder(
    column: $table.autoAdvance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get keepScreenAwake => $composableBuilder(
    column: $table.keepScreenAwake,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmations => $composableBuilder(
    column: $table.confirmations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get haptics => $composableBuilder(
    column: $table.haptics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soundEffects => $composableBuilder(
    column: $table.soundEffects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discussionSeconds => $composableBuilder(
    column: $table.discussionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultPlayerCount => $composableBuilder(
    column: $table.defaultPlayerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mcPinEnabled => $composableBuilder(
    column: $table.mcPinEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mcPinHash => $composableBuilder(
    column: $table.mcPinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kingSelection => $composableBuilder(
    column: $table.kingSelection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get narratorExtraDelayMs => $composableBuilder(
    column: $table.narratorExtraDelayMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get teamVoteEnabled => $composableBuilder(
    column: $table.teamVoteEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voicePackId => $composableBuilder(
    column: $table.voicePackId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narrationLanguage => $composableBuilder(
    column: $table.narrationLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get narrationSpeed => $composableBuilder(
    column: $table.narrationSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get narrationPitch => $composableBuilder(
    column: $table.narrationPitch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ambientAudioEnabled => $composableBuilder(
    column: $table.ambientAudioEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoAdvance => $composableBuilder(
    column: $table.autoAdvance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get keepScreenAwake => $composableBuilder(
    column: $table.keepScreenAwake,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmations => $composableBuilder(
    column: $table.confirmations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get haptics => $composableBuilder(
    column: $table.haptics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soundEffects => $composableBuilder(
    column: $table.soundEffects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discussionSeconds => $composableBuilder(
    column: $table.discussionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultPlayerCount => $composableBuilder(
    column: $table.defaultPlayerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mcPinEnabled => $composableBuilder(
    column: $table.mcPinEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mcPinHash => $composableBuilder(
    column: $table.mcPinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kingSelection => $composableBuilder(
    column: $table.kingSelection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get narratorExtraDelayMs => $composableBuilder(
    column: $table.narratorExtraDelayMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get teamVoteEnabled => $composableBuilder(
    column: $table.teamVoteEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voicePackId => $composableBuilder(
    column: $table.voicePackId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get narrationLanguage => $composableBuilder(
    column: $table.narrationLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get narrationSpeed => $composableBuilder(
    column: $table.narrationSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get narrationPitch => $composableBuilder(
    column: $table.narrationPitch,
    builder: (column) => column,
  );

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);

  GeneratedColumn<bool> get ambientAudioEnabled => $composableBuilder(
    column: $table.ambientAudioEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoAdvance => $composableBuilder(
    column: $table.autoAdvance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get keepScreenAwake => $composableBuilder(
    column: $table.keepScreenAwake,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmations => $composableBuilder(
    column: $table.confirmations,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get haptics =>
      $composableBuilder(column: $table.haptics, builder: (column) => column);

  GeneratedColumn<bool> get soundEffects => $composableBuilder(
    column: $table.soundEffects,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discussionSeconds => $composableBuilder(
    column: $table.discussionSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultPlayerCount => $composableBuilder(
    column: $table.defaultPlayerCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mcPinEnabled => $composableBuilder(
    column: $table.mcPinEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mcPinHash =>
      $composableBuilder(column: $table.mcPinHash, builder: (column) => column);

  GeneratedColumn<String> get kingSelection => $composableBuilder(
    column: $table.kingSelection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get narratorExtraDelayMs => $composableBuilder(
    column: $table.narratorExtraDelayMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get teamVoteEnabled => $composableBuilder(
    column: $table.teamVoteEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voicePackId => $composableBuilder(
    column: $table.voicePackId,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingsRecord,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingsRecord,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingsRecord>,
          ),
          SettingsRecord,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> narrationLanguage = const Value.absent(),
                Value<double> narrationSpeed = const Value.absent(),
                Value<double> narrationPitch = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<String?> voiceId = const Value.absent(),
                Value<bool> ambientAudioEnabled = const Value.absent(),
                Value<bool> autoAdvance = const Value.absent(),
                Value<bool> keepScreenAwake = const Value.absent(),
                Value<bool> confirmations = const Value.absent(),
                Value<bool> haptics = const Value.absent(),
                Value<bool> soundEffects = const Value.absent(),
                Value<int> discussionSeconds = const Value.absent(),
                Value<int> defaultPlayerCount = const Value.absent(),
                Value<bool> mcPinEnabled = const Value.absent(),
                Value<String?> mcPinHash = const Value.absent(),
                Value<String> kingSelection = const Value.absent(),
                Value<int> narratorExtraDelayMs = const Value.absent(),
                Value<bool> teamVoteEnabled = const Value.absent(),
                Value<String?> voicePackId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                narrationLanguage: narrationLanguage,
                narrationSpeed: narrationSpeed,
                narrationPitch: narrationPitch,
                volume: volume,
                voiceId: voiceId,
                ambientAudioEnabled: ambientAudioEnabled,
                autoAdvance: autoAdvance,
                keepScreenAwake: keepScreenAwake,
                confirmations: confirmations,
                haptics: haptics,
                soundEffects: soundEffects,
                discussionSeconds: discussionSeconds,
                defaultPlayerCount: defaultPlayerCount,
                mcPinEnabled: mcPinEnabled,
                mcPinHash: mcPinHash,
                kingSelection: kingSelection,
                narratorExtraDelayMs: narratorExtraDelayMs,
                teamVoteEnabled: teamVoteEnabled,
                voicePackId: voicePackId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                Value<String> narrationLanguage = const Value.absent(),
                Value<double> narrationSpeed = const Value.absent(),
                Value<double> narrationPitch = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<String?> voiceId = const Value.absent(),
                Value<bool> ambientAudioEnabled = const Value.absent(),
                Value<bool> autoAdvance = const Value.absent(),
                Value<bool> keepScreenAwake = const Value.absent(),
                Value<bool> confirmations = const Value.absent(),
                Value<bool> haptics = const Value.absent(),
                Value<bool> soundEffects = const Value.absent(),
                Value<int> discussionSeconds = const Value.absent(),
                Value<int> defaultPlayerCount = const Value.absent(),
                Value<bool> mcPinEnabled = const Value.absent(),
                Value<String?> mcPinHash = const Value.absent(),
                Value<String> kingSelection = const Value.absent(),
                Value<int> narratorExtraDelayMs = const Value.absent(),
                Value<bool> teamVoteEnabled = const Value.absent(),
                Value<String?> voicePackId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                narrationLanguage: narrationLanguage,
                narrationSpeed: narrationSpeed,
                narrationPitch: narrationPitch,
                volume: volume,
                voiceId: voiceId,
                ambientAudioEnabled: ambientAudioEnabled,
                autoAdvance: autoAdvance,
                keepScreenAwake: keepScreenAwake,
                confirmations: confirmations,
                haptics: haptics,
                soundEffects: soundEffects,
                discussionSeconds: discussionSeconds,
                defaultPlayerCount: defaultPlayerCount,
                mcPinEnabled: mcPinEnabled,
                mcPinHash: mcPinHash,
                kingSelection: kingSelection,
                narratorExtraDelayMs: narratorExtraDelayMs,
                teamVoteEnabled: teamVoteEnabled,
                voicePackId: voicePackId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingsRecord>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingsRecord>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingsRecord,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        SettingsRecord,
        BaseReferences<_$AppDatabase, $SettingsTable, SettingsRecord>,
      ),
      SettingsRecord,
      PrefetchHooks Function()
    >;
typedef $$VoicePacksTableCreateCompanionBuilder = VoicePacksCompanion Function({
  required String id,
  required String name,
  Value<String> clips,
  Value<bool> builtIn,
  Value<bool> hidden,
  Value<String> root,
  Value<int> createdAt,
  Value<int> rowid,
});
typedef $$VoicePacksTableUpdateCompanionBuilder = VoicePacksCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> clips,
  Value<bool> builtIn,
  Value<bool> hidden,
  Value<String> root,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$VoicePacksTableFilterComposer
    extends Composer<_$AppDatabase, $VoicePacksTable> {
  $$VoicePacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clips => $composableBuilder(
    column: $table.clips,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoicePacksTableOrderingComposer
    extends Composer<_$AppDatabase, $VoicePacksTable> {
  $$VoicePacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clips => $composableBuilder(
    column: $table.clips,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoicePacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoicePacksTable> {
  $$VoicePacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get clips =>
      $composableBuilder(column: $table.clips, builder: (column) => column);

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get root =>
      $composableBuilder(column: $table.root, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VoicePacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoicePacksTable,
          VoicePackRecord,
          $$VoicePacksTableFilterComposer,
          $$VoicePacksTableOrderingComposer,
          $$VoicePacksTableAnnotationComposer,
          $$VoicePacksTableCreateCompanionBuilder,
          $$VoicePacksTableUpdateCompanionBuilder,
          (
            VoicePackRecord,
            BaseReferences<_$AppDatabase, $VoicePacksTable, VoicePackRecord>,
          ),
          VoicePackRecord,
          PrefetchHooks Function()
        > {
  $$VoicePacksTableTableManager(_$AppDatabase db, $VoicePacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoicePacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoicePacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoicePacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> clips = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> root = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoicePacksCompanion(
                id: id,
                name: name,
                clips: clips,
                builtIn: builtIn,
                hidden: hidden,
                root: root,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> clips = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> root = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoicePacksCompanion.insert(
                id: id,
                name: name,
                clips: clips,
                builtIn: builtIn,
                hidden: hidden,
                root: root,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VoicePacksTable, VoicePackRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $VoicePacksTable,
                    VoicePackRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoicePacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoicePacksTable,
      VoicePackRecord,
      $$VoicePacksTableFilterComposer,
      $$VoicePacksTableOrderingComposer,
      $$VoicePacksTableAnnotationComposer,
      $$VoicePacksTableCreateCompanionBuilder,
      $$VoicePacksTableUpdateCompanionBuilder,
      (
        VoicePackRecord,
        BaseReferences<_$AppDatabase, $VoicePacksTable, VoicePackRecord>,
      ),
      VoicePackRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$QuestsTableTableManager get quests =>
      $$QuestsTableTableManager(_db, _db.quests);
  $$TeamProposalsTableTableManager get teamProposals =>
      $$TeamProposalsTableTableManager(_db, _db.teamProposals);
  $$GameEventsTableTableManager get gameEvents =>
      $$GameEventsTableTableManager(_db, _db.gameEvents);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$VoicePacksTableTableManager get voicePacks =>
      $$VoicePacksTableTableManager(_db, _db.voicePacks);
}
