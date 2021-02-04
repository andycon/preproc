###############################################################################
#
#   Align all subjects at once by submitting parallel bash jobs.
#
#   Usage: bash align_all.sh goforit
#
#   Without 'goforit' the code does not execute, and you will see this message.
#
#   Please read section below cafeully before going for it.
#
############################# Bash 101 ########################################
#
#   IF-THEN-ELSE
#
#   This script illustrates how to use an if-else statement in Bash. Whenever
#   you call a bash script the arguments to the script are accessible inside the
#   script as $1 for the first argument following the command on the command
#   line, $2 for the second, etc. Here the script is expecting one argument,
#   which is expected to be the string "goforit". This is just to try to ensure
#   that you know what you are doing before executing the script, which will
#   spawn a resource-heavy set of processes. See Bash 101 in preproc_all.sh for
#   more on this and a detailed run-down of the Bash FOR-loop.
#
#   When you call this script with goforit like this:
#       bash align_all.sh goforit
#
#   The value of $1 will be the string "goforit". The IF statement checks if
#   this is actually the case by evaluating the conditional statement:
#       [ $1 != "goforit" ]
#
#   which can be understood as [ TRUE if $1 does not equal 'goforit' ]. If this
#   statement resolves to TRUE, either because you did't include 'goforit' or
#   you misspelled it, e.g. "Go_4_IT" etc., then the statement immediately
#   following the THEN is exectuted, and the ELSE section is skipped.
#
#   In case [ "$1" != "goforit" ] in fact returns TRUE, the script executes the
#   command:
#       less align_all.sh
#
#   which shows you the contents of this file including this message. 
#
#   In case you were able to spell 'goforit' correctly, the conditional resolves
#   to FALSE, thus skipping the execution of the first part of THEN, and going
#   straight to ELSE and executes the FOR-loop therein. 
#   
#   The end fi, marks the end of the IF block. This is a cute Bashism derived
#   as IF backwards. Bash complains if you don't provide fi at the end. Note
#   that this is different from Python, which does not require such an explicit
#   ending marker. Unlike Python, Bash does not care about indentation, so the
#   explicit fi is necessary. Nevertheless, it is good practice to use
#   indentation in Bash scripts that conform more-or-less to Pythonic standards
#   because it makes reading the code much more enjoyable.
#
#   A. Connolly
#   1612386164 SSE
#
################################################################################
msg="...going for it.."
echo goforit
echo
if [ "$1" != "goforit" ]
then
    less align_all.sh
else
    mkdir logs > /dev/null 2>&1

    subs="01 12 17 24 27 31 32 33 34 36 37 41" 
 
    for s in $subs 
    do 
        msg=${msg}..${s}.
        printf $msg
        bash align_to_MNI.sh $s >> logs/$s.align.log 2>&1  
    done
fi
printf \finDuMonde


