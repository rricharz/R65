{ ioption - check and set option }

func option(opt:char):boolean;
var i,dummy,savecarg:integer;
    options:array[15] of char;
    default:boolean;
begin
  savecarg:=_carg; { save for next call to option }
  _agetstring(options,default,dummy,dummy);
  option:=false;
  if not default then begin
    if options[0]<>'/' then _argerror(103);
    for i:=1 to 15 do
      if options[i]=opt then option:=true;
  end;
  _carg:=savecarg;
end;