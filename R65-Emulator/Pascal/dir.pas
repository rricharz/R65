{
         *******************
         *                 *
         *   dir <drive>   *
         *                 *
         *******************

    2018,2019 rricharz (r77@bluewin.ch)
    2023 removed INVERSE video display
    2023 default drive 1

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

program dir;
uses syslib,arglib,strlib;

const aprepdo =$f4a7;
      agetentx=$f63a;
      aenddo  =$f625;

      TSECTORS = 2560;   { size of disk in pages }
      MAXENT   = 255;    { max number of entries }
      TEND     = chr(0); { end mark of table }

mem   filtyp  =$0300: char&;
      FILCYC  =$0311: integer&;
      filloc  =$0313: integer;
      filsiz  =$0315: integer;
      fillnk  =$031e: integer;
      scyfc   =$037c: integer&;
      filerr  =$00db: integer&;

var default, name_given,
    sortit:              boolean;
    drive, index, i, ti,
    maxlen, nument, col,
    ncol, row, nspaces,
    sfree,sdel, lines:   integer;
    ffree, fdel:         real;
    s:                   cpnt;
    entry:               array[MAXENT] of cpnt;
    afloppy:             array[15] of char;
    cfloppy, newname:    cpnt;

{$I IOPTION:P}
{$I IARGCPNT:p}

func hex(d:integer):char;
{ convert hex digit to hex char }
begin
  if (d>=0) and (d<10) then
    hex:=chr(d+ord('0'))
  else if (d>=10) and (d<16) then
    hex:=chr(d+ord('A')-10)
  else hex:='?';
end;

proc checkfilerr;
begin
  if filerr<>0 then begin
    writeln('Cannot read directory');
    _abort;
  end;
end;

func smaller(pnt1,pnt2:cpnt):boolean;
var k:integer;
begin
  k:=0;
  while (pnt2[k]=pnt1[k]) and (k<15) do
    k:=k+1;
  smaller:=(pnt2[k]<pnt1[k]);
end;

proc sort;
var i,j:integer;
    savepnt:cpnt;
begin
  for i:=0 to nument-1 do
     for j:=nument-1 downto i do
       if smaller(entry[j],entry[j+1]) then begin
          savepnt:=entry[j];
          entry[j]:=entry[j+1];
          entry[j+1]:=savepnt;
       end;
end;

begin {main}
  cfloppy:=_new;
  newname:=_new;
  name_given:=false;
  drive:=1;
  filerr:=0;
  sortit:=false;
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
    aget_cpnt(newname);
    if newname[0]<>'/' then begin
      name_given:=true;
      _carg:=10;
    end else _carg:=0;
  end;
  if ARGTYPE[_carg]='s' then begin
      { check for option }
      sortit:=option('S');
  end;

{ read disk name (FILNAM in last directory entry) }
  FILDRV:=drive;
  call(aprepdo);
  checkfilerr;
  scyfc:=MAXENT;
  call(agetentx);
  checkfilerr;
  for i:=0 to 15 do afloppy[i]:=FILNAM[i];
  conv_to_cpnt(afloppy,cfloppy);
  if name_given then begin
    change_disk(newname, 1);
    drive:= 1;
    { read FILNAM again after disk has been changed }
    FILDRV:=drive;
    call(aprepdo);
    checkfilerr;
    scyfc:=MAXENT;
    call(agetentx);
    checkfilerr;
  end;

{ display info at top of table }
  write('Directory drive ',drive,': ');
  for i:=0 to 15 do
    write(FILNAM[i]);
  writeln;

{ read file table }
  index:=0; ti:=0; maxlen:=0;
  sdel:=0;
  repeat { for each entry in table }
    scyfc:=index;
    call(agetentx);
    checkfilerr;
    if filtyp<>chr(0) then begin { not end mark }
      if (fillnk and 255)<128 then begin {not deleted}
        entry[ti]:=_new;
        s:=entry[ti];
        for i:=0 to 15 do s[i]:=FILNAM[i];
        for i:=16 to 20 do s[i]:=' ';
        i:=20;
        repeat
          i:=i-1;
        until (i=0) or
          (s[i]<>' ');
        s[i+1]:='.';
        s[i+2]:=hex(FILCYC shr 4);
        s[i+3]:=hex(FILCYC and 15);
        if maxlen<i+3 then maxlen:=i+3;
        ti:=ti+1
      end else { deleted }
        sdel:=sdel+(filsiz shr 8);
    end else { end mark }
      sfree:=TSECTORS-filloc;
    index:=index+1
  until (index>MAXENT) or (filtyp=TEND); {end of table}
  call(aenddo);
  nument:=ti-1;

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
        for i:=0 to maxlen do
          write(s[i]);
        if row<(ncol-1) then
          for i:=1 to nspaces do write(' ')
      end
    end;
    writeln
  end;

{ display info at bottom of table }
  ffree:=conv(sfree)/conv(TSECTORS);
  fdel:=conv(sdel)/conv(TSECTORS);
  writeln('Free:', sfree, '(', trunc(100.0*ffree+0.5),
    '%),deleted:', sdel, '(',trunc(100.0*fdel+0.5),
    '%),', 'entries:', index-1, '/', MAXENT);

{ Change back to original disk }
  if name_given then
    change_disk(cfloppy,1);
end.
