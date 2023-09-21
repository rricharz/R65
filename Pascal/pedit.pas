program pedit;

uses syslib, arglib;

const
    linelength = 56;
    scrlins = 16;
    maxlines = 25;
    eol    = chr($0);
    clrscr = chr($11);
    clrlin = chr($17);
    cdown  = chr($18);
    cup    = chr($1a);
    esc    = chr($0);

mem
    memory = 0: array[32767] of char&;
    curlin = $ed: integer&;
    curpos = $ee: integer&;
    video  = $400: array[768] of char&;

var line, nlines, topline: integer;
    name: array[15] of char;
    fno: file;
    chi : char;
    cyclus,drive: integer;
    default, iseof, exit: boolean;
    linepnt: array[maxlines] of integer;

proc setnumlin(l,c:integer);
mem numlin=$1789: integer&;
    numchr=$178a: integer&;
begin
  numlin:=l;
  numchr:=c;
end;

func new:integer;
begin
  endstk := endstk-linelength-1; {space for eol}
  new := endstk + 144;
end;

proc endheap;
begin
  endstk := topmem - 144;
end;

func column:integer;
begin
  column:=line-topline+1;
end;

func readline(fin: file; pnt: integer): boolean;
var ch1: char;
    pos: integer;
begin
  pos := 0;
  read(@fno,ch1);
  while (ch1<>eof) and (ch1<>cr) and (ch1<>eol)
    and (pos<=linelenght-1) do begin
    memory[pnt+ pos] := ch1;
    pos := pos + 1;
    read(@fno,ch1);
    end;
  memory[pnt + pos] := eol;
  readline := (ch1 = eof);
end;

proc goto(xpos, ypos: integer);
begin
  curlin := ypos; { top on line 2 }
  if curlin>15 then curlin:=15;
  curpos := xpos - 1;
end;

proc showline(pnt,y: integer);
var ch1: char;
    pos: integer;
begin
  pos := 0;
  write(clrlin);
  if memory[pnt]<>eol then
    repeat
      ch1 := memory[pnt + pos];
      pos := pos + 1;
      write(ch1);
      until (ch1=eol) or (pos>=linelenght);
end;

proc showtop;
begin
  goto(1,0);
  write(invvid,clrlin);
  write('line ', line, ' of ',nlines-1);
  write(' top ',topline);
  write(norvid);
end;

proc showall;
var y: integer;
begin
  showtop;
  for y:=1 to scrlins-1 do begin
    goto(1, y);
    showline(linepnt[topline-1+y],y);
  end;
end;

proc updline(pnt,lstart: integer);
var pos: integer;
begin
  memory[pnt+linelenght-1]:=eol;
  pos:=linelenght-1;
  while (video[lstart+pos]=' ') and
    (pos>0) do begin
    {remove trailing blanks}
    memory[lstart+pos]:=eol;
    pos:=pos-1;
  end;
  while pos>=0 do begin
    memory[pnt+pos]:=video[lstart+pos];
    pos:=pos-1;
  end;
end;

func edlin(pnt: integer): char;
const key    = @1;
      cleft  = chr($03);
      inschr = chr($15);
var   ch1: char;
      exit: boolean;
      lstart: integer;
begin
  goto(1,column);
  write(cleft); {to update cursor}
  exit:=false;
  lstart:=column*linelenght;
  repeat
    read(@key,ch1);
    case ch1 of
      inschr: if video[lstart+linelength-1]
              = ' ' then write(ch1);
      cup,cdown,esc: exit:=true
      else    write(ch1)
    end {case};
    until exit;
  updline(pnt,lstart);
  edlin := ch1;
end;

proc chkline;
begin
  if line<1 then line:=1
  else if line>nlines-1 then line:=nlines-1;
end;

proc chktop;
var savetop,bottom:integer;
begin
  savetop:=topline;
  bottom:=topline+scrlins-1;
  if line<topline then topline:=line;
  if line>=bottom then
    topline:=line-scrlins+2;
  if savetop<>topline then showall;
end;

func doesc: boolean;
{ escape handler }
const xpos = 36;
var ch:char;
begin
  doesc:=false;
  goto(xpos,0);
  write(invvid,'q',norvid,'uit, ',invvid,
    'l',norvid,'ine',invvid,'n',norvid,'?');
  read(@input,ch);
  case ch of
    'q': doesc:=true;
    'l': begin
           read(@input,line);
           chkline;
           chktop;
         end
  end {case};
  goto(xpos,0); write(clrlin);
end;

begin

  { Open input file }
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,' ');
  openr(fno);
  write(hom, clrscr);

  setnumlin($0f,$37);

  { Read and store lines from input file }
  nlines := 1;
  line:=1;
  topline:=1;
  repeat
    linepnt[nlines] := new;
    iseof := readline(fno, linepnt[nlines]);
    nlines := nlines+1;
    showtop;
    until iseof or (nlines >= maxlines);
  close(fno);
  topline := 1
  line := 1;
  showall;
  exit:=false;
  repeat
    showtop;
    chi := edlin(linepnt[line]);
    case chi of
      cup: begin
             line:=line-1;
             chkline;
             chktop;
           end;
      cdown: begin
             line:=line+1;
             chkline;
             chktop;
{          if nlines<maxlines then
             begin
               linepnt[nlines]:=new;
               memory[linepnt[nlines]]:=' ';
               memory[linepnt[nlines]+1]:=eol;
               nlines:=nlines+1;
               topline:=topline+1;
               line:=line+1;
               showall;
             end;        }
           end;
      esc: if doesc then exit:=true
    end {case};
    until exit;

  setnumlin($29,$2f);
  writeln(hom, clrscr, 'closing...');
  endheap;
  close(fno);

end.