#!/usr/bin/perl
# -w
#
# ABSOLUTELY NO WARRANTY WITH THIS PACKAGE. USE IT AT YOUR OWN RISK.
#
#
# Purpose: Add image(s) or recursive directory structure to a gallery
#
#
# Usage: galleryadd.pl [options] [file(s) | dir(s)]
#        -a album  album to be used for uploading image(s) or directory
#        -c album  create new album for uploading image(s) or directory
#        -C text   caption for image(s)
#        -d text   description for new album
#        -g url    URL of gallery (default: $gallery_url)
#        -G [1|2]  gallery version being accessed (default: v$gallery_version.x)
#        -l        list available albums for specified gallery 
#        -n        do not verify if album exists before starting upload
#        -p pass   password to use to login to gallery
#        -q        quiet mode (unless errors are encountered)
#        -t text   title for new album (if not specified uses -c value)
#        -T        test image(s) integrity before uploading (jpeg only)
#        -u user   username to use to login to gallery (default: $gallery_username)
#        -z        zap caption that is by default derived from filename
#        -h        help
#        -v        verbose
#
# Note: $CfgFile documents \$GALLERY_* variables.
#
#
# Copyright (c) 2005-2007  galleryadd.pl 2.20  Iain Lea      iain@bricbrac.de
# Copyright (c) 2002       galleryadd.pl 0.7a  Jesse Mullan  jmullan@visi.com
#
#   This program is free software; you can redistribute it and/or 
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2 of
#   the License, or (at your option) any later version.
# 
#   This program is distributed in the hope that it will be useful, 
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
#   See the GNU General Public License for more details.
# 
#   You should have received a copy of the GNU GPL along with this
#   program; if not, write to the Free Software Foundation, Inc.,
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
# Requirements:
#   The following perl modules available from CPAN are required:
#   perl -MCPAN -e shell;
#   install LWP::UserAgent
#   install HTTP::Request::Common
#     http://www.perldoc.com/perl5.6.1/lib/HTTP/Request/Common.html
#   install HTTP::Cookies
#     http://www.perldoc.com/perl5.6.1/lib/HTTP/Cookies.html
#   install HTTP::Response
#     http://www.perldoc.com/perl5.6.1/lib/HTTP/Response.html
#   install Data::Dumper
#     http://www.perldoc.com/perl5.6.1/lib/Data/Dumper.html
#   install Time::HiRes
#     http://www.perldoc.com/perl5.6.1/lib/Time/HiRes.html
#
#   Remember to make the script executable  'chmod u+x galleryadd.pl'
#	or use perl to run it 'perl galleryadd.pl'
#   galleryadd.pl requires gallery_remote2.php (G1) or main.php (G2)
#
#
# Contributors:
#   Jesse Mullan      jmullan AT visi DOT com
#   Bharat Mediratta  menalto DOT com
#   Greg Ewing        pobox DOT com
#   JH                eaglescrag DOT net
#   Antoine Rose      antoine.rose AT skynet DOT be
#   Edward Hayden     ehayden AT sbcglobal DOT net
#   Matt LeClair      laklare AT ml1 DOT net
#   Igor Kolker       igorkolker AT gmail DOT com
#   Jay Miller        jmiller AT digidata DOT com
#
#
# Changelog:
#   2.30  2007.04.10
#   - added $ua->agent('Gallery Remote') as G2.2 seems to like it better
#   - fixed G2 code to use auth_token scheme introduced in G2.1
#   2.20  2007.01.09
#   - changed -c create album to be able to add to any album not just root
#   2.10  2006.05.23
#   - added -T option to test images integrity before uploading (jpeg only)
#   - changed -c to print fancy formatted album name as when creating album
#   - fixed recursive addition of directories whose name contained spaces
#   - fixed 500 errors on large uploads ie. videos
#   2.00  2005.10.04
#   - added support for G2 galleries
#   - added -G [1|2] option to specify gallery version being accessed
#   - changed &FetchAlbums to list gallery title as well as gallery name
#   1.50  2005.07.29
#   - added -C caption for image(s) option
#   - changed &CreateCfgFile to use variable and not fixed defaults
#   1.40
#   - added &ParseEnvVars function for parsing of option variables
#     which is  1. Config file  2. Env variables  3. command line
#   - added &ParseCfgFile function for parsing .galleryaddrc config file
#   - added &CreateCfgFile to document ENV variables
#   - changed &FormatTitle function to uppercase every word in album title
#   - changed &FormatCaption function to uppercase every word in image caption
#   - changed $GALLERY_[USER|PASS] -> $GALLERY_[USERNMAME|PASSWORD]
#   1.30
#   - added &FormatCaption function to fancy format dates and whitespace
#   - changed &FormatTitle function to uppercase first word in album title
#   - changed &PrintErr function to work better with -q quiet option
#   1.20
#   - changed -l option to output albums & subalbums in tree form
#   1.10
#   - added filesize to upload stats   (Upload file.jpg [132.1K] [OK])
#   - added xfer speed to upload stats (Upload file.jpg [280kb/s] [OK])
#   - added $ENV{GALLERY_LOG} for verbose logfile 
#   - changed fetch-albums code to be in &FetchAlbumList function
#   - changed cookie_jar saving from autosave => 1 to $cookie_jar_save
#   - fixed stripping of path from filename for ParseCmdLine function
#   - fixed -v option to expand "~/galleryadd.log" to $HOME/filename
#   - fixed '-c newalbum' to exit if album already exists in gallery
#   - fixed -l option which was printing no files error message
#   - fixed logic so that ! [-a|-c] prints error message and usage 
#   - fixed logic so that -c newalbum can be done without adding images
#   - fixed @ARGV to be sorted before calling AddDir/AddImage (cygwin)
#   1.00
#   - added -l list albums option
#   - added -z zap captions option to replace -c add captions options
#   - added &AddAlbum for -c [-d|-t] creation of top-level album
#   - added $ENV{GALLERY_[URL|USER|PASS|ALBUM]} for default settings
#   - added &GetResponse routine to get response code and text info
#   - added &PrintOut, &PrintErr, &LogPrint output/error/log routines
#   - changed format of feedback given to user to be consistent
#   - changed command line parsing routine and format
#   0.7
#   - last official release
#
#
# Todo:
#   2.40
#   - if G2 then check if -a ID/Name is \d+ otherwise issue errormsg!
#   - disable -n if G2 gallery (need id <-> name mappings!)
#   - fix -T &CheckFileIntegrity
#   - -a needs a fuzzy lookup   $AlbumId = &LookupAlbumId ($Name, $Title)
#     with error if more than 1 match found. Regex support needed.
#   - add gif/png etc. integrity support to -T option?
#   - -C to create whole set of new albums (add whole dir tree!)
#   - -c create sub-album under top-level album HOW ? 
#   - add more stats ie. "Upload F.jpg [001/120] ... [OK]
#   - what all the work for @gallery_filename and @ARGV usage?
#   - highlight pic possible via GR protocol ???
#   - resort of album possible via GR protocol ???
#   - fix/debug 'zip' to @FormatList for bulk upload ???
#
#use strict;
require 'getopts.pl';
require LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTTP::Response;
use Time::HiRes qw(gettimeofday tv_interval);
# when debugging we might use Data::Dumper
#use Data::Dumper;

