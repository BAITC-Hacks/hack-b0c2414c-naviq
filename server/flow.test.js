const {test} = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const {app, db} = require('./index');

test('AI uses Responses structured output and never invents draft facts', async () => {
  const aiPayload = {
    questions: [
      'Кто будет пользоваться результатом?',
      'Какие данные уже доступны команде?',
      'По какой метрике оценить успех?',
    ],
    questionFields: ['users', 'data', 'success'],
    draft: {
      title: '', topic: '', context: 'Хотим бота для поддержки клиентов',
      need: '', users: '', data: '', constraints: '', outcome: '',
      success: '', contact: '', format: '',
    },
  };
  let requestBody;
  const mockAI = http.createServer((req, res) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      requestBody = JSON.parse(body);
      res.writeHead(200, {'Content-Type': 'application/json'});
      res.end(JSON.stringify({
        id: 'resp_mock', object: 'response', created_at: 1,
        status: 'completed', model: 'gpt-4.1-mini',
        output: [{
          id: 'msg_mock', type: 'message', status: 'completed', role: 'assistant',
          content: [{type: 'output_text', annotations: [], text: JSON.stringify(aiPayload)}],
        }],
        usage: {input_tokens: 1, output_tokens: 1, total_tokens: 2},
      }));
    });
  });
  await new Promise(resolve => mockAI.listen(0, resolve));
  const previousKey = process.env.OPENAI_API_KEY;
  const previousBase = process.env.OPENAI_BASE_URL;
  process.env.OPENAI_API_KEY = 'test-key';
  process.env.OPENAI_BASE_URL = `http://127.0.0.1:${mockAI.address().port}/v1`;
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}`;
  let id;
  try {
    const created = await fetch(`${base}/api/tasks`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({owner: 'business-1', idea: aiPayload.draft.context}),
    });
    id = (await created.json()).id;
    const response = await fetch(`${base}/api/tasks/${id}/questions`, {
      method: 'POST', headers: {'Content-Type': 'application/json'}, body: '{}',
    });
    const result = await response.json();
    assert.equal(response.status, 200);
    assert.equal(result.task.question_source, 'ai');
    assert.equal(result.notice, null);
    assert.deepEqual(result.task.questions, aiPayload.questions);
    assert.equal(result.task.fields.context, aiPayload.draft.context);
    assert.equal(result.task.fields.success, '');
    assert.equal(requestBody.text.format.type, 'json_schema');
    assert.equal(requestBody.text.format.strict, true);
  } finally {
    if (id) db.prepare('DELETE FROM tasks WHERE id = ?').run(id);
    if (previousKey === undefined) delete process.env.OPENAI_API_KEY;
    else process.env.OPENAI_API_KEY = previousKey;
    if (previousBase === undefined) delete process.env.OPENAI_BASE_URL;
    else process.env.OPENAI_BASE_URL = previousBase;
    await Promise.all([
      new Promise(resolve => server.close(resolve)),
      new Promise(resolve => mockAI.close(resolve)),
    ]);
  }
});

test('draft, questions, manual edit and confirmed publication', async () => {
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (method, path, body) => {
    const response = await fetch(base + path, {method, headers:{'Content-Type':'application/json'}, body:body ? JSON.stringify(body) : undefined});
    return {status:response.status, data:await response.json()};
  };
  let id;
  try {
    const created = await call('POST','/api/tasks',{owner:'test-business',idea:'Нужен бот для ответов на вопросы клиентов'});
    assert.equal(created.status,201); id = created.data.id;
    const questioned = await call('POST',`/api/tasks/${id}/questions`,{});
    assert.equal(questioned.status,200);
    assert.ok(questioned.data.task.questions.length >= 3);
    const fields = {...questioned.data.task.fields,title:'Бот поддержки',need:'Отвечать на частые вопросы'};
    const saved = await call('PUT',`/api/tasks/${id}`,{owner:'test-business',fields,answers:['Клиенты','FAQ','За месяц']});
    assert.equal(saved.status,200);
    assert.equal(saved.data.fields.title,'Бот поддержки');
    const denied = await call('POST',`/api/tasks/${id}/publish`,{owner:'test-business'});
    assert.equal(denied.status,400);
    const published = await call('POST',`/api/tasks/${id}/publish`,{owner:'test-business',confirm:true});
    assert.equal(published.status,200);
    assert.equal(published.data.status,'published');
    const unconfirmedEdit = await call('PUT',`/api/tasks/${id}`,{owner:'test-business',fields:{...fields,data:'Обезличенный FAQ'}});
    assert.equal(unconfirmedEdit.status,400);
    const confirmedEdit = await call('PUT',`/api/tasks/${id}`,{owner:'test-business',confirm:true,fields:{...fields,data:'Обезличенный FAQ'}});
    assert.equal(confirmedEdit.status,200);
    assert.equal(confirmedEdit.data.rating.score,40);
    const catalog = await call('GET','/api/tasks');
    assert.ok(catalog.data.some(task => task.id === id));
  } finally {
    if (id) db.prepare('DELETE FROM tasks WHERE id = ?').run(id);
    await new Promise(resolve => server.close(resolve));
  }
});

test('catalog retains low score tasks and owner manually selects multiple teams', async () => {
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (method,path,body) => {
    const response = await fetch(base+path,{method,headers:{'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined});
    return {status:response.status,data:await response.json()};
  };
  let id;
  try {
    const created=await call('POST','/api/tasks',{owner:'business-1',idea:'Нужна простая карта мероприятий для гостей города'});
    id=created.data.id;
    const fields={...created.data.fields,title:'Карта мероприятий',topic:'Веб',need:'Помочь гостям найти события'};
    assert.equal((await call('PUT',`/api/tasks/${id}`,{owner:'business-1',fields})).data.rating.score,20);
    const published=await call('POST',`/api/tasks/${id}/publish`,{owner:'business-1',confirm:true});
    assert.equal(published.status,200);
    assert.equal(published.data.rating.level,'Черновик');
    const catalog=await call('GET','/api/tasks');
    assert.ok(catalog.data.some(task=>task.id===id));
    assert.ok(catalog.data.every((task,index,all)=>index===0||all[index-1].rating.score>=task.rating.score));
    const proposalIds=[];
    for(const teamId of ['team-1','team-2']) {
      const proposal=await call('POST',`/api/tasks/${id}/proposals`,{team_id:teamId,idea:'Сделаем карту с фильтрами',plan:'Соберём прототип и проверим сценарий',timeline:'Три недели'});
      assert.equal(proposal.status,201); proposalIds.push(proposal.data.id);
    }
    const denied=await call('POST',`/api/proposals/${proposalIds[0]}/decision`,{owner:'business-2',decision:'selected'});
    assert.equal(denied.status,403);
    for(const proposalId of proposalIds) assert.equal((await call('POST',`/api/proposals/${proposalId}/decision`,{owner:'business-1',decision:'selected'})).data.decision,'selected');
    const inbox=await call('GET',`/api/tasks/${id}/proposals?owner=business-1`);
    assert.equal(inbox.data.filter(p=>p.decision==='selected').length,2);
  } finally {
    if(id){db.prepare('DELETE FROM proposals WHERE task_id = ?').run(id);db.prepare('DELETE FROM tasks WHERE id = ?').run(id);}
    await new Promise(resolve=>server.close(resolve));
  }
});
