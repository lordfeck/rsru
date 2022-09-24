#!/usr/bin/env perl

#===============================================================================
# Thransoft RSRU Release 3.1 (with multimedia extensions)
# A static catalogue-style website generator, freely given
# Licence: GPLv3. See "licence.txt" for full details.
# Author: Thran. Authored: 09/09/2020 - 07/05/2022
# WWW: http://soft.thran.uk
# 
# With Thanks: https://stackoverflow.com/questions/63835994/
#===============================================================================

use strict;
use warnings;
use v5.10;

use File::Copy;
use File::Path qw(make_path remove_tree);
use Time::Piece;
use Getopt::Std;
use List::Util qw(first);
use Cwd qw(getcwd);

#===============================================================================
# Load optional modules if available. Set flag so we know whether they are
#===============================================================================
my $has_rss = eval
{
    require XML::RSS;
    XML::RSS->import();
    1;
};

my $has_gd = eval
{
    require GD;
    GD->import();
    GD::Image->trueColor(1);
    1;
};

#===============================================================================
# Begin function defs and global vars.
#===============================================================================
my %entryKvs;       # Master key-value store, holds all read-in entries
my %catTotal;       # Integer value of total entries in each category
my $entryId;        # Entry-id variable of current working entry, used for reads
my %opts;           # CLI flags + args
my %uc;             # Contents of default or specified conf.pl
my @cats;           # Array of categories
my @knownKeys;      # List of known keys for each entry
my @necessaryKeys;  # RSRU will fail if any of these keys are missing in an entry

my $tplTop;         # The 'top' half of the per-category template
my $tplBottom;      # The 'bottom' half of the same. Entries will go between
my $tplEntry;       # The blank HTML for each entry
my $tplEntryImg;    # The blank HTML for each entry, with space for thumbnails
my $tplCatTab;      # Blank HTML for each category
my $tplHp;          # Blank HTML for homepage
my $tplHpEntry;     # Blank HTML for entries on the homepage
my $tplNav;         # Blank HTML for nav section
my $tplRssBlockTop; # Blank HTML for RSS block - top
my $tplRssBlockBottom;      # Blank HTML for RSS block - bottom

my $writtenOut = 0; # A count of written out files.
my $writtenEntries = 0;     # total count of written entries in all files
my $baseURL = '.';  # Relative is default
my @imgDirList;     # Listing of everything in source image dir
my $imgBasePath;    # Base path for "img src=" in output files
my $imgOutDir;      # Concatenation of root output dir + user image output dir

# Consts
my $DATE_FORMAT = "%Y-%m-%d";
my $MAX_CATS = 8;
my $MIN_ENTRIES = 2;
my $MAX_ENTRIES = 5;
my $YES = 'yes';
my $NO_SUMMARY = '';
my $TPL_EMPTY_CAT = "<h1>Notice</h1><p>This category is currently empty. Finely-curated entries are forthcoming!</p>";
my @EXTLIST = qw(jpg jpeg png JPEG PNG);
my $DEFAULT_CONF = "conf.pl";
my $RELEASE = "RSRU Release 3, (C) 2022 Thransoft.\nThis is Free Software, licenced to you under the terms of the GNU GPL v3.";
my $BANNER = <<"EOF";
$RELEASE
RSRU: Really Small, Really Useful. 
A static website weaver.

Usage:
-h : Show this message
-p : Use Productuion mode (uses Live URL as basepath)
-r : Rebuild. Will ignore no-clobber and recreates all outfiles (including images).
-c <conf> : Use this conf file
-o <dir> : Use this output directory
-v : Show version

Call with no args, RSRU will read in conf.pl and build a website.
EOF

# Declare some fn prototypes
sub sort_entries;
sub sort_all_entries;
sub get_highlighted_entries;

# Useful Helper Function.
# ARGUMENTS: Filename to be read in. RETURNS: Contents of file as string.
sub read_whole_file {
    my $fileName = shift;
    my $fileContent;
    open(my $fh, "$fileName") or die ("Fatal: couldn't open $fileName!");
    $fileContent .= $_ while <$fh>;
    close $fh;
    return $fileContent;
}

# Check template dir for file, if exists read it. If not, check common template dir
# and read it. If neither exists, fail. 
# ARGUMENTS: template file name
sub read_template_file {
    my $tplFn = shift;
    my $tplincFilepath = "$uc{tplinc}/$tplFn";
    my $tplCommonFilepath = "$uc{tplRoot}/common/$tplFn";
    if ( -f $tplincFilepath ) {
        return read_whole_file $tplincFilepath;
    } elsif ( -f $tplCommonFilepath ) {
        return read_whole_file $tplCommonFilepath;
    } else {
        die "Could not open template file $tplFn, aborting!";
    }
}

