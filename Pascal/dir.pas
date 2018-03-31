{
         *****************
         *               *
         *   dir drive   *
         *               *
         *****************

    2018 rricharz (r77@bluewin.ch)

Display the directory of a disk drive.
Uses EPROM (disk.asm) calls to get info
from disk directory.

Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.

Makes a table to find out how long the
longest name is. Then computes the number
of columns which can be displayed and
displays the directory.

Usage:  dir drive                   }

program dir;
uses syslib,arglib;

{R65 disk eprom calls and params: }
const aprepdo =$f4a7;
      agetentx=$f63a;
      aenddo  =$f625;
mem   filtyp  =$0300: char&;
      filcyc  =$0311: integer&;
      filstp  =$0312: char&;
      filloc  =$0313: integer;
      filsiz  =$0315: integer;
      fillnk  =$031e: integer;
      scyfc   =$037c: integer&;
      filerr=$db: integer&;

var default: boolean;
    drive,index,i,ti,maxlen,nument,col,
    ncol,row,nspaces,sfree,sdel,
    lines       : integer;
    { 1280 = 80 names of 20 chars }
    nametab     : array[1600] of char;
    filstptab   : array[80] of char;

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

begin
  drive:=0; {default drive}
  filerr:=0;
  agetval(drive,default);
  if (drive<0) or (drive>1) then begin
    writeln('Drive must be 0 or 1');
    abort
  end;
  fildrv:=drive;
  call(aprepdo);
  checkfilerr;

  scyfc:=79; { write disk name }
  call(agetentx);
  checkfilerr;

  write(tab8,'Directory drive ',
      drive,': ');
  for i:=0 to 15 do
    write(filnam[i]);
  writeln; writeln;

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
        for i:=0 to 19 do
          nametab[20*ti+i]:=' ';
        for i:=0 to 15 do
          nametab[20*ti+i]:=filnam[i];
        i:=20;
        repeat
          i:=i-1;
        until (i=0) or
          (nametab[20*ti+i]<>' ');
        nametab[20*ti+i+1]:='.';
        nametab[20*ti+i+2]:=hex(filcyc shr 4);
        nametab[20*ti+i+3]:=hex(filcyc and 15);
        if maxlen<i+3 then maxlen:=i+3;
        filstptab[ti]:=filstp;
        ti:=ti+1
      end else {deleted}
        sdel:=sdel+(filsiz shr 8);
    end else {end mark}
      sfree:=780-filloc;
    index:=index+1
  until (index>=79) or (filtyp=chr(0));
  call(aenddo);

  nument:=ti-1;
  ncol:=48 div (maxlen+2);
  if nument<8 then ncol:=2
  else if nument<8 then ncol:=1;
  nspaces:=(48 div ncol)-maxlen-1;
  lines:=nument div ncol;

  for col:=0 to lines do
  begin
    for row:=0 to ncol-1 do begin
      ti:=col+(lines+1)*row;
      if (ti<=nument) then begin
        if (filstptab[ti]='M') or
            (filstptab[ti]='R') then
          write(invvid);
        for i:=0 to maxlen do
          write(nametab[20*ti+i]);
        write(norvid);
        if row<(ncol-1) then
          for i:=1 to nspaces do write(' ')
      end
    end;
    writeln
  end;
  writeln;
  write('Sectors free: ',sfree,
    ', deleted: ',sdel);
end. 