const {test} = require('node:test');
const assert = require('node:assert/strict');
const {rate} = require('./rating');

test('rating ignores placeholders and needs measurable success criteria', () => {
  const fields={context:'Сейчас заявки идут по почте',need:'Нужна единая панель',data:'не знаю',outcome:'Рабочая панель заявок',success:'удобно',constraints:'Без платных сервисов',users:'Операторы',contact:'Демо-куратор',format:'Раз в неделю онлайн'};
  assert.equal(rate(fields).score,65);
  fields.data='Обезличенный экспорт 200 заявок';
  fields.success='Заявка обрабатывается не более 2 минут';
  assert.equal(rate(fields).score,100);
});
