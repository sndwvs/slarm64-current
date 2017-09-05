Unlike in Slackware, I have split Koffice and KDEi up into 
separate sub directories due to KOffice having a different release
schedule (hence version) than KDE.

I felt that this was easier to maintain.

Remember to update the VERSION= in the SlackBuild scripts.

To build KDEi packages from this directory:
 # cd kde-l10n
 # arm/build  (or which ever port directory you are using)

To build Calligra internationalisation packages from this directory:
 # cd calligra-l10n
 # arm/build

Stuart Winter
<mozes@slackware.com>
30-Aug-2005
