program pedit;
 
{ Pascal editor, original 1980 RR
  rewritten 2023 RR for R65 system }
 
uses syslib, arglib, heaplib;
 
const
    scrlins = 16; maxfs = 20; line1x = 20;
    eol    = chr($00); esc    = chr($00);
    pgdown = chr($02); pgup   = chr($08);
    pgend  = chr($10); clrscr = chr($11);
    clrlin = chr($17); cdown  = chr($18);
    cup    = chr($1a); cleft  = chr($03);
    inschr = chr($15); delchr = chr($19);
    rubout = chr($5f); cright = chr($16);
 
mem memory = 0: array[32767] of char&;
    curlin = $ed: integer&;
    curpos = $ee: integer&;
    video  = $400: array[768] of char&;
    patchesc=$230c:integer; {patch interpreter!}
 
var line, nlines, topline: integer;
    name: array[15] of char;
    fno: file;
    chi : char;
    cyclus,drive,mark,nmark,savecx: integer;
    default, iseof, exit: boolean;
 
    fs: array[maxfs] of char;
 
proc setnumlin(l,c:integer);
mem numlin=$1789: integer&;
    numchr=$178a: integer&;
begin
  numlin:=l; numchr:=c;
end;
 
func column:integer;
begin
  column:=line-topline+1;
end;
 
func readline(fin: file; pnt: integer): boolean;
const alteof=chr(127);
var ch1: char;
    pos: integer;
begin
  pos := 0; read(@fno,ch1);
  while (ch1>=' ') and (ch1<>alteof) and
      (pos<xmax-1) do begin
    memory[pnt+pos]:=ch1; pos:=pos+1; read(@fno,ch1);
    end;
  while pos<xmax do begin
    memory[pnt+pos]:=' '; pos:=pos+1;
  end;
  readline:=(ch1=eof) or (ch1=alteof);
end;
 
proc goto(xpos, ypos: integer);
begin
  curlin:=ypos; { top on line 2 }
  if curlin>15 then curlin:=15;
  curpos:=xpos-1;
end;
 
proc showline(pnt,y: integer);
var lstart,pos: integer;
begin
  lstart:=y*xmax;
  for pos:=0 to xmax-1 do
    video[lstart+pos]:=memory[pnt+pos]
end;
 
proc showtop;
begin
  goto(1,0); write(invvid,clrlin);
  write('line ', line, ' of ',nlines-1,norvid);
end;
 
proc showerror(s:array[15] of char);
var i: integer;
    ch: char;
begin
  goto(line1x,0); write(invvid,clrlin);
  for i:=0 to 15 do write(s[i]);
  read(@input,ch);
  goto(line1x,0); write(norvid,clrlin);
end;
 
proc showall;
var y,i,l,lstart: integer;
begin
  showtop;
  for y:=1 to scrlins-1 do begin
    l:=topline-1+y; lstart:=y*xmax;
    if l<nlines then
      showline(linepnt[l],y)
    else
      for i:=0 to xmax-1 do
        video[lstart+i]:=' ';
  end;
end;
 
proc updline(pnt,lstart: integer);
var pos: integer;
begin
  for pos:=0 to xmax-1 do
    memory[pnt+pos]:=video[lstart+pos];
end;
 
func lastpos(l:integer):integer;
var endpos:integer;
begin
  endpos:=xmax-1;
  while (memory[linepnt[l]+endpos]
    =chr(ord(' ') and $7f))
    and (endpos>0) do endpos:=endpos-1;
  lastpos:=endpos;
end;
 
proc chkline;
begin
  if line<1 then line:=1
  else if line>nlines-1 then line:=nlines-1;
end;
 
proc chktop(show: boolean);
var savetop,bottom:integer;
begin
  savetop:=topline; bottom:=topline+scrlins-1;
  if line<topline then topline:=line;
  if line>=bottom then
    topline:=line-scrlins+2;
  if show and (savetop<>topline) then showall;
end;
 
proc delline;
var i,savpnt:integer;
begin
  chkline; savpnt:=linepnt[line];
  if line<mark then mark:=mark-1
  else if line<mark+nmark then nmark:=nmark-1;
  for i:=line to nlines-2 do
    linepnt[i]:=linepnt[i+1];
  release(savpnt); nlines:=nlines-1;
  chkline; chktop(false);
  line:=line-1; savecx:=1;
end;
 
proc join;
var p,p1,p2,pm:integer;
begin
  p1:=lastpos(line-1); p2:=lastpos(line);
  for p:=p1+1 to xmax-1 do
    memory[linepnt[line-1]+p]
      :=memory[linepnt[line]+p-p1-1];
  if p1+p2<xmax then delline
  else begin
    pm:=xmax-p1;
    for p:=0 to xmax-pm do
      memory[linepnt[line]+p]:=
        memory[linepnt[line]+p+pm-1];
    for p:=xmax-pm+1 to xmax-1 do
      memory[linepnt[line]+p]:=' ';
    line:=line-1;
  end;
  savecx:=p1+2; chkline; chktop(false); showall;
