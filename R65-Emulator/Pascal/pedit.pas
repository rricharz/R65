program pedit;

{ Pascal editor, original 1980 RR
  rewritten 2023 RR for R65 system }

uses syslib, arglib, strlib,disklib;

const
    maxlines= 360;      xmax   = 56;
    scrlins = 16;       mlenght= 19;
    inpx    = 37;
    eol     = chr($00); esc    = chr($00);
    rdown   = chr($02); rup    = chr($08);
    pgdown  = chr($1a); pgup   = chr($18);
    pgend   = chr($10); clrscr = chr($11);
    clrlin  = chr($17); cdown  = chr($18);
    cup     = chr($1a); cleft  = chr($03);
    inschr  = chr($15); delchr = chr($19);
    rubout  = chr($5f); cright = chr($16);

mem curlin  = $ed: integer&;
    curpos  = $ee: integer&;
    filcyc  = $311: integer&;
    video   = $400: array[900] of char&;
    topi    = $400: array[xmax] of integer&;
    topc    = $400: array[xmax] of char&;


var line,nlines,topline,i,dummy,debug: integer;
    name: array[15] of char;
    fno: file;
    chi : char;
    cyclus,drive,mark,nmark,savecx: integer;
    default, iseof, exit: boolean;
    fs: cpnt;
    linepnt: array[maxlines] of cpnt;
    relpnt:  integer;
    stemp,stemp2: cpnt;

func printable(ch:char):boolean;
begin
  printable:=((ord(ch)>=$20) and (ord(ch)<=$7e))
    and (ch<>rubout);
end;

proc putontop(s:cpnt;pos:integer;inv:boolean);
var i:integer;
begin
  i:=0; { faster version: if not in loop }
  if inv then while s[i]<>endmark do begin
    topi[i+pos]:=ord(s[i]) or 128; i:=i+1;
  end else while s[i]<>endmark do begin
    topc[i+pos]:=s[i]; i:=i+1;
  end;
end;

proc release(p:cpnt);
begin
  linepnt[relpnt]:=p; relpnt:=relpnt-1;
end;

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

proc goto(xpos, ypos: integer);
begin
  curlin:=ypos; { top on line 2 }
  if curlin>15 then curlin:=15;
  curpos:=xpos-1;
end;

proc clrmessage;
var i:integer;
begin
  for i:=inpx-1 to xmax-1 do topi[i]:=128;
end;

proc showerror(s:cpnt);
var i: integer;
    ch: char;
begin
  clrmessage;
  putontop(s,36,true);
  read(@key,ch);
  clrmessage;
end;

func new:cpnt;
var i:integer;
    s:cpnt;
begin
  if relpnt<maxlines-1 then begin
    relpnt:=relpnt+1; new:=linepnt[relpnt];
  end else begin
    if nlines<maxlines-1 then begin
      s:=strnew;
      for i:=0 to xmax-1 do s[i]:=' ';
      s[xmax]:=endmark;
      new:=s;
    end else new:=nil;
    if nlines>maxlines-5 then
      showerror('Warning: Low memory');
  end;
end;

proc newline;
begin
  linepnt[nlines]:=new;
  nlines:=nlines+1;
end;

proc getinput(var n:integer; s:cpnt);
var i,j,stop:integer; ch: char;
begin
  goto(inpx,0); write(chr(ord(':') or 128));
  read(@key,ch); i:=0;
  while (ch<>chr(13)) and (ch<>esc) do begin
    if (ch=rubout) then begin
      if i>0 then i:=i-1; goto(i+inpx+1,0);
      write(chr(ord(' ') or 128),cleft);
    end else if (ch>=' ') and (ch<=chr($7d)) and
      (inpx+i<xmax-1) then begin
      goto(i+inpx+1,0);
      write(chr(ord(ch) or 128)); i:=i+1;
    end;
    read(@key,ch);
  end;
  stop:=i+inpx;
  i:=inpx; n:=0;
  while ((topi[i] and 127)>=ord('0')) and
    ((topi[i] and 127)<=ord('9')) and
    (i<stop) do begin
    n:=10*n+(topi[i] and 127)-ord('0');
    i:=i+1;
  end;
  j:=0;
  while i<stop do begin
    s[j]:=chr(topi[i] and 127); i:=i+1; j:=j+1;
  end;
  s[j]:=endmark;
end;

func readline(input: file; pnt: cpnt): boolean;
const alteof=chr(127);
var ch1: char;
    pos: integer;
