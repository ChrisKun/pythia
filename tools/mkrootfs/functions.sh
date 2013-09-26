#!/bin/sh
# Copyright 2013 The Pythia Authors.
# This file is part of Pythia.
#
# Pythia is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# Pythia is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Pythia.  If not, see <http://www.gnu.org/licenses/>.


## install_debs PACKAGE...
##
## Install Debian packages from $DEBIAN_MIRROR. A package is specified as
## "pkgname" or as "suite/pkgname", where "pkgname" is the name of the Debian
## package to install and "suite" is the Debian suite (version) to fetch.
## The default suite is $DEBIAN_SUITE.

: ${DEBIAN_MIRROR:=http://ftp.debian.org/debian}
: ${DEBIAN_SUITE:=squeeze}
debcache_dir=${build_dir}/debcache

install_debs() {
    for pkgname in "$@"; do
        # Extract suite name
        if [ "${pkgname#*/}" != "${pkgname}" ]; then
            suite=${pkgname%/${pkgname#*/}}
            pkgname=${pkgname#*/}
        else
            suite=${DEBIAN_SUITE}
        fi
        # Check if package was already installed
        mkdir -p "${work_dir}/tmp/debs/${suite}"
        [ ! -e "${work_dir}/tmp/debs/${suite}/${pkgname}" ] || return 0
        # Create cache directory
        cache=${debcache_dir}/${suite}
        mkdir -p "${cache}"
        # Download package list if needed
        if [ ! -e "${cache}/Packages.gz" ]; then
            wget -O "${cache}/Packages.gz" \
                "${DEBIAN_MIRROR}/dists/${suite}/main/binary-i386/Packages.gz"
        fi
        # Resolve filename
        filename=$(zcat "${cache}/Packages.gz" |
            sed -n "/^Package: ${pkgname}\$/,/^\$/ s/^Filename: \(.*\)\$/\1/p")
        basename=$(basename "$filename")
        deb=${cache}/${basename}
        # Download deb
        if [ ! -e "${deb}" ]; then
            msg "Downloading ${suite}/${basename}..."
            wget -O "${deb}" "${DEBIAN_MIRROR}/${filename}"
        fi
        # Extract deb
        msg "Extracting ${suite}/${pkgname}..."
        ar -p "${deb}" data.tar.gz | tar -xzC "${work_dir}"
        touch "${work_dir}/tmp/debs/${suite}/${pkgname}"
    done
}
