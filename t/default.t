use strict;
use warnings;

use Test::More;

#system("rm -rf output");
system("perl rsru.pl");
my @diff = qx(diff -r output t/expected_output);

diag explain \@diff;

# Ideally we would generate the output in a temporary directory and not in the "output" folder
# We would probably want to test various configurations.
# We should probably run the CI on the same docker images as where we created the expectation to
#     ensure that the images are the same.
# It would be probably better to generate html that does not have a timestamp in it.

# This is what the diff looks like now: (with the first line only showing on the CI)

# Binary files output/img/sample_tn.jpg and t/expected_output/img/sample_tn.jpg differ
# diff -r output/rss.xml t/expected_output/rss.xml
# 13c13
# < <lastBuildDate>Tue, 25 Apr 2023 17:02:20 UTC</lastBuildDate>
# ---
# > <lastBuildDate>Tue, 25 Apr 2023 16:44:18 UTC</lastBuildDate>


cmp_ok scalar(@diff), "<=", 6;

chomp @diff;
if (scalar(@diff) == 6) {
    # On the CI we ha
    is $diff[0], "Binary files output/img/sample_tn.jpg and t/expected_output/img/sample_tn.jpg differ";
}

done_testing;

