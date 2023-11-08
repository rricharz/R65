{
         *****************
         *               *
         *   putobject   *
         *               *
         *****************

    move a object file from
    the WORK disk on the disk PASCAL

    usage: putobject filename

    2019 rricharz (r77@bluewin.ch)
}

program putobject;
uses syslib,arglib;

const afloppy=$c827; { exdos vector }

mem filerr=$db: integer&;

var cyclus,drive,k: integer;
    fname,dname: array[15] of char;
    default,ok,libflag: boolean;

func contains(t:array[7] of char):boolean;
{ check for substring in fname }
{ the substring must end with a blank }
var i,i1,j:integer;
    found:boolean;
begin
  i:=0; found:=false;
  repeat
    j:=0;
    if fname[i]=t[j] then begin
      i1:=i;
      repeat
        i1:=i1+1;
        j:=j+1;
        found:=t[j]=' ';
      until (i1>14) or (fname[i1]<>t[j])
                             or found;
    end;
    i:=i+1;
  until found or (i>15);
  contains:=found;
end;

proc runprog
  (name: array[15] of char;
   cyc: integer; drv: integer);
var i: integer;
begin
  for i:=0 to 15 do filnm1[i]:=name[i];
  filcy1:=cyc; fildrv:=drv; filflg:=$40;
  run
end;

proc writename(text: array[15] of char);
{ write name without blanks }
var i: integer;
begin
  for i:=0 to 15 do
    if text[i]<>' ' then write(text[i]);
end;

proc setsubtype(subtype:char);
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (fname[i]=':') or
    (fname[i]=' ') or (i>=14);
  fname[i]:=':';
  fname[i+1]:=subtype;
end;

func letter(ch:char):boolean;
begin
  letter:=(ch>='A') and (ch<='Z');
end;

proc setargs(name:array[15] of char;
  carg,cyc,drv:integer);
var k:integer;
begin
  argtype[carg]:='s';
    for k:=0 to 7 do
      arglist[carg+k]:=
        ord(packed(fname[2*k+1],
                    fname[2*k]));
    argtype[carg+8]:='i';
    arglist[carg+8]:=cyc;
    argtype[carg+9]:='i';
    arglist[carg+9]:=drv;
end;

proc setargi(val,carg:integer);
begin
  argtype[carg]:='i';
  arglist[carg]:=val;
end;

begin
  ok:=true;
  filerr:=0;
  { get the argument (file name) }
  cyclus:=0; drive:=0;
  agetstring(fname,default,cyclus,drive);
  if default or not letter(fname[0]) then
    writeln('Usage: putobject filename')
  else begin
    { make sure that WORK is on drive 1 }
    writeln('Putting disk WORK in drive 1');
    cyclus:=0; drive:=1;
    asetfile('WORK            ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { make sure that PASCAL is on drive 0 }
    writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { find out which files to copy }
    libflag := contains('LIB     ');
    { copy the object file(s) }
    argtype[10]:='i';
    arglist[10]:=0; {copy to drive 0}
    argtype[11]:=chr(0);
    cyclus:=0; drive:=0; filerr:=0;
    writeln('Copying the file(s)');
    if libflag then begin
      setsubtype('L');
      setargs(fname,0,0,1);
      runprog('COPY:R          ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then begin
        ok:=false;
      end else begin
        setsubtype('T');
        setargs(fname,0,0,1);
        runprog('COPY:R          ',cyclus,drive);
      end
    end else begin  { not a library }
      setsubtype('R');
      setargs(fname,0,0,1);
      runprog('COPY:R          ',cyclus,drive);
    end;
    if (filerr<>0) or (runerr<>0) then begin
      ok:=false;
      if filerr=6 then
        writeln(invvid,
             'Object file not found',norvid)
      else
        writeln(invvid,'Copy failed',norvid);
    end else begin {if successfull}
      { delete the original file }
      setargi(0,8);
      writeln('Deleting the original file(s)');
      drive:=0; filerr:=0;
      runprog('DELETE:R        ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then begin
        writeln(invvid,
          'Deleting original failed',norvid);
        ok:=false;
      end;
      if libflag then begin
        setsubtype('L');
        setargs(fname,0,0,1);
        runprog('DELETE:R        ',cyclus,drive);
        if (filerr<>0) or (runerr<>0) then begin
          writeln(invvid,
            'Deleting original failed',norvid);
          ok:=false;
        end;
      end;
      { clean the destination drive }
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('CLEAN:R         ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then
         ok:=false;
      { pack the destination drive }
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('PACK:R          ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then
         ok:=false;
    end;
  end;
  if (not ok) or (runerr<>0) then begin
    writeln(invvid,'Putobject failed',norvid);
    filerr:=0; runerr:=0;
  end;
end.
