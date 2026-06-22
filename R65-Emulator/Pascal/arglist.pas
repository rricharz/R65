{ display argument list            }
{ test program for argument parser }

{$U+}

program ARGLIST;
uses syslib, arglib, writelib;

var string: array[15] of char;
    i, val: integer;

begin
  if ARGTYPE[_carg]=chr(0) then begin
    writeln('Usage: ARGLIST arguments');
    exit;
  end;
  while ARGTYPE[_carg]<>chr(0) do begin
    if _carg < 10 then write(' ');
    write(_carg, ': ', ARGTYPE[_carg],' ');
    case ARGTYPE[_carg] of
    's','q':  begin
                for i:=0 to 15 do
                  string[i]:=ARGLISTS[2*_carg+i];
                _carg:=_carg+8;
                write(trim16(string));
              end;
    'i','d':  begin
                val:=ARGLIST[_carg];
                _carg:=succ(_carg);
                write(val);
              end
    end {case};
    writeln;
  end
end.
