const criteria = [
  {key:'context', label:'Контекст и потребность', points:20, fields:['context','need']},
  {key:'data', label:'Данные и материалы', points:20, fields:['data']},
  {key:'outcome', label:'Ожидаемый результат', points:15, fields:['outcome']},
  {key:'success', label:'Измеримые критерии успеха', points:15, fields:['success']},
  {key:'constraints', label:'Ограничения', points:10, fields:['constraints']},
  {key:'users', label:'Пользователи', points:10, fields:['users']},
  {key:'contact', label:'Контакт и формат', points:10, fields:['contact','format']},
];
const empty = /^(нет|не знаю|неизвестно|нужно уточнить|пока нет|любые|любой|что-нибудь|тест|test|n\/a|[-–—.?\s]+)$/iu;
function meaningful(value) {
  const text = typeof value === 'string' ? value.trim() : '';
  return text.length >= 4 && !empty.test(text) && /[\p{L}\p{N}]{3,}/u.test(text);
}
function measurable(value) {
  return meaningful(value) && /\d|%|процент|не менее|не более|до \S+ (секунд|минут|час|дн|недел)|за \d|количеств|доля|время ответа|конверси|точност/iu.test(value);
}
function rate(fields) {
  const breakdown = criteria.map(item => {
    const filled = item.fields.every(key => key === 'success' ? measurable(fields[key]) : meaningful(fields[key]));
    return {...item, earned:filled ? item.points : 0,
      advice:filled ? null : `Дополните: ${item.fields.map(key => ({context:'контекст',need:'потребность',data:'данные и материалы',outcome:'ожидаемый результат',success:'измеримые критерии успеха',constraints:'ограничения',users:'пользователи',contact:'контакт',format:'формат связи'})[key]).join(' и ')}.`};
  });
  const score = breakdown.reduce((sum,item) => sum + item.earned,0);
  const level = score < 40 ? 'Черновик' : score < 70 ? 'Рабочая' : score < 90 ? 'Готовая' : 'Приоритетная';
  return {score,level,breakdown,advice:breakdown.filter(item=>!item.earned).map(item=>item.advice)};
}
module.exports = {rate,meaningful};