# Arguments: the directory to list. Returns: ref to the directory contents as an array
sub list_dir {
    my $dirName = shift;
    my @dirContents;

    say "Listing $dirName" if $uc{debug};
    opendir(my $DIR, "$dirName") or die "Problem opening $dirName: $!."; 
    # Read in dir contents, exclude dotfiles
    @dirContents = grep !/^\./, readdir $DIR;
    closedir $DIR;

    return \@dirContents;
}

# Arguments: two arrays refs, walk these and return the first entry that is in both
# TODO: Is there an easier or more performant way to do this??
sub get_first {
    my ($ar1, $ar2) = @_;
    for my $idx ( @{$ar1} ) {
        for my $idy ( @{$ar2} ) {
            return $idx if $idx eq $idy;
        }
    }
    return 0;
}

# Dump everything we've gathered into our KVS to stdout, format nicely. Intended for verbose mode.
sub dump_kvs {
    print "Dumping contents of entry KVS. All keys read in: ";
    print (keys %entryKvs, "\n");

    while (my ($entryId, $hashRef) = each (%entryKvs)) {
        say "EID: $entryId" if $uc{debug};
        while (my ($key, $val) = each (%$hashRef)) {
            say "KEY: $key. VAL: $val";
        }
    }
}

# Read in the template, look for the RSRU markers, split it.
sub read_partition_template {
    my $baseTpl = -f "$uc{tplinc}/$uc{tpl}" ? "$uc{tplinc}/$uc{tpl}" : "$uc{tplRoot}/common/$uc{tpl}";
    open(my $TPL, "$baseTpl") or die ("Fatal: Couldn't open template $baseTpl!");
    
    while (<$TPL>) {
        last if /\s*(<!--BEGIN RSRU-->)/;
        $tplTop .= $_;
    }

    # Skip everything that isn't for the "easel" area
    while (<$TPL>) { last if /\s*(<!--END RSRU-->)/; }

    # Then read the rest
    while (<$TPL>) { $tplBottom .= $_; }
    close $TPL;
}


# Check, does img_src exist under image dir? if so, use it. Otherwise look for
# $entryId.jpg/png and return it instead. If neither exists return blank (evals to false)
# ARGS: EntryID
sub get_image_filename {
    my $entryId = shift;
    my (@possibleFns, $fileSpecMatch);
    
    # return file extension and filename

    my $imgFn = $entryKvs{$entryId}{img_src};
    if ($imgFn && -f "$uc{imgSrcDir}/$imgFn") {
        return $imgFn;
    } else {
        @possibleFns = map { "${entryId}.$_" } @EXTLIST;
        $fileSpecMatch = get_first (\@imgDirList, \@possibleFns);

        if ($fileSpecMatch) {
            say "Img filename $fileSpecMatch found for $entryId" if $uc{verbose};
            return $fileSpecMatch;
        } else {
            say "No image filename found for $entryId" if $uc{verbose};
            return "";
        }
    }
}

