{ WRITELIB - Write formatting helper routines

  WRITELIB provides helper functions which return temp
orary
  cpnt strings for use in write and writeln statements
.

  Examples:
    writeln(hex(i));
    writeln(date);
    writeln(time);

  All WRITELIB functions return a pointer to a shared
temporary
  string buffer located at $17D8-$17E8 (16 characters
plus
  terminating zero).

  Limitations:
  - Maximum string length is 16 characters.
  - The result remains valid only until the next WRITE
LIB call.
  - WRITELIB functions must not be nested.
  - Intended for direct use in write and writeln state
ments.

  Memory map:
    $17D8-$17E8  WRITBUF  Temporary cpnt string buffer
}

library writelib;

func hexchar(i0: integer): char;
var i1: integer;
begin
  i1 := i0 and $0f;
  if i1 < 10 then
    hexchar := chr(ord('0') + i1)
  else
    hexchar := chr(ord('A') + i1 - 10);
end;

func hexb(i: integer): cpnt;
var cp: cpnt;
begin
  cp := cpnt($17d8);
  cp[0] := hexchar((i shr 4) and $0f);
  cp[1] := hexchar(i and $0f);
  cp[2] := chr(0);
  hexb := cp;
end;

func hexw(i: integer): cpnt;
var cp: cpnt;
begin
  cp := cpnt($17d8);
  cp[0] := hexchar((i shr 12) and $0f);
  cp[1] := hexchar((i shr 8) and $0f);
  cp[2] := hexchar((i shr 4) and $0f);
  cp[3] := hexchar(i and $0f);
  cp[4] := chr(0);
  hexw := cp;
end;

begin
end. 