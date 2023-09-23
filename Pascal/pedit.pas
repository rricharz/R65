program pedit;

uses syslib, arglib;

const
    linelength = 56;
    scrlins = 16;
    maxlines = 400;
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
{**************************}
mem numlin=$1789: integer&;
    numchr=$178a: integer&;
begin
  numlin:=l;
  numchr:=c;
end;

func new:integer;
{***************}
begin
  endstk:=endstk-linelength-1; {space for eol}
  new:=endstk+144;
  writeln(@printer,'new ',endstk+144);
end;

proc endheap;
{***********}
begin
  endstk := topmem - 144;
end;

func column:integer;
{******************}
begin
  column:=line-topline+1;
end;

func readline(fin: file; pnt: integer): boolean;
{**********************************************}
const alteof=chr(127);
var ch1: char;
    pos: integer;
begin
  pos := 0;
  read(@fno,ch1);
  while (ch1>=' ') and (ch1<>alteof) and
      (pos<linelenght-1) do begin
    memory[pnt+ pos] := ch1;
    pos := pos + 1;
    read(@fno,ch1);
    end;
  while pos<linelenght do begin
    memory[pnt+ pos] := ' ';
    pos:=pos+1;
  end;
  readline:=(ch1=eof) or (ch1=alteof);
end;

proc goto(xpos, ypos: integer);
{*****************************}
begin
  curlin := ypos; { top on line 2 }
  if curlin>15 then curlin:=15;
  curpos := xpos - 1;
end;

proc showline(pnt,y: integer);
{****************************}
var lstart,pos: integer;
begin
  lstart:=y*linelenght;
  for pos:=0 to linelenght-1 do
    video[lstart+pos]:=memory[pnt+pos]
end;

proc showtop;
{***********}
begin
  goto(1,0);
  write(invvid,clrlin);
  write('line ', line, ' of ',nlines-1);
  write(norvid);
end;

proc showall;
{***********}
var y,i,l,lstart: integer;
begin
  showtop;
  for y:=1 to scrlins-1 do begin
    l:=topline-1+y;
    lstart:=y*linelenght;
    if l<nlines then
      showline(linepnt[l],y)
    else
      for i:=0 to linelenght-1 do
        video[lstart+i]:=' ';
  end;
end;

proc updline(pnt,lstart: integer);
{********************************}
var pos: integer;
begin
  for pos:=0 to linelenght-1 do
    memory[pnt+pos]:=video[lstart+pos];
end;

func edlin(pnt: integer): char;
{*****************************}
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
      cup,cdown,esc,cr: exit:=true
      else    begin
                write(ch1);
                if curpos>=linelenght-1 then
                  write(cleft);
              end
    end {case};
    until exit;
  updline(pnt,lstart);
  edlin := ch1;
end;

proc chkline;
{***********}
begin
  if line<1 then line:=1
  else if line>nlines-1 then line:=nlines-1;
end;

proc chktop(show: boolean);
{*************************}
var savetop,bottom:integer;
begin
  savetop:=topline;
  bottom:=topline+scrlins-1;
  if line<topline then topline:=line;
  if line>=bottom then
    topline:=line-scrlins+2;
  if show and (savetop<>topline) then showall;
end;

proc readinput;
{*************}
begin
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,' ');
  openr(fno);
  write(hom, clrscr);
  setnumlin($0f,$37);
  nlines := 1;
  line:=1;
  topline:=1;
  repeat
    linepnt[nlines] := new;
    iseof := readline(fno, linepnt[nlines]);
    nlines := nlines+1;
    showtop; write(invvid,' reading',norvid);
    until iseof or (nlines >= maxlines-4);
  close(fno);
end;

proc writeoutput;
{***************}
var pos,endpos,saveline:integer;
begin
  saveline:=line;
  cyclus:=0; drive:=1;
  asetfile(name,cyclus,drive,'P');
  openw(fno);
  for line:=1 to nlines-1 do begin
    showtop; write(invvid,' writing',norvid);
    endpos:=linelenght-1;
    while (memory[linepnt[line]+endpos]=' ')
      and (endpos>0) do endpos:=endpos-1;
    for pos:=0 to endpos do
      write(@fno,memory[linepnt[line]+pos]);
    write(@fno,cr,lf);
  end;
  write(@fno,eof);
  close(fno);
  line:=saveline;
end;

func doesc: boolean;
{******************}
const xpos = 28;
var ch:char;
  proc ctoeol;
  begin
    repeat
      read(@input,ch);
      until (ch<' ');
  end;
begin
  doesc:=false;
  goto(xpos,0);
  write(invvid,'q',norvid,'uit, ',invvid,
    'l',norvid,'ine',invvid,'n',norvid,
    ', ',invvid,'w',norvid,'rite?');
  read(@input,ch);
  case ch of
    'q': begin
           ctoeol;
           doesc:=true;
         end;
    'w': begin
           ctoeol;
           writeoutput;
         end;
    'l': begin
           read(@input,line);
           chkline;
           chktop(true);
         end
  end {case};
  goto(xpos,0); write(clrlin);
end;

proc appendline;
{**************}
var i:integer;
begin
  if nlines<maxlines-1 then begin
    if line<nlines-1 then begin
      for i:=nlines-1 downto line+1 do
        linepnt[i+1]:=linepnt[i];
      end;
    linepnt[line+1]:=new;
    for i:=0 to linelenght-1 do
      memory[linepnt[line+1]+i]:=' ';
    for i:=curpos to linelenght-1 do begin
      memory[linepnt[line+1]+i-curpos]:=
        memory[linepnt[line]+i];
      memory[linepnt[line]+i]:=' ';
      end;
    line:=line+1;
    nlines:=nlines+1;
    chkline;
    chktop(false);
    showall;
  end;
end;

begin {main}
  readinput;
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
             chktop(true);
           end;
      cdown: begin
             line:=line+1;
             chkline;
             chktop(true);
           end;
       cr: begin
             appendline;
           end;
      esc: if doesc then exit:=true
    end {case};
    until exit;

  setnumlin($29,$2f);
  writeln(hom, clrscr, 'closing...');
  endheap;

end.