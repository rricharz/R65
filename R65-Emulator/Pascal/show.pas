program show;
uses syslib, arglib,wildlib;

const clrscr=chr($11);
      cup=chr($1a);

var cyclus,drive,line,entry,i,first: integer;
    found,last,default: boolean;
    ch: char;
    name: array[15] of char;
    fno: file;

func mod(n, m: integer);
begin
  mod := n - (n div m) * m;
end;

proc setsubtype(subtype:char);
{ only set subtype if not already there }
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
    (name[i]=' ') or (i>=14);
  if name[i]<>':' then begin
    name[i]:=':';
    name[i+1]:=subtype;
  end;
end;

begin
  cyclus:=0; drive:=1; first:=1;
  agetstring(name,default,cyclus,drive);
  agetval(first,default);
  if first<1 then first:=1;
  entry := 0;
  setsubtype('P');
  findentry(name,drive,entry,found,last);
  if found then begin
    for i:=0 to 15 do
      name[i] := filnam[i];
    asetfile(name,cyclus,drive,' ');
    write(cup); { avoid empty line }
    openr(fno);
    writeln;
    line := 1;
    ch:='&';
    write(first,' '); { write first line number }
    repeat
      { skip lines }
      while (line<first) and (ch<>eof) do begin
        read(@fno,ch);
        if ch=cr then line:=line+1
      end;
      if ch<>eof then read(@fno, ch);
      { and write it }
      if ch<>eof then write(ch);
      if ch = cr then begin
        line := line + 1;
        writeln;
        write(line,' ');
      end;
      if (ch = cr) and (mod(line-first+1, 12) = 0)
          and (ch <> eof) then begin
        write(invvid, '<esc to exit>');
        read(@key,ch);
        write(norvid,cr,clrscr);
        if ch<>eof then write(line,' ');
      end;
      until (ch=eof) or (ch=chr(0));
    writeln;
  end else
    writeln('File not found');
end.