begin
  pos := 0; read(@fno,ch1);
  while (ch1>=' ') and (ch1<>alteof) and
      (pos<xmax-1) do begin
    pnt[pos]:=ch1; pos:=pos+1; read(@fno,ch1);
    end;
  while pos<xmax do begin
    pnt[pos]:=' '; pos:=pos+1;
  end;
  readline:=(ch1=eof) or (ch1=alteof);
end;

proc showline(pnt:cpnt; y: integer);
var lstart,pos: integer;
begin
  lstart:=y*xmax;
  if (pnt=nil) then
   for pos:=0 to xmax-1 do
    video[lstart+pos]:=' '
  else begin
    pos:=0;
    while (pos<xmax) and (pnt[pos]<>endmark) do begin
      video[lstart+pos]:=pnt[pos]; pos:=pos+1
    end;
    while pos<xmax do begin
      video[lstart+pos]:=' '; pos:=pos+1
    end
  end;
end;

proc showtop;
begin
  intstr(line,stemp,3); putontop(stemp,5,true);
  intstr(nlines-1,stemp,3); putontop(stemp,12,true);
end;

proc showall;
var lstart,y,i,l,lstart: integer;
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

proc updline(pnt: cpnt; lstart:integer);
var pos: integer;
begin
  for pos:=0 to xmax-1 do
    pnt[pos]:=video[lstart+pos];
end;

func lastpos(l:integer):integer;
{ returns -1 if line empty }
var endpos:integer;
    s:cpnt;
begin
  endpos:=xmax-1;
  s:=linepnt[l];
  while (chr(ord(s[endpos]) and $7f)=' ')
    and (endpos>0) do endpos:=endpos-1;
  if (endpos=0) and (chr(ord(s[endpos]) and $7f)=' ')
  then endpos:=-1;
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
  { keep cursor above bottom line, if possible }
  if line>=bottom-1 then
    topline:=line-scrlins+3;
  if show and (savetop<>topline) then showall;
end;

proc delline;
var i:integer; savpnt:cpnt;
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
    s1,s2:cpnt;
begin
  p1:=lastpos(line-1); p2:=lastpos(line);
  s1:=linepnt[line-1]; s2:=linepnt[line];
  for p:=p1+1 to xmax-1 do s1[p]:=s2[p-p1-1];
  if p1+p2<xmax then delline
  else begin
    pm:=xmax-p1;
    for p:=0 to xmax-pm do s2[+p]:=s2[p+pm-1];
    for p:=xmax-pm+1 to xmax-1 do s2[p]:=' ';
    line:=line-1;
  end;
  savecx:=p1+2; chkline; chktop(false); showall;
end;

func edlin(pnt: cpnt): char;
const key    = @1;
var   ch1,lstch1,lstch2: char;
      exit: boolean;
      lstart: integer;
begin
  goto(savecx,column);
  if savecx=1 then write(cright,cleft)
  else write(cleft,cright); {to update cursor}
  exit:=false; lstart:=column*xmax;
  repeat
    read(@key,ch1);
    lstch1:=' '; lstch2:=' ';
    case ch1 of
      delchr,rubout: if (curpos=0) and (line>1)
             then begin
               updline(pnt,lstart);join;exit:=true;
             end else write(cleft,delchr);
      cleft: if curpos>0 then write(cleft)
             else if line>1 then begin
               updline(pnt,lstart);
               line:=line-1; curpos:=lastpos(line)+1;
               exit:=true;
             end;
      cright:if curpos<xmax-1 then begin
               write(cright);
             end else if line<nlines-1 then begin
               updline(pnt,lstart);
               line:=line+1; curpos:=0;
               exit:=true;
             end;
      cup,cdown,esc,cr,rup,rdown,
      pgup,pgdown,hom,pgend: exit:=true
      else begin
             if printable(ch1) then begin
               lstch1:=video[lstart+xmax-1];
               lstch1:=chr(ord(lstch1) and $7f);
               lstch2:=video[lstart+xmax-2];
               lstch2:=chr(ord(lstch2) and $7f);
               if curpos>=xmax-1 then begin
                 if line>=nlines-1 then newline;
                 video[lstart+xmax-1]:=ch1;
                 curpos:=0;
                 lstch1:=cdown;
               end else begin
                 write(inschr); write(ch1);
               end;
               if (lstch1<>' ') or (lstch2<>' ')
                 then exit:=true;
             end;
           end
    end {case};
    until exit;
  updline(pnt,lstart);
  if (lstch1<>' ') or (lstch2<>' ') then edlin:=lstch1
  else edlin:=ch1;
  if (ch1<>delchr) and (ch1<>rubout) then
    savecx:=curpos+1;
