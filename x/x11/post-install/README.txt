This is in addition to Slackware's post-install BUILD scripts
because some of them -- eg beforelight -- have hard coded 
build paths (eg /tmp/foo) which ARMedslack doesn't use, so
we must have our own versions to do the necessary cleanup.