# constants
my $Version = 'v2.30';
my $ScriptName = 'galleryadd.pl';
my $ScriptUrl = "http://iainlea.dyndns.org/software/galleryadd";
my $Copyright = "Copyright (c) 2002-2007  iain\@bricbrac.de & jmullan\@visi.com";
my @FormatList = (
	'jpeg', 'jpg', 'gif', 'png', 'crw', 'nef', 'avi', 'mpg', 'mpeg', 'wmv',
	'mov','swf'
);

# variables  Note: 'local' is used in pref to 'my' due to &ParseCfgFile magic!
#
my $CfgFile = ($ENV{"GALLERYADD_CONFIG"} ? 
	$ENV{"GALLERYADD_CONFIG"} : "$ENV{'HOME'}/.galleryaddrc");
local $gallery_version = 1;
local $gallery_url = "http://gallery.yoursite.com";
local $gallery_ssl = 0;
local $gallery_username = "admin";
local $gallery_password = "";
local $gallery_album = "";
local $gallery_caption = "";
local $gallery_zapcaption = 0;
local $gallery_quietmode = 0;
local $gallery_noverify = 0;
local $gallery_parent = "";
local $gallery_newalbum = "";
local $gallery_newtitle = "";
local $gallery_newdescr = " ";
local $gallery_listalbums = 0;
local $gallery_integrity = 0;
#
my $gallery_logfile = ($ENV{"GALLERY_LOG"} ? $ENV{"GALLERY_LOG"} : "$ENV{'HOME'}/.galleryadd.log");
my $gallery_logopen = 0;
my $gallery_verbose = 0;
my $cookie_jar_save = 0;
#
#  calculated
my $gallery_protocol_version;
my $gallery_file;
my $gallery_album_exists;
my $gallery_filename;
my $correct_arguments = 0;
my $gallery_fullurl;
my $gallery_auth_token;
my $ua;
my $response;
my $gallery_resp_text;
my $gallery_resp_throwaway;
my $gallery_resp_code;
my @gallery_files = ();
my $gallery_file_count;
my @gallery_resp_array;
my @items;
my @albums;
my @albumnames;
my $dir;
my $i;
my $return;

$| = 1;

&ParseCfgFile ($CfgFile);

&ParseEnvVars;

&ParseCmdLine ($0, 0);

&LogOpen;

# set up the user agent
$ua = LWP::UserAgent->new;
$ua->agent('Gallery Remote');
$ua->timeout (3600);	# 60 minutes instead of default 3 minutes
$ua->cookie_jar (HTTP::Cookies->new (file => 'cookie_jar', autosave => $cookie_jar_save));
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

&PrintOut ("Logging ON. Logfile:  $gallery_logfile\n\n") if $gallery_verbose;
&PrintOut ("System  $gallery_fullurl  [G$gallery_version]\nLogin:  $gallery_username  ");

&LogPrintCmd ("login", $gallery_username, $gallery_password, "", "");

if ($gallery_version == 1) {
	$response = $ua->request (POST $gallery_fullurl,
		Content_Type	=> 'form-data',
		Content			=> [ 
			protocol_version	=> $gallery_protocol_version,
			cmd					=> "login",
			uname				=> $gallery_username,
			password			=> $gallery_password 
		] );
} else {
	$response = $ua->request (POST $gallery_fullurl,
		Content_Type	=> 'form-data',
		Content			=> [
			'g2_controller'				=> 'remote:GalleryRemote',
			'g2_form[protocol_version]'	=> $gallery_protocol_version,
			'g2_form[cmd]'				=> "login",
			'g2_form[uname]'			=> $gallery_username,
			'g2_form[password]'			=> $gallery_password
		] );
}

($gallery_resp_code, $gallery_resp_text) = &GetResponse ($response);

if ($gallery_resp_code != 200) {
	if ($gallery_resp_code == 404) {
		&PrintErr ($gallery_fullurl, $gallery_resp_code, $gallery_resp_text,
			"gallery_remote2.php (G1) or main.php (G2). Is it installed on the server?");
	} else {
		&PrintErr ($gallery_fullurl, $gallery_resp_code, $gallery_resp_text, "");
    }
} else {
	SWITCH: {
		if ($gallery_resp_text =~ /Login successful/i) {
			&PrintOut ("[OK]\n");
			last SWITCH;
		}
		if ($gallery_resp_text =~ /Login parameters not found/i ||
			$gallery_resp_text =~ /Login Incorrect/i) {
			&PrintErr ("", $gallery_resp_code, $gallery_resp_text, $gallery_username);
			last SWITCH;
		}
		&PrintErr ("", "", $gallery_resp_text, "incorrect username/password");
	} 
}

if ($gallery_newalbum) {
	&FetchAlbumList ($gallery_newalbum, 1);
	&AddAlbum ($gallery_newalbum, $gallery_newtitle, $gallery_newdescr, $gallery_parent);
	$gallery_album = $gallery_newalbum;
} else {
	&FetchAlbumList ($gallery_album, 0);
}

for my $filename (sort (@ARGV)) {
	next if ($filename eq '.' || $filename eq '..'); 

	if (-d "$filename") {
		&PrintOut ("Check:  $filename  ");

		if (! -e "$filename") {
			&PrintErr ("", "", "", "directory not found");
		}
		if (! -r "$filename") {
			&PrintErr ("", "", "", "directory exists but no access. Check perms?");
		}
		if (! -x "$filename") {
			&PrintErr ("", "", "", "directory exists but cannot read it. Check perms?");
		}
		&PrintOut ("[OK]\n");

		&AddDirectory ($gallery_album, $filename);
	} else {
		&PrintOut ("Upload  $filename  ");

		if (! -e "$filename") {
			&PrintErr ("", "", "", "file not found");
		}
		if (! -r "$filename") {
			&PrintErr ("", "", "", "file exists but no access. Check perms?");
		}
		if (isAcceptable ($filename)) {
			&AddImage ($gallery_album, "$filename");
		} else {
			&PrintOut ("[IGNORED]\n");
		}
	}
}

