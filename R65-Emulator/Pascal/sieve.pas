program sieve;
const
  SIZE=8192;
  RUNS=10;
var
  flags: array[8191] of integer;
  i,k,prime,count,iter: integer;
begin
  for iter:=1 to RUNS do begin
    count:=0;

    { Initialize flags }
    for i:=0 to SIZE-1 do
      flags[i]:=1;

    { Find primes }
    for i:=0 to SIZE-1 do
      if flags[i]<>0 then begin
        prime:=i+i+3;

        { Mark multiples only up to 127 }
        if prime<=127 then begin
          k:=i+prime;
          while k<SIZE do begin
            flags[k]:=0;
            k:=k+prime;
          end;
        end;

        count:=count+1;
      end;
  end;

  writeln(count,' primes');
end. 