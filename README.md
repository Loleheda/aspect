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
    // Проверка параметра поиска на равенство пустой строке 
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
##### Файл `Task2_some.sql`. В этом файле сравнение характеристик и значаний характеристик происходит по классической выборке JSONB
```
SELECT c_gr.char_code, c_gr.char_code_start_position, c_gr.char_code_end_position, c_gr.char_value_name, c_gr.char_value_name_group_position, c_gr.comment, (c_gr.characteristics @> c_it.characteristics) as item_has_char 
FROM public.cfg_group_char_attributes as c_gr 
CROSS JOIN public.cfg_item_char_attributes as c_it
WHERE NOT(c_it.characteristic_values @> c_gr.characteristic_values) AND  
	c_gr.cfg_item_group = '9998b5ec-2722-4d75-bb21-34a297f04490' AND
	c_it.cfg_item = 'fe62c993-70eb-48d2-9fa8-ae5210103dd9'
```
##### Файл `Task2_full.sql`. В этом файле сравнение характеристик и значаний характеристик происходит при помощи итерации этих значаний
```
-- Создание запроса сравнения cfg_group_char_attributes.characteristics и cfg_item_characteristics.characteristic
CREATE OR REPLACE FUNCTION select_item_has_char(IN id_item_group text, IN id_item text) RETURNS TABLE(cfg_item_group jsonb, item_has_char boolean) AS
$$
DECLARE
	characteristic_group RECORD;
BEGIN
	FOR characteristic_group in SELECT jsonb_path_query(characteristics, '$.id[*]'::jsonpath) as characteristics_item
		FROM cfg_item_char_attributes
		WHERE cfg_item=id_item
	LOOP
		RETURN QUERY SELECT cfg_g.characteristics, (cfg_g.characteristics @> (CONCAT('[{"id":', characteristic_group.characteristics_item, '}]'))::jsonb) as item_has_char FROM cfg_group_char_attributes as cfg_g WHERE cfg_g.cfg_item_group=id_item_group ORDER BY item_has_char;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Создание запроса сравения cfg_group_char_attributes.characteristic_values и cfg_item_char_attributes.characteristic_values
CREATE OR REPLACE FUNCTION result_select(IN id_item_group text, IN id_item text) RETURNS TABLE(char_code character varying, char_code_start_position int, char_code_end_position int, char_value_name character varying, char_value_name_group_position int, comment text, item_has_char boolean) AS 
$$

DECLARE
	ids_item RECORD;
BEGIN
	FOR ids_item in SELECT DISTINCT jsonb_path_query(characteristic_values, '$.id[*]'::jsonpath) as item
		FROM cfg_item_char_attributes
		WHERE cfg_item=id_item
	LOOP
		RETURN QUERY 
		SELECT c_gr.char_code, c_gr.char_code_start_position, c_gr.char_code_end_position, c_gr.char_value_name, c_gr.char_value_name_group_position, c_gr.comment, select_item_has_char.item_has_char FROM cfg_group_char_attributes AS c_gr
		
		INNER JOIN select_item_has_char(id_item_group, id_item)
		ON select_item_has_char.cfg_item_group = c_gr.characteristics
		WHERE NOT(c_gr.characteristic_values @> (CONCAT('[{"id":', ids_item.item, '}]'))::jsonb) 
			AND c_gr.cfg_item_group=id_item_group;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT DISTINCT * FROM result_select('9998b5ec-2722-4d75-bb21-34a297f04490', 'a03f74b3-29f2-4021-a900-9675910221fc')
```
___
# Спасибо за просмотр