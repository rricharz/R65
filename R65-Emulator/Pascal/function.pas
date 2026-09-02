program function;
uses syslib,strlib,writelib,mathlib,ralib,ftlib;

const

  P_TYPE   = 0;
  P_N      = 1;
  P_TMIN   = 2;
  P_TMAX   = 3;
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

  FT_COSINE    = 1;
  FT_SUM       = 2;
  FT_PRODUCT   = 3;
  FT_GAUSSIAN  = 4;
  FT_EXP       = 5;
  FT_PULSE     = 6;
  FT_TRAPEZOID = 7;
  FT_TRIANGLE  = 8;
  FT_SINC      = 9;
  MAXTYPE      = 9;

  NAMESIZE = 15;

  PARVERSION = 1;
  PARSIZE    = 256;
  STRSIZE    = 9;   { 8 chars + chr(0) }

var
  nparams: integer;

  ibase: integer;   { word address of integer values }
  rbase: integer;   { real address of real values }
  sbase: integer;   { byte address of string values }

  pname: array[MAXPAR] of cpnt;
  ptype: array[MAXPAR] of char;
  pival: array[MAXPAR] of integer;
  prval: array[MAXPAR] of real;
  psval: array[MAXPAR] of cpnt;

  parfileexists: boolean;

  ftitle: array[MAXTYPE] of cpnt;
  fformula: array[MAXTYPE] of cpnt;

proc initparfile;
{***************}
begin
  nparams := MAXPAR + 1;

  { Parameter file layout:
      word 0 : version
      word 1 : number of parameters

      integer values:
        nparams words, starting at ibase

      real values:
        nparams reals, starting at rbase

      string values:
        nparams slots of STRSIZE bytes,
        each containing up to 8 chars + chr(0)

      complete file size is fixed at 256 bytes
  }

  ibase := 2;

  { rbase is expressed in real addresses.
    Round integer section up to next real boundary. }
  rbase := (ibase + nparams + 1) shr 1;

  { sbase is expressed in byte addresses }
  sbase := 4 * (rbase + nparams);
  debug(ibase, rbase, sbase);
end;

func fileexists(nm: array[NAMESIZE] of char;
                           drv: integer): boolean;
{************************************************}
const aprepdo  = $f4a7;
      agetentx = $f63a;
      aenddo   = $f625;

      NUMENTRIES = 255;

mem   filtyp = $0300: char&;
      fillnk = $031e: integer&;
      scyfc  = $037c: integer&;
      fildrv = $00dc: integer&;
      FILNAM = $0301: array[NAMESIZE] of char&;

var ent,i: integer;
    found,last: boolean;

    func same: boolean;
    var k: integer;
        equal: boolean;
    begin
      equal:=true;
      k:=0;
      while equal and (k<=NAMESIZE) do begin
        equal:=nm[k]=FILNAM[k];
        k:=k+1;
      end;
      same:=equal;
    end;

begin
  fildrv:=drv;
  call(aprepdo);
  ent:=0;
  found:=false;
  last:=false;
  repeat
    scyfc:=ent;
    call(agetentx);
    last:=filtyp=chr(0);
    if not last then begin
      found:=same;
      if (fillnk and $80)<>0 then
        found:=false;
    end;
    ent:=ent+1;
  until found or last or (ent>=NUMENTRIES);
  call(aenddo);
  fileexists:=found;
end;

proc displayparams;
{*****************}
const
  columns   = 2;
  namefield = 7;
  valfield  = 9;
var i,col,row,rows,k,padding,type: integer;
begin
  type := pival[P_TYPE];
  if type=0 then exit;
  writeln('FUNCTION: ',ftitle[type]);
  writeln('FORMULA:  ',fformula[type]);
  writeln
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
  writeln;
end;

proc setparam(p: integer; value: cpnt);
{*************************************}
begin
  case ptype[p] of
  'i':  begin
          pival[p] := round(str_real(value));
        end;
  'r':  begin
          prval[p] := str_real(value);
        end;
  's':  begin
          strcpyn(value, psval[p],9);
        end
  end {case }
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

  pname[P_TMIN] := 'TMIN';
  ptype[P_TMIN] := 'r';
  prval[P_TMIN] := 0.0;

  pname[P_TMAX] := 'TMAX';
  ptype[P_TMAX] := 'r';
  prval[P_TMAX] := 1.0;

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

proc initfunctions;
{*****************}
begin
  ftitle[FT_COSINE]   := 'COSINE';
  fformula[FT_COSINE] := 'A*cos(360*F1*x+PHASE)';

  ftitle[FT_SUM]   := 'SUM OF TWO COSINES';
  fformula[FT_SUM] :=
    'A1*cos(360*F1*x)+A2*cos(360*F2*x)';

  ftitle[FT_PRODUCT]   := 'PRODUCT OF TWO COSINES';
  fformula[FT_PRODUCT] :=
    'A*cos(360*F1*x)*cos(360*F2*x)';

  ftitle[FT_GAUSSIAN]   := 'GAUSSIAN';
  fformula[FT_GAUSSIAN] :=
    'A*exp(-((x-CENTER)/WIDTH)^2)';

  ftitle[FT_EXP]   := 'EXPONENTIAL';
  fformula[FT_EXP] := 'A*exp(-(x-TMIN)/TAU)';

  ftitle[FT_PULSE]   := 'RECTANGULAR PULSE';
  fformula[FT_PULSE] := 'A within WIDTH, otherwise 0';

  ftitle[FT_TRAPEZOID]   := 'TRAPEZOID';
  fformula[FT_TRAPEZOID] := 'Pulse with RISE time';

  ftitle[FT_TRIANGLE]   := 'TRIANGLE';
  fformula[FT_TRIANGLE] :=
    'Triangle with CENTER and WIDTH';

  ftitle[FT_SINC]   := 'SINC';
  fformula[FT_SINC] := 'A*sin(360*F1*x)/(360*F1*x)';
