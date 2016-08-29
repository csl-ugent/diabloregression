#!/usr/bin/env bash
sleep_time=2
jobid=`(
  echo "#!/usr/bin/env bash"
  echo "#PBS -N Regression_gobmk"
  echo "#PBS -l nodes=1:armv7"
  echo "#PBS -u pbs"
  echo "d=\\\$HOME/\\\$PBS_JOBID"
  echo "function stagein()"
  echo "{"
  echo "  scp \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/input_test.tar.bz2 ."
  echo "  scp \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/gobmk ."
  echo "}"
  echo "function stageout()"
  echo "{"
  echo "  scp capture.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp connect.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp connect_rot.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp connection.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp connection_rot.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp cutstone.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp dniwog.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "}"
  echo "function run()"
  echo "{"
  echo "  tar xf input_test.tar.bz2"
  echo "  ./do_runme_test.sh"
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