&LogClose;

exit 0;


#######################################################################
# SUBROUTINES

sub ParseCmdLine
{
	my ($ProgPath, $ShowUsage) = @_;
	my $ProgName = $ProgPath;

	$ProgName = $1 if ($ProgName =~ /.*\/([^\/]*)/);

	&Getopts ('a:c:C:d:g:G:hlnp:qst:Tu:vz');

	if ($opt_h || $ShowUsage) { 
		print <<EOT
$ScriptName $Version  URL: $ScriptUrl

$Copyright

Add image(s) or recursive directory structure to an online gallery

Usage: $ProgName [options] [file(s) | dir(s)]
       -a album  album to be used for uploading image(s) or directory
       -c album  create new album for uploading image(s) or directory
       -C text   caption for image(s)
       -d text   description for new album
       -g url    URL of gallery (default: $gallery_url)
       -s        Use https: instead of http:
       -G [1|2]  gallery version being accessed (default: v$gallery_version.x)
       -l        list available albums for specified gallery 
       -n        do not verify if album exists before starting upload
       -p pass   password to use to login to gallery
       -q        quiet mode (unless errors are encountered)
       -t text   title for new album (if not specified uses -c value)
       -T        test image(s) integrity before uploading (jpeg only)
       -u user   username to use to login to gallery (default: $gallery_username)
       -z        zap caption that is by default derived from filename
       -h        help
       -v        verbose

Examples:
  $ProgName -g http://gallery -u admin -p secret123 -a mycars bmw.jpg

    upload image bmw.jpg to album mycars

  $ProgName -g http://gallery -u admin -p secret123 -c xmas /tmp/*

    create album xmas and upload images located in /tmp directory

Options are settable in the config file $CfgFile.
EOT
;
		exit 1;
	}
	$gallery_album = $gallery_parent = $opt_a if (defined ($opt_a));
	$gallery_newalbum = $opt_c if (defined ($opt_c));
	$gallery_caption = $opt_C if (defined ($opt_C));
	$gallery_newdescr = $opt_d if (defined ($opt_d));
	$gallery_url = $opt_g if (defined ($opt_g));
	$gallery_ssl = 1 if (defined ($opt_s));
	$gallery_version = $opt_G if (defined ($opt_G));
	$gallery_listalbums = 1 if (defined ($opt_l));
	$gallery_noverify = 1 if (defined ($opt_n));
	$gallery_password = $opt_p if (defined ($opt_p));
	$gallery_quietmode = 1 if (defined ($opt_q));
	$gallery_newtitle = $opt_t if (defined ($opt_t));
	$gallery_integrity = 1 if (defined ($opt_T));
	$gallery_username = $opt_u if (defined ($opt_u));
	$gallery_verbose = 1 if (defined ($opt_v));
	$gallery_zapcaption = 1 if (defined ($opt_z));

	if ($gallery_version != 1 && $gallery_version != 2) {
		print "Error: -G option required - specify version\n\n";
		$gallery_version = 1;
		&ParseCmdLine ($0, 1);	
	}

	if (! $gallery_url) {
		print "Error: -g option required - specify URL\n\n";
		&ParseCmdLine ($0, 1);	
	}

	if (! $gallery_username) {
		print "Error: -u option required - specify username\n\n";
		&ParseCmdLine ($0, 1);	
	}

	if (! $gallery_password) {
		print "Error: -p option required - specify password\n\n";
		&ParseCmdLine ($0, 1);	
	}

	if ($gallery_listalbums) {
		$gallery_album = $gallery_newalbum = "";
	} elsif (! $gallery_album && ! $gallery_newalbum) {
		print "Error: -a or -c option required - specify album\n\n";
		&ParseCmdLine ($0, 1);	
	}

	if ($gallery_newalbum && ! $gallery_newtitle) {
		$gallery_newtitle = $gallery_newalbum;
	}

	for my $filename (@ARGV) {
		next if ($filename eq '.' || $filename eq '..' || $filename eq '');

		$filename =~ s|\\|/|;
		if(substr ($filename, -1) eq '/') {
			$filename=substr ($filename, 0, -1);
		}
		push (@gallery_files, $filename);
	}
	$gallery_file_count = @gallery_files;

	if ((! $gallery_newalbum && ! $gallery_listalbums) && ! $gallery_file_count) {
		print "Error: no files to upload - specify file(s)\n\n";
		&ParseCmdLine ($0, 1);	
	}

	if ($gallery_version == 1) {
		$gallery_protocol_version = '2.1';
		$gallery_file = '/gallery_remote2.php';
	} else {
		$gallery_protocol_version = '2.5';
		$gallery_file = '/main.php';
	}

	# check the url
	if (substr ($gallery_url, 0, 4) ne 'http') {
            if ($gallery_ssl > 0) {
		$gallery_fullurl = 'https://';
            } else {
                $gallery_fullurl = 'http://';
            }
            $gallery_fullurl .= $gallery_url . $gallery_file;
	} else {
		$gallery_fullurl = $gallery_url . $gallery_file;
	}

#	print "DBG:  ver=[$gallery_version]  proto=[$gallery_protocol_version]  url=[$gallery_fullurl]\n";
}


sub ParseCfgFile
{
	my ($CfgFile) = @_;

	if (-f "$CfgFile") {
		if (open (CFG, "$CfgFile")) {
			while (<CFG>) {
				chomp;              #  killing these things:
#				s[/\*.*\*/][];      #  /* comment */
#				s[//.*][];          #  // comment
				s/#.*//;            #  # comment 
				s/^\s+//;           #  whitespace before stuff
#				s/\s+$//;           #  whitespace after stuff
				next unless length; #  If our line is empty, We should ignore some stuff

				($CfgParam, $CfgValue) = split (/=/, $_);
				$$CfgParam = $CfgValue;

#				print "DBG:  [$_]  param=$CfgParam  value=$CfgValue $$CfgParam\n";
			}
			close CFG;

#			print "DBG:  CFG  gallery_version=[$gallery_version]\n";
#			print "DBG:  CFG  gallery_url=[$gallery_url]\n";
#			print "DBG:  CFG  gallery_ssl=[$gallery_ssl]\n";
#			print "DBG:  CFG  gallery_username=[$gallery_username]\n";
#			print "DBG:  CFG  gallery_password=[$gallery_password]\n";
#			print "DBG:  CFG  gallery_album=[$gallery_album]\n";
#			print "DBG:  CFG  gallery_caption=[$gallery_caption]\n";
#			print "DBG:  CFG  gallery_zapcaption=[$gallery_zapcaption]\n";
#			print "DBG:  CFG  gallery_quietmode=[$gallery_quietmode]\n";
#			print "DBG:  CFG  gallery_noverify=[$gallery_noverify]\n";
#			print "DBG:  CFG  gallery_newalbum=[$gallery_newalbum]\n";
#			print "DBG:  CFG  gallery_newtitle=[$gallery_newtitle]\n";
#			print "DBG:  CFG  gallery_newdescr=[$gallery_newdescr]\n";
#			print "DBG:  CFG  gallery_listalbums=[$gallery_listalbums]\n";
#			print "DBG:  CFG  gallery_integrity=[$gallery_integrity]\n";
		}
	} else {
		&CreateCfgFile ($CfgFile);
		&ParseCmdLine ($0, 1);
	}
}