# Make thumbnail and large image for each filename, use same img filename in dest dir
# Args: Entry filename, entryID. Will determine format from extension
# TODO: this could certainly be optimised
sub process_entry_image {
    my ($imgFn, $entryId) = @_;

    my ($gd, $gdOut, $imgFh, $tnFh, $imgPath, $imgFullFn, $imgTnPath, $imgTnFn, $imgSrcPath);
    my ($imgFnOut, $imgExt) = split(/\./, $imgFn, 2); # get filename and format
    my ($w, $l) = split(/x/, $uc{thumbnailSize}, 2);
    my ($srcX, $srcY, $tnExists, $imgExists, $existentImgPath);
    
    $imgPath = "${imgOutDir}/${imgFn}";
    $imgSrcPath = "$uc{imgSrcDir}/${imgFn}";
    $imgTnFn = "${imgFnOut}_tn.jpg"; # thumbnail is always jpg
    $imgTnPath = "${imgOutDir}/${imgTnFn}";

    # Assume just lowercase jpg files for now when checking for existence
    $imgExists = (-f $imgPath or -f "${imgOutDir}/${imgFnOut}.jpg");
    if (-f $imgPath) {
        $existentImgPath = "$imgFn";
        $imgExists = 1;
    } elsif (-f "${imgOutDir}/${imgFnOut}.jpg") {
        $existentImgPath = "${imgFnOut}.jpg";
    };
    $tnExists = (-f $imgTnPath);

    if ($imgExists && $tnExists && $uc{noClobberImg}) {
        say "Image file $imgPath and thumbnail $imgTnPath already exists, skipping..." if $uc{verbose};
        $entryKvs{$entryId}{img_tn} = $imgTnFn;
        $entryKvs{$entryId}{img_full} = "$existentImgPath";
        return;
    }

    say "ImgFn=$imgFn, ImgFnOut=$imgFnOut, ImgExt=$imgExt TnSz=$uc{thumbnailSize}" if $uc{debug};
    open $imgFh, "<", "$imgSrcPath" or warn "Could not open $imgPath: $!";

    $gdOut = GD::Image->new($w,$l);

    say "Opening $imgPath..." if $uc{debug};

    if (first { /$imgExt/ } ("jpeg", "jpg", "JPG", "JPEG")) {
        $imgExt = "jpg";
        warn "Invalid JPEG in $imgPath" unless 
            $gd = GD::Image->newFromJpeg($imgFh);
    } elsif (first { /$imgExt/ } ("png", "PNG")) {
        $imgExt = "png";
        warn "Invalid PNG in $imgPath" unless 
            $gd = GD::Image->newFromPng($imgFh);
    } else {
        warn "$imgPath is not supported.";
        return;
    }
    
    # TODO: make square
    $srcX = 0;
    $srcY = 0;
    $gdOut->copyResampled($gd,0,0,$srcX,$srcY,$w,$l,$gd->width,$gd->height);

    # Write thumbnail (always jpeg!)
    say "Writing thumbnail to $imgTnPath" if $uc{verbose};
    open $tnFh, ">", "$imgTnPath" or warn "Could not open $imgTnPath: $!";
    binmode $tnFh;
    print $tnFh $gdOut->jpeg(80) or warn "Couldn't write $imgFn!";
    $entryKvs{$entryId}{img_tn} = $imgTnFn;

    if ($uc{imgToJpeg} && $imgExt eq "png") {
        $imgFullFn = "${imgFnOut}.jpg";
        $imgPath = "${imgOutDir}/$imgFullFn";
        open my $imgFhFullRes, ">", $imgPath or warn "Could not open $imgPath: $!";
        binmode $imgFhFullRes;
        print $imgFhFullRes $gd->jpeg(70) or warn "Couldn't write $imgFn!";
        close $imgFhFullRes;
        $entryKvs{$entryId}{img_full} = $imgFullFn;
    } else {
        # Copy original image (TODO: later may support resizing)
        $imgFullFn = "${imgFnOut}.$imgExt";
        say "Copying fullres to $imgPath" if $uc{verbose};
        copy ($imgSrcPath, $imgPath);
        $entryKvs{$entryId}{img_full} = $imgFullFn;
    }
    close $imgFh;
    close $tnFh;
}

# Iterate through an entry and ensure all the specified necessary (necified?)
# keys are present. Failure stops everything!
# ARGS: Entry ID
sub verify_necessary_keys {
    my $entryId = shift;
    foreach my $key (@necessaryKeys){
        die "Key $key missing from $entryId.txt; please add $key: <value> to the entry file!" 
            unless (first { /$key/ } keys %{$entryKvs{$entryId}});
    }
}

# Takes a key and prints the HTML for its contents
# ARGUMENTS: Entry ID
# RETURNS: Scalar reference to woven template
sub entrykvs_to_html {
    my $entryId = shift;
    my $filledEntry;
    my ($localImgPath, $imgSrc);
    my $wasHighlight = 0;
    
    verify_necessary_keys ($entryId);

    # If image file exists, assign entry template with image field and prepare
    # the image files, otherwise use text-only tplEntry
    if ($uc{imagesEnabled} and ($localImgPath = get_image_filename($entryId))) {
        $filledEntry = $tplEntryImg;
        process_entry_image($localImgPath, $entryId);
        $filledEntry =~ s/{% img_tn %}/${imgBasePath}\/$entryKvs{$entryId}{img_tn}/g;
        $filledEntry =~ s/{% img_full %}/${imgBasePath}\/$entryKvs{$entryId}{img_full}/g;
        my $imgDesc = defined $entryKvs{$entryId}{img_desc} ? $entryKvs{$entryId}{img_desc} : "";
        $filledEntry =~ s/{% img_desc %}/$imgDesc/g;
    } else {
        $filledEntry = $tplEntry;
    }
    
    # Find and replace, boys. Find and replace.
    foreach my $key (@knownKeys) {
        if ($key eq "date") {
            my $date = $entryKvs{$entryId}{'date'}->strftime('%d/%m/%Y');
            $filledEntry =~ s/{% $key %}/$date/g;
        } elsif ($key eq "is_highlight" && defined $entryKvs{$entryId}{is_highlight} && $entryKvs{$entryId}{is_highlight} eq $YES) {
            $filledEntry =~ s/{% IS_HIGHLIGHT %}/highlight/g;
            $wasHighlight = 1;
        } else {
            $filledEntry =~ s/{% $key %}/$entryKvs{$entryId}{$key}/g;
        }
    }
    $filledEntry =~ s/{% IS_HIGHLIGHT %}//g unless $wasHighlight;

    # Do anchor for links from elsewhere. Anchor is currently entry Id (key in %entryKvs)
    $filledEntry =~ s/{% KEY %}/$entryId/g;

#    say "Filled $entryId:\n$filledEntry" if ($uc{debug});
    $writtenEntries++;
    return \$filledEntry;
}

