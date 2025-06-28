#!/bin/bash  -xue

current_srcfile=${BASH_SOURCE:-$0}
script_dir=$(readlink -f "$(dirname "${current_srcfile}")")

project_name='python3'
source  "${script_dir}/common-config.rc"

umask  0022


##################################################################
##
##    1.  引数チェック
##

target_version=$1
: ${install_base_dir:=$2}


##################################################################
##
##    2.  ファイルの確認とダウンロード
##

target_prefix=$(readlink -m "${install_base_dir}/python-${target_version}")
if "${target_prefix}/bin/python3" --version ; then
    # インストール済みなので何もしない
    echo "Already installed in ${target_prefix}"    1>&2
    sleep 5
    exit  0
fi

dlpinfo_file=$(mktemp dlpinfo.XXXXXXXX)
/bin/bash -xue "${script_dir}/download-package.sh" "${target_version}"  \
    | tee "${dlpinfo_file}"
eval $(cat "${dlpinfo_file}")
/usr/bin/rm -f "${dlpinfo_file}"


##################################################################
##
##    3.  ビルド環境の確認
##

openssl_bin_dir=$(dirname "$(which openssl)")
openssl_dir=$(readlink -f "${openssl_bin_dir}/..")

echo "OpenSSL Dir = ${openssl_dir}"     1>&2

pwd
echo "${CC:='gcc'}"
echo "${CXX:='g++'}"

which gcc
gcc --version
sleep 5


##################################################################
##
##    4.  対象ディレクトリに python をインストール
##

: ${build_base_dir:="${install_base_dir}/builds"}

python_configure_opts="--with-openssl=${openssl_dir}"
python_configure_opts+=' --with-ssl-default-suites=openssl'

export  PYTHON_CONFIGURE_OPTS=${python_configure_opts}
export  LDFLAGS="-Wl,-rpath,${openssl_dir}/lib"

mkdir -p "${build_base_dir}"
pushd    "${build_base_dir}"

tar -xzf "${installer_file}"
cd "Python-${target_version}"

./configure  \
    --prefix="${target_prefix}"  \
    --enable-optimizations  \
    ${python_configure_opts}  \
    ;
make
make install

popd
