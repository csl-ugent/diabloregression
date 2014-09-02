#!/usr/bin/python
import sys
import os
import shutil
import filecmp
import time
from os.path import join, expanduser
from getopt import *

###################################################################
# {{{ default values

# configurable by command-line arguments
diablo_prog = "diablo"
diablo_dir = "diablo"
diablo_opts = ""
config_file = "regression.conf"
test_dir = "regressiontestdir"
post_run = ""
do_validation = 1
binsearch_max = 0
binsearch_logs = 0
generate_profile = 0
generate_profile_obj = ""
use_profile = 0
profile_dir = ""
report = 0
report_file = "report.html"
do_time = 0
start_dir = os.getcwd()
do_fresh_checkout = 0
makefile = "Makefile.ppc64"
keep_optimized = 0
keep_suffix = ".diablo"
exec_previous = 0

# configurable in the general config file
basedir = ""
altdir = ""
# }}}

###################################################################
# {{{ augment path specification with base directory
def augment_path(pathspec,basedir):
    """augment path specification with base or alternate directory"""
    elems = [elem.strip() for elem in pathspec.split(":")]
    augmented = []
    for elem in elems:
        if elem[0] == "/":
            augmented.append(elem)
        elif elem[0] == "@":
            augmented.append(join(altdir,elem[1:]))
        else:
            augmented.append(join(basedir,elem))
    return ":".join(augmented)
# }}}

###################################################################
# {{{ augment file name with altdir if necessary
def altfile(fname):
    """augment file name with altdir if necessary"""
    if fname[0] == "@":
        return join(altdir,fname[1:])
    return fname
# }}}

###################################################################
# {{{ resolve filename: either from object path or from altdir
def resolve(fname,prog):
    objdir = prog["objpath"].split(":")[0]
    fname = altfile(fname)
    if fname[0] != "/":
        fname = join(objdir, fname)
    return fname
# }}}

###################################################################
# {{{ parse the general config file
def parseconfig(cfgfile):
    """parse the general configuration file"""
    global basedir, altdir

    try:
        f = file(cfgfile,"r")
    except IOError:
        print "Could not open file", cfgfile, "for reading"
        sys.exit(1)

    lines = f.readlines()
    f.close()

    # the first lines of the file may specify some tunables in key=value pairs
    tunables = {}
    while lines[0].find("=") != -1:
        key,value = lines[0].split("=",1)
        tunables[key.strip()] = value.strip()
        lines = lines[1:]
    if tunables.has_key("basedir"): basedir = tunables["basedir"]
    if tunables.has_key("altdir"): altdir = tunables["altdir"]

    # the rest of the file contains benchmark descriptions
    tests = []
    i = 0
    while i < len(lines):
        current = lines[i].strip()
        if current == "":
            i = i+1
            continue

        executable = current
        objpath = lines[i+1].strip()
        libpath = lines[i+2].strip()
        configfile = lines[i+3].strip()

        dict = {}
        dict["executable"] = executable
        dict["objpath"] = augment_path(objpath,basedir)
        dict["libpath"] = augment_path(libpath,basedir)
        dict["configfile"] = altfile(configfile)
        tests.append(dict)
        i = i+4

    return tests

# }}}

###################################################################
# {{{ parse the test-specific config file
def parsetestconf(cfgfile,prog):
    """parse the test-specific configuration file"""
    try:
        f = file(cfgfile,"r")
    except IOError:
        print "Could not open config file", cfgfile, "for reading"
        return None

    params = {}
    for line in f:
        line = line.strip()
        if line == "": continue
        key,val = line.split("=")
        params[key.strip()] = val.strip()

    if not params.has_key("savedir"):
        params["savedir"] = prog["objpath"].split(":")[0]
    params["savedir"] = augment_path(params["savedir"],basedir)

    return params

# }}}

###################################################################
# {{{ clear the directory in which b.out is run
def clear_testdir():
    """clear the directory in which b.out is run"""

    currdir = os.getcwd()
    os.chdir(test_dir)
    for entry in os.listdir("."):
        try:
            os.remove(entry)
        except OSError:
            # oops, it was a directory
            shutil.rmtree(entry)
    os.chdir(currdir)
# }}}

