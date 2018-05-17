{
         *****************
         *               *
         *  clean drive  *
         *               *
         *****************

    2018 rricharz (r77@bluewin.ch)

Clean disk. Only the latest cyclus of
each file is kept. Uses EPROM (disk.asm)
calls to get info from disk directory
and EXDOS delete.

Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.

Usage:  clean drive                   }

program clean;
uses syslib,arglib;

{R65 disk eprom calls and params: }
const aprepdo =$f4a7;
      agetentx=$f63a;
      aenddo  =$f625;
      adelete =$c80c;
mem   filtyp  =$0300: char&;
      filcyc  =$0311: integer&;
      filstp  =$0312: char&;
      filloc  =$0313: integer;
      filsiz  =$0315: integer;
      fillnk  =$031e: integer;
      scyfc   =$037c: integer&;
      filerr  =$db: integer&;

var default: boolean;
    drive,index,i,ti,maxlen,nument,sfree,
    sdel,sfound : integer;
    { 1280 = 80 names of 16 chars }
    nametab     : array[1280] of char;
    filstptab   : array[80] of char;
    cyctab      : array[80] of integer;
    foundtab    : array[80] of boolean;
    sizetab     : array[80] of integer;
    name        : array[15] of char;

proc bcderror(e:integer);
begin
  write('*** ERROR ');
  write((e shr 4) and 15);
  writeln(e and 15);
end;

func hex(d:integer):char;
{ convert hex digit to hex char }
begin
  if (d>=0) and (d<10) then
    hex:=chr(d+ord('0'))
  else if (d>=10) and (d<16) then
    hex:=chr(d+ord('A')-10)
  else hex:='?';
end;

proc mark(i3: integer);
{mark entry for delete}
var j: integer;
begin
  write('Found ');
  for j:=0 to maxlen do
    write(nametab[16*i3+j]);
  write('.');
  writeln(hex(cyctab[i3] shr 4),
          hex(cyctab[i3] and 15));
  foundtab[i3]:=true
end;

proc check(i1,i2: integer);
{check and mark entries for delete}
var j: integer;
begin
  if filstptab[i2]='Q' then mark(i2)
  else begin
    j:=-1;
    repeat
     j:=j+1;
      until (j>maxlen) or
           (nametab[16*i1+j]<>
          nametab[16*i2+j]);
    if j>maxlen then mark(i1)
  end
end;

begin
  drive:=0; {default drive}
  agetval(drive,default);
  if (drive<0) or (drive>1) then begin
    writeln('Drive must be 0 or 1');
    abort
  end;
  fildrv:=drive;
  call(aprepdo);

  scyfc:=79; { write disk name }
  call(agetentx);
  write(tab8,'Cleaning drive ',
      drive,': ');
  for i:=0 to 15 do
    write(filnam[i]);
  writeln; writeln;

  index:=0; ti:=0; maxlen:=0;
  sdel:=0; sfound:=0;
  repeat
    scyfc:=index;
    call(agetentx);
    { check for end mark }
    if filtyp<>chr(0) then begin
      { check for deleted flag }
      if (fillnk and 255)<128 then begin
        for i:=0 to 15 do
          nametab[16*ti+i]:=filnam[i];
        i:=16;
        repeat
          i:=i-1;
        until (i=0) or
          (nametab[16*ti+i]<>' ');
        if maxlen<i then maxlen:=i;
        filstptab[ti]:=filstp;
        cyctab[ti]:=filcyc;
        foundtab[ti]:=false;
        sizetab[ti]:=filsiz shr 8;
        for i:=0 to ti-1 do
          if (foundtab[i]=false) and
               (foundtab[ti]=false) then
            check(i,ti);
        ti:=ti+1
      end else {deleted}
        sdel:=sdel+(filsiz shr 8);
    end else {end mark}
      sfree:=780-filloc;
    index:=index+1
  until (index>=79) or (filtyp=chr(0));
  call(aenddo);
  nument:=ti;

  for ti:=0 to nument-1 do begin
    if foundtab[ti] then begin
      for i:=0 to 15 do
         name[i]:=nametab[16*ti+i];
         asetfile(name,cyctab[ti],drive,
               ' ');
      filerr:=0;
      call(adelete);
      if filerr<>0 then bcderror(filerr);
      sfound:=sfound+sizetab[ti];
    end
  end;

  writeln('Sectors free: ',sfree,
                ', found: ',sfound,
                ', now deleted: ',
                sdel+sfound);
  if (sdel+sfound)>0 then
    writeln('Use pack ',drive,
        ' to recover the deleted sectors');

end.  