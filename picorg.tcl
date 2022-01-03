#!/usr/bin/env tclsh
#
# SPDX-License-Identifier: MIT

package require Tcl 8.5
package require jpeg

set dir {}
set fmt {}
set verbose 0
set fmt_chars [list Y m d H M S f]

proc help {} {
    puts "picorg - a simple picture organizer"
    puts "Copyright (C) 2022 Pietro Cerutti <gahr@gahr.ch>"
    puts "SPDX-License-Identifier: MIT"
    puts ""
    puts "Usage: $::argv0 -dir <path> -fmt <format> \[-verbose] \[-help]"
    puts ""
    puts "-dir <path>    Process files in <path>"
    puts "-fmt <format>  Store processed files according to <format>"
    puts "               %Y  year"
    puts "               %m  month"
    puts "               %d  day"
    puts "               %H  hour"
    puts "               %M  minute"
    puts "               %S  second"
    puts "               %f  file name"
    puts "-verbose       Print debug information"
    puts "-help          Print this help message and quit"
    puts ""
}

proc die {msg} {
    puts stderr $msg
    exit 1
}

proc debug {msg} {
    if {$::verbose} {
        puts $msg
    }
}

proc parse_args {} {
    if {$::argc == 0} {
        help
        exit 0
    }
    for {set i 0} {$i < $::argc} {incr i} {
        switch [lindex $::argv $i] {
            -fmt {
                set ::fmt [lindex $::argv [incr i]]
            }
            -dir {
                set ::dir [lindex $::argv [incr i]]
            }
            -verbose {
                set ::verbose 1
            }
            -h - -help {
                help
                exit 0
            }
            default {
                die "Invalid argument: [lindex $::argv $i]"
            }
        }
    }
}

proc validate_dir {} {
    if {$::dir eq {}} {
        die "Empty directory: $::dir"
    }
    if {![file isdirectory $::dir]} {
        die "Invalid directory: $::dir"
    }
}

proc validate_fmt {} {
    if {$::fmt eq {}} {
        die "Empty format"
    }
    set start 0
    while {[set start [string first % $::fmt $start]] != -1} {
        set c [string index $::fmt [incr start]]
        if {$c ni $::fmt_chars} {
            die "Invalid format char: $c"
        }
    }
}

proc validate_args {} {
    validate_dir
    validate_fmt
}

proc organize {fullpath exif} {
    if {[catch {dict get $exif DateTimeOriginal} dto]} {
        debug "Missing DateTimeOrig for file: $fullpath"
        return
    }
    # DateTimeOriginal: 2021:12:24 19:07:35
    lassign [split $dto ": "] Y m d H M S
    set f [file tail $fullpath]
    set mappings [list]
    foreach c $::fmt_chars {
        lappend mappings "%$c" [set $c]
    }
    set out [file join $::dir [string map $mappings $::fmt]]
    if {[file exists $out]} {
        die "Existing destination for file: $f, $out"
    }
    file mkdir [file dirname $out]
    file rename $fullpath $out
    puts "$fullpath -> $out"
}

proc run {} {
    foreach f [glob -directory $::dir -nocomplain "*"] {
        set fullpath [file join $::dir $f]
        debug "Considering file: $fullpath"
        if {![file isfile $fullpath]} {
            debug "Skipping non file: $fullpath"
            continue
        }
        if {[catch {jpeg::getExif $fullpath} exif]} {
            debug "Cannot get exif data for file: $fullpath"
            continue
        }

        debug "Formatting entry for file: $fullpath"
        organize $fullpath $exif
    }
}

parse_args
validate_args
run

# vim: set ft=tcl ts=4 sw=4 expandtab:
