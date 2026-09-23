require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

const FIELDS = ['title','context','need','users','data','constraints','outcome','success','contact','format'];
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

const app = express();
app.use(cors());
app.use(express.json({limit: '64kb'}));
const clean = value => typeof value === 'string' ? value.trim().slice(0, 3000) : '';
function normalizeFields(input) {
  return Object.fromEntries(FIELDS.map(key => [key, clean(input?.[key])]));
}
function taskFromRow(row) {
  if (!row) return null;
  return { ...row, fields: normalizeFields(JSON.parse(row.fields)), questions: JSON.parse(row.questions), answers: JSON.parse(row.answers) };
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
  const missing = candidates.filter(([key]) => !fields[key]).map(([,q]) => q);
  const extra = candidates.filter(([key]) => !!fields[key]).map(([,q]) => `Уточните: ${q}`);
  return [...missing, ...extra].slice(0, 3);
}
async function askAI(idea, fields) {
  if (!process.env.OPENAI_API_KEY) throw new Error('AI key missing');
  const OpenAI = require('openai');
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY, timeout: 12000 });
  const response = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
    response_format: {type: 'json_object'},
    messages: [
      {role:'system', content:'Ты помощник для составления студенческой задачи. Верни JSON: questions — массив минимум 3 конкретных уточняющих вопросов о недостающих фактах; draft — объект с полями title,context,need,users,data,constraints,outcome,success,contact,format. Копируй только факты, явно указанные пользователем. Неизвестные поля оставь пустыми строками. Не рассчитывай рейтинг и не выбирай команду.'},
      {role:'user', content:JSON.stringify({idea, knownFields:fields})}
    ]
  });
  const parsed = JSON.parse(response.choices[0].message.content);
  if (!Array.isArray(parsed.questions) || parsed.questions.length < 3 || !parsed.questions.every(q => typeof q === 'string' && q.trim().length >= 8)) throw new Error('Invalid questions');
  if (!parsed.draft || typeof parsed.draft !== 'object' || Array.isArray(parsed.draft)) throw new Error('Invalid draft');
  const draft = normalizeFields(parsed.draft);
  // Never let AI overwrite facts already confirmed by the user.
  for (const key of FIELDS) if (fields[key]) draft[key] = fields[key];
  return {questions: parsed.questions.slice(0,5).map(clean), draft};
}

app.get('/api/health', (_req,res) => res.json({ok:true}));
app.get('/api/tasks', (req,res) => {
  const owner = clean(req.query.owner);
  const rows = owner ? db.prepare('SELECT * FROM tasks WHERE owner = ? ORDER BY id DESC').all(owner) : db.prepare("SELECT * FROM tasks WHERE status = 'published' ORDER BY id DESC").all();
  res.json(rows.map(taskFromRow));
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
  let questions, fields = task.fields, source = 'ai', notice = null;
  try { const result = await askAI(task.idea, task.fields); questions = result.questions; fields = result.draft; }
  catch { source = 'template'; questions = templates(task.fields); notice = 'ИИ сейчас недоступен. Используются шаблонные вопросы.'; }
  db.prepare('UPDATE tasks SET questions = ?, fields = ?, question_source = ? WHERE id = ?').run(JSON.stringify(questions),JSON.stringify(fields),source,task.id);
  res.json({task:getTask(task.id),notice});
});
app.put('/api/tasks/:id', (req,res) => {
  const task = getTask(req.params.id);
  if (!task) return res.status(404).json({error:'Задача не найдена'});
  if (task.status !== 'draft') return res.status(409).json({error:'Редактирование опубликованной задачи появится на следующем этапе'});
  if (req.body.owner !== task.owner) return res.status(403).json({error:'Выбран другой профиль бизнеса'});
  const fields = normalizeFields(req.body.fields);
  const answers = Array.isArray(req.body.answers) ? req.body.answers.slice(0,5).map(clean) : [];
  db.prepare('UPDATE tasks SET fields = ?, answers = ? WHERE id = ?').run(JSON.stringify(fields),JSON.stringify(answers),task.id);
  res.json(getTask(task.id));
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
