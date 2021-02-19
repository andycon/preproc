#################################################################################
#
#   align_to_MNI.sh
#
#   Usage: bash align_to_MNI.sh SUBJ
#
################################################################################
if [ ${#1} -eq 0 ]
then
    head -n 7 align_to_MNI.sh
    exit 55
fi

sub=$1
cd ../sub-rid0000${sub}

# This might help fix path issues 
# or not? PATH=/optnfs/afni/2017_10_2:$PATH

#afni_path=`which afni | awk -F "/afni" '{print $1}'`
afni_path=`which afni`
n=${#afni_path}
n=$(( $n - 4 ))
afni_path=${afni_path:0:$n}

#if [[ "$afni_path" == "afni not found" ]]
#then
#    echo "Where's Afni? Afni appears to not be installed."
#    exit 55
#fi

echo $afni_path
anat=T1w.nii.gz
temp="${afni_path}/MNI152_2009_template_SSW.nii.gz"
masks="${afni_path}/MNI_Glasser_HCP_v1.0.nii.gz"

# ==================== Alignment Step 3 =======================================
#
#   Align T1w-ANAT original version to MNI template using 12 param affine
#   translation, rotation, stretching, and shearing
#

3dUnifize -input ${anat} -prefix T1w_U

3dSkullStrip -input T1w_U+orig -prefix T1w_US -niter 400 -ld 40

3dAllineate -prefix T1w_USA -base $temp    \
            -source T1w_US+orig -twopass -cost lpa \
            -source_automask \
            -1Dmatrix_save T1w_USA.aff12.1D \
            -autoweight -fineblur 3 -cmass

# ==================== Alignment Step 4 ======================================
#
#   Refine T1w to MNI alignment using non-linear Qwarp
#
3dQwarp -prefix T1w_USAQ -blur 0 3 \
        -base $temp -source T1w_USA+tlrc

# ==================== Alignment Step 5 =====================================
#
#   Align the processed EPI data using transormations from steps 1, 3, and 4
#
#   If you are wondering what happened to steps 1 and 2, see the end of
#   preproc_funcs.sh. 
#

tstats=`ls tstats*.HEAD` # globs a list of all tstat files
for tstat in $tstats
do

    pref=`echo $tstat | awk -F + '{print $1}'`

    3dNwarpApply -source $tstat                                \
         -nwarp "T1w_USAQ_WARP+tlrc T1w_USA.aff12.1D epi_mu_al_reg_mat.aff12.1D" \
         -master T1w_USAQ_WARP+tlrc -newgrid 3.0                          \
         -prefix Q${pref}.nii.gz
done


# ==================== Save Q-Warped brain as nifti ========================
3dcalc -prefic T1w_USAQ.nii.gz -a T1w_USAQ+tlrc -expr 'a'

# ==================== Make some masks =====================================

# Refit the glasser masks to match the EPI grid
3dresample -master Q${pref}.nii.gz -prefix glasser_masks.nii.gz -input $masks

# use the glasser masks to make a binary gray matter mask
3dcalc -prefix gmask.nii.gz -a glasser_masks.nii.gz -expr 'step(a)'

# make a dilated version of gray-matter mask
3dcalc -a gmask.nii.gz -prefix gmaskD.nii.gz                     \
             -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k     \
             -expr 'amongst(1,a,b,c,d,e,f,g)'

cd ../code
