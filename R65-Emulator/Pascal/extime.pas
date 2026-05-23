{ extime - measure execution time of a }
{ pascal program }

{$U+}

program extime;
uses syslib, arglib, timelib, mathlib, filelib;

var cyclus,drive,i: integer;
    etime: real;
    name: array[15] of char;
    default: boolean;

begin
  write('extime start - ');
  prttime(OUTPUT); writeln;
  if ARGTYPE[_carg]<>'s' then begin
    write('Usage: extime program,drive');
    writeln(' arguments of program');
    _abort;
  end;
  cyclus:=0; drive:=0;
  _agetstring(name,default,cyclus,drive);
  _asetfile(name,cyclus,drive,'R');
  for i:=_carg to 31 do begin
    ARGTYPE[i-_carg]:=ARGTYPE[i];
    ARGLIST[i-_carg]:=ARGLIST[i];
  end;
  gettime; { start time measurement }
  run;
  etime:=timediff;
  writeln;
  write('extime stop - ');;
  prttime(OUTPUT); writeln;
  writeln('Execution time: ',etime:2,' s');
end.
