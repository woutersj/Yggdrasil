# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NetCDFCXX"
version = v"4.3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Unidata/netcdf-cxx4/archive/refs/tags/v$(version).tar.gz", "e3fe3d2ec06c1c2772555bf1208d220aab5fee186d04bd265219b0bc7a978edc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-cxx4-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdf_c++4", :libnetcdf_cxx4)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