sub CreateCfgFile
{
	my ($CfgFile) = @_;

	print "Info: creating default config file $CfgFile\n\n";

	if (open (CFG, ">$CfgFile")) {
		print CFG <<EOT
# File: .galleryaddrc  $Version
# Note: parse order is  1. Config file  2. ENV variables  3. Command line

# Option:  -G [1|2]  gallery version being accessed
# ENVvar:  \$GALLERY_VERSION
# Values:  [1 | 2]  Default:  $gallery_version
#
gallery_version=$gallery_version

# Option:  -g url  URL of gallery
# ENVvar:  \$GALLERY_URL
# Values:  TEXT  Default:  $gallery_url
#
gallery_url=$gallery_url

# Option:  -s use https: instead of http:
# ENVvar:  \$GALLERY_SSL
# Values:  TEXT  Default:  $gallery_ssl
#
gallery_ssl=0

# Option:  -u user  username to use to login to gallery
# ENVvar:  \$GALLERY_USERNAME
# Values:  TEXT  Default:  $gallery_username
#
gallery_username=$gallery_username

# Option:  -p pass  password to use to login to gallery
# ENVvar:  \$GALLERY_PASSWORD
# Values:  TEXT  Default:  $gallery_password
#
gallery_password=$gallery_password

# Option:  -a album  album to be used for uploading image(s) or directory
# ENVvar:  \$GALLERY_ALBUM
# Values:  TEXT  Default:  $gallery_album
#
gallery_album=$gallery_album

# Option:  -c album  create new album for uploading image(s) or directory
# ENVvar:  \$GALLERY_NEWALBUM
# Values:  TEXT  Default:  $gallery_newalbum
#
gallery_newalbum=$gallery_newalbum

# Option:  -C text  caption for image(s)
# ENVvar:  \$GALLERY_CAPTION
# Values:  TEXT  Default:  $gallery_caption
#
gallery_caption=$gallery_caption

# Option:  -d text  description for new album
# ENVvar:  \$GALLERY_NEWDESCR
# Values:  TEXT  Default:  $gallery_newdescr
#
gallery_newdescr=$gallery_newdescr

# Option:  -l  list available albums for specified gallery
# ENVvar:  \$GALLERY_LISTALBUMS
# Values:  [0 | 1]  Default:  $gallery_listalbums
#
gallery_listalbums=$gallery_listalbums

# Option:  -n  do not verify if album exists before starting upload
# ENVvar:  \$GALLERY_NOVERIFY
# Values:  [0 | 1]  Default:  $gallery_noverify
#
gallery_noverify=$gallery_noverify

# Option:  -q  quiet mode (unless errors are encountered)
# ENVvar:  \$GALLERY_QUIETMODE
# Values:  [0 | 1]  Default:  $gallery_quietmode
#
gallery_quietmode=$gallery_quietmode

# Option:  -t text  title for new album (if not specified uses -c value)
# ENVvar:  \$GALLERY_NEWTITLE
# Values:  TEXT  Default:  $gallery_newtitle
#
gallery_newtitle=$gallery_newtitle

# Option:  -T  test image(s) integrity before uploading (jpeg only)
# ENVvar:  \$GALLERY_INTEGRITY
# Values:  [0 | 1]  Default:  $gallery_integrity
#
gallery_integrity=$gallery_integrity

# Option:  -z  zap caption that is by default derived from filename
# ENVvar:  \$GALLERY_ZAPCAPTION
# Values:  [0 | 1]  Default:  $gallery_zapcaption
#
gallery_zapcaption=$gallery_zapcaption
EOT
;
		close CFG;
	}
}


sub ParseEnvVars
{
	$gallery_version = &GetEnvVar (GALLERY_VERSION, $gallery_version);

	$gallery_url = &GetEnvVar (GALLERY_URL, $gallery_url);

	$gallery_ssl = &GetEnvVar (GALLERY_SSL, $gallery_ssl);

	$gallery_username = &GetEnvVar (GALLERY_USERNAME, $gallery_username);

	$gallery_password = &GetEnvVar (GALLERY_PASSWORD, $gallery_password);

	$gallery_album = &GetEnvVar (GALLERY_ALBUM, $gallery_album);

	$gallery_newalbum = &GetEnvVar (GALLERY_NEWALBUM, $gallery_newalbum);

	$gallery_caption = &GetEnvVar (GALLERY_CAPTION, $gallery_caption);

	$gallery_newtitle = &GetEnvVar (GALLERY_NEWTITLE, $gallery_newtitle);

	$gallery_noverify = &GetEnvVar (GALLERY_NOVERIFY, $gallery_noverify);

	$gallery_listalbums = &GetEnvVar (GALLERY_LISTALBUMS, $gallery_listalbums);

	$gallery_quietmode = &GetEnvVar (GALLERY_QUIETMODE, $gallery_quietmode);

	$gallery_newdescr = &GetEnvVar (GALLERY_NEWDESCR, $gallery_newdescr);

	$gallery_integrity = &GetEnvVar (GALLERY_INTEGRITY, $gallery_integrity);

	$gallery_zapcaption = &GetEnvVar (GALLERY_ZAPCAPTION, $gallery_zapcaption);
}


sub GetEnvVar
{
	my ($EnvVar, $DefaultVar) = @_;
	my $Value;

	$Value = ($ENV{$EnvVar} ? $ENV{$EnvVar} : $DefaultVar);

#	print "DBG:  ENV  $EnvVar=[$Value]\n";

	return $Value;
}


sub AlbumExists 
{
	my ($name) = @_;

	for my $album (@albumnames) {
		if ($album eq $name) {
			return -1;
		}
	}
    return 0;
}


