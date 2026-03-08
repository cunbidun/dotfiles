#!/usr/bin/env bash
# Requires wf-recorder: https://github.com/ammen99/wf-recorder

# Use H.264 + yuv420p for broader compatibility (Slack/web players).
WF_RECORDER_VIDEO_OPTS="-c libx264 -p pix_fmt=yuv420p -p profile=high -p preset=veryfast -p colorspace=bt709 -p color_primaries=bt709 -p color_trc=bt709"
outputFile=""
outputDir=""
recordingPidFile="/tmp/screen_recording_pid"

# Function to check if recording is active
checkRecording() {
    if [ ! -f "$recordingPidFile" ]; then
        return 1
    fi

    recordingPid="$(cat "$recordingPidFile" 2>/dev/null)"
    if [ -z "$recordingPid" ]; then
        rm -f "$recordingPidFile"
        return 1
    fi

    if ! kill -0 "$recordingPid" 2>/dev/null; then
        rm -f "$recordingPidFile"
        return 1
    fi

    if [ -r "/proc/$recordingPid/comm" ] && [ "$(cat "/proc/$recordingPid/comm" 2>/dev/null)" = "wf-recorder" ]; then
        return 0
    fi

    rm -f "$recordingPidFile"
    return 1
}

# Function to start screen recording
startRecording() {
    if checkRecording; then
        echo "A recording is already in progress."
        exit 1
    fi

    target="$2"
    defaultSink="$(pactl get-default-sink 2>/dev/null || true)"
    audioOpt=""
    if [ -n "$defaultSink" ]; then
        audioOpt="--audio=$defaultSink.monitor"
    fi
    WF_RECORDER_OPTS="$audioOpt $WF_RECORDER_VIDEO_OPTS"

    recorderPid=""

    if [ "$target" == "screen" ]; then
        monitor_name="$3"
        outputDir="$4"
    elif [ "$target" == "region" ]; then
        outputDir="$3"
    else
        echo "Usage: $0 start {screen <monitor_name> | region} <output_directory>"
        exit 1
    fi

    # Set a default output directory if not provided
    outputDir="${outputDir:-$HOME/Videos}"

    # Expand ~ to $HOME if present in outputDir
    outputDir="${outputDir/#\~/$HOME}"

    # Ensure output directory exists
    if [ ! -d "$outputDir" ]; then
        mkdir -p "$outputDir"
        echo "Created output directory: $outputDir"
    fi

    # Generate output filename and path
    outputFile="recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    outputPath="$outputDir/$outputFile"

    echo "Target: $target"
    echo "Monitor: ${monitor_name:-N/A}"
    echo "Output dir: $outputDir"
    echo "Output file: $outputPath"

    # Start screen recording
    if [ "$target" == "screen" ]; then
        if [ -z "$monitor_name" ]; then
            echo "Error: Monitor name is required for screen recording."
            exit 1
        fi

        monitor_info=$(hyprctl -j monitors | jq -r ".[] | select(.name == \"$monitor_name\")")
        if [ -z "$monitor_info" ]; then
            echo "Error: Monitor '$monitor_name' not found."
            exit 1
        fi

        w=$(echo "$monitor_info" | jq -r '.width')
        h=$(echo "$monitor_info" | jq -r '.height')
        scale=$(echo "$monitor_info" | jq -r '.scale')
        x=$(echo "$monitor_info" | jq -r '.x')
        y=$(echo "$monitor_info" | jq -r '.y')

        transform=$(echo "$monitor_info" | jq -r '.transform')
        video_filter=""

        if [ "$transform" -eq 1 ] || [ "$transform" -eq 3 ]; then
            scaled_width=$(awk "BEGIN { v = int(($h / $scale)); print int(v / 2) * 2 }")
            scaled_height=$(awk "BEGIN { v = int(($w / $scale)); print int(v / 2) * 2 }")
        else
            scaled_width=$(awk "BEGIN { v = int(($w / $scale)); print int(v / 2) * 2 }")
            scaled_height=$(awk "BEGIN { v = int(($h / $scale)); print int(v / 2) * 2 }")
        fi

        case "$transform" in
        1)
            video_filter="-F transpose=1"
            ;;
        3)
            video_filter="-F transpose=2"
            ;;
        esac

        wf-recorder $WF_RECORDER_OPTS $video_filter --geometry "${x},${y} ${scaled_width}x${scaled_height}" --file "$outputPath" &
        recorderPid="$!"
    elif [ "$target" == "region" ]; then
        region_geometry="$(slurp)"

        # slurp returns non-zero (and empty output) when user presses Esc.
        if [ $? -ne 0 ] || [ -z "$region_geometry" ]; then
            echo "Region selection canceled."
            notify-send "Screen recording canceled" "Region selection was canceled." \
                -i video-x-generic \
                -a "Screen Recorder" \
                -t 4000
            exit 0
        fi

        # Region captures can produce odd dimensions; scale down to even sizes for yuv420p.
        wf-recorder $WF_RECORDER_OPTS -F "scale=trunc(iw/2)*2:trunc(ih/2)*2" --geometry "$region_geometry" --file "$outputPath" &
        recorderPid="$!"
    fi

    if [ -z "$recorderPid" ]; then
        echo "Error: failed to start wf-recorder."
        exit 1
    fi

    echo "$recorderPid" >"$recordingPidFile"
    disown "$recorderPid"
    echo "Recording started. Saving to $outputPath"
    echo "$outputPath" >/tmp/last_recording_path
    notify-send "Recording started" "Saving to: $outputPath" \
        -i media-record \
        -a "Screen Recorder" \
        -t 4000
}

# Function to stop screen recording
stopRecording() {
    if ! checkRecording; then
        echo "No recording in progress."
        exit 1
    fi

    recordingPid="$(cat "$recordingPidFile" 2>/dev/null)"
    if [ -n "$recordingPid" ]; then
        kill -SIGINT "$recordingPid" 2>/dev/null || true
    else
        pkill -SIGINT -f wf-recorder
    fi
    sleep 1 # Allow wf-recorder time to terminate before proceeding
    rm -f "$recordingPidFile"

    outputPath=$(cat /tmp/last_recording_path 2>/dev/null)

    if [ -z "$outputPath" ] || [ ! -f "$outputPath" ]; then
        notify-send "Recording stopped" "No recent recording found." \
            -i video-x-generic \
            -a "Screen Recorder" \
            -t 10000
        exit 1
    fi

    notify-send "Recording stopped" "Saved to: $outputPath" \
        -i video-x-generic \
        -a "Screen Recorder" \
        -t 10000 \
        --action="scriptAction:-xdg-open \"$(dirname "$outputPath")\"=Open Directory" \
        --action="scriptAction:-xdg-open \"$outputPath\"=Play"
}

# Handle script arguments
case "$1" in
start)
    startRecording "$@"
    ;;
stop)
    stopRecording
    ;;
status)
    if checkRecording; then
        echo "recording"
    else
        echo "not recording"
    fi
    ;;
*)
    echo "Usage: $0 {start [screen <monitor_name> | region] <output_directory> | stop | status}"
    exit 1
    ;;
esac
