{ include file ISTATEMENT:P of compile1}

{######################}
{ statmnt ( of block ) }
{######################}

proc statmnt;
var idpnt,relad,k2,savpc,bottom1: integer;
    device,wln: boolean;
    savtp1,vartyp2: char;
    wl: boolean;

{########################}
{ code4 ( of statement ) }
{########################}

proc code4(x,y1,z1: integer); {set 4-byte code}
var y,z: integer;
begin
  y:=y1; z:=z1;
  if y<0 then y:=y+256;
  if x=43 then z:=z-pc-2;
  code1(x);code1(y);code1(z and 255);
  code1(z shr 8)
end {code4};

{##############################}
{ testferror ( of statement) ) }
{##############################}

proc testferror;
begin
  code1($4f);
end;

{########################}
{ gpval ( of statement ) }
{########################}

proc gpval(idpnt: integer;
  dir: boolean; typ: char);

var d: integer;

begin {gpval}
  if dir then d:=1 else d:=0;
  case typ of
  'h':  begin code3($22,svda[idpnt]);
          if dir then code1($3f);
          code1($17+d) end;
  'm':  begin code3($22,svda[idpnt]);
          code1($3d+d) end;
  'i':  begin
          if dir then code1($3f);
          code3($22,svda[idpnt]);
          code1(3);
          if dir then code1($3f);
          code1($17+d) end;
  'n':  begin if dir then code1($3f);
          code3($22,1); code1($12);
          code3($22,svda[idpnt]);
          code1(3); code1($3d+d) end
  else begin
    if typ='q' then begin
      { relad=1 bedeutet: s[i] Zugriff auf }
      { cpnt-string-byte }
      if relad=1 then begin
        if sspsz[idpnt]=0 then
          checkindex(0,63)
        else
          checkindex(0,sspsz[idpnt]);
      end;
      code4($55,level-slevel[idpnt],2*svda[idpnt]);
    end else
      code4($27+2*d+relad,level-slevel[idpnt],
        2*svda[idpnt]);
    end
  end {case}
end;

{###############################################}
{ FORWARD declaration of mainexp (of statement) }
{###############################################}

proc mainexp(reqtype: char;
  var arsize: integer); forward;

{##########################}
{ express ( of statement ) }
{##########################}

proc express; {requests a normal 16-bit result }
var resultsize: integer;
begin {express}
  mainexp('n',resultsize);
  if resultsize<>0 then error(15)
end {express};

{########################}
{ arrayexp ( of mainexp) }
{########################}

proc arrayexp(size: integer; eltype: char);
var resultsize: integer;
begin
  mainexp(eltype,resultsize);
  if resultsize<>size then error(15);
  testtype(eltype);
end;

{#########################}
{ getvar ( of statement ) }
{#########################}

proc getvar;
begin
  vartyp2:=high(stype[idpnt]);
  vartype:=low(stype[idpnt]);
  scan;
  if (vartype='q') and (token=' [') and
    ((vartyp2='v') or (vartyp2='d')) then begin
    vartyp2:='q'; vartype:='c';
  end;
  case vartyp2 of
  'a','x','s','i','n','q':
      begin
        if token=' [' then begin
          scan; express; relad:=1;
          if vartyp2='r' then begin
            relad:=3;
            code3($22,1); code1($12)
          end;
          if (vartyp2='q') and (sspsz[idpnt]=0) then
            checkindex(0,63)
          else
            checkindex(0,sspsz[idpnt]);
          testtype('i'); testto(' ]'); scan;
        end else relad:=2;
      end;
  'v','w','r','h','m': relad:=0;
  'c','d','e','t','u': error(6)
  else error(1)
  end {case}
end {getvar};

{#########################}
{ prcall ( of statement ) }
{#########################}

proc prcall (idpn1: integer);

var bstack,numpar,i,n,n2: integer;

{ body of prcall follows later }

{#######################}
{ prcall1 ( of prcall ) }
{#######################}

proc prcall1;
var ressize:integer;

  proc prcall3;
  {###########}
  begin {prcall3}
    testto('id');
    idpnt:=findid;
    if idpnt=0 then error(5);
    getvar;
    if chr(stack[i] and 255)<>vartype then
      if chr(stack[i] and 255)<>'u' then
        merror(14,'01');
      push(idpnt);
  end {prcall3};

begin {prcall1}
  case chr(stack[i] shr 8) of
    'd':  begin
            if chr(stack[i] and 255) = 'q' then
              mainexp('q',ressize)
            else
              express;
            if chr(stack[i] and 255)<>'u' then
              testtype(chr(stack[i] and 255));
          end;
    'e':  begin
            arrayexp(stack[succ(i)],
              chr(stack[i]));
            i:=succ(i);
          end;
    'w':  begin
            prcall3;
            if relad<>0 then merror(14,'02');
            gpval(idpnt,false,vartyp2);
          end;
    'x':  begin
            prcall3;
            if relad<>2 then merror(14,'03');
            if vartyp2='i' then error(16);
            i:=succ(i);
            if stack[i]<>sspsz[idpnt] then
              error(15);
            if vartyp2='n' then begin
              code3($22,svda[idpnt]);
              code1($3d);
            end else code4($27,level-slevel[idpnt],
              2*svda[idpnt]);
            code2($3b,stack[i]);
          end
    else merror(14,'04')
  end {case}
end {prcall1};

{#####################}
{ prcall2 (of prcall) }
{#####################}

proc prcall2;
begin
  if n>0 then code3(35,-2*n);
  n:=0
end {prcall2};

{################}
{ body of prcall }
{################}

begin {body of prcall}
  if sspsz[idpn1]<>0 then begin
    bstack:=sspsz[idpn1];
    numpar:=stack[bstack];
    parse(' ('); scan;
    for i:=succ(bstack) to bstack+numpar do
    begin
      prcall1;
      if i<bstack+numpar then begin
        testto(' ,'); scan
      end
    end;
    testto(' )');
  end {then};
  code4(43,level-slevel[idpn1],svda[idpn1]);
  if sspsz[idpn1]<>0 then begin
    n:=0; i:=bstack+numpar;
    repeat
      case chr(stack[i] shr 8) of
      'd':  n:=succ(n);
      'w':  begin
              prcall2; idpnt:=pop;
              gpval(idpnt,true,
                  high(stype[idpnt]));
            end;
      chr(0): begin
            n2:=stack[i];
            i:=i-1;
            case chr(stack[i] shr 8) of
              'e':  n:=succ(n+n2);
              'x':  begin
                      prcall2;
                      idpnt:=pop;
                      if high(stype[idpnt])='n'
                      then begin
                        code3($22,svda[idpnt]+
                          2*sspsz[idpnt]);
                        code1($3e)
                      end else
                        code4(41,
                          level-slevel[idpnt],
                          2*(svda[idpnt]+
                          sspsz[idpnt]));
                      code2($3c,sspsz[idpnt])
                    end
              end {case}
            end
      end; {case}
      i:=prec(i);
    until i=bstack;
    prcall2
  end
end {prcall};

{########################}
{ mainexp (of statement) }
{########################}
{  see forward declaration above    }

proc mainexp(reqtype: char;
  var arsize: integer);

{ variables of mainexp}
var opcode,roff: integer;
    savtype: char;

{########################}
{ argument ( of mainexp ) }
{#########################}

proc argument(rtype: char);
begin
  parse(' ('); scan; express;
  testtype(rtype);
  testto(' )'); scan
end; {argument}

{#######################}
{ simexp ( of mainexp ) }
{#######################}

proc simexp(var arsize1: integer);
var opcode: integer;
    sign: char;

{body of simexp  follows later }

{#####################}
{ term ( of simexp )  }
{#####################}

proc term(var arsize2: integer);

var opcode: integer;

{ body of term follows later }

{#######################}
{ factor ( of term )    }
{#######################}

proc factor(var arsize3: integer);

var i, idpnt: integer;
    h: char;

{ body of factor follows later }

{######################}
{ index ( of factor )  }
{######################}

proc index(chk: boolean);
var savtype: char;
begin {index}
  scan; savtype:=restype;
  express; testtype('i'); testto(' ]');
  if savtype='r' then begin
    code3($22,1); code1($12);
  end;
  if chk then begin
    if (savtype='q') and (sspsz[idpnt]=0) then
      { is an arrayed cpnt }
      checkindex(0,63)
    else
      checkindex(0,sspsz[idpnt]);
  end;
  restype:=savtype; scan
end;

{################}
{ body of factor }
{################}

begin
  arsize3:=0;
  case token of
    'id': begin {identifier }
            idpnt:=findid;
            if idpnt=0 then error(5);
            restype:=low(stype[idpnt]);
            h:=high(stype[idpnt]);
            case h of
              'v','w','d':
                    begin
                      scan;
                      if (restype='q') and (token=' [')
                      then begin
                        code4(39,level-slevel[idpnt],
                          2*svda[idpnt]);
                        index(true);
                        code1($03);
                        code1($54);
                        restype:='c';
                      end else
                        code4(39,level-slevel[idpnt],
                          2*svda[idpnt]);
                    end;
              'h':  begin code3($22,svda[idpnt]);
                      code1($17); scan end;
              'i':  begin code3($22,svda[idpnt]);
                      scan;
                      if token=' [' then begin
                        index(true); code1($03);
                        code1($17)
                      end else begin
                        error(16)
                      end
                    end;
              'm':  begin code3($22,svda[idpnt]);
                      code1($3d); scan
                    end;
              'n':  begin code3($22,svda[idpnt]);
                      scan;
                      if token=' [' then begin
                        index(true);
                        code3($22,1);code1($12);
                        code1($03); code1($3d);
                        if restype='r' then
                        begin
                          code2($3b,1);
                          arsize3:=1
                        end
                      end else begin
                        code1($3d);
                        code2($3b,sspsz[idpnt]);
                        arsize3:=sspsz[idpnt];
                      end
                    end;
              'r','t': begin
                      code3(35,2);
                      idpnt:=prec(idpnt);
                      prcall(idpnt); scan;
                      restype:=low(stype[idpnt]);
                    end;
              'c':  if low(stype[idpnt])<>'r' then
                    begin
                      code3(34,svda[idpnt]);
                      scan;
                      if restype='s' then begin
                        if token=' [' then begin
                          index(true);
                          code1($03);
                          code1($58);
                          code1($54);
                          restype:='c';
                        end else begin
                          code1($58);
                          restype:='q';
                        end;
                      end;
                      {scan;}
                    end else begin
                      code2($3a,2);
                      code2(svda[idpnt] and 255,
                        svda[idpnt] shr 8);
                      code2(sspsz[idpnt] and 255,
                        sspsz[idpnt] shr 8);
                      arsize3:=1; scan
                    end;
              'a','e','x':
                    begin scan;
                      if token=' [' then begin
                        index(true);
                        code4($28,
                            level-slevel[idpnt],
                            2*svda[idpnt]);
                        if restype='r' then
                        begin
                          code2($3b,1);
                          arsize3:=1
                        end
                      end else begin
                        code4($27,
                            level-slevel[idpnt],
                            2*svda[idpnt]);
                        code2($3b,sspsz[idpnt]);
                        arsize3:=sspsz[idpnt];
                      end
                    end;
              's','u':
                    begin
                      code3(35,2*sspsz[idpnt]+2);
                      idpnt:=prec(idpnt);
                      prcall(idpnt); scan;
                      restype:=low(stype[idpnt]);
                      idpnt:=succ(idpnt);
                      arsize3:=sspsz[idpnt]
                    end
              else error(1)
            end {case}
          end; {identifier}
    'nu': begin code3(34,value[0]); scan;
            restype:='i'
          end;
    'ru': begin code2($3a,2);
            code2(value[0] and 255,
              value[0] shr 8);
            code2(value[1] and 255,
              value[1] shr 8);
            scan; restype:='r';
            arsize3:=1
          end;
    'st': begin
          if (reqtype='n') and (value[0]<3)
            then begin
              if value[0]<2 then begin
                code3(34,ord(ident[1]));
                restype:='c'
              end else begin
                code3(34,packed(ident[1],
                  ident[2]));
                restype:='p'
              end
            end else begin
              case reqtype of
                'c','u','n','q':
                    begin
                      if (vartype='q') or
                         (reqtype='q') then begin
                        arsize3:=0;
                        restype:='q';
                        code2($56,value[0]);
                      end else begin
                        arsize3:=prec(value[0]);
                        restype:='c';
                        code2($39,value[0]);
                      end;
                      for i:=1 to value[0] do
                        code1(ord(ident[i]));
                      if (vartype='q') or
                         (reqtype='q') then code1(0);
                    end;
                'p': begin
                      if odd(value[0]) then
                        error(15);
                      value[0]:=value[0] shr 1;
                      arsize3:=prec(value[0]);
                      restype:='p';
                      code2($3a,value[0]);
                      for i:=1 to value[0] do
                        begin
                        code1(ident[2*i]);
                        code1(ident[2*i-1]);
                      end
                    end
                else merror(14,'05')
              end {case}
            end;
            scan
          end;
    'od': begin
            argument('i'); code1(7);
            restype:='b'
          end;
    'me': begin
            parse(' ['); index(false);
            code1(23); restype:='i';
          end;
    ' (': begin
            scan; mainexp(reqtype,arsize3);
            testto(' )'); scan
          end; {no type change}
    'no': begin
            scan; factor(arsize3);
            if (arsize3<>0) then error(15);
            code1($11);
            if restype<>'i' then
              testtype('b')
          end;
    'cr': begin
            argument('i'); code1(52);
            restype:='c'
          end;
    'hi': begin
            argument('p'); code1(51);
            restype:='c'
          end;
    'lo': begin
            argument('p'); code1(52);
            restype:='c'
          end;
    'su': begin
            argument('u'); code1($14);
          end;
    'pc': begin
            argument('u'); code1($15)
          end;
    'cp': begin
            argument('i'); restype:='q';
          end;
    'ni': begin
            code3(34,0); scan; restype:='q';
          end;
    'ox': begin
            argument('u');
            restype:='i'
          end;
    ' @': begin
            scan; factor(arsize3);
            if arsize3<>0 then error(15);
            if restype<>'q' then testtype('i');
            restype:='f'
          end;
    'tr': begin
            code3(34,1); scan;
            restype:='b';
          end;
    'fa': begin
            code3(34,0); scan;
            restype:='b'
          end;
    'tc': begin
            parse(' ('); scan;
            arrayexp(1,'r');
            testto(' )'); scan;
            code1($47); restype:='i';
          end;
    'cv': begin
            argument('i');
            code1($46); arsize3:=1;
            restype:='r'
          end;
    'pa': begin
            parse(' ('); scan; express;
            testtype('c');
            if token=' ,' then begin
              scan; express; testtype('c');
              code1(53)
            end;
            testto(' )'); scan; restype:='p'
          end
    else error(1)
  end {case of token}
end {factor};

{##############}
{ body of term }
{##############}

begin
  factor(arsize2);
  repeat
    case token of
      ' *': opcode:=5;
      'di': opcode:=6;
      'an': opcode:=15;
      'sh': opcode:=18;
      'sr': opcode:=19;
      ' /': opcode:=$45
      else opcode:=0
    end {case};
    if opcode>0 then begin
      if (restype='r') and
            (arsize2=1) then begin
        scan; factor(arsize2);
        if (restype<>'r') or (arsize2<>1) then
          merror(14,'06');
        case opcode of
          5: code1($44);
          $45: code1($45)
          else error(17)
        end{case}
      end else begin
        if opcode=$45 then error(9);
        if arsize2<>0 then error(15);
        if (restype='b') and (opcode=15)
          then begin
          scan; factor(arsize2);
          if arsize2<>0 then error(15);
          testtype('b');
          code1(opcode)
        end else begin
          testtype('i'); scan;
          factor(arsize2);
          if arsize2<>0 then error(15);
          testtype('i'); code1(opcode);
        end
      end
    end;
  until opcode=0;
end;

{################}
{ body of simexp }
{################}

begin
  sign:=' ';
  if token=' +' then begin
    sign:='+'; scan
  end else if token=' -' then begin
    sign:='-'; scan
  end;
  term(arsize1);
  if sign<>' ' then begin
    if (restype='r')and (arsize1=1) then begin
      if sign='-' then code1($4e)
    end else begin
      testtype('i');
      if arsize1<>0 then error(15);
      if sign='-' then code1(2);
    end
  end;
  repeat
    case token of
      ' &': opcode:=1;
      ' +': opcode:=3;
      ' -': opcode:=4;
      'or': opcode:=14;
      'xo': opcode:=16
      else opcode:=0
    end {case};
    if opcode>1 then begin {if 1}
      if (restype='r') and (arsize1=1)
        then begin {real}
        scan; term(arsize1);
        if (restype<>'r') or (arsize1<>1) then
          error(17);
        case opcode of
          3:  code1($42);
          4:  code1($43)
          else error(17)
        end {case}
      end {real}
      else begin {not real}
        if (arsize1<>0) then error(15);
        if (restype='b') and (opcode>=14)
          then begin {boolean}
          scan; term(arsize1);
          if arsize1<>0 then error(15);
          testtype('b'); code1(opcode)
        end {boolean}
        else begin {not boolean}
          testtype('i'); scan;
          term(arsize1);
          if arsize1<>0 then error(15);
          testtype('i'); code1(opcode);
        end {not boolean}
      end {not real}
    end {if 1}
    else if opcode=1 then begin {else 1}
      sign:=restype;
      scan; term(opcode);
      arsize1:=arsize1+opcode+1;
      testtype(sign)
    end {else 1}
  until opcode=0
end {simexp};

{#################}
{ body of mainexp }
{#################}

begin { *** body of mainexp *** }
  roff:=0;
  simexp(arsize);
  if (restype='r') and (arsize=1) then
    roff:=$40;
  case token of
    ' =': opcode:=8;
    ' <': opcode:=10;
    ' >': opcode:=12;
    '<>': opcode:=9;
    '<=': opcode:=13;
    '>=': opcode:=11
    else opcode:=0
  end {case};
  if opcode>0 then begin
    if (arsize<>0) and (roff=0) then
      error(15);
    scan; savtype:=restype; simexp(arsize);
    if ((roff=0) and (arsize<>0))
      or((roff<>0) and (arsize>1)) then
      error(15);
    testtype(savtype); code1(opcode+roff);
    arsize:=0; restype:='b'
  end
end {mainexp};

{#########################}
{ assign ( of statement ) }
{#########################}

proc assign;
var savetype: char;

  proc assign1;
  {###########}
  begin
    testto(':='); scan; express;
    if (vartype='q') and (restype='s') then begin
      code1($58); restype:='q';
    end;
    gpval(idpnt,true,vartyp2);
  end {assign1};

begin {assign}
  idpnt:=findid;
  if idpnt=0 then error(5);
  if stype[idpnt]='pr' then begin
    prcall(idpnt);scan end
  else begin
    getvar; savetype:=vartype;
    if relad<2 then begin
      assign1; testtype(vartype)
    end else begin
      if vartyp2='i' then error(16); {8-bit mem}
      testto(':='); scan;
      if relad=3 then begin
        arrayexp(1,vartype); relad:=1;
        code1($53);
        if vartyp2='n' then begin
          code1($3f);
          code3($22,1);code1($12);
          code3($22,svda[idpnt]+2);
          code1($3);code1($3e)
        end else
          code4($2a,level-slevel[idpnt],
            2*svda[idpnt]+2);
        code2($3c,1)
      end else begin
        arrayexp(sspsz[idpnt],vartype);
        if vartyp2='n' then begin
          code3($22,svda[idpnt]+2*sspsz[idpnt]);
          code1($3e);
        end else
          code4($29,level-slevel[idpnt],
            2*(svda[idpnt]+sspsz[idpnt]));
        code2($3c,sspsz[idpnt]);
      end
    end
  end
end {assign};

{########################}
{ case1 ( of statement ) }
{########################}

proc case1;
var i1,i2,casave: integer;
    savetype: char;

  proc case2;
  {#########}

    proc case3;
    {#########}
    begin
      scan; code1(22); code3(34,getcon);
      testtype(savetype);
      code1(8); scan
    end;

  begin {case2}
    i1:=0; case3;
    while token=' ,' do begin
      push(pc); code3(38,0); i1:=succ(i1);
      case3
    end;
    testto(' :'); savpc:=pc; code3(37,0);
    for k2:=1 to i1 do fixup(pop);
    push(savpc);
    scan; statmnt
  end {case2};

begin {case1}
  scan; express; testto('of');
  savetype:=restype; i2:=1; case2;
  while token=' ;' do begin
    casave:=pc; code3(36,0); fixup(pop);
    push(casave); i2:=succ(i2); case2
  end;
  if token='el' then begin
    casave:=pc; code3(36,0); fixup(pop);
    push(casave); scan; statmnt
  end;
  testto('en'); for k2:=1 to i2 do fixup(pop);
  code3(35,-2); scan
end {case1};

{#########################}
{ openrw ( of statement ) }
{#########################}

proc openrw(x: integer);
begin
  parse(' ('); parse('id');
  idpnt:=findid;
  if idpnt=0 then error(5);
  getvar; code1(x);
  testferror;
  if relad=2 then error(15);
  if vartype<>'f' then merror(14,'07');
  gpval(idpnt,true,vartyp2);
  testto(' )'); scan
end {openrw};

{########################}
{ gpsec ( of statement ) }
{########################}

proc gpsec(code);   { get/put sector }

  proc gpsec1;
  {##########}
  begin
    scan; express; testtype('i');
    testto(' ,');
  end;

begin {gpsec}
  parse(' ('); gpsec1; gpsec1; gpsec1;
  code1(code);
  parse('id'); idpnt:=findid;
  if idpnt=0 then error(5);
  getvar; code3(34,$db); { get file error code }
  if relad=2 then error(15);
  code1(23); if vartype<>'i' then merror(14,'08');
  gpval(idpnt,true,vartyp2);
  testto(' )');
end {gpsec};

{###################}
{ body of statement }
{###################}

begin {body of statement }
  if token=' ;' then scan;
  case token of
    'id': assign;

    'if': begin {if}
            scan; express; testtype('b');
            testto('th'); scan;  savpc:=pc;
            code3(37,0); statmnt;
            if token='el' then begin {else}
              k2:=pc; code3(36,0);
              fixup(savpc); scan; statmnt;
              fixup(k2)
            end else fixup(savpc)
          end; {if}

    'be':  begin {begin}
            repeat
              scan; statmnt
            until token<>(' ;');
            testto('en'); scan
          end; {begin}

    'rp': begin {repeat}
            savpc:=pc;
            repeat
              scan; statmnt
            until token='un';
            scan; express; testtype('b');
            code3(37,savpc)
          end {repeat};

    're': begin {read}
            parse(' ('); scan;
            if token=' @' then begin
              scan; express; testtype('f');
              device:=true;
              code1(44); testto(' ,')
            end
            else begin
              device:=false; code1(26)
            end;
            repeat
              begin {main loop of read}
                if token=' ,' then scan;
                testto('id'); idpnt:=findid;
                if idpnt=0 then error(5);
                getvar;
                if relad=2 then error(15);
                case vartype of
                  'i':  code1(28);
                  'c':  code1(27);
                  'p':  begin
                        code1(27); code1(27);
                        code1(53)
                        end
                  else error(114)
                end {case};
                gpval(idpnt,true,vartyp2)
              end {mainloop of read}
            until token<>' ,';
            testto(' )'); scan;
            if device then code1(45);
          end {read};

    'wr','wl':
          begin {write,writeln}
            if token='wl' then wln:=true
            else wln:=false;
            scan;
            if token=' (' then begin
              scan;
              if token=' @' then begin
                scan; express;
                if restype='q' then restype:='f';
                testtype('f');
                device:=true; code1(44);
                testto(' ,');
              end else device:=false;
              repeat
                if token=' ,' then scan;
                if (token=' )') and device
                       and wln then
                   {empty writeln except device}
                   k2:=k2 {do nothing}
                else if token='st' then begin
                  {string}
                  code1(50);
                  for k2:=1 to value[0]-1 do
                    code1(ord(ident[k2])
                        and 127);
                  code1(ord(ident[value[0]])
                      or 128);
                  scan
                end else begin
                  {expression}
                  express;
                  case restype of
                    'i':  code1(30);
                    'c':  code1(29);
                    'q':  code1($57);
                    's':  begin
                            code1($58);
                            code1($57);
                          end;
                    'p':  begin
                            code1(22);
                            code1(51);
                            code1(29);
                            code1(52);
                            code1(29);
                          end
                    else merror(14,'09')
                  end {case}
                end {expression}
              until token<>' ,';
              if wln then begin {writeln(..)}
                code2(32,13); code1(29);
                code2(32,10); code1(29);
              end;
              if device then code1(45);
              testto(' )'); scan
            end {if}
            else if wln then begin {writeln}
              code2(32,13); code1(29);
              code2(32,10); code1(29);
            end
          end {write, writeln};

    'cs': case1; {case statement}

    'wh': begin {while}
            scan; savpc:=pc; express;
            testtype('b');
            k2:=pc; code3(37,0);
            testto('do'); scan; statmnt;
            code3(36,savpc); fixup(k2)
          end {while};

    'fo': begin {for}
            parse('id'); assign;
            if stype[idpnt]='pr' then error(1);
            savtp1:=low(stype[idpnt]);
            case token of
              'to': k2:=1;
              'dw': k2:=0
              else merror(2,'to')
            end {case of token};
            scan; express; testtype(savtp1);
            bottom1:=pc; code1(22);
            gpval(idpnt,false,vartyp2);
            code1(13-k2-k2);
            savpc:=pc; code3(37,0);
            testto('do'); scan; statmnt;
            gpval(idpnt,false,vartyp2);
            code1(21-k2);
            gpval(idpnt,true,vartyp2);
            code3(36,bottom1); fixup(savpc);
            code3(35,-2);
          end {for};

    'me': begin {mem}
            parse(' ['); scan; express;
            testtype('i');
            testto(' ]'); parse(':=');
            scan; express; code1(24);
            testtype('i');
          end {mem};

    'ca': begin {call}
            parse(' ('); scan; express;
            testtype('i');
            testto(' )'); code1(25); scan
          end {call};

    'op': openrw(47);

    'ow': openrw(48);

    'ob': openrw(80);

    'gb': begin
            parse(' ('); scan; express;
            testtype('f'); testto(' ,');
            scan; express; testtype('i');
            testto(' ,'); scan; testto('id');
            idpnt:=findid;
            if idpnt=0 then error(5);
            getvar;
            if relad<>0 then error(15);
            code1($51); testferror;
            gpval(idpnt,true,vartyp2);
            testto(' )'); scan
          end;

    'pb': begin
            parse(' ('); scan; express;
            testtype('f'); testto(' ,');
            scan; express; testtype('i');
            testto(' ,'); scan; express;
            code1($52);testferror;
            testto(' )');
            scan
          end;

    'ru': begin
            code1($41); scan;
          end;

    'fi': begin
            code1(46); scan
          end;

    'ge': gpsec(55);

    'pu': gpsec(56);

    'ex': begin {exit}
            if level>0 then code1(1) else code1(0);
            scan;
          end;

    'cl': begin {close}
            parse(' (');
            repeat
              scan; express; code1(49);
              testtype('f');
              testferror
            until token<>' ,';
            testto(' )'); scan;
          end {close}

    else if (token<>'en') and (token<>' ;')
      and (token<>'un') then begin
      error(10); scan
    end
  end {case of statements}
end;