###################################################################
# {{{ interpret the post-run command
def post_run_interpret(cmd,prog,conf):
    """interpret the post-run command"""
    processed = ""
    i = 0
    while i < len(cmd):
        if cmd[i] != "@":
            processed += cmd[i]
            i += 1
            continue

        next = cmd[i+1]
        if next == "N":
            processed += prog["executable"]
        elif next == "D":
            processed += prog["objpath"]
        elif next == "S":
            processed += conf["savedir"]
        else:
            processed += next

        i += 2

    return processed

# }}}

###################################################################
# {{{ run b.out and diff the output files
def test_program(prog,conf):
    """run b.out and diff the output files"""

    def leaf(dirname):
        if dirname[-1] == "/":
            dirname = dirname[:-1]
        return os.path.basename(dirname)

    os.chdir(test_dir)
    try:
        # copy the compacted executable into the test directory
        shutil.copy("b.out",prog["executable"])
        os.chmod(prog["executable"],0755)

        # input files
        infiles = conf["inputfiles"].split()
        for inf in [resolve(x,prog) for x in infiles]:
            shutil.copy(inf,test_dir)
        shutil.copy(resolve(conf["runscript"],prog),test_dir)
        if "inputdirs" in conf.keys():
            # copy the complete directories mentioned here
            indirs = conf["inputdirs"].split()
            for ind in indirs:
                shutil.copytree(resolve(ind,prog), join(test_dir,leaf(ind)))

        # execute the run script
        scriptcmdline = join(test_dir,os.path.basename(conf["runscript"]))
        os.spawnl(os.P_WAIT,"/bin/sh","sh",scriptcmdline,str(do_time),str(generate_profile))

        # compare the output files
        refdir = resolve(conf["referencedir"], prog)
        outfiles = conf["outputfiles"].split()
        test_failed = 0
        for outf in outfiles:
            result = filecmp.cmp(join(test_dir,outf), join(refdir,outf), shallow = 0)
            if not result:
                print "file", outf, "differs"
                test_failed = 1
        
        # if there is a post-run command, execute it
        if post_run != "":
            os.system(post_run_interpret(post_run,prog,conf))

    except Exception, e:
        print "Exception", e
        test_failed = 1

    return not test_failed

# }}}

###################################################################
# {{{ find the line beginning with GAIN in the given file and print it

def grep_for_gain(fname):
    """open a file and print all lines starting with GAIN"""
    
    gains = []
    f = file(fname)
    foundgain = 0
    for line in f:
        line = line.strip()
        if line[:4] == "GAIN":
            if line[-1] == "\n": line = line[:-1]
            print line
            foundgain = 1
            gains.append(float(line[5:line.find("%")]))

    if not foundgain:
        print "gain not reported"

    return gains

# }}}


###################################################################
# {{{ read the time used to execute the benchmark
def read_bench_times(fname):
    benchtimes = []

    try:
        f = file(fname,"r")
        for line in f:
          benchtimes.append(float(line))
    except IOError:
        print "Could not open ",fname," for reading"
        return [0,0]
    print "Benchmark system time: ", benchtimes[0]
    print "Benchmark user   time: ", benchtimes[1]
    return benchtimes
# }}}

###################################################################
# {{{ find the line beginning with TIME in the given file and print it

def grep_for_times(fname):
    """open a file and print all lines starting with GAIN"""
    
    times = []
    f = file(fname)
    foundtime = 0
    for line in f:
        line = line.strip()
        if line[:4] == "TIME":
            if line[-1] == "\n": line = line[:-1]
            print line
            foundtime = 1
            times.append(float(line[5:line.find("s")]))

    if not foundtime:
        print "time not reported"

    return times

# }}}

