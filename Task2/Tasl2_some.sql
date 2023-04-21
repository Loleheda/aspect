SELECT c_gr.char_code, c_gr.char_code_start_position, c_gr.char_code_end_position, c_gr.char_value_name, c_gr.char_value_name_group_position, c_gr.comment, (c_gr.characteristics @> c_it.characteristics) as item_has_char 
FROM public.cfg_group_char_attributes as c_gr 
CROSS JOIN public.cfg_item_char_attributes as c_it
WHERE NOT(c_it.characteristic_values @> c_gr.characteristic_values) AND  
	c_gr.cfg_item_group = '9998b5ec-2722-4d75-bb21-34a297f04490' AND
	c_it.cfg_item = 'fe62c993-70eb-48d2-9fa8-ae5210103dd9'