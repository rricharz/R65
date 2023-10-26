{
 
                REVERSI
 
Pascal Program for Tiny Pascal
Adapted from Byte 4,11 (1979)
Original Basic version by Peter B. Maggs
 
Last change 06/02/80 rricharz
Recovered 2018-2023 by rricharz               }
 
program reversi;
uses syslib;
 
const tab8=chr($09);
      hom=chr($01);
      csc=chr($11);
 
var f {value for opponent's best reply
       to computer's best best play},
    g {value for opponent's best reply
       to computer's current play},
    h {value for opponent's current reply},
    j,k,l {counters},
    m,m1 {play},
    n {counter},
    p {player, black=-1, white=1},
    q {total moves},
    t,t3 {logical value},
    u {counter},
    v,w {to save play},
    z {counter}
 
        : integer;
 
    us {user colour},
    nextplay
 
        : char;
 
    b {board},
    e {value for board squares}
 
        : array[100] of integer;
 
    d {distance to next squares}
 
        : array[8] of integer;
 
    endplay {end of game flag}
        : boolean;
 
proc init; {initialize the game}
var n1,n2: integer;
begin
  writeln(hom,csc,tab8,'The game of Reversi');
  writeln(tab8,'*******************');
  writeln;
 
  e[11]:=0; e[12]:= 64; e[13]:=-30;
            e[14]:= 10; e[15]:=  5;
  e[21]:=0; e[22]:=-30; e[23]:=-40;
            e[24]:=  2; e[25]:=  2;
  e[31]:=0; e[32]:= 10; e[33]:=  2;
            e[34]:=  5; e[35]:=  1;
  e[41]:=0; e[42]:=  5; e[43]:=  2;
            e[44]:=  1; e[45]:=  1;
 
  for n1:=1 to 4 do {horizontal axis}
    for n2:=1 to 5 do
      e[10*n1+11-n2]:=e[10*n1+n2];
 
  for n2:=1 to 10 do {vertical axis}
    for n1:=1 to 4 do
      e[90-10*n1+n2]:=e[10*n1+n2];
 
  for n1:=1 to 100 do b[n1]:=0;
  for n1:=1 to 10 do begin
    b[n1]:=3; b[90+n1]:=3; b[10*n1-9]:=3;
    b[10*n1]:=3
  end;
  b[45]:=2; b[46]:=2; b[55]:=2; b[56]:=2;
 
  u:=5; q:=1; p:=1; m1:=0; t3:=0;
  endplay:=false;
 
  write('Would you like to be');
  write(' Black or White?');
  read(us);
end {init};
 
proc display; {display the board}
var mm,x,y: integer;
begin
  writeln('        1  2  3  4  5  6  7  8');
  for y:=8 downto 1 do begin
    write('     ',y);
    for mm:=10*y+2 to 10*y+9 do begin
      write('  ');
      if mm=m1 then write(invvid);
      case b[mm] of
         1: write('W');
        -1: write('B')
        else write('-')
      end {case};
      write(norvid);
    end {for};
    writeln('  ',y)
  end {for};
  writeln('        1  2  3  4  5  6  7  8');
end;
 
proc adjust; {adjust corner values}
begin
  case m of
    12: begin e[13]:=5; e[22]:=5; e[23]:=5 end;
    19: begin e[18]:=5; e[28]:=5; e[29]:=5 end;
    82: begin e[72]:=5; e[73]:=5; e[83]:=5 end;
    89: begin e[77]:=5; e[78]:=5; e[88]:=5 end
  end {case}
end;
 
proc evaluate;
var stop: boolean;
begin
  g:=0; z:=12; stop:=false;
  while (z<90) and (stop=false) do begin
    if b[z]=0 then z:=z+1
    else if b[z]=p then begin
      g:=g+e[z];
      if g>f then stop:=true else z:=z+1;
    end else begin
      g:=g-e[z]; z:=z+1
    end
  end
end;
 
proc makeplay; {make a play}
var j,n,k: integer;
begin
  t:=0;
  if b[m]=0 then begin
    n:=1;
    while n<9 do begin
      j:=d[n];
      if b[m+j]=-p then begin
        k:=m+j+j;
        while b[k]=-p do k:=k+j;
        if b[k]=p then begin
          t:=1; l:=m;
          while l<>k do begin
            b[l]:=p; l:=l+j
          end {while}
        end {if}
      end; {if}
      n:=n+1
    end {while}
  end {if}
end {makeplay};
 
proc checkop; {check opponent's replies}
var z: integer;
    stop: boolean;
    a: array[100] of integer;
begin
  h:=-9999;
  for z:=12 to 89 do a[z]:=b[z];
  p:=-p; v:=m; m:=12; stop:=false;
  while (m<90) and (stop=false) do begin
    makeplay;
    if t<>0 then begin
      evaluate;
      if g>=f then begin {forget this play}
        h:=g; stop:=true
      end else begin
        if g>=h then h:=g;
        for z:=12 to 89 do b[z]:=a[z]
      end {else}
    end {if};
    m:=m+1;
  end {while};
  m:=v;
  p:=-p
end {checkop};
 
proc checkco; {check computer's play}
var c: array[100] of integer;
begin
  write('Computing');
  f:=9999;
  for z:=12 to 89 do c[z]:=b[z];
  m:=12;
  while m<90 do begin
    if u>=4 then begin u:=0; write('.') end;
    u:=u+1;
    makeplay;
    if t<>0 then begin
      checkop;
      if (h<f) or ((h=f) and (random<127))
      then begin {better found}
        f:=h; w:=v
      end;
      for z:=12 to 89 do b[z]:=c[z];
    end; {if}
    m:=m+1;
  end {while};
  m:=w;
  writeln
end {checkco};
 
proc checkplay; {check for legal play}
var stop: boolean;
begin
  t:=0 stop:=false;
  write('Checking');
  m:=1;
  while (m<90) and (stop=false) do begin
    if u>=4 then begin u:=0; write('.') end;
    u:=u+1;
    if b[m]=0 then begin
      n:=1;
      while (n<9) and (stop=false) do begin
        j:=d[n];
        if b[m+j]=-p then begin
          k:=m+j+j;
          while b[k]=-p do k:=k+j;
          if b[k]=p then begin
            stop:=true; t:=1
          end else n:=n+1
        end else n:=n+1
      end {while}
    end; {if}
  m:=m+1
  end {while};
  writeln
end {checkplay};
 
proc getplay;
var x,y: integer;
begin
  writeln;
  if ((p=1) and (us='S')) or ((p=-1) and
    (us<>'S')) then m:=0
  else begin
      case p of
         -1: write('Black');
          1: write('White')
      end; {case}
      write(' is playing: x,y?');
      read(x,y);
      m:=x+1+10*y;
  end
end {getplay};
 
begin {main}
  d[1]:=1; d[2]:=11; d[3]:=10 d[4]:=9;
  d[5]:=-1; d[6]:=-11; d[7]:=-10; d[8]:=-9;
  repeat {main loop for game}
    init;
    write(hom,csc); display;
    repeat
      if (q>=5) then checkplay;
      if (q>=5) and (t<>1) then begin
        if t<>1 then begin
          t3:=t3+1;
          if t3>=2 then begin
            writeln('The game is finished');
            n:=0; j:=0;
            for z:=12 to 89 do begin
              case b[z] of
                -1: n:=n+1;
                 1: j:=j+1
              end {case}
            end {for z};
            write('Black has ',n);
            writeln(' , White has ',j,
              ' points');
            endplay:=true
          end else begin {t3<2}
            write(hom,csc);
            if (p=1) then write('White')
            else write('Black');
            writeln(' cannot play');
            display;
          end {t3<2}
        end {(q>=5) and (t<>1)}
      end {t<>1}
      else begin {t=1}
        repeat
          t3:=0;
          getplay;
          if m=0 then begin
            if q<=4 then begin
              m:=45;
              while b[m]<>2 do m:=m+1
            end else checkco
          end;
          m1:=m;
          if ((m<1) or (m>100)) or ((q<=4)
            and (b[m]<>2)) then t:=0
          else begin
            if q<=4 then begin
              b[m]:=p; q:=q+1; t:=1
            end else
              makeplay
          end;
          if t=0 then begin
            write(hom,csc);
            writeln('Illegal play!');
            display
          end
        until t<>0;
        write(hom,csc);
        display
      end;
      p:=-p;
      if e[m]=64 then adjust
      until endplay=true;
    write('Another game(Y/N)?');
    read(nextplay);
  until nextplay<>'Y'
end.
 