###################################################################
# {{{ print program usage info and exit
def PrintUsage():
    """print usage info and exit"""
    print "Usage:"
    print sys.argv[0],"""
    [-c|--config <config-file>]           (regression.conf-style file to use) (default: regression.conf)
    [-p|--diablo-executable <executable>] (name of diablo executable to use) (default: diablo)
    [-d|--diablo-dir <diablo-dir>]        (directory in which to search for the diablo executable) (default: ./diablo/)
    [-o|--diablo-opts <diablo-options>]   (options to pass to diablo) (default: none)
    [-x|--post-exec <post-run command>]   (command to run after the diablo processing and testing of a program is finished) (default: none)
    [-b|--binary-search <max count>]      (look for debugcounter value where test fails; <max count>+1 should be known to fail)
    [-B|--binary-search-with-logs <mc>]   (idem as -b, but rerun Diablo on last bad/good with -v -v -v)
    [-g|--generate-profile <obj> ]        (profile the rewritten binary, link <obj> for support via diablo -SP parameter) (default: don't profile)
    [-P|--use-profile ]                   (rewrite the binary using an existing profile generated via the -p option) (default: don't use profiling information)
    [--profile-directory <dir> ]          (with -p, put, and with -P, get, the profile information under <dir>) (default: nothing)
    [-r|--report]                         (generate report.html with test results) (default: disabled)
    [-R|--report-file <file>]             (generate <file> with test results in html) (default: disabled)
    [-i|--time]                           (time the execution of rewritten binaries)
    [-m|--measure-only]                   (only process tests with diablo, do not try to run them) (default: do run tests)
    [-f|--fresh-checkout <makefile>]      (check out and build diablo using makefile instead of using the one specified via -d/-p) (default: disabled)
    [-k|--keep-optimized]                 (do not delete processed tests after testing) (default: delete them)
    [-K|--keep-with-suffix <suffix>]      (keep processed binaries after testing with suffix) (default: disabled)
    [-t|--temp-test-dir]                  (create new temporary directory to perform tests in) (default: disabled)
    [-T|--test-dir <dir>]                 (perform all tests in <dir>; overrides -t, default is regressiontestdir; note: EXISTING DIRECTORY CONTENTS WILL BE ERASED) 
    [-X|--exec-previous <suffix>]         (don't rerun diablo, but use previously generated executables saved via -K option; requires "savedir" option in config file) (default: disabled)
    [<bench>|^<bench>]...                 (bench: include benchmark; ^bench: exclude benchmark) (default: all benchmarks in config file)"""
    sys.exit(-1)

# }}}

###################################################################
# {{{ parse the command line arguments 
def parse_args():
    """parse the command line arguments"""
    global config_file, diablo_dir, diablo_opts, diablo_prog, do_validation, post_run, binsearch_max, binsearch_logs, generate_profile, generate_profile_obj, use_profile, profile_dir, report, report_file, do_time, do_fresh_checkout, makefile, keep_optimized, keep_suffix, test_dir, exec_previous

    short_opts = "c:d:o:p:x:b:B:g:PR:irmf:kK:tT:X:"
    long_opts = ["config=","diablo-dir=","diablo-opts=","measure-only","diablo-executable=","post-exec=","binary-search=","binary-search-with-log","generate-profile=","use-profile","profile-directory=","report","report-file=","time","fresh-checkout=","keep-optimized","keep-with-suffix=","temp-test-dir","test-dir=","exec-previous="]

    try:
        opts, args = getopt(sys.argv[1:],short_opts,long_opts);
    except GetoptError:
        PrintUsage()

    for opt, arg in opts:
        if opt == "-c" or opt == "--config":
            config_file = arg
        elif opt == "-d" or opt == "--diablo-dir":
            diablo_dir = arg
        elif opt == "-o" or opt == "--diablo-opts":
            diablo_opts = arg
        elif opt == "-m" or opt == "--measure-only":
            do_validation = 0
        elif opt == "-p" or opt == "--diablo-executable":
            diablo_prog = arg
        elif opt == "-x" or opt == "--post-exec":
            post_run = arg
        elif opt == "-b" or opt == "--binary-search":
            binsearch_max = int(arg)
        elif opt == "-B" or opt == "--binary-search-with-log":
            binsearch_max = int(arg)
            binsearch_logs = 1
        elif opt == "-g" or opt == "--generate-profile":
            generate_profile = 1
            generate_profile_obj = arg
        elif opt == "-P" or opt == "--use-profile":
            use_profile = 1
        elif opt == "--profile-directory":
            profile_dir = arg
        elif opt == "-r" or opt == "--report":
            report = 1
        elif opt == "-R" or opt == "--report-file":
            report = 1
            report_file = arg
        elif opt == "-i" or opt == "--time":
            do_time = 1
        elif opt == "-f" or opt == "--fresh-checkout":
            do_fresh_checkout = 1
            makefile = arg
        elif opt == "-k" or opt == "--keep-optimized":
            keep_optimized = 1
        elif opt == "-K" or opt == "--keep-with-suffix":
            keep_optimized = 1
            keep_suffix = arg
        elif opt == "-X" or opt == "--exec-previous":
            exec_previous = 1
            keep_suffix = arg
        elif opt == "-T" or opt == "--test-dir":
            test_dir = arg
        elif opt == "-t" or opt == "--temp-test-dir":
            test_dir = None
            while test_dir is None:
                test_dir = os.tmpnam()
                try:
                    os.makedirs(test_dir)
                except error:
                    test_dir = None
        else:
            print "unknown option", opt
            PrintUsage()

