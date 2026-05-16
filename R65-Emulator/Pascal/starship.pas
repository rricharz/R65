{ starship - A game for the R65 computer using
  the tek4010 Tektronix 4010 emulator

  www.github.com/rricharz/Tek4010

  This is a revival of my original starship
  game with added high resolution graphics

  rewritten rricharz 2019                  }

program starship;
uses syslib,mathlib,teklib;

const
    maxships=8;

var sinetable: array[90] of integer;
    dshiptable: array[maxships] of integer;
    ashiptable: array[maxships] of integer;
    shipdamage: array[maxships] of integer;
    energy,damage: array[4] of integer;
    radarsize,charging,score: integer;
    shield,quit: boolean;
    phaserrange,step: integer;

proc writethrough;
begin
  write(@PLOTTER,chr(27),'p');
end;

proc endwritethrough;
begin
  write(@PLOTTER,chr(27),chr(96));
end;

proc delay10msec(time:integer);
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

func atan2(x,y:integer):real;
{ this is a special fast atan function
for thestarship coordinate system }
  func atan(z:real):
real;
  const n1= 0.972394;
        n2=-0.191948;
        n3= 57.29578;
  begin
    atan:=(n1+n2*z*z)*z*n3;
  end;

func atanp(x,y:integer):real;
  begin
    if (y<>0) and (x<>0) then begin
      if x<y then
        atanp:=atan(conv(x)/conv(y))
      else
        atanp:=90.0-atan(conv(y)/conv(x))
    end else begin
      if y>0 then atanp:=0.0
      else if x>0 then atanp:=90.0
      else atanp:=0.0;
    end;
end;

begin
  if (x>=0) and (y>=0) then
    atan2:=atanp(x,y)
  else if (x>=0) and (y<0) then
    atan2:=180.0-atanp(x,-y)
  else if (x<0) and (y<0) then
    atan2:=atanp(-x,-y)+180.0
  else
    atan2:=360.0-atanp(-x,y)
end;

proc checkradar(angle,cx,cy,mode:integer);
var i,xi,yi,dist,rsize0,a:integer;
    x,y:real;
begin
  rsize0:=radarsize;
  if mode=0 then rsize0:=rsize0 div 10;
  for i:=0 to maxships-1 do
    if (ashiptable[i]>=angle) and
      (ashiptable[i]<angle+step) then begin
      if dshiptable[i]<=rsize0 then begin
        dist:=dshiptable[i];
        a:=ashiptable[i];
        if angle<90 then begin
          x:=conv(sinetable[a])*
            conv(dist)/32000.0;
          y:=conv(sinetable[89-a])*
            conv(dist)/32000.0
        end else if angle<180 then begin
          x:=conv(sinetable[179-a])*
            conv(dist)/32000.0;
          y:=-conv(sinetable[a-90])*
            conv(dist)/32000.0
        end else if angle<270 then begin
          x:=-conv(sinetable[a-180])*
            conv(dist)/32000.0;
          y:=-conv(sinetable[269-a])*
            conv(dist)/32000.0
        end else begin
          x:=-conv(sinetable[359-a])*
            conv(dist)/32000.0;
          y:=conv(sinetable[a-270])*
            conv(dist)/32000.0
        end;
        if mode=0 then begin
          x:=x*10.0;
          y:=y*10.0;
        end;
        xi:=cx+trunc(x);
        yi:=cy+trunc(y);
        _startdraw(xi-3,yi-3);
        _draw(xi+3,yi-3);
        _draw(xi,yi+2);
        _draw(xi-3,yi-3);
        _enddraw;
        _moveto(xi+6,yi-7);
        write(@PLOTTER,i+1);
        if shipdamage[i]<100 then
          write(@PLOTTER,'d');
        if mode=1 then begin
          _moveto(20,MAXY-16*i-78);
          write(@PLOTTER,i+1,': ');
          write(@PLOTTER,conv(angle):4:0);
          write(@PLOTTER,conv(dist)*0.1:6:1);
          write(@PLOTTER,' pc');
          if shipdamage[i]<100 then
            write(@PLOTTER,' d');
        end;
      end;
    end;
