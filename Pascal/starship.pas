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

proc startwritethrough;
begin
  write(@plotter,chr(27),'p');
end;

proc endwritethrough;
begin
  write(@plotter,chr(27),'`');
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
        startdraw(xi-3,yi-3);
        draw(xi+3,yi-3);
        draw(xi,yi+2);
        draw(xi-3,yi-3);
        enddraw;
        moveto(xi+6,yi-7);
        write(@plotter,i+1);
        if shipdamage[i]<100 then
          write(@plotter,'d');
        if mode=1 then begin
          moveto(20,maxy-16*i-78);
          write(@plotter,i+1,': ');
          writef0(plotter,0,conv(angle),
            4,false);
          writef0(plotter,1,conv(dist)*0.1,
            6,false);
          write(@plotter,' pc');
          if shipdamage[i]<100 then
            write(@plotter,' d');
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
    startwritethrough;
    drawvector(cx,cy,cx+trunc(x),cy+trunc(y));
    endwritethrough;
    drawvector(cx+trunc(x),
      cy+trunc(y),
      cx+trunc(ticfactor*x),
      cy+trunc(ticfactor*y));
    if mode=0 then begin
      drawvector(cx+trunc(ticf1*x),
      cy+trunc(ticf1*y),
      cx+trunc(ticf2*x),
      cy+trunc(ticf2*y));
    end;
    angle:=angle+step;
  end;

begin
  setchsize(1);
  if mode=0 then begin
    step:=6;
    cx:=maxx-130;
    cy:=150;
    moveto((maxx div 2)-72,maxy-25);
    radarsize:=100;
    ticfactor:=1.0+3.0/conv(radarsize);
    ticf1:=conv(phaserrange)/10.0;
    ticf2:=0.01+conv(phaserrange)/10.0;
    csize:=conv(radarsize)/32000.0;
    moveto(cx-130,cy-radarsize-28);
    write(@plotter,'Phaser range');
    writef0(plotter,1,
      conv(phaserrange)/10.0,
      4,false);
    write(@plotter,' pc');
  end else begin
    step:=3;
    cx:=maxx div 2;
    cy:=maxy div 2;
    moveto((maxx div 2)-72,maxy-25);
    write(@plotter,'R65 Starship');
    radarsize:=(310*damage[0]) div 100;
    ticfactor:=1.0+3.0/conv(radarsize);
    csize:=conv(radarsize)/32000.0;
    moveto(cx-150,cy-radarsize-28);
    write(@plotter,'Long range scan');
    writef0(plotter,1,conv(radarsize)*0.1,
      4,false);
    write(@plotter,' pc');
  end;
  angle:=0;
  setlinemode(2);
  setchsize(2);
  drawvector(cx-radarsize,cy,cx+radarsize,cy);
  drawvector(cx,cy-radarsize,cx,cy+radarsize);
  setlinemode(1);
  if (mode=1) then begin
    drawrectange(10,maxy-200,240,maxy-10);
    moveto(20,maxy-30);
    write(@plotter,'SCANNER');
    moveto(20,maxy-46);
    write(@plotter,'Objects located:');
    moveto(20,maxy-60);
    write(@plotter,'   angle distance');
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
  setlinemode(1);
  setchsize(2);
  drawrectange(10,10,240,116);
  moveto(20,90);
  write(@plotter,'ENERGY');
  for i:= 0 to 3 do begin
    moveto(20,74-16*i);
    case i of
      0: write(@plotter,'Scanner:    ');
      1: write(@plotter,'Shield:     ');
      2: write(@plotter,'Phaser:     ');
      3: write(@plotter,'Warp Engine:')
    end;
    writef0(plotter,0,conv(energy[i]),4,false);
    write(@plotter,'%');
    if charging=i then
      write(@plotter,'^');
  end;
end;

proc showStatus;
var i: integer;
begin
  setchsize(2);
  setlinemode(1);
  drawrectange(maxx-240,maxy-116,
    maxx-10,maxy-10);
  moveto(maxx-230,maxy-36);
  write(@plotter,'STATUS/DAMAGE');
  for i:= 0 to 3 do begin
    moveto(maxx-230,maxy-52-16*i);
    case i of
      0: write(@plotter,'Scanner:    ');
      1: if shield then
           write(@plotter,'Shield: Up  ')
         else
           write(@plotter,'Shield: Down');
      2: write(@plotter,'Phaser:     ');
      3: write(@plotter,'Warp Engine:')
    end;
    writef0(plotter,0,conv(damage[i]),4,false);
    write(@plotter,'%');
  end;
end;

proc setcharging;
var select: integer;
begin
  writeln('Select station to charge:');
  writeln('1: Scanner');
  writeln('2: Shield');
  writeln('3: Phaser');
  writeln('4: Warp Engine');
  write('Which station (1..4)? ');
  read(select);
  if (select>=1) and (select<=4) then
    charging:=select-1
  else
    writeln(invvid,'Illegal selection',
      norvid);
  write('Charging ');
  case charging of
    0: writeln('Scanner');
    1: writeln('Shield');
    2: writeln('Phaser');
    3: writeln('Warp Engine')
  end;
end;

proc doscan;
begin
  if damage[0]<5 then
    writeln(invvid,
      'Scanner defective',norvid)
  else if energy[0]<8 then
    writeln(invvid,
      'Not enough energy for scan',norvid)
  else begin
    energy[0]:=energy[0]-8;
    if energy[0]<0 then energy[0]:=0;
    scan(1);
    scan(0);
  end;
