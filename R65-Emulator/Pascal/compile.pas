{
        *****************
        * C O M P I L E *
        *****************

    Version 01/08/82 rricharz

R65 Pascal Pascal Compiler main compiler.
Calls compile1 and compile2

Usage:
compile filename [xx]
  where x     l: hard copy print
              r: index bound checking
  [] means not required                }

program compile;
uses syslib,arglib;

const adelete=$c80c; { exdos vector }

var cyclus,drive: integer;
    name: array[15] of char;
    default: boolean;

{       * runprog *           }

proc runprog(name: array[15] of char);

var i: integer;

begin
  for i:=0 to 15 do filnm1[i]:=name[i];
  filcy1:=0; fildrv:=0;
  run
end;

{       * main *              }

begin {main}

  {get file name to be able to delete :Q}
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);

  runprog('COMPILE1:R      ');

  cyclus:=filcyc;
  {make sure that load runs same cyclus}
  argtype[8]:='i';
  arglist[8]:=cyclus;

  if runerr=0 then
    runprog('COMPILE2:R      ');

  asetfile(name,cyclus,drive,'Q');
  call(adelete);

  runerr:=0;
end.

