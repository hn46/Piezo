#!/bin/bash

NPP=4

PREFIX="Mo"
D_PREF="Mo"
STEP=0.1
MIN_A=0.00
MAX_A=2.00
MIN_B=0.00
MAX_B=2.00
X_1=0.000000
Y_1=0.000000
X_2=0.333333
Y_2=0.666667
SCALE=6


Y_1_INIT=$Y_1
Y_2_INIT=$Y_2

A=3.23
C=25
NAT=5
NTYP=5
ECUTW=50
ECUTRHO=350

ATOM_SPE="\
Ga     12.0107     Ga.pbe-dnl-kjpaw_psl.1.0.0.UPF
N      12.0107     N.pbe-n-kjpaw_psl.1.0.0.UPF
Mo     12.0107     Mo.pbe-dn-kjpaw_psl.1.0.0.UPF
S      12.0107     S.pbe-nl-kjpaw_psl.1.0.0.UPF
Se     12.0107     Se.pbe-n-kjpaw_psl.1.0.0.UPF
"

D_INN="/media/sakib05/D/MaTerials/WS/My_Rig_Pie/$D_PREF"
D_PSEUDO="/media/sakib05/D/MaTerials/UbuntuFiles/Pseudo/PAW"
D_QEE="/media/sakib05/D/MaTerials/Deb/qe-6.5/bin"

# D_INN="/home/nano3/Desktop/SAKIB/LST/$D_PREF"
# D_PSEUDO="/home/nano3/Desktop/SAKIB/Pseudo/"
# D_QEE="/home/nano3/Desktop/SAKIB/qe-6.5/bin"

# D_INN="/mnt/h/SAKIB/store/$D_PREF"
# D_PSEUDO="/mnt/h/SAKIB/pseudo/"
# D_QEE="/media/sakib_05/G4M35/MaTerials/UbuntuFiles/qe-6.3/bin"

if [ ! -d "$PWD/$D_PREF" ]; then
    mkdir $PWD/$D_PREF
    mkdir $PWD/$D_PREF/OUT
fi

touch $PWD/$D_PREF/$PREFIX.xyz
cat > $PWD/$D_PREF/$PREFIX.xyz << EOF
EOF
touch $PWD/$D_PREF/${PREFIX}.sh
cat > $PWD/$D_PREF/${PREFIX}.sh << EOF
#!/bin/bash
F_PREFIX=${PREFIX}
D_IN="$D_INN"
D_OUT="$D_INN/OUT"
D_QE="$D_QEE"
NP="$NPP"

if [ ! -d "\$D_OUT" ]; then
    mkdir \$D_OUT
fi

touch \$D_OUT/${PREFIX}_plot.dat
echo -e "\n" > ${PREFIX}_plot.dat

echo "Started Relax Calculation for ${PREFIX}"

EOF

#SCF file creation
for A_VAL in $(seq $MIN_A $STEP $MAX_A); do
    for B_VAL in $(seq $MIN_B $STEP $MAX_B); do
        ATOM_POS="\
Se      0.333333   0.666667   0.000000
Mo      0.000000   0.000000   0.068400
S       0.333333   0.666667   0.130000
Ga      ${X_1}   ${Y_1}   0.298000
N       ${X_2}   ${Y_2}   0.298000
"
        cat >> $PWD/$D_PREF/$PREFIX.xyz <<EOF
6
$ATOM_POS
EOF
# Se     0.3333333333    0.6666666667    0.0000000000
# Mo     0.0000000000    0.0000000000    0.0684000000
# S      0.3333333333    0.6666666667    0.1300000000
# Se     ${X_1}000000000    ${Y_1}000000000    0.2420000000
# Mo     ${X_2}    ${Y_2}    0.3100000000
# S      ${X_1}000000000    ${Y_1}000000000    0.3720000000
        Y_1=$(echo "scale=$SCALE; $Y_1+$STEP" | bc)
        Y_2=$(echo "scale=$SCALE; $Y_2+$STEP" | bc)
        # Y_2=$(calc $Y_2+$STEP | awk {'print $1'})
##################################--STARTING--#########################################
        touch $PWD/$D_PREF/${PREFIX}_${A_VAL}_${B_VAL}.scf.in
        cat > $PWD/$D_PREF/${PREFIX}_${A_VAL}_${B_VAL}.scf.in <<EOF
&CONTROL
    calculation   = "scf"
    outdir        = "$D_INN/work/"
    prefix        = "${PREFIX}_${A_VAL}_${B_VAL}"
    pseudo_dir    = "$D_PSEUDO"
    restart_mode  = "from_scratch"
    verbosity     = 'high'
/

&SYSTEM
    ibrav       =  4
    a           =  $A
    c           =  $C
    nat         =  $NAT
    ntyp        =  $NTYP
    input_dft   = 'PBE'
    ecutwfc     =  $ECUTW
    ecutrho     =  $ECUTRHO
    occupations = 'smearing'
    smearing    = 'mp'
    degauss     =  0.005
    vdw_corr    = 'DFT-D'
/

&ELECTRONS
    conv_thr         =  1.00000e-8
    mixing_beta      =  0.7
/

ATOMIC_SPECIES
$ATOM_SPE
ATOMIC_POSITIONS (crystal)
$ATOM_POS

EOF
        if [ $NPP == -1 ];then
        cat >> $PWD/$D_PREF/${PREFIX}.sh << EOF
date
\$D_QE/pw.x -i \$D_IN/${PREFIX}_${A_VAL}_${B_VAL}.scf.in > \$D_OUT/${PREFIX}_${A_VAL}_${B_VAL}.scf.out;
echo "${PREFIX}_${A_VAL}_${B_VAL}";
echo -n "\$(grep ! "\$D_OUT/${PREFIX}_${A_VAL}_${B_VAL}.scf.out" | awk {'print \$5'}) " >> \$D_OUT/${PREFIX}_plot.dat
EOF
        else
        cat >> $PWD/$D_PREF/${PREFIX}.sh << EOF
date
mpirun -np \$NP \$D_QE/pw.x -i \$D_IN/${PREFIX}_${A_VAL}_${B_VAL}.scf.in > \$D_OUT/${PREFIX}_${A_VAL}_${B_VAL}.scf.out;
echo "${PREFIX}_${A_VAL}_${B_VAL}";
echo -n "\$(grep ! "\$D_OUT/${PREFIX}_${A_VAL}_${B_VAL}.scf.out" | awk {'print \$5'}) " >> \$D_OUT/${PREFIX}_plot.dat
EOF
        fi
    done
        Y_1=$Y_1_INIT
        Y_2=$Y_2_INIT
        X_1=$(echo "scale=$SCALE; $X_1+$STEP" | bc)
        X_2=$(echo "scale=$SCALE; $X_2+$STEP" | bc)
        cat >> $PWD/$D_PREF/${PREFIX}.sh << EOF
echo -e "\n" >> \$D_OUT/${PREFIX}_plot.dat
EOF

done


