#!/usr/bin/env bash
sleep_time=2
jobid=`(
  echo "#!/usr/bin/env bash"
  echo "#PBS -N Regression_gcc"
  echo "#PBS -l nodes=1:VAR_PBS_PROPERTIES"
  echo "#PBS -u pbs"
  echo "d=\\\$HOME/\\\$PBS_JOBID"
  echo "function stagein()"
  echo "{"
  echo "  scp \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/input_ref.tar.bz2 ."
  echo "  scp \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/gcc ."
  echo "}"
  echo "function stageout()"
  echo "{"
  echo "  scp 166.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp 200.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp c-typeck.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp cp-decl.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp expr.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp expr2.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp g23.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp s04.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp scilab.s \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "}"
  echo "function run()"
  echo "{"
  echo "  tar xf input_ref.tar.bz2"
  echo "  ./do_runme_ref.sh"
  echo "}"
  echo "olddir=\\\$PWD"
  echo "mkdir -p \\\$d && cd \\\$d"
  echo "echo host: \\\`uname -n\\\`"
  echo "stagein"
  echo "run"
  echo "stageout"
  echo "cd \\\$olddir"
  echo "rm -r \\\$d"
) | qsub`
status=`qstat | grep $jobid`
while [ -n "$status" ]; do
  sleep $sleep_time
  status=`qstat | grep $jobid`
done