sub AddDirectory
{
	my ($album, $dir) = @_;
	my @dirname = split (/\//, $dir);
	my $wantedAlbumName = $dirname[$#dirname];
	my $cleanAlbumName = $wantedAlbumName;
	my $newAlbumName = $wantedAlbumName;
	my ($newAlbumNum, $newAlbumTitle);

#   JH: fix for albums with spaces in them, this is a hard coded /hack/ but should work in most cases.
#   this could be changed to include some sort of optional character substitution, but this works for now

#   JH: Parentheses seem to cause some odd problems, not sure if this is directly due to problems inherent in
#   gallery itself, or if this is due in part to perl not liking them much.  Personally, I think it's
#   the nature of the way query is dealt with by the webserver needing a means of not dealing with
#   special characters.  Solution: ignore these as characters
#   JM: I also moved these into that mass of special characters in that regex.  I'm not eager to group them
#   with square brackets and figure out which ones need to be escaped and which ones don't.
#   $newAlbumName =~ s/\(|\)//g;

#   JM: I put the ampersand into the special characters group because it makes more sense to me there.
#   I am including this line in the comments because it might be a useful hint to users seeking to
#   transform their ampersands into something useful
#   $newAlbumName =~ s/&/AND/g;


#   Here is the actual regex that clears out naughty characters.
	$cleanAlbumName =~ s/\\|\/|\*|\?|"|'|<|>|\||\.|\+|#|\s|&|\(|\)/_/g;
	$newAlbumName = $cleanAlbumName;
	$i = 0;
	while (AlbumExists ($newAlbumName)) {
		$newAlbumName = $cleanAlbumName . '_' . $i;
		$i++;
	}
	opendir (DIR, $dir) || &PrintErr ("", "", "", "$dir - $!");
	my @filename = readdir (DIR);
	closedir DIR;
    
	$newAlbumTitle = &FormatTitle ($dirname[$#dirname]);

	&PrintOut ("Create  $album/$newAlbumName  ($newAlbumTitle)  ");

	&LogPrintCmd ("new-album", $album, $newAlbumName, $newAlbumTitle, "");

	if ($gallery_version == 1) {
		$response = $ua->request (POST $gallery_fullurl,
			Content_Type	=> 'form-data',
			Content			=> [ 
				protocol_version	=> $gallery_protocol_version,
				cmd					=> "new-album",
				set_albumName		=> $album,
				newAlbumName		=> $newAlbumName,
				newAlbumTitle		=> $newAlbumTitle,
				newAlbumDesc		=> ''
			] );
	} else {
		$response = $ua->request (POST $gallery_fullurl,
			Content_Type	=> 'form-data',
			Content			=> [ 
				'g2_controller'				=> 'remote:GalleryRemote',
				'g2_form[protocol_version]'	=> $gallery_protocol_version,
				'g2_form[cmd]'				=> "new-album",
				'g2_form[set_albumName]'	=> $album,
				'g2_form[newAlbumName]'		=> $newAlbumName,
				'g2_form[newAlbumTitle]'	=> $newAlbumTitle,
				'g2_form[newAlbumDesc]'		=> '',
				'g2_authToken'				=> $gallery_auth_token
			] );
	}

	($gallery_resp_code, $gallery_resp_text) = &GetResponse ($response);
    
	if ($gallery_resp_code != 200) {
		&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
			"could not create album");
	} else {
		SWITCH: {
			if ($gallery_resp_text =~ /New album created successful/i ||
				$gallery_resp_text =~ /New-album successful/i) {
				if ($gallery_resp_text =~ /album_name=(.+)/) {
					$newAlbumName = $newAlbumNum = $1;
					print "($newAlbumName)  ";
				}
				push (@albumnames, $newAlbumName);
				&PrintOut ("[OK]\n");
				last SWITCH;
			}
			if ($gallery_resp_text =~ /A new album could not be created because the user does not have permission to do so/) {
				&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
					"could not create album - user does not have permission");
				last SWITCH;
			}
			&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
				"could not create album - unknown error");
		} 
	}
    
    foreach my $filename (sort (@filename))  {
		next if ($filename eq '.' || $filename eq '..'); 

		if ( -d "$dir/$filename") {
			&PrintOut ("Check:  $dir/$filename  ");

			if (! -e "$dir/$filename") {
				&PrintErr ("", "", "", "directory not found");
			}
			if (! -r "$dir/$filename") {
				&PrintErr ("", "", "", "directory exists but no access. Check perms?");
			}
			if (! -x "$dir/$filename") {
				&PrintErr ("", "", "", "directory exists but cannot read it. Check perms?");
			}
			&PrintOut ("[OK]\n");

			&AddDirectory ($newAlbumName, "$dir/$filename");
		} else {
			&PrintOut ("Upload  $dir/$filename  ");

			if (! -e "$dir/$filename") {
				&PrintErr ("", "", "", "file not found");
			}
			if (! -r "$dir/$filename") {
				&PrintErr ("", "", "", "file exists but no access. Check perms?");
			}
			if (isAcceptable ("$dir/$filename")) {
				&AddImage ($newAlbumName, "$dir/$filename");
			} else {
				&PrintOut ("[IGNORED]\n");
			}
		}
	}
}


sub AddAlbum 
{
	my ($album, $title, $descr, $parent) = @_;
	my $wantedAlbumName = $album;
	my $cleanAlbumName = $wantedAlbumName;
	my $newAlbumName = $wantedAlbumName;
	my ($newAlbumNum, $newAlbumTitle);

#   JH: fix for albums with spaces in them, this is a hard coded /hack/ but should work in most cases.
#   this could be changed to include some sort of optional character substitution, but this works for now

#   JH: Parentheses seem to cause some odd problems, not sure if this is directly due to problems inherent in
#   gallery itself, or if this is due in part to perl not liking them much.  Personally, I think it's
#   the nature of the way query is dealt with by the webserver needing a means of not dealing with
#   special characters.  Solution: ignore these as characters
#   JM: I also moved these into that mass of special characters in that regex.  I'm not eager to group them
#   with square brackets and figure out which ones need to be escaped and which ones don't.
#   $newAlbumName =~ s/\(|\)//g;

#   JM: I put the ampersand into the special characters group because it makes more sense to me there.
#   I am including this line in the comments because it might be a useful hint to users seeking to
#   transform their ampersands into something useful
#   $newAlbumName =~ s/&/AND/g;


#   Here is the actual regex that clears out naughty characters.
	$albumcleanAlbumName =~ s/\\|\/|\*|\?|"|'|<|>|\||\.|\+|#|\s|&|\(|\)/_/g;
	$newAlbumName = $cleanAlbumName;
	$i = 0;
	while (AlbumExists ($newAlbumName)) {
		$newAlbumName = $cleanAlbumName . '_' . $i;
		$i++;
	}
    
	$newAlbumTitle = &FormatTitle ($title);

	if ($gallery_version == 1) {
		if ($parent) {
			&PrintOut ("Create  $parent/$newAlbumName  ($newAlbumTitle)  ");
		} else {
			&PrintOut ("Create  $newAlbumName  ($newAlbumTitle)  ");
		}
		&LogPrintCmd ("new-album", "", $newAlbumName, $newAlbumTitle, $descr, $parent);

		$response = $ua->request (POST $gallery_fullurl,
			Content_Type	=> 'form-data',
			Content			=> [ 
				protocol_version	=> $gallery_protocol_version,
				cmd					=> "new-album",
				set_albumName		=> $parent,
				newAlbumName		=> $newAlbumName,
				newAlbumTitle		=> $newAlbumTitle,
				newAlbumDesc		=> $descr
			] );
	} else {
		&PrintOut ("Create  $newAlbumName  ($newAlbumTitle)  ");
		&LogPrintCmd ("new-album", $albums[1]->{'name'}, $newAlbumName, $newAlbumTitle, $descr);

		$response = $ua->request (POST $gallery_fullurl,
			Content_Type	=> 'form-data',
			Content			=> [ 
				'g2_controller'				=> 'remote:GalleryRemote',
				'g2_form[protocol_version]'	=> $gallery_protocol_version,
				'g2_form[cmd]'				=> "new-album",
				'g2_form[set_albumName]'	=> $albums[1]->{'name'},
				'g2_form[newAlbumName]'		=> $newAlbumName,
				'g2_form[newAlbumTitle]'	=> $newAlbumTitle,
				'g2_form[newAlbumDesc]'		=> $descr,
				'g2_authToken'				=> $gallery_auth_token
			] );
	}

	($gallery_resp_code, $gallery_resp_text) = &GetResponse ($response);
    
	if ($gallery_resp_code != 200) {
		&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
			"could not create album");
	} else {
		SWITCH: {
			if ($gallery_resp_text =~ /New album created successful/i ||
				$gallery_resp_text =~ /New-album successful/i) {
				if ($gallery_resp_text =~ /album_name=(.+)/) {
					$newAlbumName = $newAlbumNum = $1;
					print "($newAlbumName)  ";
				}
				push (@albumnames, $newAlbumName);
				&PrintOut ("[OK]\n");
				last SWITCH;
			}
			if ($gallery_resp_text =~ /A new album could not be created because the user does not have permission to do so/) {
				&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
					"could not create album - user does not have permission");
				last SWITCH;
			}
			&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
				"could not create album - unknown error");
		} 
	}
}


