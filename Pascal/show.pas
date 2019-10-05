{
         ******************
         *                *
         * Show(filename) *
         *                *
         ******************

            2018 rricharz

Written to test serial file input

Shows a serial file on the screen

Usage:  show(filename)
        show(filename,firstline)
    <return> to get one more line
    <space>  to get one more screen
    <others> quit

}

program show;
uses syslib,arglib;

const maxlines = 13;

var line, aline, value: integer;
    name: array[15] of char;
    fno: file;
    cyclus,drive: integer;
    default: boolean;
    ch,k: char;

{ * shownumber *}

proc shownumber;

begin
  writeln;
  write(invvid,'Line ',aline,':',norvid)
end;

{ * main * }

begin
  line := 0; aline:=1;
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,' ');
  openr(fno);

  value:=1;
  agetval(value,default);      {starting line}
  if value<1 then value:=1;
  if value>1 then begin
    repeat
      repeat
        read(@fno,ch);
      until (ch=eof) or(ch=cr);
      value:=prec(value);
      aline:=succ(aline);
    until (ch=eof) or (value<=1);
    if ch<>eof then read(@fno,ch);
    {read past cr}
  end
    else read(@fno,ch);

  shownumber;
  writeln;
  repeat
    if ch=cr then begin
      if (line>=maxlines) and (ch<>eof)
      then begin
        read(@key,k);
        case k of
          cr:  line:=line-1;{ one more line }
          ' ': begin { maxlines more lines}
                 line:=0;
                 shownumber
               end
          else line:=99     { stop }
        end {case}
      end;
      writeln;
      line:=succ(line);
      aline:=succ(aline);
    end
    else
      if (ch<>eof) then write(ch);
    end;
    read(@fno,ch);
  until (ch=eof) or (line>maxlines);
  close(fno);
end.