end;

proc scan(mode:integer);
var i,angle: integer;
    cx,cy: integer;
    x,y,csize,ticfactor,ticf1,ticf2: real;

  proc drawsegment;
  begin
    writethrough;
    _drawvector(cx,cy,cx+trunc(x),cy+trunc(y));
    endwritethrough;
    _drawvector(cx+trunc(x),
      cy+trunc(y),
      cx+trunc(ticfactor*x),
      cy+trunc(ticfactor*y));
    if mode=0 then begin
      _drawvector(cx+trunc(ticf1*x),
      cy+trunc(ticf1*y),
      cx+trunc(ticf2*x),
      cy+trunc(ticf2*y));
    end;
    angle:=angle+step;
  end;

begin
  _setchsize(1);
  if mode=0 then begin
    step:=6;
    cx:=MAXX-130;
    cy:=150;
    _moveto((MAXX div 2)-72,MAXY-25);
    radarsize:=100;
    ticfactor:=1.0+3.0/conv(radarsize);
    ticf1:=conv(phaserrange)/10.0;
    ticf2:=0.01+conv(phaserrange)/10.0;
    csize:=conv(radarsize)/32000.0;
    _moveto(cx-130,cy-radarsize-28);
    write(@PLOTTER,'Phaser range');
    write(@PLOTTER,conv(phaserrange)/10.0:4:1);
    write(@PLOTTER,' pc');
  end else begin
    step:=3;
    cx:=MAXX div 2;
    cy:=MAXY div 2;
    _moveto((MAXX div 2)-72,MAXY-25);
    write(@PLOTTER,'R65 Starship');
    radarsize:=(310*damage[0]) div 100;
    ticfactor:=1.0+3.0/conv(radarsize);
    csize:=conv(radarsize)/32000.0;
    _moveto(cx-150,cy-radarsize-28);
    write(@PLOTTER,'Long range scan');
    write(@PLOTTER,conv(radarsize)*0.1:5:1);
    write(@PLOTTER,' pc');
  end;
  angle:=0;
  _setlinemode(2);
  _setchsize(2);
  _drawvector(cx-radarsize,cy,cx+radarsize,cy);
  _drawvector(cx,cy-radarsize,cx,cy+radarsize);
  _setlinemode(1);
  if (mode=1) then begin
    _drawrectangle(10,MAXY-200,240,MAXY-10);
    _moveto(20,MAXY-30);
    write(@PLOTTER,'SCANNER');
    _moveto(20,MAXY-46);
    write(@PLOTTER,'Objects located:');
    _moveto(20,MAXY-60);
    write(@PLOTTER,'   angle distance');
  end;
  angle:=0;
  i:=0
  repeat
    checkradar(angle,cx,cy,mode);
    x:=csize*conv(sinetable[i]);
    y:=csize*conv(sinetable[89-i]);
    drawsegment;
    i:=i+step;
  until i>=90;
  i:=0;
  repeat
    checkradar(angle,cx,cy,mode);
    x:=csize*conv(sinetable[89-i]);
    y:=-csize*conv(sinetable[i]);
    drawsegment;
    i:=i+step;
  until i>=90;
  i:=0;
  repeat
    checkradar(angle,cx,cy,mode);
    x:=-csize*conv(sinetable[i]);
    y:=-csize*conv(sinetable[89-i]);
    drawsegment;
    i:=i+step;
  until i>=90;
  i:=0;
  repeat
    checkradar(angle,cx,cy,mode);
    x:=-csize*conv(sinetable[89-i]);
    y:=csize*conv(sinetable[i]);
    drawsegment;
   i:=i+step;
  until i>=90;
end;