# Clear destination before write (configurable)
sub clear_dest {
    say "clear_dest: wiping $uc{out}..." if ($uc{verbose});
    remove_tree("$uc{out}");
    warn "Problem clearing output dir ($uc{out}): $!" if $!;
}

# Copy any resources to outdir. 
sub copy_res {
    for my $file (glob "$uc{tplinc}/static/*") {
        copy($file,"$uc{out}/") or die ("Problem copying $file to $uc{out}.");
    }
}

# Insert title and description to master template top
sub paint_desc {
    $tplTop =~ s/{% HEAD_TITLE %}/$uc{siteName}/;
    $tplTop =~ s/{% HEAD_DESC %}/$uc{siteHeaderDesc}/;
}

# Make link bar for the top of each page
sub generate_cat_tabs {
    my $activeCat = shift;
    my $catFn; # Cat Filename (used for hyperlinks)
    my $cwCat;  # Current Working Category
    my $filledCats; # Tabs of categories, eventually filled

    # Handle relative paths (overwrite global var)
    my $baseURL = ($baseURL eq ".") && ($activeCat ne "index") ? ".." : $baseURL;

    # handle special case of index.html
    $catFn = "$baseURL/index.html";
    $cwCat = $tplCatTab;
    $cwCat =~ s/{% CAT_NAME %}/home/;
    $cwCat =~ s/{% CAT_URL %}/$catFn/;
    if ($activeCat eq 'index'){
        $cwCat =~ s/{% IS_ACTIVE %}/active/;
    } 
    $filledCats .= $cwCat;

    # Now fill in the category tabs
    foreach my $cat (@cats) {
        $catFn = "${baseURL}/${cat}/index.html";
        $cwCat = $tplCatTab;
        $cwCat =~ s/{% CAT_NAME %}/$cat/;
        $cwCat =~ s/{% CAT_URL %}/$catFn/;
        # Remove IS_ACTIVE from home tab
        $filledCats =~ s/{% IS_ACTIVE %}//;
        # Set only the active cat to have the HTML class "active"
        if ($cat eq $activeCat) {
            $cwCat =~ s/{% IS_ACTIVE %}/active/;
        }  else {
            $cwCat =~ s/{% IS_ACTIVE %}//;
        }
        $filledCats .= $cwCat;
    }
    return $filledCats;
}

# Calculate the max page index for a category
# Note: This will be easier once entryKvs is restructured
# ARGS: Cat name
# RETURNS: Max page index
sub calculate_max_page {
    my $catName = shift;
    my $maxPage = 0;

    # For empty cats, return 1
    return 1 unless $catTotal{$catName};
    use integer;
    $maxPage = ($catTotal{$catName} / $uc{maxPerPage}); 
    # Handle case of odd/even total entries
    return ($catTotal{$catName} % $uc{maxPerPage}) ? $maxPage + 1 : $maxPage;
}

