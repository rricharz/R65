{ display argument list            }
{ test program for argument parser }

{$U+}

program ARGLIST;
uses syslib, arglib, writelib, ftlib;

var string: array[15] of char;
    i, val: integer;
    line: cpnt;

proc decompose;
var name, value: cpnt;
    count: integer;
    done: boolean;
begin
  count := 0;
  name := _allocate(9);
  value := _allocate(17);
  repeat
    _nextparam(name, value, done);
    if not done then begin
      count := count + 1;
      writeln(count, ' ', name, ' ', value);
    end;
  until done;
end;

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
              end;
    'l':      begin
                line := cpnt($60);
                _carg := succ(_carg);
                writeln(line);
                decompose;
              end
    end {case};
    writeln;
  end
end.
