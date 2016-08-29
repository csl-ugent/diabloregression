#!/bin/bash

# this script (re)generates the contents of the entire helperdata directory,
# save for the *nocpp.conf files. The only things to change are the CONFIG
# and SPECINSTDIR variables below (everything can be generated for any
# *x86* set of compiled benchmarks)

CONFIG=i486gcc481bu223O2
SPECINSTDIR=/home/jmaebe/diablo/spec2006inst

set -eu

# argument 1: benchmark name
# argument 2: input file name
# result: name to add (empty if to be skipped)
FilterInputFileName() {
  BENCHNAME="$1"
  FILE="$2"
  # skip big endian input files, remove .le. from little endian input file
  # names (so that we have one set of input file names; this is unrelated
  # to the endianess of the platform eventually tested, that's handled by
  # spec2regression, which will copy the correct files to these names)
  if [ $BENCHNAME == sphinx3 ]; then
    if [[ $FILE =~ .*\.be\..* ]]; then
      FILE=""
    else
      if [[ $FILE =~ .*\.le\..* ]]; then
        FILE=${FILE//\.le/}
      fi
    fi
  fi
  echo "$FILE"
}

# argument 1: benchmark name
# argument 2: directory name
# result: name to add (empty if to be skipped)
FilterInputDirName() {
  BENCHNAME="$1"
  FILE="$2"
  if [ $BENCHNAME == wrf ]; then
    if [[ $FILE =~ .*/[lb]e ]]; then
      FILE=""
    fi
  fi
  echo "$FILE"
}


STARTDIR="$PWD"
cd "$SPECINSTDIR"
# buggy spec script
set +u
. shrc
set -u

BENCHMARKS=`ls -d benchspec/CPU2006/*/ | grep -v 998`

rm -rf "$STARTDIR"/helperdata
mkdir "$STARTDIR"/helperdata

for BENCHDIR in $BENCHMARKS; do
  BENCHDIR=`basename $BENCHDIR`
  BENCHNAME=`echo $BENCHDIR | sed -e 's+[^\.]*\.++'`
  DATADIR="benchspec/CPU2006/$BENCHDIR/data"
  HELPERBASEDIR="$STARTDIR"/helperdata/$BENCHDIR
  # collect input files for all benchmark sizes
  BASEINPUTFILES=
  BASEINPUTDIRS=
  if [ -d "$DATADIR/all/input" ]; then
    for FILE in $DATADIR/all/input/*; do
      if [ -d "$FILE" ]; then
        # special cases
        FILE=`FilterInputDirName $BENCHNAME $FILE`
        if [ -z "$FILE" ]; then
          continue
        fi
        BASEINPUTDIRS="$BASEINPUTDIRS input/all/`basename $FILE`"
      else
        # special cases
        FILE=`FilterInputFileName $BENCHNAME $FILE`
        if [ -z "$FILE" ]; then
          continue
        fi
        BASEINPUTFILES="$BASEINPUTFILES input/all/`basename $FILE`"
      fi
    done
    # insert the RRTM_DATA file for wrf (it's in one of the removed
    # directories, added from there by spec2regression)
    if [ $BENCHNAME == wrf ]; then
      BASEINPUTFILES="$BASEINPUTFILES input/all/RRTM_DATA"
    fi
  fi
  for SIZE in test train ref; do
    echo "*** Processing $BENCHNAME - $SIZE"
    # create main regression configuration file
    mkdir -p "$HELPERBASEDIR"
    REGRESSIONCONF="$HELPERBASEDIR/../spec2006_${SIZE}.conf"
    if [ ! -f "$REGRESSIONCONF" ]; then
      echo "basedir=TEMPLATE_BASEDIR" > "$REGRESSIONCONF"
    fi
    # capture output of running/verifying the benchmark
    OUTPUT=`runspec -a run --fake -c $CONFIG --noreportable --loose --size=$SIZE $BENCHNAME| tr '\n' '&'`
    # extract the run commands from the lines like:
    #  ../run_base_test_i486gcc481bu223O2-nn.0000/specrand_base.i486gcc481bu223O2-nn 324342 24239 > rand.24239.out 2>> rand.24239.err
    COMMANDS=`echo $OUTPUT | sed -e 's/.*%% Fake commands from benchmark_run\(.*\)%% End of fake output from benchmark_run.*/\1/' | tr '&' '\n'|grep '^\.\.' | sed -e 's+[^ ]*/+./+' -e "s+_[^_]*\.${CONFIG}[^ ]*++"`
    # extract the output files from the lines like (get last word and remove '.cmp'):
    #   specperl /home/jmaebe/diablo/spec2006inst/bin/specdiff -m -l 10  --floatcompare /home/jmaebe/diablo/spec2006inst/benchspec/CPU2006/999.specrand/data/test/output/rand.24239.out rand.24239.out > rand.24239.out.cmp
    OUTPUTFILES=`echo $OUTPUT | sed -e 's/.*%% Fake commands from compare_run\(.*\)End of fake output from compare_run.*/\1/' | tr '&' '\n'|grep 'specdiff' | sed -e 's+.* ++' -e 's+\.cmp$++' | tr '\n' ' '`

    OUTPUTCOMPARECOMMANDS=`echo $OUTPUT | sed -e 's/.*%% Fake commands from compare_run\(.*\)End of fake output from compare_run.*/\1/' | tr '&' '\n' | grep 'specdiff' | tr '\n' '&'`
    OUTPUTCOMPARECOMMANDS=`echo $OUTPUTCOMPARECOMMANDS | sed -e 's+/[^&]*specdiff+\$spec_install_dir/bin/specdiff+g'`
    OUTPUTCOMPARECOMMANDS=`echo $OUTPUTCOMPARECOMMANDS | sed -e 's@\s/\S*/output/\(\S*\)@ $refdir/\1@g'`
    OUTPUTCOMPARECOMMANDS=`echo $OUTPUTCOMPARECOMMANDS | sed -e 's@\s\(\S*\) > \(\S*\)@ $testdir/\1 | egrep -v "^specdiff run completed$" > $testdir/\2@g'`
    OUTPUTCOMPARECOMMANDS=`echo $OUTPUTCOMPARECOMMANDS | tr '&' '\n'`

    # collect the input files
    INPUTDIRS="$BASEINPUTDIRS"
    INPUTFILES="$BASEINPUTFILES"

    if [ -d "$DATADIR/$SIZE/input" ]; then
      for FILE in $DATADIR/$SIZE/input/*; do
        if [ -d "$FILE" ]; then
          # special cases
          FILE=`FilterInputDirName $BENCHNAME $FILE`
          if [ -z "$FILE" ]; then
            continue
          fi
          INPUTDIRS="$INPUTDIRS input/$SIZE/`basename $FILE`"
        else
          # special cases
          FILE=`FilterInputFileName $BENCHNAME $FILE`
          if [ -z "$FILE" ]; then
            continue
          fi
          INPUTFILES="$INPUTFILES input/$SIZE/`basename $FILE`"
        fi
        # insert the ctlfile for sphinx (it's generated by spec2regression)
        if [ $BENCHNAME == sphinx3 ]; then
          INPUTFILES="$INPUTFILES input/$SIZE/ctlfile"
        fi
      done
    fi

    (
      echo '#!/bin/bash'
      echo "refdir=\$1"
      echo "testdir=\$2"
      echo "spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY"
      echo "cd \$spec_install_dir"
      echo "source ./shrc"
      echo "cd - > /dev/null"
      echo "$OUTPUTCOMPARECOMMANDS"
      echo "exitcode=0"
      echo "for i in $OUTPUTFILES; do"
      echo "  if [[ ! -f \$testdir/\$i ]]; then"
      echo "    echo \"Output file \$i does not exist\""
      echo "    exitcode=1"
      echo "  elif [[ -s \$testdir/\$i.cmp ]]; then"
      echo "    echo \"Output file \$i differs\""
      echo "    exitcode=1"
      echo "  fi"
      echo "done"
      echo "exit \$exitcode"
      echo ""
    ) > "$HELPERBASEDIR"/compare_${SIZE}.sh

    # for timing
    INPUTFILES="$INPUTFILES do_runme_$SIZE.sh"
#    echo "  dir: $BENCHDIR"
#    echo "  inputfiles: $INPUTFILES"
#    echo "  inputdirs: $INPUTDIRS"
#    echo "  outputfiles: $OUTPUTFILES"
#    echo "  run commands: $COMMANDS"
    # create runme script template
    echo '#!/bin/bash' > "$HELPERBASEDIR"/runme_${SIZE}.sh.org
    echo "$COMMANDS" >> "$HELPERBASEDIR"/runme_${SIZE}.sh.org
    # create regression configuration for this test
    (
      echo inputfiles="$INPUTFILES"
      if [ ! -z "$INPUTDIRS" ]; then
        echo inputdirs="$INPUTDIRS"
      fi
      echo outputfiles="$OUTPUTFILES"
      echo runscript="runme_${SIZE}.sh"
      echo referencedir=reference/${SIZE}/
      echo comparescript="compare_${SIZE}.sh"
      echo inputfilesarchive="input_$SIZE.tar.bz2"
      echo inputfilesarchivescript="tar_input_$SIZE.sh"
      echo pbs_run_remote="pbs_$SIZE.sh"
    ) > "$HELPERBASEDIR/regression_${SIZE}".conf

    BENCHNAME_CLEAN=$(
      case $BENCHNAME in
        sphinx3)
          echo "sphinx_livepretend"
          ;;
        xalancbmk)
          echo "Xalan"
          ;;
        *)
          echo $BENCHNAME
      esac
    )

    # add entry to the main regression configuration file
    (
      echo ""
      echo $BENCHNAME_CLEAN
      echo $BENCHDIR
      echo $BENCHDIR
      echo regression_${SIZE}.conf
    ) >> "$REGRESSIONCONF"

    # script to create tarball for inputs
    (
      echo "#!/usr/bin/env bash"
      echo "cd \`dirname \$0\`"
      echo outfile="input_${SIZE}.tar.bz2"
      echo "if [ -e \$outfile ]; then"
      echo "  exit 0"
      echo "fi"
      echo inputfiles=\""$INPUTFILES"\"
      echo inputdirs=\""$INPUTDIRS"\"
      echo "tar cjf \$outfile --transform=\"s:^input/\(all\|$SIZE\)/::\" \$inputfiles \$inputdirs"
    ) > "$HELPERBASEDIR"/tar_input_${SIZE}.sh

    # PBS job file for this benchmark
    DBACKSLASH="\\\\\\"
    PBS_FILE="$HELPERBASEDIR"/pbs_${SIZE}.sh

    # script header
    (
      echo "#!/usr/bin/env bash"
      echo "sleep_time=2"
      echo "jobid=\`("
    ) > $PBS_FILE

    # inline PBS file
    (
      echo "  echo \"#!/usr/bin/env bash\""
      echo "  echo \"#PBS -N Regression_$BENCHNAME\""
      echo "  echo \"#PBS -l nodes=1:VAR_NODE_PROPERTIES\""
      echo "  echo \"#PBS -u pbs\""
      echo "  echo \"d=$DBACKSLASH\$HOME/$DBACKSLASH\$PBS_JOBID\""
      echo "  echo \"function stagein()\""
      echo "  echo \"{\""
      echo "  echo \"  scp $DBACKSLASH\$PBS_O_HOST:$DBACKSLASH\$PBS_O_WORKDIR/input_$SIZE.tar.bz2 .\""
      echo "  echo \"  scp $DBACKSLASH\$PBS_O_HOST:$DBACKSLASH\$PBS_O_WORKDIR/$BENCHNAME_CLEAN .\""
      echo "  echo \"}\""
      echo "  echo \"function stageout()\""
      echo "  echo \"{\""
    ) >> $PBS_FILE

    # output files
    for OUTPUT in $OUTPUTFILES; do
      echo "  echo \"  scp $OUTPUT $DBACKSLASH\$PBS_O_HOST:$DBACKSLASH\$PBS_O_WORKDIR/\"" >> $PBS_FILE
    done

    (
      echo "  echo \"}\""
      echo "  echo \"function run()\""
      echo "  echo \"{\""
      echo "  echo \"  tar xf input_$SIZE.tar.bz2\""
      echo "  echo \"  ./do_runme_$SIZE.sh\""
      echo "  echo \"}\""
      echo "  echo \"olddir=$DBACKSLASH\$PWD\""
      echo "  echo \"mkdir -p $DBACKSLASH\$d && cd $DBACKSLASH\$d\""
      echo "  echo \"echo host: $DBACKSLASH\`uname -n$DBACKSLASH\`\""
      echo "  echo \"stagein\""
      echo "  echo \"run\""
      echo "  echo \"stageout\""
      echo "  echo \"cd $DBACKSLASH\$olddir\""
      echo "  echo \"rm -r $DBACKSLASH\$d\""
    ) >> $PBS_FILE

    # outline script
    (
      echo ") | qsub\`"
      echo "status=\`qstat | grep \$jobid\`"
      echo "while [ -n \"\$status\" ]; do"
      echo "  sleep \$sleep_time"
      echo "  status=\`qstat | grep \$jobid\`"
      echo "done"
    ) >> $PBS_FILE
  done
done
