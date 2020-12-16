#!/usr/bin/perl

#
# Tool for generate catalog of exoplanets
#
# Copyright (C) 2013 Alexander Wolf
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 

use DBI();
use LWP::UserAgent();
use Text::CSV;

#
# Stage 1: connect to 'The Extrasolar Planets Encyclopaedia' at exoplanet.eu, fetch CSV data and store to MySQL
# Stage 2: read MySQL catalog of exoplanets and store it to JSON
#

$URL	= "http://exoplanet.eu/catalog/csv/";
$CSV	= "./exoplanets.csv";
$HCSV	= "./";
$JSON	= "./exoplanets.json";
$HCSV	= "./habitable.csv";

$CATALOG_FORMAT_VERSION = 1;

$dbname	= "exoplanets";
$dbhost	= "localhost";
$dbuser	= "exoplanet";
$dbpass	= "exoplanet";

$UA = LWP::UserAgent->new(keep_alive => 1, timeout => 360);
$UA->agent("Mozilla/5.0 (Stellarium Exoplanets Catalog Updater 0.5; http://stellarium.org/)");
$request = HTTP::Request->new('GET', $URL);
$responce = $UA->request($request);

if ($responce->is_success) {
	open(OUT, ">$CSV");
	$data = $responce->content;
	binmode OUT;
	print OUT $data;
	close OUT;
} else {
	print "Can't connect to URL: $URL\n";
	exit;
}

$dsn = "DBI:mysql:database=$dbname;host=$dbhost";

$csvdata = Text::CSV->new();

open (HCSV, "<$HCSV");
@habitable = <HCSV>;
close HCSV;

%hs = ();
%hp = ();
for ($i=1;$i<scalar(@habitable);$i++) {
	$status  = $csvdata->parse($habitable[$i]);
	@hdata = $csvdata->fields();
	%hs = (%hs, $hdata[0], 1);
	%hp = (%hp, $hdata[0]." ".$hdata[1], $habitable[$i]);
}

open (CSV, "<$CSV");
@catalog = <CSV>;
close CSV;

$dbh = DBI->connect($dsn, $dbuser, $dbpass, {'RaiseError' => 1});
$sth = $dbh->do(q{SET NAMES utf8});
$sth = $dbh->do(q{TRUNCATE stars});
$sth = $dbh->do(q{TRUNCATE planets});

