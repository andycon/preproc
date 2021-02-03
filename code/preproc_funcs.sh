#################################################################################
#
#   preproc_funcs.sh
#
#   Usage: bash preproc_funcs.sh SUBJ
#
################################################################################
subj=$1
subj=sub-rid0000${subj}
anat=T1w.nii.gz

if [ ${#1} -eq 0 ]
then
    head -n 7 preproc_funcs.sh
    exit 55
fi

# Change the value of 'cleanup' to 1, if you want to delete all intermediate files
# created by this script. It is recommended to visually inspect your data to
# make sure that everythi9ng is working ok throughout the processing steps. ONce
# you are confident that this are all good, then cleanup as you wish to save
# space. This processing script takes just 5 or so minutes to complete, so it is
# not a big loss if you have to do it all over again..
cleanup=1

# Likewise change dropDataladData to 1 to also clear out the downloaded data in
# the parent dataset
dropDataladData=1

code_dir=`pwd`

dpath=../../../$subj # datapath for this subject
opath=../$subj # output directory

### First get the data from Datalad
cd ../../../
datalad get $subj
cd ${code_dir}


tr=2.0
# make the output directory
mkdir $opath 
cp ${dpath}/anat/${subj}_$anat ${opath}/$anat
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

# Save a mean volume of motion-corrected EPI for use in registering to
# anatomy

out_fn=$opath/st02.beh_run-1.volreg
 
3dTstat -mean -prefix $opath/epi_mu $out_fn+orig

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

for run in $runs
do
    3dbucket -prefix ${opath}/tstats_$run ${opath}/stats.${run}.nii.gz'[2..59(3)]'
done

######################### Align EPI mean to original T1 ########################
#
# Nota bene: argument "-keep_rm_files". This keeps all intermediate files
# including a T1w anatomical image that is aligned to the motion-corrected EPI
# data, i.e. the EPI mean saved earlier. We rename the tempfile as T1w_a2e+orig,
# using "a2e" representing "Anatomical to EPI".  This is useful for viewing the
# preprocessing results in native EPI space. In the next step, we will align the
# original T1w image to an MNI template, and then use the EPI to ANAT
# transformation to align the EPI data to the MNI template.
#
# So in this step we have: 
#   1 epi_mu+orig -align-to-> T1w+orig :yield:-> epi_mu_e2a+orig (T1w+orig space) 
#   2 T1w+orig    ----------> epi_mu+orig ::::-> T1w_a2e+orig    (EPI+orig space)
#   
# In the next step using the separate alignment script, we will have:
#   3 T1w+orig    ----------> MNI_template :::-> T1w_A+tlrc    (MNI space)
#   4 T1w_a2m+tlrc ~~QWarp~~> MNI_template :::-> T1w_AQ+tlrc   (MNI space)
#   
# And finally we use the transformations ("delta-n", Dn) from n steps 1,3,4 to
# register and non-linearly warp all EPI results to MNI space, thus:
#   5 <EPI>+orig -D1-> <EPI>_a2e+orig -D3-> <EPI>_A+tlrc -D4-> <EPI>_AQ+tlrc
#
#################################################################################
cd $opath
align_epi_anat.py -anat $anat -epi epi_mu+orig \
      -epi_base 0 -epi2anat -big_move -keep_rm_files
3dcalc -prefix T1w_a2e -a __tt_T1w_al+orig -expr 'a'

cd $code_dir

if [ $cleanup -eq 1 ]
then
    bash cleanup_preproc.sh $subj $dropDataladData
else
    echo "*************************************************************"
    printf "\n\n All results, including many intermediate datasets are in \n
    $opath. Go there and use afni to check your results. If you don't want \n
    all that extra stuff hanging around, consider changing the \n
    value of 'cleanup' to 1 at the top of the script. Likewise for \n
    dropDataladData.  Why keep it if you don't need it? For now, you can clean \n
    up $opath (and Datalad data) from the command line by running: \n
    'bash cleanup_preproc.sh $subj 1', or not. Suite yourself.\n\n"
    echo "============================================================"


fi
