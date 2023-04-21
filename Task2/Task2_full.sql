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