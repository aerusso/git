#!/bin/sh

test_description='git log --graph of merges'

. ./test-lib.sh
. "$TEST_DIRECTORY"/lib-log-graph.sh

check_graph () {
	cat >expect &&
	lib_test_cmp_graph --format=%s "$@"
}

crawl() {
	T=$(git commit-tree $nulltree -m "$@" ) &&
	git tag $1 $T
}

test_expect_success 'setup test' '
	nulltree=$(git hash-object -t tree /dev/null)
'

test_expect_success 'log --graph with merge pulling in a feature' '
	git checkout --orphan _p && test_commit A &&
	git checkout -b _q &&
	git checkout _p && test_commit B &&
	git checkout -b _r &&
	git checkout _p && test_commit C &&
	git checkout _r && test_commit F_1 &&
	git checkout _q && test_commit F_2 &&
	git checkout _r && git merge --no-ff _q -m M &&
	git checkout _p && git merge --no-ff _r -m D &&

	check_graph <<-\EOF
	X   D
	|\
	| *   M
	| |\
	| | * F_2
	| * | F_1
	* | | C
	|/ /
	* / B
	|/
	* A
	EOF
'

test_expect_success 'log --graph with merge pulling in a feature (ignore-merge-bases)' '
	check_graph --ignore-merge-bases <<-\EOF
	X   D
	|\
	| *   M
	| |\
	| | v F_2
	| v F_1
	* C
	* B
	* A
	EOF
'

test_expect_success 'log --graph with twisted merge pulling in a feature from master' '
	git checkout --orphan 0_p && test_commit 0_A &&
	git checkout -b 0_q &&
	git checkout 0_p && test_commit 0_B &&
	git checkout -b 0_r &&
	git checkout 0_p && test_commit 0_C &&
	git checkout 0_q && test_commit 0_F1 && git merge --no-ff 0_r -m 0_M1 &&
	git checkout 0_p && git merge --no-ff 0_q -m 0_M2 &&

	check_graph <<-\EOF
	X   0_M2
	|\
	| *   0_M1
	| |\
	| * | 0_F1
	* | | 0_C
	| |/
	|/|
	* | 0_B
	|/
	* 0_A
	EOF
'

test_expect_success 'log --graph with twisted merge pulling in a feature from master (ignore-merge-bases)' '
	check_graph --ignore-merge-bases <<-\EOF
	X   0_M2
	|\
	| v 0_M1
	| v 0_F1
	* 0_C
	* 0_B
	* 0_A
	EOF
'

