program sprites;
uses syslib,strlib,striolib,plotlib;

{$R+}
{$U+}

const NSPRITES  = 4;
      NASPRITES = 16;  { 4 * NSPRITES }

var sprites: array[NASPRITES] of integer;

proc readfile;
var i, cyclus, drive: integer;
    f:file;
begin
  cyclus := 0;
  drive  := 1;
  _strfio('SPRITES:B', cyclus, drive);
  openr(f);
  for i:= 0 to NASPRITES - 1 do begin
    read(@f,sprites[i]);
    write(sprites[i]:8);
    sprites[i] := not sprites[i];
    if _mod(i,4) = 3 then writeln;
  end;
  close(f);
end;

proc showsprite(x, y, index: integer);
var base: integer;
begin
  base := 4 * index;
  _plotmap(x,     y,     sprites[base + 2]);
  _plotmap(x + 4, y,     sprites[base + 3]);
  _plotmap(x,     y + 4, sprites[base + 0]);
  _plotmap(x + 4, y + 4, sprites[base + 1]);
end;

proc spritetable;
var i: integer;
begin
  for i := 0 to NSPRITES - 1 do
    showsprite(20 + 12 * i, 50, i);
end;

begin
  readfile;
  _grinit;
  _splitview;
  _cleargr;
  spritetable;
end.