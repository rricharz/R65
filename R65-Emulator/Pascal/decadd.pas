program decadd;
uses syslib,strlib;

var accu:cpnt;
    tests,passed:integer;

func add(a,b,r:cpnt;size:integer):boolean;
var
  a1,b1,t:cpnt;
  i,j,k,n,carry,cmp:integer;
  sa,sb,negative,subtract:boolean;
begin
  add:=false;
  if (size<4) or (size>16) then exit;

  { Determine signs }
  a1:=a;
  b1:=b;
  sa:=false;
  sb:=false;
  if a1[0]='-' then begin
    sa:=true;
    a1:=a1+1;
  end;
  if b1[0]='-' then begin
    sb:=true;
    b1:=b1+1;
  end;

  { Find ends of input fields }
  i:=0;
  while (a1[i]<>ENDMARK) and (a1[i]<>',') do i:=i+1;
  j:=0;
  while (b1[j]<>ENDMARK) and (b1[j]<>',') do j:=j+1;

  { Check decimal points }
  if (i<4) or (j<4) then exit;
  if (a1[i-3]<>'.') or (b1[j-3]<>'.') then exit;

  subtract:=sa<>sb;
  negative:=sa;

  { For subtraction, larger magnitude first }
  if subtract then begin
    if i>j then
      cmp:=1
    else if i<j then
      cmp:=-1
    else
      cmp:=_strncmp(a1,b1,i);

    if cmp<0 then begin
      t:=a1;
      a1:=b1;
      b1:=t;
      k:=i;
      i:=j;
      j:=k;
      negative:=sb;
    end;
  end;

  { Prepare result }
  for k:=0 to size-1 do r[k]:='0';
  r[size]:=ENDMARK;
  r[size-3]:='.';

  { Add or subtract digits from right to left }
  i:=i-1;
  j:=j-1;
  k:=size-1;
  carry:=0;

  while k>=0 do begin
    if k=size-3 then
      k:=k-1
    else begin
      if (i>=0) and (a1[i]='.') then i:=i-1;
      if (j>=0) and (b1[j]='.') then j:=j-1;

      n:=carry;

      if i>=0 then begin
        if (a1[i]<'0') or (a1[i]>'9') then exit;
        n:=n+ord(a1[i])-ord('0');
        i:=i-1;
      end;

      if j>=0 then begin
        if (b1[j]<'0') or (b1[j]>'9') then exit;
        if subtract then
          n:=n-ord(b1[j])+ord('0')
        else
          n:=n+ord(b1[j])-ord('0');
        j:=j-1;
      end;

      if n<0 then begin
        n:=n+10;
        carry:=-1;
      end
      else begin
        carry:=n div 10;
        n:=_mod(n,10);
      end;

      r[k]:=chr(ord('0')+n);
      k:=k-1;
    end;
  end;

  { Overflow or unprocessed input }
  if (i>=0) or (j>=0) or (carry<>0) then exit;

  { Remove leading zeros, keeping one integer digit }
  k:=0;
  while (r[k]='0') and (k<size-4) do k:=k+1;

  { Check if result is zero }
  if r[k]='0' then begin
    if (r[k+2]='0') and (r[k+3]='0') then
      negative:=false;
  end;

  { Check width including possible minus sign }
  if negative and (size-k+1>size) then exit;

  { Move result to beginning }
  i:=0;
  if negative then begin
    r[0]:='-';
    i:=1;
  end;

  while r[k]<>ENDMARK do begin
    r[i]:=r[k];
    i:=i+1;
    k:=k+1;
  end;
  r[i]:=ENDMARK;

  add:=true;
end;

proc testadd(a,b,expected:cpnt;size:integer;
             shouldwork:boolean);
var success:boolean;
begin
  tests:=tests+1;
  success:=add(a,b,accu,size);

  if success=shouldwork then begin
    if not success then
      passed:=passed+1
    else if _strcmp(accu,expected)=0 then
      passed:=passed+1
    else
      writeln('FAIL ',tests,' result=',accu,
              ' expected=',expected);
  end
  else
    writeln('FAIL ',tests,' ok=',success,
            ' a=',a,' b=',b);
end;

begin
  accu:=_new;
  tests:=0;
  passed:=0;

  { Positive addition }
  testadd('123.45','6666.35','6789.80',10,true);
  testadd('0.00','0.00','0.00',10,true);
  testadd('0.99','0.01','1.00',4,true);
  testadd('999.99','0.01','1000.00',10,true);
  testadd('999999.99','0.01','1000000.00',10,true);

  { Positive overflow }
  testadd('9999999.99','0.01','',10,false);
  testadd('99.99','0.01','',4,false);
  testadd('999.99','0.01','',6,false);

  { Negative plus negative }
  testadd('-123.45','-20.00','-143.45',10,true);
  testadd('-999.99','-0.01','-1000.00',10,true);
  testadd('-0.01','-0.01','-0.02',5,true);

  { Mixed signs, positive result }
  testadd('200.00','-123.45','76.55',10,true);
  testadd('-123.45','200.00','76.55',10,true);
  testadd('100.00','-0.01','99.99',10,true);

  { Mixed signs, negative result }
  testadd('123.45','-200.00','-76.55',10,true);
  testadd('-200.00','123.45','-76.55',10,true);
  testadd('0.00','-1.00','-1.00',10,true);

  { Cancellation and zero }
  testadd('123.45','-123.45','0.00',10,true);
  testadd('-123.45','123.45','0.00',10,true);
  testadd('-0.00','0.00','0.00',10,true);

  { Width boundaries }
  testadd('-0.01','0.00','',4,false);
  testadd('-0.01','0.00','-0.01',5,true);
  testadd('-99.99','0.00','-99.99',6,true);
  testadd('-999.99','0.00','',6,false);
  testadd('1.00','2.00','',3,false);
  testadd('1.00','2.00','',17,false);

  { Comma-terminated fields }
  testadd('123.45,100.00','20.00,','143.45',10,true);
  testadd('-123.45,','20.00,','-103.45',10,true);

  { Invalid inputs }
  testadd('1.2','2.00','',10,false);
  testadd('1.X0','2.00','',10,false);
  testadd('12.00','3.00','15.00',10,true);

  writeln('Tests: ',tests,' Passed: ',passed);

  _release(accu);
end.
