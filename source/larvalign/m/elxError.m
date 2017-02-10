function elxErrorMsg=elxError(cmdout)
idx = strfind(cmdout,'Description: ');
elxErrorMsg = strrep(cmdout(idx:end), '\', '/'); 
end