program debug;
uses syslib,arglib,strlib,ralib,mathlib;

const npcodes=$59;

var codename: array[npcodes] of cpnt;
    codebytes: array[npcodes] of integer;
    fcode,scode: file;
    cdsize,i,code,line: integer;
    name: array[15] of char;
    cyclus,drive:integer;
    default: boolean;
    linestr:cpnt;

func readline(f: file; pnt: cpnt): boolean;
{#########################################}
const alteof=chr(127);
var ch1: char;
    pos: integer;
begin
  pos := 0; read(@f,ch1);
  while (ch1>=' ') and (ch1<>alteof) and
      (pos<strsize-1) do begin
    pnt[pos]:=ch1; pos:=pos+1; read(@f,ch1);
    end;
  pnt[pos]:=endmark;
  readline:=(ch1=eof) or (ch1=alteof);
end;

proc setsubtype(var nm:array[15] of char;subtype:char);
{#####################################################}
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (nm[i]=':') or
    (nm[i]=' ') or (i>=14);
  nm[i]:=':';
  nm[i+1]:=subtype;
end;

proc writehex(a:integer);
{#######################}
var h:integer;
  func hexdigit(c:char):char;
  var d:integer;
  begin
    d:=ord(c) and 15;
    if d>9 then hexdigit:=chr(d-10+ord('A'))
    else hexdigit:=chr(d+ord('0'));
  end;
begin
  h:=a and 255;
  write(hexdigit(chr(h shr 4)));
  write(hexdigit(chr(h and 15)));
end;

proc writeui(n:integer);
{######################}
var limit:integer;
begin
  limit:=10000;
  while (limit>n) and (limit>0) do begin
    limit:=limit div 10; write(' ');
  end;
  write(n);
end;

proc showprog;
{############}
var pc,a,b,c,codesize:integer;
    r:real;
    done:boolean;

  proc packreal(i1,i2:%integer;
    var r:array[1] of %integer);
  begin
    r[0]:=i1; r[1]:=i2;
  end;

begin
  line:=1;
  getbyte(fcode,0,a);
  getbyte(fcode,1,b);
  codesize:=a+(b shl 8);
  writeln('Program size: ', codesize,' bytes, ',
    b+1,' sectors');
  writeln;
  pc:=2;
  repeat
    getbyte(fcode,pc,code);
    if code<0 then begin
      writeln('Negative code');
      exit;
    end;
    write('  '); writeui(pc);
    write(' '), writehex(code);
    write(' ',codebytes[code],' ');
    if (code<=npcodes) and (code>=0) then
      write(codename[code])
    else begin
      writeln('pcode not known');
      exit;
    end;
    c:=0;
    case codebytes[code] of
      2: begin
             getbyte(fcode,pc+1,a);
             write(' ',a);
           end;
      3: begin
             getbyte(fcode,pc+1,a);
             getbyte(fcode,pc+2,b);
             c:=a+(b shl 8);
             { exception for JUMP }
             if code=$24 then write(' ',c+pc+1)
             else write(' ',c);
           end;
      4: begin
             getbyte(fcode,pc+1,a);
             write(' ',a,',');
             getbyte(fcode,pc+2,a);
             getbyte(fcode,pc+3,b);
             write(' ',a+(b shl 8));
           end;
      5: begin
             getbyte(fcode,pc+1,a);
             getbyte(fcode,pc+2,b);
             write(' ',a+(b shl 8),' ');
             getbyte(fcode,pc+3,a);
             getbyte(fcode,pc+4,b);
             write(' ',a+(b shl 8));
         end;
      6: begin
             getbyte(fcode,pc+1,a);
             write(' ',a,',');
             getbyte(fcode,pc+2,a);
             getbyte(fcode,pc+3,b);
             c:=a+(b shl 8); ;
             getbyte(fcode,pc+4,a);
             getbyte(fcode,pc+5,b);
             if code=$3a then begin
               packreal(c, a+(b shl 8),r);
               write(' '); writeflo(output,r);
             end else begin
               write(' ',c,' ');
               write(' ',a+(b shl 8));
             end;
         end
      end; {case}
    writeln;
    if (code=$59) then begin
      { LINE }
      done:=false;
      while (line<=c) and not done do begin
        done:=readline(scode,linestr);
        writeln(line, ' ',linestr);
        line:=line+1;
      end;
    end;
    {if (pc=2) and (code=$24) then begin
      if c>8 then writeln('Skipping libraries');
      pc:=pc+c;
    end;}
    if codebytes[code]<>0 then
      pc:=pc+codebytes[code]
    else writeln('codebytes not known');
    until (pc>=codesize) or (codebytes[code]=0) or
      (line>10);
end;

proc init;
{########}
var i:integer;
  proc set(p:integer;n:cpnt;b:integer);
  begin
    codename[p]:=n; codebytes[p]:=b;
  end;
begin
  for i:=0 to npcodes+1 do begin
    codename[i]:=nil; codebytes[i]:=0;
  end;
  set($00,'STOP',1);
  set($01,'RETN',1);
  set($02,'NEGA',1);
  set($03,'ADDA',1);
  set($04,'SUBA',1);
  set($05,'MULA',1);
  set($06,'DIVA',1);
  set($07,'LOWB',1);
  set($08,'TEQU',1);
  set($09,'TNEQ',1);
  set($0a,'TLES',1);
  set($0b,'TGRE',1);
  set($0c,'TGRT',1);
  set($0d,'TLEE',1);
  set($0e,'ORAC',1);
  set($0f,'ANDA',1);
  set($10,'EORA',1);
  set($11,'NOTA',1);
  set($12,'LEFT',3);
  set($13,'RIGH',3);
  set($14,'INCA',1);
  set($15,'DECA',1);
  set($16,'COPY',1);
  set($17,'PEEK',1);
  set($18,'POKE',1);
  set($19,'CALA',1);
  set($1a,'RLIN',0);
  set($1b,'GETC',1);
  set($1c,'GETN',1);
  set($1d,'PRTC',1);
  set($1e,'PRTN',1);
  set($1f,'PRTS',0);
  set($20,'LITB',2);
  set($21,'INCB',2);
  set($22,'LITW',3);
  set($23,'INCW',3);
  set($24,'JUMP',3);
  set($25,'JMPZ',1);
  set($26,'JMPO',1);
  set($27,'LOAD',4);
  set($28,'LODX',4);
  set($29,'STOR',4);
  set($2a,'STOX',4);
  set($2b,'CALL',4);
  set($2c,'SDEV',1);
  set($2d,'RDEV',1);
  set($2e,'FNAM',1);
  set($2f,'OPNR',1);
  set($30,'OPNW',1);
  set($31,'CLOS',1);
  set($32,'PRTI',2);
  set($33,'GHGH',1);
  set($34,'GLOW',1);
  set($35,'PHGH',1);
  set($36,'PLOW',1);
  set($37,'GSEQ',1);
  set($38,'PSEQ',1);
  set($39,'NBYT',0);
  set($3a,'NWRD',6);
  set($3b,'LODN',2);
  set($3c,'STON',2);
  set($3d,'LODI',1);
  set($3e,'STOI',1);
  set($3f,'EXST',1);
  set($40,'TIND',5);
  set($41,'RUNP',1);
  set($42,'ADDF',1);
  set($43,'SUBF',1);
  set($44,'MULF',1);
  set($45,'DIVF',1);
  set($46,'FLOF',1);
  set($47,'FIXF',1);
  set($48,'FEQU',1);
  set($49,'FNEQ',1);
  set($4a,'FLES',1);
  set($4b,'FGRE',1);
  set($4c,'FGRT',1);
  set($4d,'FLEE',1);
  set($4e,'FCOM',1);
  set($4f,'TFER',1);
  set($50,'OPRA',1);
  set($51,'GTRA',1);
  set($52,'PTRA',1);
  set($53,'SWA2',1);
  set($54,'LDXI',1);
  set($55,'STXI',3);
  set($56,'CPNT',0);
  set($57,'WRCP',1);
  set($58,'ADPS',1);
  set($59,'LINE',3);
end;

begin {main}
  init;
  linestr:=strnew;
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  setsubtype(name,'R');
  writeln('Opening object file ');
  fcode:=attach(name,0,1,fread,0,0,'R');
  cdsize:=getsize;
  writeln;
  writeln('Object file opened, file size ',
    cdsize div 256,' sectors');
  setsubtype(name,'P');
  asetfile(name,cyclus,drive,'P');
  writeln('Opening source file ');
  openr(scode);
  writeln; writeln('Source file opened');
  showprog;
  close(fcode);
  close(scode);
end.