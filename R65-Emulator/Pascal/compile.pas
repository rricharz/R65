{        *****************        }
{        * C O M P I L E *        }
{        *****************        }

{ this version tests whether object file exists }

program compile;
uses syslib,arglib, filelib;

const adelete=$c80c; { exdos vector }

var cyclus,drive: integer;
    name: array[15] of char;
    default: boolean;

{       * runprog *           }

proc runprog(name: array[15] of char);
var i: integer;
begin
  for i:=0 to 15 do FILNM1[i]:=name[i];
  FILCY1:=0; FILCYC:=0; FILDRV:=0;
  run
end;

{       * main *              }

begin {main}
  {get file name to be able to delete :Q}
  cyclus := 0;
        drive := 1;
  _agetstring(name,default,cyclus,drive);

  { check versions }
        RUNERR := 0;
  runprog('LASTVERS:R      ');
        if RUNERR <> 0 then exit;

  runprog('COMPILE1:R      ');
  cyclus := FILCYC;
  {make sure that load runs same cyclus}
  ARGTYPE[8] := 'i';
  ARGLIST[8] := cyclus;

  if RUNERR = 0 then begin
    runprog('COMPILE2:R      ');
  end;

  _asetfile(name,cyclus,drive,'Q');
  call(adelete);
  RUNERR:=0;
end.

