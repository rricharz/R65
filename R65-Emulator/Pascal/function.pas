program function;
uses syslib,paramlib,strlib,writelib;

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

proc displayparams;
{*****************}
const
  columns   = 2;
  namefield = 7;
  valfield  = 9;
var i,col,row,rows,k,padding: integer;
begin
  rows := (MAXPAR + columns) div columns;
  padding := (48 div columns) - namefield - valfield;
  for row := 0 to rows - 1 do begin
    for col := 0 to columns - 1 do begin
      i := row + col * rows;
      if i <= MAXPAR then begin
        if col > 0 then
          for k := 1 to padding do write(' ');
        write(field(pname[i], namefield));
        case ptype[i] of
          'i':  write(pival[i]:valfield);
          'r':  write(prval[i]:valfield:2);
          's':  write(field(psval[i],valfield))
          else write('undefined')
        end {case};
      end {if};
    end {column};
    writeln;
  end {row};
end;

proc setparam(p: integer; value: cpnt);
{*************************************}
begin
end;

func findparam(name: cpnt): integer;
{**********************************}
var p: integer;
    found: boolean;
begin
  p := 0;
  repeat
    found := _strcmp(pname[p], name) = 0;
    p := p + 1;
  until found or (p > MAXPAR);
  if found then
    findparam := p - 1
  else
    findparam := -1;
  writeln('findparam ', name, ': p=', p);
end;

proc readparams;
{**************}
var name, value: cpnt;
    done: boolean;
    p: integer;
begin
  name  := _allocate(9);
  value := _allocate(17);
  repeat
    _nextparam(name, value, done);
    if not done then begin
      p := findparam(name);
      if p < 0 then
        writeln('Unknown parameter ',name)
      else
        setparam(p,value);
    end;
  until done;
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

  pname[P_N] := cpnt('N');
  ptype[P_N] := 'i';
  pival[P_N] := 256;

  pname[P_XMIN] := 'XMIN';
  ptype[P_XMIN] := 'r';
  prval[P_XMIN] := 0.0;

  pname[P_XMAX] := 'XMAX';
  ptype[P_XMAX] := 'r';
  prval[P_XMAX] := 1.0;

  pname[P_A] := cpnt('A');
  ptype[P_A] := 'r';
  prval[P_A] := 1.0;

  pname[P_A1] := cpnt('A1');
  ptype[P_A1] := 'r';
  prval[P_A1] := 1.0;

  pname[P_A2] := cpnt('A2');
  ptype[P_A2] := 'r';
  prval[P_A2] := 1.0;

  pname[P_F1] := cpnt('F1');
  ptype[P_F1] := 'r';
  prval[P_F1] := 8.0;

  pname[P_F2] := cpnt('F2');
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
  readparams;
  displayparams;
end. 