import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/championship_repository.dart';
import '../../models/championship_models.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_chip.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ChampionshipRepository>();
    final pages = [
      const _OverviewTab(),
      const _OperationsTab(),
      const _StatsTab(),
      const _SettingsTab(),
    ];

    if (repo.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final currentPage = Padding(
          padding: const EdgeInsets.all(20),
          child: pages[_currentIndex],
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('AnotaAI MVP'),
          ),
          body: SafeArea(
            child: isCompact
                ? currentPage
                : Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (value) => setState(() => _currentIndex = value),
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Resumo')),
                          NavigationRailDestination(icon: Icon(Icons.sports_soccer_outlined), label: Text('Operação')),
                          NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), label: Text('Estatísticas')),
                          NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Ajustes')),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: currentPage),
                    ],
                  ),
          ),
          bottomNavigationBar: isCompact
              ? NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (value) => setState(() => _currentIndex = value),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Resumo'),
                    NavigationDestination(icon: Icon(Icons.sports_soccer_outlined), label: 'Operação'),
                    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
                    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ChampionshipRepository>();
    final championship = repo.selectedChampionship;
    if (championship == null) {
      return const Center(child: Text('Crie um campeonato para começar.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;
        final summaryCard = SectionCard(
          title: championship.name,
          action: FilledButton.icon(
            onPressed: () => _showCreateChampionshipDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Novo campeonato'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(championship.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(championship.description),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  StatChip(label: 'Formato', value: _formatLabel(championship.format)),
                  StatChip(label: 'Privacidade', value: championship.privacy),
                  StatChip(label: 'Tema', value: championship.theme),
                  StatChip(label: 'Patrocínio', value: championship.sponsor),
                ],
              ),
            ],
          ),
        );

        final nextMatchesCard = SectionCard(
          title: 'Próximas partidas',
          child: Column(
            children: repo.nextMatches
                .map(
                  (match) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(repo.findTeam(match.homeTeamId).logo)),
                    title: Text('${repo.findTeam(match.homeTeamId).name} x ${repo.findTeam(match.awayTeamId).name}'),
                    subtitle: Text(DateFormat('dd/MM HH:mm').format(match.scheduledAt)),
                    trailing: Chip(label: Text(_matchStatus(match.status))),
                  ),
                )
                .toList(),
          ),
        );

        final standingsCard = SectionCard(
          title: 'Classificação ao vivo',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Equipe')),
                DataColumn(label: Text('P')),
                DataColumn(label: Text('SG')),
                DataColumn(label: Text('Pts')),
              ],
              rows: repo.standings
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(Text(row.team.name)),
                        DataCell(Text('${row.played}')),
                        DataCell(Text('${row.goalDifference}')),
                        DataCell(Text('${row.points}')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );

        return ListView(
          children: [
            summaryCard,
            const SizedBox(height: 20),
            if (compact) ...[
              nextMatchesCard,
              const SizedBox(height: 20),
              standingsCard,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nextMatchesCard),
                  const SizedBox(width: 20),
                  Expanded(child: standingsCard),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _OperationsTab extends StatelessWidget {
  const _OperationsTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ChampionshipRepository>();
    final stages = repo.championshipStages;

    return ListView(
      children: [
        SectionCard(
          title: 'Equipes e jogadores',
          action: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddTeamDialog(context),
                icon: const Icon(Icons.groups),
                label: const Text('Adicionar equipe'),
              ),
              FilledButton.icon(
                onPressed: repo.championshipTeams.isEmpty ? null : () => _showAddPlayerDialog(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Adicionar jogador'),
              ),
            ],
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 700;
                  final filter = DropdownButton<TeamStatus?>(
                    value: repo.teamStatusFilter,
                    hint: const Text('Status da equipe'),
                    items: const [
                      DropdownMenuItem<TeamStatus?>(value: null, child: Text('Todas')),
                      DropdownMenuItem<TeamStatus?>(value: TeamStatus.active, child: Text('Ativa')),
                      DropdownMenuItem<TeamStatus?>(value: TeamStatus.suspended, child: Text('Suspensa')),
                      DropdownMenuItem<TeamStatus?>(value: TeamStatus.disqualified, child: Text('Desclassificada')),
                    ],
                    onChanged: repo.updateTeamStatusFilter,
                  );

                  final search = TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar jogador',
                    ),
                    onChanged: repo.updatePlayerSearch,
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [search, const SizedBox(height: 12), filter],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      filter,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: repo.championshipTeams
                    .map(
                      (team) => SizedBox(
                        width: 320,
                        child: Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(child: Text(team.logo)),
                                  title: Text(team.name),
                                  subtitle: Text('${team.groupName} • ${_teamStatusLabel(team.status)}'),
                                  trailing: TextButton(
                                    onPressed: () => _showCsvImportDialog(context, team.id),
                                    child: const Text('Importar CSV'),
                                  ),
                                ),
                                const Divider(),
                                ...repo.championshipPlayers
                                    .where((player) => player.teamId == team.id)
                                    .map(
                                      (player) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(player.name),
                                        subtitle: Text(player.position),
                                        trailing: Text('${player.goals} G / ${player.assists} A'),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Fases, grupos, rodadas e partidas',
          action: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddStageDialog(context),
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('Nova fase'),
              ),
              FilledButton.icon(
                onPressed: stages.isEmpty ? null : () => _showAddRoundDialog(context, stages.first.id),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Nova rodada'),
              ),
            ],
          ),
          child: Column(
            children: stages
                .map(
                  (stage) => ExpansionTile(
                    title: Text('${stage.name} • ${stage.type}'),
                    subtitle: Text('Caminho de classificação configurável'),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => repo.generateSequentialRound(stage.id),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Gerar rodada sequencial'),
                        ),
                      ),
                      ...repo.roundsForStage(stage.id).map(
                        (round) => ListTile(
                          title: Text(round.name),
                          subtitle: Wrap(
                            spacing: 8,
                            children: repo
                                .matchesForRound(round.id)
                                .map(
                                  (match) => ActionChip(
                                    label: Text(
                                      '${repo.findTeam(match.homeTeamId).name} ${match.homeScore} x ${match.awayScore} ${repo.findTeam(match.awayTeamId).name}',
                                    ),
                                    onPressed: () => _showResultDialog(context, match),
                                  ),
                                )
                                .toList(),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _showAddMatchDialog(context, round.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ChampionshipRepository>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1000;
        final rankingCard = SectionCard(
          title: 'Ranking de equipes',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Equipe')),
                DataColumn(label: Text('V')),
                DataColumn(label: Text('E')),
                DataColumn(label: Text('D')),
                DataColumn(label: Text('GM')),
                DataColumn(label: Text('GS')),
                DataColumn(label: Text('Pts')),
              ],
              rows: repo.standings
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(Text(row.team.name)),
                        DataCell(Text('${row.wins}')),
                        DataCell(Text('${row.draws}')),
                        DataCell(Text('${row.losses}')),
                        DataCell(Text('${row.goalsFor}')),
                        DataCell(Text('${row.goalsAgainst}')),
                        DataCell(Text('${row.points}')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );

        final scorersCard = SectionCard(
          title: 'Artilharia',
          child: Column(
            children: repo.topScorers
                .map(
                  (player) => ListTile(
                    title: Text(player.name),
                    subtitle: Text(repo.findTeam(player.teamId).name),
                    trailing: Text('${player.goals} gols'),
                  ),
                )
                .toList(),
          ),
        );

        final assistsCard = SectionCard(
          title: 'Assistências',
          child: Column(
            children: repo.topAssists
                .map(
                  (player) => ListTile(
                    title: Text(player.name),
                    subtitle: Text(repo.findTeam(player.teamId).name),
                    trailing: Text('${player.assists} assists'),
                  ),
                )
                .toList(),
          ),
        );

        return ListView(
          children: [
            rankingCard,
            const SizedBox(height: 20),
            if (compact) ...[
              scorersCard,
              const SizedBox(height: 20),
              assistsCard,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: scorersCard),
                  const SizedBox(width: 20),
                  Expanded(child: assistsCard),
                ],
              ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Exportação e relatórios',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  Chip(label: Text('Exportar PDF (próxima etapa)')),
                  Chip(label: Text('Exportar CSV (próxima etapa)')),
                  Chip(label: Text('Dashboard visual com gráficos')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ChampionshipRepository>();
    final championship = repo.selectedChampionship;
    if (championship == null) return const SizedBox.shrink();

    return ListView(
      children: [
        SectionCard(
          title: 'Personalização e privacidade',
          child: Column(
            children: [
              SwitchListTile(
                value: championship.privacy == 'Convidados',
                onChanged: (_) {},
                title: const Text('Campeonato privado para convidados'),
                subtitle: const Text('Preparado para controle de acesso e convites.'),
              ),
              const ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('Notificações push'),
                subtitle: Text('Estrutura pronta para integrar Firebase/OneSignal em versões futuras.'),
              ),
              const ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('Privacidade e conformidade'),
                subtitle: Text('Base preparada para consentimento LGPD/GDPR, criptografia e autenticação em duas etapas.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showCreateChampionshipDialog(BuildContext context) async {
  final repo = context.read<ChampionshipRepository>();
  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final themeController = TextEditingController(text: 'Azul');
  final sponsorController = TextEditingController(text: 'Patrocinador local');
  var format = ChampionshipFormat.league;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Criar campeonato'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome')),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descrição')),
                const SizedBox(height: 12),
                DropdownButtonFormField<ChampionshipFormat>(
                  value: format,
                  items: ChampionshipFormat.values
                      .map((item) => DropdownMenuItem(value: item, child: Text(_formatLabel(item))))
                      .toList(),
                  onChanged: (value) => setState(() => format = value ?? ChampionshipFormat.league),
                  decoration: const InputDecoration(labelText: 'Formato'),
                ),
                const SizedBox(height: 12),
                TextField(controller: themeController, decoration: const InputDecoration(labelText: 'Tema')),
                const SizedBox(height: 12),
                TextField(controller: sponsorController, decoration: const InputDecoration(labelText: 'Patrocinador')),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.addChampionship(
              name: nameController.text,
              title: titleController.text,
              description: descriptionController.text,
              format: format,
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 90)),
              theme: themeController.text,
              sponsor: sponsorController.text,
              privacy: 'Convidados',
            );
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> _showAddTeamDialog(BuildContext context) async {
  final repo = context.read<ChampionshipRepository>();
  final nameController = TextEditingController();
  final logoController = TextEditingController();
  final groupController = TextEditingController(text: 'Grupo A');
  var status = TeamStatus.active;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar equipe'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da equipe')),
              const SizedBox(height: 12),
              TextField(controller: logoController, decoration: const InputDecoration(labelText: 'Sigla / logo textual')),
              const SizedBox(height: 12),
              TextField(controller: groupController, decoration: const InputDecoration(labelText: 'Grupo')),
              const SizedBox(height: 12),
              DropdownButtonFormField<TeamStatus>(
                value: status,
                items: TeamStatus.values
                    .map((item) => DropdownMenuItem(value: item, child: Text(_teamStatusLabel(item))))
                    .toList(),
                onChanged: (value) => setState(() => status = value ?? TeamStatus.active),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.addTeam(
              name: nameController.text,
              logo: logoController.text,
              status: status,
              groupName: groupController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
}

Future<void> _showAddPlayerDialog(BuildContext context) async {
  final repo = context.read<ChampionshipRepository>();
  final nameController = TextEditingController();
  final positionController = TextEditingController();
  var selectedTeamId = repo.championshipTeams.first.id;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar jogador'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedTeamId,
                items: repo.championshipTeams
                    .map((team) => DropdownMenuItem(value: team.id, child: Text(team.name)))
                    .toList(),
                onChanged: (value) => setState(() => selectedTeamId = value ?? selectedTeamId),
                decoration: const InputDecoration(labelText: 'Equipe'),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 12),
              TextField(controller: positionController, decoration: const InputDecoration(labelText: 'Posição')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.addPlayer(teamId: selectedTeamId, name: nameController.text, position: positionController.text);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> _showCsvImportDialog(BuildContext context, int teamId) async {
  final repo = context.read<ChampionshipRepository>();
  final csvController = TextEditingController(text: 'Novo Jogador,Atacante\nNova Jogadora,Meia');
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Importação em massa via CSV'),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: csvController,
          minLines: 8,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Nome,Posição',
            helperText: 'Cole linhas no formato nome,posição',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.importPlayersFromCsv(teamId, csvController.text);
            Navigator.pop(context);
          },
          child: const Text('Importar'),
        ),
      ],
    ),
  );
}

Future<void> _showAddStageDialog(BuildContext context) async {
  final repo = context.read<ChampionshipRepository>();
  final nameController = TextEditingController();
  final typeController = TextEditingController(text: 'Pontos corridos');
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar fase'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da fase')),
            const SizedBox(height: 12),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Tipo')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.addStage(name: nameController.text, type: typeController.text);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> _showAddRoundDialog(BuildContext context, int fallbackStageId) async {
  final repo = context.read<ChampionshipRepository>();
  final nameController = TextEditingController();
  var stageId = fallbackStageId;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar rodada'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: stageId,
                items: repo.championshipStages
                    .map((stage) => DropdownMenuItem(value: stage.id, child: Text(stage.name)))
                    .toList(),
                onChanged: (value) => setState(() => stageId = value ?? stageId),
                decoration: const InputDecoration(labelText: 'Fase'),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da rodada')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.addRound(stageId, nameController.text);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> _showAddMatchDialog(BuildContext context, int roundId) async {
  final repo = context.read<ChampionshipRepository>();
  if (repo.championshipTeams.length < 2) return;
  var homeTeamId = repo.championshipTeams[0].id;
  var awayTeamId = repo.championshipTeams[1].id;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar partida'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: homeTeamId,
                items: repo.championshipTeams
                    .map((team) => DropdownMenuItem(value: team.id, child: Text(team.name)))
                    .toList(),
                onChanged: (value) => setState(() => homeTeamId = value ?? homeTeamId),
                decoration: const InputDecoration(labelText: 'Mandante'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: awayTeamId,
                items: repo.championshipTeams
                    .map((team) => DropdownMenuItem(value: team.id, child: Text(team.name)))
                    .toList(),
                onChanged: (value) => setState(() => awayTeamId = value ?? awayTeamId),
                decoration: const InputDecoration(labelText: 'Visitante'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.addMatch(
              roundId: roundId,
              homeTeamId: homeTeamId,
              awayTeamId: awayTeamId,
              scheduledAt: DateTime.now().add(const Duration(days: 1)),
            );
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> _showResultDialog(BuildContext context, MatchData match) async {
  final repo = context.read<ChampionshipRepository>();
  final homeController = TextEditingController(text: '${match.homeScore}');
  final awayController = TextEditingController(text: '${match.awayScore}');
  var status = match.status;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar resultado'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${repo.findTeam(match.homeTeamId).name} x ${repo.findTeam(match.awayTeamId).name}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: homeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mandante'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: awayController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Visitante'))),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MatchStatus>(
                value: status,
                items: MatchStatus.values
                    .map((item) => DropdownMenuItem(value: item, child: Text(_matchStatus(item))))
                    .toList(),
                onChanged: (value) => setState(() => status = value ?? status),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            repo.updateMatchResult(
              matchId: match.id,
              homeScore: int.tryParse(homeController.text) ?? 0,
              awayScore: int.tryParse(awayController.text) ?? 0,
              status: status,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resultado atualizado em tempo real.')),
            );
            Navigator.pop(context);
          },
          child: const Text('Atualizar'),
        ),
      ],
    ),
  );
}

String _formatLabel(ChampionshipFormat format) {
  switch (format) {
    case ChampionshipFormat.league:
      return 'Pontos corridos';
    case ChampionshipFormat.leaguePlayoffs:
      return 'Pontos corridos + eliminatórias';
    case ChampionshipFormat.knockout:
      return 'Eliminatórias';
  }
}

String _teamStatusLabel(TeamStatus status) {
  switch (status) {
    case TeamStatus.active:
      return 'Ativa';
    case TeamStatus.suspended:
      return 'Suspensa';
    case TeamStatus.disqualified:
      return 'Desclassificada';
  }
}

String _matchStatus(MatchStatus status) {
  switch (status) {
    case MatchStatus.pending:
      return 'Não realizado';
    case MatchStatus.live:
      return 'Em andamento';
    case MatchStatus.finished:
      return 'Encerrado';
  }
}
