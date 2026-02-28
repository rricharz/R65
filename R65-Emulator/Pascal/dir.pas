{
         *******************
         *                 *
         *   dir <drive>   *
         *                 *
         *******************

    2018,2019 rricharz (r77@bluewin.ch)
    2023 removed inverse video display
    2023 default drive 1

Display the directory of a disk drive.
Uses EPROM (disk.asm) calls to get info
from disk directory.

Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.

Makes a table to find out how long the
longest name is. Then computes the number
of columns which can be displayed and
displays the directory.

option /S sorts the directory

Usage:  dir drive [/s]                   }

program dir;
uses syslib,arglib,strlib;

{R65 disk eprom calls and params: }
const aprepdo =$f4a7;
      agetentx=$f63a;
      aenddo  =$f625;
      tsectors = 2560;
      maxent  = 255;

mem   filtyp  =$0300: char&;
      filcyc  =$0311: integer&;
      filloc  =$0313: integer;
      filsiz  =$0315: integer;
      fillnk  =$031e: integer;
      scyfc   =$037c: integer&;
      filerr  =$00db: integer&;

var default,sortit: boolean;
    drive,index,i,ti,maxlen,nument,col,
    ncol,row,nspaces,sfree,sdel,
    lines        : integer;
    ffree,fdel   : real;
    s            : cpnt;
    entry        : array[maxent] of cpnt;

{$I IOPTION:P}

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
    abort;
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
  drive:=1; {default drive}
  filerr:=0;
  if argtype[carg]='i' then agetval(drive,default);
  if (drive<0) or (drive>1) then begin
    writeln('Drive must be 0 or 1');
    abort
  end;
  if option('H') then begin
    writeln('/S   sort directory');
    exit;
  end;
  sortit:=option('S');
  fildrv:=drive;
  call(aprepdo);
  checkfilerr;

  scyfc:=255; { write disk name }
  call(agetentx);
  checkfilerr;

  write(invvid,'Directory drive ',drive,': ');
  for i:=0 to 15 do
    write(filnam[i]);
  writeln(norvid);

  index:=0; ti:=0; maxlen:=0;
  sdel:=0;
  repeat
    scyfc:=index;
    call(agetentx);
    checkfilerr;
    { check for end mark }
    if filtyp<>chr(0) then begin
      { check for deleted flag }
      if (fillnk and 255)<128 then begin
        entry[ti]:=new;
        s:=entry[ti];
        for i:=0 to 15 do s[i]:=filnam[i];
        for i:=16 to 20 do s[i]:=' ';
        i:=20;
        repeat
          i:=i-1;
        until (i=0) or
          (s[i]<>' ');
        s[i+1]:='.';
        s[i+2]:=hex(filcyc shr 4);
        s[i+3]:=hex(filcyc and 15);
        if maxlen<i+3 then maxlen:=i+3;
        ti:=ti+1
      end else {deleted}
        sdel:=sdel+(filsiz shr 8);
    end else {end mark}
      sfree:=tsectors-filloc;
    index:=index+1
  until (index>=255) or (filtyp=chr(0));
  call(aenddo);

  nument:=ti-1;
  if sortit then sort;
  ncol:=48 div (maxlen+2);
  if nument<8 then ncol:=2
  else if nument<8 then ncol:=1;
  nspaces:=(48 div ncol)-maxlen-1;
  lines:=nument div ncol;

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
  ffree:=conv(sfree)/conv(tsectors);
  fdel:=conv(sdel)/conv(tsectors);
  writeln('Free:',sfree,'(',
    trunc(100.0*ffree+0.5),
    '%),deleted:',sdel,'(',
    trunc(100.0*fdel+0.5),'%),',
    'files:',index-1);
end.
