{
         *******************
         *                 *
         *   dir <drive>   *
         *                 *
         *******************

    2018,2019 rricharz (r77@bluewin.ch)
    2023 removed INVERSE video display
    2023 default drive 1
    2026 added DIR diskname

Display the directory of a disk drive.
Uses EPROM (disk.asm) calls to get info
from disk directory.

Written 2018 for Micro Pascal.

Makes a table to find out how long the
longest name is. Then computes the number
of columns which can be displayed and
displays the directory.

option /S sorts the directory

Usage:
  DIR drive [/s]
     where drive is the drive number 1 (default) or 0
  DIR name
     where name is the name of a floppy disk

The directory table has 256 entries of 32 bytes
The disk name is stored in the last entry (255)
The last currently used entry has filtyp=TEND
}

{$U+}

program dir;
uses syslib, arglib, strlib, striolib;

const aprepdo =$f4a7;
      agetentx=$f63a;
      aenddo  =$f625;

      TSECTORS = 2560;   { size of disk in pages }
      MAXENT   = 255;    { max number of entries }
      TEND     = chr(0); { end mark of table }

mem   filtyp  = $0300: char&;
      filcyc  = $0311: integer&;
      filloc  = $0313: integer;
      filsiz  = $0315: integer;
      fildat  = $0317: array[2] of integer&;
      fillnk  = $031e: integer;
      scyfc   = $037c: integer&;

var default, name_given,
    sortit, full:             boolean;
    drive, index, i, l, ti:   integer;
    maxlen, nument, col:      integer;
    ncol, row, nspaces:       integer;
    sfree,sdel, lines:        integer;
    day, month, year:         integer;
    ffree, fdel:              real;
    s:                        cpnt;
    entry:                    array[MAXENT] of cpnt;
    cfloppy, newname:         cpnt;

func hex(d:integer):char;
{***********************}
{ convert hex digit to hex char }
begin
  if (d>=0) and (d<10) then
    hex:=chr(d+ord('0'))
  else if (d>=10) and (d<16) then
    hex:=chr(d+ord('A')-10)
  else hex:='?';
end;

proc checkfilerr;
{***************}
begin
  if filerr<>0 then begin
    writeln('Cannot read directory');
    _abort;
  end;
end;

func smaller(pnt1,pnt2:cpnt):boolean;
{***********************************}
var k:integer;
begin
  k:=0;
  while (pnt1[k]=pnt2[k]) and (pnt1[k]<>ENDMARK) do
    k:=k+1;
  smaller:=(pnt2[k]<pnt1[k]);
end;

proc sort;
{********}
var ii,j:integer;
    savepnt:cpnt;
begin
  for ii:=0 to nument-1 do
     for j:=nument-1 downto ii do
       if smaller(entry[j],entry[j+1]) then begin
          savepnt:=entry[j];
          entry[j]:=entry[j+1];
          entry[j+1]:=savepnt;
       end;
end;

proc filnam_to_str(str: cpnt);
{****************************}
var j: integer;
begin
  j := 0;
  while (j <= NAMESIZE) and (FILNAM[j] <> ' ') do
  begin
    str[j] := FILNAM[j];
    j := j + 1;
  end;
  str[j] := ENDMARK;
end;

begin {main}
{**********}
  cfloppy:=_new;
  newname:=_new;
  name_given:=false;
  drive:=1;
  filerr:=0;
  sortit:=false;
  full:=false;
  _carg:=0;
{ Process arguments }
  if ARGTYPE[_carg]=chr(0) then begin
    { no argument }
    drive:=1;
  end else if ARGTYPE[_carg]='i' then begin
    { drive number given }
    name_given:=false;
    _agetval(drive,default);
    _carg:=1;
    if (drive<0) or (drive>1) then begin
      writeln('Drive must be 0 or 1');
      _abort
    end
  end else if ARGTYPE[_carg]='s' then begin
    { name of disk or option }
    _sgetstring(newname, _carg, default);
    i := 15;
    while (newname[i] = ' ') and (i > 0) do begin
      newname[i] := ENDMARK;
      i := i - 1;
    end;
    if newname[0]<>'/' then begin
      name_given:=true;
      _carg:=10;
    end else _carg:=0;
  end;
  { check for options }
  if ARGTYPE[_carg]='s' then begin
    sortit  := option('S');
    full    := option('F');
    if not (sortit or full) then begin
      writeln('option must be /S or /F or /FS');
      exit;
    end;
  end;

{ read disk name (FILNAM of last directory entry) }
  FILDRV := drive;
  call(aprepdo);
  checkfilerr;
  scyfc := MAXENT;
  call(agetentx);
  checkfilerr;
  filnam_to_str(cfloppy);
  if name_given then begin
    _change_disk(newname, 1);
    drive:= 1;
    FILDRV:=drive;
    call(aprepdo);
    checkfilerr;
    scyfc:=MAXENT;
    call(agetentx);
    checkfilerr;
  end;

{ display info at top of table }
  if name_given then
    writeln(INVVID,'Directory drive ',drive,': ',
    newname,NORVID)
  else
    writeln(INVVID,'Directory drive ',drive,': ',
    cfloppy,NORVID);

{ read file table }
  index:=0; ti:=0; maxlen:=0;
  sdel:=0;
  repeat { for each entry in table }
    scyfc:=index;
    call(agetentx);
    checkfilerr;
    if filtyp<>chr(0) then begin { not end mark }
      if (fillnk and 255)<128 then begin {not deleted}
        entry[ti] := _new;
        s := entry[ti];
        filnam_to_str(s);
        write(@s, '.',
          hex(filcyc shr 4), hex(filcyc and 15));
        if full then begin
          day   := fildat[0]; { format: bcd}
          month := fildat[1];
          year  := fildat[2];
          write(@s,' ',day shr 4, day and 15);
          write(@s,'/',month shr 4, month and 15);
          write(@s,'/',year shr 4,year and 15);
        end;
        l := _strlen(s);
        if maxlen < l then maxlen := l;
        ti:=ti+1
      end else { deleted }
        sdel:=sdel+(filsiz shr 8);
    end else { end mark }
    sfree:=TSECTORS-filloc;
    index:=index+1
  until (index>MAXENT) or (filtyp=TEND);
  call(aenddo);
  nument:=ti-1;
  { fix position of filsiz in string }
  { now the lenght of the largest string is known}
  if full then begin
    for ti := 0 to nument do begin
      s := entry[ti];
      while _strlen(s) < maxlen do
        _strinsc(' ', _strlen(s) - 12, s);
    end;
  end;

{ sort table if requested }
  if sortit then sort;

{ compute number of columns and spaces between them }
  ncol:=48 div (maxlen+2);
  if nument<8 then ncol:=2
  else if nument<8 then ncol:=1;
  nspaces:=(48 div ncol)-maxlen-1;
  lines:=nument div ncol;

{ display table with columns and rows }
  for col:=0 to lines do
  begin
    for row:=0 to ncol-1 do begin
      ti:=col+(lines+1)*row;
      s:=entry[ti];
      if (ti<=nument) then begin
        write(s);
        l := _strlen(s);
        for i := l + 1 to maxlen + nspaces do
          write(' ');
      end
    end;
    writeln
  end;

{ display info at bottom of table }
  ffree:=conv(sfree)/conv(TSECTORS);
  fdel:=conv(sdel)/conv(TSECTORS);
  writeln('Free:', trunc(100.0*ffree+0.5),
    '%, deleted:',trunc(100.0*fdel+0.5),
    '%,',' entries:', index-1, '/',MAXENT);

{ Change back to original disk }
  if name_given then
    _change_disk(cfloppy,1);
end.
