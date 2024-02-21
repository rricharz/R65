{ ioption - check and set option }

func option(opt:char):boolean;
var i,dummy,savecarg:integer;
    options:array[15] of char;
    default:boolean;
begin
  savecarg:=carg; { save for next call to option }
  agetstring(options,default,dummy,dummy);
  option:=false;
  if not default then begin
    if options[0]<>'/' then argerror(103);
    for i:=1 to 15 do
      if options[i]=opt then option:=true;
  end;
  carg:=savecarg;
end;