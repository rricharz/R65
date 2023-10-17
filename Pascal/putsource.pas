 {
         *****************
         *               *
         *   putsource   *
         *               *
         *****************
 
    move the source file from the WORK disk
    on the disk SOURCEPASCAL or SOURCECOMPIL
 
    usage: putsource filename
 
    2019 rricharz (r77@bluewin.ch)
}
 
program putsource;
uses syslib,arglib;
 
const afloppy=$c827; { exdos vector }
 
mem filerr=$db: integer&;
 
var cyclus,drive,k: integer;
    fname,dname: array[15] of char;
    default,ok: boolean;
 
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
    writeln('Usage: putsource filename')
  else begin
    setsubtype('P');
      dname:='PSOURCE         ';
    { make sure that WORK is on drive 1 }
    writeln('Putting disk WORK in drive 1');
    cyclus:=0; drive:=1;
    asetfile('WORK            ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { make sure that dname is on drive 0 }
    write('Putting disk ');  writename(dname);
    writeln(' in drive 0');
    cyclus:=0; drive:=0;
    asetfile(dname,cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { clean WORK }
    writeln('Calling CLEAN 1');
    setargi(1,0);
    argtype[1]:=chr(0);
    cyclus:=0; drive:=0; filerr:=0;
    runprog('CLEAN:R         ',cyclus,drive);
    writeln;
    if (filerr<>0) or (runerr<>0) then
      ok:=false;
    { copy the source file }
    write('Calling COPY ');
    writename(fname);
    writeln(',1,0');
    setargs(fname,0,0,1);
    argtype[10]:='i';
    arglist[10]:=0; {copy to drive 0}
    argtype[11]:=chr(0);
    cyclus:=0; drive:=0; filerr:=0;
    runprog('COPY:R          ',cyclus,drive);
    writeln;
    if (filerr<>0) or (runerr<>0) then begin
      ok:=false;
      if filerr=6 then
        writeln(invvid,
          'Source file not found',norvid)
      else
        writeln(invvid,'Copy failed',norvid);
    end else begin {if successfull}
      { delete the source file }
      setargi(filcyc,8);
      writeln('Deleting the original file');
      drive:=0; filerr:=0;
      runprog('DELETE:R        ',cyclus,drive);
      writeln;
      if (filerr<>0) or (runerr<>0) then  begin
        ok:=false;
        writeln(invvid,
          'Deleting original failed',norvid);
      end;
      { clean the destination drive }
      writeln('Calling CLEAN 0');
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('CLEAN:R         ',cyclus,drive);
      writeln;
      if (filerr<>0) or (runerr<>0) then
         ok:=false;
      { pack the destination drive }
      writeln('Calling PACK 0');
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('PACK:R          ',cyclus,drive);
      writeln;
      if (filerr<>0) or (runerr<>0) then
         ok:=false;
    end;
    { make sure that PASCAL is on drive 0 }
    writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
  end;
  if not ok then begin
    writeln(invvid,'Putsource failed',norvid);
    filerr:=0; runerr:=0;
  end;
end.
 