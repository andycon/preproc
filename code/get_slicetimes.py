import json
import sys

sub = sys.argv[1]
run = sys.argv[2]
opath = sys.argv[3]

fn="../../../{}/func/{}_task-{}_bold.json".format(sub,sub,run)
info = json.load(open(fn))

slicetimes_fn = "../{}/slicetimes/{}.1D".format(sub,run)
f = open(slicetimes_fn,'w')

for t in info['SliceTiming']:
    f.write("{}\n".format(t))

f.close()

