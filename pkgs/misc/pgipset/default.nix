{ stdenv, fetchFromGitHub, ipset, wget }:

stdenv.mkDerivation rec {
  name = "pgipset-0.1";

  src = fetchFromGitHub {
    owner = "ilikenwf";
    repo = "pg2ipset";
    rev = "master";
    sha256 = "1sf750vx8bmfkgsmbj8vcjfdycm0w4mfn4k8jxdlrfiay479cj0v";
  };

  buildInputs = [ ipset wget ];

  patches = [ ./nixos.patch ];

  postPatch = ''
    patchShebangs ipset-update.sh
    substituteAllInPlace ipset-update.sh
    substituteInPlace ipset-update.sh \
      --subst-var-by ipset ${ipset}
  '';

  buildPhase = ''
    make build
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    mv ipset-update.sh pg2ipset "$out/bin"
  '';

  meta = {
    description = "Converts PG2 IP Blocklists into lists that ipset can consume";
    homepage = https://github.com/ilikenwf/pg2ipset;
    license = stdenv.lib.licenses.gpl2;
    maintainers = [ stdenv.lib.maintainers.joko ];
    platforms = stdenv.lib.platforms.linux;
  };
}

