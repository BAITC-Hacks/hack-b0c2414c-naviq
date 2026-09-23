require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');
const {rate, meaningful} = require('./rating');

const FIELDS = ['title','topic','context','need','users','data','constraints','outcome','success','contact','format'];
const dataDir = path.join(__dirname, 'data');
fs.mkdirSync(dataDir, { recursive: true });
const db = new Database(path.join(dataDir, 'passport.sqlite'));
db.pragma('journal_mode = WAL');
db.exec(`CREATE TABLE IF NOT EXISTS tasks (
 id INTEGER PRIMARY KEY AUTOINCREMENT, owner TEXT NOT NULL, idea TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'draft', fields TEXT NOT NULL DEFAULT '{}',
 questions TEXT NOT NULL DEFAULT '[]', answers TEXT NOT NULL DEFAULT '[]',
 question_source TEXT NOT NULL DEFAULT 'template', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 published_at TEXT
);`);
if (!db.prepare('PRAGMA table_info(tasks)').all().some(column => column.name === 'question_fields')) {
  db.exec("ALTER TABLE tasks ADD COLUMN question_fields TEXT NOT NULL DEFAULT '[]'");
}
db.exec(`CREATE TABLE IF NOT EXISTS teams (
 id TEXT PRIMARY KEY, name TEXT NOT NULL, focus TEXT NOT NULL, university TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS proposals (
 id INTEGER PRIMARY KEY AUTOINCREMENT, task_id INTEGER NOT NULL REFERENCES tasks(id),
 team_id TEXT NOT NULL REFERENCES teams(id), idea TEXT NOT NULL, plan TEXT NOT NULL,
 timeline TEXT NOT NULL, prototype TEXT NOT NULL DEFAULT '', decision TEXT NOT NULL DEFAULT 'pending',
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(task_id,team_id)
);
CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);`);
db.pragma('foreign_keys = ON');

const app = express();
app.use(cors());
app.use(express.json({limit: '64kb'}));
const clean = value => typeof value === 'string' ? value.trim().slice(0, 3000) : '';
function normalizeFields(input) {
  return Object.fromEntries(FIELDS.map(key => [key, clean(input?.[key])]));
}
function taskFromRow(row) {
  if (!row) return null;
  const fields = normalizeFields(JSON.parse(row.fields));
  return { ...row, fields, questions: JSON.parse(row.questions), question_fields: JSON.parse(row.question_fields), answers: JSON.parse(row.answers), rating:rate(fields), proposal_count: db.prepare('SELECT COUNT(*) AS total FROM proposals WHERE task_id = ?').get(row.id).total };
}
function getTask(id) { return taskFromRow(db.prepare('SELECT * FROM tasks WHERE id = ?').get(id)); }
function templates(fields) {
  const candidates = [
    ['users', 'Кто будет пользоваться результатом и в какой ситуации?'],
    ['data', 'Какие данные, материалы или доступы уже есть для работы?'],
    ['outcome', 'Какой конкретный результат вы хотите получить от команды?'],
    ['success', 'По каким измеримым признакам вы поймёте, что задача решена?'],
    ['constraints', 'Какие есть сроки, ограничения или обязательные условия?'],
    ['contact', 'Кто ответит на вопросы команды и как с ним связаться?'],
  ];
  const missing = candidates.filter(([key]) => !fields[key]);
  const extra = candidates.filter(([key]) => !!fields[key]).map(([key,q]) => [key,`Уточните: ${q}`]);
  const selected = [...missing, ...extra].slice(0, 3);
  return {questions:selected.map(([,q])=>q), questionFields:selected.map(([key])=>key)};
}
async function askAI(idea, fields) {
  if (!process.env.OPENAI_API_KEY) throw new Error('AI key missing');
  const OpenAI = require('openai');
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY, timeout: 12000 });
  const response = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
    response_format: {type: 'json_object'},
    messages: [
      {role:'system', content:'Ты помощник для составления студенческой задачи. Верни JSON: questions — массив минимум 3 конкретных уточняющих вопросов; questionFields — массив ключей поля для каждого вопроса из context,need,users,data,constraints,outcome,success,contact,format; draft — объект с полями title,topic,context,need,users,data,constraints,outcome,success,contact,format. В draft копируй только дословные фрагменты входа. Неизвестные поля оставь пустыми строками. Не рассчитывай рейтинг и не выбирай команду.'},
      {role:'user', content:JSON.stringify({idea, knownFields:fields})}
    ]
  });
  const parsed = JSON.parse(response.choices[0].message.content);
  if (!Array.isArray(parsed.questions) || parsed.questions.length < 3 || !parsed.questions.every(q => typeof q === 'string' && q.trim().length >= 8)) throw new Error('Invalid questions');
  if (!Array.isArray(parsed.questionFields) || parsed.questionFields.length !== parsed.questions.length || !parsed.questionFields.every(key => FIELDS.includes(key) && key !== 'title' && key !== 'topic')) throw new Error('Invalid question fields');
  if (!parsed.draft || typeof parsed.draft !== 'object' || Array.isArray(parsed.draft)) throw new Error('Invalid draft');
  const draft = normalizeFields(parsed.draft);
  for (const key of FIELDS) if (draft[key] && !idea.toLocaleLowerCase().includes(draft[key].toLocaleLowerCase())) draft[key] = '';
  // Never let AI overwrite facts already confirmed by the user.
  for (const key of FIELDS) if (fields[key]) draft[key] = fields[key];
  return {questions: parsed.questions.slice(0,5).map(clean), questionFields:parsed.questionFields.slice(0,5), draft};
}