end;

proc loadparams;
{**************}
var
  f: file;
  p,i,addr,version,np,ii: integer;
  ir: real;
  s: cpnt;
begin
  f:=_attach('FUNCPARS:X      ',0,1,FREAD+FSILENT,
                                    PARSIZE,0,'X');

  if _getsize<>PARSIZE then
    _abortwith('Wrong parameter file size');

  _getword(f,0,version);
  if version<>PARVERSION then
    _abortwith('Wrong parameter file version');

  _getword(f,1,np);
  if np<>nparams then
    _abortwith('Wrong number of parameters');

  for p:=0 to MAXPAR do begin
    _getword(f,ibase+p,ii);
    pival[p]:=ii;
  end;

  for p:=0 to MAXPAR do begin
    _getreal(f,rbase+p,ir);
    prval[p]:=ir;
  end;

  for p:=0 to MAXPAR do begin
    if psval[p]<>nil then begin
      s:=psval[p];
      addr:=sbase+STRSIZE*p;
      for i:=0 to STRSIZE-1 do begin
        getbyte(f,addr+i,ii);
        s[i]:=chr(ii);
      end;
    end;
  end;

  close(f);
end;

proc storeparams;
{***************}
const size = 256;
var f: file;
    p, i, addr: integer;
    s: cpnt;
begin
  if parfileexists then
    f := _attach('FUNCPARS:X      ',0,1,
                  FWRITE+FSILENT,size,0,'X')
  else begin
    f := _attach('FUNCPARS:X      ',0,1,
                  FNEW+FSILENT,size,0,'X');
    parfileexists := true;
  end;

  if _getsize <> size then
    _abortwith('Wrong parameter file size');

  { header }
  _putword(f,0,PARVERSION);
  _putword(f,1,nparams);

  { integer values }
  for p:=0 to MAXPAR do
    _putword(f,ibase+p,pival[p]);

  { real values }
  for p:=0 to MAXPAR do
    _putreal(f,rbase+p,prval[p]);

    { string values: fixed 9-byte slots }
    for p:=0 to MAXPAR do begin
      addr:=sbase+STRSIZE*p;
      if psval[p]=nil then begin
        for i:=0 to STRSIZE-1 do
          putbyte(f,addr+i,0);
      end else begin
        s:=psval[p];
        for i:=0 to STRSIZE-1 do
          putbyte(f,addr+i,ord(s[i]));
      end;
    end;

  close(f);
end;

proc displayfunctions;
{********************}
var i: integer;
begin
  writeln('FUNCTION GENERATOR');
  writeln;
  for i:=1 to MAXTYPE do
    writeln(i:2, '  ', ftitle[i]);
  writeln;
  writeln('Select: FUNCTION TYPE=n');
  writeln('Help:   FUNCTION TYPE=0');
  writeln;
end;

proc makefunction;
{****************}
var f: file;
    t, deltat, val, a, f1, phase, phaseval: real;
    k: integer;
begin
  { validate common parameters }
  _n := pival[P_N];
  if not ((_n=128) or (_n=256) or
          (_n=512) or (_n=1024)) then begin
    _abortwith('N must be 128, 256, 512 or 1024');
  end;
  _min := prval[P_TMIN];
  _max := prval[P_TMAX];
  if (_max <= _min) then
    _abortwith('TMAX must be > TMIN');
  if (_strcmp(psval[P_DATA],'REAL') = 0) then
    _datatype := 0
  else if (_strcmp(psval[P_DATA],'COMPLEX') = 0) then
    _datatype := 1
  else
    _abortwith('DATA must be REAL or COMPLEX');
  _domain := 0;

  { attach data file and check size }
  if fileexists('FUNCDATA:X      ', 1) then
    f := _attach('FUNCDATA:X      ', 0, 1,
      FWRITE + FSILENT, DATAFILESIZE + 256, 0, 'X')
  else
    f := _attach('FUNCDATA:X      ', 0, 1,
      FNEW + FSILENT, DATAFILESIZE + 256, 0, 'X');
  if _getsize <> DATAFILESIZE + 256 then
    _abortwith('Wrong data file size');

  { put data header in file }
  _putdataheader(f);

  { compute and store function }
  t := _min;
  deltat := (_max - _min) / conv(_n);

  a  := prval[P_A];
  f1 := prval[P_F1];
  phase := prval[P_PHASE];

  case pival[P_TYPE] of
    1: begin
         for k := 0 to _n - 1 do begin
           phaseval := 360.0 * f1 * t + phase;

           { real part }
           val := a * cos(phaseval);
           _putreal(f,REALBASE+k,val);

           { imaginary part }
           if _datatype = DATA_COMPLEX then
             val := a * sin(phaseval)
          else
             val := 0.0;
          _putreal(f,COMPLEXBASE+k,val);

          t := t + deltat;
         end;
       end
    else _abortwith(
          'Function TYPE not yet implemented')
    end {case};

  close(f);
end;

begin { main }
  initfunctions;
  initparfile;
  parfileexists := fileexists('FUNCPARS:X      ', 1);
  initparams;
  if parfileexists then loadparams;
  readparams;
  if pival[P_TYPE] = 0 then
    displayfunctions
  else begin
    displayparams;
    makefunction;
  end;
  storeparams;
end. 