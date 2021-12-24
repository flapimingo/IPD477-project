
clear;

paramList = {'a','b','c',{ {'key','value1','another',3}, {'key','value2','another',4}}};

val1 = get_parameter_in_context(paramList, 'key','value1','another');
val2 = get_parameter_in_context(paramList, 'key','value2','another');

paramList = set_parameter_in_context(paramList, 'key','value1','another',8);
paramList = set_parameter_in_context(paramList, 'key','value2','another',9);

val1
val2
paramList

