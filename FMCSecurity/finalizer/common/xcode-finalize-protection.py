#!/usr/bin/env python
from cStringIO import StringIO
import argparse
import os
import shutil
import subprocess
import sys
import threading
import multiprocessing

################################################################################
# Script Exit Codes
################################################################################
# Success
EXIT_SUCCESS                      = 0
# Failed to run a command:
RUN_COMMAND_EXCEPTION             = 101
# Invalid parameter provide to the script:
INVALID_ARGUMENT                  = 102
# Script not executed from within an Xcode Run Script Build Phase:
MISSING_XCODE_ENVIRONMENT         = 103
# Unexpected exception while finalizing a single architecture binary:
UNEXPECTED_FINALIZATION_EXCEPTION = 104
# Could not find the finalizer binary relative to this script:
FINALIZER_NOT_FOUND               = 105

################################################################################
# Log an error message
#
# @param text The text to log
################################################################################
def echo_error(text):
    print "Error: " + text
    sys.stdout.flush()

################################################################################
# Log a warning message
#
# @param text The text to log
################################################################################
def echo_warn(text):
    print "Warning: " + text
    sys.stdout.flush()

################################################################################
# Log an information message, unless quiet
#
# @param text The text to log
################################################################################
quiet = False
def echo_note(text):
    if not quiet:
        print "Finalize Protection: " + text
    sys.stdout.flush()