# Prepare the navbar.
# Arguments: Cat Name, Current Index, isLast
# Returns: prepared navbar HTML
sub prep_navbar {
    my ($catName, $pgIdx, $isLast) = @_;
    my $cwNavbar = $tplNav;
    my %url;
    my ($max, $next);

    my $prev = $pgIdx - 1;
    my $baseURL = $baseURL eq "." ? ".." : $baseURL;

    $max = calculate_max_page($catName);
    say "Max page for $catName is $max" if $uc{debug};

    if ($max == 1) {
        $url{max} = "$baseURL/${catName}/index.html";
    } else {
        $url{max} = "$baseURL/${catName}/$max.html";
    }

    if ($pgIdx == 1) {
        $url{prev} = "#"     
    } elsif ($pgIdx  == 2){
        $url{prev} = "$baseURL/${catName}/index.html";
    } else {
        $url{prev} = "$baseURL/${catName}/$prev.html";
    }

    if ($isLast eq 'no'){
        $next = $pgIdx + 1;
        $url{next} = "$baseURL/${catName}/$next.html";
    } else {
        $url{next} = "#";
    }

    say "Generated previous=$prev, next=$next" if $uc{debug};

    $cwNavbar =~ s/{% IDX_PREV %}/$url{prev}/;
    $cwNavbar =~ s/{% IDX_NEXT %}/$url{next}/;
    $cwNavbar =~ s/{% IDX %}/$pgIdx/;
    $cwNavbar =~ s/{% MAX %}/$max/;
    $cwNavbar =~ s/{% MAX_URL %}/$url{max}/;
    return $cwNavbar;
}

# Insert the cat links. called by paint_template when it is used to process
# each category page.
# ARGUMENTS: active cat, page number
sub prep_tpltop {
    my ($activeCat, $pgIdx) = @_; 
    my $pageTxt = "";
    $pageTxt = "(Page $pgIdx)" if $pgIdx;
    my $catTabs = generate_cat_tabs($activeCat);
    my $cwTplTop = $tplTop;
    my $staticRoot = ($baseURL eq ".") && ($activeCat ne "index") ? ".." : $baseURL;
    $cwTplTop =~ s/{% RSRU_TITLE %}/$uc{siteName} :: $activeCat $pageTxt/;
    $cwTplTop =~  s/{% RSRU_CATS %}/$catTabs/;
    $cwTplTop =~  s/{% STATIC_ROOT %}/$staticRoot/g;

    # Handle RSS feeds
    if ($uc{rssEnabled}) {
        $cwTplTop =~ s/{% FEEDBLOCK_TOP %}/$tplRssBlockTop/;
        $cwTplTop =~ s/{% RSRU_FEED %}/$staticRoot\/$uc{rssFilepath}/;
        $cwTplTop =~ s/{% RSRU_TITLE %}/$uc{siteName}/;
    } else {
        $cwTplTop =~ s/{% FEEDBLOCK_TOP %}//;
    }
    return $cwTplTop;
}

# Works on global tplBottom (it doesn't vary for category or page)
# Appends RSS link, if configured
sub prep_tplbottom {
    # Handle RSS feeds
    my $rssPath = "${baseURL}/$uc{rssFilepath}";
    if ($uc{rssEnabled}) {
        $tplBottom =~ s/{% FEEDBLOCK_BOTTOM %}/$tplRssBlockBottom/;
        $tplBottom =~ s/{% RSRU_FEED %}/$rssPath/;
    } else {
        $tplBottom =~ s/{% FEEDBLOCK_BOTTOM %}//;
    }
    # QnD method to get static files into the footer. Will be invalid
    # for pages below root in non-production mode. FIXME.
    $tplBottom =~  s/{% STATIC_ROOT %}/${baseURL}/;
}

# Print gathered entries into our template files. Do one for each cat.
# ARGUMENTS: Cat name
sub paint_template {
    my $catName = shift;
    my $currentEntry;
    my $pgIdx = 1;
    my $cwTplTop = prep_tpltop($catName, $pgIdx); 
    my $catIsEmpty = 1;
    my $currentPgIdx = 0;

    # assume index, make new page if we exceed maxPerPage
    my $outFn = "${catName}/index.html";
    my $navBar;

    open (my $fh, '>', "$uc{out}/$outFn");
    print $fh $cwTplTop;

    print $fh "<p id=\"catDesc\">"; 
    print $fh "$uc{catDesc}{$catName}" if (defined $uc{catDesc}{$catName} && $pgIdx == 1);
    print $fh "<span id=\"catTotal\">($catTotal{$catName} total)</span>" if ($uc{showCatTotal} && defined $catTotal{$catName} && $catTotal{$catName} > 0);
    print $fh "</p>"; 

    for my $entryId (sort_entries $catName) {
        # Handle pagination
        if ($currentPgIdx >= $uc{maxPerPage}) {
            print $fh prep_navbar($catName, $pgIdx, 'no');
            print $fh $tplBottom; 
            $pgIdx++;
            $outFn = "${catName}/${pgIdx}.html";
            close $fh;
            open ($fh, '>', "$uc{out}/$outFn");
            print $fh prep_tpltop($catName, $pgIdx); 
            say "NEW PAGE!! $pgIdx" if $uc{debug};
            $writtenOut++;
            $currentPgIdx = 0;
        }
        $entryKvs{$entryId}{path} = $outFn;
        $currentEntry = entrykvs_to_html $entryId;
        $catIsEmpty = 0;
        $currentPgIdx++;
        print $fh $$currentEntry;
    }
    
    print $fh $TPL_EMPTY_CAT if $catIsEmpty;
    
    print $fh prep_navbar($catName, $pgIdx, 'yes');
    print $fh $tplBottom;
    # Increment grand total for reporting files written after process completes
    $writtenOut++;
    close $fh;
}