end;

proc repair;
var select: integer;
begin
  writeln('Select station to repair:');
  writeln('1: Scanner');
  writeln('2: Shield');
  writeln('3: Phaser');
  writeln('4: Warp Engine');
  write('Which station (1..4)? ');
  read(select);
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
    write(invvid,'Illegal selection',norvid);
  writeln;
end;

proc warp;
var i,angle,required:integer;
    distance,x,y,warpx,warpy:real;
    done:boolean;
begin
  if damage[3]<10 then
    writeln(invvid,
      'Warp engine damaged',norvid)
  else begin
    done:=false;
    write('Warp direction? ');
    read(angle);
    if angle<0 then angle:=360-angle;
    if angle>360 then angle:=360;
    repeat
      write('Warp distance in pc? ');
      distance:=readflo(input);
      required:=trunc(2.0*distance);
      writeln('Energy required: ',required);
      if energy[3]<required then
        writeln(invvid,'Not enough energy (',
          required,'% required)',norvid)
      else begin
        done:=true;
        energy[3]:=energy[3]-required;
        write('Warping...');
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
        writeln('done');
      end
    until done;
  end;
end;

proc shoot;
var i,angle:integer;
begin
  if shield then begin
    writeln(invvid,'Lowering shield',norvid);
    shield:=false;
  end;
  if damage[2]<10 then
    writeln(invvid,
      'Phaser damaged',norvid)
  else if energy[2]<20 then
    writeln(invvid,
      'Not enough energy for phaser',norvid)
  else begin
    energy[2]:=energy[2]-20;
    write('Phaser direction? ');
    read(angle);
    if angle<0 then angle:=360-angle;
    if angle>360 then angle:=360;
    for i:=0 to 7 do begin
      if (abs(angle-ashiptable[i])<4) and
        (dshiptable[i]<phaserrange) then begin
        shipdamage[i]:=shipdamage[i]-50;
        if shipdamage[i]>0 then begin
          writeln(invvid,'Ship ',i+1,
          ' damaged',norvid);
        score:=score+1;
        end else begin
          writeln(invvid,'Ship ',i+1,
            ' destroyed',norvid);
          score:=score+10;
          { Create new ship far away }
          dshiptable[i]:=20000;
          ashiptable[i]:=
            trunc(conv(random)*360.0/256.0);
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
  write(invvid,'Starship hit, ');
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
    station:=random div 64;
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
  write(norvid);
end;

proc enemy;
var i,dangle,distance:integer;
begin
  for i:=0 to 7 do begin
    if dshiptable[i]>10 then begin
      { warp }
      if random<128 then begin
        distance:=random div 2;
        dshiptable[i]:=dshiptable[i]-
          (random div 2);
        if dshiptable[i]<3 then
          dshiptable[i]:=3;
        dangle:=(random-128) div dshiptable[i];
        ashiptable[i]:=ashiptable[i]+
          dangle;
        if ashiptable[i]<0 then
          ashiptable[i]:=ashiptable[i]+360
        else if ashiptable[i]>=360 then
          ashiptable[i]:=ashiptable[i]-360;
      end
    end;
    if dshiptable[i]<10 then begin
      if random<128 then
        hit(random div 6);
    end;
  end;
end;

proc action;
var i,s:integer;
    sshield:boolean;
    select:char;
begin
  sshield:=shield;
  writeln(invvid,'Current score: ',
    score,norvid);
  if not shield then
    writeln(invvid,'Shield is down',norvid);
  writeln('Select action:');
  writeln('R: Repair stations');
  if shield then
    writeln('S: Lower shield')
  else
    writeln('S: Rase shield');
  write('P: Phaser (range ');
  writef0(output,1,conv(phaserrange)/10.0,
    2,false);
  writeln(' pc)');
  writeln('W: Warp');
  writeln('C: Choose station for fast charge');
  writeln('Q: Quit game');
  write('Which action (R,S,P,W,C,Q)? ');
  read(select);
  case select of
    'R': repair;
    'S': shield:= not shield;
    'P': shoot;
    'W': warp;
    'C': setcharging;
    'Q': quit:=true
    else writeln(invvid,'No action taken',
      norvid)
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
       writeln(invvid,'Not enough energy, ',
         'shield down',norvid);
      shield:=false;
    end else begin
      energy[1]:=energy[1]-10;
      if energy[1]>damage[1] then
        energy[1]:=damage[1];
    end;
  end;
  if not quit then begin
    clearscreen;
    enemy;
    if (select='P') and (shield<>sshield)
    then begin
      writeln(invvid,'Raising shield',norvid);
      shield:=sshield;
    end;
    phaserrange:=10*damage[2] div 100;
    showEnergy;
    showStatus;
    doscan;
    moveto(5,maxx-20);
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
  writeln('STARSHIP by rricharz, ',
    'revived 2019');
  writeln('requires an attached ',
    'tek4010 terminal');
  write('Initializing...');
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
      trunc(conv(random)*360.0/256.0);
    dshiptable[i]:=random div 2 +
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
  starttek;
  initialize;
  showEnergy;
  showStatus;
  scan(1);
  scan(0);
  moveto(5,maxx-20);
  repeat
    action;
  until quit;
  writeln(invvid,'Final score: ',score,norvid);
  endtek;
end. 