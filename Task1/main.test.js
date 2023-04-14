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