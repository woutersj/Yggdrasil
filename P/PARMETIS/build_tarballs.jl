using BinaryBuilder

name = "PARMETIS"
version = v"4.0.4" # <-- This is a lie, we're bumping to 4.0.4 to create a Julia v1.6+ release with experimental platforms

# Collection of sources required to build PARMETIS.
# The patch prevents building the source of METIS that ships with PARMETIS;
# we rely on METIS_jll instead.
sources = [
    ArchiveSource("http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz",
                  "f2d9a231b7cf97f1fee6e8c9663113ebf6c240d407d3c118c55b3633d6be6e5f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/parmetis-4.0.3

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done

pushd metis
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0001-mingw-w64-does-not-have-sys-resource-h.patch
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0002-mingw-w64-do-not-use-reserved-double-underscored-names.patch
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0003-WIN32-Install-RUNTIME-to-bin.patch
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0004-Fix-GKLIB_PATH-default-for-out-of-tree-builds.patch
fi
popd

cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHARED=1 \
    -DGKLIB_PATH=$(realpath ../metis/GKlib) \
    -DMETIS_PATH=$(realpath ../metis) \
    -DMPI_INCLUDE_PATH="${prefix}/include" \
    -DMPI_LIBRARIES="mpi"
make -j${nproc}
make install
"""

# OpenMPI and MPICH are not precompiled for Windows
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libparmetis", :libparmetis)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("METIS_jll"),
    Dependency("MPICH_jll"; platforms=filter(!Sys.iswindows, platforms)),
    Dependency("MicrosoftMPI_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