#    print "args:" , args
    all_benches = parseconfig(config_file)
    included = []
    excluded = []
    for arg in args:
        if arg[0] == "^":
            excluded.append(arg[1:])
        else:
            included.append(arg)

#    print "included:", included
#    print "excluded:", excluded

    exec_benches = []
    if included != []:
        for bench in all_benches:
            if bench["executable"] in included:
                exec_benches.append(bench)
    else:
        for bench in all_benches:
            if not (bench["executable"] in excluded):
                exec_benches.append(bench)

    return exec_benches
    
# }}}


###################################################################
# {{{ check whether a program is in the path and executable,
#     from http://stackoverflow.com/questions/377017/test-if-executable-exists-in-python/377028#377028
def which(program):
    import os
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

###################################################################
# {{{ check completeness/consistency of profiling options

def check_profile_options(tests):
    if generate_profile or use_profile:
        if (profile_dir == "") or not os.path.isdir(profile_dir):
            print "Invalid or unspecified profile base directory, specify using --profile-dir"
            sys.exit(-1)
    if generate_profile and use_profile:
        print "Cannot both use and generate profiling information at the same time"
        sys.exit(-1)
    if generate_profile:
        if do_time:
            print "Cannot both generate profile information and time the benchmark execution"
            sys.exit(-1)
        if not os.path.isfile(generate_profile_obj):
            print "Cannot find object file '",generate_profile_obj,"' to link in for profiling"
            sys.exit(-1)
        if which("merge_profiles.py") == None:
            print "Cannot find merge_profiles.py in the path or it is not executable"
            sys.exit(-1)
        if which("binary_profile_to_plaintext.py") == None:
            print "Cannot find binary_profile_to_plaintext.py in the path or it is not executable"
            sys.exit(-1)
    if use_profile:
        for test in tests:
          if not os.path.isfile(join(profile_dir,test["executable"],"bbprofile")):
            print "Cannot find profile ",join(profile_dir,test["executable"],"bbprofile")
            sys.exit(-1)
# }}}



###################################################################
# {{{ make a directory if it doesn't exit yet
def mkdir(path):
        if not os.path.exists(path):
                os.makedirs(path)
# }}}

###################################################################
# {{{ construct command line and run diablo
def run_diablo(test,logfile=None,extra_opts=""):
    """run diablo and return the exit code"""

    if logfile is None:
        logfile = "diablo_log." + test["executable"]
    os.chdir(test_dir)
    clear_testdir()
    commandline = join(diablo_dir,diablo_prog)
    commandline = commandline + " -O "+test["objpath"]+" -L "+test["libpath"]
    commandline = commandline + " " + diablo_opts + " " + extra_opts
    commandline = commandline + " " + test["executable"]
    if generate_profile:
      commandline = commandline + " -SP " + generate_profile_obj
    if use_profile:
      commandline = commandline + " --rawprofiles off -pb " + join(profile_dir,test["executable"],"bbprofile")
    commandline = commandline + " >" + logfile + " 2>/dev/null"
    print "Executing: ", commandline
    exitcode = os.system(commandline)
    return exitcode
# }}}

###################################################################
# {{{ do binary search for an error using the debugcounter
def BinarySearch(test,maxcount):
    """perform binary search on the test using the debug counter"""
    config = parsetestconf(resolve(test["configfile"],test),test)
    os.chdir(test_dir)

    execlog = "diablo_log."+test["executable"]
    b_out = "b.out"
    final_list = b_out+".list"
    final_dir = join(diablo_dir,'debugresults');

    def save_with_suffix(suffix):
        try:
            os.makedirs(final_dir)
        except OSError:
            pass
        try:
            shutil.copyfile(execlog,join(final_dir,execlog+suffix))
        except IOError:
            pass
        try:
            shutil.copyfile(b_out,join(final_dir,b_out+suffix))
        except IOError:
            pass
        try:
            shutil.copyfile(final_list,join(final_dir,final_list+suffix))
        except IOError:
            pass

    correct=0
    faulty=maxcount+1

    while faulty - correct > 1:
        lookat=(faulty+correct)/2
        print "looking at", lookat
        exitcode = run_diablo(test,execlog,"-c "+repr(lookat))
        if exitcode:
            good_run = 0
            print "diablo failed with exit code", exitcode
        else:
            good_run = test_program(test,config)

        if good_run:
            correct = lookat
            save_with_suffix(".good")
        else: 
            faulty = lookat
            save_with_suffix(".bad")

    if (binsearch_logs == 1) and (faulty <> correct):
      print "Generating verbose logs"
      run_diablo(test,execlog,"-v -v -v -c "+repr(correct))
      save_with_suffix(".good")
      run_diablo(test,execlog,"-v -v -v -c "+repr(faulty))
      save_with_suffix(".bad")

    print "last correct:", correct
    print "first faulty:", faulty
    print "Logs and binaries are in "+final_dir
            
