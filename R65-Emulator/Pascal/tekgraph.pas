{ tekgraph -                          }
{ display a table of real numbers     }
{ on attached Tektronix 4010 terminal }
{                                     }

program tekgraph;
uses syslib,ralib,mathlib,tek4Klib,writelib,
      strlib,ftlib;

const
  border = 200;
  leftborder = 480;

  LEFT = 0;     { to justify in _plotstr }
  CENTER = 1;
  RIGHT = 2;

  P_MODE   = 0;
  P_YSCALE = 1;
  P_YMIN   = 2;
  P_YMAX   = 3;

  MAXPAR   = 3;
  NAMESIZE = 15;

  PARVERSION = 1;
  PARSIZE    = 256;
  STRSIZE    = 9;   { 8 chars + chr(0) }

var
  pname: array[MAXPAR] of cpnt;
  ptype: array[MAXPAR] of char;
  pchanged: array[MAXPAR] of boolean;

  pival: array[MAXPAR] of integer;
  prval: array[MAXPAR] of real;
  psval: array[MAXPAR] of cpnt;

  parfileexists: boolean;

  nparams: integer;
  ibase: integer;    { word address }
  rbase: integer;    { real address }
  sbase: integer;    { byte address }

  f:file;
  i:integer;
  xaxis, xsaxis:real;
  axis, daxis, daxis0:real;
  xs, xw, ys, yw, x:integer;
  min, max, nmax, v:real;
  realmode, autoscale: boolean;

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
var i,col,row,rows,k,padding: integer;
begin
  writeln
    ('DISPLAY PARAMETERS (change with TEKGRAPH)');

  rows := (MAXPAR + columns) div columns;
  padding := (48 div columns) - namefield - valfield;

  for row := 0 to rows - 1 do begin
    for col := 0 to columns - 1 do begin
      i := row + col * rows;
      if i <= MAXPAR then begin
        if col > 0 then
          for k := 1 to padding do write(' ');
        write(field(pname[i],namefield));
        case ptype[i] of
          'i': write(pival[i]:valfield);
          'r': write(prval[i]:valfield:2);
          's': write(field(psval[i],valfield))
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
  pchanged[p] := true;
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
        _abortwith('Unknown parameter')
      else
        setparam(p,value);
    end;
  until done;
end;

proc initparams;
{**************}
var i: integer;
begin
  for i:=0 to MAXPAR do begin
    psval[i]    := nil;
    pchanged[i] := false;
  end;

  pname[P_MODE] := 'MODE';
  ptype[P_MODE] := 's';
  psval[P_MODE] := _allocate(9);
  strcpyn('REAL',psval[P_MODE],9);

  pname[P_YSCALE] := 'YSCALE';
  ptype[P_YSCALE] := 's';
  psval[P_YSCALE] := _allocate(9);
  strcpyn('AUTO',psval[P_YSCALE],9);

  pname[P_YMIN] := 'YMIN';
  ptype[P_YMIN] := 'r';
  prval[P_YMIN] := -1.0;

  pname[P_YMAX] := 'YMAX';
  ptype[P_YMAX] := 'r';
  prval[P_YMAX] := 1.0;
end;

proc loadparams;
{**************}
var
  f: file;
  p,i,addr,version,np,ii: integer;
  ir: real;
  s: cpnt;
