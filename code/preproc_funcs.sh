#!/bin/bash

subj=$1
subj=sub-rid0000${subj}



code_dir=`pwd`

dpath=../../../$subj # datapath for this subject
cd ../../../
### First get the data from Datalad
datalad get $subj

cd ${code_dir}


opath=../$subj # output directory
tr=2.0
# make the output directory
mkdir $opath 
cp ${dpath}/anat/${subj}_T1w.nii.gz ${opath}/T1w.nii.gz
# set list of run numbers
runNums=`count -digits 1 1 5`

# list of tasks
tasks="beh tax"

# create stimuli directory
spath=${opath}/stimuli
mkdir $spath

# Convert stim times to AFNI format
python make_stimtimes.py $subj

runs=""
for task in $tasks
do
    for r in $runNums
    do
        runs="${runs}${task}_run-${r} "
    done
done

echo $runs


# ================================= tshift =================================
# time shift data so all slice timing is the same 
step=01
stpath=$opath/slicetimes
mkdir $stpath
for run in $runs 
do
    
    python get_slicetimes.py $subj $run $stpath 
    in_fn=${dpath}/func/${subj}_task-${run}_bold.nii.gz
    out_fn=${opath}/st${step}.$run.tshift
    tpat=$stpath/${run}.1D
    3dTshift -TR $tr -tzero 0 -quintic -tpattern @${tpat} -prefix $out_fn $in_fn
done


# --------------------------------
# extract volreg registration base
3dbucket -prefix $opath/vr_base $opath/st01.beh_run-1.tshift+orig'[2]'

# ================================= volreg =================================
# align each dset to base volume
mp_path=$opath/motion_params
mkdir $mp_path
step=02 

for run in $runs
do
    # register each volume to the base image
    in_fn=${opath}/st01.$run.tshift+orig
    out_fn=$opath/st${step}.$run.volreg
    3dvolreg -verbose -zpad 1 -base $opath/vr_base+orig                    \
             -1Dfile $mp_path/$run.1D \
             -prefix $out_fn -cubic $in_fn
done

# ================================== blur ==================================
# blur each volume of each run
step=03
for run in $runs
do

    in_fn=$opath/st02.$run.volreg+orig
    out_fn=$opath/st${step}.$run.blur
    3dmerge -1blur_fwhm 4.0 -doall -prefix $out_fn \
            $in_fn
done


# ================================== mask ==================================
# create 'full_mask' dataset (union mask)
for run in $runs
do
    in_fn=$opath/st03.$run.blur+orig
    out_fn=$opath/rm.mask_$run
    3dAutomask -prefix $out_fn $in_fn
done

# create union of inputs, output type is byte
3dmask_tool -inputs $opath/rm.mask_*+orig.HEAD -union -prefix $opath/full_mask



# ================================= scale ==================================
# scale each voxel time series to have a mean of 100
# (be sure no negatives creep in)
# (subject to a range of [0,200])
step=04
for run in $runs 
do

    in_fn=$opath/st03.$run.blur+orig
    out_fn=$opath/st${step}.$run.scal
    3dTstat -prefix $opath/rm.mean_$run $in_fn
    3dcalc -a $in_fn -b $opath/rm.mean_$run+orig \
           -expr 'min(200, a/b*100)*step(a)*step(b)'           \
           -prefix $out_fn
done

# ================================ regress =================================

# compute de-meaned motion parameters (for use in regression)
for run in $runs
do
    in_fn=$opath/motion_params/$run.1D
    out_fn=$opath/motion_params/$run.demean.1D
    1d_tool.py -infile $in_fn                   \
           -demean -write $out_fn
done

# ------------------------------
# run the regression analysis
# We will do this for each run separately to
# prepare data for MVPA run-wise crossvalidation

Rmodel="WAV(2)" # "TENT(0,14,7)"
mask=$opath/full_mask+orig.HEAD

for run in $runs
do
    in_fn=$opath/st04.$run.scal+orig.HEAD
    out_fn=$opath/stats.$run.nii.gz
    mot_par=$opath/motion_params/$run.demean.1D
    stims=`ls $opath/stimuli/task-$run*`
    stim_arg=""
    s=1
    for stim in $stims
    do
        lab=`echo $stim | awk -F / '{print $4}' | awk -F . '{print $1}'`
        lab=`echo $lab | awk -F _ '{a = $3;  b = $4; print a"_"b}'`
        stim_arg="${stim_arg}-stim_times $s $stim $Rmodel "
        stim_arg="${stim_arg}-stim_label $s $lab "
        s=$(( s + 1 ))
        
    done

    3dDeconvolve -input $in_fn              \
        -mask $mask \
        -ortvec $mot_par mot_demean                        \
        -polort 3 -float                                           \
        -jobs 12 \
        -num_stimts 20 $stim_arg                                 \
        -fout -tout -x1D $opath/X.$run.xmat.1D -xjpeg $opath/X.$run.jpg                    \
        -fitts $opath/fitts.$run                                         \
        -errts $opath/errts.$run                                       \
        -bucket $out_fn

done
STOP

for run in $runs
do
    3dbucket -prefix ${opath}/tstats_$run ${opath}/stats.${run}.nii.gz'[2..59(3)]'
done