# }}}

###################################################################
# {{{ write a report of this run to a html file
def WriteReport(tests):
    """write a report of the regression run to a html file"""

    os.chdir(start_dir)
    f = file(report_file,"w")
    f.write("""
<html>
<head>
<title>Diablo regression test results</title>
</head>
<body>
Regression run on %s with options <code>%s</code><br>
<table>
<tr><th>program</th><th>diablo's exit code</th><th>valid b.out</th><th>code size gain</th><th>total size gain</th><th>diablo clock wall time</th><th>diablo cpu time</th><th>program sys time</th><program cpu time</th></tr>
""" % (time.asctime(time.localtime())," ".join(sys.argv[1:])))

    csavg = 0.0
    totavg = 0.0
    nvalids = 0
    for test in tests:
        exitcode = test["exitcode"]
        if len(test["gains"]) >= 1:
            csgain = test["gains"][0]
            if len(test["gains"]) > 1:
                totgain = test["gains"][-1]
            else:
                totgain = 0.0;
        else:
          csgain = 0.0;
          totgain = 0.0;
        if len(test["times"]) >= 1:
            walltime = test["times"][0]
            if len(test["times"]) > 1:
                cputime = test["times"][-1]
            else:
                cputime = 0.0;
        else:
          cputime = 0.0;
          walltime = 0.0;
        if len(test["benchtimes"]) >= 1:
            benchsystime = test["benchtimes"][0]
            benchcputime = test["benchtimes"][1]
        else:
            benchsystime = 0.0
            benchcputime = 0.0
        valid = test["validation"]
        if valid:
            nvalids = nvalids + 1
            csavg = csavg + csgain
            totavg = totavg + totgain

        if exitcode == 0 and valid:
            f.write("<tr>");
        else:
            f.write("<tr bgcolor=#ffaaaa>")
        f.write("<td>%s</td>" % (test["executable"]))
        f.write("<td>%d</td>" % (exitcode))
        f.write("<td>%s</td>" % ((do_validation and ((valid and "OK") or "FAILED")) or "N/A"))
        f.write("<td>%f%%</td>" % (csgain))
        f.write("<td>%f%%</td>" % (totgain))
        f.write("<td>%4.0fs</td>" % (walltime))
        f.write("<td>%4.0fs</td>" % (cputime))
        f.write("<td>%4.2fs</td>" % (benchsystime))
        f.write("<td>%4.2fs</td>" % (benchcputime))
        f.write("</tr>\n")
        
    if nvalids > 0:
        csavg = csavg / nvalids
        totavg = totavg / nvalids
    else:
        csavg = 0.0
        totavg = 0.0

    f.write("""
</table>
<br>
Average gain in code section: %f%%<br>
Average gain in total size: %f%%<br>
</body>
</html>
""" % (csavg,totavg))

    f.close()

# }}}

###################################################################
# {{{ set up temporary directories and do a fresh checkout
def SetupForFreshCheckout():
    """set up temporary directories and do a fresh checkout"""
    global diablo_dir, test_dir

    dirpref = None
    while dirpref is None:
        dirpref = os.tmpnam()
        try:
            os.makedirs(dirpref)
        except error:
            dirpref = None

    os.makedirs(join(dirpref,"test"))
    os.chdir(dirpref)
    #exitcode = os.system("cvs checkout diablo")
    exitcode = os.system("svn co --username anon --password anon https://acavus.elis.ugent.be/svn/diablo/trunk diablo")
    if exitcode:
        print "checkout failed"
        sys.exit(-1)
    os.chdir("diablo")
    exitcode = os.system("make -f " + makefile)
    if exitcode:
        print "compile failed"
        sys.exit(-1)

    diablo_dir = join(dirpref,"diablo")
    test_dir = join(dirpref, "test")
    os.chdir(start_dir)

