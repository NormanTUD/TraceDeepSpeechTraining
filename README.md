# TraceDeepSpeechTraining

This allows tracing the output of DeepSpeech in a graphical way without invoking X11-related programs to get a quick
overview of what's happening in the training/validation phases.

Either source this file or put it in your `~/.bashrc` (or preferrably `~/.zshrc`). 

Then you can

> showlosses $OUTPUTLOGFILE

or individually

> traininglossavg $OUTPUTLOGFILE

or

> validationavg $OUTPUTLOGFILE

You can also do

> tracedeepspeech $SLURMJOBID

or

> tracedeepspeech $OUTPUTLOGFILE

It will try to locate the log file at first by it's full name (you can enter a full path), or by looking for files named `*$1*`, or, if this fails, it
will try to get the path from `slurmlogpath` (which invokes `scontrol show job $JOBID`).

# Requirements

- gnuplot
- Slurm (for auto-detection of log path, not needed if you always provide full file paths)

# Requirements that should be installed by default on your distro

- awk
- sed
- column
- grep
- perl
- cut

# The output

The output looks like this and refreshes every 10 seconds:

![Screenshot](screenshot.png?raw=true "Screenshot")

It will automatically adjust to the screen height/width to show training- and validationloss.
