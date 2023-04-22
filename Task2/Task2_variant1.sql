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