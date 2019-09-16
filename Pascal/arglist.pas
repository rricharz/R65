{ display argument list }

program arglist;
uses syslib,arglib;

var string: array[15] of char;
    i, val: integer;

begin
  if argtype[carg]=chr(0) then
    writeln('Usage: arglist arguments');
  while argtype[carg]<>chr(0) do begin
    write(carg,': ',argtype[carg],' ');
    case argtype[carg] of
    's': begin
           for i:=0 to 15 do
             string[i]:=arglists[2*carg+i];
           carg:=carg+8;
           prtext16(output,string);
         end;
    'i': begin val:=arglist[carg];
           carg:=succ(carg);
           write(val);
         end;
    'd': begin
           carg:= succ(carg);
         end
    end;
    writeln;
  end
end.