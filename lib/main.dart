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
  final _responseKey = GlobalKey();
  String role = 'business', profile = 'business-1', page = 'catalog';
  String topic = 'Все темы', level = 'Все уровни', search = '';
  bool busy = false;
  bool inboxLoading = false;
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
      if (mounted) {
        setState(() => busy = false);
        if (banner != null) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(banner!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              action: SnackBarAction(
                label: 'Закрыть',
                textColor: const Color(0xFFB6D3FF),
                onPressed: messenger.hideCurrentSnackBar,
              ),
            ),
          );
        }
      }
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
    final taskId = selected!['id'];
    final ownerId = profile;
    setState(() => inboxLoading = true);
    try {
      final result = await api.call(
        'GET',
        '/api/tasks/$taskId/proposals?owner=$ownerId',
      );
      if (mounted && selected?['id'] == taskId && profile == ownerId) {
        setState(() {
          inbox = result;
          inboxLoading = false;
        });
      }
    } catch (e) {
      if (mounted && selected?['id'] == taskId && profile == ownerId) {
        setState(() {
          banner = e.toString();
          inboxLoading = false;
        });
      }
    }
  }

  void openTask(Map<String, dynamic> task) {
    setState(() {
      selected = task;
      inbox = [];
      inboxLoading = role == 'business' && task['owner'] == profile;
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

  Widget _brand({bool compact = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.assignment_turned_in_outlined,
          color: Colors.white,
          size: 21,
        ),
      ),
      const SizedBox(width: 11),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Паспорт',
            style: TextStyle(
              color: ink,
              fontSize: compact ? 19 : 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
          if (!compact)
            const Text(
              'ЗАДАЧИ И КОМАНДЫ',
              style: TextStyle(
                color: muted,
                fontSize: 9,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    ],
  );

  Widget _sidebar() => Container(
    width: 232,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: line)),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 31, 20, 43),
            child: _brand(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(27, 0, 16, 12),
            child: Text(
              'ПРОСТРАНСТВО',
              style: TextStyle(
                color: Color(0xFF9AA0AA),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          _nav('catalog', Icons.explore_outlined, 'Каталог задач'),
          if (role == 'business') ...[
            _nav('mine', Icons.folder_outlined, 'Мои задачи'),
            _nav('create', Icons.add_circle_outline, 'Создать задачу'),
          ],
          if (role == 'team')
            _nav('sent', Icons.near_me_outlined, 'Мои отклики'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: blue,
                    size: 24,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'От идеи — к результату',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Помощник уточнит детали и соберёт понятную задачу.',
                    style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                  ),
                  if (role == 'business') ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: resetCreate,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Создать задачу'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(27, 2, 20, 24),
            child: Text(
              'AI SANA  /  NavIQ',
              style: TextStyle(
                color: Color(0xFF9AA0AA),
                fontSize: 11,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _nav(String id, IconData icon, String label) {
    final active = page == id || (id == 'catalog' && page == 'detail');
    final count = id == 'catalog'
        ? catalog.length
        : id == 'mine'
        ? mine.length
        : id == 'sent'
        ? sent.length
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: active ? const Color(0xFFEAF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => id == 'create' ? resetCreate() : navigate(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: active ? blue : muted, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? blue : ink,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      color: active ? blue : const Color(0xFF9AA0AA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
    width: double.infinity,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: line)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, box) {
          final nav = Wrap(
            spacing: 3,
            children: [
              _compactNav('catalog', 'Каталог'),
              if (role == 'business') ...[
                _compactNav('mine', 'Мои задачи'),
                _compactNav('create', 'Создать'),
              ],
              if (role == 'team') _compactNav('sent', 'Отклики'),
            ],
          );
          if (box.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brand(compact: true),
                const SizedBox(height: 12),
                nav,
              ],
            );
          }
          return Row(children: [_brand(compact: true), const Spacer(), nav]);
        },
      ),
    ),
  );
  Widget _compactNav(String id, String label) {
    final active = page == id || (page == 'detail' && id == 'catalog');
    return TextButton(
      onPressed: () => id == 'create' ? resetCreate() : navigate(id),
      style: TextButton.styleFrom(
        backgroundColor: active ? const Color(0xFFEAF2FF) : null,
        foregroundColor: active ? blue : muted,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _workspace() => Column(
    children: [
      _topbar(),
      if (busy)
        const LinearProgressIndicator(
          minHeight: 2,
          color: blue,
          backgroundColor: line,
        ),
      Expanded(
        child: SingleChildScrollView(
          key: ValueKey('$page-${selected?['id'] ?? ''}'),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.sizeOf(context).width > 1100 ? 38 : 22,
                  30,
                  MediaQuery.sizeOf(context).width > 1100 ? 38 : 22,
                  54,
                ),
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
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    child: LayoutBuilder(
      builder: (context, box) {
        final picker = SizedBox(
          width: box.maxWidth < 440 ? 145 : 180,
          child: DropdownButtonFormField<String>(
            key: ValueKey('$role-$profile'),
            initialValue: profile,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: muted,
            ),
            borderRadius: BorderRadius.circular(18),
            decoration: InputDecoration(
              fillColor: Colors.white,
              prefixIcon: box.maxWidth > 440
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFFEAF2FF),
                        child: Text(
                          profileName.isEmpty ? 'P' : profileName[0],
                          style: const TextStyle(
                            color: blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) switchProfile(value);
            },
          ),
        );
        return Row(
          children: [
            if (box.maxWidth > 690) ...[
              const Icon(Icons.workspaces_outline, size: 18, color: muted),
              const SizedBox(width: 9),
              const Text(
                'Рабочее пространство',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const Spacer(),
            ] else
              const Spacer(),
            _roleToggle(),
            const SizedBox(width: 12),
            picker,
          ],
        );
      },
    ),
  );
  Widget _roleToggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEAEDF2),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roleButton('business', 'Бизнес'),
        _roleButton('team', 'Команда'),
      ],
    ),
  );
  Widget _roleButton(String value, String label) => InkWell(
    onTap: busy ? null : () => switchRole(value),
    borderRadius: BorderRadius.circular(99),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: role == value ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        boxShadow: role == value
            ? const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: role == value ? ink : muted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
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
        IconButton(
          tooltip: 'Закрыть сообщение',
          onPressed: () => setState(() => banner = null),
          icon: const Icon(Icons.close_rounded, size: 18, color: blue),
        ),
      ],
    ),
  );

  String _companyName(String owner) {
    for (final business in businesses) {
      if (business['id'] == owner) return business['name'].toString();
    }
    return 'Бизнес';
  }

  String _responseLabel(int count) {
    final n = count % 100;
    final word = n >= 11 && n <= 14
        ? 'откликов'
        : count % 10 == 1
        ? 'отклик'
        : count % 10 >= 2 && count % 10 <= 4
        ? 'отклика'
        : 'откликов';
    return '$count $word';
  }

  void _clearFilters() {
    searchInput.clear();
    setState(() {
      search = '';
      topic = 'Все темы';
      level = 'Все уровни';
    });
  }

  Widget _catalogPage() {
    final filtered = catalog.where((item) {
      final f = Map<String, dynamic>.from(item['fields']),
          r = Map<String, dynamic>.from(item['rating']);
      return (topic == 'Все темы' || f['topic'] == topic) &&
          (level == 'Все уровни' || r['level'] == level) &&
          (search.isEmpty ||
              '${f['title']} ${f['context']} ${f['need']}'
                  .toLowerCase()
                  .contains(search.toLowerCase()));
    }).toList();
    final ready = catalog
        .where((item) => (item['rating']['score'] as int) >= 70)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ВОЗМОЖНОСТИ ДЛЯ РОСТА',
          style: TextStyle(
            color: blue,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        _pageTitle(
          'Каталог задач',
          'Идеи бизнеса, которые ждут вашу команду.',
          action: role == 'business'
              ? FilledButton.icon(
                  onPressed: resetCreate,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Создать задачу'),
                )
              : null,
        ),
        const SizedBox(height: 17),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _inlineMetric(
              Icons.grid_view_rounded,
              '${catalog.length} открытых задач',
            ),
            _inlineMetric(Icons.verified_outlined, '$ready готовы к старту'),
            const Text(
              'Все уровни готовности — в одном месте',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, box) {
            final query = TextField(
              controller: searchInput,
              onChanged: (value) => setState(() => search = value),
              decoration: InputDecoration(
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 23,
                  color: muted,
                ),
                hintText: 'Какую задачу вы ищете?',
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить поиск',
                        onPressed: () {
                          searchInput.clear();
                          setState(() => search = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            );
            final readiness = _dropdown(
              level,
              levels,
              (v) => setState(() => level = v),
            );
            if (box.maxWidth < 520) {
              return Column(
                children: [query, const SizedBox(height: 10), readiness],
              );
            }
            return Row(
              children: [
                Expanded(child: query),
                const SizedBox(width: 12),
                SizedBox(width: 204, child: readiness),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((name) {
            final active = topic == name;
            return ChoiceChip(
              label: Text(name),
              selected: active,
              showCheckmark: false,
              avatar: Icon(
                name == 'Все темы' ? Icons.apps_rounded : topicIcon(name),
                size: 16,
                color: active ? blue : topicColor(name),
              ),
              labelStyle: TextStyle(
                color: active ? blue : muted,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(color: active ? const Color(0xFFBDD4F5) : line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              selectedColor: const Color(0xFFEAF2FF),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              onSelected: (_) => setState(() => topic = name),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              topic == 'Все темы' ? 'Все задачи' : topic,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEDF2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${filtered.length}',
                style: const TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (search.isNotEmpty ||
                topic != 'Все темы' ||
                level != 'Все уровни')
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Сбросить'),
              ),
            const Icon(Icons.south_rounded, color: muted, size: 15),
            const SizedBox(width: 5),
            const Text(
              'По готовности',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (catalog.isEmpty && businesses.isEmpty && banner == null)
          const Padding(
            padding: EdgeInsets.all(45),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty)
          _emptyState(
            Icons.manage_search_rounded,
            'Ничего не нашлось',
            'Попробуйте другую тему или сбросьте фильтры.',
            action: TextButton(
              onPressed: _clearFilters,
              child: const Text('Сбросить фильтры'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 1040
                  ? 3
                  : box.maxWidth >= 580
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  mainAxisExtent: 346,
                ),
                itemBuilder: (context, i) =>
                    _taskCard(Map<String, dynamic>.from(filtered[i])),
              );
            },
          ),
      ],
    );
  }

  Widget _inlineMetric(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: muted),
      const SizedBox(width: 7),
      Text(text, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );

  Widget _emptyState(
    IconData icon,
    String title,
    String description, {
    Widget? action,
  }) => surface(
    SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: blue, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 14),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    ),
  );

  Widget _taskCard(Map<String, dynamic> task) {
    final f = Map<String, dynamic>.from(task['fields']),
        rating = Map<String, dynamic>.from(task['rating']);
    final category = (f['topic'] as String).isEmpty
        ? 'Другое'
        : f['topic'] as String;
    final score = rating['score'] as int;
    return HoverCard(
      onTap: () => openTask(task),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              topicMark(category, size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: topicColor(category),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _companyName(task['owner']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.north_east_rounded,
                size: 18,
                color: topicColor(category).withValues(alpha: .7),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            f['title'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: ink,
              height: 1.24,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            (f['need'] as String).isEmpty ? f['context'] : f['need'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 14, height: 1.5),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                rating['level'],
                style: TextStyle(
                  color: levelColor(rating['level']),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$score',
                style: const TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                ' / 100',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 4,
                color: levelColor(rating['level']),
                backgroundColor: const Color(0xFFF0F2F5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.forum_outlined, size: 15, color: muted),
              const SizedBox(width: 7),
              Text(
                _responseLabel(task['proposal_count'] as int),
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const Spacer(),
              const Text(
                'Посмотреть',
                style: TextStyle(
                  color: blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    key: ValueKey(value),
    initialValue: value,
    isExpanded: true,
    borderRadius: BorderRadius.circular(18),
    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
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
    final drafts = mine.where((task) => task['status'] == 'draft').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pageTitle(
          'Мои задачи',
          'Ваши идеи и работа с командами — в одном месте.',
          action: FilledButton.icon(
            onPressed: resetCreate,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Новая задача'),
          ),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth > 650
                ? (box.maxWidth - 32) / 3
                : box.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _stat(
                    'Всего задач',
                    '${mine.length}',
                    Icons.folder_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _stat(
                    'В работе над брифом',
                    '$drafts',
                    Icons.edit_note_rounded,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _stat(
                    'Опубликовано',
                    '${mine.length - drafts}',
                    Icons.public_rounded,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        const Text(
          'Ваши карточки',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 16),
        if (mine.isEmpty)
          _emptyState(
            Icons.note_add_outlined,
            'Начните с первой идеи',
            'Помощник поможет превратить её в задачу.',
            action: FilledButton(
              onPressed: resetCreate,
              child: const Text('Создать задачу'),
            ),
          )
        else
          for (final raw in mine) ...[
            _mineRow(Map<String, dynamic>.from(raw)),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon) => surface(
    Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: blue, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
    padding: const EdgeInsets.all(22),
  );
  Widget _mineRow(Map<String, dynamic> task) {
    final f = Map<String, dynamic>.from(task['fields']),
        rating = Map<String, dynamic>.from(task['rating']);
    final draft = task['status'] == 'draft';
    final category = (f['topic'] as String).isEmpty
        ? 'Другое'
        : f['topic'] as String;
    final title = (f['title'] as String).isEmpty ? task['idea'] : f['title'];
    final content = Row(
      children: [
        topicMark(category, size: 42),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                draft
                    ? 'Не опубликована · ${rating['score']}/100'
                    : '${rating['level']} · ${_responseLabel(task['proposal_count'] as int)}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => editTask(task),
          child: Text(draft ? 'Продолжить' : 'Редактировать'),
        ),
        if (!draft) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => openTask(task),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEAF2FF),
              foregroundColor: blue,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 19),
            tooltip: 'Открыть задачу',
          ),
        ],
      ],
    );
    return surface(
      LayoutBuilder(
        builder: (context, box) => box.maxWidth < 590
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [content, const SizedBox(height: 18), actions],
              )
            : Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 20),
                  actions,
                ],
              ),
      ),
      padding: const EdgeInsets.all(22),
    );
  }

  Widget _createPage() {
    final isPublished = editing?['status'] == 'published';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pageTitle(
          isPublished
              ? 'Редактировать задачу'
              : createStep == 2
              ? 'Карточка задачи'
              : 'Новая задача',
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
    return LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          for (var i = 0; i < names.length; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: i == createStep ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: i == createStep ? line : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i < createStep
                            ? mint
                            : i == createStep
                            ? blue
                            : const Color(0xFFE8ECF2),
                        shape: BoxShape.circle,
                      ),
                      child: i < createStep
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF188038),
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == createStep ? Colors.white : muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    if (box.maxWidth > 450) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          names[i],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: i == createStep ? ink : muted,
                            fontSize: 13,
                            fontWeight: i == createStep
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (i < names.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _ideaStep() => LayoutBuilder(
    builder: (context, box) {
      final form = surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                topicMark('AI', size: 46),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Всё начинается с идеи',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Расскажите, что вы хотите улучшить. Помощник уточнит детали и подготовит основу карточки.',
              style: TextStyle(color: muted, fontSize: 15, height: 1.55),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: idea,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Например: менеджеры тратят много времени на одинаковые вопросы покупателей. Хотим бота для поддержки.',
                contentPadding: EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _exampleChip(
                  'Бот поддержки',
                  'Менеджеры тратят много времени на одинаковые вопросы покупателей. Хотим бота для поддержки.',
                ),
                _exampleChip(
                  'Аналитика отзывов',
                  'Получаем отзывы из разных каналов. Нужно понять, какие проблемы упоминают чаще всего.',
                ),
              ],
            ),
            const SizedBox(height: 27),
            FilledButton.icon(
              onPressed: busy ? null : startQuestions,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(busy ? 'Готовим вопросы…' : 'Получить вопросы'),
            ),
          ],
        ),
        padding: const EdgeInsets.all(30),
      );
      final guide = Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF3FD),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Что получится',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 22),
            _guideItem(
              Icons.assignment_outlined,
              'Понятная карточка',
              'Контекст, результат и условия работы.',
            ),
            _guideItem(
              Icons.donut_large_rounded,
              'Рейтинг готовности',
              'Подсказки, что стоит уточнить.',
            ),
            _guideItem(
              Icons.people_outline_rounded,
              'Предложения команд',
              'Вы сами выбираете, с кем работать.',
            ),
            const Divider(height: 26, color: Color(0xFFD9E3F3)),
            const Text(
              'Публикация — только после вашего подтверждения.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
      if (box.maxWidth < 880) {
        return Column(children: [form, const SizedBox(height: 18), guide]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: form),
          const SizedBox(width: 22),
          Expanded(flex: 3, child: guide),
        ],
      );
    },
  );
  Widget _exampleChip(String label, String value) => ActionChip(
    onPressed: () {
      idea.text = value;
    },
    avatar: const Icon(Icons.add_rounded, size: 15, color: muted),
    label: Text(label, style: const TextStyle(color: muted, fontSize: 12)),
    backgroundColor: Colors.white,
    side: const BorderSide(color: line),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
  );
  Widget _guideItem(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: blue, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
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
        final wide = c.maxWidth > 920;
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
            : Column(children: [form, const SizedBox(height: 20), sidebar]);
      },
    );
  }

  Widget _cardForm() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Паспорт задачи',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.7,
                ),
              ),
            ),
            if (editing?['rating'] != null)
              levelPill(editing!['rating']['level']),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Проверьте факты и добавьте детали. Оценка обновится после сохранения.',
          style: TextStyle(color: muted, fontSize: 14),
        ),
        const SizedBox(height: 28),
        _formSection('01', 'Суть задачи', [
          'title',
          'topic',
          'context',
          'need',
        ]),
        const Divider(height: 40),
        _formSection('02', 'Результат и условия', [
          'users',
          'data',
          'outcome',
          'success',
          'constraints',
        ]),
        const Divider(height: 40),
        _formSection('03', 'Связь с командой', ['contact', 'format']),
        const SizedBox(height: 28),
        const Divider(height: 1),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 12,
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
                editing?['status'] == 'published'
                    ? Icons.check_rounded
                    : Icons.arrow_upward_rounded,
                size: 18,
              ),
              label: Text(
                editing?['status'] == 'published'
                    ? 'Подтвердить изменения'
                    : 'Опубликовать',
              ),
            ),
          ],
        ),
      ],
    ),
    padding: const EdgeInsets.all(28),
  );

  Widget _formSection(String number, String title, List<String> keys) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            number,
            style: const TextStyle(
              color: blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -.3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth > 590
              ? (box.maxWidth - 18) / 2
              : box.maxWidth;
          return Wrap(
            spacing: 18,
            runSpacing: 20,
            children: keys
                .map(
                  (key) => SizedBox(
                    width: key == 'constraints' ? box.maxWidth : width,
                    child: _editorField(key),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
  Widget _editorField(String key) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        fieldLabels[key]!,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: ink,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 8),
      if (key == 'topic')
        _dropdown(
          topics.skip(1).contains(fields['topic']!.text)
              ? fields['topic']!.text
              : 'Другое',
          topics.skip(1).toList(),
          (v) => setState(() => fields['topic']!.text = v),
        )
      else
        TextField(
          controller: fields[key],
          minLines: key == 'title' ? 1 : 3,
          maxLines: key == 'title' ? 1 : 5,
          style: const TextStyle(fontSize: 15, height: 1.5),
          decoration: InputDecoration(hintText: _hint(key)),
        ),
    ],
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
        const Row(
          children: [
            Icon(Icons.donut_large_rounded, color: blue, size: 19),
            SizedBox(width: 9),
            Text(
              'Готовность задачи',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Center(child: ScoreRing(rating['score'] as int)),
        const SizedBox(height: 17),
        Center(child: levelPill(rating['level'])),
        const SizedBox(height: 9),
        const Center(
          child: Text(
            'По сохранённым данным',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 26),
        for (final raw in rating['breakdown'] as List) ...[
          _ratingLine(Map<String, dynamic>.from(raw)),
          const SizedBox(height: 15),
        ],
        const Divider(height: 27),
        Row(
          children: [
            Icon(
              (rating['advice'] as List).isEmpty
                  ? Icons.check_circle_outline
                  : Icons.lightbulb_outline,
              size: 18,
              color: blue,
            ),
            const SizedBox(width: 8),
            Text(
              (rating['advice'] as List).isEmpty
                  ? 'Всё готово'
                  : 'Следующий шаг',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if ((rating['advice'] as List).isEmpty)
          const Text(
            'Все критерии заполнены. Карточка готова к работе с командой.',
            style: TextStyle(color: muted, fontSize: 13, height: 1.5),
          )
        else
          for (final advice in rating['advice'] as List)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.add_rounded, size: 14, color: muted),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
    padding: const EdgeInsets.all(24),
  );
  Widget _ratingLine(Map<String, dynamic> item) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              item['label'],
              style: const TextStyle(color: ink, fontSize: 12, height: 1.35),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item['earned']}/${item['points']}',
            style: TextStyle(
              color: (item['earned'] as int) > 0
                  ? const Color(0xFF188038)
                  : muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: (item['earned'] as num) / (item['points'] as num),
          backgroundColor: const Color(0xFFEDF0F4),
          color: const Color(0xFF6BBF8C),
          minHeight: 4,
        ),
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
    final category = (f['topic'] as String).isEmpty
        ? 'Другое'
        : f['topic'] as String;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => navigate('catalog'),
          icon: const Icon(Icons.arrow_back_rounded, size: 17),
          label: const Text('Все задачи'),
        ),
        const SizedBox(height: 18),
        surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  topicMark(category, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _companyName(task['owner']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            color: topicColor(category),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  levelPill(rating['level']),
                ],
              ),
              const SizedBox(height: 23),
              Text(
                f['title'],
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 11),
              Text(
                f['need'],
                style: const TextStyle(color: muted, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 24),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 22,
                runSpacing: 16,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScoreRing(rating['score'] as int, small: true),
                      const SizedBox(width: 10),
                      const Text(
                        'Готовность задачи',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                  _inlineMetric(
                    Icons.forum_outlined,
                    _responseLabel(task['proposal_count'] as int),
                  ),
                  if (role == 'team' || isOwner)
                    FilledButton.icon(
                      onPressed: () {
                        final target = _responseKey.currentContext;
                        if (target != null) {
                          Scrollable.ensureVisible(
                            target,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            alignment: .03,
                          );
                        }
                      },
                      icon: Icon(
                        role == 'team'
                            ? Icons.near_me_outlined
                            : Icons.people_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        role == 'team'
                            ? 'Предложить решение'
                            : 'Предложения команд',
                      ),
                    ),
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.all(30),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, box) {
            final body = _detailsFields(f);
            final response = KeyedSubtree(
              key: _responseKey,
              child: role == 'team'
                  ? _proposalForm()
                  : isOwner
                  ? _proposalsPanel()
                  : const SizedBox.shrink(),
            );
            final aside = Column(
              children: [
                response,
                if (role == 'team' || isOwner) const SizedBox(height: 20),
                _ratingPanel(rating),
              ],
            );
            if (box.maxWidth < 960) {
              return Column(
                children: [body, const SizedBox(height: 20), aside],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: body),
                const SizedBox(width: 22),
                Expanded(flex: 4, child: aside),
              ],
            );
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
          'Бриф задачи',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 25),
        for (final key in [
          'context',
          'need',
          'outcome',
          'success',
          'users',
          'data',
          'constraints',
          'contact',
          'format',
        ]) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  switch (key) {
                    'context' => Icons.subject_rounded,
                    'need' => Icons.flag_outlined,
                    'outcome' => Icons.inventory_2_outlined,
                    'success' => Icons.check_circle_outline,
                    'users' => Icons.people_outline_rounded,
                    'data' => Icons.storage_rounded,
                    'constraints' => Icons.tune_rounded,
                    'contact' => Icons.alternate_email_rounded,
                    _ => Icons.chat_bubble_outline_rounded,
                  },
                  size: 17,
                  color: muted,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fieldLabels[key]!,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SelectableText(
                      (f[key] as String).isEmpty ? 'Пока не указано' : f[key],
                      style: TextStyle(
                        color: (f[key] as String).isEmpty
                            ? const Color(0xFF9AA0AA)
                            : ink,
                        fontSize: 15,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (key != 'format') const Divider(height: 32),
        ],
      ],
    ),
    padding: const EdgeInsets.all(28),
  );
  Widget _proposalForm() => surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.near_me_outlined, color: blue, size: 21),
        ),
        const SizedBox(height: 16),
        const Text(
          'Предложите решение',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'От команды $profileName. Расскажите о подходе и первых шагах.',
          style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _formField('Идея решения', proposalIdea, maxLines: 3),
        _formField('План работы', proposalPlan, maxLines: 3),
        _formField('Срок', proposalTimeline),
        _formField('Ссылка на прототип · необязательно', proposalLink),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : sendProposal,
            icon: const Icon(Icons.arrow_outward_rounded, size: 18),
            label: Text(busy ? 'Отправляем…' : 'Отправить отклик'),
          ),
        ),
        const SizedBox(height: 13),
        const Center(
          child: Text(
            'Выбор команды остаётся за бизнесом',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ),
      ],
    ),
    padding: const EdgeInsets.all(26),
  );
  Widget _formField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: ink,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, height: 1.5),
          decoration: InputDecoration(
            hintText: controller == proposalIdea
                ? 'Как вы решите задачу?'
                : controller == proposalPlan
                ? 'Этапы и результат каждого этапа'
                : controller == proposalTimeline
                ? 'Например, 3 недели'
                : 'https://…',
          ),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.5,
                ),
              ),
            ),
            _tag('${inbox.length}'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Сравните подходы. Можно выбрать несколько команд.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 22),
        if (inboxLoading)
          const Padding(
            padding: EdgeInsets.all(26),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (inbox.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: canvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.forum_outlined, color: muted, size: 26),
                SizedBox(height: 10),
                Text(
                  'Первые отклики ещё впереди',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
        for (final raw in inbox) ...[
          _proposalTile(Map<String, dynamic>.from(raw)),
          const SizedBox(height: 14),
        ],
      ],
    ),
    padding: const EdgeInsets.all(24),
  );
  Widget _proposalTile(Map<String, dynamic> proposal) {
    final selectedTeam = proposal['decision'] == 'selected';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selectedTeam ? const Color(0xFFF4FBF6) : Colors.white,
        border: Border.all(
          color: selectedTeam ? const Color(0xFFBFDFCA) : line,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEAF2FF),
                child: Text(
                  proposal['team_name'].toString()[0],
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  proposal['team_name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _decisionPill(proposal['decision']),
              _tag(proposal['timeline']),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${proposal['team_focus']} · ${proposal['university']}',
            style: const TextStyle(color: muted, fontSize: 11, height: 1.45),
          ),
          const Divider(height: 25),
          Text(
            proposal['idea'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ПЛАН РАБОТЫ',
            style: TextStyle(
              color: muted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            proposal['plan'],
            style: const TextStyle(color: muted, fontSize: 13, height: 1.55),
          ),
          if ((proposal['prototype'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Прототип',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            SelectableText(
              proposal['prototype'],
              style: const TextStyle(color: blue, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: busy || proposal['decision'] == 'rejected'
                    ? null
                    : () => decide(proposal, 'rejected'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: const Text('Отклонить', style: TextStyle(fontSize: 12)),
              ),
              FilledButton.icon(
                onPressed: busy || selectedTeam
                    ? null
                    : () => decide(proposal, 'selected'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: Icon(
                  selectedTeam ? Icons.check_rounded : Icons.add_rounded,
                  size: 15,
                ),
                label: Text(
                  selectedTeam ? 'Выбрана' : 'Выбрать',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