proc showEnergy;
var i: integer;
begin
  _setlinemode(1);
  _setchsize(2);
  _drawrectangle(10,10,240,116);
  _moveto(20,90);
  write(@PLOTTER,'ENERGY');
  for i:= 0 to 3 do begin
    _moveto(20,74-16*i);
    case i of
      0: write(@PLOTTER,'Scanner:    ');
      1: write(@PLOTTER,'Shield:     ');
      2: write(@PLOTTER,'Phaser:     ');
      3: write(@PLOTTER,'Warp Engine:')
    end;
    write(@PLOTTER,conv(energy[i]):4:0);
    write(@PLOTTER,'%');
    if charging=i then
      write(@PLOTTER,'^');
  end;
end;

proc showStatus;
var i: integer;
begin
  _setchsize(2);
  _setlinemode(1);
  _drawrectangle(MAXX-240,MAXY-116,
    MAXX-10,MAXY-10);
  _moveto(MAXX-230,MAXY-36);
  write(@PLOTTER,'STATUS/DAMAGE');
  for i:= 0 to 3 do begin
    _moveto(MAXX-230,MAXY-52-16*i);
    case i of
      0: write(@PLOTTER,'Scanner:    ');
      1: if shield then
           write(@PLOTTER,'Shield: Up  ')
         else
           write(@PLOTTER,'Shield: Down');
      2: write(@PLOTTER,'Phaser:     ');
      3: write(@PLOTTER,'Warp Engine:')
    end;
    write(@PLOTTER,conv(damage[i]):5:0);
    write(@PLOTTER,'%');
  end;
end;

proc setcharging;
var select: integer;
    k:      char;
begin
  writeln('Select station to charge:');
  writeln('1: Scanner');
  writeln('2: Shield');
  writeln('3: Phaser');
  writeln('4: Warp Engine');
  write('Which station (1..4)? ');
  read(@KEY,k);
  writeln(INVVID,k,NORVID);
  select := ord(k) - ord('0');
  if (select>=1) and (select<=4) then
    charging:=select-1
  else
    writeln(INVVID,'Unknown station',
      NORVID);
  write(INVVID,'Charging ');
  case charging of
    0: writeln('Scanner');
    1: writeln('Shield');
    2: writeln('Phaser');
    3: writeln('Warp Engine')
  end;
  write(NORVID);
end;

proc doscan;
begin
  if damage[0]<5 then
    writeln(INVVID,
      'Scanner defective',NORVID)
  else if energy[0]<8 then
    writeln(INVVID,
      'Not enough energy for scan',NORVID)
  else begin
    energy[0]:=energy[0]-8;
    if energy[0]<0 then energy[0]:=0;
    scan(1);
    scan(0);
  end;
end;

proc repair;
var select: integer;
    k: char;
begin
  writeln('Select station to repair:');
  writeln('1: Scanner');
  writeln('2: Shield');
  writeln('3: Phaser');
  writeln('4: Warp Engine');
  write('Which station (1..4)? ');
  read(@KEY,k);
  writeln(k,INVVID);
  select := ord(k) - ord('0');
  if (select>=1) and (select<=4) then begin
    damage[select-1]:=damage[select-1]+20;
    if damage[select-1]>100 then
      damage[select-1]:=100;
    write('Repairing ');
    case select-1 of
      0: write('Scanner');
      1: write('Shield');
      2: write('Phaser');
      3: write('Warp Engine')
    end
  end else
    write(INVVID,'Unknown station',NORVID);
  writeln;
end;

proc warp;
var i,angle,required:integer;
    distance,x,y,warpx,warpy:real;
    done:boolean;
