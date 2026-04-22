{*****************************************}
{* striolib - file io using cpnt strings *}
{*****************************************}

{$U+}

library striolib;

{ prepare read/write to file }
{ Example:                   }
{   strfio('TEXT':B,1);      }
{   openr;                   }

const
    NAMESIZE = 15;
mem
    filerr  =$00db: integer&;

proc _argerror(e: integer);
{*************************}
{ display argument error e and stops app }
const
    STOP=$2010;
mem
    RUNERR=$000c: integer&;
begin
    writeln;
    writeln('Argument error ',e);
    RUNERR:=255;
    call(STOP)
end;

proc _checkfilerr;
{****************}
{ display file error code and stop }
const
    STOP=$2010;
mem
    RUNERR=$000c: integer&;
begin
  if filerr<>0 then begin
    writeln('File Error ', filerr);
    RUNERR := 255;
    call(STOP);
  end;
end;

proc _sgetstring(string: cpnt; var scarg: integer;
                  var default: boolean);
{***************** ********************}
{ get string argument }
{ set string to if no argument }
const
    ENDMARK = chr(0);
mem
    ARGLISTS = $0060: array[63] of char&;
    ARGTYPE  = $00a0: array[31] of char&;
var
    i: integer;
    dummy: boolean;
begin
  string[0] := ENDMARK;
  case ARGTYPE[scarg] of
    's': begin
           for i:=0 to NAMESIZE do
             string[i]:=ARGLISTS[2 * scarg + i];
           scarg:=scarg + 8;
           default:=false;
           string[16] := ENDMARK;
         end;
    'd': begin
           string[0] := ENDMARK;
           default:=true; scarg:= scarg + 1;
         end;
    chr(0):
         begin
           string[0] := ENDMARK;
           default:=true;
         end
    else _argerror(101)
  end {case}
end;


proc _ssetsubtype(sname: cpnt; subtype:char;
                  force: boolean);
{*******************************************}
{ if not force: only set subtype if not there }
const
    ENDMARK = chr(0);
mem
    filstp=$312:char&;
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (sname[i]=':') or
    (sname[i]=' ') or (sname[i] = ENDMARK);
  if sname[i]<>':' then begin
    sname[i]:=':';
    sname[i+1]:=subtype;
    filstp:=subtype;
  end
  else if force then begin
    sname[i+1]:=subtype;
  end;
  filstp := sname[i+1];
  sname[i+2] := ENDMARK;
end;

proc _strfio(name:cpnt; cyclus, drive: integer);
{**********************************************}
const
    ENDMARK = chr(0);
mem
    FILFLG  = $00da: integer&;
    FILDRV  = $00dc: integer&;
    FILTYP  = $0300:char&;
    FILNAM  = $0301: array[NAMESIZE] of char&;
    FILCYC  = $0311: integer&;
    FILSTP = $0312: char&;
    FILNM1  = $0320: array[NAMESIZE] of char&;
    FILCY1  = $0330: integer&;

var i,j: integer;
begin
  i := 0;
  while (name[i]<>ENDMARK) and (i<=NAMESIZE) do begin
    FILNAM[i] := name[i];
    FILNM1[i] := name[i];
    i := i + 1;
  end;
  for j := i to NAMESIZE do begin
    FILNAM[j] := ' ';
    FILNM1[j] := ' ';
  end;
  FILCYC := cyclus;
  FILCY1 := cyclus;
  FILDRV := drive;
  FILFLG := 0;
end;

proc _getdiskname(s: cpnt; drive: integer);
{*****************************************}
const
    ENDMARK = chr(0);
    MAXENT   = 255;    { max number of entries }
    aprepdo =$f4a7;
    agetentx=$f63a;
    aenddo  =$f625;
mem
    FILDRV  = $00dc: integer&;
    FILNAM  = $0301: array[NAMESIZE] of char&;
    scyfc   =$037c: integer&;
var
    i: integer;

begin
  FILDRV:=drive;
  call(aprepdo);
  _checkfilerr;
  scyfc:=MAXENT;
  call(agetentx);
  _checkfilerr;
  for i:=0 to NAMESIZE do begin
    if (FILNAM[i] = ' ') then
      s[i] := ENDMARK
    else
      s[i]:=FILNAM[i];
  end;
  call(aenddo);
end;

proc _change_disk(s: cpnt; drv: integer);
{**************************************}
{ set drv (drive) to s (name) }
const afloppy = $c827; { exdos vector }
begin
  _strfio(s, 0, drv);
  call(afloppy);
end;

proc srunprog(name: cpnt; cyc: integer; drv: integer);
{****************************************************}
const
    ENDMARK = chr(0);
mem
    FILFLG = $00da: integer&;
    FILNM1 = $0320: array[15] of char&;
    FILCY1 = $0330: integer&;
    FILDRV = $00dc: integer&;
var
    i: integer;
begin
  for i := 0 to NAMESIZE do FILNM1[i] := ' ';
  i := 0;
  while (name[i] <> ENDMARK) and (i <= NAMESIZE)
  do begin
    FILNM1[i]:=name[i];
    i := i + 1;
  end;
  FILCY1:=cyc; FILDRV:=drv; FILFLG:=$40;
  run;
end;

begin
end.