sub isAcceptable ($)
{
	my ($File) = shift (@_);
	my (@Pieces, $Extension, $Format);

	@Pieces = split (/\./, $File);
	$Extension = $Pieces[$#Pieces];

# print "DBG:  isAcceptable ($File, $Extension)\n";

	for $Format (@FormatList) {
# print "DBG:  format=[$Format] ext=[$Extension]\n";
		if ($Format eq lc ($Extension)) {
			if ($gallery_integrity && $Format =~ /(jpg|jpeg)/) {
				return &CheckFileIntegrity ($File);
			} else {
				return -1;
			}
		}
	}

	return 0;
}


sub CheckFileIntegrity
{
	my ($File) = shift (@_);
	my ($Head, $Tail);

	print "DBG:  CheckFileIntegrity ($File)\n";

	if (open (FILE, "< $File")) {
		read FILE, $Head, 2;
		$Head = pack ("n", $Head);

		seek (FILE, -2, SEEK_END);

		read FILE, $Tail, 2;
		$Tail = pack ("n", $Tail);

		close FILE;

		if (($Head == 0xd8ff) && ($Tail == 0xd9ff)) {
#		if (($Head == 0xffd8) && ($Tail == 0xffd9)) {
printf "DBG:  OK  Head=[0xffd8][%s] Tail=[0xffd9][%s]\n", $Head, $Tail;
			return -1;
		}
	}

printf "DBG:  ERR Head=[0xffd8][%s] Tail=[0xffd9][%s]\n", $Head, $Tail;

	return 0;
}


sub stripPathAndExtension ($)
{
	my $fullpath = shift (@_);
	my @path = split(/\//, $fullpath);
	my $filename = pop (@path);
	my @pieces = split (/\./, $filename);

	pop @pieces;

	return join ('.', @pieces);
}


sub AddImage
{
	my ($album, $filename) = @_;
	my ($Caption, $beg_time, $end_time);

	$beg_time = [gettimeofday];

	if (! $gallery_zapcaption) {

		$Caption = ($gallery_caption ? 
			$gallery_caption : &FormatCaption ($filename));

		&PrintOut ("\($Caption\)  ");

		&LogPrintCmd ("add-item", $album, "caption", $Caption, $filename);

		if ($gallery_version == 1) {
			$response = $ua->request (POST $gallery_fullurl,
				Content_Type	=> 'form-data',
				Content			=> [ 
					protocol_version	=> $gallery_protocol_version,
					cmd					=> "add-item",
					set_albumName		=> $album,
					caption				=> $Caption,
					userfile			=> ["$filename"]
				] );
		} else {
			$response = $ua->request (POST $gallery_fullurl,
				Content_Type	=> 'form-data',
				Content			=> [
					'g2_controller'				=> 'remote:GalleryRemote',
					'g2_form[protocol_version]' => $gallery_protocol_version,
					'g2_form[cmd]'				=> "add-item",
					'g2_form[set_albumName]'	=> $album,
					'g2_form[caption]'			=> $Caption,
					'g2_userfile'				=> ["$filename"],
					'g2_authToken'				=> $gallery_auth_token
				] );
		}
	} else {
		&LogPrintCmd ("add-item", $album, "setCaption", $filename);

		if ($gallery_version == 1) {
			$response = $ua->request (POST $gallery_fullurl,
				Content_Type	=> 'form-data',
				Content			=> [ 
					protocol_version	=> $gallery_protocol_version,
					cmd					=> "add-item",
					set_albumName		=> $album,
					setCaption			=> '',
					userfile			=> ["$filename"]
				] );
		} else {
			$response = $ua->request (POST $gallery_fullurl,
				Content_Type	=> 'form-data',
				Content			=> [
					'g2_controller'				=> 'remote:GalleryRemote',
					'g2_form[protocol_version]' => $gallery_protocol_version,
					'g2_form[cmd]'				=> "add-item",
					'g2_form[set_albumName]'	=> $album,
					'g2_form[caption]'			=> '',
					'g2_userfile'				=> ["$filename"],
					'g2_authToken'				=> $gallery_auth_token
				] );
		}
	}

	($gallery_resp_code, $gallery_resp_text) = &GetResponse ($response);

	$end_time = [gettimeofday];

	if ($gallery_resp_code != 200) {
		&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
			"could not upload image");
	} else {
		SWITCH: {
			if ($gallery_resp_text =~ /Add photo successful/) {
				&PrintOutUploadStats ($filename, $beg_time, $end_time);
				last SWITCH;
			}
			if ($gallery_resp_text =~ /User cannot add to album/) {
				&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
					"could not upload image - user cannot add to album");
				last SWITCH;
			}
			&PrintErr ("", $gallery_resp_code, $gallery_resp_text, 
				"could not upload image - unknown error");
		} 
	}
}