for ($i=1;$i<scalar(@catalog);$i++) {
	$currdata = $catalog[$i];
	
	@cpname = ();
	(@cpname) = split(",",$currdata);
	
	@cfname = ();
	@cfname = split(" ",$cpname[0]);
	
	if (scalar(@cfname)==4) {
		$csname = $cfname[0]." ".$cfname[1]." ".$cfname[2];
		$pname = $cfname[3];
	} elsif (scalar(@cfname)==3) {
		$csname = $cfname[0]." ".$cfname[1];
		$pname = $cfname[2];
	} else {
		$csname = $cfname[0];
		$pname = $cfname[1];
	}
	
	$status  = $csvdata->parse($currdata);
	($aname,$pmass,$pradius,$pperiod,$psemiax,$pecc,$pincl,$angdist,$psl,$discovered,$updated,$pomega,$ptperi,$ptconj,$ptzero_tr,$ptzero_tr_sec,$plambda_angle,$ptzero_vr,$ptemp_calculated,$ptemp_measured,$phot_point_lon,$plog_g,$dtype,$mol,$starname,$sRA,$sDec,$sVmag,$sImag,$sJmag,$sHmag,$sKmag,$sdist,$smetal,$smass,$sradius,$sstype,$sage,$sefftemp) = $csvdata->fields();

	($hour,$mint,$sect) = split(":",$sRA);
	($deg,$min,$sec) = split(":",$sDec);
	# fixed bug in raw data
	$sec =~ s/-//gi;
	# fixed bug for Kepler-68
	if ($starname =~ m/kepler-68/gi) {
		$hour = 19;
	}
	# fixed bug for omi CrB
	if ($starname =~ m/omi\s+CrB/gi) {
		$hour = 15; $mint = 20; $sect = 8.4;
		$deg = 29; $min = 36; $sec = 57.9;
	}
	
	$sec =~ s/-//gi;
	$sect =~ s/-//gi;
	
	$outRA = $hour."h".$mint."m".$sect."s";
	$outDE = $deg."d".$min."m".$sec."s";
	
	$sname = $starname;

	$sname =~ s/^alpha/α/gi;
	$sname =~ s/^alf/α/gi;
	$sname =~ s/^beta/β/gi;
	$sname =~ s/^gamma/γ/gi;
	$sname =~ s/^delta/δ/gi;
	$sname =~ s/^epsilon/ε/gi;
	$sname =~ s/^eps/ε/gi;
	$sname =~ s/^zeta/ζ/gi;
	$sname =~ s/^theta/θ/gi;
	$sname =~ s/^eta/η/gi;
	$sname =~ s/^iota/ι/gi;
	$sname =~ s/^kappa/κ/gi;
	$sname =~ s/^lambda/λ/gi;
	$sname =~ s/^mu/μ/gi;
	$sname =~ s/^nu/ν/gi;
	$sname =~ s/^xi/ξ/gi;
	$sname =~ s/^ksi/ξ/gi;
	$sname =~ s/^(omicron|omi)/ο/gi;
	$sname =~ s/^pi/π/gi;
	$sname =~ s/^rho/ρ/gi;
	$sname =~ s/^sigma/σ/gi;
	$sname =~ s/^tau/τ/gi;
	$sname =~ s/^upsilon/υ/gi;
	$sname =~ s/^ups/υ/gi;
	$sname =~ s/^phi/φ/gi;
	$sname =~ s/^chi/χ/gi;
	$sname =~ s/^psi/ψ/gi;
	$sname =~ s/^omega/ω/gi;
	$sname =~ s/^ome/ω/gi;
	
	if (($sRA ne '00:00:00.0') && ($sDec ne '+00:00:00.0') && ($sname ne '')) {
		# check star
		$sth = $dbh->prepare(q{SELECT sid,sname FROM stars WHERE ra_coord=? AND dec_coord=?});
		$sth->execute($outRA, $outDE);
		@starDATA = $sth->fetchrow_array();
		# get star ID
		if (scalar(@starDATA)!=0) {
			$starID   = @starDATA[0];
			$starName = @starDATA[1];
		} else {
			$HPflag = 0;
			if (exists($hs{$sname})) {
				$HPflag = 1;
			}
			# insert star data
			$sth = $dbh->do(q{INSERT INTO stars (ra_coord,dec_coord,sname,distance,stype,smass,smetal,vmag,sradius,sefftemp,has_habit_planet) VALUES (?,?,?,?,?,?,?,?,?,?,?)}, undef, $outRA, $outDE, $sname, $sdist, $sstype, $smass, $smetal, $sVmag, $sradius, $sefftemp, $HPflag);
			$sth = $dbh->prepare(q{SELECT sid,sname FROM stars ORDER BY sid DESC LIMIT 0,1});
			$sth->execute();
			@starDATA = $sth->fetchrow_array();
			$starID   = @starDATA[0];
			$starName = @starDATA[1];
		}
		
		$hclass = '';
		$mstemp = -1;
		$esi    = -1;
		
		$key = $starName." ".$pname;
		if (exists($hp{$key})) {
			$status  = $csvdata->parse($hp{$key});
			($hsname,$hpname,$hclass,$mstemp,$esi) = $csvdata->fields();
		}
		
		# insert planet data
		$sth = $dbh->do(q{INSERT INTO planets (sid,pname,pmass,pradius,pperiod,psemiaxis,pecc,pinc,padistance,discovered,hclass,mstemp,esi) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)}, undef, $starID, $pname, $pmass, $pradius, $pperiod, $psemiax, $pecc, $pincl, $angdist, $discovered, $hclass, $mstemp, $esi);
	}
}

open (JSON, ">$JSON");
print JSON "{\n";
print JSON "\t\"version\": \"".$CATALOG_FORMAT_VERSION."\",\n";
print JSON "\t\"shortName\": \"A catalogue of stars with exoplanets\",\n";
print JSON "\t\"stars\":\n";
print JSON "\t{\n";

$sth = $dbh->prepare(q{SELECT COUNT(sid) FROM stars});
$sth->execute();
@scountraw = $sth->fetchrow_array();
$scount = @scountraw[0];
$i = 0;

