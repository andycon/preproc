
sub=$1
cd ../sub-rid0000${sub}

afni_path=$HOME/bin/abin
epi=st02.beh_run-1.volreg+orig
anat=T1w.nii.gz
#temp="$HOME/bin/abin/MNI152_T1_2009c+tlrc" # Template ships with AFNI
temp="${afni_path}/MNI152_2009_template_SSW.nii.gz"
masks="${afni_path}/MNI_Glasser_HCP_v1.0.nii.gz"


3dUnifize -input ${anat} -prefix T1w_U

3dSkullStrip -input T1w_U+orig -prefix T1w_US -niter 400 -ld 40

3dAllineate -prefix T1w_USA -base $temp    \
            -source T1w_US+orig -twopass -cost lpa \
            -1Dmatrix_save T1w_USA.aff12.1D \
            -autoweight -fineblur 3 -cmass

3dQwarp -prefix T1w_USAQ -blur 0 3 \
        -base $temp -source T1w_USA+tlrc

3dTstat -mean -prefix epi_mu $epi 


align_epi_anat.py -anat $anat -epi epi_mu+orig \
      -epi_base 0 -epi2anat -big_move    


3dNwarpApply -source epi_mu+orig                                \
     -nwarp "T1w_USAQ_WARP+tlrc T1w_USA.aff12.1D epi_mu_al_reg_mat.aff12.1D"                 \
     -master T1w_USAQ_WARP+tlrc -newgrid 3.0                          \
     -prefix epi_mu_alAQ

tstats=`ls tstats*.HEAD` # globs a list of all tstat files
for tstat in $tstats
do

    pref=`echo $tstat | awk -F + '{print $1}'`

    3dNwarpApply -source $tstat                                \
         -nwarp "T1w_USAQ_WARP+tlrc T1w_USA.aff12.1D epi_mu_al_reg_mat.aff12.1D"                 \
         -master T1w_USAQ_WARP+tlrc -newgrid 3.0                          \
         -prefix Q${pref}.nii.gz
done

# finally make the gray matter mask
3dresample -master Q${pref}.nii.gz -prefix glasser_masks.nii.gz -input $masks
3dcalc -prefix gmask.nii.gz -a glasser_masks.nii.gz -expr 'step(a)'
3dcalc -a gmask.nii.gz -prefix gmaskD.nii.gz                     \
             -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k     \
             -expr 'amongst(1,a,b,c,d,e,f,g)'

cd ../code
