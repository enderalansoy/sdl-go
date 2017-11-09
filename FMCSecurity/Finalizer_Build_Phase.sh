if [[ "${CONFIGURATION}" == "Release" ]]; then

FINALIZE_DIR="${SRCROOT}/FMCSecurity/finalizer/common"
LIB_DIR="${SRCROOT}/FMCSecurity/FMCSecurity"

echo $FINALIZE_DIR
echo $LIB_DIR

if [[ ! -e "$FINALIZE_DIR/xcode-finalize-protection.py" ]]; then
echo "${SRCROOT}/FMCSecurity/xcode-finalize-protection.py does not exist. Please update the Finalize Protection Build Phase in the Xcode project with the correct path to the xcode-finalize-protection.py script in the Finalizer installation."
exit 1
fi

FINALIZE="$FINALIZE_DIR/xcode-finalize-protection.py -prefinalized-library"

${FINALIZE} "$LIB_DIR/release/libFMCSecurity.a"

fi
