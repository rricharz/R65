{ paint - paint in a graphics canvas
  usage: paint filename[.cyclus][,drive]

  Paint with following keys:
    right arrow    move cursor right
    left arror     move cursor left
    up arrow       move cursor up
    down arrow     move cursor down
    p              paint a dot at cursor position
    M              move start for draw to cursor pos
    D              draw a line
    R              draw a rectangle
    U              undo last operation
    S              start drawing a string
    esc            stop drawing a string
    W              write canvas to disk
    Q              write canvas to disk and quit
    K              kill program without writing to disk

  2024 rricharz                                   }

program paint;
uses syslib,arglib,wildlib,plotlib;

const startcanvas = $700;
      sizecanvas  = 3304; { 224x118/8 }
      rdfile      = $e815;
      wrfile      = $e81b;

mem   filflg=$da:   char&;
      filerr=$db:   integer&;
      filsa=$031a:  integer;
      filea=$031c:  integer;
      filsa1=$0331: integer;
      filtyp=$0300: char&;

var cyclus,drive:integer;
    name:array[15] of char;

proc forcesubtype(subtype:char);
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
    (name[i]=' ') or (i>=14);
  name[i]:=':';
  name[i+1]:=subtype;
end;

proc loadcanvas;
var entry: integer;
    last,found,default:  boolean;
begin
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  if default then begin
    write('Usage: paint filename[.cyclus][,drive]');
    abort;
  end;
  { check whether file exists, wildcards allowed }
  entry:=0;
  forcesubtype('I');
  findentry(name,drive,entry,found,last);
  if (not found) or last then exit;
  asetfile(name,cyclus,drive,'I');
  filflg:=chr(0);
  filsa:=startcanvas;
  filea:=startcanvas+sizecanvas;
  filsa1:=startcanvas;
  filtyp:='I';
  filerr:=0;
  call(rdfile);
  writeln;
  if filerr<>0 then
    writeln(invvid,'File error ',filerr shr 4,
      filerr and 15,norvid);
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
  grinit;  cleargr; splitview;
  loadcanvas;
  savecanvas;
end.