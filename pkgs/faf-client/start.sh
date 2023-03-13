#!@runtimeShell@

cd "@out@/lib/faf-client"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}@libs@" \
LOG_DIR=${LOG_DIR-"$HOME/.faforever/logs"} \
JAVA_HOME="@java_home@" @java_home@/bin/java \
    -Xmx712m \
    -XX:ConcGCThreads=1 \
    -XX:ParallelGCThreads=1 \
    -XX:+UseG1GC \
    -XX:+HeapDumpOnOutOfMemoryError \
    -Djava.net.preferIPv4Stack=true \
    -DnativeDir=@out@/lib/faf-client/natives \
    -Dprism.forceGPU=true \
    -Djava.library.path=@out@/lib/faf-client/lib \
    --add-opens=java.base/java.lang=ALL-UNNAMED \
    -Djavafx.cachedir="${XDG_CACHE_HOME:-$HOME/.cache}/openjfx" \
    -classpath "$(find "@out@/lib/faf-client/lib" -type f -name "*.jar" | @gawk@/bin/awk '$0!~/faf-ice-adapter.jar/{printf s$0;s=":"}')" \
    com.faforever.client.Main
