s=$1 

prep=`du -h -d 0 ../${s} | awk '{print $1}'`

cd ../${s}
chmod u+w *
rm *orig*
rm *1D
rm epi*
rm T1w.nii.gz

# copy T1w_USAQ+tlrc to a nifti file for mass consumption.
3dcalc -prefix T1w_USAQ.nii.gz -a T1w_USAQ+tlrc -expr 'a' 

rm *tlrc*

prep_c=`du -h -d 0 ../${s} | awk '{print $1}'`

# Function that takes a size such as 234K, 654G, 456.34M, etc,
# and prints the value in Bytes
bytize () {
    x=$1
    n=${#x}
    n=$(( $n - 1 ))
    p=${x:$n}
    sgd=${x:0:$n}
    omag=1
    case $p in
        B)
            omag=1;;
        K)
            omag=1000;;
        M)
            omag=1000000;;
        G)
            omag=1000000000;;
        T)
            omag=1000000000000;;
    esac

    echo $sgd $omag | awk '{print $1*$2}'
}

# Function that takes 2 integer inputs and subtracts the
# 2nd from the 1st, and also prints the Order of Magnitude, KiloBytes, etc.
comput () {
    s=`echo $1 $2 | awk '{print $1-$2}'`
    n=${#s}
    p=Bytes
    round=0
    case $n in
        4 | 5 | 6)
            p="KiloBytes"
            round=3;;
        7 | 8 | 9)
            p="MegaBytes"
            round=6;;
        10 | 11 | 12)
            p="GigaBytes"
            round=9;;
        13 | 14 | 15)
            p="~~ TERABYTES!! ~~"
            round=12;;
    esac
    r=$(( $n - $round ))
    echo ${s:0:$r} $p
}

# How much disk space did you save by running this program?
a=`bytize $prep`
b=`bytize $prep_c`

howmuch=`comput $a $b`
echo "******************************************************"
printf "\n\tThanks for cleaning up your mess. You saved 
        $howmuch of precious diskspace. Not bad.\n\n"
echo "======================================================"






