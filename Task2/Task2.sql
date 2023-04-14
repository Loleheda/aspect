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