program function;
uses syslib,paramlib,strlib;

const

  P_TYPE   = 0;
  P_N      = 1;
  P_XMIN   = 2;
  P_XMAX   = 3;
  P_A      = 4;
  P_A1     = 5;
  P_A2     = 6;
  P_F1     = 7;
  P_F2     = 8;
  P_PHASE  = 9;
  P_TAU    = 10;
  P_CENTER = 11;
  P_WIDTH  = 12;
  P_RISE   = 13;
  P_DATA   = 14;
  MAXPAR   = 14;

var
  pname: array[MAXPAR] of cpnt;
  ptype: array[MAXPAR] of char;
  pival: array[MAXPAR] of integer;
  prval: array[MAXPAR] of real;
  psval: array[MAXPAR] of cpnt;

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
  debug(source,i);
  if source[i]<>chr(0) then
    _runerr(91);
  dest[i]:=chr(0);
end;

func field(text: cpnt; width0: integer): cpnt;
{********************************************}
var i: integer;
    cp: cpnt;
    width: integer;
begin
  width := width0;
  cp := cpnt($17d8);
  if width>25 then width:=25;
  if width<0 then width:=0;
  i:=0;
  while (i<width) and (text[i]<>chr(0)) do begin
    cp[i]:=text[i];
    i:=i+1
  end;
  while i<width do begin
    cp[i]:=' ';
    i:=i+1
  end;
  cp[width]:=chr(0);
  field:=cp
end;

proc displayparams;
{*****************}
var i: integer;
begin
for i := 0 to MAXPAR do
  writeln(field(pname[i], 10), '=');
end;

proc initparams;
{**************}
var i: integer;
begin
  for i:=0 to MAXPAR do
    psval[i]:=nil;

  pname[P_TYPE] := 'TYPE';
  ptype[P_TYPE] := 'i';
  pival[P_TYPE] := 0;

  pname[P_N] := 'N';
  ptype[P_N] := 'i';
  pival[P_N] := 256;

  pname[P_XMIN] := 'XMIN';
  ptype[P_XMIN] := 'r';
  prval[P_XMIN] := 0.0;

  pname[P_XMAX] := 'XMAX';
  ptype[P_XMAX] := 'r';
  prval[P_XMAX] := 1.0;

  pname[P_A] := 'A';
  ptype[P_A] := 'r';
  prval[P_A] := 1.0;

  pname[P_A1] := 'A1';
  ptype[P_A1] := 'r';
  prval[P_A1] := 1.0;

  pname[P_A2] := 'A2';
  ptype[P_A2] := 'r';
  prval[P_A2] := 1.0;

  pname[P_F1] := 'F1';
  ptype[P_F1] := 'r';
  prval[P_F1] := 8.0;

  pname[P_F2] := 'F2';
  ptype[P_F2] := 'r';
  prval[P_F2] := 16.0;

  pname[P_PHASE] := 'PHASE';
  ptype[P_PHASE] := 'r';
  prval[P_PHASE] := 0.0;

  pname[P_TAU] := 'TAU';
  ptype[P_TAU] := 'r';
  prval[P_TAU] := 1.0;

  pname[P_CENTER] := 'CENTER';
  ptype[P_CENTER] := 'r';
  prval[P_CENTER] := 0.5;

  pname[P_WIDTH] := 'WIDTH';
  ptype[P_WIDTH] := 'r';
  prval[P_WIDTH] := 0.25;

  pname[P_RISE] := 'RISE';
  ptype[P_RISE] := 'r';
  prval[P_RISE] := 0.05;

  pname[P_DATA] := 'DATA';
  ptype[P_DATA] := 's';
  psval[P_DATA] := _allocate(9);
  strcpyn('REAL',psval[P_DATA],9);
end;

begin
  initparams;
  displayparams;
end. 