$sth = $dbh->prepare(q{SELECT * FROM stars});
$sth->execute();
while (@stars = $sth->fetchrow_array()) {
	$sid		= $stars[0];
	$RA		= $stars[1];
	$DE		= $stars[2];
	$sname		= $stars[3];
	$sdist		= $stars[4];
	$sstype		= $stars[5];
	$smass		= $stars[6];
	$smetal		= $stars[7];
	$sVmag		= $stars[8];
	$sradius	= $stars[9];
	$sefftemp	= $stars[10];
	$hasHabitPl	= $stars[11];
	
	$out  = "\t\t\"".$sname."\":\n";
	$out .= "\t\t{\n";
	$out .= "\t\t\t\"exoplanets\":\n";
	$out .= "\t\t\t[\n";
	
	$stp = $dbh->prepare(q{SELECT COUNT(pid) FROM planets WHERE sid=?});
	$stp->execute($sid);
	@pcountraw = $stp->fetchrow_array();
	$pcount = @pcountraw[0];
	$j = 0;
	
	$stp = $dbh->prepare(q{SELECT * FROM planets WHERE sid=?});
	$stp->execute($sid);
	while(@planets = $stp->fetchrow_array()) {
		$pid		= $planets[0];
		$pname		= $planets[2];
		$pmass		= $planets[3];
		$pradius	= $planets[4];
		$pperiod	= $planets[5];
		$psemiax	= $planets[6];
		$pecc		= $planets[7];
		$pinc		= $planets[8];
		$angdist	= $planets[9];
		$discovered	= $planets[10];
		$habitclass	= $planets[11];
		$meanstemp	= $planets[12];
		$esindex	= $planets[13];
	
		$out .= "\t\t\t{\n";
		if ($pmass ne '') {
			$out .= "\t\t\t\t\"mass\": ".$pmass.",\n";
		}
		if ($pradius ne '') {
			$out .= "\t\t\t\t\"radius\": ".$pradius.",\n";
		}
		if ($pperiod ne '') {
			$out .= "\t\t\t\t\"period\": ".$pperiod.",\n";
		}
		if ($psemiax ne '') {
			$out .= "\t\t\t\t\"semiAxis\": ".$psemiax.",\n";
		}
		if ($pecc ne '') {
			$out .= "\t\t\t\t\"eccentricity\": ".$pecc.",\n";
		}
		if ($pinc ne '') {
			$out .= "\t\t\t\t\"inclination\": ".$pinc.",\n";
		}
		if ($angdist ne '') {
			$out .= "\t\t\t\t\"angleDistance\": ".$angdist.",\n";
		}
		if ($discovered ne '') {
			$out .= "\t\t\t\t\"discovered\": ".$discovered.",\n";
		}
		if ($habitclass ne '') {
			$out .= "\t\t\t\t\"hclass\": \"".$habitclass."\",\n";
		}
		if ($meanstemp > 0) {
			$out .= "\t\t\t\t\"MSTemp\": ".$meanstemp.",\n";
		}
		if ($esindex > 0) {
			$out .= "\t\t\t\t\"ESI\": ".$esindex.",\n";
		}
		if ($pname eq '') {
			$pname = "a";
		}
		$out .= "\t\t\t\t\"planetName\": \"".$pname."\"\n";
		$out .= "\t\t\t}";
		$j += 1;
		if ($j<$pcount) {
			$out .= ",";
		}
		$out .= "\n";
	}
	$out .= "\t\t\t],\n";

	if ($sdist ne '') {
		$out .= "\t\t\t\"distance\": ".$sdist.",\n";
	}
	if ($sstype ne '') {
		$out .= "\t\t\t\"stype\": \"".$sstype."\",\n";
	}
	if ($smass ne '') {
		$out .= "\t\t\t\"smass\": ".$smass.",\n";
	}
	if ($smetal ne '') {
		$out .= "\t\t\t\"smetal\": ".$smetal.",\n";
	}
	if ($sVmag ne '') {
		$out .= "\t\t\t\"Vmag\": ".$sVmag.",\n";
	}
	if ($sradius ne '') {
		$out .= "\t\t\t\"sradius\": ".$sradius.",\n";
	}
	if ($sefftemp ne '') {
		$out .= "\t\t\t\"effectiveTemp\": ".$sefftemp.",\n";
	}
	if ($hasHabitPl > 0) {
		$out .= "\t\t\t\"hasHP\": true,\n";
	}
	$out .= "\t\t\t\"RA\": \"".$RA."\",\n";
	$out .= "\t\t\t\"DE\": \"".$DE."\"\n";
	$out .= "\t\t}";
	
	$i += 1;
	if ($i<$scount) {
		$out .= ",";
	}

	print JSON $out."\n";

}

print JSON "\t}\n}";

close JSON;
