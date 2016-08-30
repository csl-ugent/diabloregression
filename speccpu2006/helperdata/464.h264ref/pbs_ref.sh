#!/usr/bin/env bash
sleep_time=2
jobid=`(
  echo "#!/usr/bin/env bash"
  echo "#PBS -N Regression_h264ref"
  echo "#PBS -l nodes=1:VAR_PBS_PROPERTIES"
  echo "#PBS -u pbs"
  echo "d=\\\$HOME/\\\$PBS_JOBID"
  echo "function stagein()"
  echo "{"
  echo "  scp \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/input_ref.tar.bz2 ."
  echo "  scp \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/h264ref ."
  echo "}"
  echo "function stageout()"
  echo "{"
  echo "  scp foreman_ref_baseline_encodelog.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp foreman_ref_baseline_leakybucketparam.cfg \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp foreman_ref_main_encodelog.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp foreman_ref_main_leakybucketparam.cfg \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp sss_main_encodelog.out \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
  echo "  scp sss_main_leakybucketparam.cfg \\\$PBS_O_HOST:\\\$PBS_O_WORKDIR/"
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