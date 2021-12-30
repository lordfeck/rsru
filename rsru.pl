#!/usr/bin/env perl

#===============================================================================
# Thransoft RSRU Release 3
# A static catalogue-style website generator, freely given
# Licence: GPLv3. See "licence.txt" for full details.
# Author: Thran. Authored: 09/09/2020 - 27/11/2021
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
use List::Util qw(first);
use Cwd qw(getcwd);

#===============================================================================
# Load optional modules if available
#===============================================================================
my $has_rss = eval
{
    require XML::RSS;
    XML::RSS->import();
    1;
};

#===============================================================================
# Read in user-configurable values
#===============================================================================

my %uc = do getcwd . "/conf.pl";
die 'Problem reading config' if $!;
# Copy cats list from the user conf and make it a mutable array.
my @cats = @{$uc{cats}};

#===============================================================================
# End usr config, begin function defs and global vars.
#===============================================================================
my %entryKvs;       # Master key-value store, holds all read-in entries
my $entryId;        # Entry-id variable of current working entry, used for reads

my $tplTop;         # The 'top' half of the per-category template
my $tplBottom;      # The 'bottom' half of the same. Entries will go between
my $tplEntry;       # The blank HTML for each entry
my $tplCatTab;      # Blank HTML for each category
my $tplHp;          # Blank HTML for homepage
my $tplHpEntry;     # Blank HTML for entries on the homepage
my $tplNav;         # Blank HTML for nav section
my $tplRssBlockTop; # Blank HTML for RSS block - top
my $tplRssBlockBottom;      # Blank HTML for RSS block - bottom

my %catsFilledEntries;      # Hash of filled entries in HTML for each category
my $writtenOut = 0; # A count of written out files.
my $writtenEntries = 0;     # total count of written entries in all files
my $baseURL = '.';  # Relative is default

# Consts
my $DATE_FORMAT = "%Y-%m-%d";
my $MAX_CATS = 8;
my $MIN_ENTRIES = 5;
my $MAX_ENTRIES = 5;
my $YES = 'yes';
my $NO_SUMMARY = '';
my $TPL_EMPTY_CAT = "<h1>Notice</h1><p>This category is currently empty. Finely-curated entries are forthcoming!</p>";

# List of known keys for each entry
my @knownKeys = @{$uc{knownKeys}};
my @necessaryKeys = @{$uc{necessaryKeys}};

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
    open(my $TPL, $uc{tpl}) or die ("Fatal: Couldn't open template $uc{tpl}!");
    
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

# Iterate through an entry and ensure all the specified necessary (necified?)
# keys are present. Failure stops everything!
# ARGS: Entry ID
sub verify_necessary_keys {
    my $entryId = shift;
    foreach my $key (@necessaryKeys){
        die "Key $key missing from $entryId.txt; please add $key: <value> to the entry file!" unless (first { /$key/ } keys %{$entryKvs{$entryId}});
    }
}

# Takes a key and prints the HTML for its contents
# ARGUMENTS: Entry ID
# RETURNS: Scalar reference to woven template
sub entrykvs_to_html {
    my $entryId = shift;
    my $filledEntry = $tplEntry;
    
    verify_necessary_keys ($entryId);

    # Find and replace, boys. Find and replace.
    foreach my $key (@knownKeys) {
        if ($key eq "date") {
            my $date = $entryKvs{$entryId}{'date'}->strftime('%d/%m/%Y');
            $filledEntry =~ s/{% $key %}/$date/g;
        } else {
            $filledEntry =~ s/{% $key %}/$entryKvs{$entryId}{$key}/g;
        }
    }
    # Do anchor for links from elsewhere. Anchor is currently entry Id (key in %entryKvs)
    $filledEntry =~ s/{% KEY %}/$entryId/g;
    
    say "Filled $entryId:\n$filledEntry" if ($uc{debug});
    $writtenEntries++;
    return \$filledEntry;
}

# Clear destination before write (configurable)
sub clear_dest {
    say "clear_dest: Removing $uc{out}..." if ($uc{debug});
    remove_tree("$uc{out}");
    warn "Problem clearing output dir ($uc{out}): $!" if $!;
}