begin
  if damage[3]<10 then
    writeln(INVVID,
      'Warp engine damaged',NORVID)
  else begin
    done:=false;
    write('Warp direction? ');
    read(angle);
    if angle<0 then angle:=360-angle;
    if angle>360 then angle:=360;
    repeat
      write('Warp distance in pc? ');
      distance:=readflo(INPUT);
      required:=trunc(2.0*distance);
      writeln('Energy required: ',required);
      if energy[3]<required then
        writeln(INVVID,'Not enough energy (',
          required,'% required)',NORVID)
      else begin
        done:=true;
        energy[3]:=energy[3]-required;
        write(INVVID,'Warping...');
        warpx:=sin(conv(angle))*distance*10.0;
        warpy:=cos(conv(angle))*distance*10.0;
        for i:=0 to 7 do begin
          x:=sin(conv(ashiptable[i]))*
            conv(dshiptable[i])-warpx;
          y:=cos(conv(ashiptable[i]))*
            conv(dshiptable[i])-warpy;
          ashiptable[i]:=
            trunc(atan2(trunc(x),trunc(y)));
          dshiptable[i]:=trunc(sqrt(x*x+y*y));
        end;
        writeln('done',NORVID);
      end
    until done;
  end;
end;

proc shoot;
var i,angle:integer;
begin
  if shield then begin
    writeln(INVVID,'Lowering shield',NORVID);
    shield:=false;
  end;
  if damage[2]<10 then
    writeln(INVVID,
      'Phaser damaged',NORVID)
  else if energy[2]<20 then
    writeln(INVVID,
      'Not enough energy for phaser',NORVID)
  else begin
    energy[2]:=energy[2]-20;
    write('Phaser direction? ');
    read(angle);
    if angle<0 then angle:=360-angle;
    if angle>360 then angle:=360;
    for i:=0 to 7 do begin
      if (_abs(angle-ashiptable[i])<4) and
        (dshiptable[i]<phaserrange) then begin
        shipdamage[i]:=shipdamage[i]-50;
        if shipdamage[i]>0 then begin
          writeln(INVVID,'Ship ',i+1,
          ' damaged',NORVID);
        score:=score+1;
        end else begin
          writeln(INVVID,'Ship ',i+1,
            ' destroyed',NORVID);
          score:=score+10;
          { Create new ship far away }
          dshiptable[i]:=20000;
          ashiptable[i]:=
            trunc(conv(_random)*360.0/256.0);
          shipdamage[i]:=100;
        end;
      end;
    end;
  end;
end;

proc hit(impact0:integer);
var impact,station: integer;
begin
  impact:=impact0;
  if impact<5 then impact:=5;
  write(INVVID,'Starship hit, ');
  if shield then begin
    if energy[1]>=impact then begin
      energy[1]:=energy[1]-impact;
      writeln('shield at ',energy[1],'%');
      impact:=0
    end else begin
      impact:=impact-energy[1];
      energy[1]:=0;
      writeln('shield at ',energy[1],'%');
    end
  end;
  if impact>0 then begin
    station:=_random div 64;
    write(INVVID);
    case station of
      0: write('Scanner');
      1: write('Shield generator');
      2: write('Phaser');
      3: write('Warp engine')
    end;
    damage[station]:=damage[station]-impact;
    if damage[station]<0 then
      damage[station]:=0;
    if energy[station]>damage[station] then
      energy[station]:=damage[station];
    writeln(' damaged (',
      damage[station],'%)');
  end;
  write(NORVID);
end;

proc enemy;
var i,dangle,distance:integer;
begin
  for i:=0 to 7 do begin
    if dshiptable[i]>10 then begin
      { warp }
      if _random<128 then begin
        distance:=_random div 2;
        dshiptable[i]:=dshiptable[i]-
          (_random div 2);
        if dshiptable[i]<3 then
          dshiptable[i]:=3;
        dangle:=(_random-128) div dshiptable[i];
        ashiptable[i]:=ashiptable[i]+
          dangle;
        if ashiptable[i]<0 then
          ashiptable[i]:=ashiptable[i]+360
        else if ashiptable[i]>=360 then
          ashiptable[i]:=ashiptable[i]-360;
      end
    end;
    if dshiptable[i]<10 then begin
      if _random<128 then
        hit(_random div 6);
    end;
  end;
end;

