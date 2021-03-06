#!/bin/bash

set +vx
type module >& /dev/null || . /mnt/software/Modules/current/init/bash
module purge
#module load gcc
#module load ccache
module load python/3
module load htslib/1.9
module load zlib
module load cram
set -vex

which gcc
gcc --version
which python3
python3 --version

export PYTHONUSERBASE=$PWD/build
export PATH=${PYTHONUSERBASE}/bin:${PATH}

#PIP="pip --cache-dir=$bamboo_build_working_directory/.pip"
PIP=pip
if [[ -z ${bamboo_repository_branch_name+x} ]]; then
  WHEELHOUSE=/mnt/software/p/python/wheelhouse/develop
elif [[ ${bamboo_repository_branch_name} == develop ]]; then
  WHEELHOUSE=/mnt/software/p/python/wheelhouse/develop
elif [[ ${bamboo_repository_branch_name} == master ]]; then
  WHEELHOUSE=/mnt/software/p/python/wheelhouse/master
else
  WHEELHOUSE=/mnt/software/p/python/wheelhouse/develop
fi
export WHEELHOUSE

rm -rf   build
mkdir -p build/{bin,lib,include,share}
PIP_INSTALL="${PIP} install --no-index --find-links=${WHEELHOUSE}"
#PIP_INSTALL="${PIP} install -v"

export HTSLIB_MODE='external'
export HTSLIB_LIBRARY_DIR=/mnt/software/h/htslib/1.9/lib
export HTSLIB_INCLUDE_DIR=/mnt/software/h/htslib/1.9/include
#$PIP install -v --user pysam==0.15.3
$PIP_INSTALL --user repos/pbcommand
$PIP_INSTALL --user repos/pbcore

#python -c 'import pysam as p; print(p)'
#$PIP_INSTALL --user pyBigWig
#python -c 'import pysam as p; print(p)'

#iso8601 xmlbuilder tabulate pysam avro?
$PIP_INSTALL --user ./
python3 -c 'import pysam as p; print(p)'

# Sanity-test for linkage errors.
ipdSummary -h

$PIP_INSTALL --user --upgrade pytest
$PIP_INSTALL --user pytest-xdist pytest-cov pylint

make -j3 test
