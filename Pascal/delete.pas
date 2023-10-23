 {
         *****************
         *               *
         *    delete     *
         *               *
         *****************
 
    2018 rricharz (r77@bluewin.ch)
    2023 added wildcards
 
Delete a file.
 
Written 2018 to test the R65 emulator and
to demonstrate the power of Tiny Pascal.
 
Usage:  delete filnam[:x][.cy][,drive]
 
  [:X]:    type of file,     default :P
  [drive]: disk drive (0,1), default 1
 
Wild cards * and ? are allowed
}
 
program delete;
uses syslib,arglib,wildlib;
 
const adelete=$c80c; { exdos vector }
      prflab     = $ece3;
 
mem filerr=$db: integer&;
 
var cyclus,scyclus,drive,entry,fcount,i: integer;
    name,savename: array[15] of char;
    default,found,last: boolean;
 
proc bcderror(e:integer);
begin
  write(invvid,'ERROR ');
  write((e shr 4) and 15);
  writeln(e and 15,norvid);
end;
 
begin
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  scyclus:=cyclus;
  fcount:=0; last:=false; entry:= 0;
  while (entry<numentries) and not last do begin
    cyclus:=scyclus;
    findentry(name,drive,entry,found,last);
    if found and (not last) and
        ((scyclus=0) or (scyclus=filcyc)) then begin
      for i:=0 to 15 do begin
        savename[i]:=name[i];
        name[i]:=filnam[i];
      end;
      asetfile(name,filcyc,drive,' ');
      call(prflab); writeln;
      call(adelete);
      if filerr<>0 then begin
        bcderror(filerr);
        last:=true;
      end;
      fcount:=fcount+1;
      for i:=0 to 15 do
        name[i]:=savename[i];
    end;
  end;
  if fcount=0 then
    writeln(invvid,'No files found',norvid)
  else
    writeln(fcount, ' files deleted');
end.
 