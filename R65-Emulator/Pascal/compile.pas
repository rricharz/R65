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
uses syslib;

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
  runprog('COMPILE1:R      ');
  if runerr=0 then
    runprog('COMPILE2:R      ');
end.

