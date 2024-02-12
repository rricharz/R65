{ irandom: real and integer random functions with limit
}

func rrandom(min,max:real):real;
begin
  rrandom := min + (conv(random)/255.0) * (max - min);
end;

func irandom(min,max:integer):integer;
begin
  irandom := trunc(rrandom(conv(min),conv(max)));
end;
