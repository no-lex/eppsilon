function getvar_savefile, savefile, varname, pointer_return=pointer_return, names = names, return_size = return_size
  if file_test(savefile) eq 0 then begin
    print, 'getvar_savefile: file ' + string(savefile) + ' not found'
    return, 0
  endif
  
  savefile_obj = obj_new('idl_savefile', savefile)
  if arg_present(names) then names = file_obj->names()
  
  if n_elements(varname) ne 0 then begin
    if keyword_set(return_size) then begin
      size = file_obj->size(varname)
      obj_destroy, savefile_obj
      
      return, size
    endif else begin
      savefile_obj->Restore, varname
      obj_destroy, savefile_obj
      
      IF Keyword_Set(pointer_return) THEN p=execute(varname+'=Ptr_new('+varname+')')
      q=execute('return,'+varname)
    endelse
  endif else begin
    obj_destroy, savefile_obj
    return, 0
  endelse
end