function seedDemo() {
  if (db.prepare("SELECT value FROM meta WHERE key = 'demo-v1'").get()) return;
  const teams = [
    ['team-1','Byte Crew','Веб и UX','Университет А'],
    ['team-2','Qadam Lab','Аналитика данных','Университет Б'],
    ['team-3','Orion Dev','AI и автоматизация','Университет В'],
    ['team-4','Dala Studio','Мобильные продукты','Университет Г'],
    ['team-5','Signal Team','Интеграции','Университет Д'],
  ];
  const insertTeam = db.prepare('INSERT OR IGNORE INTO teams (id,name,focus,university) VALUES (?,?,?,?)');
  const insertTask = db.prepare('INSERT INTO tasks (owner,idea,status,fields,published_at) VALUES (?,?,?,?,?)');
  const insertProposal = db.prepare('INSERT OR IGNORE INTO proposals (task_id,team_id,idea,plan,timeline,prototype) VALUES (?,?,?,?,?,?)');
  const published = [
    ['business-1',{title:'Бот для поддержки клиентов',topic:'AI',context:'Магазин получает повторяющиеся вопросы в чате.',need:'Сократить ручные ответы менеджеров.',users:'Покупатели интернет-магазина и операторы.',data:'Обезличенный FAQ из 120 вопросов и ответов.',constraints:'Пилот за 4 недели, без персональных данных.',outcome:'Рабочий бот с передачей сложного вопроса оператору.',success:'Не менее 70% типовых вопросов закрываются без оператора.',contact:'Демо-контакт: куратор магазина',format:'Еженедельный онлайн созвон и переписка.'}],
    ['business-2',{title:'Панель учёта заявок',topic:'Веб',context:'Мастерская ведёт обращения в таблицах.',need:'Собрать заявки в одном месте.',users:'Диспетчеры и мастера.',data:'Обезличенный экспорт 200 заявок.',constraints:'Без платных сервисов.',outcome:'Веб-панель со статусами и поиском.',success:'Обработка заявки за 2 минуты вместо 5.',contact:'Демо-контакт: менеджер мастерской',format:'Два созвона в неделю.'}],
    ['business-3',{title:'Анализ отзывов посетителей',topic:'Данные',context:'Кафе получает отзывы из разных каналов.',need:'Увидеть частые проблемы.',users:'Управляющий кафе.',data:'Обезличенные тексты 80 отзывов.',outcome:'Сводка тем и простая панель.'}],
    ['business-1',{title:'Расписание волонтёров',topic:'Веб',context:'Организаторы распределяют смены вручную.',need:'Упростить запись на смены.',users:'Волонтёры и координатор.',outcome:'Простой календарь смен.'}],
    ['business-2',{title:'Идея для экскурсионного сервиса',topic:'Мобильное',context:'Нужен цифровой помощник для экскурсий.',need:'Помочь гостям ориентироваться.'}],
  ];
  const drafts = [
    ['business-1','Нужен сервис для бронирования переговорных'],
    ['business-2','Хотим найти идеи для анализа складских остатков'],
    ['business-3','Нужно улучшить выдачу заказов'],
    ['business-1','Помогите с цифровой картой мероприятий'],
    ['business-2','Нужен инструмент для обратной связи клиентов'],
  ];
  db.transaction(() => {
    for (const team of teams) insertTeam.run(...team);
    const ids = published.map(([owner,fields]) => Number(insertTask.run(owner,fields.context,'published',JSON.stringify(normalizeFields(fields)),new Date().toISOString()).lastInsertRowid));
    for (const [owner,idea] of drafts) insertTask.run(owner,idea,'draft',JSON.stringify(normalizeFields({context:idea})),null);
    [
      [ids[0],'team-1','Сделаем веб-виджет с поиском по FAQ.','Прототип, тест на FAQ, интеграция.', '4 недели','https://example.org/demo/bot'],
      [ids[0],'team-3','Соберём бот с эскалацией оператору.','Разметка FAQ, диалоги, пилот.', '3 недели',''],
      [ids[1],'team-2','Панель с быстрым поиском и отчётами.','Схема данных, интерфейс, тест.', '5 недель',''],
      [ids[2],'team-4','Визуализируем частые темы отзывов.','Очистка текстов, группы тем, панель.', '4 недели',''],
      [ids[3],'team-5','Календарь с учётом свободных слотов.','Модель смен, запись, проверка.', '3 недели',''],
    ].forEach(proposal => insertProposal.run(...proposal));
    db.prepare("INSERT INTO meta (key,value) VALUES ('demo-v1','1')").run();
  })();
}
seedDemo();