end;
 
func edlin(pnt: integer): char;
const key    = @1;
var   ch1: char;
      exit: boolean;
      lstart: integer;
begin
  goto(savecx,column);
  if savecx=1 then write(cright,cleft)
  else write(cleft,cright); {to update cursor}
  exit:=false; lstart:=column*xmax;
  repeat
    read(@key,ch1);
    case ch1 of
      inschr: if video[lstart+xmax-1]
              = ' ' then write(ch1);
      delchr,rubout: if (curpos=0) and (line>1)
             then begin
               updline(pnt,lstart) ;join; exit:=true;
               end
             else write(cleft,delchr);
      cup,cdown,esc,cr,
      pgup,pgdown,hom,pgend: exit:=true
      else begin
             if (ch1>=' ') and (ch1<chr($7f))
               then write(inschr);
             write(ch1);
             if curpos>=xmax-1 then
               write(cleft);
           end
    end {case};
    until exit;
  updline(pnt,lstart);
  edlin := ch1;
  if (ch1<>delchr) and (ch1<>rubout) then
    savecx:=curpos+1;
end;
 
proc readinput;
begin
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,'P');
  openr(fno); write(hom, clrscr); setnumlin($0f,$37);
  nlines := 1; line:=1; topline:=1;
  repeat
    linepnt[nlines] := new;
    iseof := readline(fno, linepnt[nlines]);
    nlines := nlines+1;
    showtop; write(invvid,' reading',norvid);
    until iseof or (nlines >= maxlines-1);
    if nlines >= maxlines-1 then
      showerror('too many lines  ');
 
  close(fno);
end;
 
proc writeoutput;
var pos,endpos,saveline:integer;
begin
  cyclus:=0; drive:=1;
  asetfile(name,cyclus,drive,'P');
  openw(fno);
  for line:=1 to nlines-1 do begin
    showtop; write(invvid,' writing',norvid);
    endpos:=lastpos(line);
    for pos:=0 to endpos do
      write(@fno,
        chr(ord(memory[linepnt[line]+pos])
        and $7f));
    if (line<nlines-1) or (endpos<>0) then
      write(@fno,cr);
  end;
  close(fno); line:=nlines-1;
end;
 
proc clrmarks;
var savel,x:integer;
begin
  savel:=line;
  for line:=1 to nlines-1 do begin
    for x:=0 to xmax-1 do
      memory[linepnt[line]+x]:=
        chr(ord(memory[linepnt[line]+x]) and $7f);
    showtop;
    end;
  line:=savel; mark:=0; nmark:=0;
end;
 
proc find(again:boolean);
var pos,x,i:integer;
    ch:char;
    found:boolean;
 
  proc checkrest;
  var failed:boolean;
      x1:integer;
  begin
    failed:=false; pos:=1; x1:=x+1;
    while (fs[pos]<>cr) and (pos<maxfs)
      and (x1<xmax) do begin
      if memory[linepnt[line]+x1] <> fs[pos]
        then failed:=true;
      pos:=pos+1; x1:=x1+1;
      end;
     if (failed=false) and (fs[pos]=cr)
      then found:=true;
  end;
 
begin
  pos:=0;
  if not again then begin
    goto(line1x,0);
    write(invvid,'find?',clrlin);
    repeat
      read(@input,ch); fs[pos]:=ch; pos:=pos+1;
      until (ch=cr) or (pos>=maxfs);
    write(norvid);
    end;
  if fs[0]=cr then begin
    {empty string -> delete all marks}
    clrmarks; showall;
    end
  else begin
    found:=false;
    repeat
      x:=0;
      repeat
        pos:=0;
        if memory[linepnt[line]+x]=fs[pos]
          then checkrest;
        x:=x+1;
        until found or (x>=xmax);
      showtop; line:=line+1;
      until found or (line>=nlines);
    if found then begin
      line:=line-1; x:=x-1; i:=0;
      while fs[i]<>cr do begin {*4*}
        memory[linepnt[line]+x+i] :=
          chr(ord(memory[linepnt[line]+x+i]) or $80);
         i:=i+1;
        end
      end
    else begin
      line:=nlines-1;
    end
  end
end;
 
