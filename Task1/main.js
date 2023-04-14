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