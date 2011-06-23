Requirements
============

  - [Irssi](http://irssi.org) IRC client.
  - The following Perl packages. You have to restart Irssi when installed.
     - Debian/Ubuntu: libwww-perl + libcrypt-ssleay-perl
     - FreeBSD: p5-libwww
  - A [Notifo](http://notifo.com) account.
  - An iPhone with the Notifo app (free).

HOWTO
=====
  - Download the script to your Irssi scripts folder.
  - /script load notifonotify.pl
  - Follow the instructions on how to set Notifo username and api secret.
  - You'll receive push notifications when set as /away in Irssi.

Tips
====
  - If you've got problems activate debug mode with /set notifo_debug on and check your status window.
  - Notifonotify goes great together with autoaway.pl from [http://scripts.irssi.org/scripts/](http://scripts.irssi.org/scripts/).
