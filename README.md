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
    if (true != (table == 'table1' || table == 'table2' || table == 'table3')) {
        throw new Error(`ERROR: The entered table name does not match the table in the database`)
    };
    // Проверка параметра поиска на равенство пустой строке 
    if (argSearch == '') {
        throw new Error(`ERROR: No search string entered`)
    };
    let data = [];
    const query = await db.query(`SELECT * FROM ${table} WHERE lower(name) LIKE lower('%${argSearch}%') OR lower(decription) LIKE lower('%${argSearch}%') ORDER BY name, decription`); 
    let count = query.rowCount;
    for (let i of query.rows) {
        if (data.length < 20){
            data.push(i);
        };
    };
    return {data: data, count: count};
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
##### Файл `Task2.sql`
```
-- Создание функции
-- Создание функции
CREATE OR REPLACE FUNCTION result_select(IN id_item_group text, IN id_item text) RETURNS TABLE(char_code text, char_code_start_position int, char_code_end_position int, char_value_name text, char_value_name_group_position int, comment text, item_has_char boolean) AS $$

	-- Создание WITH, для нахождения characteristic_values 
	WITH id_searth AS 
		(SELECT jsonb_path_query(characteristic_values::jsonb, '$.id[*]'::jsonpath) as id_characteristics_group FROM public.cfg_group_char_attributes
		WHERE cfg_item_group = id_item_group
		EXCEPT
		SELECT jsonb_path_query(characteristic_values::jsonb, '$.id[*]'::jsonpath) as id_characteristics_item FROM public.cfg_item_char_attributes 
		WHERE cfg_item = id_item)

	-- Вывод доп. атрибутов наборов значений характеристик группы изделий, отсутствующих в наборах значений характеристик изделия
	SELECT char_code, char_code_start_position, char_code_end_position, char_value_name, char_value_name_group_position, comment,
		-- Создание столбца item_has_char по первой характеристике группы
		(SELECT (SELECT (characteristics[0] -> 'id')::text FROM cfg_group_char_attributes WHERE id IN (SELECT id
		WHERE (public.cfg_group_char_attributes.characteristic_values[0] -> 'id' IN (SELECT * FROM id_searth) OR
			public.cfg_group_char_attributes.characteristic_values[1] -> 'id' IN (SELECT * FROM id_searth)) AND cfg_item_group = id_item_group)) 
			IN (SELECT DISTINCT characteristic::text FROM cfg_item_characteristics WHERE cfg_item = id_item)) 
	FROM public.cfg_group_char_attributes
	WHERE (public.cfg_group_char_attributes.characteristic_values[0] -> 'id' in (SELECT * FROM id_searth) OR
		public.cfg_group_char_attributes.characteristic_values[1] -> 'id' in (SELECT * FROM id_searth)) AND cfg_item_group = id_item_group
	-- Объединение 2-х запросов
	UNION
	-- Вывод второй характеристики группы, если она есть
	SELECT char_code, char_code_start_position, char_code_end_position, char_value_name, char_value_name_group_position, comment,
		(SELECT (SELECT (characteristics[1] -> 'id')::text FROM cfg_group_char_attributes WHERE id IN (SELECT id
		WHERE (public.cfg_group_char_attributes.characteristic_values[0] -> 'id' IN (SELECT * FROM id_searth) OR
			public.cfg_group_char_attributes.characteristic_values[1] -> 'id' IN (SELECT * FROM id_searth)) AND cfg_item_group = id_item_group)) 
			IN (SELECT DISTINCT characteristic::text FROM cfg_item_characteristics WHERE cfg_item = id_item)) 
	FROM public.cfg_group_char_attributes
	WHERE (public.cfg_group_char_attributes.characteristic_values[0] -> 'id' in (SELECT * FROM id_searth) OR
		public.cfg_group_char_attributes.characteristic_values[1] -> 'id' in (SELECT * FROM id_searth)) AND cfg_item_group = id_item_group
	
$$ LANGUAGE SQL;

-- Вызов функции
SELECT * FROM result_select('9998b5ec-2722-4d75-bb21-34a297f04490', 'fe62c993-70eb-48d2-9fa8-ae5210103dd9')
```
___
# Спасибо за просмотр