test_expect_success 'log --graph with several merges' '
	git checkout --orphan 1_p &&
	test_commit 1_root &&
	for m in $(test_seq 1 10) ;
	do
		git checkout -b 1_f${m} 1_root ;
		test_commit 1_A${m} ;
	done &&
	for m in $(test_seq 1 10) ;
	do
		i=$((11 - $m)) ;
		git merge --no-ff 1_f${i} -m 1_M${m}A${i} ;
	done &&
	for mp in $(test_seq 1 10) ;
	do
		m=$((11 - mp))
		git checkout 1_f${m} ;
		test_commit 1_B${m} ;
		git checkout 1_p ;
		git merge --no-ff 1_f${m} -m 1_M${m} ;
	done &&

	check_graph <<-\EOF
	X   1_M1
	|\
	| * 1_B1
	* |   1_M2
	|\ \
	| * | 1_B2
	* | |   1_M3
	|\ \ \
	| * | | 1_B3
	* | | |   1_M4
	|\ \ \ \
	| * | | | 1_B4
	* | | | |   1_M5
	|\ \ \ \ \
	| * | | | | 1_B5
	* | | | | |   1_M6
	|\ \ \ \ \ \
	| * | | | | | 1_B6
	* | | | | | |   1_M7
	|\ \ \ \ \ \ \
	| * | | | | | | 1_B7
	* | | | | | | |   1_M8
	|\ \ \ \ \ \ \ \
	| * | | | | | | | 1_B8
	* | | | | | | | |   1_M9
	|\ \ \ \ \ \ \ \ \
	| * | | | | | | | | 1_B9
	* | | | | | | | | |   1_M10
	|\ \ \ \ \ \ \ \ \ \
	| * | | | | | | | | | 1_B10
	| * | | | | | | | | |   1_M10A1
	| |\ \ \ \ \ \ \ \ \ \
	| | | |_|_|_|_|_|_|_|/
	| | |/| | | | | | | |
	| | * | | | | | | | | 1_A1
	| |/ / / / / / / / /
	|/| | | | | | | | |
	| * | | | | | | | |   1_M9A2
	| |\ \ \ \ \ \ \ \ \
	| | | |_|_|_|_|_|_|/
	| | |/| | | | | | |
	| | * | | | | | | | 1_A2
	| |/ / / / / / / /
	|/| | | | | | | |
	| * | | | | | | |   1_M8A3
	| |\ \ \ \ \ \ \ \
	| | | |_|_|_|_|_|/
	| | |/| | | | | |
	| | * | | | | | | 1_A3
	| |/ / / / / / /
	|/| | | | | | |
	| * | | | | | |   1_M7A4
	| |\ \ \ \ \ \ \
	| | | |_|_|_|_|/
	| | |/| | | | |
	| | * | | | | | 1_A4
	| |/ / / / / /
	|/| | | | | |
	| * | | | | |   1_M6A5
	| |\ \ \ \ \ \
	| | | |_|_|_|/
	| | |/| | | |
	| | * | | | | 1_A5
	| |/ / / / /
	|/| | | | |
	| * | | | |   1_M5A6
	| |\ \ \ \ \
	| | | |_|_|/
	| | |/| | |
	| | * | | | 1_A6
	| |/ / / /
	|/| | | |
	| * | | |   1_M4A7
	| |\ \ \ \
	| | | |_|/
	| | |/| |
	| | * | | 1_A7
	| |/ / /
	|/| | |
	| * | |   1_M3A8
	| |\ \ \
	| | | |/
	| | |/|
	| | * | 1_A8
	| |/ /
	|/| |
	| * | 1_M2A9
	| |\|
	| | * 1_A9
	| |/
	|/|
	| * 1_A10
	|/
	* 1_root
	EOF
'

test_expect_success 'log --graph with several merges (ignore-merge-bases)' '
	check_graph --ignore-merge-bases <<-\EOF
	X   1_M1
	|\
	| v 1_B1
	*   1_M2
	|\
	| v 1_B2
	*   1_M3
	|\
	| v 1_B3
	*   1_M4
	|\
	| v 1_B4
	*   1_M5
	|\
	| v 1_B5
	*   1_M6
	|\
	| v 1_B6
	*   1_M7
	|\
	| v 1_B7
	*   1_M8
	|\
	| v 1_B8
	*   1_M9
	|\
	| v 1_B9
	*   1_M10
	|\
	| * 1_B10
	| *   1_M10A1
	| |\
	| | v 1_A1
	| *   1_M9A2
	| |\
	| | v 1_A2
	| *   1_M8A3
	| |\
	| | v 1_A3
	| *   1_M7A4
	| |\
	| | v 1_A4
	| *   1_M6A5
	| |\
	| | v 1_A5
	| *   1_M5A6
	| |\
	| | v 1_A6
	| *   1_M4A7
	| |\
	| | v 1_A7
	| *   1_M3A8
	| |\
	| | v 1_A8
	| *   1_M2A9
	| |\
	| | v 1_A9
	| v 1_A10
	* 1_root
	EOF
'

test_expect_success 'log --graph with root re-merge' '
	crawl rrm_root &&
	crawl rrm_A -p rrm_root &&
	crawl rrm_B -p rrm_root -p rrm_A &&
	crawl rrm_C -p rrm_root &&
	crawl rrm_D -p rrm_B -p rrm_C &&
	crawl rrm_E -p rrm_D -p rrm_root &&

	check_graph rrm_E <<-\EOF
	X   rrm_E
	|\
	* \   rrm_D
	|\ \
	| * | rrm_C
	| |/
	* |   rrm_B
	|\ \
	| |/
	|/|
	| * rrm_A
	|/
	* rrm_root
	EOF
'

test_expect_success 'log --graph with root re-merge (ignore merge bases)' '
	check_graph --ignore-merge-bases rrm_E <<-\EOF
	V rrm_E
	*   rrm_D
	|\
	| v rrm_C
	*   rrm_B
	|\
	| v rrm_A
	* rrm_root
	EOF
'

test_done
