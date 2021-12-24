
function newPath = expand_path(oldPath)
	global SABRE_BASE_DIR;

	sabreDir = regexprep(SABRE_BASE_DIR, '\\', '/');
	oldPath = regexprep(oldPath,'\\', '/');

	newPath = regexprep(oldPath,'^sabre:', sabreDir);


