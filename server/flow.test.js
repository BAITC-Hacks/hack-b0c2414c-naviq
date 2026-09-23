const {test} = require('node:test');
const assert = require('node:assert/strict');
const {app, db} = require('./index');

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
    const catalog = await call('GET','/api/tasks');
    assert.ok(catalog.data.some(task => task.id === id));
  } finally {
    if (id) db.prepare('DELETE FROM tasks WHERE id = ?').run(id);
    await new Promise(resolve => server.close(resolve));
  }
});