proc insertline;
var i:integer;
begin
  if nlines<maxlines-1 then begin
    if line<mark then mark:=mark+1
    else if line<mark+nmark then nmark:=nmark+1;
    if line<nlines-1 then begin
      for i:=nlines-1 downto line+1 do
        linepnt[i+1]:=linepnt[i];
      end;
    linepnt[line+1]:=new;
    for i:=0 to xmax-1 do
      memory[linepnt[line+1]+i]:=' ';
    for i:=curpos to xmax-1 do begin
      memory[linepnt[line+1]+i-curpos]:=
        memory[linepnt[line]+i];
      memory[linepnt[line]+i]:=' ';
      end;
    line:=line+1; nlines:=nlines+1;
    savecx:=1; chkline; chktop(false); showall;
  end;
end;
 
proc paste;
var l,i:integer;
begin
  for i:=nlines-1 downto line do
    linepnt[i+nmark]:=linepnt[i];
  nlines:=nlines+nmark;
  if mark>line then mark:=mark+nmark;
  for l:=mark to mark+nmark-1 do begin
    linepnt[line]:=new;
    for i:=0 to xmax-1 do
      memory[linepnt[line]+i]:=memory[linepnt[l]+i];
    line:=line+1;
  end;
  showall;
end;
 
proc move;
var i,j,savepnt,saveline: integer;
begin
  saveline:=line; { insert above}
  if line>=mark+nmark then begin
    mark:=mark+nmark-1;
    for j:=0 to nmark-1 do begin
      savepnt:=linepnt[mark];
      for i:=mark to line-1 do
        linepnt[i]:=linepnt[i+1];
      mark:=mark-1; line:=line-1;
      linepnt[line]:=savepnt;
    end;
  end else if line<mark then begin
    for j:=0 to nmark-1 do begin
      savepnt:=linepnt[mark];
      for i:=mark downto line+1 do
        linepnt[i]:=linepnt[i-1];
      linepnt[line]:=savepnt;
      mark:=mark+1; line:=line+1;
    end;
  end else showerror('move inside move');
 mark:=saveline; line:=saveline; showall;
end;
 
func doesc: boolean;
var ch:char;
    i,n,savl:integer;
begin
  doesc:=false; goto(line1x,0); savecx:=1;
  write(invvid,'t,b,ln,f,g,cn,p,m,dn,w,q,k?');
  read(@input,ch); if ch<>cr then read(@input,n);
  case ch of
    't': begin {top}
           line:=1; chktop(true);
         end;
    'b': begin {bottom}
           line:=nlines-1; chktop(true);
         end;
    'l': begin {line number}
           line:=n; chkline; chktop(true);
         end;
    'f','g': begin {find string}
           find(ch='g'); chkline; chktop(false);
           showall;
         end;
    'c': begin {mark lines for copy}
           if n<1 then n:=1;
           if line+n>= nlines-1 then
             showerror('too many lines  ')
           else begin
             mark:=line; nmark:=n;
             for line:=mark to mark+nmark-1 do
               for i:=0 to xmax-1 do
                 memory[linepnt[line]+i]:=
          chr(ord(memory[linepnt[line]+i]) or $80);
             line:=mark;
           end;
           showall;
         end;
    'p': begin {paste marked lines}
           if mark=0 then showerror('nothing marked  ')
 
           else begin
 
             if nlines+nmark>=maxlines then
               showerror('too many lines  ')
             else paste;
           end;
         end;
    'm': begin {move marked lines }
           if mark=0 then showerror('nothing marked  ')
 
           else move;
 
         end;
    'd': begin {delete n lines}
           if n<1 then n:=1;
           if line+n=maxlines-3 then
             n:=maxlines-3-line;
           for i:=1 to n do begin
             delline; line:=line+1;
           end;
           chkline; chktop(false); showall;
         end;
    'w': writeoutput; {write output}
    'q': begin {write output and quit}
           writeoutput; doesc:=true;
         end;
    'k': doesc:=true {kill program}
    else showerror('unknown escape  ')
  end {case};
  goto(line1x,0); write(norvid,clrlin);
end;
 
begin {main}
  startheap(56);
  patchesc:=$eaea; {patch twice nop}
  mark:=0; nmark:=0; savecx:=1;
  readinput; fs[0]:=chr(0);
  topline:= 1; line:=1; showall; exit:=false;
  repeat
    showtop; chi := edlin(linepnt[line]);
    case chi of
      cup: begin
             line:=line-1; chkline; chktop(true);
           end;
      cdown: begin
             line:=line+1; chkline; chktop(true);
           end;
      pgup: begin
             line:=line-15; chkline; chktop(true);
           end;
      pgdown: begin
             line:=line+15; chkline; chktop(true);
           end;
      hom: begin
             line:=1; savecx:=1; chktop(true);
           end;
      pgend: begin
             line:=nlines-1; savecx:=1; chktop(true);
           end;
      cr:  insertline;
      esc: if doesc then exit:=true
    end {case};
    until exit;
  setnumlin($29,$2f);
  writeln(hom, clrscr, 'closing...');
  endheap;  patchesc:=$27b0; {restore original}
end.
 