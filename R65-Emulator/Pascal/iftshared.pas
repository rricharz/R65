{ shared library for FUNCTION, FT and GRAPH }

{ Data file header bytes

  0 - 15    current binary header
             version, n, datatype, domain,
             min, max

 16 - 31    reserved for future binary fields

 32 - 96    title        64 chars + chr(0)
 97 -161    description  64 chars + chr(0)

162 -255    reserved for future expansion

Data starts at byte 256. }

const
  DATA_REAL    = 0;
  DATA_COMPLEX = 1;

  DOMAIN_TIME  = 0;
  DOMAIN_FREQ  = 1;

  DATAVERSION  = 2;
  DATAFILESIZE = 8192;  { + 256 for header section }
  REALBASE     = 64;    { 256 div 4 }
  COMPLEXBASE  = 1088;  { REALBASE + 1024 }

  TEXTSIZE    = 65;
  TITLEPOS    = 32;
  DESCRPOS    = 97;

  PARSIZE    = 256;
  STRSIZE    = 9;   { 8 chars + chr(0) }

var
  _parampos: integer;
  _n, _datatype, _domain: integer;
  _min, _max: real;
  _title, _description: cpnt;

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

proc _runerr(e:integer);
{**********************}
{ set runerr to e and stop execution of app }
const stopcode = $2010;
mem   _mrunerr = $000c: integer&;
begin
  _mrunerr:=e;
  call(stopcode);
end;

proc _abortwith(s: cpnt);
{**********************}
const stopcode = $2010;
begin
  writeln(chr($0e),s,chr($0b));
  _runerr(54);
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
    _runerr($91);
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

proc _getdataheader(f: file);
{***************************}
var version: integer;
  i, vi: integer;

  proc getword(device:file; address:integer;
                                var word:integer);
  var h,l:integer;
  begin
    getbyte(device,2*address,l);
    getbyte(device,2*address+1,h);
    word:=(h shl 8) + l;
  end;

  proc getreal(device:file; address:integer;
    var rvalue:array[1] of %integer);
  var i1,i2:integer;
  begin
    getword(device,2*address,i1);
    getword(device,2*address+1,i2);
    rvalue[0]:=i1;
    rvalue[1]:=i2;
  end;

begin
  getword(f, 0, version);
  if version <> DATAVERSION then
    _abortwith('Wrong data file version');
  getword(f, 1, _n);
  getword(f, 2, _datatype);
  getword(f, 3, _domain);
  getreal(f, 2, _min);  { real has 4 bytes }
  getreal(f, 3, _max);
  for i:=0 to TEXTSIZE-1 do begin
    getbyte(f,TITLEPOS+i,vi);
    _title[i] := chr(vi);
    getbyte(f,DESCRPOS+i,vi);
    _description[i] := chr(vi);
  end;
end;

proc _putdataheader(f: file);
{***************************}
var i:integer;

  proc putword(device:file; address:integer;
    word:integer);
  begin
    putbyte(device,2*address, word and 255);
    putbyte(device,2*address+1, word shr 8);
  end;

  proc putreal(device:file; address:integer;
    rvalue:array[1] of %integer);
  begin
    putword(device,2*address, rvalue[0]);
    putword(device,2*address+1, rvalue[1]);
  end;

begin
  putword(f, 0, DATAVERSION);
  putword(f, 1, _n);
  putword(f, 2, _datatype);
  putword(f, 3, _domain);
  putreal(f, 2, _min);  { real has 4 bytes }
  putreal(f, 3, _max);
  for i:=0 to TEXTSIZE-1 do begin
    putbyte(f,TITLEPOS+i,_title[i]);
    putbyte(f,DESCRPOS+i,_description[i]);
  end;
end;

{*****************}
proc initiftshared;
{*****************}
begin  { initialize library }
  _parampos := 0;
  _title       := _allocate(TEXTSIZE);
  _description := _allocate(TEXTSIZE);
  strcpyn('',_title,TEXTSIZE);
  strcpyn('',_description,TEXTSIZE);
end;

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

proc loadparams(f: file);
{***********************}
var
  p,i,addr,version,np,ii: integer;
  ir: real;
  s: cpnt;
begin
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
end;
