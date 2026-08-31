library ftlib;

{ sahred library for FUNCTION, FT and GRAPH }

var _parampos: integer;

proc _runerr(e:integer);
{**********************}
{ set runerr to e and stop execution of app }
const stopcode = $2010;
mem   _mrunerr = $000c: integer&;
begin
  _mrunerr:=e;
  call(stopcode);
end;

func _allocate(b: integer): cpnt;
{*******************************}
{ allocate memory on heap for string }
mem  stackp = $0008: integer;
     endstk = $000e: integer;
var  freewords: integer;
     str: cpnt;
begin
  { Pascal has no type unsigned integer. }
  { But the free space can be larger than 32767 }
  { We work therefore with free words here }
  freewords:=(endstk-stackp) shr 1;
  if freewords < (b div 2 + 256) then begin
    { 256 words are left for the growing stack }
    _runerr($88);
  end;
  { allocate heap memory }
  endstk := endstk - b;
  str := cpnt(endstk);
  { initialize the string }
  str[0] := chr(0);
  _allocate := str;
end;

proc _nextparam(name, value: cpnt; var done: boolean);
{****************************************************}
mem
    ARGTYPE  = $00a0: array[31] of char&;
var s: cpnt;
    i: integer;
    ch: char;
begin
  if (ARGTYPE[0] <> 'l') then begin
    done := true;
    exit;
  end;
  s := cpnt($60);
  { initialize returned strings }
  name[0] := chr(0);
  value[0] := chr(0);
  { skip blanks before next parameter }
  while s[_parampos] = ' ' do
    _parampos := _parampos + 1;
  { end of parameter line }
  if s[_parampos] = chr(0) then begin
    done := true;
    exit;
  end;
  done := false;
  { get parameter name }
  i := 0;
  ch := s[_parampos];
  while ch <> '=' do begin
    if (ch = chr(0)) or (ch = ' ') then
      _runerr(106);
    if not (((ch >= 'A') and (ch <= 'Z')) or
            ((ch >= '0') and (ch <= '9'))) then
      _runerr(106);
    if i >= 8 then
      _runerr(106);
    name[i] := ch;
    i := i + 1;
    _parampos := _parampos + 1;
    ch := s[_parampos];
  end;
  name[i] := chr(0);
  { skip '=' }
  _parampos := _parampos + 1;
  { get parameter value }
  i := 0;
  ch := s[_parampos];
  while (ch <> ' ') and (ch <> chr(0)) do begin
    if i >= 16 then
      _runerr(106);
    value[i] := ch;
    i := i + 1;
    _parampos := _parampos + 1;
    ch := s[_parampos];
  end;
  value[i] := chr(0);
end;

proc strcpyn(source, dest: cpnt; maxlen: integer);
{************************************************}
var i: integer;
begin
  if dest=nil then
    _runerr($89);
  i:=0;
  while (source[i]<>chr(0)) and (i<maxlen-1) do begin
    dest[i]:=source[i];
    i:=i+1;
  end;
  if source[i]<>chr(0) then
    _runerr(91);
  dest[i]:=chr(0);
  i:=i+1;
  while i<maxlen do begin
    dest[i]:=chr(0);
    i:=i+1;
  end;
end;

func str_real(s: cpnt): real;
{***************************}
var i, sign: integer;
    val, frac, scale: real;
begin
  i := 0;
  sign := 1;
  if s[0] = '-' then begin
    sign := -1;
    i := 1;
  end;
  if s[i] = chr(0) then
    _runerr(106);
  val := 0.0;
  { integer part }
  while (s[i] >= '0') and (s[i] <= '9') do begin
    val := val * 10.0 + conv(ord(s[i]) - ord('0'));
    i := i + 1;
  end;
  { fractional part }
  if s[i] = '.' then begin
    i := i + 1;
    frac := 0.0;
    scale := 1.0;
    while (s[i] >= '0') and (s[i] <= '9') do begin
      frac := frac * 10.0 + conv(ord(s[i])-ord('0'));
      scale := scale * 10.0;
      i := i + 1;
    end;
    val := val + frac / scale;
  end;
  if s[i] <> chr(0) then
    _runerr(106);
  str_real := conv(sign) * val;
end;

func round(r: real): integer;
{**************************}
begin
  if r >= 0.0 then
    round := trunc(r + 0.5)
  else
    round := trunc(r - 0.5);
end;

begin  { initialize library }
  _parampos := 0;
end. 