proc action;
var i,s:integer;
    sshield:boolean;
    select:char;
begin
  sshield:=shield;
  writeln(INVVID,'Current score: ',
    score,NORVID);
  if not shield then
    writeln(INVVID,'Shield is down',NORVID);
  writeln('Select action:');
  writeln('R: Repair stations');
  if shield then
    writeln('S: Lower shield')
  else
    writeln('S: Rase shield');
  write('P: Phaser (range ');
  write(conv(phaserrange)/10.0:4:1);
  writeln(' pc)');
  writeln('W: Warp');
  writeln('C: Choose station for fast charge');
  writeln('Q: Quit game');
  write('Which action (R,S,P,W,C,Q)? ');
  read(@KEY,select);
  writeln(INVVID,select,NORVID);
  case select of
    'R': repair;
    'S': shield:= not shield;
    'P': shoot;
    'W': warp;
    'C': setcharging;
    'Q': quit:=true
    else writeln(INVVID,'Unknown action',
      NORVID)
  end;
  energy[charging]:=energy[charging]+10;
  if energy[charging]>damage[charging] then
    energy[charging]:=damage[charging];
  for i:=0 to 3 do begin
    energy[i]:=energy[i]+5;
    if energy[i]>damage[i] then
      energy[i]:=damage[i];
  end;
  if shield then begin
    if energy[1]<10 then begin
       writeln(INVVID,'Not enough energy, ',
         'shield down',NORVID);
      shield:=false;
    end else begin
      energy[1]:=energy[1]-10;
      if energy[1]>damage[1] then
        energy[1]:=damage[1];
    end;
  end;
  if not quit then begin
    _clearscreen;
    enemy;
    if (select='P') and (shield<>sshield)
    then begin
      writeln(INVVID,'Raising shield',NORVID);
      shield:=sshield;
    end;
    phaserrange:=10*damage[2] div 100;
    showEnergy;
    showStatus;
    doscan;
    _moveto(5,MAXX-20);
    s:=0;
    for i:=1 to 3 do
      s:=s+damage[i];
    if s<30 then begin
      writeln('Starship heavily damaged,',
        ' game over!');
      quit:=true;
    end;
    s:=20000;
    for i:=0 to 7 do begin
      if dshiptable[i]<s then
        s:=dshiptable[i];
    end;
    if s>1000 then begin
      writeln('No nearby ships anymore,',
        ' game over!');
      quit:=true;
    end;
  end;
end;

proc initialize;
var i,j,distance,s: integer;
    v:real;
begin
  writeln('STARSHIP by rricharz');
  write('Initializing...');
  _starttek(T_GAMING);
  quit:=false;
  score:=0;
  shield:=true;
  radarsize:=310;
  phaserrange:=10;
  for i:=0 to 89 do begin
    v:=32000.0*sin(conv(i));
    sinetable[i]:=trunc(v);
  end;
  for i:=0 to 3 do begin
    energy[i]:=80;
    damage[i]:=100;
  end;
  charging:=1;
  for i:=0 to maxships-1 do begin
    ashiptable[i]:=
      trunc(conv(_random)*360.0/256.0);
    dshiptable[i]:=_random div 2 +
       radarsize-128;
    shipdamage[i]:=100;
  end;
  for i:=0 to maxships-2 do
    for j:=0 to maxships-2-i do
      if ashiptable[j]>ashiptable[j+1]
      then begin
        s:=ashiptable[j];
        ashiptable[j]:=ashiptable[j+1];
        ashiptable[j+1]:=s;
        s:=dshiptable[j];
        dshiptable[j]:=dshiptable[j+1];
        dshiptable[j+1]:=s;
      end;
  writeln(' done.');
end;

begin {main}
  initialize;
  showEnergy;
  showStatus;
  scan(1);
  scan(0);
  _moveto(5,MAXX-20);
  repeat
    action;
  until quit;
  writeln(INVVID,'Final score: ',score,NORVID);
  _endtek;
end. 