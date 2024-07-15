id=com.jaanonim.bible_runner
name=bible_runner

echo `dirname $(realpath $0)`

kill "$(pidof BibleRunner-rs)"

execPath=$(dirname $(realpath $0))/../target/debug/BibleRunner-rs
cd "$(dirname "$0")"

echo "Path: $execPath"

dataHome=~/.local/share

mkdir -p "$dataHome"/krunner/dbusplugins/
mkdir -p "$dataHome"/dbus-1/services/

serviceFileName=$id.service
desktopFileName=plasma-runner-$name.desktop
iconFileName=$name.png

cp $iconFileName /usr/share/pixmaps/$iconFileName
cp $iconFileName /usr/share/icons/$iconFileName
cat $serviceFileName | sed "s|Exec=|Exec=$execPath|" - > "$dataHome"/dbus-1/services/$serviceFileName
cp $desktopFileName "$dataHome"/krunner/dbusplugins/$desktopFileName

kquitapp6 krunner
