#!/usr/bin/env perl

#===============================================================================
# Thransoft RSRU
# Collation and generation of software listings for a static software catalogue.
# Licence: GPLv3. See "licence.txt" for full details.
# Author: Thran. Authored: 09/09/2020
#
# With Thanks: https://stackoverflow.com/questions/63835994/
#===============================================================================

use strict;
use warnings;
use v5.10;
use File::Copy;
use Time::Piece;

#===============================================================================
# Begin user-configurable
#===============================================================================
my $tplinc = "./html";
my $entrydir = "./entries";
my $out = "./rsru";
my $tpl = "$tplinc/rsru_template.html";
my $blankEntry = "$tplinc/rsru_entry.html";
my $blankCatEntry = "$tplinc/rsru_cat.html";
my $fnPre = "rsru";
my $siteName = "RSRU";
my $siteHeaderDesc = "Really Small, Really Useful software listings.";
my $siteHomepageDesc = "Lightweight software catalogue.";
my $debug = 0;
my $verbose = 1;
my $clearDest = 1;

# Default cats are always generated, even if empty.
# hitherto unknown cats will be appended to this list if found.
my @cats = ("utility", "media", "sysadmin", "gfx", "dev");

#===============================================================================
# End usr config, begin function defs and global vars.
#===============================================================================
my %entryKvs;       # Master key-value store, holds all read-in entries
my $entryId;        # Entry-id variable of current working entry, used for reads
my $tplTop;         # The 'top' half of the per-category template
my $tplBottom;      # The 'bottom' half of the same. Entries will go between
my $tplEntry;       # The blank HTML for each entry
my $tplCatBar;      # Blank HTML for each category
my $cwTplTop;       # Current working template top (global scope)
my %catsFilledEntries;      # Hash of filled entries in HTML for each category
my $writtenOut = 0; # A count of written out files.

# Consts
my $DATE_FORMAT = "%Y-%m-%d";

# List of known keys for each entry
my @knownKeys = qw(title version category interface img_desc os_support order date desc dl_url);

sub sort_cat;

# Dump everything we've gathered into our KVS to stdout, format nicely. Intended for verbose mode.
sub dump_kvs {
    print "Dumping contents of entry KVS. All keys read in: ";
    print (keys %entryKvs, "\n");

    while (my ($entryId, $hashRef) = each (%entryKvs)) {
        say "EID: $entryId";
        while (my ($key, $val) = each (%$hashRef)) {
            say "KEY: $key. VAL: $val";
        }
    }
}

# Read in the template, look for the RSRU markers, split it.
sub read_partition_template {
    open(TPL, "$tpl") or die ("Fatal: Couldn't open template $tpl!");
    
    while (<TPL>) {
        last if /\s*(<!--BEGIN RSRU-->)/;
        $tplTop .= $_;
    }

    say "TPLTOP: $tplTop" if ($debug);

    # Skip everything that isn't for the "easel" area
    while (<TPL>) { last if /\s*(<!--END RSRU-->)/; }

    # Then read the rest
    while (<TPL>) { $tplBottom .= $_; }

    say "TPLBOTTOM: $tplBottom" if ($debug);
    close TPL;
}

# Now load in our entry template file. This should be a HTML table
# with the appropriate areas for our data marked out
sub read_entrytpl {
    open(my $fh, "$blankEntry") or die ("Fatal: couldn't open entry template $blankEntry!");
    while (<$fh>) { $tplEntry .= $_; }
    say "Entry Template:\n$tplEntry" if ($debug);
    close $fh;
}

# Load in the HTML for each category in the catbar
sub read_cat_entrytpl {
    open(my $fh, "$blankCatEntry") or die("Fatal: couldn't open catbar template $blankCatEntry!");
    while(<$fh>) { $tplCatBar .= $_; }
    say "Catbar Template: $tplCatBar" if ($debug);
    close $fh;
}

# Takes a key and prints the HTML for its contents
# ARGUMENTS: Entry ID
# RETURNS: Scalar reference to woven template
sub entrykvs_to_html {
    my $entryId = $_[0];
    my $filledEntry = $tplEntry;
    
    # Find and replace, boys. Find and replace.
    foreach my $key (@knownKeys) {
        if ($key eq "date") {
            my $date = $entryKvs{$entryId}{'date'}->strftime('%m/%d/%Y');
            $filledEntry =~ s/{% $key %}/$date/g;
        } else {
            $filledEntry =~ s/{% $key %}/$entryKvs{$entryId}{$key}/g;
        }
    }
    
    say "Filled $entryId:\n$filledEntry" if ($debug);
    return \$filledEntry;
}

# Clear destination before write (configurable)
# Currently, will not clear any subdirs in $out
sub clear_dest {
    for my $unwanted (glob "$out/*.*") {
        next if -d $unwanted;
        say "clear_dest: Removing $unwanted..." if ($debug);
        unlink $unwanted or warn("Problem deleting $unwanted\n");
    }
}

# Copy any resources to outdir. For now, this is only CSS.
sub copy_res {
    for my $cssFile (glob "$tplinc/*.css") {
        copy($cssFile,"$out/") or die ("Problem copying $cssFile to $out.");
    }
}

# Insert title and description to master template top
sub paint_desc {
    $tplTop =~ s/{% HEAD_TITLE %}/$siteName/;
    $tplTop =~ s/{% HEAD_DESC %}/$siteHeaderDesc/;
}