# make a category path for each category that exists
sub make_category_dirs {
    if ($uc{debug}) {
        say "will create dir $uc{out}/$_" for (@cats);
    }
    make_path "$uc{out}/$_" for (@cats);
}

# Use the $tplHpEntry template to generate a list of entries for the homepage.
# ARGUMENTS: An array of entry key names
sub generate_entries_hp {
    my $hpEntries = "";
    my ($cwHpEntry, $catFn, $cat, $date);

    for my $entry (@_) {
       $cwHpEntry = $tplHpEntry;
       $cwHpEntry =~ s/{% ENTRY_NAME %}/$entryKvs{$entry}{title}/;
       if ($entryKvs{$entry}{summary}) {
           $cwHpEntry =~ s/{% ENTRY_DESC %}/$entryKvs{$entry}{summary}/;
       } else {
            say "No summary found for $entry; its summary will be omitted on homepage." if $uc{verbose};
            $cwHpEntry =~ s/{% ENTRY_DESC %}/$NO_SUMMARY/;
       }
       $cat = $entryKvs{$entry}{category};
       $cwHpEntry =~ s/{% ENTRY_CAT %}/$cat/;
       $date = $entryKvs{$entry}{date}->strftime('%d/%m/%Y');
       $cwHpEntry =~ s/{% ENTRY_DATE %}/$date/;
       $catFn = "${baseURL}/$entryKvs{$entry}{path}#$entry";
       $cwHpEntry =~ s/{% ENTRY_CAT_URL %}/$catFn/;
       $hpEntries .= $cwHpEntry;
    }
    return $hpEntries;
}

# Print the homepage. ARGS: None.
sub paint_homepage {
    my $outFn = "$uc{out}/index.html";
    
    my $cwTplTop = prep_tpltop('index'); 
    my (@latest, @highlights);

    open (my $fh, '>', $outFn) or die ("Fatal: Couldn't open $uc{out}Fn for writing!");
    print $fh $cwTplTop;
        
    $tplHp =~ s/{% RSRU_HPHD %}/$uc{siteHomepageHeader}/;
    $tplHp =~ s/{% RSRU_HPDESC %}/$uc{siteHomepageDesc}/;
    $tplHp .= "<p>Current total entries: " . scalar %entryKvs . "</p>";

    print $fh $tplHp;
    my $totalEntries = scalar (%entryKvs);

    if ( $totalEntries >= $MIN_ENTRIES ){
        my $max = ($totalEntries < $MAX_ENTRIES) ? $totalEntries : $MAX_ENTRIES;
        @latest = sort_all_entries($totalEntries); 
        print $fh '<h2>Latest Entries</h2>';
        print $fh generate_entries_hp(@latest);
    } else {
        say "Total entries are below $MIN_ENTRIES. Skipping latest on homepage.";
    }
    
    @highlights = get_highlighted_entries; 
    if (@highlights) {
        print $fh '<h2>Highlights</h2>';
        print $fh generate_entries_hp(@highlights);
    }
    print $fh $tplBottom; 
    $writtenOut++;
    close $fh;
}


# Sort the given cat's entries. TODO sort order: DATE > RANK > ENTRY_NAME, currently only DATE, ENTRY NAME.
# Argument: Cat name. [If not supplied, sort ALL entries by date]
# Returns: A list that consists of ordered entry IDs for each cat
sub sort_entries {
    my $cwCat = shift;
    my %entryDate;

    for my $entryId (keys %entryKvs) {
        if ($entryKvs{$entryId}{"category"} eq $cwCat) {
           $entryDate{$entryId} = $entryKvs{$entryId}{"date"};
        } 
    }

    # First sort alphabetically, then by date
    my @sorted = sort keys %entryDate;
    @sorted = sort { $entryDate{$b} <=> $entryDate{$a} } @sorted;

    say "SORTED: @sorted, Length: ". scalar @sorted . " " if $uc{debug};
    return @sorted;
}