# Copy any resources to outdir. 
sub copy_res {
    for my $cssFile (glob "$uc{tplinc}/static/*") {
        copy($cssFile,"$uc{out}/") or die ("Problem copying $cssFile to $uc{out}.");
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
    my $catSize = 0;
    foreach (keys %entryKvs){
        $catSize++ if ($entryKvs{$_}{category} eq $catName);
    }
    use integer;
    return ($catSize / $uc{maxPerPage}) + 1; 
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
    if ($max == 1) {
        $url{max} = "$baseURL/${catName}/index.html";
    } else {
        $url{max} = "$baseURL/${catName}/$max.html";
    }

    if ($pgIdx == 1) {
        $url{prev} = "#"     
    } elsif ($prev  == 2){
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
    $cwTplTop =~  s/{% STATIC_ROOT %}/$staticRoot/;

    # Handle RSS feeds
    if ($uc{rss_enabled}) {
        $cwTplTop =~ s/{% FEEDBLOCK_TOP %}/$tplRssBlockTop/;
        $cwTplTop =~ s/{% RSRU_FEED %}/$staticRoot\/$uc{rss_filepath}/;
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
    my $rss_path = "${baseURL}/$uc{rss_filepath}";
    if ($uc{rss_enabled}) {
        $tplBottom =~ s/{% FEEDBLOCK_BOTTOM %}/$tplRssBlockBottom/;
        $tplBottom =~ s/{% RSRU_FEED %}/$rss_path/;
    } else {
        $tplBottom =~ s/{% FEEDBLOCK_BOTTOM %}//;
    }
}

# Print gathered entries into our template files. Do one for each cat.
# ARGUMENTS: Cat name
sub paint_template {
    my $catName = shift;
    my $currentEntry;
    my $pgIdx = 1;
    my $cwTplTop = prep_tpltop($catName, $pgIdx); 
    my $catIsEmpty = 1;

    my $entryIdx = 0;
    my $outFn = "$uc{out}/${catName}/index.html";
    my $navBar;

    open (my $fh, '>', $outFn);
    print $fh $cwTplTop;

    print $fh "<p id=\"catDesc\">$uc{catDesc}{$catName}</p>" if ($uc{catDesc}{$catName} && $pgIdx == 1);

    for my $entryId (sort_entries $catName) {
        say "$entryIdx is entry index. for $entryId" if $uc{debug};
        # Handle pagination
        if ($entryIdx >= $uc{maxPerPage}) {
            print $fh prep_navbar($catName, $pgIdx, 'no');
            print $fh $tplBottom; 
            $pgIdx++;
            $outFn = "$uc{out}/${catName}/${pgIdx}.html";
            close $fh;
            open ($fh, '>', $outFn);
            print $fh prep_tpltop($catName, $pgIdx); 
            say "NEW PAGE!! $pgIdx" if $uc{debug};
            $writtenOut++;
        }
        next unless ($entryKvs{$entryId}{"category"} eq $catName);
        $entryKvs{$entryId}{pgIdx} = $pgIdx;
        $currentEntry = entrykvs_to_html $entryId;
        $catIsEmpty = 0;
        print $fh $$currentEntry;
        $entryIdx++;
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
        
       $cwHpEntry =~ s/{% ENTRY_NAME %}/$entryKvs{$entry}{"title"}/;
       if ($entryKvs{$entry}{'summary'}) {
           $cwHpEntry =~ s/{% ENTRY_DESC %}/$entryKvs{$entry}{'summary'}/;
       } else {
            say "No summary found for $entry; its summary will be omitted on homepage." if $uc{verbose};
            $cwHpEntry =~ s/{% ENTRY_DESC %}/$NO_SUMMARY/;
       }
       $cat = $entryKvs{$entry}{"category"};
       $cwHpEntry =~ s/{% ENTRY_CAT %}/$cat/;
       $date = $entryKvs{$entry}{'date'}->strftime('%d/%m/%Y');
       $cwHpEntry =~ s/{% ENTRY_DATE %}/$date/;
       $catFn = "$baseURL/${cat}/$entryKvs{$entry}{pgIdx}.html#$entry";
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

    if (scalar (%entryKvs) >= $MIN_ENTRIES){
        @latest = sort_all_entries($MAX_ENTRIES); 
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
    opendir(my $ENTRIES, "$uc{entrydir}") or die "Directory of entries not found."; 
    # Read in entries, exclude dotfiles
    my @entries = grep !/^\./, readdir $ENTRIES;
    closedir $ENTRIES;
    say "Entrydir listing: @entries" if ($uc{debug});

    # $entryID is assigned inside read_entry
    $entryKvs{$entryId} = read_entry $_ for @entries;
    print (keys %entryKvs, " Keys in entrykvs. $entryId (last read)\n") if ($uc{debug});
    print (values %entryKvs, " values in entrykvs.\n") if ($uc{debug});
    dump_kvs if ($uc{verbose});
}

# Write the latest amount of entries, as configured, to a RSS 2.0 file
# Requires all pages to be written first, so that pgIdx is correctly set for each entry
sub write_rss {
    return unless $has_rss;
    my $t = Time::Piece->new;
    my $build_date = $t->strftime();
    my $entry_count;

    if ($uc{rss_entry_count} gt (scalar %entryKvs)) {
        $entry_count = $uc{rss_entry_count};
    } else {
        $entry_count = scalar %entryKvs;
    }

    my @sortedEntryKeys = sort_all_entries($entry_count);
    my $rss = XML::RSS->new (version => '2.0');

    $rss->channel(
        title          => $uc{siteName},
        link           => $uc{liveUrl},
        language       => $uc{rss_lang},
        description    => $uc{siteHomepageDesc},
        copyright      => $uc{rss_copyright},
        lastBuildDate  => $build_date,
    );

    foreach my $entry (@sortedEntryKeys) {
        # it isn't a permalink
        my $flimsyLink = "$baseURL/$entryKvs{$entry}{category}/$entryKvs{$entry}{pgIdx}.html#$entry";
        $rss->add_item(
            title => $entryKvs{$entry}{title},
            permaLink  => $flimsyLink,
            description => $entryKvs{$entry}{desc},
            categories => [$entryKvs{$entry}{category}],
            pubDate => $entryKvs{$entry}{date}->strftime(),
        );
    }

    $rss->save("$uc{out}/$uc{rss_filepath}");
}

#===============================================================================
# End Fndefs, begin exec.
#===============================================================================
say "RSRU starting. Master template: $uc{tpl}";

if (scalar @ARGV and ($ARGV[0] eq '-p') or $uc{target} eq 'production') {
    $baseURL = $uc{liveURL};
    say "Production mode configured, base URL: $baseURL";
}

# Check we have what's needed.
die "Template file $uc{tpl} not found, cannot continue." unless -f $uc{tpl};

say "==> Begin read of $uc{entrydir} contents ==>";
read_entrydir;
say "CATS: @cats" if ($uc{debug});
warn "Warning: More than $MAX_CATS exist in file. Template may be malformed.\n" if (scalar (@cats) > $MAX_CATS);
say "<== Read Finished <==";

say "==> Begin read of template files ==>";
read_partition_template;

# Now load in our entry template file. This should be a HTML table with the appropriate areas for our data marked out
$tplEntry = read_whole_file($uc{blankEntry});

# Load in blank HTML for homepage items. Fills the global vars tplHp and tplHpEntry.
$tplHp = read_whole_file($uc{blankTplHp});
$tplHpEntry = read_whole_file($uc{blankTplHpEntry});
$tplNav = read_whole_file($uc{blankTplNav});
# Load in the HTML for each category in the catbar
$tplCatTab = read_whole_file($uc{blankCatEntry});
$tplRssBlockTop = read_whole_file($uc{rssBlockTop});
$tplRssBlockBottom = read_whole_file($uc{rssBlockBottom});
say "<== Read Finished <==";

say "<== Begin template interpolation... ==>";
clear_dest if ($uc{clearDest});
mkdir $uc{out} unless -d $uc{out};
copy_res;
make_category_dirs;
prep_tplbottom;
paint_desc;
foreach my $cat (@cats) { paint_template $cat; }
paint_homepage;
say "<== Template interpolation finished. ==>";
if ($uc{rss_enabled} && !$has_rss) {
    warn "!! RSS configured but XML::RSS is not installed.\nPlease run 'cpan install XML::RSS' to enable RSS output !!";
    $uc{rss_enabled} = 0;
}
if ($uc{rss_enabled}){
    say "==> Writing RSS 2.0 feed to $uc{rss_filepath}. ==>";
    write_rss;
    say "<== RSS composition complete. ==>";
}
say "RSRU complete. Wrote $writtenEntries total entries into $writtenOut files.";
