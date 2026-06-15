
{         *****************                 }
{         *  clean drive  *                 }
{         *****************                 }

{    2018 rricharz (r77@bluewin.ch)         }

{ Clean disk. Only the latest cyclus of     }
{ each file is kept. Uses EPROM (disk.asm)  }
{ calls to get info from disk directory     }
{ and EXDOS delete.                         }

{ Usage:  clean [drive]                     }
{         default: drive 1                  }

{$U+}

program clean;
uses syslib,arglib,filelib,hexlib;

{R65 disk eprom calls and params: }
const
      aprepdo =$f4a7;
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

var default, quiet: boolean;
    drive,index,i,ti,maxlen,nument,sfree,
    sdel,sfound : integer;
    { array size = 16 * 256 }
    nametab     : array[4096] of char;
    filstptab   : array[255] of char;
    cyctab      : array[255] of integer;
    foundtab    : array[255] of boolean;
    sizetab     : array[255] of integer;
    name        : array[15] of char;

proc bcderror(e:integer);
begin
  writeln;
  write(INVVID,'ERROR ');
  write((e shr 4) and 15);
  writeln(e and 15,NORVID);
end;

proc mark(i3: integer);
{mark entry for delete}
var j: integer;
begin
  debug('mark',i3,quiet);
  if not quiet then begin
    write('Deleting ');
    for j:=0 to maxlen-1 do
      write(nametab[16*i3+j]);
    writeln('.',hexlow(cyctab[i3] shr 4));
  end;
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

begin { main }
  drive := 1; {default drive}
  if ARGTYPE[_carg] = 'i' then
    _agetval(drive,default);
  if (drive<0) or (drive>1) then begin
    writeln('Drive must be 0 or 1');
    _abort
  end;
  if ARGTYPE[_carg] = 's' then
    quiet := option('Q');

  FILDRV:=drive;
  call(aprepdo);

  scyfc:=255; { write disk name }
  call(agetentx);

  index:=0; ti:=0; maxlen:=0;
  sdel:=0; sfound:=0;
  repeat
    scyfc:=index;
    call(agetentx);
    { check for end mark }
    if filtyp<>chr(0) then begin
      { check for deleted flag }
      if (fillnk and 255)<128 then begin
        debug(ti);
        for i:=0 to 15 do
          nametab[16*ti+i]:=FILNAM[i];
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
      sfree:=2560-filloc;
    index:=index+1
  until (index>=255) or (filtyp=chr(0));
  call(aenddo);
  nument:=ti;

  for ti:=0 to nument-1 do begin
    if foundtab[ti] then begin
      for i:=0 to 15 do
         name[i]:=nametab[16*ti+i];
         _asetfile(name,cyctab[ti],drive,
               ' ');
      FILERR:=0;
      call(adelete);
      if FILERR<>0 then bcderror(FILERR);
      sfound:=sfound+sizetab[ti];
    end
  end;

  if not quiet then
    writeln('Free: ',sfree,', found: ',sfound,
      ', now deleted: ',sdel+sfound);

end.

