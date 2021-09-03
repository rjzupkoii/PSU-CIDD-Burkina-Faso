function [result] = yesno(value)
    result = 'yes';
    if value == 0; result = 'no'; end
end