# }}}

###################################################################
# {{{ run previously saved programs
def ExecutePrevious(test,config):
    """run previously generated optimized versions"""
    clear_testdir()
    try:
        shutil.copy(join(config["savedir"],test["executable"]+keep_suffix),join(test_dir,"b.out"))
    except OSError:
        print "file", test["executable"]+keep_suffix, "does not exist"
        return 0
    return test_program(test,config)
# }}}

###################################################################
# {{{ main program

def main():
    print "regression test for diablo..."

    tests = parse_args()
    check_profile_options(tests)
    #print "config file:", config_file
    #print "diablo dir :", diablo_dir
    #print "diablo opts:", diablo_opts
    #print "diablo prog:", diablo_prog

    if do_fresh_checkout:
        SetupForFreshCheckout()

    if binsearch_max > 0:
        BinarySearch(tests[0],binsearch_max)
    else:

        for test in tests:
            print "testing", test["executable"]
            config = parsetestconf(resolve(test["configfile"],test),test)
            
            if config is None:
                print "invalid config file"
                test["exitcode"] = 6666666
                test["validation"] = 1
                continue

            if not exec_previous:
                logfile = "diablo_log." + test["executable"]
                test["exitcode"] = run_diablo(test,logfile)
                try:
                    shutil.copy(join(test_dir,logfile),config["savedir"])
                except IOError:
                    print "cannot copy %s to %s" % (logfile,config["savedir"])

                if test["exitcode"]:
                    print "diablo failed execution: exited with code", test["exitcode"]
                    test["gains"] = [0,0]
                    test["times"] = [0,0]
                    test["benchtimes"] = [0,0]
                    test["validation"] = 0
                else:
                    test["gains"] = grep_for_gain(join(test_dir,logfile))
                    test["times"] = grep_for_times(join(test_dir,logfile))

                    if do_validation:
                        test["validation"] = test_program(test,config)
                        if test["validation"]:
                            print "OK"
                            if do_time:
                              test["benchtimes"] = read_bench_times(join(test_dir,"benchtime.out"))
                            else:
                              test["benchtimes"] = [0,0]

                            if generate_profile:
                                if not os.path.isfile(join(test_dir,"mergedbinprofile")):
                                    print "Cannot find generated profile at ", join(test_dir,"mergedbinprofile")
                                else:
                                   try:
                                       mkdir(join(profile_dir, test["executable"])) 
                                       os.system(which("binary_profile_to_plaintext.py")+" "+join(test_dir,"mergedbinprofile") + " > " + join(test_dir,"mergedplaintextprofile"))
                                       os.system(which("merge_profiles.py")+" "+join(test_dir,"mergedplaintextprofile")+" > "+join(profile_dir,test["executable"],"bbprofile"))
                                   except Exception, e:
                                      print "Exception", e

                        else:
                            print "FAILED"
                            test["benchtimes"] = [0,0]
                    else:
                        test["benchtimes"] = [0,0]
                        test["validation"] = 1

                    if keep_optimized:
                        shutil.copy(join(test_dir,"b.out"),join(config["savedir"],test["executable"]+keep_suffix))
        
            else:
                test["exitcode"] = 0
                test["gains"] = [0,0]
                test["times"] = [0,0]
                test["benchtimes"] = [0,0]
                test["validation"] = ExecutePrevious(test,config)
                if test["validation"]:
                    print "OK"
                else:
                    print "FAILED"

        diablo_failed = []
        validation_failed = []
        for test in tests:
            if test["exitcode"]: diablo_failed += [ test["executable"] ]
            if not test["validation"]: validation_failed += [ test["executable"] ]
        if len(diablo_failed):
            print "Failed to execute Diablo for:", " ".join(diablo_failed)
        if len(validation_failed):
            print "Validation failed for:", " ".join(validation_failed)

        if report:
            WriteReport(tests)

    if do_fresh_checkout:
        # clean up temporary directories
        shutil.rmtree(diablo_dir[:-6])

# }}}
            
if __name__ == "__main__":
    main()

# vim: set shiftwidth=4 tabstop=4 expandtab autoindent foldmethod=marker:
