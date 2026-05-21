{ sprtlib - sprite library }

library sprtlib;

const NSPRITES    = 44;
      FRAMES      = 3;
      S_CLEAR     = 0;
      S_STANDING  = 1;
      S_RIGHT     = 9;
      S_LEFT      = 32;
      S_UP        = 14;
      S_DOWN      = 35;
      S_JUMPR     = 38;
      S_JUMPL     = 41;
      S_TURN      = 19;

var sprites: array[176] of integer;

proc readsprites;
var  i, j, index: integer;
    f: file;

  proc setfio(name:cpnt);
  const
      ENDMARK = chr(0);
  mem FILFLG  = $00da: integer&;
      FILDRV  = $00dc: integer&;
      { FILTYP  = $0300:char&; }
      FILNAM  = $0301: array[15] of char&;
      FILCYC  = $0311: integer&;
      { FILSTP = $0312: char&; }
      FILNM1  = $0320: array[15] of char&;
      FILCY1  = $0330: integer&;
  var i,j, cyclus, drive: integer;
  begin
    cyclus := 0;
    drive  := 0;
    i := 0;
    while (name[i]<>ENDMARK) and (i<=15) do begin
      FILNAM[i] := name[i];
      FILNM1[i] := name[i];
      i := i + 1;
    end;
    for j := i to 15 do begin
      FILNAM[j] := ' ';
      FILNM1[j] := ' ';
      end;
    FILCYC := cyclus;
    FILCY1 := cyclus;
    FILDRV := drive;
    FILFLG := 0;
  end;

begin
  setfio('SPRITES:B');
  openr(f);
  index := 0;
  for j:= 0 to NSPRITES - 1 do begin
    for i:= 0 to 3 do begin
      read(@f,sprites[index]);
      index := index + 1;
    end;
  end;
  close(f);
end;

proc showsprite(x, y, index: integer);
var base: integer;

  proc plotmap(x,y,m:integer);
  const abitmap=$c81b;
        XSIZE=223;
        YSIZE=117;
  mem   grmap=$03b6: integer;
        grx=$03ae: integer&;
        gry=$03af: integer&;
  begin
    grx:=x;
    gry:=y;
    if x<0 then grx:=0;
    if x>(XSIZE-4) then grx:=XSIZE-4;
    if y<0 then gry:=0;
    if y>(YSIZE-4) then gry:=YSIZE-4;
    grmap:=m;
    call(abitmap);
  end;

begin
  base := 4 * index;
  plotmap(x,     y,     sprites[base + 2]);
  plotmap(x + 4, y,     sprites[base + 3]);
  plotmap(x,     y + 4, sprites[base + 0]);
  plotmap(x + 4, y + 4, sprites[base + 1]);
end;

begin
  readsprites;
end.
