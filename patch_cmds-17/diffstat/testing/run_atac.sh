#!/bin/sh
# $Id: run_atac.sh,v 1.2 1998/01/17 01:10:06 tom Exp $
rm -f /tmp/atac_dir/*
run_test.sh
atac -u ../*.atac /tmp/atac_dir/*
atacmin ../*.atac /tmp/atac_dir/*
