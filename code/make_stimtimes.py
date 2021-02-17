import sys
import glob

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

# Now for each condition lets make a stimtimes file for all ten runs. This is
# just the same as for individual runs, except instead of just one row of times
# indicating the onsets of the stimuli in just one run, each file will contain
# ten rows, one row for each run.

conds = stims['beh'][1].keys()  # Note: The stims dict for each condition and run
                                # should contain a list of the all 20 conditions
for c in conds:
    allruns_fn = "../{}/stimuli/{}_allruns.1D".format(s,c)  # filename for allruns
                                                    # stimfile
    print("\n.......>>>>> {}\n".format(c))
    print("<> Python glob.glob returns unsorted list of filenames")
    print("-----> matching pattern:\n")
    files = glob.glob("../{}/stimuli/*{}.1D".format(s,c))
    for f in files:
        print(f)
    files.sort()
    print("\n<> Python list.sort is used to sort the filenames\n ----> Sorted:\n")
    for f in files:
        print(f)

    print("\n<> Saving stimtimes for {} for all runs in {}".format(c,allruns_fn))
    allruns = open(allruns_fn,'w')
    for f in files:
        allruns.write(open(f).read())
    allruns.close()

        
