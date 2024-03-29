RSRU Testplan
===============

# Test all config samples
1. Ensure each is read and applied properly
2. Test both thumbnailed and un-thumbnailed entries for each template
3. Ensure the templates are interpolated properly
4. Create an entry and assign it a category that isn't defined in the conf.pl file. Ensure this category is created by RSRU.
5. Create an entry and omit some of the necessaryKeys. Ensure RSRU flags this and exits.

# Layout test
1. Test desktop and mobile browsers
2. Ensure all elements are rendered presentably. No overlaps, no misaligned elements.

# Input test
1. Test HTML and RSS output
2. Ensure everything is formatted

# Config test
1. Configure thumbnails to be enabled/disabled
2. Check no image clobber.
3. Check other options and ensure they're applied.
4. Verify command line args work
5. Check production and relative URLs are applied when configured, and that the URLS are correct.
6. Also check the RSS and image URLs in each mode. RSS should always be production URL.
7. Modify the default paths for input and output. Ensure they work properly.

# Pagination test
1. Ensure that max entries is applied to pages. Check odd/even values for max entries.
2. Check back/forwards link for categories, ensure they work properly and that "1 of $MAX" is correct for each category.
3. Ensure that highlights/recent isn't shown on homepage when below HPMAX value
4. Ensure that homepage entries link to the correct URL and page number

# Imaging test
1. Ensure that img_src is obeyed, or that the entry_name.{jpg,png} is used to generate image files
2. Ensure thumbnails are generated at the correct size and with the correct filename
3. Check all supported image formats work (jpg, png currently)
4. Check that imgDestDir works when its value is modified.

# Before release
* Update version number in README, rsru.pl
* Update copyright year in templates
* Check that HOWTO and docs are accurate
* Update release notes (use git commit log for reminder)
* Tidy up repo
* Announce on blog & Thransoft WWW