end;

proc readinput;
var i,pend:integer;
begin
  cyclus:=0; drive:=1;
  goto(1,1); write(clrscr);
  agetstring(name,default,cyclus,drive);
  asetfile(name,cyclus,drive,'P');
  openr(fno);
  nlines := 1; line:=1; topline:=1;
  pend:=15; while name[pend]=' ' do pend:=pend-1;
  for i:=0 to pend do stemp[i]:=name[i];
  stemp[pend+1]:=endmark;
  stradd(':P.',stemp);
  hexstr(filcyc,stemp2);
  stradd(stemp2,stemp);
  while strlen(stemp)<17 do stradd(' ',stemp);
  putontop(stemp,17,true);
  putontop('Reading',36,true);
  repeat
    linepnt[nlines] := new;
    iseof := readline(fno, linepnt[nlines]);
    nlines := nlines+1;
    showtop;
    until iseof or (nlines >= maxlines-9);
  if nlines >= maxlines-9 then
      showerror('Too many lines');
  close(fno);
  clrmessage;
  showall;
end;

proc writeoutput;
var pos,endpos:integer;s,saveline:cpnt;
begin
  cyclus:=0; drive:=1;
  goto(1,1); write(clrscr);
  asetfile(name,cyclus,drive,'P');
  openw(fno);
  putontop('Writing',36,true);
  for line:=1 to nlines-1 do begin
    showtop;
    endpos:=lastpos(line);
    s:=linepnt[line];
    for pos:=0 to endpos do
      write(@fno,chr(ord(s[pos]) and $7f));
    if (line<nlines-1) then write(@fno,cr);
  end;
  close(fno); line:=nlines-1;
  showall;
end;

proc clrmarks;
var x,savel:integer; s:cpnt;
begin
  savel:=line;
  for line:=1 to nlines-1 do begin
    s:=linepnt[line];
    for x:=0 to xmax-1 do
      s[x]:=chr(ord(s[x]) and $7f);
    showtop;
    end;
  line:=savel; mark:=0; nmark:=0;
end;

proc find(again:boolean);
var pos,x,i:integer;
    ch:char;
    found:boolean;
    s2:cpnt;

  proc checkrest;
  var failed:boolean;
      x1:integer;
      s1:cpnt;
  begin
    failed:=false; pos:=3; x1:=x+1;
    while (fs[pos]<>endmark) and (x1<xmax) do begin
      s1:=linepnt[line];
      if s1[x1] <> fs[pos] then failed:=true;
      pos:=pos+1; x1:=x1+1;
      end;
     if (failed=false) and (fs[pos]=endmark)
      then found:=true;
  end;

begin
  clrmessage;
  if not again then strcpy(stemp,fs);
  if fs[1]=endmark then begin
    {empty string -> delete all marks}
    putontop('Clearing marks',36,true);
    clrmarks; showall;
    end
  else begin
    putontop('Searching',36,true);
    found:=false;
    repeat
      x:=0;
      repeat
        pos:=2;
        s2:=linepnt[line];
        if s2[x]=fs[pos] then checkrest;
        x:=x+1;
        until found or (x>=xmax);
      showtop; line:=line+1;
      until found or (line>=nlines);
    if found then begin
      line:=line-1; x:=x-1; i:=2;
      s2:=linepnt[line];
      while fs[i]<>endmark do begin
        s2[x+i-2]:=chr(ord(s2[x+i-2]) or $80);
         i:=i+1;
        end
      end
    else begin
      line:=nlines-1;
    end;
  end
end;

proc insertline;
var i:integer;
    s1,s2:cpnt;
begin
  if nlines<maxlines-1 then begin
    if line<mark then mark:=mark+1
    else if line<mark+nmark then nmark:=nmark+1;
    if line<nlines-1 then begin
      for i:=nlines-1 downto line+1 do
        linepnt[i+1]:=linepnt[i];
      end;
    linepnt[line+1]:=new;
    s1:=linepnt[line+1]; s2:=linepnt[line];
    for i:=0 to xmax-1 do s1[i]:=' ';
    for i:=curpos to xmax-1 do begin
      s1[i-curpos]:=s2[i]; s2[i]:=' ';
      end;
    line:=line+1; nlines:=nlines+1;
    savecx:=1; chkline; chktop(false); showall;
  end;