sub LogOpen
{
	if ($gallery_verbose && $gallery_logfile) {
		open (LOG, ">>$gallery_logfile") || die "Error: $gallery_logfile - $!";
		$gallery_logopen = 1;
	}
}


sub LogClose
{
	close LOG if ($gallery_logopen);
}


sub LogPrint
{
	my ($Code, $Text, $Mesg) = @_;
	
	if ($gallery_logopen) {
		print LOG "$Mesg\n" if $Mesg; 
		print LOG "$Code\n" if $Code; 
		print LOG "$Text\n" if $Text; 
	}
}


sub LogPrintCmd
{
	my ($Cmd, $Val1, $Val2, $Val3, $Val4) = @_;

	if ($gallery_logopen) {
		print LOG "POST $gallery_fullurl\n";
		print LOG "Content_Type => 'form-data'\n";
		print LOG "Content      => \n";
		print LOG "  protocol_version => $gallery_protocol_version\n";
		print LOG "  cmd              => '$Cmd'\n";
		
		if ($Cmd =~ /login/) {
			print LOG "  uname            => $Val1\n";
			print LOG "  password         => $Val2\n";
		} elsif ($Cmd =~ /new-album/) {
			print LOG "  set_albumName    => $Val1\n";
			print LOG "  newAlbumName     => $Val2\n";
			print LOG "  newAlbumTitle    => $Val3\n";
			print LOG "  newAlbumDesc     => $Val4\n";
		} elsif ($Cmd =~ /add-item/) {
			print LOG "  set_albumName    => $Val1\n";
			print LOG "  $Val2            => $Val3\n";
			print LOG "  userfile         => $Val4\n";
		}

		print LOG "\n";
	}
}

sub PrintOut
{
	my ($Mesg) = @_;

	print $Mesg if (! $gallery_quietmode);
}


sub PrintErr
{
	my ($Url, $Code, $Text, $Mesg) = @_;

	print "[ERROR]\n\n" if ! $gallery_quietmode;
	print "Error:  $Mesg\n" if $Mesg;
	print "\n" if ($Url || $Code || $Text);
	print "$Url\n" if $Url;
	print "$Code\n" if $Code;
	print "$Text" if $Text;

	exit 1;
}


sub GetResponse
{
	my ($Response) = @_;
	my $Code, $Text;

	$Code = $Response->code;
	if ($Response->is_error) {
		$Text = $Response->error_as_HTML;
	} else {
		$Text = $Response->content;
	}

	print "DBG:  code=[$Code]  text=[$Text]\n" if $gallery_verbose;

	&LogPrint ($Code, $Text, "");

	return ($Code, $Text);
}


sub FormatTitle
{
	my ($Title) = @_;
	my @TitleList, $NewTitle = $Title;

	if ($NewTitle =~ /([0-9]{4})([0-9]{2})([0-9]{2})/) {
		$NewTitle = "$1.$2.$3";
	}

	$NewTitle =~ s/[-_]/ /g;

	$NewTitle =~ s/(\w+)/\u\L$1/g;

	return $NewTitle;
}


sub FormatCaption
{
	my ($Caption) = @_;
	my $NewCaption = &stripPathAndExtension ($Caption);

	if ($NewCaption =~ /([0-9]{4})([0-9]{2})([0-9]{2})[-_\s](\d+)/) {
		$NewCaption = "$1.$2.$3 $4";
	}

	$NewCaption =~ s/[-_]/ /g;

	$NewCaption =~ s/(\w+)/\u\L$1/g;

	return $NewCaption;
}


