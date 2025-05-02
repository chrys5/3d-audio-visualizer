# split 16384 into 16 bins logarithmically spaced between 10 and 16384 (or so)
LINEAR_BINS = 16384
factor = 2**(14/25)
bins = [round(factor**i) for i in range(4, 26)]
print(bins)