end;

proc paste;
var l,i:integer; s1,s2:cpnt;
begin
  if nlines+nmark<nlines-5 then begin
    for i:=nlines-1 downto line do
      linepnt[i+nmark]:=linepnt[i];
    nlines:=nlines+nmark;
    if mark>line then mark:=mark+nmark;
    for l:=mark to mark+nmark-1 do begin
      linepnt[line]:=new;
      s1:=linepnt[line]; s2:=linepnt[l];
      for i:=0 to xmax-1 do s1[i]:=s2[i];
      line:=line+1;
    end;
    showall;
  end else showerror('Error: Out of memory');
end;

proc move;
var i,j,saveline:integer; savepnt:cpnt;
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
  end else showerror('Move inside move');
 mark:=saveline; line:=saveline; showall;
end;

func doesc: boolean;
var ch:char;
    i,n:integer;
    s,savl:cpnt;
begin
  clrmessage;
  doesc:=false; savecx:=1;
  getinput(n,stemp); ch:=stemp[0];
  if (strlen(stemp)>1) and (stemp[1]<>' ') then
    showerror('Expected f: xxx')
  else begin
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
               showerror('Too many lines')
             else begin
               mark:=line; nmark:=n;
               for line:=mark to mark+nmark-1 do
               begin
                 s:=linepnt[line];
                 for i:=0 to xmax-1 do
                   s[i]:= chr(ord(s[i]) or $80);
               end;
               line:=mark;
             end;
             showall;
           end;
      'p': begin {paste marked lines}
             if mark=0 then
               showerror('Nothing marked')
             else begin
               if nlines+nmark>=maxlines then
                 showerror('Too many lines')
               else paste;
             end;
           end;
      'm': begin {move marked lines }
             if mark=0 then
               showerror('Nothing marked')
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
      'k': doesc:=true; {kill program}
      '?','h': showerror('tb/l/fg/cpm/d/wqk/?h');
      endmark: begin end
      else showerror('tb/l/fg/cpm/d/wqk/?h')
    end {case};
  end;
  clrmessage;
end;

proc newline;
begin
  linepnt[nlines]:=new; nlines:=nlines+1;
end;

proc insert(ch:char;l:integer);
{ insert char at start of line (recursive) }
var i,y:integer;
    pnt:cpnt;
    lstch1,lstch2:char;
begin
  if l>=nlines then newline;
  pnt:=linepnt[l];
  lstch1:=chr(ord(pnt[xmax-1]) and $7f);
  lstch2:=chr(ord(pnt[xmax-2]) and $7f);
  if (lstch1<>' ') or (lstch2<>' ')
    then insert(lstch1,l+1);
  for i:=xmax-2 downto 0 do pnt[i+1]:=pnt[i];
  pnt[0]:=ch; y:=l-topline+1;
  if (y>0) and (y<scrlins) then showline(pnt,y);
end;

begin {main}
  for i:=0 to maxlines-1 do linepnt[i]:=nil;
  stemp:=strnew; stemp2:=strnew; fs:=strnew; debug:=0;
  setnumlin($0f,$37); write(hom,clrscr);
  putontop('Line xxx of xxx',0,true);
  relpnt:=maxlines-1; mark:=0; nmark:=0; savecx:=1;
  clrmessage; readinput; fs[0]:=endmark;
  putontop('R65 PEDIT V 2.10',36,true);
  topline:= 1; line:=1; showall; exit:=false;
  repeat
    showtop; chi := edlin(linepnt[line]);
    if printable(chi) then insert(chi,line+1)
    else case chi of
      cup,cdown: begin
             if chi=cup then line:=line-1
             else line:=line+1;
             chkline;
             if curpos>lastpos(line)+2 then
               savecx:=lastpos(line)+2;
             chktop(true);
           end;
      pgup: begin
             line:=line-15; chkline; chktop(true);
           end;
      pgdown: begin
             line:=line+15; chkline; chktop(true);
           end;
      rup: if (topline>1) then begin
             topline:=topline-1;chktop(false);showall;
           end;
      rdown: if (topline<nlines-15) then begin
             topline:=topline+1;chktop(false);showall;
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
  writeln(hom, clrscr);
  dummy:=freedsk(fildrv,true);
end.
