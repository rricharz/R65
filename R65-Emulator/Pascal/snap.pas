{ snap filnam[.cy][,drive

  take a snapshot of the graphics canvas
  default for drive is one
  the graphics canvas must be enabled      }

program snap;
uses syslib,arglib;

const startcanvas = $700;
      sizecanvas  = 3304; { 224x118/8 }
      wrfile      = $e81b;

mem   filerr=$db:   integer&;
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

proc savecanvas;
{ save the canvas on disk }
begin
  asetfile(name,cyclus,drive,'I');
  filsa:=startcanvas;
  filea:=startcanvas+sizecanvas;
  filsa1:=startcanvas;
  filtyp:='I';
  filerr:=0;
  call(wrfile);
  if filerr<>0 then
    writeln(invvid,'File error ',filerr shr 4,
      filerr and 15,norvid);
end;

begin
  if not splitted then begin
    writeln(invvid,'Video canvas not available',
       norvid);
    exit;
  end;

  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  if default then begin
    writeln(invvid,'Usage: snap filnam',norvid);
    exit;
  end;
  if haswildcard(name) then begin
    writeln(invvid,'Wild cards not allowed',norvid);
    exit;
  end;

  savecanvas;

end.