# Do the same as above but with no heed to each category. Just returns a list
# of all entries sorted by date.
# ARGUMENTS: max index
sub sort_all_entries {
    my $max = shift;
    my %entryDate;
    for my $entry (keys %entryKvs) {
        say "entry $entry and $entryKvs{$entry}{'date'}" if $uc{debug};
        $entryDate{$entry} = $entryKvs{$entry}{"date"};
    }
    # First sort alphabetically, then by date
    my @sorted = sort keys %entryDate;
    @sorted = sort { $entryDate{$b} <=> $entryDate{$a} } @sorted;
    say "Sorted are @sorted." if $uc{debug};
    return @sorted[0..$max-1];
}

sub get_highlighted_entries {
    my @highlights;

    foreach (keys %entryKvs) {
        last if (scalar @highlights ge $uc{maxHpHighlights});
        next unless ($entryKvs{$_}{is_highlight});
        push (@highlights, $_) if ($entryKvs{$_}{is_highlight} eq $YES);
    }
    return @highlights;
}

# Read the contents of an individual entry file. Entryfiles are plain text and in
# a simple format. See 'samplesoft1.txt' for an example.
# Argument: Entry ID (equivalent to the name of its text file)
# Returns a reference to a key-value store of all obtained key-values from the entryfile.
sub read_entry {
    $entryId = shift;
    open (my $ENTRY, '<', "$uc{entrydir}/$entryId") or die "Couldn't open $uc{entrydir}/$entryId";
    $entryId =~ s/\.txt//;

    my %entryData;
    while (<$ENTRY>) {
        # Skip comments (hash-commenced lines)
        next if /^#/;
        # Lines commencing with single words, colon-terminated are a key, lines without are descriptions
        if (/^\S+:/) {
            chomp;
            # Watch for URLs! spilt will split at each colon it finds, unless restrained as such:
            my ($key, $val) = split /:\s+/; 
            if ($key eq "date"){
                $entryData{"date"} = Time::Piece->strptime($val, $DATE_FORMAT); 
                next;
            } elsif ($key eq "category"){
                unless ( first { /$val/ } @cats ){
                    say "New category found: $val." if $uc{verbose};
                    push (@cats, $val);
                }
                $catTotal{$val}++;
            }
            $entryData{$key} = $val;
            print "KEY: $key VALUE: $val\n" if ($uc{debug});
        } else {
            # $_ means current line... '_' looks like a line
            $entryData{desc} .= $_;
        }
    }
    say "$entryId DESC: $entryData{desc}" if ($uc{debug});
    close $ENTRY;

    return \%entryData;
}

# Read in the contents of the entrydir. Calls read_entry
# on each text file therein. We will use this to fill our
# entryKvs.
sub read_entrydir {
    my @entries = @{ list_dir($uc{entrydir}) };
    say "Entrydir listing: @entries" if ($uc{debug});

    # $entryID is assigned inside read_entry
    $entryKvs{$entryId} = read_entry $_ for @entries;
    print (keys %entryKvs, " Keys in entrykvs. $entryId (last read)\n") if ($uc{debug});
    print (values %entryKvs, " values in entrykvs.\n") if ($uc{debug});
    dump_kvs if ($uc{debug});
}

# Write the latest amount of entries, as configured, to a RSS 2.0 file
# Requires all pages to be written first, so that pgIdx is correctly set for each entry
sub write_rss {
    return unless $has_rss;
    my $t = Time::Piece->new;
    my $buildDate = $t->strftime();
    my $entryMax;

    if ((scalar %entryKvs) > $uc{rssEntryMax}) {
        $entryMax = $uc{rssEntryMax};
    } else {
        $entryMax = (scalar %entryKvs);
    }

    my @sortedEntryKeys = sort_all_entries($entryMax);
    my $rss = XML::RSS->new (version => '2.0', encode_output=>1);

    $rss->channel(
        title          => $uc{siteName},
        link           => $uc{liveURL},
        language       => $uc{rssLang},
        description    => $uc{siteHomepageDesc},
        copyright      => $uc{rssCopyright},
        lastBuildDate  => $buildDate,
    );

    foreach my $entry (@sortedEntryKeys) {
        # it isn't a permalink (yet)
        my $flimsyLink = "$uc{liveURL}/$entryKvs{$entry}{path}#$entry";
        my $href = "<a href=\"$flimsyLink\" target=\"_blank\">View $entryKvs{$entry}{title} on $uc{siteName}.</a>";
        $rss->add_item(
            title => $entryKvs{$entry}{title},
            link  => $flimsyLink,
            description => "$entryKvs{$entry}{desc}\n$href",
            category => [ $entryKvs{$entry}{category} ],
            pubDate => $entryKvs{$entry}{date}->strftime(),
        );
    }

    $rss->save( "$uc{out}/$uc{rssFilepath}" );
}