sub FetchAlbumList
{
	my ($album_name, $create_album) = @_;
	my ($album_num);

	return if $gallery_noverify;

	&PrintOut ("Album:  fetching list  ");

	&LogPrintCmd ("fetch-albums", "", "", "", "");

	# Fetch list of albums
	if ($gallery_version == 1) {
		$response = $ua->request(POST $gallery_fullurl,
			Content_Type	=> 'form-data',
			Content			=> [ 
				protocol_version	=> $gallery_protocol_version,
				cmd					=> "fetch-albums"
			] );
	} else {
		$response = $ua->request (POST $gallery_fullurl,
			Content_Type	=> 'form-data',
			Content			=> [
				'g2_controller'				=> 'remote:GalleryRemote',
				'g2_form[protocol_version]'	=> $gallery_protocol_version,
				'g2_form[cmd]'				=> "fetch-albums-prune"
			] );
	}

	($gallery_resp_code, $gallery_resp_text) = &GetResponse ($response);

	if ($gallery_resp_code != 200) {
		&PrintErr ($gallery_fullurl, $gallery_resp_code, $gallery_resp_text, "");
	} else {
		SWITCH: {
			if ($gallery_resp_text =~ /Fetch albums successful/i ||
				$gallery_resp_text =~ /Fetch-albums successful/i) {
				&PrintOut ("[OK]\n");
				last SWITCH;
			}
			&PrintErr ("", $gallery_resp_code, $gallery_resp_text, "unknown error");
		}
	}

	if (! $gallery_listalbums) {
		if ($create_album) {
			&PrintOut ("Check:  $album_name  ");
		} else {
			&PrintOut ("Album:  $album_name  ");
		}
	}

	@gallery_resp_array = split (/\n/, $gallery_resp_text);

	# Not sure why we're throwing these away, but the G2.2 auth token
	# shows up at the very end of the list so if you get rid of these lines
	# (possibly to get rid of the debug_user and debug_time results?) you lose
	# the auth token and can't do anything.
	#
	# $gallery_resp_text = pop (@gallery_resp_array);
	# $gallery_resp_throwaway = pop (@gallery_resp_array);

	$gallery_resp_code = $response->code;
	$gallery_album_exists = 0;

	foreach my $item (@gallery_resp_array) {
		chomp ($item);
		my ($field, @value) = split (/=/, $item);

		if ($field eq 'auth_token') {
			$gallery_auth_token = shift (@value);
print "DBG:  auth_token=[$gallery_auth_token]\n" if $gallery_verbose;
			next;
		}

		my @foo = split (/\./, $field);
		my $bar = shift (@foo);
		if ($bar eq 'album_count') {
			next;
		}

		my $fieldname = shift (@foo);
		if ($fieldname eq 'perms') {
			my $fieldname .= '.' . shift (@foo);
		}

print "DBG:  field=[$fieldname]  " if $gallery_verbose;

		my $number = shift (@foo);
		if ($fieldname eq 'name') {
			$albums[$number]->{'name'} = $albumName = join ('=', @value);
			push (@albumnames, join ('=', @value));

print "name=[$albumName]\n" if $gallery_verbose;

			if ($album_name eq $albums[$number]->{'name'}) {
				$gallery_album_exists = 1;
				$album_num = $number;
			}
		}

		if ($fieldname eq 'title') {
			$albums[$number]->{'title'} = join ('=', @value);
printf "title=[%s]\n", $albums[$number]->{'title'} if $gallery_verbose;
		}
		if ($fieldname eq 'summary') {
			$albums[$number]->{'summary'} = join ('=', @value);
printf "summary=[%s]\n", $albums[$number]->{'summary'} if $gallery_verbose;
		}
		if ($fieldname eq 'parent') {
			$albums[$number]->{'parent'} = join ('=', @value);

if ($gallery_version == 1) {
			$albums[$number]->{'id'} = $number;
} else {
			$albums[$number]->{'id'} = $albumName;
}

printf "parent=[%s]  id=[$number]\n", $albums[$number]->{'parent'} if $gallery_verbose;
		}
		if ($fieldname eq 'perms.add') {
			$albums[$number]->{'add'} = join ('=', @value);
printf "perms.add=[%s]\n", $albums[$number]->{'add'} if $gallery_verbose;
		}
		if ($fieldname eq 'perms.write') {
			$albums[$number]->{'write'} = join ('=', @value);
printf "perms.write=[%s]\n", $albums[$number]->{'write'} if $gallery_verbose;
		}
		if ($fieldname eq 'perms.del_alb') {
			$albums[$number]->{'del_alb'} = join ('=', @value);
printf "perms.del_alb=[%s]\n", $albums[$number]->{'del_alb'} if $gallery_verbose;
		}
		if ($fieldname eq 'perms.create_sub') {
			$albums[$number]->{'create_sub'} = join ('=', @value);
printf "perms.create_sub=[%s]\n", $albums[$number]->{'create_sub'} if $gallery_verbose;
		}
		if ($fieldname eq 'perms.del_item') {
			$albums[$number]->{'del_item'} = join ('=', @value);
printf "perms.del_item=[%s]\n", $albums[$number]->{'del_item'} if $gallery_verbose;
		}
		if ($fieldname eq 'info.extrafields') {
			$albums[$number]->{'extrafields'} = join ('=', @value);
printf "perms.info.extrafields=[%s]\n", $albums[$number]->{'info.extrafields'} if $gallery_verbose;
		}
	}

	if ($gallery_listalbums) {
		&PrintAlbumTree;
	} else {
		if ($gallery_album_exists) {
			if ($create_album) {
				&PrintErr ("", "", "", "specified album already exists");
			} else {
				&PrintOut ("($albums[$album_num]->{'title'})  [OK]\n");
			}
		} else {
			if ($create_album) {
				&PrintOut ("[OK]\n");
			} else {
				&PrintErr ("", "", "", "specified album does not exist");
			}
		}
	}
}


sub PrintAlbumTree
{
	my ($Num, $Info, $Padding, $Len);

	$Padding = "";

	foreach $Num (1 .. $#albums) {
		if ($albums[$Num]->{'parent'} == 0) {	# top level album
			$Info = "";
			if ($gallery_verbose) {
				$Info = sprintf "[%03d]  [%03d]  ",
					$albums[$Num]->{'id'},
					$albums[$Num]->{'parent'};
			}

			$Len = ($gallery_version == 1 ? 13 : 5);
			$Info .= sprintf "%-${Len}s  (%s)",
				$albums[$Num]->{'name'}, 
				$albums[$Num]->{'title'};

			&PrintOut ("Album:  $Padding$Info\n");

			&PrintAlbumNode ($albums[$Num]->{'id'}, $Padding);
		}
	}
}


sub PrintAlbumNode
{
	my ($Id, $Padding) = @_;
	my ($Num, $Info, $Len);

	$Padding .= "  ";

	foreach $Num (1 .. $#albums) {
		if ($Id == $albums[$Num]->{'parent'}) {
			$Info = "";
			if ($gallery_verbose) {
				$Info = sprintf "[%03d]  [%03d]  ",
					$albums[$Num]->{'id'},
					$albums[$Num]->{'parent'};
			}

			$Len = ($gallery_version == 1 ? 13 : 5);
			$Info .= sprintf "%-${Len}s  (%s)",
				$albums[$Num]->{'name'}, 
				$albums[$Num]->{'title'};

			&PrintOut ("Album:  $Padding$Info\n");

			&PrintAlbumNode ($albums[$Num]->{'id'}, $Padding);
		}
	}
}


sub PrintOutUploadStats
{
	my ($File, $BegTime, $EndTime) = @_;
	my ($Size) = (stat ($File)) [7];
	my $Elapsed = tv_interval $BegTime, $EndTime;
	my $BytesPerSec = $Size / $Elapsed;
	my $Xfer, $Stats;

	if ($Size > 1048576) {		# MB
		$Size = sprintf "%1.1fM", $Size / 1048576; 
	} elsif ($Size > 1024) {	# KB
		$Size = sprintf "%3.0fK", $Size / 1024; 
	}

	if ($BytesPerSec > 1048576) {	# MB/s
		$Xfer = sprintf "%1.1fM/s", $BytesPerSec / 1048576; 
	} elsif ($BytesPerSec > 1024) {	# KB/s
		$Xfer = sprintf "%3.0fK/s", $BytesPerSec / 1024; 
	}
	
	$Stats = sprintf "[%4s] [%6s] [OK]\n", $Size, $Xfer;
	&PrintOut ($Stats);
}
