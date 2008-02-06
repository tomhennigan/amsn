#!/bin/bash
gst-launch filesrc location="$1" ! mimdec ! ffmpegcolorspace ! videorate ! ffenc_mpeg4 ! avimux ! filesink location="$2"
