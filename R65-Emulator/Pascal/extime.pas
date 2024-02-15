{ extime - measure execution time of a }
{ pascal program }

program extime;
uses syslib,arglib,timelib,mathlib;

var cyclus,drive,i: integer;
    etime: real;
    name: array[15] of char;
    default: boolean;

begin
  write('extime start - ');
  prttime(output); writeln;
  if argtype[carg]<>'s' then begin
    write('Usage: extime program,drive');
    writeln(' arguments of program');
    abort;
  end;
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,'R');
  for i:=carg to 31 do begin
    argtype[i-carg]:=argtype[i];
    arglist[i-carg]:=arglist[i];
  end;
  gettime; { start time measurement }
  run;
  etime:=timediff;
  writeln;
  write('extime stop - ');;
  prttime(output); writeln;
  writeln('Execution time: ');
  writefix(output,2,etime)
  writeln(' s');
end.
