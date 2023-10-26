program show;
uses syslib, arglib,wildlib;
 
const clrscr = chr(17);
 
var cyclus, drive, line, entry, i: integer;
    found, last, default: boolean;
    ch: char;
    name: array[15] of char;
    fno: file;
 
func mod(n, m: integer);
begin
  mod := n - (n div m) * m;
end;
 
begin
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  entry := 0;
  findentry(name,drive,entry,found,last);
  if found then begin
    for i:=0 to 15 do
      name[i] := filnam[i];
    asetfile(name,cyclus,drive,' ');
    openr(fno);
    writeln;  writeln;
    line := 1;
    repeat
      read(@fno, ch);
      if (ch <> eof) then write(ch);
      if ch = cr then begin
        line := line + 1;
        writeln;
      end;
      if (ch = cr) and (mod(line, 12) = 0)
          and (ch <> eof) then begin
        write(invvid, '<esc to exit>');
        read(@key,ch);
        if ch = chr(0) then ch := eof;
        write(norvid, cr, clrscr);
      end;
      until ch = eof;
  end else
    writeln('File not found');
end.
 