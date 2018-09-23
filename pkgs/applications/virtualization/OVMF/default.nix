{ stdenv, fetchurl, lib, edk2, nasm, iasl, seabios, secureBoot ? false, perl }:

let

  projectDscPath = if stdenv.isi686 then
    "OvmfPkg/OvmfPkgIa32.dsc"
  else if stdenv.isx86_64 then
    "OvmfPkg/OvmfPkgX64.dsc"
  else if stdenv.isAarch64 then
    "ArmVirtPkg/ArmVirtQemu.dsc"
  else
    throw "Unsupported architecture";

  version = (builtins.parseDrvName edk2.name).version;

  src = edk2.src;

  opensslSrc = fetchurl {
    url = "https://www.openssl.org/source/openssl-1.1.0i.tar.gz";
    sha256 = "16fgaf113p6s5ixw227sycvihh3zx6f6rf0hvjjhxk68m12cigzb";
  };
in (

stdenv.mkDerivation (edk2.setup projectDscPath {
  name = "OVMF-${version}";

  srcs = [ src ] ++ (lib.optionals secureBoot) [ opensslSrc ];

  outputs = [ "out" "fd" ];

  nativeBuildInputs = [ perl ];

  buildInputs = [ nasm iasl ];

  hardeningDisable = [ "stackprotector" "pic" "fortify" ];

  unpackPhase = ''
    # $fd is overwritten during the build
    export OUTPUT_FD=$fd

    for file in \
      "${src}"/{UefiCpuPkg,MdeModulePkg,IntelFrameworkModulePkg,PcAtChipsetPkg,FatBinPkg,EdkShellBinPkg,MdePkg,ShellPkg,OptionRomPkg,IntelFrameworkPkg,FatPkg,SourceLevelDebugPkg};
    do
      ln -sv "$file" .
    done

    ${if stdenv.isAarch64 then ''
      ln -sv ${src}/ArmPkg .
      ln -sv ${src}/ArmPlatformPkg .
      ln -sv ${src}/ArmVirtPkg .
      ln -sv ${src}/EmbeddedPkg .
      ln -sv ${src}/OvmfPkg .
    '' else if seabios != null then ''
      cp -r ${src}/OvmfPkg .
      chmod +w OvmfPkg/Csm/Csm16
      cp ${seabios}/Csm16.bin OvmfPkg/Csm/Csm16/Csm16.bin
    '' else ''
      ln -sv ${src}/OvmfPkg .
    ''}

    ${if secureBoot then ''
      ln -sv ${src}/SecurityPkg .
      cp -r ${src}/CryptoPkg .
      chmod +w CryptoPkg/Library/OpensslLib
      mkdir -p CryptoPkg/Library/OpensslLib/openssl
      chmod +w CryptoPkg/Library/OpensslLib/openssl
      chmod +w CryptoPkg/Library/Include/openssl/opensslconf.h
      tar xzf ${opensslSrc} -C CryptoPkg/Library/OpensslLib/openssl/ --strip-components=1
      cd CryptoPkg/Library/OpensslLib
      patchShebangs openssl/Configure
      patch -p1 < ${./openssl110i.patch}
      perl process_files.pl
      cd ../../..
    '' else ''
      ln -sv ${src}/CryptoPkg .
    ''}
  '';

  buildPhase = if stdenv.isAarch64 then ''
      build -n $NIX_BUILD_CORES
    '' else if seabios == null then ''
      build -n $NIX_BUILD_CORES ${lib.optionalString secureBoot "-DSECURE_BOOT_ENABLE=TRUE"}
    '' else ''
      build -n $NIX_BUILD_CORES -D CSM_ENABLE -D FD_SIZE_2MB ${lib.optionalString secureBoot "-DSECURE_BOOT_ENABLE=TRUE"}
    '';

  postFixup = if stdenv.isAarch64 then ''
    mkdir -vp $fd/FV
    mkdir -vp $fd/AAVMF
    mv -v $out/FV/QEMU_{EFI,VARS}.fd $fd/FV

    # Uses Fedora dir layout: https://src.fedoraproject.org/cgit/rpms/edk2.git/tree/edk2.spec
    # FIXME: why is it different from Debian dir layout? https://anonscm.debian.org/cgit/pkg-qemu/edk2.git/tree/debian/rules
    dd of=$fd/AAVMF/QEMU_EFI-pflash.raw       if=/dev/zero bs=1M    count=64
    dd of=$fd/AAVMF/QEMU_EFI-pflash.raw       if=$fd/FV/QEMU_EFI.fd conv=notrunc
    dd of=$fd/AAVMF/vars-template-pflash.raw if=/dev/zero bs=1M    count=64
  '' else ''
    mkdir -vp $OUTPUT_FD/FV
    mv -v $out/FV/OVMF{,_CODE,_VARS}.fd $OUTPUT_FD/FV
  '';

  dontPatchELF = true;

  meta = {
    description = "Sample UEFI firmware for QEMU and KVM";
    homepage = https://github.com/tianocore/tianocore.github.io/wiki/OVMF;
    license = stdenv.lib.licenses.bsd2;
    platforms = ["x86_64-linux" "i686-linux" "aarch64-linux"];
  };
}))
