export const radicals = [
  { character: '木', pinyin: 'mù', meaning: 'дерево' },
  { character: '水', pinyin: 'shuǐ', meaning: 'вода' },
  { character: '火', pinyin: 'huǒ', meaning: 'огонь' },
  { character: '土', pinyin: 'tǔ', meaning: 'земля' },
  { character: '日', pinyin: 'rì', meaning: 'солнце' },
  { character: '月', pinyin: 'yuè', meaning: 'луна' },
  { character: '人', pinyin: 'rén', meaning: 'человек' },
  { character: '心', pinyin: 'xīn', meaning: 'сердце' },
  { character: '口', pinyin: 'kǒu', meaning: 'рот' },
  { character: '手', pinyin: 'shǒu', meaning: 'рука' },
  { character: '目', pinyin: 'mù', meaning: 'глаз' },
  { character: '田', pinyin: 'tián', meaning: 'поле' },
  { character: '山', pinyin: 'shān', meaning: 'гора' },
  { character: '石', pinyin: 'shí', meaning: 'камень' },
  { character: '金', pinyin: 'jīn', meaning: 'металл' },
  { character: '雨', pinyin: 'yǔ', meaning: 'дождь' },
];

export const recipes = [
  {
    radicals: ['木', '木'],
    result: '林',
    pinyin: 'lín',
    meaning: 'лес',
    description: 'Два дерева образуют лес'
  },
  {
    radicals: ['木', '木', '木'],
    result: '森',
    pinyin: 'sēn',
    meaning: 'чаща',
    description: 'Три дерева - густой лес'
  },
  {
    radicals: ['日', '月'],
    result: '明',
    pinyin: 'míng',
    meaning: 'яркий',
    description: 'Солнце и луна дают свет'
  },
  {
    radicals: ['人', '木'],
    result: '休',
    pinyin: 'xiū',
    meaning: 'отдыхать',
    description: 'Человек у дерева отдыхает'
  },
  {
    radicals: ['木', '火'],
    result: '焚',
    pinyin: 'fén',
    meaning: 'сжигать',
    description: 'Огонь сжигает дерево'
  },
  {
    radicals: ['水', '目'],
    result: '泪',
    pinyin: 'lèi',
    meaning: 'слеза',
    description: 'Вода из глаз - слёзы'
  },
  {
    radicals: ['心', '土'],
    result: '志',
    pinyin: 'zhì',
    meaning: 'воля',
    description: 'Сердце на земле - твёрдая воля'
  },
  {
    radicals: ['人', '人'],
    result: '从',
    pinyin: 'cóng',
    meaning: 'следовать',
    description: 'Один человек следует за другим'
  },
  {
    radicals: ['口', '口'],
    result: '回',
    pinyin: 'huí',
    meaning: 'возвращаться',
    description: 'Циклическое движение'
  },
  {
    radicals: ['日', '木'],
    result: '東',
    pinyin: 'dōng',
    meaning: 'восток',
    description: 'Солнце восходит за деревьями'
  },
  {
    radicals: ['山', '石'],
    result: '岩',
    pinyin: 'yán',
    meaning: 'скала',
    description: 'Каменная гора - скала'
  },
  {
    radicals: ['雨', '田'],
    result: '雷',
    pinyin: 'léi',
    meaning: 'гром',
    description: 'Дождь над полем с громом'
  },
  {
    radicals: ['金', '土'],
    result: '銅',
    pinyin: 'tóng',
    meaning: 'медь',
    description: 'Металл из земли'
  },
  {
    radicals: ['手', '目'],
    result: '看',
    pinyin: 'kàn',
    meaning: 'смотреть',
    description: 'Рука защищает глаза от солнца'
  },
];
