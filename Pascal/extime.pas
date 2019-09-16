{ extime - measure execution time of a }
{ pascal program }

program extime;
uses syslib,arglib,timelib;

var cyclus,drive,i,etime: integer;
    name: array[15] of char;
    default: boolean;

begin
  if argtype[carg]<>'s' then begin
    write('Usage: extime program,drive');
    writeln(' arguments of program');
    abort;
  end;
  write('extime start - ');
  prttime(output); writeln;
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
  writeln('Execution time: ',etime,'s');
end.
