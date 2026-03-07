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
  for i:=0 to 15 do FILNM1[i]:=name[i];
  FILCYC:=0; FILDRV:=0;
  run
end;

{       * main *              }

begin {main}
  {get file name to be able to delete :Q}
  cyclus:=0; drive:=1;
  _agetstring(name,default,cyclus,drive);

  runprog('COMPILE1:R      ');

  cyclus:=FILCYC;
  {make sure that load runs same cyclus}
  ARGTYPE[8]:='i';
  ARGLIST[8]:=cyclus;

  if RUNERR=0 then
    runprog('COMPILE2:R      ');

  _asetfile(name,cyclus,drive,'Q');
  call(adelete);

  RUNERR:=0;
end.

