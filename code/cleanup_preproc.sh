s=$1 
d=$2

dlad=`du -h -d 0 ../../../.git | awk '{print $1}'`
prep=`du -h -d 0 ../${s} | awk '{print $1}'`

echo $dlad $prep

echo $s $d
cd ../${s}
rm __*
rm rm*
rm fitts*
rm errts*
rm st*
rm X*
rm full*
rm vr*
rm epi_mu_al+*


if [ "$d" -eq "1" ]
then
    datalad drop ../../../${s}
fi

dlad_c=`du -h -d 0 ../../../.git | awk '{print $1}'`
prep_c=`du -h -d 0 ../${s} | awk '{print $1}'`

# The rest of This is just for fun
# and for providing examples of how to write and use functions in BASH

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

# Function that takes 4 integer inputs and adds the first two and subtracts the
# 3rd and 4th, and also prints the Order of Magnitude, KiloBytes, etc.
comput () {
    s=`echo $1 $2 $3 $4 | awk '{print $1+$2-$3-$4}'`
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
a=`bytize $dlad`
b=`bytize $prep`
c=`bytize $dlad_c`
d=`bytize $prep_c`

howmuch=`comput $a $b $c $d`
echo "******************************************************"
printf "\n\tThanks for cleaning up your mess. You saved 
        $howmuch of precious diskspace. Not bad.\n\n"
echo "======================================================"