# Insert the cat links. called by paint_template when it is used to process
# each category page.
# ARGUMENTS: active cat
sub prep_tpltop {
    my $activeCat = $_[0];
    my $filledCats; # Catbar
    my $cwCat;  # Current Working Category
    my $catFn; # Cat Filename (used for hyperlinks)

    foreach my $cat (@cats) {
        $catFn = $fnPre."_".$cat.".html";
        $cwCat = $tplCatBar;
        $cwCat =~ s/{% CAT_NAME %}/$cat/;
        $cwCat =~ s/{% CAT_URL %}/$catFn/;
        # Set only the active cat to have the HTML class "active"
        if ($cat eq $activeCat) {
            $cwCat =~ s/{% IS_ACTIVE %}/active/;
        }  else {
            $cwCat =~ s/{% IS_ACTIVE %}//;
        }
        $filledCats .= $cwCat;
    }

    $cwTplTop =~  s/{% RSRU_CATS %}/$filledCats/;
}

# Print gathered entries into our template files. Do one for each cat.
# ARGUMENTS: Cat name
sub paint_template {
    my $catName = $_[0];
    my $outFn = "$out/". $fnPre . "_" . $catName . ".html";
    my $currentEntry;
    my $pageNo = 1;

    open (my $fh, '>', $outFn);
    
    $cwTplTop = $tplTop;
    $cwTplTop =~ s/{% RSRU_TITLE %}/$siteName :: $catName (Page $pageNo)/;
    prep_tpltop $catName; 

    print $fh $cwTplTop;
    
    for my $entryId (sort_cat $catName) {
        next unless ($entryKvs{$entryId}{"category"} eq $catName);
        $currentEntry = entrykvs_to_html $entryId;
        print $fh $$currentEntry;
    }

    print $fh $tplBottom; 
    $writtenOut++;
    close $fh;
}

# Sort the given cat's entries. TODO sort order: DATE > RANK > ENTRY_NAME, currently only DATE.
# Argument: Cat name
# Returns: A list that consists of ordered entry IDs for each cat
sub sort_cat {
    my $cwCat = $_[0];
    my %entryDate;

    for my $entryId (keys %entryKvs) {
        if ($entryKvs{$entryId}{"category"} eq $cwCat) {
           $entryDate{$entryId} = $entryKvs{$entryId}{"date"};
        }
    }

    # I have no idea how this works, but it does.
    my @sorted = sort { $entryDate{$b} <=> $entryDate{$a} } keys %entryDate;

    say "SORTED SOFAR: @sorted, Length: ". length @sorted . " " if $debug;
    return @sorted;
}

# Read the contents of an individual entry file. Entryfiles are plain text and in
# a simple format. See 'samplesoft1.txt' for an example.
# Argument: Entry ID (equivalent to the name of its text file)
# Returns a reference to a key-value store of all obtained key-values from the entryfile.
sub read_entry {
    $entryId = $_[0];
    open (ENTRY, '<', "$entrydir/$entryId") or die "Couldn't open $entrydir/$entryId";
    $entryId =~ s/\.txt//;

    my %entryData;
    while (<ENTRY>) {
        # Skip comments (hash-commenced lines)
        next if /^#/;
        # Lines with a colon have a key, lines without are descriptions
        if (/:/) {
            chomp;
            # Watch for URLs! spilt will split at each colon it finds, unless restrained as such:
            my ($key, $val) = split /:\s+/; 
            if ($key eq "date"){
                $entryData{"date"} = Time::Piece->strptime($val, $DATE_FORMAT); 
            } else {
                $entryData{$key} = $val;
            }
            print "KEY: $key VALUE: $val\n" if ($debug);
        } else {
            # $_ means current line... '_' looks like a line
            $entryData{desc} .= $_;
        }
    }
    say "DESC: $entryData{desc}" if ($debug);
    close ENTRY;

    return \%entryData;
}

# Read in the contents of the entrydir. Calls read_entry
# on each text file therein. We will use this to fill our
# entryKvs.
sub read_entrydir {
    opendir(ENTRIES, "$entrydir") or die "Directory of entries not found."; 
    # Read in entries, exclude dotfiles
    my @entries = grep !/^\./, readdir ENTRIES;
    closedir ENTRIES;
    say "Entrydir listing: @entries" if ($debug);

    # $entryID is assigned inside read_entry
    $entryKvs{$entryId} = read_entry $_ for @entries;
    print (keys %entryKvs, " Keys in entrykvs. $entryId (last read)\n") if ($debug);
    print (values %entryKvs, " values in entrykvs.\n") if ($debug);
    dump_kvs if ($verbose);
}

#===============================================================================
# End Fndefs, begin exec.
#===============================================================================
say "RSRU starting. Master template: $tpl";

# Check we have what's needed.
die "Template file $tpl not found, cannot continue." unless -f $tpl;
mkdir $out unless -d $out;

say "==> Begin read of $entrydir contents ==>";
read_entrydir;
say "<== Read Finished <==";

say "==> Begin read of template files ==>";
read_partition_template;
read_entrytpl;
read_cat_entrytpl;
say "<== Read Finished <==";

say "<== Begin template interpolation... ==>";
clear_dest if ($clearDest);
copy_res;
paint_desc;
foreach my $cat (@cats) { paint_template $cat; }
say "<== Template interpolation finished. Wrote $writtenOut files. ==>";

say "RSRU complete.";
