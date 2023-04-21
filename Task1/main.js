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