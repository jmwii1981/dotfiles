# -*- coding: utf-8 -*-
"""
This file is executed when the Python interactive shell is started if
$PYTHONSTARTUP is in your environment and points to this file.
Adapted from https://github.com/whiteinge/dotfiles/blob/master/.pythonrc.py
"""

import atexit
from code import InteractiveConsole
import os
import pprint
import readline, rlcompleter
import sys
from tempfile import mkstemp

import datetime
import pdb

# Color Support
###############

class TermColors(dict):
    """Gives easy access to ANSI color codes. Attempts to fall back to no color
    for certain TERM values. (Mostly stolen from IPython.)"""

    COLOR_TEMPLATES = (
        ("Black"       , "0;30"),
        ("Red"         , "0;31"),
        ("Green"       , "0;32"),
        ("Brown"       , "0;33"),
        ("Blue"        , "0;34"),
        ("Purple"      , "0;35"),
        ("Cyan"        , "0;36"),
        ("LightGray"   , "0;37"),
        ("DarkGray"    , "1;30"),
        ("LightRed"    , "1;31"),
        ("LightGreen"  , "1;32"),
        ("Yellow"      , "1;33"),
        ("LightBlue"   , "1;34"),
        ("LightPurple" , "1;35"),
        ("LightCyan"   , "1;36"),
        ("White"       , "1;37"),
        ("Normal"      , "0"),
    )

    NoColor = ''
    _base  = '\001\033[%sm\002'

    def __init__(self):
        if os.environ.get('TERM') in ('xterm-color', 'xterm-256color', 'linux',
                                    'screen', 'screen-256color', 'screen-bce',
                                    'rxvt', 'rxvt-unicode-256color'):
            self.update(dict([(k, self._base % v) for k,v in self.COLOR_TEMPLATES]))
        else:
            self.update(dict([(k, self.NoColor) for k,v in self.COLOR_TEMPLATES]))
_c = TermColors()

# Enable a History
##################

HISTFILE="%s/.pyhistory" % os.environ["HOME"]

# Read the existing history if there is one
if os.path.exists(HISTFILE):
    readline.read_history_file(HISTFILE)

# Set maximum number of items that will be written to the history file
readline.set_history_length(300)

def savehist():
    readline.write_history_file(HISTFILE)

atexit.register(savehist)

# Enable Color Prompts
######################

sys.ps1 = '%s>>> %s' % (_c['Green'], _c['Normal'])
sys.ps2 = '%s... %s' % (_c['Red'], _c['Normal'])

# Enable Pretty Printing for stdout
###################################

def my_displayhook(value):
    if value is not None:
        try:
            import __builtin__
            __builtin__._ = value
        except ImportError:
            __builtins__._ = value

        pprint.pprint(value)
sys.displayhook = my_displayhook

# Welcome message
#################

WELCOME = """\
%(Cyan)s
You've got color, history, and pretty printing.
%(Brown)s
Type \e to get an external editor.
%(Normal)s""" % _c

atexit.register(lambda: sys.stdout.write("""%(DarkGray)s
Quitting.
%(Normal)s""" % _c))

# Django Helpers
################

def SECRET_KEY():
    "Generates a new SECRET_KEY that can be used in a project settings file."

    from random import choice
    return ''.join(
            [choice('abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)')
                for i in range(50)])

# If we're working with a Django project, set up the environment
if 'DJANGO_SETTINGS_MODULE' in os.environ:
    from django.db.models.loading import get_models
    from django.test.client import Client
    from django.test.utils import setup_test_environment, teardown_test_environment
    from django.conf import settings as S

    class DjangoModels(object):
        """Loop through all the models in INSTALLED_APPS and import them."""
        def __init__(self):
            for m in get_models():
                setattr(self, m.__name__, m)

    A = DjangoModels()
    C = Client()

    WELCOME += """%(Green)s
Django environment detected.
* Your INSTALLED_APPS models are available as `A`.
* Your project settings are available as `S`.
* The Django test client is available as `C`.
%(Normal)s""" % _c

    setup_test_environment()
    S.DEBUG_PROPAGATE_EXCEPTIONS = True

    WELCOME += """%(LightPurple)s
Warning: the Django test environment has been set up; to restore the
normal environment call `teardown_test_environment()`.
Warning: DEBUG_PROPAGATE_EXCEPTIONS has been set to True.
%(Normal)s""" % _c


# Start an external editor with \e
##################################
# http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/438813/

EDITOR = os.environ.get('EDITOR', 'vi')
EDIT_CMD = '\e'

class EditableBufferInteractiveConsole(InteractiveConsole):
    def __init__(self, *args, **kwargs):
        self.last_buffer = [] # This holds the last executed statement
        InteractiveConsole.__init__(self, *args, **kwargs)

    def runsource(self, source, *args):
        self.last_buffer = [ source.encode('utf-8') ]
        return InteractiveConsole.runsource(self, source, *args)

    def raw_input(self, *args):
        line = InteractiveConsole.raw_input(self, *args)
        if line == EDIT_CMD:
            fd, tmpfl = mkstemp('.py')
            os.write(fd, b'\n'.join(self.last_buffer))
            os.close(fd)
            os.system('%s %s' % (EDITOR, tmpfl))
            line = open(tmpfl).read()
            os.unlink(tmpfl)
            tmpfl = ''
            lines = line.split( '\n' )
            for i in range(len(lines) - 1): self.push( lines[i] )
            line = lines[-1]
        return line

c = EditableBufferInteractiveConsole(locals=locals())
c.interact(banner=WELCOME)

# Exit the Python shell on exiting the InteractiveConsole
sys.exit()