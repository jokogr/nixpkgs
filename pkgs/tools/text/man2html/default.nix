{ stdenv, fetchcvs }:

stdenv.mkDerivation rec {
  name = "man2html-${version}";
  version = "3.0.1";

  src = fetchcvs {
    cvsRoot = ":pserver:anonymous@cvs.savannah.gnu.org:/sources/man2html";
    module = "man2html";
    date = "2003-05-22";
    sha256 = "097pv94495njppl9iy2yk47z5wdwvf7swsl88nmwrac51jibbg4i";
  };

  meta = with stdenv.lib; {
    description = "A Unix manpage-to-HTML converter";
    license = licenses.gpl2;
    platforms = platforms.unix;
    maintainers = [ maintainers.joko ];
  };

}
