_RSRU_ HOWTO
============

User's Guide covering installation, configuration, customisation and utilisation. Valid for Release 3.

# RSRU in brief

RSRU, or _Really Small Really Useful_, is a static website builder written in Perl.
It currently specialises in building "catalogue" style websites, so it is ideal for building a website dedicated to collections.

Sample templates are included for building a link catalogue or a software catalogue. These may be adapted to fit your needs.

PRACTICAL AND CONVENIENT TO THOSE ALREADY FAMILIAR WITH THE UNIX TERMINAL

# Installation

## System Requirements

- Windows, Linux or Mac OSX. RSRU has been tested on Windows and Linux but should also work on OSX.
- Perl v5.18 or later (exact version hasn't been tested, but RSRU is very vanilla Perl so probably works on older versions too).

## Readying Perl

If you are on Windows, first [install Strawberry Perl](https://strawberryperl.com/). If you are using Linux or OSX, your operating system has good taste and already includes Perl.

If you have never used Perl before, run `cpan` from a command window and agree to all the defaults. This will allow installation of helper modules for RSRU.

## Installing Helper Modules (Optional)

You may wish to include pictures in your website. You may also wish to generate RSS feeds so your eager audience can stay informed of your latest discoveries.
In these cases, RSRU needs some help to perform these duties. *If you opt against installing these, RSRU is still usable but will be without RSS and graphics processing.*

**NOTE:** To install the graphics module on Linux, another library must first be installed. This is not necessary on Windows.

Open a command window and run the following as root/sudo on Debian:

```
# apt install build-essential libgd-dev
```

Or on Void Linux:

```
# xbps-install base-devel gd-devel
```

I haven't used other Linux versions, but if you find how to install the GD dev library for that distro it should work. You can also install the Perl modules directly using your distro's packager, if you prefer and have the knowhow.

### Installing the CPAN modules

CPAN is the pakager for Perl. It will fetch and install our helper modules. To install these, open a command line on your Windows or \*nix box and run:

```
$ cpan install XML::RSS GD
```

You'll also need `Time::Piece` if you're using anything in the Fedora/RH/CentOS family.

## Download and extract RSRU

Download the latest version of RSRU from [Thransoft](https://soft.thran.uk) or [GitHub](https://github.com/lordfeck/rsru/releases). Extract the tar or zipfile to a convenient location in your filesystem.

```
$ tar -xvzf rsru_r3.tar.gz
```

On Windows, you can use the Windows file extraction wizard, 7zip, WinZip, WinRAR, pkzip or whichever archiever is nearest to hand.

# Customisation

Now that you've RSRU ready and waiting on your system, it is time to decide which template you prefer.

(screenshots of both, how to switch keywords in the tpl)

# Configuration

(conf.pl other options)

# Utilisation

edit entries, images howto, describe all keys for entries

run it

command line flags

how to publish it

sample entries & conf files for all tpls...
