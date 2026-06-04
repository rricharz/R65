{ show FILNAM[.cy][,drive

  show a snapshot of the graphics canvas
  default for drive is one                }

program show;

uses syslib,arglib,filelib,plotlib;

const startcanvas = $700;
      sizecanvas  = 3304; { 224x118/8 }
      rdfile      = $e815;

mem   FILFLG=$da:   char&;
      filsa=$031a:  integer;
      filea=$031c:  integer;
      filsa1=$0331: integer;
      filtyp=$0300: char&;

var   cyclus,drive: integer;
      name:         array[15] of char;
      default:      boolean;

func haswildcard(nm1:array[15] of char): boolean;
var k:integer;
begin
  haswildcard:=false;
  for k:=0 to 15 do
    if (nm1[k]='*') or (nm1[k]='?') then
      haswildcard:=true;
end;

func splitted: boolean;
{ is video memory splitted }
mem numlin=$1789:integer&;
begin
  splitted := numlin <= 16;
end;

proc loadcanvas;
{ load the canvas from disk }
begin
  _asetfile(name,cyclus,drive,'I');
  FILFLG:=chr($40); { silent read }
  filsa:=startcanvas;
  filea:=startcanvas+sizecanvas;
  filsa1:=startcanvas;
  filtyp:='I';
  FILERR:=0;
  call(rdfile);
  if FILERR<>0 then
    writeln(INVVID,'File error ',FILERR shr 4,
      FILERR and 15,NORVID);
end;

begin
  cyclus:=0; drive:=1;
  _agetstring(name,default,cyclus,drive);
  if default then begin
    writeln(INVVID,'Usage: SHOW filename',NORVID);
    exit;
  end;
  if haswildcard(name) then begin
    writeln(INVVID,'Wild cards not allowed',NORVID);
    exit;
  end;

  _grinit; _fullview; _cleargr;
  loadcanvas;

end.
