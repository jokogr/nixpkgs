{ stdenv, fetchurl, which }:

stdenv.mkDerivation rec {
	name = "x2goserver-${version}";
  version = "4.0.1.19";

	src = fetchurl {
    url = "http://code.x2go.org/releases/source/x2goserver/x2goserver-${version}.tar.gz";
		sha256 = "3dd5c1464a7992a38760fd6b08f5f8d37646f939f4f7834a7cd96bf4950623cc";
	};

  buildInputs = [ which ];

	meta = with stdenv.lib; {
		description = "Remote Desktop solution";
		homepage = http://www.x2go.org/;
		license = licenses.gpl2;
		maintainers = [ maintainers.joko ];
		platforms = platforms.linux;
	};
}
