{ display argument list }

program ARGLIST;
uses syslib, arglib;

var string: array[15] of char;
    i, val: integer;

begin
  if ARGTYPE[_carg]=chr(0) then
    writeln('Usage: ARGLIST arguments');
  while ARGTYPE[_carg]<>chr(0) do begin
    if _carg < 10 then write(' ');
    write(_carg, ': ', ARGTYPE[_carg],' ');
    case ARGTYPE[_carg] of
    's': begin
           for i:=0 to 15 do
             string[i]:=ARGLISTS[2*_carg+i];
           _carg:=_carg+8;
           _prtext16(OUTPUT,string);
         end;
    'i': begin val:=ARGLIST[_carg];
           _carg:=succ(_carg);
           write(val);
         end;
    'd': begin
           _carg:= succ(_carg);
           write(val);
         end
    end;
    writeln;
  end
end.