#===============================================================================
# End Fndefs, begin exec.
#===============================================================================

# Handle user flags, if any
getopts('c:vhpro:', \%opts);

if (defined $opts{h}) { say $BANNER; exit; }
if (defined $opts{v}) { say $RELEASE; exit; }

print "RSRU starting. ";

# Read in user-configurable values
my $conf = (defined $opts{c} ? $opts{c} : $DEFAULT_CONF);
say "Using config file: $conf";
my $cwd = getcwd;
%uc = do ("$cwd/$conf");
die "Problem reading config file $conf, cannot continue." unless $uc{tpl};

# Copy cats list from the user conf and make it a mutable array.
@cats = @{$uc{cats}};
# Assign other vals from user conf
@knownKeys = @{$uc{knownKeys}};
@necessaryKeys = @{$uc{necessaryKeys}};

# If rebuild is yes
if (defined $opts{r}) { 
    $uc{noClobberImg} = 0;
    $uc{clearDest} = 1;
 }

if ((defined $opts{p}) or $uc{target} eq 'production') {
    $baseURL = $uc{liveURL};
    $uc{target} = 'production';
    say "Production mode configured, base URL: $baseURL";
}

$uc{out} = $opts{o} if (defined $opts{o}); 

# Check we have the appropriate module installed for imaging
if ($uc{imagesEnabled} && !$has_gd) {
    warn "!! Images configured but GD is not installed. Please run 'cpan install GD' !!";
    $uc{imagesEnabled} = 0;
}

$imgOutDir = "$uc{out}/$uc{imgDestDir}/";

if ($uc{target} eq "production") {
    $imgBasePath = "${baseURL}/$uc{imgDestDir}";
} else {
    $imgBasePath = "${baseURL}/../$uc{imgDestDir}";
}

#===============================================================================
# Check we have what's needed, then get to work
#===============================================================================
say "==> Begin read of $uc{entrydir} contents ==>";
read_entrydir;
say "Categories read: @cats" if ($uc{debug});

warn "Image destination directory $uc{imgDestDir} matches a category name. This may lead to conflicts."
    if first { /$uc{imgDestDir}/ } @cats;

warn "Warning: More than $MAX_CATS exist in file. Template may be malformed.\n" if (scalar (@cats) > $MAX_CATS);
say "<== Read Finished <==";

say "==> Begin read of template files ==>";
read_partition_template;
# Load in blank HTML for homepage items. Fills the global vars tplHp and tplHpEntry.
$tplHp = read_template_file($uc{blankTplHp});
$tplHpEntry = read_template_file($uc{blankTplHpEntry});
$tplNav = read_template_file($uc{blankTplNav});
# Load in the HTML for each category in the catbar
$tplCatTab = read_template_file($uc{blankCatEntry});
$tplRssBlockTop = read_template_file($uc{rssBlockTop});
$tplRssBlockBottom = read_template_file($uc{rssBlockBottom});
# Now load in our entry template file. This should be a HTML table with the appropriate areas for our data marked out
$tplEntryImg = read_template_file($uc{blankEntryImg});
$tplEntry = read_template_file($uc{blankEntry});

@imgDirList = @{list_dir($uc{imgSrcDir})} if $uc{imagesEnabled};

say "<== Read Finished <==";

say "<== Begin template interpolation... ==>";
clear_dest if ($uc{clearDest});
mkdir $uc{out} unless -d $uc{out};
mkdir "$uc{out}/$uc{imgDestDir}" unless -d "$uc{out}/$uc{imgDestDir}";
copy_res;
make_category_dirs;
prep_tplbottom;
paint_desc;
foreach my $cat (@cats) { paint_template $cat; }
paint_homepage;
say "<== Template interpolation finished. ==>";

if ($uc{rssEnabled} && !$has_rss) {
    warn "!! RSS configured but XML::RSS is not installed !!\n!! Please run 'cpan install XML::RSS' to enable RSS output !!";
    $uc{rssEnabled} = 0;
}
if ($uc{rssEnabled}){
    say "==> Writing RSS 2.0 feed to $uc{rssFilepath}. ==>";
    write_rss;
    say "<== RSS composition complete. ==>";
}
say "RSRU complete. Wrote $writtenEntries total entries into $writtenOut files.";
