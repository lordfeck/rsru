#!/usr/bin/env perl

#===============================================================================
# Thransoft RSRU
# Collation and generation of software listings for a static website.
# Licence: GPLv3. See "licence.txt" for full details.
# Author: Thran. Authored: 09/09/2020

# With Thanks: https://stackoverflow.com/questions/63835994/
#===============================================================================

use strict;
use warnings;
use v5.10;

#===============================================================================
# Begin user-configurable
#===============================================================================
my $tplinc = "./html";      # Where shall I find my easel?
my $entrydir = "./entries"; # Where shall I find my inspiration?
my $out = "./rsru";         # Where shall I place my finished work?
my $tpl = "$tplinc/rsru_template.html"; # What is my easel named?
my $blankentry = "$tplinc/rsru_entry.html";
my $fnPre = "rsru";
my $siteName = "RSRU";
my $debug = 1;
my $verbose = 0;

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
my %catsFilledEntries;      # Hash of filled entries in HTML for each category

# List of known keys for each entry
my @knownKeys = qw(title version category interface img_desc os_support order date_added desc);

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
    while (<TPL>) {last if /\s*(<!--END RSRU-->)/; }

    while (<TPL>) {$tplBottom .= $_; }

    say "TPLBOTTOM: $tplBottom" if ($debug);
    close TPL;
}

# Now load in our entry template file. This should be a HTML table
# with the appropriate areas for our data marked out
sub read_entrytpl {
    open(my $fh, "$blankentry") or die ("Fatal: couldn't open entry template $blankentry!");
    while (<$fh>) { $tplEntry .= $_ ;}
    say "Entry Template:\n$tplEntry" if ($debug);
    close TPL;
}

# Takes a key and prints the HTML for its contents
# ARGUMENTS: Entry ID
# RETURNS: Scalar reference to woven template
sub entrykvs_to_html {
    my $entryId = $_[0];
    my $filledEntry = $tplEntry;
    
    # Find and replace, boys. Find and replace.
    foreach my $key (@knownKeys) {
        $filledEntry =~ s/{% $key %}/$entryKvs{$entryId}{$key}/;
    }
    
    say "Filled $entryId:\n$filledEntry" if ($debug);
    return \$filledEntry;
}

# Copy any resources to outdir.
sub copy_res {
# TODO: CSS
}

# Print gathered entries into our template files. Do one for each cat.
# Incomplete. TODO: complete, need to do for each cat...
# ARGUMENTS: Cat name
sub paint_template {
    my $catName = $_[0];
    my $outFn = "$out/". $fnPre . $catName . ".html";
    my $currentEntry;

    open (my $fh, '>', $outFn);
    print $fh $tplTop;

    while (my ($entryId, $hashRef) = each (%entryKvs)) {
        $currentEntry = entrykvs_to_html $entryId;
        print $fh $$currentEntry;
    }

    print $fh $tplBottom; 
    close $fh;
}

# Read the contents of an individual entry file. Entryfiles are plain text and in
# a simple format. See 'samplesoft1.txt' for an example.
# Returns a reference to a key-value store of all obtained key-values from the entryfile.
sub read_entry {
    ($entryId) = $_[0];
    open (ENTRY, '<', "$entrydir/$entryId") or die "Couldn't open $entrydir/$entryId";
    #FIXME: This should be a new variable for clarity's sake
    $entryId =~ s/\.txt//;

    my %entryData;
    while (<ENTRY>) {
        # Skip comments (hash-commenced lines)
        next if /^#/;
        # Lines with a colon have a key, lines without are descriptions
        if (/:/) {
            chomp;
            my ($key, $val) = split /:\s*/; 
            $entryData{$key} = $val;
            print "KEY: $key VALUE: $val\n" if ($debug);
        } else {
            # $_ means current line... '_' LOOKS LIKE A LINE... BRILLIANT!
            $entryData{desc} .= $_;
        }
    }
    say "DESC: $entryData{desc}" if ($debug);
    close ENTRY;

    return \%entryData;
}

#===============================================================================
# End Fndefs, begin exec.
#===============================================================================
say "RSRU starting. Master template: $tpl";

# Check we have what's needed.
die "Template file $tpl not found, cannot continue." unless -f $tpl;
mkdir $out unless -d $out;

opendir(ENTRIES, "$entrydir") or die "Directory of entries not found."; 
# Read in entries, exclude dotfiles
my @entries = grep !/^\./, readdir ENTRIES;
closedir ENTRIES;
say "Entrydir listing: @entries" if ($debug);

say "==> Begin read of $entrydir contents ==>";
$entryKvs{$entryId} = read_entry $_ for @entries;
print (keys %entryKvs, " Keys in entrykvs. $entryId (last read)\n") if ($debug);
print (values %entryKvs, " values in entrykvs.\n") if ($debug);
dump_kvs if ($verbose);
say "<== Read Finished <==";

say "==> Begin read of template files ==>";
read_partition_template;
read_entrytpl;
say "<== Read Finished <==";

say "<== Begin template interpolation... ==>";
paint_template "test";
say "<== Template interpolation finished ==>";

say "RSRU complete.";