begin
  f:=_attach('GRAPHPARS:X     ',0,1,FREAD+FSILENT,
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
    f := _attach('GRAPHPARS:X     ',0,1,
                  FWRITE+FSILENT,size,0,'X')
  else begin
    f := _attach('GRAPHPARS:X     ',0,1,
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

proc _plotstr(s: cpnt; x, y: integer;
                              justify: integer);
{**********************************************}
const
  CHARWIDTH = 50.568;   { _setchsize(2) }
  XOFFSET   = 8.0;
  YOFFSET   = -16.0;
var
  xpos: real;
  width: real;
begin
  width := conv(_strlen(s)) * CHARWIDTH;

  xpos := conv(x);

  case justify of
    CENTER: xpos := xpos - width/2.0;
    RIGHT:  xpos := xpos - width
  end;

  { do not output partial strings }

  if (xpos<0.0) or
      (xpos+width>conv(MAXX)) then
    exit;

  _moveto(trunc(xpos + XOFFSET + 0.5),
          trunc(conv(y) + YOFFSET + 0.5));
  write(@PLOTTER,s);
end;

proc tics;
{********}
const eps = 0.001;
var r, base, frac: real;
begin
{ ---------- Y axis ---------- }

daxis0 := (max-min)/2.0;
daxis := 1.0;

while daxis>daxis0 do
  daxis:=daxis*0.1;

while daxis<0.1*daxis0 do
  daxis:=daxis*10.0;

{ round lower limit down to a tick }
r:=min/daxis;
if (r<=32767.0) and (r>=-32768.0) then begin
  axis:=daxis*conv(trunc(r));
  if axis>min+eps*daxis then
    axis:=axis-daxis;
end
else
  axis:=min;
min:=axis;

{ round upper limit up to a tick }
r:=max/daxis;
if (r<=32767.0) and (r>=-32768.0) then begin
  nmax:=daxis*conv(trunc(r));
  if nmax<max-eps*daxis then
    nmax:=nmax+daxis;
  max:=nmax;
end;

  { ---------- X axis ---------- }

  daxis0 := (_max-_min)/5.0;

  base := 1.0;
  while base>daxis0 do
    base := base*0.1;
  while base*10.0<=daxis0 do
    base := base*10.0;

  frac := daxis0/base;
  if frac<=1.5 then
    xaxis := base
  else if frac<=3.5 then
    xaxis := 2.0*base
  else
    xaxis := 5.0*base;

  r := _min/xaxis;
  if (r<=32767.0) and (r>=-32768.0) then begin
    xsaxis := xaxis*conv(trunc(r));
    if xsaxis<_min-eps*xaxis then
      xsaxis := xsaxis+xaxis;
  end
  else
    xsaxis := _min;
end;

proc initialize;
{**************}
begin
  f:=_attach('FUNCDATA:X      ', 0, 1,
  FREAD + FSILENT, 0, 0, 'X');
  if _getsize <> DATAFILESIZE + 256 then
  _abortwith('Wrong data file size');
  _getdataheader(f);
  initparfile;
  initparams;
  parfileexists := fileexists('GRAPHPARS:X     ', 1);
  if parfileexists then loadparams;
  readparams;
end;

proc normalize;
{*************}
{ normalize vertical axis }
var minbin, maxbin: integer;
begin
  min := 1.0e10;
  max := -1.0e10;
  minbin := 0;
  maxbin := 0;
  for i:=0 to _n-1 do begin
    _getreal(f,REALBASE+i,v);
    if v<min then begin
      min:=v;
      minbin := i;
    end;
    if v>max then begin
      max:=v;
      maxbin := i;
    end;
    if _datatype=DATA_COMPLEX then begin
      _getreal(f,COMPLEXBASE+i,v);
      if v<min then begin
        min:=v;
        minbin := i;
      end;
      if v>max then begin
        max:=v;
        maxbin := i;
      end;
    end;
  end;
end;

proc validate;
{************}
begin
  if (_strcmp(psval[P_MODE],'REAL') = 0) then
    realmode := true
  else if (_strcmp(psval[P_MODE],'IMAG')=0) then
    realmode := false
  else
    _abortwith('MODE must be REAL or IMAG');
  if (_strcmp(psval[P_YSCALE],'AUTO') = 0) then
    autoscale := true
  else if (_strcmp(psval[P_YSCALE],'MANUAL') = 0) then
    autoscale := false
  else
    _abortwith('YSCALE must be AUTO or MANUAL');


  if (pchanged[P_YMIN]) or (pchanged[P_YMAX]) then
  begin
    strcpyn('MANUAL', psval[P_YSCALE], 9);
    autoscale := false;
  end;
  if autoscale = true then
    normalize
  else begin
    min := prval[P_YMIN];
    max := prval[P_YMAX];
    if min >= max then
      _abortwith('YMIN must be smaller than YMAX');
  end;
end;

proc displayfuncpars;
{*******************}
begin
  writeln(
    'FUNCTION PARAMETERS (change with FUNCTION)');
  writeln('N      ',_n:9);

  write  ('Xmin   ',_min:9:2,'        ');
  if _domain = DOMAIN_TIME then
    writeln('DOMAIN ',' TIME')
  else
    writeln('DOMAIN ',' FREQUENCY');

  write  ('Xmax   ',_max:9:2,'        ');
  if _datatype = DATA_REAL then
    writeln('DATA   ',' REAL')
  else
    writeln('DATA   ',' COMPLEX');
end;

proc drawaxes;
{************}
var labelstr : cpnt;
    y: integer;
begin
  tics;
  labelstr := _new;
  _starttek(T_HALF);
  xs:=leftborder;
  xw:=MAXX-leftborder-border;
  ys:=border;
  yw:=MAXY-2*border;

  _drawrectangle(xs,ys,xs+xw,ys+yw);

  _setlinemode(DOTTED);
  _setchsize(2);

  repeat
    labelstr[0] := chr(0);
    y:=trunc((axis-min)/(max-min)*conv(yw)+0.5);
    if (y>0) and (y<yw) then
      _drawvector(xs,ys+y,xs+xw,ys+y);
    _moveto(5,ys+y-5);
    if daxis<0.001 then
      write(@labelstr,axis:1:4)
    else if daxis<0.01 then
      write(@labelstr,axis:1:3)
    else if daxis<0.1 then
      write(@labelstr,axis:1:2)
    else
      write(@labelstr,axis:1:1);
    _plotstr(labelstr,xs,
      ys + y, RIGHT);
    axis:=axis+daxis;
  until axis>max*1.0001;

  repeat
    labelstr[0] := chr(0);
    x:=trunc((xsaxis-_min)/
                 (_max-_min)*conv(xw)+0.5);
    if (x>0) and (x<xw) then
      _drawvector(xs+x,ys,xs+x,ys+yw);
    if xaxis<0.001 then
      write(@labelstr,xsaxis:1:4)
    else if xaxis<0.01 then
      write(@labelstr,xsaxis:1:3)
    else if xaxis<0.1 then
      write(@labelstr,xsaxis:1:2)
    else
      write(@labelstr,xsaxis:1:1);
    _plotstr(labelstr,xs + x,
      ys - trunc(0.4
       * conv(border)), CENTER);
    xsaxis:=xsaxis+xaxis;
  until xsaxis>_max;
end;

func ypos(i: integer): integer;
var j: integer;
    v: real;
begin
  j := i;
  if _domain = DOMAIN_FREQ then begin
    j := j + _n div 2;
    if j >= _n then
      j := j - _n;
  end;

  if realmode then
    _getreal(f, REALBASE+j, v)
  else
    _getreal(f, COMPLEXBASE+j, v);
  if (v < min) then
    ypos := 0
  else if (v > max) then
    ypos := yw
  else
    ypos:=trunc((v-min)/(max-min)*conv(yw)+0.5);
end;

proc drawdata;
{************}
begin
  _setlinemode(SOLID);
  _setchsize(1);
  _startdraw(xs,ys+ypos(0));
  for i:=1 to _n-1 do begin
    x:=trunc(conv(xw)/conv(_n)*conv(i)+0.5);
    _draw(xs+x,ys+ypos(i));
  end;
  _enddraw;
end;

proc cleanup;
{***********}
begin
  storeparams;
  close(f);
  _moveto(1,MAXY-24);
  _endtek;
end;

begin
  initialize;
  validate;
  displayfuncpars;
  displayparams;
  drawaxes;
  drawdata;
  cleanup;
end.  