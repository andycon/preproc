import sys

s = sys.argv[1]



stims = {} # initialize dictionary

for task in ["beh","tax"]:
    stims[task] = {}
    for run in range(1,6):
        stims[task][run] = {}
        fn = "../../../{}/func/{}_task-{}_run-{}_events.tsv".format(s,s,task,run)
        f = open(fn, 'r')
        lines = f.readlines()
        f.close()

        for line in lines[1:]:
            ln = line.split()
            t = ln[0]
            c = ln[2]

            if c in stims[task][run].keys():
                stims[task][run][c].append(t)
            else:
                stims[task][run][c] = [t]


for task in ["beh","tax"]:
    for run in range(1,6):
        for c in stims[task][run].keys():
            fn = "../{}/stimuli/task-{}_run-{}_{}.1D".format(s,task,run,c)
            f = open(fn,'w')
            times = ""
            for t in stims[task][run][c]:
                times = times + "{} ".format(t)
            f.write("{}\n".format(times.strip()))
            f.close()

