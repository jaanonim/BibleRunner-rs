id=com.jaanonim.bible_runner
name=bible_runner

echo `dirname $(realpath $0)`

kill "$(pidof $name)"

cd "$(dirname "$0")"

echo "Path: $execPath"

dataHome=~/.local/share

mkdir -p ~/.local/bin
mkdir -p "$dataHome"/krunner/dbusplugins/
mkdir -p "$dataHome"/dbus-1/services/

cp ../target/debug/$name ~/.local/bin/$name

serviceFileName=$id.service
desktopFileName=plasma-runner-$name.desktop
iconFileName=$name.png
execFullPath=$(readlink -m ~/.local/bin/$name)

cp $iconFileName /usr/share/pixmaps/$iconFileName
cp $iconFileName /usr/share/icons/$iconFileName
cat $serviceFileName | sed "s|Exec=|Exec=$execFullPath|" - > "$dataHome"/dbus-1/services/$serviceFileName
cp $desktopFileName "$dataHome"/krunner/dbusplugins/$desktopFileName

kquitapp6 krunner