app.get('/api/health', (_req,res) => res.json({ok:true}));
app.get('/api/profiles', (_req,res) => res.json({businesses:[
  {id:'business-1',name:'Nova Market'}, {id:'business-2',name:'Qala Workshop'}, {id:'business-3',name:'City Lab'}
],teams:db.prepare('SELECT * FROM teams ORDER BY id').all()}));
app.get('/api/tasks', (req,res) => {
  const owner = clean(req.query.owner);
  const rows = owner ? db.prepare('SELECT * FROM tasks WHERE owner = ? ORDER BY id DESC').all(owner) : db.prepare("SELECT * FROM tasks WHERE status = 'published'").all();
  let tasks = rows.map(taskFromRow);
  if (!owner) {
    const topic = clean(req.query.topic), level = clean(req.query.level), search = clean(req.query.search).toLocaleLowerCase();
    if (topic) tasks = tasks.filter(task => task.fields.topic === topic);
    if (level) tasks = tasks.filter(task => task.rating.level === level);
    if (search) tasks = tasks.filter(task => `${task.fields.title} ${task.fields.context} ${task.fields.need}`.toLocaleLowerCase().includes(search));
    tasks.sort((a,b) => b.rating.score - a.rating.score || b.id - a.id);
  }
  res.json(tasks);
});
app.get('/api/tasks/:id', (req,res) => {
  const task = getTask(req.params.id);
  if (!task) return res.status(404).json({error:'Задача не найдена'});
  res.json(task);
});
app.post('/api/tasks', (req,res) => {
  const owner = clean(req.body.owner), idea = clean(req.body.idea);
  if (!owner || idea.length < 10) return res.status(400).json({error:'Укажите профиль и опишите задачу минимум в 10 символах'});
  const fields = normalizeFields({context:idea});
  const result = db.prepare('INSERT INTO tasks (owner,idea,fields) VALUES (?,?,?)').run(owner, idea, JSON.stringify(fields));
  res.status(201).json(getTask(result.lastInsertRowid));
});
app.post('/api/tasks/:id/questions', async (req,res) => {
  const task = getTask(req.params.id);
  if (!task) return res.status(404).json({error:'Задача не найдена'});
  if (task.status !== 'draft') return res.status(409).json({error:'Опубликованную задачу нельзя вернуть к вопросам'});
  let questions, questionFields, fields = task.fields, source = 'ai', notice = null;
  try { const result = await askAI(task.idea, task.fields); questions = result.questions; questionFields = result.questionFields; fields = result.draft; }
  catch { source = 'template'; const result = templates(task.fields); questions = result.questions; questionFields = result.questionFields; notice = 'ИИ сейчас недоступен. Используются шаблонные вопросы.'; }
  db.prepare('UPDATE tasks SET questions = ?, question_fields = ?, fields = ?, question_source = ? WHERE id = ?').run(JSON.stringify(questions),JSON.stringify(questionFields),JSON.stringify(fields),source,task.id);
  res.json({task:getTask(task.id),notice});
});
app.put('/api/tasks/:id', (req,res) => {
  const task = getTask(req.params.id);
  if (!task) return res.status(404).json({error:'Задача не найдена'});
  if (req.body.owner !== task.owner) return res.status(403).json({error:'Выбран другой профиль бизнеса'});
  const fields = normalizeFields(req.body.fields);
  const answers = Array.isArray(req.body.answers) ? req.body.answers.slice(0,5).map(clean) : [];
  for (let i=0;i<answers.length;i++) {
    const key = task.question_fields[i];
    if (key && !meaningful(fields[key]) && meaningful(answers[i])) fields[key] = answers[i];
  }
  if (task.status === 'published' && req.body.confirm !== true) return res.status(400).json({error:'Подтвердите обновление опубликованной карточки'});
  db.prepare('UPDATE tasks SET fields = ?, answers = ? WHERE id = ?').run(JSON.stringify(fields),JSON.stringify(answers),task.id);
  res.json(getTask(task.id));
});
app.get('/api/tasks/:id/proposals', (req,res) => {
  const task = getTask(req.params.id);
  if (!task) return res.status(404).json({error:'Задача не найдена'});
  if (task.owner !== clean(req.query.owner)) return res.status(403).json({error:'Предложения доступны владельцу задачи'});
  res.json(db.prepare('SELECT proposals.*, teams.name AS team_name, teams.focus AS team_focus, teams.university AS university FROM proposals JOIN teams ON teams.id = proposals.team_id WHERE task_id = ? ORDER BY proposals.id DESC').all(task.id));
});
app.post('/api/tasks/:id/proposals', (req,res) => {
  const task = getTask(req.params.id);
  if (!task || task.status !== 'published') return res.status(404).json({error:'Опубликованная задача не найдена'});
  const teamId = clean(req.body.team_id);
  if (!db.prepare('SELECT id FROM teams WHERE id = ?').get(teamId)) return res.status(400).json({error:'Выберите команду'});
  const idea = clean(req.body.idea), plan = clean(req.body.plan), timeline = clean(req.body.timeline), prototype = clean(req.body.prototype);
  if (!meaningful(idea) || !meaningful(plan) || !meaningful(timeline)) return res.status(400).json({error:'Опишите идею, план и срок'});
  if (prototype && !/^https?:\/\/[^\s]+$/i.test(prototype)) return res.status(400).json({error:'Ссылка на прототип должна начинаться с http:// или https://'});
  try {
    const result = db.prepare('INSERT INTO proposals (task_id,team_id,idea,plan,timeline,prototype) VALUES (?,?,?,?,?,?)').run(task.id,teamId,idea,plan,timeline,prototype);
    res.status(201).json(db.prepare('SELECT * FROM proposals WHERE id = ?').get(result.lastInsertRowid));
  } catch (error) {
    if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') return res.status(409).json({error:'Эта команда уже откликнулась на задачу'});
    throw error;
  }
});
app.get('/api/teams/:id/proposals', (req,res) => {
  if (!db.prepare('SELECT id FROM teams WHERE id = ?').get(req.params.id)) return res.status(404).json({error:'Команда не найдена'});
  res.json(db.prepare('SELECT proposals.*, tasks.fields AS task_fields FROM proposals JOIN tasks ON tasks.id = proposals.task_id WHERE team_id = ? ORDER BY proposals.id DESC').all(req.params.id).map(row => ({...row,task_title:JSON.parse(row.task_fields).title,task_fields:undefined})));
});
app.post('/api/proposals/:id/decision', (req,res) => {
  const proposal = db.prepare('SELECT proposals.*, tasks.owner FROM proposals JOIN tasks ON tasks.id = proposals.task_id WHERE proposals.id = ?').get(req.params.id);
  if (!proposal) return res.status(404).json({error:'Отклик не найден'});
  if (proposal.owner !== clean(req.body.owner)) return res.status(403).json({error:'Решение принимает только владелец задачи'});
  if (!['selected','rejected'].includes(req.body.decision)) return res.status(400).json({error:'Выберите действие'});
  db.prepare('UPDATE proposals SET decision = ? WHERE id = ?').run(req.body.decision,proposal.id);
  res.json(db.prepare('SELECT * FROM proposals WHERE id = ?').get(proposal.id));
});
app.post('/api/tasks/:id/publish', (req,res) => {
  const task = getTask(req.params.id);
  if (!task) return res.status(404).json({error:'Задача не найдена'});
  if (req.body.owner !== task.owner) return res.status(403).json({error:'Выбран другой профиль бизнеса'});
  if (task.status !== 'draft') return res.status(409).json({error:'Задача уже опубликована'});
  if (req.body.confirm !== true) return res.status(400).json({error:'Требуется ручное подтверждение публикации'});
  if (!task.fields.title || !task.fields.need) return res.status(400).json({error:'Заполните название и потребность перед публикацией'});
  db.prepare("UPDATE tasks SET status = 'published', published_at = CURRENT_TIMESTAMP WHERE id = ?").run(task.id);
  res.json(getTask(task.id));
});
app.use((err,_req,res,_next) => res.status(500).json({error:'Ошибка сервера', detail:process.env.NODE_ENV === 'production' ? undefined : err.message}));
if (require.main === module) app.listen(Number(process.env.PORT || 3000), () => console.log(`API on http://localhost:${process.env.PORT || 3000}`));
module.exports = {app,db};
