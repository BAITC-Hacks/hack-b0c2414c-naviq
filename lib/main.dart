import 'package:flutter/material.dart';

import 'api.dart';
import 'design.dart';

const fieldLabels = <String, String>{
  'title': 'Название задачи',
  'topic': 'Тема',
  'context': 'Контекст',
  'need': 'Потребность',
  'users': 'Пользователи',
  'data': 'Данные и материалы',
  'constraints': 'Ограничения',
  'outcome': 'Ожидаемый результат',
  'success': 'Критерии успеха',
  'contact': 'Контакт',
  'format': 'Формат взаимодействия',
};
const topics = ['Все темы', 'AI', 'Веб', 'Данные', 'Мобильное', 'Другое'];
const levels = ['Все уровни', 'Приоритетная', 'Готовая', 'Рабочая', 'Черновик'];

void main() => runApp(
  MaterialApp(
    title: 'Паспорт задачи',
    debugShowCheckedModeBanner: false,
    theme: passportTheme(),
    home: const Home(),
  ),
);

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final api = Api();
  String role = 'business', profile = 'business-1', page = 'catalog';
  String topic = 'Все темы', level = 'Все уровни', search = '';
  bool busy = false;
  String? banner;
  List<dynamic> catalog = [],
      mine = [],
      inbox = [],
      sent = [],
      businesses = [],
      teams = [];
  Map<String, dynamic>? selected, editing;
  int createStep = 0;
  final searchInput = TextEditingController(), idea = TextEditingController();
  final fields = {
    for (final key in fieldLabels.keys) key: TextEditingController(),
  };
  final proposalIdea = TextEditingController(),
      proposalPlan = TextEditingController(),
      proposalTimeline = TextEditingController(),
      proposalLink = TextEditingController();
  final answers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    for (final c in [
      searchInput,
      idea,
      proposalIdea,
      proposalPlan,
      proposalTimeline,
      proposalLink,
      ...fields.values,
      ...answers,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get profileName {
    final list = role == 'business' ? businesses : teams;
    for (final item in list) {
      if (item['id'] == profile) return item['name'] as String;
    }
    return profile;
  }

  Future<void> refresh() async {
    try {
      final data = await api.call('GET', '/api/profiles');
      final all = await api.call('GET', '/api/tasks');
      final owned = role == 'business'
          ? await api.call('GET', '/api/tasks?owner=$profile')
          : [];
      final proposals = role == 'team'
          ? await api.call('GET', '/api/teams/$profile/proposals')
          : [];
      if (!mounted) return;
      setState(() {
        businesses = data['businesses'];
        teams = data['teams'];
        catalog = all;
        mine = owned;
        sent = proposals;
        if (selected != null) {
          final current = all.where((item) => item['id'] == selected!['id']);
          if (current.isNotEmpty) {
            selected = Map<String, dynamic>.from(current.first);
          }
        }
      });
      if (page == 'detail' &&
          selected != null &&
          role == 'business' &&
          selected!['owner'] == profile) {
        await loadInbox();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => banner =
              'Не удалось подключиться к серверу. Запустите API на порту 3000.',
        );
      }
    }
  }

  Future<void> action(Future<void> Function() work) async {
    setState(() {
      busy = true;
      banner = null;
    });
    try {
      await work();
    } catch (e) {
      if (mounted) setState(() => banner = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void navigate(String next) {
    setState(() {
      page = next;
      selected = null;
      banner = null;
    });
    if (next == 'catalog' || next == 'mine' || next == 'sent') refresh();
  }

  void switchRole(String value) {
    setState(() {
      role = value;
      profile = value == 'business' ? 'business-1' : 'team-1';
      page = 'catalog';
      selected = null;
      banner = null;
    });
    refresh();
  }

  void switchProfile(String value) {
    setState(() {
      profile = value;
      selected = null;
      page = 'catalog';
      banner = null;
    });
    refresh();
  }

  void fillFields(Map<String, dynamic> values) {
    for (final key in fieldLabels.keys) {
      fields[key]!.text = (values[key] ?? '').toString();
    }
  }

  void resetCreate() {
    idea.clear();
    for (final c in fields.values) {
      c.clear();
    }
    for (final c in answers) {
      c.dispose();
    }
    answers.clear();
    setState(() {
      editing = null;
      createStep = 0;
      page = 'create';
      banner = null;
    });
  }

  void editTask(Map<String, dynamic> task) {
    editing = task;
    idea.text = (task['idea'] ?? '').toString();
    fillFields(Map<String, dynamic>.from(task['fields']));
    answers.clear();
    for (final value in task['answers'] as List) {
      answers.add(TextEditingController(text: value.toString()));
    }
    setState(() {
      createStep = 2;
      page = 'create';
      selected = null;
    });
  }

  Future<void> startQuestions() => action(() async {
    editing = await api.call('POST', '/api/tasks', {
      'owner': profile,
      'idea': idea.text,
    });
    final result = await api.call(
      'POST',
      '/api/tasks/${editing!['id']}/questions',
      {},
    );
    editing = Map<String, dynamic>.from(result['task']);
    fillFields(Map<String, dynamic>.from(editing!['fields']));
    answers.clear();
    for (final _ in editing!['questions'] as List) {
      answers.add(TextEditingController());
    }
    setState(() {
      createStep = 1;
      banner = result['notice'];
    });
    await refresh();
  });
  void goToCard() {
    final keys = editing!['question_fields'] as List;
    for (var i = 0; i < answers.length && i < keys.length; i++) {
      final key = keys[i].toString();
      if (fields.containsKey(key) && fields[key]!.text.trim().isEmpty) {
        fields[key]!.text = answers[i].text.trim();
      }
    }
    setState(() => createStep = 2);
  }

  Future<bool> saveCard({bool confirmUpdate = false}) async {
    bool success = false;
    await action(() async {
      editing = await api.call('PUT', '/api/tasks/${editing!['id']}', {
        'owner': profile,
        'confirm': confirmUpdate,
        'fields': {for (final key in fieldLabels.keys) key: fields[key]!.text},
        'answers': answers.map((c) => c.text).toList(),
      });
      fillFields(Map<String, dynamic>.from(editing!['fields']));
      success = true;
      setState(() => banner = 'Карточка сохранена. Рейтинг обновлён.');
      await refresh();
    });
    return success;
  }

  Future<bool> confirmDialog(
    String title,
    String body,
    String actionLabel,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(actionLabel),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> publish() async {
    if (!await saveCard() || !mounted) return;
    if (!await confirmDialog(
          'Опубликовать задачу?',
          'Карточка станет видна всем командам, включая задачи с низким рейтингом.',
          'Опубликовать',
        ) ||
        !mounted) {
      return;
    }
    await action(() async {
      editing = await api.call('POST', '/api/tasks/${editing!['id']}/publish', {
        'owner': profile,
        'confirm': true,
      });
      setState(() {
        createStep = 3;
        banner = 'Задача опубликована в каталоге.';
      });
      await refresh();
    });
  }

  Future<void> updatePublished() async {
    if (!await confirmDialog(
          'Сохранить изменения?',
          'Рейтинг опубликованной задачи пересчитается после вашего подтверждения.',
          'Подтвердить',
        ) ||
        !mounted) {
      return;
    }
    await saveCard(confirmUpdate: true);
  }

  Future<void> loadInbox() async {
    if (selected == null) return;
    try {
      final result = await api.call(
        'GET',
        '/api/tasks/${selected!['id']}/proposals?owner=$profile',
      );
      if (mounted) setState(() => inbox = result);
    } catch (e) {
      if (mounted) setState(() => banner = e.toString());
    }
  }

  void openTask(Map<String, dynamic> task) {
    setState(() {
      selected = task;
      page = 'detail';
      banner = null;
    });
    if (role == 'business' && task['owner'] == profile) loadInbox();
  }

  Future<void> sendProposal() => action(() async {
    if (selected == null) return;
    await api.call('POST', '/api/tasks/${selected!['id']}/proposals', {
      'team_id': profile,
      'idea': proposalIdea.text,
      'plan': proposalPlan.text,
      'timeline': proposalTimeline.text,
      'prototype': proposalLink.text,
    });
    proposalIdea.clear();
    proposalPlan.clear();
    proposalTimeline.clear();
    proposalLink.clear();
    setState(
      () => banner = 'Отклик отправлен. Решение примет представитель бизнеса.',
    );
    await refresh();
  });
  Future<void> decide(Map<String, dynamic> proposal, String decision) async {
    final word = decision == 'selected' ? 'Выбрать' : 'Отклонить';
    if (!await confirmDialog(
          '$word команду?',
          decision == 'selected'
              ? 'Можно выбрать несколько команд для одной задачи.'
              : 'Решение можно изменить позже.',
          word,
        ) ||
        !mounted) {
      return;
    }
    await action(() async {
      await api.call('POST', '/api/proposals/${proposal['id']}/decision', {
        'owner': profile,
        'decision': decision,
      });
      await loadInbox();
      setState(() => banner = 'Решение сохранено.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      body: desktop
          ? Row(
              children: [
                _sidebar(),
                Expanded(child: _workspace()),
              ],
            )
          : Column(
              children: [
                _mobileBar(),
                Expanded(child: _workspace()),
              ],
            ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 252,
      color: ink,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 30, 18, 36),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: blue,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ПАСПОРТ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'РАБОЧЕЕ ПРОСТРАНСТВО',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .48),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _nav('catalog', Icons.dashboard_outlined, 'Каталог задач'),
            if (role == 'business') ...[
              _nav('create', Icons.add_box_outlined, 'Создать задачу'),
              _nav('mine', Icons.folder_open_outlined, 'Мои задачи'),
            ],
            if (role == 'team')
              _nav('sent', Icons.send_outlined, 'Мои отклики'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFF9AAEFF)),
                    SizedBox(height: 9),
                    Text(
                      'Сильная задача начинается с ясного описания.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _nav(String id, IconData icon, String label) {
    final active = page == id || (id == 'catalog' && page == 'detail');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: active ? const Color(0xFF304365) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => id == 'create' ? resetCreate() : navigate(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? Colors.white : const Color(0xFF98A6BE),
                  size: 20,
                ),
                const SizedBox(width: 13),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFFC0C9D9),
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileBar() => Container(
    color: ink,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: SafeArea(
      bottom: false,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          const Text(
            'ПАСПОРТ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          TextButton(
            onPressed: () => navigate('catalog'),
            child: const Text('Каталог'),
          ),
          if (role == 'business')
            TextButton(onPressed: resetCreate, child: const Text('Создать')),
          if (role == 'business')
            TextButton(
              onPressed: () => navigate('mine'),
              child: const Text('Мои'),
            ),
          if (role == 'team')
            TextButton(
              onPressed: () => navigate('sent'),
              child: const Text('Отклики'),
            ),
        ],
      ),
    ),
  );
  Widget _workspace() => Column(
    children: [
      _topbar(),
      Expanded(
        child: SingleChildScrollView(
          key: ValueKey('$page-${selected?['id'] ?? ''}'),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1260),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 54),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (banner != null) ...[
                      _notice(),
                      const SizedBox(height: 22),
                    ],
                    switch (page) {
                      'create' => _createPage(),
                      'mine' => _minePage(),
                      'sent' => _sentPage(),
                      'detail' => _detailPage(),
                      _ => _catalogPage(),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  Widget _topbar() => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
        if (MediaQuery.sizeOf(context).width >= 700)
          Expanded(
            child: Text(
              role == 'business'
                  ? 'Пространство бизнеса'
                  : 'Пространство команды',
              style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ),
        _roleToggle(),
        const SizedBox(width: 10),
        SizedBox(
          width: MediaQuery.sizeOf(context).width < 700 ? 155 : 190,
          child: DropdownButtonFormField<String>(
            key: ValueKey('$role-$profile'),
            initialValue: profile,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: (role == 'business' ? businesses : teams)
                .map<DropdownMenuItem<String>>(
                  (item) => DropdownMenuItem(
                    value: item['id'] as String,
                    child: Text(
                      item['name'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) switchProfile(value);
            },
          ),
        ),
      ],
    ),
  );
  Widget _roleToggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: canvas,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _roleButton('business', 'Бизнес'),
        _roleButton('team', 'Команда'),
      ],
    ),
  );
  Widget _roleButton(String value, String label) => InkWell(
    onTap: () => switchRole(value),
    borderRadius: BorderRadius.circular(9),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: role == value ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        boxShadow: role == value
            ? const [BoxShadow(color: Color(0x12000000), blurRadius: 6)]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: role == value ? ink : muted,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ),
  );
  Widget _notice() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6EDFF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: blue, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(banner!, style: const TextStyle(color: ink)),
        ),
      ],
    ),
  );

  Widget _catalogPage() {
    final filtered = catalog.where((item) {
      final task = Map<String, dynamic>.from(item);
      final f = Map<String, dynamic>.from(task['fields']);
      final r = Map<String, dynamic>.from(task['rating']);
      return (topic == 'Все темы' || f['topic'] == topic) &&
          (level == 'Все уровни' || r['level'] == level) &&
          (search.isEmpty ||
              '${f['title']} ${f['context']} ${f['need']}'
                  .toLowerCase()
                  .contains(search.toLowerCase()));
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pageTitle(
          'Каталог задач',
          'Реальные задачи бизнеса. Чем полнее карточка, тем выше она в каталоге.',
          action: role == 'business'
              ? FilledButton.icon(
                  onPressed: resetCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать задачу'),
                )
              : null,
        ),
        const SizedBox(height: 26),
        surface(
          LayoutBuilder(
            builder: (context, box) {
              final query = TextField(
                controller: searchInput,
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по задачам',
                ),
              );
              final topicFilter = _dropdown(
                topic,
                topics,
                (v) => setState(() => topic = v),
              );
              final levelFilter = _dropdown(
                level,
                levels,
                (v) => setState(() => level = v),
              );
              if (box.maxWidth < 650) {
                return Column(
                  children: [
                    query,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: topicFilter),
                        const SizedBox(width: 10),
                        Expanded(child: levelFilter),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: query),
                  const SizedBox(width: 12),
                  SizedBox(width: 170, child: topicFilter),
                  const SizedBox(width: 12),
                  SizedBox(width: 180, child: levelFilter),
                ],
              );
            },
          ),
          padding: const EdgeInsets.all(16),
        ),
        const SizedBox(height: 21),
        Row(
          children: [
            Text('Все задачи', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 10),
            Text(
              '${filtered.length}',
              style: const TextStyle(color: muted, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.sort, color: muted, size: 18),
            const SizedBox(width: 6),
            const Text('По рейтингу', style: TextStyle(color: muted)),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          surface(
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: Text('По этим фильтрам задач пока нет.'),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final columns = c.maxWidth > 860
                  ? 3
                  : c.maxWidth > 540
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 275,
                ),
                itemBuilder: (context, i) =>
                    _taskCard(Map<String, dynamic>.from(filtered[i])),
              );
            },
          ),
      ],
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final f = Map<String, dynamic>.from(task['fields']);
    final rating = Map<String, dynamic>.from(task['rating']);
    return InkWell(
      onTap: () => openTask(task),
      borderRadius: BorderRadius.circular(20),
      child: surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tag((f['topic'] as String).isEmpty ? 'Другое' : f['topic']),
                const Spacer(),
                levelPill(rating['level']),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              f['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: ink,
                height: 1.22,
              ),
            ),
            const SizedBox(height: 9),
            Expanded(
              child: Text(
                (f['need'] as String).isEmpty ? f['context'] : f['need'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, height: 1.45),
              ),
            ),
            const Divider(color: line),
            Row(
              children: [
                _scoreCircle(rating['score'] as int, small: true),
                const SizedBox(width: 10),
                const Text(
                  'готовность',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${task['proposal_count']} откликов',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    items: options
        .map(
          (v) => DropdownMenuItem(
            value: v,
            child: Text(v, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF1F8),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: ink,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
  Widget _scoreCircle(int score, {bool small = false}) => Container(
    width: small ? 39 : 92,
    height: small ? 39 : 92,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: score >= 70 ? mint : const Color(0xFFFFF1D9),
      border: Border.all(
        color: score >= 70 ? const Color(0xFFB4E8CE) : const Color(0xFFFFDB9D),
        width: small ? 2 : 5,
      ),
    ),
    child: Text(
      '$score',
      style: TextStyle(
        fontSize: small ? 15 : 30,
        fontWeight: FontWeight.w900,
        color: score >= 70 ? const Color(0xFF148657) : const Color(0xFFA76A10),
      ),
    ),
  );
  Widget _pageTitle(String title, String subtitle, {Widget? action}) =>
      LayoutBuilder(
        builder: (context, box) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 15),
              ),
            ],
          );
          if (box.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                if (action != null) ...[const SizedBox(height: 16), action],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              ?action,
            ],
          );
        },
      );

  Widget _minePage() {
    final drafts = mine.where((t) => t['status'] == 'draft').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pageTitle(
          'Мои задачи',
          'Черновики и опубликованные карточки профиля $profileName.',
          action: FilledButton.icon(
            onPressed: resetCreate,
            icon: const Icon(Icons.add),
            label: const Text('Новая задача'),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: _stat('Всего задач', '${mine.length}', Icons.folder_open),
            ),
            const SizedBox(width: 14),
            Expanded(child: _stat('Черновики', '$drafts', Icons.edit_note)),
            const SizedBox(width: 14),
            Expanded(
              child: _stat(
                'Опубликовано',
                '${mine.length - drafts}',
                Icons.public,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (mine.isEmpty)
          surface(
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Задач пока нет. Создайте первую карточку.'),
            ),
          )
        else
          for (final raw in mine) ...[
            _mineRow(Map<String, dynamic>.from(raw)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon) => surface(
    Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: blue),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            Text(label, style: const TextStyle(color: muted, fontSize: 13)),
          ],
        ),
      ],
    ),
  );
  Widget _mineRow(Map<String, dynamic> task) {
    final f = Map<String, dynamic>.from(task['fields']);
    final rating = Map<String, dynamic>.from(task['rating']);
    return surface(
      Row(
        children: [
          _scoreCircle(rating['score'] as int, small: true),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (f['title'] as String).isEmpty ? task['idea'] : f['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  task['status'] == 'draft'
                      ? 'Черновик · ${rating['level']}'
                      : 'Опубликована · ${task['proposal_count']} откликов',
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => editTask(task),
            child: const Text('Редактировать'),
          ),
          if (task['status'] == 'published') ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => openTask(task),
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Открыть задачу',
            ),
          ],
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _createPage() {
    final isPublished = editing?['status'] == 'published';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pageTitle(
          isPublished ? 'Редактировать задачу' : 'Новая задача',
          isPublished
              ? 'Изменения рейтинга вступят в силу после подтверждения.'
              : 'От идеи до понятной карточки для команды.',
        ),
        const SizedBox(height: 23),
        _steps(),
        const SizedBox(height: 24),
        if (createStep == 0) _ideaStep(),
        if (createStep == 1) _questionStep(),
        if (createStep == 2) _cardStep(),
        if (createStep == 3) _doneStep(),
      ],
    );
  }

  Widget _steps() {
    final names = ['Идея', 'Уточнения', 'Карточка', 'Публикация'];
    return surface(
      Row(
        children: [
          for (var i = 0; i < names.length; i++) ...[
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i <= createStep ? blue : const Color(0xFFE9EDF5),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i <= createStep ? Colors.white : muted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      names[i],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: i <= createStep ? ink : muted,
                        fontWeight: i == createStep
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < names.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _ideaStep() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Опишите задачу своими словами',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Можно начать с пары предложений. Помощник задаст вопросы о недостающих деталях.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: idea,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Например: хотим бота, который отвечает на частые вопросы покупателей...',
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: busy ? null : startQuestions,
          icon: const Icon(Icons.auto_awesome),
          label: Text(busy ? 'Подождите…' : 'Получить вопросы'),
        ),
      ],
    ),
  );
  Widget _questionStep() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Уточним важное',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
            _tag(
              editing?['question_source'] == 'ai'
                  ? 'Вопросы AI'
                  : 'Шаблонные вопросы',
            ),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'Ответы попадут в соответствующие поля карточки. Вы сможете всё проверить и изменить.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 23),
        for (var i = 0; i < answers.length; i++) ...[
          Text(
            '${i + 1}. ${editing!['questions'][i]}',
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: answers[i],
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Ваш ответ'),
          ),
          const SizedBox(height: 20),
        ],
        FilledButton(
          onPressed: goToCard,
          child: const Text('Сформировать карточку'),
        ),
      ],
    ),
  );
  Widget _cardStep() {
    final rating = editing?['rating'] is Map
        ? Map<String, dynamic>.from(editing!['rating'])
        : <String, dynamic>{
            'score': 0,
            'level': 'Черновик',
            'breakdown': [],
            'advice': [],
          };
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 830;
        final form = _cardForm();
        final sidebar = _ratingPanel(rating);
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: form),
                  const SizedBox(width: 18),
                  Expanded(flex: 3, child: sidebar),
                ],
              )
            : Column(children: [sidebar, const SizedBox(height: 18), form]);
      },
    );
  }

  Widget _cardForm() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Паспорт задачи',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Заполняйте конкретными фактами. Длинный текст сам по себе не повышает рейтинг.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 22),
        for (final entry in fieldLabels.entries) ...[
          Text(
            entry.value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
          ),
          const SizedBox(height: 8),
          entry.key == 'topic'
              ? _dropdown(
                  fields['topic']!.text.isEmpty
                      ? 'Другое'
                      : fields['topic']!.text,
                  topics.skip(1).toList(),
                  (v) => setState(() => fields['topic']!.text = v),
                )
              : TextField(
                  controller: fields[entry.key],
                  minLines: entry.key == 'title' ? 1 : 2,
                  maxLines: entry.key == 'title' ? 1 : 3,
                  decoration: InputDecoration(hintText: _hint(entry.key)),
                ),
          const SizedBox(height: 17),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: busy
                  ? null
                  : (editing?['status'] == 'published'
                        ? updatePublished
                        : () => saveCard()),
              child: const Text('Сохранить и пересчитать'),
            ),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : (editing?['status'] == 'published'
                        ? updatePublished
                        : publish),
              icon: Icon(
                editing?['status'] == 'published' ? Icons.check : Icons.publish,
              ),
              label: Text(
                editing?['status'] == 'published'
                    ? 'Подтвердить изменения'
                    : 'Опубликовать задачу',
              ),
            ),
          ],
        ),
      ],
    ),
  );
  String _hint(String key) => switch (key) {
    'title' => 'Например: бот поддержки клиентов',
    'context' => 'Что происходит сейчас?',
    'need' => 'Какую проблему нужно решить?',
    'users' => 'Кто будет пользоваться результатом?',
    'data' => 'Какие данные и материалы доступны?',
    'constraints' => 'Срок, бюджет, технологии, запреты',
    'outcome' => 'Что должна передать команда?',
    'success' => 'Например: 70% вопросов без оператора',
    'contact' => 'Демо-контакт или роль куратора',
    'format' => 'Созвоны, переписка, частота обратной связи',
    _ => '',
  };
  Widget _ratingPanel(Map<String, dynamic> rating) => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Готовность задачи',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _scoreCircle(rating['score'] as int),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  levelPill(rating['level']),
                  const SizedBox(height: 9),
                  const Text('из 100 баллов', style: TextStyle(color: muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 21),
        for (final raw in rating['breakdown'] as List) ...[
          _ratingLine(Map<String, dynamic>.from(raw)),
          const SizedBox(height: 12),
        ],
        const Divider(color: line, height: 30),
        const Text(
          'Что улучшить',
          style: TextStyle(fontWeight: FontWeight.w800, color: ink),
        ),
        const SizedBox(height: 10),
        if ((rating['advice'] as List).isEmpty)
          const Text('Все критерии заполнены.', style: TextStyle(color: muted))
        else
          for (final advice in rating['advice'] as List)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $advice',
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
      ],
    ),
  );
  Widget _ratingLine(Map<String, dynamic> item) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              item['label'],
              style: const TextStyle(color: ink, fontSize: 12),
            ),
          ),
          Text(
            '${item['earned']}/${item['points']}',
            style: TextStyle(
              color: (item['earned'] as int) > 0
                  ? const Color(0xFF15875C)
                  : muted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      LinearProgressIndicator(
        value: (item['earned'] as num) / (item['points'] as num),
        backgroundColor: const Color(0xFFECF0F6),
        color: const Color(0xFF36B889),
        borderRadius: BorderRadius.circular(8),
        minHeight: 5,
      ),
    ],
  );
  Widget _doneStep() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF15875C), size: 52),
        const SizedBox(height: 17),
        const Text(
          'Задача опубликована',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Она уже в каталоге. Команды могут отправлять предложения, а решение остаётся за бизнесом.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => openTask(editing!),
          child: const Text('Посмотреть карточку'),
        ),
      ],
    ),
  );

  Widget _detailPage() {
    if (selected == null) return _catalogPage();
    final task = selected!,
        f = Map<String, dynamic>.from(task['fields']),
        rating = Map<String, dynamic>.from(task['rating']);
    final isOwner = role == 'business' && task['owner'] == profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => navigate('catalog'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Назад в каталог'),
        ),
        const SizedBox(height: 12),
        surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _tag((f['topic'] as String).isEmpty ? 'Другое' : f['topic']),
                  const SizedBox(width: 10),
                  levelPill(rating['level']),
                  const Spacer(),
                  const Icon(Icons.visibility_outlined, color: muted, size: 18),
                  const SizedBox(width: 5),
                  const Text(
                    'Доступна всем командам',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                f['title'],
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 9),
              Text(
                f['need'],
                style: const TextStyle(color: muted, fontSize: 16),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _scoreCircle(rating['score'] as int, small: true),
                  const SizedBox(width: 10),
                  Text(
                    'Готовность ${rating['score']}/100',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${task['proposal_count']} откликов',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.all(27),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 820;
            final body = _detailsFields(f);
            final aside = Column(
              children: [
                _ratingPanel(rating),
                const SizedBox(height: 17),
                if (role == 'team')
                  _proposalForm()
                else if (isOwner)
                  _proposalsPanel()
                else
                  surface(
                    const Text(
                      'Переключитесь на профиль владельца, чтобы увидеть отклики.',
                    ),
                  ),
              ],
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: body),
                      const SizedBox(width: 18),
                      Expanded(flex: 4, child: aside),
                    ],
                  )
                : Column(children: [body, const SizedBox(height: 18), aside]);
          },
        ),
      ],
    );
  }

  Widget _detailsFields(Map<String, dynamic> f) => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'О задаче',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 17),
        for (final key in [
          'context',
          'need',
          'users',
          'data',
          'constraints',
          'outcome',
          'success',
          'contact',
          'format',
        ]) ...[
          Text(
            fieldLabels[key]!,
            style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
          ),
          const SizedBox(height: 6),
          Text(
            (f[key] as String).isEmpty ? 'Не указано' : f[key],
            style: TextStyle(
              color: (f[key] as String).isEmpty ? muted : ink,
              height: 1.45,
            ),
          ),
          const Divider(color: line, height: 28),
        ],
      ],
    ),
  );
  Widget _proposalForm() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Откликнуться на задачу',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Опишите предложение. Команду выбирает только представитель бизнеса.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        _formField('Идея решения', proposalIdea, maxLines: 3),
        _formField('План работы', proposalPlan, maxLines: 3),
        _formField('Срок', proposalTimeline),
        _formField('Ссылка на прототип (необязательно)', proposalLink),
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: busy ? null : sendProposal,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Отправить отклик'),
        ),
      ],
    ),
  );
  Widget _formField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: label),
        ),
      ],
    ),
  );
  Widget _proposalsPanel() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Предложения команд',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
            Text('${inbox.length}', style: const TextStyle(color: muted)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Можно выбрать несколько команд или никого.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (inbox.isEmpty)
          const Text('Откликов пока нет.', style: TextStyle(color: muted)),
        for (final raw in inbox) ...[
          _proposalTile(Map<String, dynamic>.from(raw)),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
  Widget _proposalTile(Map<String, dynamic> p) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                p['team_name'],
                style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
              ),
            ),
            _decisionPill(p['decision']),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${p['team_focus']} · ${p['university']}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Text(p['idea'], style: const TextStyle(color: ink)),
        const SizedBox(height: 8),
        Text(
          'План: ${p['plan']}',
          style: const TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 5),
        Text(
          'Срок: ${p['timeline']}',
          style: const TextStyle(color: muted, fontSize: 13),
        ),
        if ((p['prototype'] as String).isNotEmpty)
          Text(
            'Прототип: ${p['prototype']}',
            style: const TextStyle(color: blue, fontSize: 13),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => decide(p, 'rejected'),
              child: const Text('Отклонить'),
            ),
            FilledButton(
              onPressed: () => decide(p, 'selected'),
              child: const Text('Выбрать'),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _decisionPill(String decision) {
    final label = switch (decision) {
      'selected' => 'Выбрана',
      'rejected' => 'Отклонена',
      _ => 'На рассмотрении',
    };
    final color = switch (decision) {
      'selected' => const Color(0xFF15875C),
      'rejected' => const Color(0xFF9D4F5B),
      _ => const Color(0xFF9E7417),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sentPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pageTitle(
        'Мои отклики',
        'Предложения команды $profileName и решения бизнеса.',
      ),
      const SizedBox(height: 24),
      if (sent.isEmpty)
        surface(
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text('Откликов пока нет. Найдите задачу в каталоге.'),
          ),
        )
      else
        for (final raw in sent) ...[
          surface(
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        raw['task_title'] ?? 'Задача',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(raw['idea'], style: const TextStyle(color: muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _decisionPill(raw['decision']),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
    ],
  );
}
