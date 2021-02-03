#################################### Bash 101 ##################################
#
#   FOR loop for iterating across subjects and processing each subject in turn
#   by calling :
#       bash preproc_funcs.sh <SUB>
#
#   The array of subjects is written as a string assigned to the variable subs
#   with spaces (or any white space) separating the subject ids. The FOR-loop
#   uses the white spaces to parse the string and assigns the values
#   one-at-a-time to the variable $s for doing the DO section.   
#
#   The second part of the preproc_funcs call is optional:
#       > $s.preproc.log 2>&1
#   
#   The greater-than symbol > redirects standard output stdout to a file (or bit
#   stream) here named $s.preproc.log. The $s is the aforementioned subject
#   variable, so if $s was 01 the file name resolves to 01.preproc.log, and
#   because there is no path preceding the output file, it will be written to
#   the present working
#   directory <pwd>. 
#   
#   The next part:
#       2>$1
#   
#   takes standard error stderr output 2, i.e. the second output from the
#   code execution, and redirects it >& to stdout 1 which was the first output.
#   So 2 gets redirected to 1 which gets redirected to the log file. The end
#   result is that you don't see anthing written  to the screen when you execute
#   the script. All messages and error messages get written to the log, which
#   can be useful later for checking errors.
#
#   The final ampersand: 
#       & 
#
#   makes it so that Bash does not wait until the command
#   returns to execute the next command. So this will submit all of the subjects
#   at once, and runs them in the background in parallel. It might be possible
#   to use up all of your RAM and overwhelm your processors so that your
#   computer slows or even freezes! Monitor your resources while testing code
#   like this. I like the linux utility htop - open another terminal on the same
#   machine and type htop, if that doesn't work, type top, and then install
#   htop. htop lets you watch your RAM and processors, and lets you manage open
#   processes. My computer has 16Gb RAM and 12 processing cores, which is more
#   than enough. If you have less than 8Gb RAM try submitting two or three
#   subjects at a time, at first. 
#
#   A. Connolly
#   
################################################################################   
subs="01 12 17 24 27 31 32 33 34 36 37 41"

for s in $subs
do
    bash preproc_funcs.sh $s > $s.preproc.log 2>&1 &
done
