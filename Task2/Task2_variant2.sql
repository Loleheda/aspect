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