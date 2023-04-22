# Здравствуйте
### Для быстрой проверки заданий предлагаю Вам краткую экскурсию по ним
___
#### Задание №1 (Расположено в папке "Task1")
##### Файл `package.json`
```
{
  "name": "task1",
  "version": "1.0.0",
  "description": "",
  "main": "main.js",
  "scripts": {
    "test": "jest"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "pg": "^8.10.0"
  },
  "devDependencies": {
    "jest": "^29.5.0"
  }
}
```
##### Файл `db.js`
```
const Pool = require('pg').Pool
const pool = new Pool({
    user: 'postgres',
    password: 'admin',
    host: 'localhost',
    port: 5432,
    database: 'Task1'
})

module.exports = pool
```
##### Файл `main.js`
```
const db = require('./db');

async function searchTables (table, argSearch) {
    // Проверка на валидность наименования таблицы
    const validTables = new Set(['table1', 'table2', 'table3'])
    if (!validTables.has(table)) {
        throw new Error(`ERROR: The entered table name does not match the table in the database`)
    };
    // Проверка параметра поиска на валидность 
    const notValidArgsSearch = new Set(['', null, 'null', undefined, 'undefined'])
    if (notValidArgsSearch.has(argSearch)) {
        throw new Error(`ERROR: No search string entered`)
    };
    let data = [];
    const query = await db.query(`
    
        WITH searsh_elements AS (
            SELECT * FROM public.${table} 
            WHERE lower(name) LIKE lower('%${argSearch}%') 
                OR lower(decription) LIKE lower('%${argSearch}%') 
            ORDER BY name, decription
            LIMIT 20
        ) 
        
        SELECT (
            SELECT COUNT(*)::int FROM public.${table} 
            WHERE lower(name) LIKE lower('%${argSearch}%') 
                OR lower(decription) LIKE lower('%${argSearch}%')
            ), 
            (SELECT json_agg(searsh_elements) AS data FROM searsh_elements)

    `); 
    return {data: query.rows[0]['data'], count: query.rows[0]['count']};
}

module.exports = searchTables
```
##### Файл `main.test.js`. Для запуска тестов необходимо: 
##### 1. Открыть терминал 
##### 2. Перейти в папку `Task1` 
##### 2. Ввести команду `npm test`
```
const searchTables = require('./main');
const db = require('./db');

test(
    'Проверка на пустой результат',
    async () => {
        const result = await searchTables('table1', 'qqqq');
        expect(result.count).toBeTruthy();
    }
);

test(
    'Проверка на равенство результирующего списка и количества найденных записей',
    async () => {
        const result = await searchTables('table2', 'jo');
        expect(result.data).toHaveLength(result.count);
    }
    );

test(
    'Проверка на то, что результирующий список меньше количества найденных записей',
    async () => {
        const result = await searchTables('table1', 'a');
        expect(result.count).toBeGreaterThan(result.data.length);
    }
    );

test(
    'Проверка на верность результата',
    async () => {
        const table = 'table1'
        const argSearch = 'jo'
        const query = await db.query(`SELECT * FROM ${table} WHERE lower(name) LIKE lower('%${argSearch}%') OR lower(decription) LIKE lower('%${argSearch}%') ORDER BY name, decription LIMIT 20`);
        const result = await searchTables(table, argSearch);
        expect(query.rows).toEqual(result.data);
    }
);

test(
    'Проверка на то, что в результате не Undefined',
    async () => {
        const result = await searchTables('table1', 'jo');
        expect(result.count).not.toBeUndefined();
    }
);
```
___
#### Задание №2 (Расположено в папке "Task2")
##### Файл `Task2_version1.sql`. Первая версия выполнения задания
```
SELECT c_gr.char_code, c_gr.char_code_start_position, c_gr.char_code_end_position, c_gr.char_value_name, c_gr.char_value_name_group_position, c_gr.comment, 
	bool_item_has_char.item_has_char
FROM public.cfg_group_char_attributes as c_gr 
JOIN public.cfg_item_char_attributes as c_it
ON c_gr.characteristic_values != c_it.characteristic_values 
JOIN (SELECT c_gr.id, (jsonb_build_object('id', arr.item_object['id']) in (
		SELECT jsonb_build_object('id', characteristic) 
		FROM cfg_item_characteristics 
		WHERE cfg_item='43cbc45d-d939-4fd3-b673-8354a562fe51')) AS item_has_char
	FROM cfg_group_char_attributes as c_gr,
	jsonb_array_elements(c_gr.characteristics) with ordinality arr(item_object, position)
	WHERE c_gr.cfg_item_group = 'c52b39e8-bbc6-4e90-8bd4-55bba9fa8948') AS bool_item_has_char
ON bool_item_has_char.id = c_gr.id
WHERE c_gr.cfg_item_group = 'c52b39e8-bbc6-4e90-8bd4-55bba9fa8948' AND
	c_it.cfg_item = '43cbc45d-d939-4fd3-b673-8354a562fe51'
```
##### Файл `Task2_version2.sql`. Вторая версия выполнения задания
```
SELECT DISTINCT c_gr.char_code, c_gr.char_code_start_position, c_gr.char_code_end_position, c_gr.char_value_name, 
	c_gr.char_value_name_group_position, c_gr.comment, 
	jsonb_build_object('id', arr.item_object['id']) in (
		SELECT DISTINCT jsonb_build_object('id', characteristic)
		FROM cfg_item_characteristics
		WHERE cfg_item = '43cbc45d-d939-4fd3-b673-8354a562fe51') AS item_has_char
FROM cfg_group_char_attributes as c_gr,
jsonb_array_elements(c_gr.characteristics) with ordinality arr(item_object, position)
CROSS JOIN public.cfg_item_char_attributes as c_it
WHERE NOT(c_gr.characteristic_values @> c_it.characteristic_values)
	AND c_gr.cfg_item_group='9998b5ec-2722-4d75-bb21-34a297f04490'
	AND c_it.cfg_item = '43cbc45d-d939-4fd3-b673-8354a562fe51'
```
___
# Спасибо за просмотр