################################################################################
# Run a command in another process, collecting the output and checking the
# return value
#
# @param description A description of the command to run
# @param command The full path and name of the command to run
# @param args The arguments to be provided to the command to run
################################################################################
def run_cmd(description, command, args):
    echo_note(description)
    print "<Finalizer Command> " + command + " " + ' '.join(args)
    sys.stdout.flush()

    command_line = [ command ]
    command_line.extend(args)
    try:
        # Run the command in a child process, redirecting output from the child
        # process to this process
        p = subprocess.Popen(command_line, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (stdout, stderr) = p.communicate()

    except Exception as e:
        echo_error(command + " failed: " + str(e))
        sys.stdout.flush()
        sys.exit(RUN_COMMAND_EXCEPTION)

    else:
        print stdout
        sys.stdout.flush()
        if p.returncode:
            echo_error(command + " failed: " + str(p.returncode))
            sys.stdout.flush()
            sys.exit(p.returncode)

################################################################################
# Run the finalizer command in another process, collecting the output and
# checking the return value
#
# @param current_arch The architecture of the binary to finalize
# @param mutex A mutex used to prevent concurrent access to stdout
################################################################################
def finalize_binary(current_arch, mutex):
    exitcode = EXIT_SUCCESS

    # To prevent intermixed output from the parallel finalization of multiple
    # architectures, access to stdout is serialized with a mutex. Try to
    # immediately acquire the mutex. If successful, we are the owner of stdout
    # until the end of this process. If not, we'll buffer stdout and stderr and
    # wait until we can successfully acquire the mutex to dump to the actual
    # stdout before exiting the process. Using a trylock in this manner allows
    # one finalization process to log immediately to stdout so that the user
    # doesn't have to wait until all activity is done on the process prior to
    # seeing any finalization output while still allowing the other finalization
    # processes to perform the finalization in parallel.
    stdout_owner = mutex.acquire(False)
    if not stdout_owner:
        # We did not successfully acquire the mutex at the beginning of the process.
        # Re-route stdout and stderr to a string buffer.
        local_stdout = StringIO()
        sys.stdout = sys.stderr = local_stdout

    # Perform all process activities in a try block. This way if something goes
    # wrong we still have a chance to dump the buffered output to the real stdout
    try:
        echo_note("Finalizing protection for " + current_arch)

        # Architecture Specific Variables
        objects_dir = OBJECT_FILE_DIR + "/" + current_arch
        finalizer_outputfile = objects_dir + "/" + finalized_executable

        # If building single architecture, the binary is in the Products directory
        # not the Intermediates directory
        if len(built_archs) == 1:
            finalizer_outputfile = built_product

        finalized_executable_dir = os.path.dirname(os.path.realpath(finalizer_outputfile))
        finalizer_map_file = TEMP_FILES_DIR + "/" + EXECUTABLE_NAME + "-LinkMap-" + build_variant + "-" + current_arch + ".txt"

        # Create the prefin file
        echo_note("Creating " + finalized_executable + ".prefin in " + objects_dir)
        shutil.copyfile(finalizer_outputfile, objects_dir + "/" + finalized_executable + ".prefin")

        # Set the runtime debug data file name
        finalizer_args = [ ]
        debug_suffix = ""
        if args.finalizer_debug or args.finalizer_debug_verbose:
            if args.finalizer_debug_verbose:
                debug_suffix=".v"
            finalizer_args.append("-runtime-debug-data")
            finalizer_args.append(finalized_executable + ".app/" + EXECUTABLE_NAME + "-" + current_arch + ".dbg" + debug_suffix)

        # Bundle Directory
        finalizer_args.append("-bundle-directory")
        finalizer_args.append(os.path.dirname(os.path.realpath(built_product)))

        # If dSYM is enabled, disable strip in the finalizer if it was not already
        # disabled by the user. The binary will be stripped after the dSYM is generated.
        if not args.disable_strip and (DEBUGGING_SYMBOLS == "YES" and DEBUG_INFORMATION_FORMAT == "dwarf-with-dsym"):
            finalizer_args.append("-disable-strip")

        # Copy the common finalizer args into the finalizer args. Do this after the
        # above args are added so that the user can override any of the above args
        # if necessary without modifying this script.
        finalizer_args.extend(common_finalizer_args)

        # Output Filename
        finalizer_args.append("-o")
        finalizer_args.append(finalizer_outputfile)

        # Binary to be finalized
        finalizer_args.append(finalizer_outputfile)

        # Linker Map File
        finalizer_args.append(finalizer_map_file)

        # Finalizer .fin file(s)
        for each_prefin_file in args.prefinalized_libraries:
            fin_file = each_prefin_file + "-" + current_arch + ".fin"
            # finalizer_args.append(fin_file)
            # Because of the way our structure works, we need the file name and
            # it's parent directory
            parent_dir = os.path.dirname(os.path.dirname(fin_file))
            file_path = os.path.relpath(fin_file, parent_dir)
            # But the files are actually in the same directory as the finalizer
            file_path = finalizer_root + '/' + file_path
            finalizer_args.append(file_path)


        # Execute the finalizer for the current architecture
        run_cmd("Invoking the finalizer for " + finalized_executable + " for " + current_arch, finalizer, finalizer_args)

        # Copy the finalizer dbg output file to the proper location
        if args.finalizer_debug or args.finalizer_debug_verbose:
            echo_note("Moving debug file " + finalizer_outputfile + ".dbg to " + built_product + "-" + current_arch + ".dbg" + debug_suffix)
            shutil.move(finalizer_outputfile + ".dbg", built_product + "-" + current_arch + ".dbg" + debug_suffix)

    except StandardError as e:
        print "Caught Exception: " + str(e)
        exitcode = UNEXPECTED_FINALIZATION_EXCEPTION

    except SystemExit as e:
        # We could get here if run_cmd() encounters a failure. Propogate the exit code.
        exitcode = e

    finally:
        if stdout_owner:
            mutex.release()
        else:
            # Make sure that all output to the redirected stdout is flushed, then
            # restore stdout and stderr to their original values.
            sys.stdout.flush()
            sys.stdout = sys.__stdout__
            sys.stderr = sys.__stderr__

            # Log all messagse at once after aquiring the mutex to prevent
            # intermixed output from other finalization processes.
            mutex.acquire()
            print local_stdout.getvalue()
            sys.stdout.flush()
            mutex.release()
        sys.exit(exitcode)

################################################################################
# Main Program
################################################################################
if __name__ == "__main__":
    # Describe and collect command line arguments
    parser = argparse.ArgumentParser(description="Finalize protection of a binary")
    parser.add_argument("-finalizer-quiet", action="store_true", dest="quiet", default=False,
                        help="Disables informational logging during finalization")
    parser.add_argument("-finalizer-verbose", action="store_true", dest="verbose", default=False,
                        help="Prints verbose finalization information")
    parser.add_argument("-finalizer-debug", action="store_true", dest="finalizer_debug", default=False,
                        help="Enables runtime protection debug information if the static library was accompanied by a .dbg file")
    parser.add_argument("-finalizer-debug-verbose", action="store_true", dest="finalizer_debug_verbose", default=False,
                        help="Enables verbose runtime protection debug information if the static library was accompanied by a .dbg file")
    parser.add_argument("-finalizer-disable-strip", action="store_true", dest="disable_strip", default=False,
                        help="Disables symbol stripping after finalization")
    parser.add_argument("-finalizer-strip-cmd", action="store", dest="strip_command",
                        metavar="<Strip_Command>", help="Strip command that should be used instead of the default strip command")
    parser.add_argument("-prefinalized-library", required=True, action="append", dest="prefinalized_libraries",
                        metavar="<Pre-finalized_Library>", help="Protected static library to be finalized. This argument may be specified multiple times if multiple static libraries require finalization.")
    parser.add_argument("-build-variant", action="store", dest="build_variant", help=argparse.SUPPRESS)
    (args, other_finalizer_args) = parser.parse_known_args()

    # Collect Common Finalizer Args
    common_finalizer_args = [ ]
    if args.disable_strip:
        common_finalizer_args.append("-disable-strip")

    strip_cmd = "strip"
    if args.strip_command:
        common_finalizer_args.append("-strip-cmd")
        common_finalizer_args.append(args.strip_command)
        strip_cmd = args.strip_command

    if args.quiet:
        common_finalizer_args.append("-quiet")
        quiet = True

    if args.verbose:
        common_finalizer_args.append("-v")

    # Handle Custom Xcode Build Variants that the user may specify using the -build-variant flag
    # This script may only be used to finalize a single variant at at time. This
    # script may be invoked multiple times with different -build-variant flag
    # values to finalize multiple build variants.
    build_variant = "normal"
    executable_suffix = ""
    if args.build_variant:
        build_variant = args.build_variant
    if build_variant != "normal":
        executable_suffix = "_" + build_variant

    # Add other finalizer args not handled by this script last so that they override
    # any of the settings above. This is useful to guarantee that flags destined
    # directly for the finalizer take precedence.
    common_finalizer_args.extend(other_finalizer_args)

    # Retrieve Xcode Environment Variables
    try:
        ARCHS = os.environ["ARCHS"]
        BUILT_PRODUCTS_DIR = os.environ["BUILT_PRODUCTS_DIR"]
        DEBUG_INFORMATION_FORMAT = os.environ["DEBUG_INFORMATION_FORMAT"]
        DEBUGGING_SYMBOLS = os.environ["DEBUGGING_SYMBOLS"]
        DWARF_DSYM_FOLDER_PATH = os.environ["DWARF_DSYM_FOLDER_PATH"]
        DWARF_DSYM_FILE_NAME = os.environ["DWARF_DSYM_FILE_NAME"]
        EXECUTABLE_NAME = os.environ["EXECUTABLE_NAME"]
        EXECUTABLE_PATH = os.environ["EXECUTABLE_PATH"]
        OBJECT_FILE_DIR = os.environ["OBJECT_FILE_DIR_" + build_variant]
        TEMP_FILES_DIR = os.environ["TEMP_FILES_DIR"]
    except Exception as invalid_env_var:
        echo_error("Environment variable, " + str(invalid_env_var) +
                   ", does not exist. This script must be executed within the "
                   "context of an Xcode Build Phase Run Script. Please see the "
                   "finalizer documentation for more information on usage of this "
                   "script.")
        sys.exit(MISSING_XCODE_ENVIRONMENT)

    # Define common arguments shared by all architectures
    built_product = BUILT_PRODUCTS_DIR + "/" + EXECUTABLE_PATH + executable_suffix
    finalizer_root = os.path.dirname(os.path.realpath(__file__ + "/.."))
    finalizer = finalizer_root + "/finalizer"
    if not os.path.isfile(finalizer):
        finalizer = finalizer_root + "/common/finalizer"
        if not os.path.isfile(finalizer):
            echo_error(finalizer + " does not exist. Please make sure the " + os.path.basename(os.path.realpath(__file__)) + " script and finalizer binary were not moved from their original install locations.")
            sys.exit(FINALIZER_NOT_FOUND)
    finalized_executable = os.path.basename(built_product)
    lipo_cmd = "lipo"
    lipo_args = [ "-create" ]

    # Set the FINALIZER environment variable as required by the finalizer
    # This replaces the need to run setenv.sh
    os.environ["FINALIZER"] = finalizer_root

    # Finalize each single architecture binary independently, on a separate thread
    built_archs = ARCHS.split()
    processes = [ ]
    mutex = multiprocessing.Lock()
    for current_arch in built_archs:
        process = multiprocessing.Process(target=finalize_binary, args=(current_arch, mutex))
        processes.append(process)
        process.start()
        lipo_args.append(OBJECT_FILE_DIR + "/" + current_arch + "/" + finalized_executable)

    # Wait for all processes to complete
    for process in processes:
        process.join()
        if process.exitcode:
            echo_error("Finalization failed with exit code " + str(process.exitcode))
            sys.stdout.flush()
            sys.exit(process.exitcode)

    # If building for multiple architectures, create the universal binary
    if len(built_archs) > 1:
        lipo_args.append("-output")
        lipo_args.append(built_product)
        run_cmd("Create universal binary " + finalized_executable, lipo_cmd, lipo_args)

    # If dSYM is enabled, create the dSYM
    if DEBUGGING_SYMBOLS == "YES" and DEBUG_INFORMATION_FORMAT == "dwarf-with-dsym":
        dsym_cmd = "dsymutil"
        dsym_args = [ ]
        dsym_args.append(built_product)
        dsym_args.append("-o")
        dsym_args.append(DWARF_DSYM_FOLDER_PATH + "/" + DWARF_DSYM_FILE_NAME)
        run_cmd("Generate " + DWARF_DSYM_FILE_NAME, dsym_cmd, dsym_args)

        # Strip the binary unless it was disabled
        if not args.disable_strip:
            strip_args = [ built_product ]
            run_cmd("Strip " + finalized_executable, strip_cmd, strip_args)
