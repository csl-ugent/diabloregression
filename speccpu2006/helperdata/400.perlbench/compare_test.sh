#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/append.out $testdir/append.out | egrep -v "^specdiff run completed$" > $testdir/append.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/args.out $testdir/args.out | egrep -v "^specdiff run completed$" > $testdir/args.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/arith.out $testdir/arith.out | egrep -v "^specdiff run completed$" > $testdir/arith.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/array.out $testdir/array.out | egrep -v "^specdiff run completed$" > $testdir/array.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/attrs.out $testdir/attrs.out | egrep -v "^specdiff run completed$" > $testdir/attrs.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/auto.out $testdir/auto.out | egrep -v "^specdiff run completed$" > $testdir/auto.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/base_cond.out $testdir/base_cond.out | egrep -v "^specdiff run completed$" > $testdir/base_cond.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/base_pat.out $testdir/base_pat.out | egrep -v "^specdiff run completed$" > $testdir/base_pat.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/base_term.out $testdir/base_term.out | egrep -v "^specdiff run completed$" > $testdir/base_term.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/bless.out $testdir/bless.out | egrep -v "^specdiff run completed$" > $testdir/bless.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/bop.out $testdir/bop.out | egrep -v "^specdiff run completed$" > $testdir/bop.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/bproto.out $testdir/bproto.out | egrep -v "^specdiff run completed$" > $testdir/bproto.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/chars.out $testdir/chars.out | egrep -v "^specdiff run completed$" > $testdir/chars.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/chop.out $testdir/chop.out | egrep -v "^specdiff run completed$" > $testdir/chop.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/cmdopt.out $testdir/cmdopt.out | egrep -v "^specdiff run completed$" > $testdir/cmdopt.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/cmp.out $testdir/cmp.out | egrep -v "^specdiff run completed$" > $testdir/cmp.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/comp_term.out $testdir/comp_term.out | egrep -v "^specdiff run completed$" > $testdir/comp_term.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/concat.out $testdir/concat.out | egrep -v "^specdiff run completed$" > $testdir/concat.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/context.out $testdir/context.out | egrep -v "^specdiff run completed$" > $testdir/context.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/decl.out $testdir/decl.out | egrep -v "^specdiff run completed$" > $testdir/decl.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/defins.out $testdir/defins.out | egrep -v "^specdiff run completed$" > $testdir/defins.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/delete.out $testdir/delete.out | egrep -v "^specdiff run completed$" > $testdir/delete.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/die.out $testdir/die.out | egrep -v "^specdiff run completed$" > $testdir/die.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/do.out $testdir/do.out | egrep -v "^specdiff run completed$" > $testdir/do.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/each.out $testdir/each.out | egrep -v "^specdiff run completed$" > $testdir/each.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/eval.out $testdir/eval.out | egrep -v "^specdiff run completed$" > $testdir/eval.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/exists_sub.out $testdir/exists_sub.out | egrep -v "^specdiff run completed$" > $testdir/exists_sub.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/exp.out $testdir/exp.out | egrep -v "^specdiff run completed$" > $testdir/exp.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/fh.out $testdir/fh.out | egrep -v "^specdiff run completed$" > $testdir/fh.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/grep.out $testdir/grep.out | egrep -v "^specdiff run completed$" > $testdir/grep.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/gv.out $testdir/gv.out | egrep -v "^specdiff run completed$" > $testdir/gv.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/hashwarn.out $testdir/hashwarn.out | egrep -v "^specdiff run completed$" > $testdir/hashwarn.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/if.out $testdir/if.out | egrep -v "^specdiff run completed$" > $testdir/if.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/inc.out $testdir/inc.out | egrep -v "^specdiff run completed$" > $testdir/inc.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/index.out $testdir/index.out | egrep -v "^specdiff run completed$" > $testdir/index.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/int.out $testdir/int.out | egrep -v "^specdiff run completed$" > $testdir/int.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/join.out $testdir/join.out | egrep -v "^specdiff run completed$" > $testdir/join.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/length.out $testdir/length.out | egrep -v "^specdiff run completed$" > $testdir/length.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/lex.out $testdir/lex.out | egrep -v "^specdiff run completed$" > $testdir/lex.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/list.out $testdir/list.out | egrep -v "^specdiff run completed$" > $testdir/list.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/loopctl.out $testdir/loopctl.out | egrep -v "^specdiff run completed$" > $testdir/loopctl.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/lop.out $testdir/lop.out | egrep -v "^specdiff run completed$" > $testdir/lop.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/makerand.out $testdir/makerand.out | egrep -v "^specdiff run completed$" > $testdir/makerand.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/method.out $testdir/method.out | egrep -v "^specdiff run completed$" > $testdir/method.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/my.out $testdir/my.out | egrep -v "^specdiff run completed$" > $testdir/my.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/nothr5005.out $testdir/nothr5005.out | egrep -v "^specdiff run completed$" > $testdir/nothr5005.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/oct.out $testdir/oct.out | egrep -v "^specdiff run completed$" > $testdir/oct.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/op_cond.out $testdir/op_cond.out | egrep -v "^specdiff run completed$" > $testdir/op_cond.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/op_pat.out $testdir/op_pat.out | egrep -v "^specdiff run completed$" > $testdir/op_pat.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/ord.out $testdir/ord.out | egrep -v "^specdiff run completed$" > $testdir/ord.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/override.out $testdir/override.out | egrep -v "^specdiff run completed$" > $testdir/override.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/pack.out $testdir/pack.out | egrep -v "^specdiff run completed$" > $testdir/pack.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/package.out $testdir/package.out | egrep -v "^specdiff run completed$" > $testdir/package.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/pos.out $testdir/pos.out | egrep -v "^specdiff run completed$" > $testdir/pos.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/push.out $testdir/push.out | egrep -v "^specdiff run completed$" > $testdir/push.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/quotemeta.out $testdir/quotemeta.out | egrep -v "^specdiff run completed$" > $testdir/quotemeta.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/range.out $testdir/range.out | egrep -v "^specdiff run completed$" > $testdir/range.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/recurse.out $testdir/recurse.out | egrep -v "^specdiff run completed$" > $testdir/recurse.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/redef.out $testdir/redef.out | egrep -v "^specdiff run completed$" > $testdir/redef.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/ref.out $testdir/ref.out | egrep -v "^specdiff run completed$" > $testdir/ref.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/regexp.out $testdir/regexp.out | egrep -v "^specdiff run completed$" > $testdir/regexp.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/regexp_noamp.out $testdir/regexp_noamp.out | egrep -v "^specdiff run completed$" > $testdir/regexp_noamp.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/regmesg.out $testdir/regmesg.out | egrep -v "^specdiff run completed$" > $testdir/regmesg.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/repeat.out $testdir/repeat.out | egrep -v "^specdiff run completed$" > $testdir/repeat.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/reverse.out $testdir/reverse.out | egrep -v "^specdiff run completed$" > $testdir/reverse.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/rs.out $testdir/rs.out | egrep -v "^specdiff run completed$" > $testdir/rs.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/sleep.out $testdir/sleep.out | egrep -v "^specdiff run completed$" > $testdir/sleep.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/sort.out $testdir/sort.out | egrep -v "^specdiff run completed$" > $testdir/sort.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/splice.out $testdir/splice.out | egrep -v "^specdiff run completed$" > $testdir/splice.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/study.out $testdir/study.out | egrep -v "^specdiff run completed$" > $testdir/study.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/sub_lval.out $testdir/sub_lval.out | egrep -v "^specdiff run completed$" > $testdir/sub_lval.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/subst.out $testdir/subst.out | egrep -v "^specdiff run completed$" > $testdir/subst.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/subst_amp.out $testdir/subst_amp.out | egrep -v "^specdiff run completed$" > $testdir/subst_amp.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/subst_wamp.out $testdir/subst_wamp.out | egrep -v "^specdiff run completed$" > $testdir/subst_wamp.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/tr.out $testdir/tr.out | egrep -v "^specdiff run completed$" > $testdir/tr.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/undef.out $testdir/undef.out | egrep -v "^specdiff run completed$" > $testdir/undef.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/unshift.out $testdir/unshift.out | egrep -v "^specdiff run completed$" > $testdir/unshift.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/vec.out $testdir/vec.out | egrep -v "^specdiff run completed$" > $testdir/vec.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/wantarray.out $testdir/wantarray.out | egrep -v "^specdiff run completed$" > $testdir/wantarray.out.cmp
exitcode=0
for i in append.out args.out arith.out array.out attrs.out auto.out base_cond.out base_pat.out base_term.out bless.out bop.out bproto.out chars.out chop.out cmdopt.out cmp.out comp_term.out concat.out context.out decl.out defins.out delete.out die.out do.out each.out eval.out exists_sub.out exp.out fh.out grep.out gv.out hashwarn.out if.out inc.out index.out int.out join.out length.out lex.out list.out loopctl.out lop.out makerand.out method.out my.out nothr5005.out oct.out op_cond.out op_pat.out ord.out override.out pack.out package.out pos.out push.out quotemeta.out range.out recurse.out redef.out ref.out regexp.out regexp_noamp.out regmesg.out repeat.out reverse.out rs.out sleep.out sort.out splice.out study.out sub_lval.out subst.out subst_amp.out subst_wamp.out tr.out undef.out unshift.out vec.out wantarray.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

